# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**SCP: Lost Control** is a Garry's Mod gamemode based on the SCP Foundation universe. It's a PvP gamemode with complex mechanics including SCP entities, player classes, round management, and extensive networking. Current version: Beta 0.11.1 rev. 2.

## Development Commands

This is a Garry's Mod gamemode - there are no build commands. Development workflow:
1. Edit Lua files in `gamemodes/scplc/` or `lua/autorun/`
2. Test in Garry's Mod by loading the gamemode on map `gm_site19`
3. Use `lua_openscript_cl <file>` or `lua_openscript <file>` in console for hot-reloading
4. Check console for Lua errors

**Developer Tools:**
- `draw_vectors` - Visualize debug vectors
- `draw_item_spawns` - Show item spawn locations
- `draw_zones` - Display map zones
- `filter_item_spawns <pool_name>` - Filter spawn visualization

## Architecture Overview

### Directory Structure

```
gamemodes/scplc/
├── gamemode/
│   ├── core/           # 45 core modules (~450KB) - utilities, networking, database
│   ├── modules/        # 56 game modules (~800KB) - UI, gameplay logic
│   ├── mapconfigs/     # Map-specific configurations (primarily gm_site19.lua)
│   ├── minigames/      # Minigame implementations
│   ├── languages/      # 9 language translation files
│   ├── shared.lua      # Main initialization orchestrator - loads all modules
│   ├── init.lua        # Server entry point
│   └── cl_init.lua     # Client entry point
├── entities/
│   ├── effects/        # 5 effect entities
│   ├── entities/       # 27 custom entities (buttons, cameras, lootables, etc.)
│   └── weapons/        # 60 weapons/items (SCPs, tools, equipment)
└── scplc.txt          # Gamemode manifest

lua/autorun/           # 48 shared libraries (~470KB) - loaded before gamemode
data/slc/             # Game data (SCP overrides, resource packs)
```

### File Naming Conventions

- `sv_*.lua` - Server-only files
- `cl_*.lua` - Client-only files (sent via AddCSLuaFile)
- `sh_*.lua` - Shared files (run on both realms)
- `_*.lua` - Skipped during auto-loading (development/test files)

### Initialization Flow

The gamemode loads in this order (orchestrated by `shared.lua`):

1. **Core modules** (45 files in `core/`) - Utilities, networking, database, configuration
2. **Languages** (9 files in `languages/`) - Translation tables
3. **Module system registration** - `sh_module.lua`, `sv_module.lua`, `cl_module.lua`
4. **Game modules** (56 files in `modules/`) - Client UI, server logic, shared systems
5. **Map configuration** - `mapconfigs/gm_site19.lua` + overrides
6. **Custom hooks fired**:
   - `SLCLanguagesLoaded`
   - `SLCModulesLoaded`
   - `SLCMapConfigLoaded`
   - `SLCFullyLoaded`

## Core Systems

### Round Management (`sv_round.lua`, `sh_round.lua`)

The round system manages gameplay through multiple phases:

**Round States:**
```lua
ROUND = {
    preparing = false,    -- Preparation phase
    active = false,       -- Round in progress
    post = false,         -- Post-round results
    aftermatch = false,   -- After match state
    infoscreen = false,   -- Info screen showing
    timers = {},         -- Round-local timers
    queue = {},          -- Support spawn queue
    stats = {},          -- Round statistics
    winners = {},        -- Winning team
}
```

**Round Flow:**
1. Waiting → Wait for minimum players (`slc_min_players`)
2. Preparing → Class selection, SCP freeze (`slc_time_preparing` seconds)
3. Active → Main gameplay (`slc_time_round` seconds)
4. Lockdown → Emergency procedures (`slc_lockdown_duration` seconds)
5. Post → Results screen (`slc_time_postround` seconds)
6. Restart cycle

**Key Functions:**
- `SetupSupportTimer()` - Schedules support team spawns (MTF, Alpha-1, etc.)
- `assign_scps()` - Weighted SCP selection with karma system
- `SpawnSupport()` - Spawns support teams based on queue

**Custom Hooks:**
- `SLCRound` - Round started
- `SLCRoundEnd` - Round ending
- `SLCRoundCleanup` - Cleanup phase (auto-clears round hooks)

### SCP System (`sv_scp.lua`, `sv_base_scps.lua`)

SCPs are registered using a centralized system:

```lua
RegisterSCP(name, model, weapon, static_stats, dynamic_stats, callback, post_callback)
```

**SCP Structure:**
```lua
ObjectSCP = {
    name = "SCP-173",
    model = "models/...",
    swep = "weapon_scp_173",
    spawnpos = Vector(...),
    basestats = {
        base_speed = 200,
        max_health = 1500,
        jump_power = 200,
        -- 23 more valid entries
    },
    callback = function(ply, basestats) end,  -- Setup function
    post = function(ply) end,                  -- Post-setup function
}
```

