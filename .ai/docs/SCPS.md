# SCP: Lost Control - SCP Documentation

This document provides a summary of all SCPs available in the gamemode, including their descriptions, lore, abilities, and notable characteristics.

---

## SCP-023 - The Black Shuck

**Health:** 2550 | **Speed:** 180

### Description
A large black spectral hound with glowing eyes. An omen of death that drains the life force of those nearby.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Drain Aura** | Passive | Continuously drains stamina from nearby players. Larger radius on surface. |
| **Clone** | Secondary | Creates a decoy clone to confuse enemies. Can be toggled. |
| **Hunt** | Special | Hunts marked prey with blinking ability and special vision effects. |
| **Invisibility** | Passive | Variable invisibility radius controlled by upgrades. |

### Notable Characteristics
- Semi-transparent appearance
- Avoids SCP-173 (mutual collision avoidance)
- Low health compensated by high buff scaling (1.25x)
- Strong stamina denial capabilities

---

## SCP-035 - The Possessive Mask

**Health:** 1500 | **Speed:** 180

### Description
An ornate white porcelain comedy mask that secretes a corrosive black substance. It can possess hosts and manipulate them to do its bidding.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Corrosive Touch** | Primary | Apply corrosion effect causing damage over time and slowing targets. |
| **Item Usage** | Passive | Can pick up and use weapons, keycards, and medical items like humans. |

### Notable Characteristics
- **Humanoid SCP** - Can interact with items and environment like human players
- Can communicate via voice/text chat
- Allied with Class-D personnel (shared escape objective)
- Neutral relationship with Chaos Insurgency
- Cannot wear tactical vests

---

## SCP-049 - The Plague Doctor

**Health:** 2000 | **Speed:** 180

### Description
A humanoid entity resembling a medieval plague doctor. Believes it is curing a great pestilence by killing its victims, whom it then reanimates as zombie servants.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Choke** | Primary | Hold and strangle players, building a choking meter. Full meter = instant kill. |
| **Surgery** | Reload | Convert corpses into zombies (Normal, Assassin, Boomer, or Heavy variants). |
| **Boost** | Special | Grant speed buff to self and nearby zombie allies. |

### Zombie Variants
| Type | Speed | Health | Damage | Specialty |
|------|-------|--------|--------|-----------|
| Normal | 1.0x | 1.0x | 1.0x | Balanced |
| Assassin | 1.4x | 0.5x | 1.25x | Fast, fragile |
| Boomer | 0.9x | 1.3x | 1.5x | Explosive death |
| Heavy | 0.8x | 1.6x | 0.75x | Tank |

### Notable Characteristics
- Vulnerable to hazmat suits and SCP-714 (jade ring)
- Commands a zombie army as support
- Escape multiplier (0.75x) encourages teamwork
- Humanoid SCP with item interaction

---

## SCP-049-2 - Plague Zombie

**Health:** 400 | **Speed:** 165

### Description
Reanimated corpses created by SCP-049's "cure." They retain basic motor functions but lack higher cognitive abilities, serving their creator with mindless loyalty.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Bite** | Primary | Aggressive melee attack. Varies by zombie type. |
| **Protection** | Passive | Nearby zombies of the same parent protect SCP-049. |

### Notable Characteristics
- **Dynamic spawn only** - Cannot be selected at round start
- Stats configurable per spawn (health, speed, damage, model)
- Life steal capability when SCP-049 is upgraded
- Stacking buffs increase with more zombies active

---

## SCP-058 - Heart of Darkness

**Health:** 2900 | **Speed:** 175

### Description
A bovine heart with arthropod-like legs and a tail ending in a stinger. It speaks constantly in a deep, resonant voice, reciting disturbing poetry and prophecies of doom.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Attack** | Primary | Melee-focused combat abilities. |

### Notable Characteristics
- Frozen during preparation phase
- High base health pool
- Attack-based gameplay with upgrade progression

---

## SCP-066 - Eric's Toy

**Health:** 2600 | **Speed:** 165

### Description
A mass of intertwined yarn and ribbon that produces sounds. Originally benign, it now aggressively shouts "ERIC!" and emits deadly frequencies when threatened.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Music Attack** | Primary | Plays lethal music damaging enemies in radius based on proximity. |
| **Eric Stacks** | Passive | Gains stacks when threatened. Used to fuel special abilities. |
| **Dash** | Reload | Charge forward and attach to enemies, draining their control. |
| **Boost** | Special | Spend Eric stacks for Speed, Defense, or Regeneration buffs. |

### Notable Characteristics
- Must be threatened (damaged or facing armed players) to attack
- Threat detection through visibility and weapon checks
- Three rotating special abilities cycle through buffs
- No ragdoll on death

---

## SCP-096 - The Shy Guy

**Health:** 1900 | **Speed:** 125

### Description
An emaciated humanoid with elongated arms. Normally docile, it enters an unstoppable rage state when its face is viewed by any living creature, pursuing the viewer until eliminated.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Rage Trigger** | Passive | Looking at SCP-096 triggers rage mode. Must chase viewers. |
| **Lunge** | Primary | Mid-rage jump attack that can cancel rage state. |
| **Regeneration** | Reload | Convert regen stacks to health (requires standing still). |
| **Hunt's Over** | Special | Exit rage early, gain regen stacks per target, mitigate sanity damage. |

