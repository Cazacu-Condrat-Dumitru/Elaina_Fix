name = "Elaina"
description = "Elaina - The Wandering Witch (Majo no Tabitabi)\n\nBugfix & English Translation version."
author = "lk"
version = "1.0"
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
        hover = "Base melee damage of Elaina's Broom.",
        options = {
            {description = "34", data = 34},
            {description = "50", data = 50},
            {description = "68", data = 68},
            {description = "100", data = 100},
        },
        default = 50,
    },
    {
        name = "wand_damage",
        label = "Wand Damage",
        hover = "Ranged projectile damage of Elaina's Magic Wand.",
        options = {
            {description = "25", data = 25},
            {description = "34", data = 34},
            {description = "50", data = 50},
            {description = "68", data = 68},
            {description = "100", data = 100},
        },
        default = 34,
    },
    {
        name = "hat_waterproof",
        label = "Hat Waterproof",
        hover = "Water resistance percentage granted by Elaina's Hat.",
        options = {
            {description = "50%", data = 0.5},
            {description = "70%", data = 0.7},
            {description = "90%", data = 0.9},
            {description = "100%", data = 1.0},
        },
        default = 1.0,
    },
    {
        name = "level_damage_bonus",
        label = "Damage / Level",
        hover = "Bonus attack power gained with each level.",
        options = {
            {description = "0%", data = 0.0},
            {description = "+0.5%", data = 0.005},
            {description = "+1.0%", data = 0.01},
            {description = "+2.0%", data = 0.02},
        },
        default = 0.01,
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
    {
        name = "broom_companion_cost",
        label = "Broom Spell Cost",
        hover = "Sanity cost to summon/transform the Broom Companion at Level 10.",
        options = {
            {description = "0", data = 0},
            {description = "15", data = 15},
            {description = "25", data = 25},
            {description = "40", data = 40},
        },
        default = 25,
    },
    {
        name = "hoki_start_mode",
        label = "Starting Form",
        hover = "Choose whether to begin with the Broom weapon or Hoki in person.",
        options = {
            {description = "Broom", data = "broom"},
            {description = "Hoki", data = "hoki"},
        },
        default = "broom",
    },
    {
        name = "hoki_health",
        label = "Hoki Max Health",
        hover = "Base health of Hoki in human companion form.",
        options = {
            {description = "150", data = 150},
            {description = "250", data = 250},
            {description = "400", data = 400},
            {description = "600", data = 600},
        },
        default = 250,
    },
    {
        name = "hoki_damage",
        label = "Hoki Magic Damage",
        hover = "Ranged magical attack damage dealt by Hoki.",
        options = {
            {description = "20", data = 20},
            {description = "34", data = 34},
            {description = "50", data = 50},
            {description = "68", data = 68},
        },
        default = 34,
    },
    {
        name = "hoki_sanity_aura",
        label = "Hoki Sanity Aura",
        hover = "Sanity restoration aura granted to Elaina when Hoki is nearby.",
        options = {
            {description = "0", data = 0},
            {description = "+2.4/m", data = 2.4},
            {description = "+5.0/m", data = 5.0},
            {description = "+10.0/m", data = 10.0},
        },
        default = 5.0,
    },
    {
        name = "hoki_command_key",
        label = "Hoki Command Key",
        hover = "Keyboard hotkey to issue commands / cycle modes for Hoki (Farm, Battle, Passive, Broom).",
        options = {
            {description = "V (Default)", data = "KEY_V"},
            {description = "Z", data = "KEY_Z"},
            {description = "X", data = "KEY_X"},
            {description = "C", data = "KEY_C"},
            {description = "B", data = "KEY_B"},
            {description = "G", data = "KEY_G"},
            {description = "H", data = "KEY_H"},
            {description = "J", data = "KEY_J"},
            {description = "K", data = "KEY_K"},
            {description = "Disabled", data = "disabled"},
        },
        default = "KEY_V",
    },
    {
        name = "pack_size",
        label = "Satchel Slots",
        hover = "Storage capacity of Elaina's Traveler Warded Pack.",
        options = {
            {description = "8 Slots", data = 8},
            {description = "10 Slots", data = 10},
            {description = "14 Slots (Default)", data = 14},
        },
        default = 14,
    },
}