**Configuration:**
- `data/slc/scp_override.txt` - Modifiable SCP stats (INI format)
- `data/slc/scp_default.txt` - Reference defaults

**SCP Mechanics:**
- Door overload system (`slc_overload_cooldown`, `slc_overload_time`)
- SCP-specific hooks via `SCPHook(scp_name, hook_name, func)`
- Dynamic buff system outside facility
- Protection/buff scaling based on round progress

**Registered SCPs:** 023, 049, 0492, 058, 066, 096, 106, 173, 457, 682, 860-2, 939, 966, 2427-3, 3199, 1987-J

**Support SCPs:** Some SCPs spawn as support groups rather than at round start:
- SCP-1987-J (Freddy Fazbear) - Joke SCP that spawns after 2 minutes into the round

### Player Class System (`sh_classes.lua`, `sv_player.lua`)

Classes are organized into groups with weighted selection:

```lua
-- Add a class group
AddClassGroup(name, weight, spawn_positions)

-- Class structure
{
    team = TEAM_GUARDS,
    health = 100,
    walk_speed = 100,
    run_speed = 225,
    stamina = 100,
    vest = nil,
    loadout = "loadout_name",  -- From lua/autorun/loadout.lua
    weapons = { "weapon_class", ... },
    max = 0,                    -- Max players (0 = unlimited)
    tier = 0,                   -- Selection tier
    spawn = Vector(...) or { Vector(...), ... },
    callback = function(ply, class) end,
}
```

**Teams:**
- `TEAM_SCP` (1) - SCP entities
- `TEAM_GUARDS` (2) - Security personnel
- `TEAM_SCIENTISTS` (3) - Research staff
- `TEAM_CLASSD` (4) - D-Class personnel
- `TEAM_CI` (5) - Chaos Insurgency
- `TEAM_MTF` (6) - Mobile Task Forces

**Support Teams:**
Use `AddSupportGroup()` to register teams that spawn during rounds (MTF, Alpha-1, CI, etc.)

### Item & Looting System (`sv_items.lua`, `sv_looting.lua`)

**Item Registry:**
```lua
SLC_ITEMS_DATA = {
    item_class = {
        icon = "materials/path/to/icon",
        name = "Item Name",
        rarity = 5,          -- Rarity level
        value = 100,         -- Point value
        max = 5,             -- Max stack size
        weight = 1,          -- Weight for generation
        -- equipment = true, -- If it's equipment
        -- ... custom data
    }
}
```

**Loot Pool System:**
```lua
AddLootPool(name, {
    max = 12,              -- Max items per container
    value_limit = 5000,    -- Total value cap
    chance = 0.75,         -- 75% chance per slot
    items = {
        { class = "item_class", weight = 10, value = 100, max = 3, ... },
        -- ...
    }
})

-- Generate loot for a container
GenerateLootTable(pool_name, num_slots)
```

**Looting Mechanics:**
- Hold-based system (`slc_time_looting`: 1.5 sec per item)
- Item swapping (`slc_time_swapping`: 1.5 sec)
- Priority-based pickup
- Time-based drop removal

### Damage System (`sh_damage.lua`)

Custom damage modifiers for SCPs:

```lua
GetSCPModifiers(ply) -- Returns:
{
    def = 0.0,          -- Damage reduction (%)
    flat = 0,           -- Flat damage reduction
    heal_scale = 1.0,   -- Healing multiplier
    regen_scale = 0.75, -- Regen multiplier
}
```

**Scaling:**
- Round progress-based (0.1 to 0.9)
- SCP protection scaling
- Aftermatch/escape buffs
- Direct damage cap system

### Effects System (`sh_effects.lua`)

48 different effect types with configuration:
- Duration-based with stacking
- Custom icons and colors
- Examples: blinding, burning, poisoning, radiation, bleeding, etc.

### Game Events (`sv_game_events.lua`)

Events track player actions and award XP/karma/points:
- Player deaths/kills/assists
- Escapes
- Document recovery
- Door destruction
- SCP containment
- Warhead detonation
- 30+ more tracked events

Register event handlers:
```lua
hook.Add("RegisterGameEvents", "CustomEvents", function()
    -- Register event handlers here
end)
```

## Hook System

### Custom Hook Types

**SCP Hooks** (activate/deactivate per SCP):
```lua
SCPHook(scp_name, hook_name, func)
EnableSCPHook(scp_name)
DisableSCPHook(scp_name)
ClearSCPHooks()
```

**Round Hooks** (auto-cleared on `SLCRoundCleanup`):
```lua
AddRoundHook(name, identifier, func)
RemoveRoundHook(name, identifier)
ClearRoundHooks()
```

