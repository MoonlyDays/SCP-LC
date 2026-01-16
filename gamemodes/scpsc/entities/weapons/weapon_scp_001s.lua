SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-001-S"
SWEP.HoldType = "normal"
SWEP.ScoreOnDamage = true
SWEP.ScoreOnKill = true

-- Ability cooldowns and parameters
SWEP.BoneAttackCooldown = 1
SWEP.BoneAttackDamage = 1
SWEP.BoneAttackRange = 500
SWEP.BoneProjectileSpeed = 1500

SWEP.BlasterCooldown = 5
SWEP.BlasterDamage = 25
SWEP.BlasterRange = 600
SWEP.BlasterWidth = 50

SWEP.TeleportCooldown = 120
SWEP.TeleportStaminaCost = 100

SWEP.MaxStamina = 500
SWEP.StaminaRegen = 2 -- Per second, very slow

-- Sin thresholds
SWEP.SinThresholdYellow = 50
SWEP.SinThresholdRed = 100

--[[
    SCP-001-S - The Judge

    A mysterious skeletal entity that manifests to pass judgment upon those who have committed violence.

    Passive - Karmic Judgment: Tracks damage dealt by all players. Outlines based on sin level.
    Passive - Stamina Shield: Cannot be killed while stamina remains. Damage depletes stamina instead.
    LMB - Bone Attack: Launch a bone projectile. Multi-hit + bleeding for sinners.
    RMB - Gaster Blaster: Fire a devastating beam attack.
    Special - Shortcut: Teleport to a selected area. Consumes stamina.
]]

function SWEP:SetupDataTables()
    self:CallBaseClass("SetupDataTables")
    self:NetworkVar("Float", "Stamina")
    self:NetworkVar("Float", "MaxStaminaNet")
    self:NetworkVar("Float", "NextBlaster")
    self:NetworkVar("Float", "NextTeleport")
    self:NetworkVar("Bool", "TeleportMode")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self:InitializeLanguage("SCP001S")
    self:InitializeHUD()

    if SERVER then
        self:SetStamina(self.MaxStamina)
        self:SetMaxStaminaNet(self.MaxStamina)
    end
end

function SWEP:Think()
    if ROUND.preparing or ROUND.post then return end
    local ct = CurTime()
    local owner = self:GetOwner()

    if SERVER then
        -- Regenerate stamina slowly
        if not self.NextStaminaRegen or self.NextStaminaRegen <= ct then
            self.NextStaminaRegen = ct + 1
            local stamina = self:GetStamina()
            local maxStamina = self:GetMaxStaminaNet()
            if stamina < maxStamina then
                local newStamina = math.min(stamina + self.StaminaRegen * self:GetUpgradeMod("stamina_regen", 1), maxStamina)
                self:SetStamina(newStamina)
            end
        end

        -- Update player outlines based on sin levels
        if not self.NextOutlineUpdate or self.NextOutlineUpdate <= ct then
            self.NextOutlineUpdate = ct + 0.5
            self:UpdatePlayerOutlines(owner)
        end
    end
end

-- Get a player's sin level based on damage dealt this round
function SWEP:GetPlayerSinLevel(ply)
    if not IsValid(ply) then return 0 end
    local damage = ply:GetProperty("scp001s_damage_dealt", 0)

    if damage >= self.SinThresholdRed then
        return 3 -- Red - Murderer
    elseif damage >= self.SinThresholdYellow then
        return 2 -- Yellow - Sinner
    else
        return 1 -- Green - Innocent
    end
end

-- Get sin color for outline
function SWEP:GetSinColor(sinLevel)
    if sinLevel >= 3 then
        return Color(255, 0, 0) -- Red
    elseif sinLevel >= 2 then
        return Color(255, 255, 0) -- Yellow
    else
        return Color(0, 255, 0) -- Green
    end
end

