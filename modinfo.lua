name = "Elaina"
description = "Elaina - The Wandering Witch (Majo no Tabitabi)\n\nBugfix, balance & English translation.\n[R] Fly (Lvl 10)  [Z] Gale  [L] Status"
author = "lk"
version = "1.1"
forumthread = "https://steamcommunity.com/sharedfiles/filedetails/?id=3604181203&tscn=1790467654"
api_version = 6
dont_starve_compatible = true
reign_of_giants_compatible = true
hamlet_compatible = true
shipwrecked_compatible = true
dst_compatible = false
icon_atlas = "modicon.xml"
icon = "modicon.tex"

configuration_options = {
    {
        name = "exp_rate",
        label = "EXP Multiplier",
        hover = "Adjust the amount of EXP gained from kills and food.",
        options = {
            {description = "0.5x", data = 0.5},
            {description = "1.0x", data = 1.0},
            {description = "1.5x", data = 1.5},
            {description = "2.0x", data = 2.0},
            {description = "3.0x", data = 3.0},
        },
        default = 1.0,
    },
    {
        name = "broom_damage",
        label = "Broom Damage",
        hover = "Melee damage of the Witch's Broom (it's for flying, not fighting).",
        options = {
            {description = "17", data = 17},
            {description = "25", data = 25},
            {description = "34 (Spear)", data = 34},
            {description = "50 (Original)", data = 50},
        },
        default = 34,
    },
    {
        name = "wand_damage",
        label = "Wand Damage",
        hover = "Damage of each Magic Wand star bolt.",
        options = {
            {description = "20", data = 20},
            {description = "25 (Original)", data = 25},
            {description = "34", data = 34},
            {description = "50", data = 50},
        },
        default = 25,
    },
    {
        name = "wand_sanity_cost",
        label = "Wand Focus Cost",
        hover = "Sanity spent for each Magic Wand bolt that hits.",
        options = {
            {description = "0 (Free)", data = 0},
            {description = "0.5", data = 0.5},
            {description = "1", data = 1},
            {description = "2", data = 2},
        },
        default = 1,
    },
    {
        name = "hat_waterproof",
        label = "Hat Waterproof",
        hover = "Water resistance granted by Elaina's Hat.",
        options = {
            {description = "35%", data = 0.35},
            {description = "50%", data = 0.5},
            {description = "70%", data = 0.7},
            {description = "100% (Original)", data = 1.0},
        },
        default = 1.0,
    },
    {
        name = "level_damage_bonus",
        label = "Damage / Level",
        hover = "Bonus attack power gained with each level.",
        options = {
            {description = "0%", data = 0.0},
            {description = "+0.25%", data = 0.0025},
            {description = "+0.5%", data = 0.005},
            {description = "+1.0%", data = 0.01},
        },
        default = 0.005,
    },
    {
        name = "stats_per_level",
        label = "Stats / Level",
        hover = "Max Health, Hunger and Sanity gained with each level.",
        options = {
            {description = "+0", data = 0},
            {description = "+1", data = 1},
            {description = "+2 (Original)", data = 2},
        },
        default = 1,
    },
    {
        name = "flight_base_duration",
        label = "Flight Duration",
        hover = "Base duration (in seconds) of broom flight at Level 10.",
        options = {
            {description = "5s", data = 5},
            {description = "10s", data = 10},
            {description = "15s", data = 15},
            {description = "20s", data = 20},
            {description = "30s", data = 30},
        },
        default = 10,
    },
    {
        name = "flight_sanity_cost",
        label = "Flight Cost / sec",
        hover = "Sanity consumed per second while flying.",
        options = {
            {description = "0/s", data = 0.0},
            {description = "0.5/s", data = 0.5},
            {description = "1.0/s", data = 1.0},
            {description = "2.0/s", data = 2.0},
        },
        default = 1.0,
    },
}