**Player Hooks** (auto-cleared on player cleanup):
```lua
PLAYER:AddHook(name, identifier, func)
PLAYER:RemoveHook(name, identifier)
PLAYER:ClearHooks()
```

### Important Custom Hooks
- `SLCLanguagesLoaded` - After languages loaded
- `SLCModulesLoaded` - After modules loaded
- `SLCMapConfigLoaded` - After map config loaded
- `SLCFullyLoaded` - Gamemode fully initialized
- `RegisterSCP` - Register SCP classes
- `RegisterClassGroups` - Register player classes
- `RegisterGameEvents` - Register game event handlers

## Key Utilities

### Player Properties (`core/player.lua`)
```lua
PLAYER:SetProperty(key, value)     -- Store custom data
PLAYER:GetProperty(key, default)   -- Retrieve custom data
```

### Hold System (for interactions)
```lua
PLAYER:StartHold(tab, id, key, time, callback, never_release)
PLAYER:UpdateHold(tab, id)  -- Returns (completed, data)
PLAYER:InterruptHold(tab, id)
```

### Networking (`core/net.lua`)
```lua
net.Ping(name, data, callback)              -- Simple data ping
net.SendTable(name, channel, data, target)  -- Large table transmission
net.AddTableChannel(name)                   -- Register named channel
```

### Zone System (`lua/autorun/zones.lua`)
```lua
MAP_ZONES = {
    ZONE_NAME = { Vector(...), Vector(...), ... },
}

PLAYER:IsInZone(zone_name)
```

### Configuration (`core/gamemode_config.lua`)
```lua
SLCCVar(name, category, default, flags, help, min, max, valid_check)
-- Creates replicated ConVar + client-side settings UI
```

### Version System (`core/version.lua`)
```lua
SLCVersion(signature)  -- e.g., "b001101r2"
-- Parses: realm(b=beta), major(00), minor(11), patch(01), rev(2)
-- Supports comparison: ==, <, >, <=, >=
```

## Extension Points

### Adding New SCPs

**IMPORTANT:** Add new SCPs directly to the main gamemode files, NOT in separate `lua/autorun/` files. Separate autorun files may not load in the correct order and can cause registration failures.

**Required files to modify:**
1. `modules/sv_base_scps.lua` - Add `RegisterSCP()` call
2. `mapconfigs/gm_site19.lua` - Add spawn position (e.g., `SPAWN_SCP_XXXX`)
3. `languages/english.lua` - Add class name, objectives, weapon descriptions, effects
4. `entities/weapons/weapon_scp_xxxx.lua` - Create the SWEP

**For Support SCPs** (spawn mid-round like SCP-1987-J):
1. Also add to `modules/sh_base_classes.lua`:
   - `AddSupportGroup()` - Defines spawn timing and conditions
   - `RegisterSupportClass()` - Defines the player class
2. Add spawn position like `SPAWN_SUPPORT_XXXX` in map config

```lua
-- In modules/sv_base_scps.lua (inside the RegisterSCP hook)
RegisterSCP("SCP_XXXX", "models/...", "weapon_scp_xxxx", {
    jump_power = 200,
    prep_freeze = true,
    no_select = true,      -- For support SCPs only
    dynamic_spawn = true,  -- For support SCPs only
}, {
    base_health = 2000,
    max_health = 2000,
    base_speed = 180,
}, nil, function(ply)
    -- Post-setup callback
end)
```

**For Support SCP class registration** (in `sh_base_classes.lua`):
```lua
-- Add support group (when/how they spawn)
AddSupportGroup("scp_xxxx", weight, SPAWN_SUPPORT_XXXX, max_players, function()
    -- Spawn callback (announcements, round properties)
end, function()
    -- Spawn condition (return true to allow spawn)
    return round_time >= 120
end)

-- Register the support class
RegisterSupportClass("scp_xxxx_class", "scp_xxxx", "models/...", {
    team = TEAM_SCP,
    name = "SCP_XXXX",
    health = 1500,
    callback = function(ply, class)
        local scp = GetSCP("SCP_XXXX")
        if scp then scp:SetupPlayer(ply, true, ply:GetPos()) end
    end
})
```

### Adding New Classes
```lua
-- In lua/autorun/shared/my_classes.lua
hook.Add("RegisterClassGroups", "CustomClasses", function()
    AddClassGroup("MY_GROUP", 1, {
        {
            team = TEAM_GUARDS,
            name = "my_class",
            health = 150,
            -- ... class config
        }
    })
end)
```

### Adding New Items
Modify `SLC_ITEMS_DATA` in `modules/sv_items.lua` or add items in map config.