-- Update player outlines for the SCP owner
function SWEP:UpdatePlayerOutlines(owner)
    if not IsValid(owner) then return end

    -- This would need a custom networking system to show outlines to the SCP
    -- For now, we'll use the existing property system
    for _, ply in ipairs(player.GetAll()) do
        if ply == owner or ply:SCPTeam() == TEAM_SPEC then continue end
        local sinLevel = self:GetPlayerSinLevel(ply)
        ply:SetProperty("scp001s_sin_level", sinLevel)
    end
end

-- Primary Attack: Bone projectile
local attack_trace = {}
attack_trace.mask = MASK_SHOT
attack_trace.output = attack_trace

function SWEP:PrimaryAttack()
    if ROUND.preparing or ROUND.post then return end
    if self:GetTeleportMode() then return end

    self:SetNextPrimaryFire(CurTime() + self.BoneAttackCooldown * self:GetUpgradeMod("bone_cd", 1))

    if not SERVER then return end

    local owner = self:GetOwner()
    local spos = owner:GetShootPos()
    local dir = owner:GetAimVector()

    attack_trace.start = spos
    attack_trace.endpos = spos + dir * self.BoneAttackRange
    attack_trace.filter = owner

    owner:LagCompensation(true)
    util.TraceLine(attack_trace)
    owner:LagCompensation(false)

    -- Play bone attack sound
    owner:EmitSound("SCP001S.BoneAttack")

    -- Create visual effect (bone projectile trail)
    local effectdata = EffectData()
    effectdata:SetStart(spos)
    effectdata:SetOrigin(attack_trace.HitPos)
    effectdata:SetEntity(owner)
    util.Effect("SLC_SCP001S_Bone", effectdata, true, true)

    local ent = attack_trace.Entity
    if not IsValid(ent) then return end

    if not ent:IsPlayer() then
        self:SCPDamageEvent(ent, 50)
        return
    end

    if not self:CanTargetPlayer(ent) then return end

    local sinLevel = self:GetPlayerSinLevel(ent)
    local baseDamage = self.BoneAttackDamage * self:GetUpgradeMod("bone_dmg", 1)

    -- Calculate hits and effects based on sin level
    local hits = 1
    local bleedTier = 0

    if sinLevel >= 2 then
        hits = 3 -- Multi-hit for sinners
        bleedTier = 1 -- Light bleeding
    end

    if sinLevel >= 3 then
        hits = 5 -- More hits for murderers
        bleedTier = 2 -- Severe bleeding
    end

    -- Apply damage
    local totalDamage = baseDamage * hits
    local dmg = DamageInfo()
    dmg:SetDamage(totalDamage)
    dmg:SetDamageType(DMG_SLASH)
    dmg:SetAttacker(owner)
    dmg:SetInflictor(self)
    ent:TakeDamageInfo(dmg)

    -- Apply karma bleeding effect
    if bleedTier > 0 then
        ent:ApplyEffect("karma_bleed", bleedTier, owner)
    end

    AddRoundStat("001s_bone")
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

    self:SetNextBlaster(ct + self.BlasterCooldown * self:GetUpgradeMod("blaster_cd", 1))
    self:SetNextSecondaryFire(ct + 0.5)

    if not SERVER then return end

    local owner = self:GetOwner()
    local spos = owner:GetShootPos()
    local dir = owner:GetAimVector()

    -- Play blaster sound
    owner:EmitSound("SCP001S.GasterBlaster")

    -- Create beam effect
    local effectdata = EffectData()
    effectdata:SetStart(spos)
    effectdata:SetOrigin(spos + dir * self.BlasterRange)
    effectdata:SetEntity(owner)
    effectdata:SetRadius(self.BlasterWidth)
    util.Effect("SLC_SCP001S_Blaster", effectdata, true, true)

    -- Damage all players in beam path
    local baseDamage = self.BlasterDamage * self:GetUpgradeMod("blaster_dmg", 1)
    local range = self.BlasterRange * self:GetUpgradeMod("blaster_range", 1)
    local width = self.BlasterWidth

    owner:LagCompensation(true)
    for _, ply in ipairs(player.GetAll()) do
        if ply == owner or not self:CanTargetPlayer(ply) then continue end

        -- Check if player is in beam path
        local plyPos = ply:GetPos() + Vector(0, 0, 40)
        local toPlayer = plyPos - spos
        local dist = toPlayer:Dot(dir)

        if dist < 0 or dist > range then continue end

        local closestPoint = spos + dir * dist
        local perpDist = (plyPos - closestPoint):Length()

        if perpDist > width then continue end

        local sinLevel = self:GetPlayerSinLevel(ply)
        local damage = baseDamage

        -- Bonus damage to sinners
        if sinLevel >= 2 then
            damage = damage * 1.5
        end
        if sinLevel >= 3 then
            damage = damage * 2
        end

        local dmg = DamageInfo()
        dmg:SetDamage(damage)
        dmg:SetDamageType(DMG_ENERGYBEAM)
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        ply:TakeDamageInfo(dmg)

        -- Apply karma bleeding to sinners
        if sinLevel >= 2 then
            ply:ApplyEffect("karma_bleed", sinLevel - 1, owner)
        end
    end
    owner:LagCompensation(false)

    AddRoundStat("001s_blaster")