### Notable Characteristics
- Vision detection triggers rage (3-second prep phase)
- Slowest base speed (125) but becomes fast during rage
- Multikill system during rage sequences
- Regeneration stacks build passively outside rage
- Avoids SCP-173 (collision avoidance)

---

## SCP-106 - The Old Man

**Health:** 1000 | **Speed:** 150

### Description
An elderly humanoid that can phase through solid matter. It drags victims into its "pocket dimension" - a nightmare realm from which few escape.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Withering** | Primary | Melee attack applying slow + damage over time. Stacks with "teeth" counter. |
| **Trap** | Secondary | Place invisible wall traps that teleport victims to pocket dimension. |
| **Spot Teleport** | Special | Create and teleport between visible ground spots (max 8). |
| **Passive Damage** | Passive | Continuous damage forcing pocket dimension teleport at threshold. |

### Notable Characteristics
- "Teeth" counter tracks successful teleports
- Lowest health SCP (1000 HP) but high survivability through mechanics
- Third-person camera during certain sequences
- Custom collision detection for phasing

---

## SCP-173 - The Sculpture

**Health:** 4000 | **Speed:** 500

### Description
A concrete statue that cannot move while being observed. When line of sight is broken, it moves at extreme speeds to attack, snapping the necks of its victims.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Freeze** | Passive | Becomes a statue when observed. Teleports behind observers. |
| **Gas Cloud** | Primary | Emit choking gas that slows vision and increases blink rate. |
| **Decoy** | Secondary | Place statue decoys (1-3 based on upgrades) to distract enemies. |
| **Stealth** | Special | Become invisible and phase through doors. Cannot attack while active. |

### Notable Characteristics
- **Fastest SCP** (500 base speed)
- Statue form is invulnerable but immobile
- Deals sanity damage to players looking at it
- Protection scale reduced (0.25x) for balance
- Restricted in certain facility zones

---

## SCP-457 - The Burning Man

**Health:** 2300 | **Speed:** 165

### Description
A sentient flame entity in humanoid form. It seeks to spread and grow by consuming all flammable material, including living creatures.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Fire Aura** | Passive | Always burning, damages nearby enemies. |
| **Fireball** | Primary | Launch exploding fireballs. Costs fuel. |
| **Fire Trap** | Secondary | Place stationary traps that ignite when triggered. Costs fuel. |
| **Ignite** | Special | Area ignition creating expanding rings of fire. Costs fuel. |

### Notable Characteristics
- **Fuel management system** - Starts at 100, regenerates passively
- **Fatal weakness to water** - Takes 10 damage per 0.1s in water
- Cannot place traps on elevators
- Fireball has configurable size, speed, and damage

---

## SCP-682 - The Hard-to-Destroy Reptile

**Health:** 3500 | **Speed:** 160

### Description
A large, vaguely reptilian creature with extreme regeneration and adaptation abilities. Highly intelligent and harbors intense hatred for all life.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Swipe** | Primary | Quick melee attack. |
| **Bite** | Secondary | Charge a devastating bite. Damage scales with charge time. 72° cone. |
| **Charge** | Special | Sprint forward, breaking doors and pinning players with knockback. |
| **Shield** | Passive | 900 HP regenerating shield that protects health. |

### Notable Characteristics
- State machine (Normal, Stunned)
- Charge breaks doors and props
- 4-second stun after failed charge
- Shield can be upgraded to full health capacity

---

## SCP-860-2 - The Guardian of the Forest

**Health:** 4600 | **Speed:** 175

### Description
A creature inhabiting the forest dimension accessed through SCP-860 (blue key). It hunts those who enter its domain with relentless precision.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Detection** | Passive | Auto-detects and damages players in forest zone. Grants overheal shield. |
| **Punch** | Primary | Melee attack with knockback. |
| **Defense Dash** | Secondary | Charge and release to dash with damage mitigation (0.6 reduction). |
| **Charge** | Special | Charge at enemy and pin them. Extra damage against walls. |

### Notable Characteristics
- **Highest health SCP** (4600 HP)
- Operates primarily in forest zone (ZONE_FOREST)
- Overheal shield up to 1200 HP protects base health
- Persistent target tracking system

---

## SCP-939 - With Many Voices

**Health:** 3100 | **Speed:** 175

### Description
Pack-based predators that lack eyes and hunt by sound. They can perfectly mimic human voices to lure prey, often using the last words of their victims.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Bite** | Primary | Multi-directional cone attack (90° arc). |
| **Trail** | Secondary | Create persistent damaging trail while moving. Emits aura and slows. |
| **Sonic Shriek** | Special | Massive area sound attack that disorients all players in radius. |

### Notable Characteristics
- Aura radius damage (130 base)
- Trail system with 8 max stacks
- Amnesia effect blocks victim attacks
- Sound visualization for players (expanding spheres)
- Can only see team members and other SCPs

---

## SCP-966 - The Sleep Killer