### Adding New Game Events
```lua
hook.Add("RegisterGameEvents", "CustomEvents", function()
    hook.Add("PlayerDeath", "MyCustomEvent", function(ply, inf, att)
        -- Award XP, karma, etc.
    end)
end)
```

### Adding New Maps
Create `gamemodes/scplc/gamemode/mapconfigs/<mapname>.lua` with:
- Spawn positions per class
- Zone definitions
- Door triggers
- Item spawn locations
- Special mechanics

## Important Files Reference

### Core Entry Points
- `gamemode/shared.lua` - Main initialization orchestrator
- `gamemode/init.lua` - Server entry point
- `gamemode/cl_init.lua` - Client entry point

### Essential Systems
- `core/net.lua` - Networking utilities
- `core/player.lua` - Player meta table extensions
- `modules/sv_round.lua` - Round management
- `modules/sv_scp.lua` - SCP registration system
- `modules/sv_base_scps.lua` - All SCP definitions
- `modules/sh_classes.lua` - Class system
- `modules/sh_base_classes.lua` - All class/support group definitions
- `modules/sv_items.lua` - Item registry
- `modules/sv_looting.lua` - Loot generation
- `modules/sv_game_events.lua` - Event tracking

### Client UI
- `modules/cl_hud.lua` - Main HUD (22 KB)
- `modules/cl_scp_hud.lua` - SCP-specific HUD (18 KB)
- `modules/cl_settings.lua` - Settings menu (24 KB)
- `modules/cl_menu_screen.lua` - Main menu interface
- `modules/cl_info_screen.lua` - Info/spawn screen

### Map Configuration
- `mapconfigs/gm_site19.lua` - Main map config (79 KB)
- `mapconfigs/__gm_site19_overrides.lua` - Custom overrides

### Autorun Libraries
- `lua/autorun/loadout.lua` - Weapon loadout system (31 KB)
- `lua/autorun/zones.lua` - Zone definitions
- `lua/autorun/teams.lua` - Team relationships
- `lua/autorun/sv_astar.lua` - A* pathfinding for SCPs
- `lua/autorun/slc_frame_handler.lua` - Frame optimization

## Configuration System

150+ ConVars organized by category:
- Round timing (`slc_time_preparing`, `slc_time_round`, etc.)
- General gameplay (`slc_min_players`, etc.)
- Features (doors, precache, logging)
- SCP mechanics (buff, overload, etc.)
- Gas decontamination
- XP system
- Warheads
- AFK handling

All ConVars are defined using `SLCCVar()` which creates both server ConVars and client-side settings UI.

## Language System

9 supported languages: English, Russian, Ukrainian, Polish, French, Chinese, German, Korean, Turkish

Translation tables contain:
- `NRegistry` - Notifications
- `NCRegistry` - Client notifications
- `CLASSES` - Class names
- `CLASS_OBJECTIVES` - Class descriptions
- `TEAMS` - Team names
- `WEAPONS` - Weapon names
- `ITEMS` - Item names
- 500+ translation keys total

Register languages:
```lua
RegisterLanguage(tab, name, ...)
```

### SCP Weapon Localization Structure

**IMPORTANT:** When adding localization for SCP weapons, the `skills` and `upgrades` sections use **different keys** for descriptions:

```lua
wep.SCPXXX = {
    name = "SCP-XXX",
    desc = "Description of the SCP",
    skills = {
        skill_name = {
            name = "Skill Name",
            dsc = "Skill description",  -- MUST use 'dsc' for skills!
        },
    },
    upgrades = {
        parse_description = true,
        upgrade_name = {
            name = "Upgrade Name",
            info = "Upgrade description",  -- Use 'info' for upgrades
        },
    },
}
```

- **Skills section**: Use `dsc` for descriptions (read by `cl_scp_hud.lua:97`)
- **Upgrades section**: Use `info` for descriptions

The skill names in the localization must match the names used in `hud:AddSkill("skill_name")` calls in the weapon file.

### Adding Localization for New SCPs

When adding a new SCP, ensure these entries exist in **all** language files:

1. **Class name**: `classes.SCPXXX = "SCP-XXX"`
2. **Class objectives**: `CLASS_OBJECTIVES.SCPXXX = [[...]]`
3. **Weapon localization**: `wep.SCPXXX = { ... }` with:
   - `skills` table (using `dsc` for descriptions)
   - `upgrades` table (using `info` for descriptions)

## Notes

- **No automated testing** - Manual testing in-game required
- **No build system** - Direct Lua file editing
- **Single map focus** - Primarily designed for `gm_site19`
- **Steam Workshop integration** - Workshop ID: 2402059605
- **License** - CC BY-SA 3.0
- **Memory management** - Use round hooks/player hooks to prevent leaks
- **Performance** - Use frame handler for high-frequency operations
- **Networking** - Large tables auto-chunked (65KB limit)
