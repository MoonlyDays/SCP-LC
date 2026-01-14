SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-001-S"
SWEP.HoldType = "normal"
SWEP.ScoreOnDamage = true
SWEP.ScoreOnKill = true

-- Ability cooldowns and parameters
SWEP.BoneAttackCooldown = 1
SWEP.BoneAttackDamage = 1
SWEP.BoneAttackRange = 600
SWEP.BoneProjectileSpeed = 1200

SWEP.BlasterCooldown = 5
SWEP.BlasterDamage = 5
SWEP.BlasterRange = 800

SWEP.TeleportCooldown = 120
SWEP.TeleportStaminaCost = 100

-- Multi-hit parameters for sinful targets
SWEP.YellowHits = 3
SWEP.RedHits = 5
SWEP.YellowBleedTier = 1
SWEP.RedBleedTier = 2

-- Stamina as HP system
SWEP.MaxStamina = 500
SWEP.StaminaRegen = 2 -- per second

--[[
    SCP-001-S "Sans" - The Judge

    Mechanics:
    - Has 1 HP, but stamina acts as health (damage depletes stamina instead)
    - Very high stamina pool, slow regeneration
    - Tracks damage dealt by all players during the round
    - Players are marked with colored outlines based on their "sin level":
        Green: < 200 damage dealt (normal attacks)
        Yellow: 200-499 damage dealt (multi-hit + bleeding)
        Red: 500+ damage dealt (multi-hit + severe bleeding)

    Attacks:
    - LMB: Bone projectile (1 sec cooldown)
    - RMB: Gaster Blaster (5 sec cooldown)
    - G: Teleport to selected location (2 min cooldown, costs stamina)
]]

function SWEP:SetupDataTables()
    self:CallBaseClass("SetupDataTables")
    self:NetworkVar("Float", "SansStamina")
    self:NetworkVar("Float", "MaxSansStamina")
    self:NetworkVar("Float", "NextBlaster")
    self:NetworkVar("Float", "NextTeleport")
    self:NetworkVar("Bool", "TeleportMode")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self:InitializeLanguage("SCP001S")
    self:InitializeHUD()

    self:SetSansStamina(self.MaxStamina)
    self:SetMaxSansStamina(self.MaxStamina)
    self:SetNextBlaster(0)
    self:SetNextTeleport(0)
    self:SetTeleportMode(false)
end

function SWEP:Think()
    if ROUND.preparing or ROUND.post then return end

    local ct = CurTime()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- Stamina regeneration (server-side)
    if SERVER then
        if not self.NextStaminaRegen or self.NextStaminaRegen <= ct then
            self.NextStaminaRegen = ct + 1
            local current = self:GetSansStamina()
            local max = self:GetMaxSansStamina()
            if current < max then
                self:SetSansStamina(math.min(current + self.StaminaRegen, max))
            end
        end
    end
end

