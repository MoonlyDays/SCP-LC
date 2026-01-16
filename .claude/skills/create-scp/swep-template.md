# SCP SWEP Template

This is the complete template for creating an SCP weapon file.

## Basic Template

```lua
SWEP.Base = "weapon_scp_base"
SWEP.PrintName = "SCP-XXX"
SWEP.HoldType = "normal"  -- or "knife", "melee", "fist"
SWEP.ScoreOnDamage = true
SWEP.ScoreOnKill = true

-- Ability parameters (customize these)
SWEP.PrimaryCooldown = 1
SWEP.PrimaryDamage = 25
SWEP.PrimaryRange = 100

SWEP.SecondaryCooldown = 5
SWEP.SecondaryDamage = 50

SWEP.SpecialCooldown = 60

--[[
    SCP-XXX - Name

    Description of the SCP and its abilities.
]]

function SWEP:SetupDataTables()
    self:CallBaseClass("SetupDataTables")
    -- Add your networked variables here
    self:NetworkVar("Float", "NextSecondary")
    self:NetworkVar("Float", "NextSpecial")
    -- self:NetworkVar("Int", "Stacks")
    -- self:NetworkVar("Bool", "AbilityActive")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self:InitializeLanguage("SCPXXX")  -- Must match language key
    self:InitializeHUD()
end

function SWEP:Think()
    if CLIENT or ROUND.preparing or ROUND.post then return end
    local ct = CurTime()
    local owner = self:GetOwner()

    -- Add periodic logic here (regeneration, passive effects, etc.)
end

--[[-------------------------------------------------------------------------
Primary Attack (LMB)
---------------------------------------------------------------------------]]
local attack_trace = {}
attack_trace.mask = MASK_SHOT
attack_trace.output = attack_trace

function SWEP:PrimaryAttack()
    if ROUND.preparing or ROUND.post then return end

    local ct = CurTime()
    self:SetNextPrimaryFire(ct + self.PrimaryCooldown * self:GetUpgradeMod("primary_cd", 1))

    if not SERVER then return end

    local owner = self:GetOwner()
    local spos = owner:GetShootPos()
    local dir = owner:GetAimVector()

    attack_trace.start = spos
    attack_trace.endpos = spos + dir * self.PrimaryRange
    attack_trace.filter = owner

    owner:LagCompensation(true)
    util.TraceLine(attack_trace)
    owner:LagCompensation(false)

    -- Play sound
    owner:EmitSound("SCPXXX.Attack")

    local ent = attack_trace.Entity
    if not IsValid(ent) then return end

    -- Damage non-players (doors, props)
    if not ent:IsPlayer() then
        self:SCPDamageEvent(ent, 50)
        return
    end

    -- Check if valid target
    if not self:CanTargetPlayer(ent) then return end

    -- Deal damage
    local dmg = DamageInfo()
    dmg:SetDamage(self.PrimaryDamage * self:GetUpgradeMod("primary_dmg", 1))
    dmg:SetDamageType(DMG_SLASH)
    dmg:SetAttacker(owner)
    dmg:SetInflictor(self)
    ent:TakeDamageInfo(dmg)

    -- Optional: Apply effect
    -- ent:ApplyEffect("effect_name", 1, owner)

    AddRoundStat("xxx_primary")
end

--[[-------------------------------------------------------------------------
Secondary Attack (RMB)
---------------------------------------------------------------------------]]
function SWEP:SecondaryAttack()
    if ROUND.preparing or ROUND.post then return end

    local ct = CurTime()
    if self:GetNextSecondary() > ct then return end

    self:SetNextSecondary(ct + self.SecondaryCooldown * self:GetUpgradeMod("secondary_cd", 1))
    self:SetNextSecondaryFire(ct + 0.5)

    if not SERVER then return end

    local owner = self:GetOwner()

    -- Play sound
    owner:EmitSound("SCPXXX.Secondary")

    -- Implement secondary ability here

    AddRoundStat("xxx_secondary")
end

--[[-------------------------------------------------------------------------
Special Attack (SCP Special Key, usually G)
---------------------------------------------------------------------------]]
function SWEP:SpecialAttack()
    if ROUND.preparing or ROUND.post then return end

    local ct = CurTime()
    if self:GetNextSpecial() > ct then return end

    self:SetNextSpecial(ct + self.SpecialCooldown * self:GetUpgradeMod("special_cd", 1))

    if not SERVER then return end

    local owner = self:GetOwner()

    -- Play sound
    owner:EmitSound("SCPXXX.Special")

    -- Implement special ability here

    AddRoundStat("xxx_special")
end

--[[-------------------------------------------------------------------------
Optional: Override CanTargetPlayer for special targeting rules
---------------------------------------------------------------------------]]
-- function SWEP:CanTargetPlayer(ply)
--     local t = ply:SCPTeam()
--     return t ~= TEAM_SPEC
--         and not ply:HasGodMode()
--         and not ply:HasEffect("spawn_protection")
--         and ply ~= self:GetOwner()
-- end

--[[-------------------------------------------------------------------------
Optional: Track kills
---------------------------------------------------------------------------]]
function SWEP:OnPlayerKilled(ply)
    AddRoundStat("xxx_kills")
end

--[[-------------------------------------------------------------------------
SCP Hooks (only run when this SCP is active)
---------------------------------------------------------------------------]]
-- Example: Passive ability that triggers on certain events
-- SCPHook("SCPXXX", "PlayerDeath", function(victim, inflictor, attacker)
--     -- Do something when a player dies
-- end)

--[[-------------------------------------------------------------------------
Upgrade System
---------------------------------------------------------------------------]]
local icons = {}
if CLIENT then
    icons.primary = GetMaterial("slc/hud/upgrades/scp/xxx/primary.png", "smooth")
    icons.secondary = GetMaterial("slc/hud/upgrades/scp/xxx/secondary.png", "smooth")
    icons.special = GetMaterial("slc/hud/upgrades/scp/xxx/special.png", "smooth")
end

DefineUpgradeSystem("scpxxx", {
    grid_x = 3,
    grid_y = 3,
    upgrades = {
        {
            name = "primary1",
            cost = 1,
            req = {},
            reqany = false,
            pos = {1, 1},
            mod = {
                primary_cd = 0.8  -- 20% cooldown reduction
            },
            icon = icons.primary
        },
        {
            name = "primary2",
            cost = 2,
            req = {"primary1"},
            reqany = false,
            pos = {1, 2},
            mod = {
                primary_dmg = 1.25  -- 25% damage increase
            },
            icon = icons.primary
        },
        {
            name = "secondary1",
            cost = 1,
            req = {},
            reqany = false,
            pos = {2, 1},
            mod = {
                secondary_cd = 0.8
            },
            icon = icons.secondary
        },
        {
            name = "secondary2",
            cost = 2,
            req = {"secondary1"},
            reqany = false,
            pos = {2, 2},
            mod = {
                secondary_dmg = 1.25
            },
            icon = icons.secondary
        },
        {
            name = "special1",
            cost = 2,
            req = {},
            reqany = false,
            pos = {3, 1},
            mod = {
                special_cd = 0.7
            },
            icon = icons.special
        },
    },
    rewards = {{100, 1}, {200, 1}, {350, 1}, {500, 1}, {700, 1}}
}, SWEP)

--[[-------------------------------------------------------------------------
Client HUD
---------------------------------------------------------------------------]]
if CLIENT then
    local hud = SCPHUDObject("SCPXXX", SWEP)
    hud:AddCommonSkills()  -- Adds health bar

    hud:AddSkill("primary")
        :SetButton("attack")
        :SetMaterial("slc/hud/scp/xxx/primary.png", "smooth")
        :SetCooldownFunction("GetNextPrimaryFire")

    hud:AddSkill("secondary")
        :SetButton("attack2")
        :SetMaterial("slc/hud/scp/xxx/secondary.png", "smooth")
        :SetCooldownFunction("GetNextSecondary")

    hud:AddSkill("special")
        :SetButton("scp_special")
        :SetMaterial("slc/hud/scp/xxx/special.png", "smooth")
        :SetCooldownFunction("GetNextSpecial")

    -- Optional: Add custom bar (resource, stacks, etc.)
    -- hud:AddBar("resource")
    --     :SetMaterial("slc/hud/scp/xxx/resource.png", "smooth")
    --     :SetColor(Color(100, 150, 255))
    --     :SetTextFunction(function(swep)
    --         return swep:GetStacks() .. " / " .. swep.MaxStacks
    --     end)
    --     :SetProgressFunction(function(swep)
    --         return swep:GetStacks() / swep.MaxStacks
    --     end)
end

--[[-------------------------------------------------------------------------
Sounds
---------------------------------------------------------------------------]]
sound.Add({
    name = "SCPXXX.Attack",
    volume = 1,
    level = 75,
    pitch = {95, 105},
    sound = "path/to/attack_sound.wav",
    channel = CHAN_WEAPON,
})

sound.Add({
    name = "SCPXXX.Secondary",
    volume = 1,
    level = 80,
    pitch = {90, 100},
    sound = "path/to/secondary_sound.wav",
    channel = CHAN_WEAPON,
})

sound.Add({
    name = "SCPXXX.Special",
    volume = 1,
    level = 85,
    pitch = 100,
    sound = "path/to/special_sound.wav",
    channel = CHAN_STATIC,
})
```

