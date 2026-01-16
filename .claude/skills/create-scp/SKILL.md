---
name: create-scp
description: Create new SCP entities for the gamemode. Use when the user wants to add a new SCP, implement an SCP, create an SCP weapon, or add a new anomaly to the game. Handles SWEP creation, registration, spawn positions, and language strings.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# SCP Creation Skill

This skill guides you through creating a complete SCP implementation for SCP: Lost Control.

## Overview

When creating a new SCP, you MUST create/modify these files in order:

1. **SWEP File** - `gamemodes/scpsc/entities/weapons/weapon_scp_xxxx.lua`
2. **SCP Registration** - `gamemodes/scpsc/gamemode/modules/sv_base_scps.lua`
3. **Support Group (if support SCP)** - `gamemodes/scpsc/gamemode/modules/sh_base_classes.lua`
4. **Spawn Position** - `gamemodes/scpsc/gamemode/mapconfigs/gm_site19.lua`
5. **Language Strings** - `gamemodes/scpsc/gamemode/languages/english.lua` (and optionally russian.lua)
6. **Custom Effects (if needed)** - `gamemodes/scpsc/gamemode/modules/sh_effects.lua`

## Step 1: Gather Requirements

Before implementing, ask the user for:
- SCP designation (e.g., "SCP-173", "SCP-001-S")
- Brief description and lore
- Health, speed, and other stats
- Abilities (primary attack, secondary attack, special ability)
- Is it a regular SCP or support SCP (spawns mid-round)?
- Team alliances (usually TEAM_SCP, but some ally with Class-D or CI)
- Any custom effects needed

## Step 2: Create the SWEP

Reference [swep-template.md](swep-template.md) for the complete template.

Key requirements:
- Inherit from `weapon_scp_base`
- Use `SetupDataTables()` for networked variables
- Call `InitializeLanguage("SCPXXXX")` in Initialize
- Implement `PrimaryAttack()`, `SecondaryAttack()`, `SpecialAttack()` as needed
- Add SCPHook for any passive abilities
- Create client HUD with `SCPHUDObject`
- Define upgrade system with `DefineUpgradeSystem`

## Step 3: Register the SCP

Add to `sv_base_scps.lua` inside the `RegisterSCP` hook:

```lua
RegisterSCP("SCPXXXX", "models/path/to/model.mdl", "weapon_scp_xxxx", {
    -- Static stats (not modifiable in config)
    jump_power = 200,
    prep_freeze = true,      -- Frozen during preparation phase
    -- For support SCPs:
    no_select = true,        -- Cannot spawn naturally
    dynamic_spawn = true,    -- Spawns mid-round
    -- For humanoid SCPs:
    scp_human = true,        -- Can pick up items
    can_interact = true,     -- Can use doors/buttons
    allow_chat = true,       -- Can use voice/text
}, {
    -- Dynamic stats (can be modified in data/slc/scp_override.txt)
    base_health = { var = 1500, min = 1000, max = 2000 },
    max_health = { var = 1500, min = 1000, max = 2000 },
    base_speed = { var = 180, min = 150, max = 200 },
    buff_scale = 0.8,
    prot_scale = 0.9,
})
```

## Step 4: Add Support Group (Support SCPs Only)

For SCPs that spawn mid-round, add to `sh_base_classes.lua`:

```lua
-- In SLCRegisterClassGroups hook
AddSupportGroup("scp_xxxx", weight, SPAWN_SUPPORT_XXXX, max_players, function()
    SetRoundProperty("scp_xxxx_spawned", true)
    -- Announcement/effects
end, function()
    if GetRoundProperty("scp_xxxx_spawned") then return false end
    local round = GetTimer("SLCRound")
    if not IsValid(round) then return false end
    return round:GetTime() - round:GetRemainingTime() >= spawn_delay_seconds
end)

-- In SLCRegisterPlayerClasses hook
RegisterSupportClass("scp_xxxx_class", "scp_xxxx", "", {
    team = TEAM_SCP,
    weapons = {},
    ammo = {},
    health = 100,
    walk_speed = 100,
    run_speed = 225,
    callback = function(ply, class)
        local scp = GetSCP("SCPXXXX")
        if scp then scp:SetupPlayer(ply, true, ply:GetPos()) end
    end
})
```

## Step 5: Add Spawn Position

Add to `mapconfigs/gm_site19.lua`:

```lua
-- Regular SCP
SPAWN_SCPXXXX = Vector(x, y, z)

-- Support SCP
SPAWN_SUPPORT_XXXX = {Vector(x, y, z),}
```

## Step 6: Add Language Strings

Add to `languages/english.lua`:

```lua
-- Class name (in classes section ~line 760)
classes.SCPXXXX = "SCP-XXX"
classes.scp_xxxx_class = "SCP-XXX"  -- For support SCPs

-- Effects (if custom effects, in effects section ~line 264)
effects.my_custom_effect = "Effect Name"

-- Weapon localization (in wep section ~line 2700+)
wep.SCPXXXX = {
    name = "SCP-XXX",
    desc = "Description of the SCP",
    skills = {
        _overview = {"primary", "secondary", "special"},  -- Skills shown in overview
        primary = {
            name = "Primary Attack",
            dsc = "Description of primary attack",  -- MUST use 'dsc' for skills!
        },
        secondary = {
            name = "Secondary Attack",
            dsc = "Description of secondary attack",
        },
        special = {
            name = "Special Ability",
            dsc = "Description of special ability",
        },
    },
    upgrades = {
        parse_description = true,
        upgrade1 = {
            name = "Upgrade Name",
            info = "Upgrade description\n\t- Bonus: [+modifier_name]",  -- Use 'info' for upgrades!
        },
    },
}
```

## Step 7: Custom Effects (If Needed)

Add to `sh_effects.lua`:

```lua
EFFECTS.RegisterEffect("effect_name", {
    duration = 10,
    stacks = 0,  -- 0=refresh, 1=stack duration, 2=tier stacking
    tiers = {
        { icon = Material("slc/hud/effects/icon.png") },
    },
    cantarget = function(ply) return ply:SCPTeam() ~= TEAM_SPEC end,
    begin = function(self, ply, tier, args, refresh) end,
    finish = function(self, ply, tier, args, interrupt) end,
    think = function(self, ply, tier, args) end,
    wait = 1,  -- Think interval
})
```

## Important Notes

### Damage Tracking with Hooks
- `SCPHook` - Only runs when that SCP is active in the round
- `AddRoundHook` - Runs for the entire round (use for tracking that needs to start before SCP spawns)
- `hook.Add` - Runs always (use sparingly)

### Common Patterns
- Use `self:GetUpgradeMod("key", default)` for upgrade-modified values
- Use `self:CanTargetPlayer(ply)` to check valid targets
- Use `ply:ApplyEffect("name", tier, attacker)` to apply effects
- Use `AddRoundStat("stat_name")` for statistics

### Required Materials (placeholders OK)
- HUD skill icons: `slc/hud/scp/xxxx/skill.png`
- Upgrade icons: `slc/hud/upgrades/scp/xxxx/upgrade.png`
- Effect icons: `slc/hud/effects/effect.png`

## Checklist

Before finishing, verify:
- [ ] SWEP file created with all abilities
- [ ] SCP registered in sv_base_scps.lua
- [ ] Support group added (if support SCP)
- [ ] Spawn position defined in map config
- [ ] Language strings added (classes, wep, effects)
- [ ] Custom effects registered (if any)
- [ ] HUD skills defined in SWEP
- [ ] Upgrade system defined in SWEP
- [ ] Sounds registered with sound.Add()