-- Get player's sin level based on damage dealt this round
function SWEP:GetPlayerSinLevel(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return 0 end
    local dmg = ply:GetProperty("sans_damage_dealt", 0)
    if dmg >= 500 then return 3 end -- Red
    if dmg >= 200 then return 2 end -- Yellow
    return 1 -- Green
end

-- Get sin color for outline rendering
function SWEP:GetSinColor(sinLevel)
    if sinLevel == 3 then return Color(255, 0, 0, 255) end -- Red
    if sinLevel == 2 then return Color(255, 255, 0, 255) end -- Yellow
    return Color(0, 255, 0, 255) -- Green
end

-- Override damage to use stamina instead of HP
function SWEP:TakeStaminaDamage(damage)
    local current = self:GetSansStamina()
    local newStamina = current - damage

    if newStamina <= 0 then
        -- Player dies when stamina depletes
        self:SetSansStamina(0)
        local owner = self:GetOwner()
        if IsValid(owner) and SERVER then
            local dmg = DamageInfo()
            dmg:SetDamage(owner:Health())
            dmg:SetDamageType(DMG_DIRECT)
            owner:TakeDamageInfo(dmg)
        end
        return true -- Died
    end

    self:SetSansStamina(newStamina)
    return false -- Survived
end

-- Primary Attack: Bone Projectile
local attack_trace = {}
attack_trace.mask = MASK_SHOT
attack_trace.output = attack_trace

function SWEP:PrimaryAttack()
    if ROUND.preparing or ROUND.post then return end
    if self:GetTeleportMode() then
        self:ExecuteTeleport()
        return
    end

    local ct = CurTime()
    self:SetNextPrimaryFire(ct + self.BoneAttackCooldown)

    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- Create bone projectile
    local spos = owner:GetShootPos()
    local dir = owner:GetAimVector()

    local projectile = ents.Create("slc_sans_bone")
    if IsValid(projectile) then
        projectile:SetPos(spos + dir * 20)
        projectile:SetAngles(dir:Angle())
        projectile:SetOwner(owner)
        projectile.Weapon = self
        projectile:Spawn()

        local phys = projectile:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(dir * self.BoneProjectileSpeed)
        end
    end

    owner:EmitSound("SCP001S.BoneAttack")
    AddRoundStat("001s")
end

-- Secondary Attack: Gaster Blaster
function SWEP:SecondaryAttack()
    if ROUND.preparing or ROUND.post then return end
    if self:GetTeleportMode() then
        -- Cancel teleport mode
        self:SetTeleportMode(false)
        return
    end

    local ct = CurTime()
    if self:GetNextBlaster() > ct then return end

    self:SetNextBlaster(ct + self.BlasterCooldown)

    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- Create Gaster Blaster projectile
    local spos = owner:GetShootPos()
    local dir = owner:GetAimVector()

    local blaster = ents.Create("slc_sans_blaster")
    if IsValid(blaster) then
        blaster:SetPos(spos + dir * 30)
        blaster:SetAngles(dir:Angle())
        blaster:SetOwner(owner)
        blaster.Weapon = self
        blaster:Spawn()
    end

    owner:EmitSound("SCP001S.GasterBlaster")
end

-- Special Attack: Teleport
function SWEP:SpecialAttack()
    if ROUND.preparing or ROUND.post then return end

    local ct = CurTime()
    if self:GetNextTeleport() > ct then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- Check if we have enough stamina
    if self:GetSansStamina() < self.TeleportStaminaCost then
        if CLIENT then
            owner:EmitSound("buttons/button11.wav")
        end
        return
    end

    -- Toggle teleport mode
    self:SetTeleportMode(not self:GetTeleportMode())

    if CLIENT and self:GetTeleportMode() then
        owner:EmitSound("SCP001S.TeleportReady")
    end
end

function SWEP:ExecuteTeleport()
    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- Trace to find teleport destination
    local trace = {}
    trace.start = owner:GetShootPos()
    trace.endpos = trace.start + owner:GetAimVector() * 5000
    trace.filter = owner
    trace.mask = MASK_PLAYERSOLID

    local tr = util.TraceLine(trace)

    if tr.Hit then
        local targetPos = tr.HitPos + tr.HitNormal * 32

        -- Verify there's room for the player
        local hull = {}
        hull.start = targetPos
        hull.endpos = targetPos
        hull.mins = owner:GetCollisionBounds()
        hull.maxs = select(2, owner:GetCollisionBounds())
        hull.filter = owner

        local hullTrace = util.TraceHull(hull)

        if not hullTrace.StartSolid then
            -- Consume stamina and teleport
            self:SetSansStamina(self:GetSansStamina() - self.TeleportStaminaCost)
            self:SetNextTeleport(CurTime() + self.TeleportCooldown)
            self:SetTeleportMode(false)

            owner:SetPos(targetPos)
            owner:EmitSound("SCP001S.Teleport")

            -- Visual effect at both locations
            local effectdata = EffectData()
            effectdata:SetOrigin(targetPos)
            util.Effect("sans_teleport", effectdata, true, true)
        else
            owner:EmitSound("buttons/button11.wav")
        end
    end

    self:SetTeleportMode(false)
end

-- Deal damage based on target's sin level
function SWEP:DealSinDamage(target, baseDamage, attacker, inflictor)
    if not IsValid(target) or not target:IsPlayer() then return end
    if not self:CanTargetPlayer(target) then return end

    local sinLevel = self:GetPlayerSinLevel(target)
    local hits = 1
    local bleedTier = 0

    if sinLevel == 2 then
        hits = self.YellowHits
        bleedTier = self.YellowBleedTier
    elseif sinLevel == 3 then
        hits = self.RedHits
        bleedTier = self.RedBleedTier
    end

    -- Deal multiple hits for sinful targets
    for i = 1, hits do
        local dmg = DamageInfo()
        dmg:SetDamage(baseDamage)
        dmg:SetDamageType(DMG_SLASH)
        dmg:SetAttacker(attacker)
        dmg:SetInflictor(inflictor)
        target:TakeDamageInfo(dmg)
    end

    -- Apply bleeding for sinful targets
    if bleedTier > 0 then
        target:ApplyEffect("bleeding", bleedTier, attacker)
    end
end

function SWEP:OnRemove()
    if not SERVER then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
end

--[[-------------------------------------------------------------------------
SCP Hooks - Damage redirection to stamina
---------------------------------------------------------------------------]]
SCPHook("SCP001S", "EntityTakeDamage", function(ply, dmg)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if ply:SCPClass() ~= CLASSES.SCP001S then return end

    local wep = ply:GetSCPWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_scp_001s" then return end

    -- Redirect damage to stamina
    local damage = dmg:GetDamage()
    if damage > 0 then
        wep:TakeStaminaDamage(damage)
        dmg:SetDamage(0)
        return true
    end
end)

--[[-------------------------------------------------------------------------
Global damage tracking - uses round hook to track ALL players' damage
This runs from round start, not just when Sans spawns
---------------------------------------------------------------------------]]
if SERVER then
    hook.Add("SLCRound", "SCP001S_InitDamageTracking", function()
        -- Initialize damage tracking for all players at round start
        for _, ply in ipairs(player.GetAll()) do
            ply:SetProperty("sans_damage_dealt", 0)
        end

        -- Add round hook to track damage dealt by all players
        AddRoundHook("PostEntityTakeDamage", "SCP001S_TrackDamage", function(ent, dmg, took)
            if not took then return end
            if not IsValid(ent) or not ent:IsPlayer() then return end

            local attacker = dmg:GetAttacker()
            if not IsValid(attacker) or not attacker:IsPlayer() then return end
            if attacker:SCPTeam() == TEAM_SPEC then return end

            -- Track damage dealt
            local currentDmg = attacker:GetProperty("sans_damage_dealt", 0)
            attacker:SetProperty("sans_damage_dealt", currentDmg + dmg:GetDamage())
        end)
    end)

    -- Also initialize for players who join mid-round
    hook.Add("PlayerInitialSpawn", "SCP001S_InitNewPlayer", function(ply)
        if ROUND.active then
            ply:SetProperty("sans_damage_dealt", 0)
        end
    end)
end

--[[-------------------------------------------------------------------------
Upgrade system
---------------------------------------------------------------------------]]
local icons = {}
if CLIENT then
    icons.bone = GetMaterial("slc/hud/upgrades/scp/001s/bone.png", "smooth")
    icons.blaster = GetMaterial("slc/hud/upgrades/scp/001s/blaster.png", "smooth")
    icons.teleport = GetMaterial("slc/hud/upgrades/scp/001s/teleport.png", "smooth")
end

DefineUpgradeSystem("scp001s", {
    grid_x = 3,
    grid_y = 3,
    upgrades = {
        {
            name = "bone1",
            cost = 1,
            req = {},
            reqany = false,
            pos = {1, 1},
            mod = {
                bone_cd = 0.8
            },
            icon = icons.bone
        },
        {
            name = "bone2",
            cost = 2,
            req = {"bone1"},
            reqany = false,
            pos = {1, 2},
            mod = {
                bone_dmg = 1.5
            },
            icon = icons.bone
        },
        {
            name = "blaster1",
            cost = 1,
            req = {},
            reqany = false,
            pos = {2, 1},
            mod = {
                blaster_cd = 0.8
            },
            icon = icons.blaster
        },
        {
            name = "blaster2",
            cost = 2,
            req = {"blaster1"},
            reqany = false,
            pos = {2, 2},
            mod = {
                blaster_dmg = 1.5
            },
            icon = icons.blaster
        },
        {
            name = "teleport1",
            cost = 2,
            req = {},
            reqany = false,
            pos = {3, 1},
            mod = {
                teleport_cd = 0.7,
                teleport_cost = 0.8
            },
            icon = icons.teleport
        },
        {
            name = "outside_buff",
            cost = 1,
            req = {},
            reqany = false,
            pos = {3, 3},
            mod = {},
            active = false
        },
    },
    rewards = {{100, 1}, {200, 1}, {350, 1}, {500, 1}, {700, 1},}
}, SWEP)

--[[-------------------------------------------------------------------------
SCP HUD
---------------------------------------------------------------------------]]
if CLIENT then
    local hud = SCPHUDObject("SCP001S", SWEP)
    hud:AddCommonSkills()

    -- Stamina bar (acts as HP)
    hud:AddBar("stamina")
        :SetMaterial("slc/hud/scp/001s/stamina.png", "smooth")
        :SetColor(Color(0, 150, 255))
        :SetTextFunction(function(swep)
            return math.floor(swep:GetSansStamina()) .. "/" .. math.floor(swep:GetMaxSansStamina())
        end)
        :SetProgressFunction(function(swep)
            return swep:GetSansStamina() / swep:GetMaxSansStamina()
        end)

    -- Bone attack
    hud:AddSkill("bone_attack")
        :SetButton("attack")
        :SetMaterial("slc/hud/scp/001s/bone.png", "smooth")
        :SetCooldownFunction("GetNextPrimaryFire")

    -- Gaster Blaster
    hud:AddSkill("gaster_blaster")
        :SetButton("attack2")
        :SetMaterial("slc/hud/scp/001s/blaster.png", "smooth")
        :SetCooldownFunction("GetNextBlaster")

    -- Teleport
    hud:AddSkill("teleport")
        :SetButton("scp_special")
        :SetMaterial("slc/hud/scp/001s/teleport.png", "smooth")
        :SetCooldownFunction("GetNextTeleport")
        :SetActiveFunction(function(swep) return swep:GetTeleportMode() end)

    -- Teleport mode indicator
    hud:AddBar("teleport_mode")
        :SetColor(Color(100, 100, 255))
        :SetTextFunction(function(swep)
            return swep:GetTeleportMode() and "TELEPORT MODE - Click to teleport" or ""
        end)
        :SetProgressFunction(function(swep)
            return swep:GetTeleportMode() and 1 or 0
        end)
        :SetVisibleFunction(function(swep) return swep:GetTeleportMode() end)

    -- Sin level indicator for looked-at player
    hook.Add("HUDPaint", "SCP001S_SinIndicator", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or ply:SCPClass() ~= CLASSES.SCP001S then return end

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "weapon_scp_001s" then return end

        -- Get player we're looking at
        local trace = {}
        trace.start = ply:GetShootPos()
        trace.endpos = trace.start + ply:GetAimVector() * 1000
        trace.filter = ply

        local tr = util.TraceLine(trace)

        if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
            local target = tr.Entity
            local sinLevel = wep:GetPlayerSinLevel(target)
            local sinColor = wep:GetSinColor(sinLevel)

            local dmg = target:GetProperty("sans_damage_dealt", 0)
            local sinText = sinLevel == 1 and "INNOCENT" or (sinLevel == 2 and "SINNER" or "GUILTY")

            local scrW, scrH = ScrW(), ScrH()
            local x, y = scrW / 2, scrH / 2 + 50

            draw.SimpleText(sinText, "DermaLarge", x, y, sinColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Damage: " .. math.floor(dmg), "DermaDefault", x, y + 25, sinColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end)

    -- Draw player outlines based on sin level
    hook.Add("PreDrawHalos", "SCP001S_SinOutlines", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or ply:SCPClass() ~= CLASSES.SCP001S then return end

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "weapon_scp_001s" then return end

        local green, yellow, red = {}, {}, {}

        for _, target in ipairs(player.GetAll()) do
            if target == ply then continue end
            if target:SCPTeam() == TEAM_SPEC then continue end
            if not target:Alive() then continue end

            local sinLevel = wep:GetPlayerSinLevel(target)
            if sinLevel == 1 then
                table.insert(green, target)
            elseif sinLevel == 2 then
                table.insert(yellow, target)
            else
                table.insert(red, target)
            end
        end

        halo.Add(green, Color(0, 255, 0), 2, 2, 1)
        halo.Add(yellow, Color(255, 255, 0), 2, 2, 1)
        halo.Add(red, Color(255, 0, 0), 2, 2, 1)
    end)
end

--[[-------------------------------------------------------------------------
Sounds
---------------------------------------------------------------------------]]
sound.Add({
    name = "SCP001S.BoneAttack",
    volume = 0.8,
    level = 75,
    pitch = {95, 105},
    sound = "physics/concrete/concrete_break2.wav",
    channel = CHAN_WEAPON,
})

sound.Add({
    name = "SCP001S.GasterBlaster",
    volume = 1,
    level = 85,
    pitch = {90, 100},
    sound = "ambient/energy/weld1.wav",
    channel = CHAN_WEAPON,
})

sound.Add({
    name = "SCP001S.Teleport",
    volume = 1,
    level = 80,
    pitch = 100,
    sound = "ambient/machines/teleport1.wav",
    channel = CHAN_STATIC,
})

sound.Add({
    name = "SCP001S.TeleportReady",
    volume = 0.5,
    level = 0,
    pitch = 100,
    sound = "buttons/button17.wav",
    channel = CHAN_STATIC,
})