end

-- Special Attack: Teleport
function SWEP:SpecialAttack()
    if ROUND.preparing or ROUND.post then return end

    local ct = CurTime()

    if self:GetTeleportMode() then
        -- Execute teleport
        if self:GetNextTeleport() > ct then
            self:SetTeleportMode(false)
            return
        end

        local staminaCost = self.TeleportStaminaCost * self:GetUpgradeMod("teleport_cost", 1)
        if self:GetStamina() < staminaCost then
            if SERVER then self:HUDNotify("Not enough stamina!", 2) end
            self:SetTeleportMode(false)
            return
        end

        if not SERVER then
            self:SetTeleportMode(false)
            return
        end

        local owner = self:GetOwner()
        local spos = owner:GetShootPos()
        local dir = owner:GetAimVector()

        -- Trace for teleport destination
        local tr = util.TraceLine({
            start = spos,
            endpos = spos + dir * 5000,
            filter = owner,
            mask = MASK_PLAYERSOLID
        })

        if tr.Hit then
            -- Find valid ground position
            local groundTr = util.TraceLine({
                start = tr.HitPos + Vector(0, 0, 50),
                endpos = tr.HitPos - Vector(0, 0, 100),
                filter = owner,
                mask = MASK_PLAYERSOLID
            })

            if groundTr.Hit then
                -- Consume stamina
                self:SetStamina(self:GetStamina() - staminaCost)
                self:SetNextTeleport(ct + self.TeleportCooldown * self:GetUpgradeMod("teleport_cd", 1))

                -- Teleport effect at origin
                owner:EmitSound("SCP001S.Teleport")

                local effectdata = EffectData()
                effectdata:SetOrigin(owner:GetPos())
                util.Effect("SLC_SCP001S_Teleport", effectdata, true, true)

                -- Move player
                owner:SetPos(groundTr.HitPos + Vector(0, 0, 5))

                -- Teleport effect at destination
                effectdata = EffectData()
                effectdata:SetOrigin(owner:GetPos())
                util.Effect("SLC_SCP001S_Teleport", effectdata, true, true)

                AddRoundStat("001s_teleport")
            end
        end

        self:SetTeleportMode(false)
    else
        -- Enter teleport mode
        if self:GetNextTeleport() > ct then return end
        self:SetTeleportMode(true)
        if SERVER then self:HUDNotify("Teleport mode: Press SPECIAL to confirm, RMB to cancel", 3) end
    end
end

