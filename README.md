# Elaina - The Wandering Witch (Majo no Tabitabi)
### Don't Starve Singleplayer Mod (Reign of Giants / Shipwrecked / Hamlet)

[![Don't Starve Mod](https://img.shields.io/badge/Don't_Starve-Compatible-green.svg)](https://www.klei.com/games/dont-starve)
[![DLC Support](https://img.shields.io/badge/DLC-RoG%20%7C%20Shipwrecked%20%7C%20Hamlet-blue.svg)](https://store.steampowered.com/app/219740/Dont_Starve/)
[![CI Tests](https://github.com/Cazacu-Condrat-Dumitru/Elaina_Fix/actions/workflows/ci.yml/badge.svg)](https://github.com/Cazacu-Condrat-Dumitru/Elaina_Fix/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An enhanced, community-maintained character mod bringing **Elaina (The Ashen Witch)** from *Wandering Witch: The Journey of Elaina* (*Majo no Tabitabi*) into **Don't Starve**.

This repository contains a full English localization, crash fixes, balance adjustments and Elaina's own character voice, built on top of the original Workshop mod.

---

## Background and Attribution

- **Original Character & Story**: Created by **Jougi Shiraishi** with original illustrations by **Azure** (*SB Creative / GA Novel*).
- **Original Mod Creator**: Originally created by **lk** for the Don't Starve community on the Steam Workshop ([Original Steam Mod #3604181203](https://steamcommunity.com/sharedfiles/filedetails/?id=3604181203&tscn=1790467654)).
- **This Enhanced Version**: Maintained by the community as an open-source project. Code has been cleaned, translated into English, fixed and re-balanced.

> **Hoki (Broom-san) and the Traveler's Warded Pack are temporarily removed.** They used borrowed models (a pink-tinted Elaina and the vanilla backpack). They will come back once they have their own art. Their code remains in the git history (commit `05419d6`).
>
> Saves from older versions load fine, but a Hoki in the world disappears, and **items stored in the Traveler's Pack are lost**. Empty the pack before updating.

---

## Features

### 1. Elaina - The Ashen Witch
- **Stats**: 120 Health, 150 Hunger, 120 Sanity. A witch, not a brawler: -25% physical damage (like Wendy), with a slower sanity drain at night.
- **Innate Genius**: +1 Science tier everywhere. She can craft the `lantern`, `compass` and `sewing_kit` without prototyping them.
- **Her own voice**: Confident, a little vain and pragmatic. She would rather not get involved.
- **Witchcraft tab**: Elaina can remake her broom, hat, wand and grimoire if she loses them.

### 2. Leveling
- EXP from kills (scaled by the creature's strength) and from eating.
- EXP per level is `100 + 20 x level`. Level 10 takes about 1,800 EXP (a few days), level 20 about 5,700, level 50 about 29,400. Max level is 100.
- Each level adds +1 max Health/Hunger/Sanity and +0.5% damage (both configurable).
- **Level 20**: +10% move speed. **Level 50**: +20% move speed and a light weather ward (60 insulation against both cold and heat).
- Press **L** to see your level, EXP, and the Mana Barrier status.

### 3. Witch's Broom and Flight (Level 10+)
- Hold the broom and press **R** to fly: +60% speed, pass over walls, trees, boulders and creatures, and collect loose items within reach.
- 10s base duration (+1s every 5 levels above 10). Costs 1 sanity per second (configurable). 3 seconds of rest after landing.
- Flight keeps you over land and out of Hamlet interiors, so you can never be dropped into the sea or out of a room.

### 4. Magic
- **Magic Wand**: Fires homing star bolts (25 damage). Each hit costs 1 sanity (configurable).
- **Gale Repulsion (Z)**: Hits hostile creatures within 8 units for 25 damage and knocks them back onto solid ground. Neutral animals and followers are unaffected. Costs 10 sanity, 12s cooldown.
- **Mana Barrier**: Once per day, a lethal hit leaves Elaina at low health instead, heals her by 25 and casts a free Gale. The cooldown is saved with your game.
- **Ancient Grimoire**: Reading it restores 40 sanity, once per day.

### 5. Potions (Magic tab, craft at a Shadow Manipulator)
- **Mana Potion / Primordial Water**: Restore 5 Health and 5 Sanity every 3 seconds for 36 seconds.
- **Frost Elixir**: A Frost Nova that freezes nearby hostile creatures and puts out fires. For 30s, +25% damage, and your weapon's hits add frost (the weapon's own effects are kept).
- **Traveler's Potion**: A caffeinated speed boost (Shipwrecked/Hamlet).

---

## Mod Configuration (modinfo.lua)

| Setting | Options | Default | Description |
| :--- | :--- | :--- | :--- |
| **EXP Multiplier** | `0.5x` - `3.0x` | `1.0x` | Leveling speed from kills & food |
| **Broom Damage** | `17`, `25`, `34`, `50` | `34` | Melee damage of the broom |
| **Wand Damage** | `20`, `25`, `34`, `50` | `25` | Damage of each star bolt |
| **Wand Focus Cost** | `0`, `0.5`, `1`, `2` | `1` | Sanity per wand hit |
| **Hat Waterproof** | `35%`, `50%`, `70%`, `100%` | `100%` | Rain protection of Elaina's hat |
| **Damage / Level** | `0%` - `+1.0%` | `+0.5%` | Attack bonus per level |
| **Stats / Level** | `+0`, `+1`, `+2` | `+1` | Max Health/Hunger/Sanity per level |
| **Flight Duration** | `5s` - `30s` | `10s` | Base flight time at level 10 |
| **Flight Cost / sec** | `0` - `2.0/s` | `1.0/s` | Sanity per second while flying |

---

## Repository Structure

When publishing to GitHub or installing locally, ensure all mod assets and directories are included:

```text
Elaina_Fix/
├── .github/                # GitHub Actions CI workflow definitions
├── anim/                   # Character animations & item builds (.zip)
├── bigportraits/           # Character select & companion portraits (.tex / .xml)
├── images/
│   ├── avatars/            # HUD badges and avatar icons
│   ├── inventoryimages/    # Item inventory icons & atlases
│   ├── map_icons/          # Minimap icons
│   ├── saveslot_portraits/ # Save slot UI portraits
│   └── selectscreen_portraits/
├── minimap/                # Minimap prefab atlases
├── scripts/
│   ├── brains/             # AI Brains
│   ├── components/         # Custom Lua components (level.lua, magicpoint.lua, etc.)
│   ├── prefabs/            # Entity prefabs (elena, elena_broom, potions, etc.)
│   └── stategraphs/        # StateGraphs
├── sound/                  # Audio banks (.fsb / .fev)
├── tests/                  # Automated test suite (Python / Lua 5.1 CI)
├── modicon.tex             # Mod listing icon texture
├── modicon.xml             # Mod listing icon atlas
├── modinfo.lua             # Mod metadata and configuration menu options
├── modmain.lua             # Main mod initialization and hook scripts
├── change log.txt          # Version update log
├── README.md               # Documentation
└── CREDITS.md              # Attribution and copyright acknowledgments
```

---

## Installation

1. Clone or download this repository.
2. Place the folder into your Don't Starve mods directory:
   - **Windows**: `C:\Program Files (x86)\Steam\steamapps\common\dont_starve\mods\Elaina_Fix`
   - **Mac**: `~/Library/Application Support/Steam/steamapps/common/dont_starve/mods/Elaina_Fix`
   - **Linux**: `~/.steam/steam/steamapps/common/dont_starve/mods/Elaina_Fix`
3. Launch **Don't Starve**, enter the **Mods** menu, enable **Elaina**, and configure your preferred settings.

---

## License and Disclaimer

- The code enhancements and modifications in this repository are distributed under the **MIT License**.
- *Majo no Tabitabi* (*The Wandering Witch: The Journey of Elaina*) is copyright (c) **Jougi Shiraishi**, **Azure**, and **SB Creative Corp.**
- *Don't Starve* is a registered trademark of **Klei Entertainment**.
- This project is a non-commercial, fan-made mod created for community entertainment.