## Common Attack Patterns

### Melee Trace Attack
```lua
local attack_trace = {}
attack_trace.mask = MASK_SHOT
attack_trace.output = attack_trace

function SWEP:MeleeAttack(range, damage)
    local owner = self:GetOwner()
    attack_trace.start = owner:GetShootPos()
    attack_trace.endpos = attack_trace.start + owner:GetAimVector() * range
    attack_trace.filter = owner

    owner:LagCompensation(true)
    util.TraceLine(attack_trace)
    owner:LagCompensation(false)

    local ent = attack_trace.Entity
    if not IsValid(ent) or not ent:IsPlayer() or not self:CanTargetPlayer(ent) then return end

    local dmg = DamageInfo()
    dmg:SetDamage(damage)
    dmg:SetDamageType(DMG_SLASH)
    dmg:SetAttacker(owner)
    dmg:SetInflictor(self)
    ent:TakeDamageInfo(dmg)
end
```

### Hull Trace (Wider hitbox)
```lua
local attack_trace = {}
attack_trace.mins = Vector(-10, -10, -10)
attack_trace.maxs = Vector(10, 10, 10)
attack_trace.mask = MASK_SHOT
attack_trace.output = attack_trace

function SWEP:HullAttack(range, damage)
    local owner = self:GetOwner()
    attack_trace.start = owner:GetShootPos()
    attack_trace.endpos = attack_trace.start + owner:GetAimVector() * range
    attack_trace.filter = owner

    owner:LagCompensation(true)
    util.TraceHull(attack_trace)
    owner:LagCompensation(false)

    -- Same damage logic as above
end
```

