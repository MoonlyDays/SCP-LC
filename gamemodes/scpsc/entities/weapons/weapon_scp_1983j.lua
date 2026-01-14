SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-1983-J"
SWEP.HoldType = "normal"
SWEP.ScoreOnDamage = true
-- Primary attack parameters
SWEP.BaseDamage = 20
SWEP.DamagePerTargetKill = 5
SWEP.PrimaryCooldown = 1.5
SWEP.PrimaryRange = 80
-- Secondary attack - highlight target
SWEP.HighlightDuration = 10
SWEP.HighlightCooldown = 60
-- Special attack - audio + insanity
SWEP.InsanityRadius = 400
SWEP.InsanityDuration = 10
SWEP.InsanityCooldown = 120
if SERVER then
    util.AddNetworkString("SLC1983JTarget")
    util.AddNetworkString("SLC1983JHighlight")
end

--[[
	William Afton / Springtrap
	A serial killer trapped inside an animatronic suit, hunting targets assigned by fate.

	ABILITIES:

	Primary Attack (LMB) - "Slaughter"
		Base damage: 20 (+5 per target kill, stacks permanently)
		Cooldown: 1.5 seconds
		Range: 80 units
		- Deals base damage to non-target enemies
		- INSTANTLY KILLS your assigned target
		- Each target kill grants +5 permanent damage bonus
		- New target is assigned after killing current one

	Secondary Attack (RMB) - "Follow Me"
		Cooldown: 60 seconds
		Duration: 2 seconds
		- Highlights your current target through walls with a red halo
		- Helps locate your target when they're hiding

	Special Attack (R) - "It's Me"
		Cooldown: 120 seconds (2 minutes)
		Radius: 400 units
		Effect duration: 10 seconds
		- Plays disturbing audio for all nearby enemies
		- Applies insanity effect (motion blur, screen shake, desaturation)
		- Does not affect SCPs or spectators

	Passive - "Animatronic Stealth"
		- Quieter footsteps (metal vent sounds at reduced volume)
]]
function SWEP:SetupDataTables()
    self:CallBaseClass("SetupDataTables")
    self:NetworkVar("Int", "BonusDamage")
    self:NetworkVar("Int", "TargetKills")
    self:NetworkVar("Float", "NextSecondaryAttack")
    self:NetworkVar("Entity", "CurrentTarget")
    self:NetworkVar("Float", "HighlightEndTime")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self:InitializeLanguage("SCP1983J")
    self:InitializeHUD()
    if SERVER then
        self:SetBonusDamage(0)
        self:SetTargetKills(0)
        self:SetCurrentTarget(NULL)
        self:SetHighlightEndTime(0)
    end
end

function SWEP:Think()
    if ROUND.preparing or ROUND.post then return end
    local ct = CurTime()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if SERVER then
        -- Check if current target is still valid, if not - assign new one
        local target = self:GetCurrentTarget()
        if not IsValid(target) or not self:IsValidTarget(target) then self:AssignNewTarget() end
        -- Clear highlight when expired
        if self:GetHighlightEndTime() > 0 and ct >= self:GetHighlightEndTime() then self:SetHighlightEndTime(0) end
    end
end