-- Override CanTargetPlayer to allow targeting all factions including SCPs
function SWEP:CanTargetPlayer(ply)
    local t = ply:SCPTeam()
    -- Can target everyone except spectators and self
    return t ~= TEAM_SPEC and not ply:HasGodMode() and not ply:HasEffect("spawn_protection") and ply ~= self:GetOwner()
end

function SWEP:OnRemove()
    if not SERVER then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
end

--[[-------------------------------------------------------------------------
SCP Hooks - Stamina Shield & Damage Tracking
---------------------------------------------------------------------------]]

-- Stamina Shield - redirect damage to stamina (only needs to run when SCP is active)
SCPHook("SCP001S", "EntityTakeDamage", function(target, dmginfo)
    if not IsValid(target) or not target:IsPlayer() then return end
    if target:SCPClass() ~= CLASSES.SCP001S then return end

    local wep = target:GetSCPWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_scp_001s" then return end

    local damage = dmginfo:GetDamage()
    local stamina = wep:GetStamina()

    if stamina > 0 then
        -- Absorb damage with stamina
        local newStamina = stamina - damage

        if newStamina <= 0 then
            -- Stamina depleted, allow remaining damage through
            wep:SetStamina(0)
            dmginfo:SetDamage(-newStamina) -- Remaining damage
            target:EmitSound("SCP001S.StaminaDepleted")
        else
            -- Fully absorbed by stamina
            wep:SetStamina(newStamina)
            dmginfo:SetDamage(0)
            return true -- Block damage
        end
    end
end)

--[[-------------------------------------------------------------------------
Global Damage Tracking - Runs from round start (not tied to SCP spawning)
Uses regular hooks so damage is tracked BEFORE SCP-001-S spawns
---------------------------------------------------------------------------]]
if SERVER then
    -- Track damage dealt by ANYONE to ANYONE from round start
    hook.Add("SLCRound", "SCP001S_InitDamageTracking", function()
        -- Clear damage tracking for all players
        for _, ply in ipairs(player.GetAll()) do
            ply:SetProperty("scp001s_damage_dealt", 0)
            ply:SetProperty("scp001s_sin_level", 0)
        end

        -- Add round hook to track all damage during this round
        AddRoundHook("PostEntityTakeDamage", "SCP001S_DamageTracking", function(target, dmginfo, took)
            if not took then return end

            local attacker = dmginfo:GetAttacker()
            if not IsValid(attacker) or not attacker:IsPlayer() then return end

            -- Target must be a valid player (not spectator)
            if not IsValid(target) or not target:IsPlayer() then return end
            if target:SCPTeam() == TEAM_SPEC then return end
            if attacker:SCPTeam() == TEAM_SPEC then return end
            if attacker == target then return end -- Ignore self-damage

            -- Track damage dealt by the attacker (regardless of their team or target's team)
            local currentDamage = attacker:GetProperty("scp001s_damage_dealt", 0)
            attacker:SetProperty("scp001s_damage_dealt", currentDamage + dmginfo:GetDamage())
        end)
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
    icons.stamina = GetMaterial("slc/hud/upgrades/scp/001s/stamina.png", "smooth")
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
                blaster_dmg = 1.25,
                blaster_range = 1.2
            },
            icon = icons.blaster
        },
        {
            name = "stamina1",
            cost = 1,
            req = {},
            reqany = false,
            pos = {3, 1},
            mod = {
                stamina_regen = 1.5
            },
            icon = icons.stamina
        },
        {
            name = "stamina2",
            cost = 2,
            req = {"stamina1"},
            reqany = false,
            pos = {3, 2},
            mod = {
                teleport_cost = 0.75
            },
            icon = icons.stamina
        },
        {
            name = "teleport1",
            cost = 2,
            req = {"stamina2"},
            reqany = false,
            pos = {3, 3},
            mod = {
                teleport_cd = 0.7
            },
            icon = icons.teleport
        },
    },
    rewards = {{100, 1}, {200, 1}, {350, 1}, {500, 1}, {700, 1}}
}, SWEP)