**Health:** 1750 | **Speed:** 190

### Description
Predatory creatures invisible to the naked eye. They emit a field that prevents REM sleep, slowly driving victims to exhaustion and death.

### Abilities
| Ability | Key | Description |
|---------|-----|-------------|
| **Vision Aura** | Passive | Applies blindness/perception debuff to nearby players. |
| **Attack** | Primary | Damage scales with victim's effect stacks. Requires 10+ stacks. |
| **Channel** | Secondary | Hold to channel on target, increasing their effect stacks. |
| **Mark** | Special | Mark a player to spread effect stacks to nearby victims. |

### Notable Characteristics
- Effect stacks required for lethal attacks (minimum 10)
- Damage scales 5-50 based on stack count
- Multi-channel modes (single or radius)
- Healing based on stack count and targets
- Sound detection network visualization

---

## SCP-2427-3 - The Hive Mind Parasite

**Health:** 4500 | **Speed:** 170

### Description
A parasitic organism that creates a collective consciousness among its hosts, spreading through physical contact.

### Notable Characteristics
- No ragdoll on death
- Frozen during preparation phase
- High health pool (4500 HP)
- Stat-based progression

---

## SCP-3199 - Humans, Refuted

**Health:** 1450 | **Speed:** 215

### Description
Featherless bipedal creatures that reproduce through traumatic means. They are extremely fast and aggressive hunters.

### Notable Characteristics
- **Second fastest SCP** (215 speed, after SCP-173)
- Frozen during preparation
- Medium health with high buff scaling (0.95x)

---

## SCP-808-J - Kanye (Joke)

**Health:** 2000 | **Speed:** 175

### Description
A joke SCP based on Kanye West that alternates between "Good Kanye" and "Evil Kanye" personalities. The mode swaps randomly every 1-5 minutes, completely changing the SCP's abilities.

### Abilities

**Both Modes:**
| Ability | Key | Description |
|---------|-----|-------------|
| **Melee Attack** | Primary | 30 damage punch attack with 3 second cooldown. |

**Good Kanye Mode:**
| Ability | Type | Description |
|---------|------|-------------|
| **Sunday Service** | Passive | Regenerate 5 HP every 3 seconds while standing still. |
| **Item Spawn** | Secondary | Spawn a random useful item (medkit, battery, flashlight, etc.). 1 minute cooldown. |
| **Stamina Drain** | Special | Drain all stamina from players within 5m radius. 3 minute cooldown. |

**Evil Kanye Mode:**
| Ability | Type | Description |
|---------|------|-------------|
| **Paparazzi** | Passive | See the closest enemy through walls (wallhack highlight). |
| **Deafen** | Secondary | Play audio that blocks sounds for 30 seconds in 600 unit radius. 3 minute cooldown. |
| **Cancel Culture** | Special | Mark target for 25% increased damage for 15 seconds. 45 second cooldown. |

### Notable Characteristics
- Joke SCP (Kanye model)
- **Dual personality system** - randomly swaps between Good and Evil mode every 1-5 minutes
- Can communicate via chat
- Frozen during preparation
- Mode swap is announced to the player
- Configurable stats (1500-2500 HP, 150-200 speed)

---

## SCP-1983-J - The Purple Guy (Joke)

**Health:** 2200 | **Speed:** 170

### Description
A joke SCP referencing the antagonist from the Five Nights at Freddy's franchise.

### Notable Characteristics
- Joke SCP (William Afton/Springtrap)
- Frozen during preparation
- Configurable health (1800-2800 HP)

---

## SCP-1987-J - Freddy Fazbear (Joke)

**Health:** 1350 | **Speed:** 185

### Description
A joke SCP based on the animatronic character from Five Nights at Freddy's.

### Notable Characteristics
- **Support SCP** - Spawns mid-round, not at round start
- Joke SCP (Animatronic model)
- Lower jump power (150)
- Cannot escape normally (escape override)
- Protection scale: 0.9x

---

## Quick Reference

### Health Rankings (Highest to Lowest)
| Rank | SCP | Health |
|------|-----|--------|
| 1 | SCP-860-2 | 4600 |
| 2 | SCP-2427-3 | 4500 |
| 3 | SCP-173 | 4000 |
| 4 | SCP-682 | 3500 |
| 5 | SCP-939 | 3100 |
| 6 | SCP-058 | 2900 |
| 7 | SCP-066 | 2600 |
| 8 | SCP-023 | 2550 |
| 9 | SCP-457 | 2300 |
| 10 | SCP-1983-J | 2200 |

### Speed Rankings (Fastest to Slowest)
| Rank | SCP | Speed |
|------|-----|-------|
| 1 | SCP-173 | 500 |
| 2 | SCP-3199 | 215 |
| 3 | SCP-966 | 190 |
| 4 | SCP-1987-J | 185 |
| 5 | SCP-035/049/023 | 180 |

### SCP Types
- **Humanoid SCPs** (can use items): SCP-035, SCP-049
- **Support SCPs** (spawn mid-round): SCP-049-2, SCP-1987-J
- **Joke SCPs**: SCP-808-J, SCP-1983-J, SCP-1987-J