function SWEP:IsValidTarget(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    return self:CanTargetPlayer(ply)
end

function SWEP:AssignNewTarget()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local validTargets = {}
    for _, ply in ipairs(player.GetAll()) do
        if self:IsValidTarget(ply) then table.insert(validTargets, ply) end
    end

    if #validTargets > 0 then
        local newTarget = validTargets[math.random(#validTargets)]
        self:SetCurrentTarget(newTarget)
        -- Notify owner about new target
        net.Start("SLC1983JTarget")
        net.WriteEntity(newTarget)
        net.Send(owner)
    else
        self:SetCurrentTarget(NULL)
    end
end

-- Primary Attack: Melee with target mechanic
local attack_trace = {}
attack_trace.mins = Vector(-10, -10, -10)
attack_trace.maxs = Vector(10, 10, 10)
attack_trace.mask = MASK_SHOT
attack_trace.output = attack_trace
function SWEP:PrimaryAttack()
    if ROUND.preparing or ROUND.post then return end
    self:SetNextPrimaryFire(CurTime() + self.PrimaryCooldown * self:GetUpgradeMod("primary_cd", 1))
    if not SERVER then return end
    local owner = self:GetOwner()
    local spos = owner:GetShootPos()
    attack_trace.start = spos
    attack_trace.endpos = spos + owner:GetAimVector() * self.PrimaryRange
    attack_trace.filter = owner
    owner:LagCompensation(true)
    util.TraceHull(attack_trace)
    owner:LagCompensation(false)
    local ent = attack_trace.Entity
    if IsValid(ent) and ent:IsPlayer() and self:CanTargetPlayer(ent) then
        local currentTarget = self:GetCurrentTarget()
        local isTarget = IsValid(currentTarget) and ent == currentTarget
        if isTarget then
            -- Target dies instantly
            owner:EmitSound("SCP1983J.TargetKill")
            local dmg = DamageInfo()
            dmg:SetDamage(ent:Health())
            dmg:SetDamageType(DMG_DIRECT)
            dmg:SetAttacker(owner)
            dmg:SetInflictor(self)
            ent:TakeDamageInfo(dmg)
            -- Increase bonus damage
            self:SetBonusDamage(self:GetBonusDamage() + self.DamagePerTargetKill)
            self:SetTargetKills(self:GetTargetKills() + 1)
            -- Assign new target
            self:AssignNewTarget()
        else
            -- Normal attack
            owner:EmitSound("SCP1983J.Hit")
            local damage = self.BaseDamage + self:GetBonusDamage()
            damage = damage * self:GetUpgradeMod("primary_dmg", 1)
            local dmg = DamageInfo()
            dmg:SetDamage(damage)
            dmg:SetDamageType(DMG_SLASH)
            dmg:SetAttacker(owner)
            dmg:SetInflictor(self)
            ent:TakeDamageInfo(dmg)
        end
    else
        owner:EmitSound("SCP1983J.Miss")
    end

    AddRoundStat("1983j")
end

-- Secondary Attack: Highlight target
function SWEP:SecondaryAttack()
    if ROUND.preparing or ROUND.post then return end
    local ct = CurTime()
    if self:GetNextSecondaryAttack() > ct then return end
    local target = self:GetCurrentTarget()
    if not IsValid(target) then
        if SERVER then
            local owner = self:GetOwner()
            if IsValid(owner) then owner:ChatPrint("[SCP-1983-J] No target assigned!") end
        end
        return
    end

    self:SetNextSecondaryAttack(ct + self.HighlightCooldown * self:GetUpgradeMod("highlight_cd", 1))
    if not SERVER then return end
    local owner = self:GetOwner()
    local duration = self.HighlightDuration * self:GetUpgradeMod("highlight_duration", 1)
    self:SetHighlightEndTime(ct + duration)
    owner:EmitSound("SCP1983J.Highlight")
    -- Network highlight to client
    net.Start("SLC1983JHighlight")
    net.WriteEntity(target)
    net.WriteFloat(duration)
    net.Send(owner)
end

-- Special Attack: Audio + Insanity effect
function SWEP:SpecialAttack()
    if ROUND.preparing or ROUND.post then return end
    local ct = CurTime()
    if self:GetNextSpecialAttack() > ct then return end
    self:SetNextSpecialAttack(ct + self.InsanityCooldown * self:GetUpgradeMod("insanity_cd", 1))
    if not SERVER then return end
    local owner = self:GetOwner()
    local pos = owner:GetPos()
    local radius = self.InsanityRadius * self:GetUpgradeMod("insanity_radius", 1)
    local duration = self.InsanityDuration * self:GetUpgradeMod("insanity_duration", 1)
    -- Play the audio for nearby players
    owner:EmitSound("SCP1983J.Insanity")
    local affected = 0
    for _, ply in ipairs(player.GetAll()) do
        if not self:CanTargetPlayer(ply) then continue end
        if ply:GetPos():Distance(pos) > radius then continue end
        ply:ApplyEffect("scp1983j_insanity", 1, duration)
        affected = affected + 1
    end

    if affected > 0 then owner:ChatPrint("[SCP-1983-J] Affected " .. affected .. " player(s) with insanity!") end
end

function SWEP:OnPlayerKilled(ply)
    AddRoundStat("1983j")
end

function SWEP:OnRemove()
    if not SERVER then return end
    -- Cleanup if needed
end

--[[-------------------------------------------------------------------------
SCP Hooks
---------------------------------------------------------------------------]]
SCPHook("SCP1983J", "SLCPlayerFootstep", function(ply, foot, snd)
    if ply:SCPClass() ~= CLASSES.SCP1983J then return end
    -- Quieter footsteps like an animatronic
    ply:EmitSound("MetalVent.StepLeft", 50)
    return true
end)

--[[-------------------------------------------------------------------------
Insanity Effect (blur/visual distortion)
---------------------------------------------------------------------------]]
local scp_spec_filter = function(ply)
    local t = ply:SCPTeam()
    return t ~= TEAM_SPEC and t ~= TEAM_SCP
end

EFFECTS.RegisterEffect("scp1983j_insanity", {
    duration = 10,
    stacks = 0,
    tiers = {
        {
            icon = Material("slc/hud/effects/insane.png")
        }
    },
    cantarget = scp_spec_filter,
    begin = function(self, ply, tier, args, refresh)
        if #args > 0 then self.duration = args[1] end
        if CLIENT then ply:EmitSound("SCP1983J.InsanityEffect") end
    end,
    finish = function(self, ply, tier, args, interrupt) if CLIENT then ply:StopSound("SCP1983J.InsanityEffect") end end,
})

if CLIENT then
    local insanity_blur = 0
    local insanity_shake = 0
    hook.Add("RenderScreenspaceEffects", "SCP1983J_Insanity", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply.HasEffect then return end
        local has_effect = ply:HasEffect("scp1983j_insanity")
        local target = has_effect and 1 or 0
        insanity_blur = Lerp(FrameTime() * (has_effect and 6 or 3), insanity_blur, target)
        if insanity_blur > 0.01 then DrawMotionBlur(0.1, insanity_blur * 0.8, 0.01) end
    end)

    hook.Add("SLCCalcView", "SCP1983J_Insanity", function(ply, view)
        if not ply.HasEffect then return end
        local has_effect = ply:HasEffect("scp1983j_insanity")
        if not has_effect then return end
        insanity_shake = insanity_shake + FrameTime() * 8
        view.angles.roll = view.angles.roll + math.sin(insanity_shake) * 1.5
        view.angles.pitch = view.angles.pitch + math.cos(insanity_shake * 0.7) * 1
    end)

    hook.Add("SLCScreenMod", "SCP1983J_Insanity", function(data)
        local ply = LocalPlayer()
        if not ply.HasEffect or not ply:HasEffect("scp1983j_insanity") then return end
        data.contrast = data.contrast * 0.8
        data.brightness = data.brightness - 0.02
        data.colour = data.colour * 0.7
    end)
end

--[[-------------------------------------------------------------------------
Upgrade system

UPGRADES:
	primary1 - "I Always Come Back I" (Cost: 1)
		- Attack cooldown reduced by 15%

	primary2 - "I Always Come Back II" (Cost: 2, requires primary1)
		- Attack damage increased by 25%

	highlight1 - "Follow Me" (Cost: 1)
		- Highlight cooldown reduced by 25%
		- Highlight duration increased by 50%

	insanity1 - "It's Me I" (Cost: 1)
		- Insanity ability cooldown reduced by 15%

	insanity2 - "It's Me II" (Cost: 2, requires insanity1)
		- Insanity radius increased by 25%
		- Insanity duration increased by 50%

	outside_buff - "The Man Behind the Slaughter" (Cost: 1)
		- Reduces damage penalty when outside the facility
---------------------------------------------------------------------------]]
local icons = {}
if CLIENT then
    icons.primary = GetMaterial("slc/hud/upgrades/scp/1983j/primary.png", "smooth")
    icons.highlight = GetMaterial("slc/hud/upgrades/scp/1983j/highlight.png", "smooth")
    icons.insanity = GetMaterial("slc/hud/upgrades/scp/1983j/insanity.png", "smooth")
end

DefineUpgradeSystem("scp1983j", {
    grid_x = 3,
    grid_y = 3,
    upgrades = {
        -- "I Always Come Back I" - Attack cooldown -15%
        {
            name = "primary1",
            cost = 1,
            req = {},
            reqany = false,
            pos = {1, 1},
            mod = {
                primary_cd = 0.85
            },
            icon = icons.primary
        },
        -- "I Always Come Back II" - Attack damage +25%
        {
            name = "primary2",
            cost = 2,
            req = {"primary1"},
            reqany = false,
            pos = {1, 2},
            mod = {
                primary_dmg = 1.25
            },
            icon = icons.primary
        },
        -- "Follow Me" - Highlight cooldown -25%, duration +50%
        {
            name = "highlight1",
            cost = 1,
            req = {},
            reqany = false,
            pos = {2, 1},
            mod = {
                highlight_cd = 0.75,
                highlight_duration = 1.5
            },
            icon = icons.highlight
        },
        -- "It's Me I" - Insanity cooldown -15%
        {
            name = "insanity1",
            cost = 1,
            req = {},
            reqany = false,
            pos = {3, 1},
            mod = {
                insanity_cd = 0.85
            },
            icon = icons.insanity
        },
        -- "It's Me II" - Insanity radius +25%, duration +50%
        {
            name = "insanity2",
            cost = 2,
            req = {"insanity1"},
            reqany = false,
            pos = {3, 2},
            mod = {
                insanity_radius = 1.25,
                insanity_duration = 1.5
            },
            icon = icons.insanity
        },
        -- "The Man Behind the Slaughter" - Outside facility buff
        {
            name = "outside_buff",
            cost = 1,
            req = {},
            reqany = false,
            pos = {2, 3},
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
    local hud = SCPHUDObject("SCP1983J", SWEP)
    hud:AddCommonSkills()
    hud:AddSkill("attack"):SetButton("attack"):SetMaterial("slc/hud/scp/049/choke.png", "smooth"):SetCooldownFunction("GetNextPrimaryFire")
    hud:AddSkill("highlight"):SetButton("attack2"):SetMaterial("slc/hud/scp/049/choke.png", "smooth"):SetCooldownFunction("GetNextSecondaryAttack")
    hud:AddSkill("insanity"):SetButton("scp_special"):SetMaterial("slc/hud/scp/049/choke.png", "smooth"):SetCooldownFunction("GetNextSpecialAttack")
    hud:AddBar("damage"):SetMaterial("slc/hud/scp/049/choke.png", "smooth"):SetColor(Color(139, 0, 0)):SetTextFunction(function(swep)
        local bonus = swep:GetBonusDamage()
        local kills = swep:GetTargetKills()
        return "DMG: " .. (swep.BaseDamage + bonus) .. " | Kills: " .. kills
    end):SetProgressFunction(function(swep) return math.Clamp(swep:GetBonusDamage() / 50, 0, 1) end):SetVisibleFunction(function(swep) return true end)

    -- Target highlighting
    local highlightTarget = NULL
    local highlightEndTime = 0
    net.Receive("SLC1983JTarget", function()
        local target = net.ReadEntity()
        local ply = LocalPlayer()
        if IsValid(ply) then ply:ChatPrint("[SCP-1983-J] New target: " .. (IsValid(target) and target:Nick() or "None")) end
    end)

    net.Receive("SLC1983JHighlight", function()
        highlightTarget = net.ReadEntity()
        highlightEndTime = CurTime() + net.ReadFloat()
    end)

    hook.Add("PreDrawHalos", "SCP1983J_Highlight", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "weapon_scp_1983j" then return end
        -- Highlight target if active
        if IsValid(highlightTarget) and highlightEndTime > CurTime() then halo.Add({highlightTarget}, Color(255, 0, 0), 3, 3, 2, true, true) end
        -- Always show current target with subtle halo
        local target = wep:GetCurrentTarget()
        if IsValid(target) and (not IsValid(highlightTarget) or highlightEndTime <= CurTime()) then halo.Add({target}, Color(139, 0, 0, 255), 3, 3, 2, true, false) end
    end)
end

--[[-------------------------------------------------------------------------
Sounds
---------------------------------------------------------------------------]]
sound.Add({
    name = "SCP1983J.Hit",
    volume = 1,
    level = 80,
    pitch = {95, 105},
    sound = "physics/body/body_medium_impact_hard1.wav",
    channel = CHAN_WEAPON,
})

sound.Add({
    name = "SCP1983J.Miss",
    volume = 0.8,
    level = 70,
    pitch = {90, 110},
    sound = "npc/zombie/claw_miss1.wav",
    channel = CHAN_WEAPON,
})

sound.Add({
    name = "SCP1983J.TargetKill",
    volume = 1,
    level = 85,
    pitch = 80,
    sound = "physics/body/body_medium_break2.wav",
    channel = CHAN_WEAPON,
})

sound.Add({
    name = "SCP1983J.Highlight",
    volume = 1,
    level = 70,
    pitch = 100,
    sound = "buttons/button17.wav",
    channel = CHAN_ITEM,
})

sound.Add({
    name = "SCP1983J.Insanity",
    volume = 1,
    level = 90,
    sound = "scp_lc/scp/1983/purpleguy.ogg",
    channel = CHAN_STATIC,
})

sound.Add({
    name = "SCP1983J.InsanityEffect",
    volume = 0.5,
    level = 0,
    pitch = 100,
    sound = "ambient/wind/wind_snippet2.wav",
    channel = CHAN_STATIC,
})
