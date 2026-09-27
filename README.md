# Elaina - The Wandering Witch (Majo no Tabitabi)
### Don't Starve Singleplayer Mod (Reign of Giants / Shipwrecked / Hamlet)

[![Don't Starve Mod](https://img.shields.io/badge/Don't_Starve-Compatible-green.svg)](https://www.klei.com/games/dont-starve)
[![DLC Support](https://img.shields.io/badge/DLC-RoG%20%7C%20Shipwrecked%20%7C%20Hamlet-blue.svg)](https://store.steampowered.com/app/219740/Dont_Starve/)
[![CI Tests](https://github.com/Cazacu-Condrat-Dumitru/Elaina_Fix/actions/workflows/ci.yml/badge.svg)](https://github.com/Cazacu-Condrat-Dumitru/Elaina_Fix/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An enhanced, community-maintained character mod bringing **Elaina (The Ashen Witch)** and her loyal companion **Hoki (Broom-san)** from *Wandering Witch: The Journey of Elaina* (*Majo no Tabitabi*) into **Don't Starve**.

This repository contains a full English localization, extensive bug fixes, modern balance adjustments, lore-accurate flight mechanics, and the complete transformable Hoki companion system.

---

## Background and Attribution

- **Original Character & Story**: Created by **Jougi Shiraishi** with original illustrations by **Azure** (*SB Creative / GA Novel*).
- **Original Mod Creator**: Originally created by **lk** for the Don't Starve community.
- **This Enhanced Version**: Maintained by the community as an open-source project. Code and assets have been cleaned, translated into English, re-balanced, and extended with lore-accurate gameplay features. Note: Hoki currently uses the original character model with customized pink hair, custom portraits, and minimap icons; dedicated custom models and level-based visual updates will be created in future releases.

---

## Key Features

### 1. Elaina - The Ashen Witch
- **Innate Genius**: As the youngest witch to pass the sorcery exam, Elaina starts with innate scientific insight:
  - Grants $+1$ Science Tier bonus.
  - Can craft essential traveler instruments (`lantern`, `compass`, `sewing_kit`) from memory without requiring advanced research prototypes.
- **Leveling and Experience System**:
  - Gains EXP by defeating hostile creatures and consuming cooked meals.
  - Max Level: **100**.
  - Each level permanently increases maximum Health, Hunger, Sanity, and spell potency.
- **Three-Tier Light Novel Progression**:
  - **Tier 1: Apprentice Traveler (Levels 1 - 19 / Vol. 1-3 & Anime)**: Classic young Ashen Witch traveling gear, learning the mysteries of the wilderness.
  - **Tier 2: Wandering Sorceress (Levels 20 - 49 / Vol. 4-15)**: Unlocks an ambient warm magical light source (`Light` radius 2.4) making night travel safe, $+10\%$ bonus movement speed, and $+5\text{s}$ base flight duration.
  - **Tier 3: Legendary Arch-Witch (Levels 50 - 100 / Vol. 7 mid-20s & Animate 2025 Grand Form)**: Unlocks a radiant celestial starlight aura (`Light` radius 4.0), continuous star sparkle particles, $+20\%$ travel speed, and innate **Mana Shield** thermal resistance against extreme heat and freezing cold.

### 2. Witch's Broom and Aerial Flight (Level 10+)
- **Dual-Function Weapon**:
  - High durability melee weapon with configurable damage (Spear, Default 50, or Dark Sword tier).
- **High-Speed Flight (Hotkey: `R`)**:
  - Unlocked at **Level 10** when the broom is equipped in hands.
  - Base duration: **10 seconds** (configurable), gaining $+1\text{s}$ duration every 5 levels.
  - Grants **$+60\%$ movement speed**, ignores ground obstacles and walls (`COLLISION.FLYERS`), glides freely across rivers and open oceans, and leaves a sparkling starlight particle trail.
  - Consumes a gentle stream of sanity while airborne. Includes a safe water-landing grace period.

### 3. Hoki (Broom-san) - Dual Form Companion
In the light novel and anime, Elaina develops a magical spell that temporarily bestows her broom with human form.

- **Dual-Form Transformation**:
  - The player can start the game with the broom in weapon form or Hoki in person (configurable in mod settings).
  - Use the **Ancient Grimoire** (`book_ancientmagic`) to awaken the broom into Hoki, or return her to weapon form whenever needed.
  - When Hoki's health reaches 0 in combat, she never dies permanently; instead, she gently returns to broom form to rest.
- **Autonomous Ranged Magic Combat**:
  - Hoki stays close to Elaina, engaging hostile monsters with homing magical starlight projectiles (`light_projectile`).
  - Protects Elaina from ambushes and automatically targets whatever attacks her mistress.
- **Sweets and Potions Upgrade System**:
  - **Sweets (Honey, Taffy, Waffles, Cake)**: Increases Hoki's maximum Health by $+10$ and restores HP.
  - **Magic Potions (`potion_magic`, `potion_sourceliquid`)**: Increases Hoki's magic attack power by $+2$ and fully heals her.
- **Multi-Stage Power Evolution (Planned Visual Model Updates)**:
  - Currently, Hoki uses the original character model with customized pink hair, custom portraits, and minimap icons.
  - **Stage 1 (Apprentice Form)**: Base health and cheerful banter.
  - **Stage 2 (Arch-Witch Form)**: Unlocks an ambient rose-pink light aura, 1.06 scale, $+10\%$ bonus damage, and scaling health.
  - **Stage 3 (Starlight Witch Form)**: Brilliant celestial starlight radiance (light radius 3.8), continuous star particle aura, and enhanced projectile potency.
  - *Future Update Plan*: Dedicated brand-new models and visual updates corresponding to each level tier will be created and added in future versions.
- **Canon Personality and Dialogue**:
  - Voiced in text with pastel pink font.
  - Speaks genuine, cheerful, and polite quotes calling Elaina *"Lady Elaina"*, playfully teasing her when summoned for *"an extra pair of hands"*, and reminding her to eat sweets when hungry.

### 4. Traveler's Warded Pack (elena_pack)
- **14-Slot Grand Capacity (Krampus Sack Size)**: Fitted with a spacious 14-slot inventory (7x2 grid) using vanilla container frames, allowing Elaina to transport abundant spell reagents, collected flora, and survival provisions. Configurable in settings (8, 10, or 14 slots).
- **75% Defensive Ward**: Woven with starlight wards, providing 75% physical damage reduction without needing bulky wooden or marble armor.
- **Hands-Free Starlight Illumination**: Emits a soft celestial glow while equipped on the body, freeing both hands for weapons or broom flight at night.
- **Food Preservation**: Features magical cooling that halves food and ingredient spoilage rate (acting as an enchanted travel cooler).
- **Thermal & Weather Insulation**: Protects against hypothermia in winter and overheating in summer, plus 50% water resistance.
- **Craftable & Starter Gear**: Elaina starts with her satchel, and can re-craft it from the Survival tab with basic materials (grass, twigs, rope).

### 5. Defensive Magic & Flight Utility
- **Gale Repulsion (Hotkey: `Z`)**: Releases a concussive burst of starlight wind that repels nearby aggressive enemies up to 7 units away, staggering attackers and creating breathing room.
- **Mana Barrier (Emergency Ward)**: If Elaina receives a lethal blow that would otherwise kill her, her mana barrier instantly activates, negating death, restoring an emergency health buffer, releasing an automatic Gale Repulsion, and entering a 3-minute cooldown.
- **Flight Resource Magnetism**: While soaring on her broom, nearby ground resources (grass, twigs, flint, petals, monster loot) are automatically collected into inventory or pack.
- **Frost Nova (Frost Elixir)**: Consuming `potion_icepowder` now unleashes a Frost Nova, instantly freezing nearby monsters and putting out fires in a 12-unit radius in addition to temporarily enchanting equipped weapons with ice attacks.

---

## Mod Configuration (modinfo.lua)

All settings use concise labels designed specifically to fit neatly inside Don't Starve's configuration menus:

| Setting | Options | Default | Description |
| :--- | :--- | :--- | :--- |
| **EXP Multiplier** | `0.5x`, `1.0x`, `1.5x`, `2.0x`, `3.0x` | `1.0x` | Controls leveling speed from kills & food |
| **Broom Damage** | `34`, `50`, `68`, `100` | `50` | Base damage of Elaina's broom weapon |
| **Wand Damage** | `25`, `34`, `50`, `68`, `100` | `34` | Ranged damage of the Magic Wand |
| **Hat Waterproof** | `50%`, `70%`, `90%`, `100%` | `100%` | Water resistance granted by Elaina's Hat |
| **Damage / Level** | `0%`, `+0.5%`, `+1.0%`, `+2.0%` | `+1.0%` | Bonus attack power gained per level |
| **Flight Duration** | `5s`, `10s`, `15s`, `20s`, `30s` | `10s` | Base flight duration at Level 10 |
| **Flight Cost / sec**| `0/s`, `0.5/s`, `1.0/s`, `2.0/s` | `1.0/s` | Sanity consumed per second while flying |
| **Broom Spell Cost** | `0`, `15`, `25`, `40` | `25` | Sanity cost to awaken Hoki via the Grimoire |
| **Starting Form** | `Broom`, `Hoki` | `Broom` | Start with broom weapon or Hoki companion |
| **Hoki Max Health** | `150`, `250`, `400`, `600` | `250` | Base health of Hoki companion |
| **Hoki Magic Damage**| `20`, `34`, `50`, `68` | `34` | Ranged magical projectile attack damage |
| **Hoki Sanity Aura** | `0`, `+2.4/m`, `+5.0/m`, `+10.0/m` | `+5.0/m` | Passive sanity restoration near Hoki |
| **Hoki Command Key** | `V`, `Z`, `X`, `C`, `B`, `G`, `H`, `J`, `K` | `V` | Keyboard hotkey for companion commands |
| **Satchel Slots** | `8 Slots`, `10 Slots`, `14 Slots` | `14 Slots` | Storage capacity of the Traveler Pack |

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
│   ├── map_icons/          # Minimap icons for Elaina and Hoki
│   ├── saveslot_portraits/ # Save slot UI portraits
│   └── selectscreen_portraits/
├── minimap/                # Minimap prefab atlases
├── scripts/
│   ├── brains/             # AI Brains (hokibrain.lua, etc.)
│   ├── components/         # Custom Lua components (level.lua, magicpoint.lua, etc.)
│   ├── prefabs/            # Entity prefabs (elena, hoki, elena_broom, etc.)
│   └── stategraphs/        # StateGraphs (SGhoki.lua, etc.)
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