--[[-------------------------------------------------------------------------
SCP HUD
---------------------------------------------------------------------------]]
if CLIENT then
    local sin_colors = {
        [1] = Color(0, 255, 0),    -- Green - Innocent
        [2] = Color(255, 255, 0),  -- Yellow - Sinner
        [3] = Color(255, 0, 0),    -- Red - Murderer
    }

    local hud = SCPHUDObject("SCP001S", SWEP)
    hud:AddCommonSkills()

    hud:AddSkill("bone_attack"):SetButton("attack"):SetMaterial("slc/hud/scp/001s/bone.png", "smooth"):SetCooldownFunction("GetNextPrimaryFire")
    hud:AddSkill("gaster_blaster"):SetButton("attack2"):SetMaterial("slc/hud/scp/001s/blaster.png", "smooth"):SetCooldownFunction("GetNextBlaster")
    hud:AddSkill("shortcut"):SetButton("scp_special"):SetMaterial("slc/hud/scp/001s/teleport.png", "smooth"):SetCooldownFunction("GetNextTeleport")

    -- Stamina bar (main resource)
    hud:AddBar("stamina"):SetMaterial("slc/hud/scp/001s/stamina.png", "smooth"):SetColor(Color(100, 150, 255)):SetTextFunction(function(swep)
        return math.floor(swep:GetStamina()) .. " / " .. math.floor(swep:GetMaxStaminaNet())
    end):SetProgressFunction(function(swep)
        return swep:GetStamina() / swep:GetMaxStaminaNet()
    end)

    -- Teleport mode indicator
    hud:AddBar("teleport_mode"):SetMaterial("slc/hud/scp/001s/teleport.png", "smooth"):SetColor(Color(150, 100, 255)):SetTextFunction(function(swep)
        return swep:GetTeleportMode() and "TELEPORT MODE" or ""
    end):SetProgressFunction(function(swep)
        return swep:GetTeleportMode() and 1 or 0
    end):SetVisibleFunction(function(swep)
        return swep:GetTeleportMode()
    end)

    -- Draw sin level outlines on players
    hook.Add("PreDrawHalos", "SCP001S_SinOutlines", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or ply:SCPClass() ~= CLASSES.SCP001S then return end

        for sinLevel, color in pairs(sin_colors) do
            local players_at_level = {}
            for _, target in ipairs(player.GetAll()) do
                if target == ply or target:SCPTeam() == TEAM_SPEC then continue end
                local targetSin = target:GetProperty("scp001s_sin_level", 0)
                if targetSin == sinLevel then
                    table.insert(players_at_level, target)
                end
            end

            if #players_at_level > 0 then
                halo.Add(players_at_level, color, 2, 2, 1, true, true)
            end
        end
    end)
end

--[[-------------------------------------------------------------------------
Sounds
---------------------------------------------------------------------------]]
sound.Add({
    name = "SCP001S.BoneAttack",
    volume = 1,
    level = 75,
    pitch = {95, 105},
    sound = "physics/body/body_medium_impact_hard1.wav",
    channel = CHAN_WEAPON,
})

sound.Add({
    name = "SCP001S.GasterBlaster",
    volume = 1,
    level = 85,
    pitch = {90, 100},
    sound = "ambient/energy/whiteflash.wav",
    channel = CHAN_WEAPON,
})

sound.Add({
    name = "SCP001S.Teleport",
    volume = 0.8,
    level = 70,
    pitch = {95, 105},
    sound = "ambient/machines/teleport1.wav",
    channel = CHAN_STATIC,
})

sound.Add({
    name = "SCP001S.StaminaDepleted",
    volume = 1,
    level = 60,
    pitch = 100,
    sound = "player/suit_sprint.wav",
    channel = CHAN_STATIC,
})