### Area of Effect Attack
```lua
function SWEP:AOEAttack(radius, damage)
    local owner = self:GetOwner()
    local origin = owner:GetPos()

    owner:LagCompensation(true)
    for _, ply in ipairs(player.GetAll()) do
        if ply == owner or not self:CanTargetPlayer(ply) then continue end

        local dist = ply:GetPos():Distance(origin)
        if dist > radius then continue end

        -- Optional: Damage falloff
        local falloff = 1 - (dist / radius) * 0.5  -- 50% falloff at max range

        local dmg = DamageInfo()
        dmg:SetDamage(damage * falloff)
        dmg:SetDamageType(DMG_BLAST)
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        ply:TakeDamageInfo(dmg)
    end
    owner:LagCompensation(false)
end
```

### Cone Attack (Like SCP-939)
```lua
function SWEP:ConeAttack(range, angle, damage)
    local owner = self:GetOwner()
    local origin = owner:GetPos()
    local forward = owner:GetAngles():Forward()
    forward.z = 0
    forward:Normalize()

    owner:LagCompensation(true)
    for _, ply in ipairs(player.GetAll()) do
        if ply == owner or not self:CanTargetPlayer(ply) then continue end

        local toPlayer = ply:GetPos() - origin
        if math.abs(toPlayer.z) > 48 then continue end  -- Height check

        local dist = toPlayer:Length2D()
        if dist > range then continue end

        toPlayer:Normalize()
        local dot = forward:Dot(toPlayer)
        if dot < math.cos(math.rad(angle / 2)) then continue end

        -- Player is in cone, deal damage
        local dmg = DamageInfo()
        dmg:SetDamage(damage)
        dmg:SetDamageType(DMG_SLASH)
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        ply:TakeDamageInfo(dmg)
    end
    owner:LagCompensation(false)
end
```

### Beam Attack
```lua
function SWEP:BeamAttack(range, width, damage)
    local owner = self:GetOwner()
    local spos = owner:GetShootPos()
    local dir = owner:GetAimVector()

    owner:LagCompensation(true)
    for _, ply in ipairs(player.GetAll()) do
        if ply == owner or not self:CanTargetPlayer(ply) then continue end

        local plyPos = ply:GetPos() + Vector(0, 0, 40)
        local toPlayer = plyPos - spos
        local dist = toPlayer:Dot(dir)

        if dist < 0 or dist > range then continue end

        local closestPoint = spos + dir * dist
        local perpDist = (plyPos - closestPoint):Length()

        if perpDist > width then continue end

        local dmg = DamageInfo()
        dmg:SetDamage(damage)
        dmg:SetDamageType(DMG_ENERGYBEAM)
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        ply:TakeDamageInfo(dmg)
    end
    owner:LagCompensation(false)
end
```

## NetworkVar Types

```lua
self:NetworkVar("Float", "Name")   -- Decimal numbers (cooldowns, timers)
self:NetworkVar("Int", "Name")     -- Integers (stacks, counters)
self:NetworkVar("Bool", "Name")    -- True/false (states, toggles)
self:NetworkVar("String", "Name")  -- Text (rarely needed)
self:NetworkVar("Entity", "Name")  -- Entity references (targets)
self:NetworkVar("Vector", "Name")  -- 3D positions
self:NetworkVar("Angle", "Name")   -- Rotations
```

Access with `self:GetName()` and `self:SetName(value)`.
