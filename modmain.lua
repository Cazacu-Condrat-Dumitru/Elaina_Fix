local require = GLOBAL.require
local Ingredient = GLOBAL.Ingredient
local RECIPETABS = GLOBAL.RECIPETABS
local STRINGS = GLOBAL.STRINGS
local TECH = GLOBAL.TECH
local Action = GLOBAL.Action
local ActionHandler = GLOBAL.ActionHandler
local ACTIONS = GLOBAL.ACTIONS
local TheInput = GLOBAL.TheInput
local GetPlayer = GLOBAL.GetPlayer
local GetWorld = GLOBAL.GetWorld
local TimeEvent = GLOBAL.TimeEvent
local EventHandler = GLOBAL.EventHandler
local FRAMES = GLOBAL.FRAMES
local State = GLOBAL.State
local SpawnPrefab = GLOBAL.SpawnPrefab
local Vector3 = GLOBAL.Vector3
local FindEntity = GLOBAL.FindEntity
local TUNING = GLOBAL.TUNING
local Recipe = GLOBAL.Recipe
local Widget = GLOBAL.require('widgets/widget')
local Image = GLOBAL.require('widgets/image')
local Text = GLOBAL.require('widgets/text')
local Badge = GLOBAL.require("widgets/badge")

-- Retrieve configuration options from mod settings
TUNING.BROOM_DAMAGE = GetModConfigData("broom_damage") or 50
TUNING.MAGICSTAR_DAMAGE = GetModConfigData("wand_damage") or 34
TUNING.ELENA_HAT_WATERPROOF = GetModConfigData("hat_waterproof") or 1.0
TUNING.ELENA_EXP_RATE = GetModConfigData("exp_rate") or 1.0
TUNING.ELENA_LEVEL_DAMAGE_BONUS = GetModConfigData("level_damage_bonus") or 0.01
TUNING.ELENA_FLIGHT_BASE_DURATION = GetModConfigData("flight_base_duration") or 10
TUNING.ELENA_FLIGHT_SANITY_COST = GetModConfigData("flight_sanity_cost") or 1.0
TUNING.ELENA_BROOM_COMPANION_COST = GetModConfigData("broom_companion_cost") or 25
TUNING.HOKI_START_MODE = GetModConfigData("hoki_start_mode") or "broom"
TUNING.HOKI_HEALTH = GetModConfigData("hoki_health") or 250
TUNING.HOKI_DAMAGE = GetModConfigData("hoki_damage") or 34
TUNING.HOKI_SANITY_AURA = GetModConfigData("hoki_sanity_aura") or 5.0
TUNING.HOKI_COMMAND_KEY = GetModConfigData("hoki_command_key") or "KEY_V"

TUNING.BROOM_RANGE = 1
TUNING.ELENA_HUNGER = 150
TUNING.ELENA_HEALTH = 120
TUNING.ELENA_SANITY = 120
TUNING.ELENA_MAXLEVEL = 100

GLOBAL.TUNING.CRITTER_WALK_SPEED = 6
local total_day_time = GLOBAL.TUNING.TOTAL_DAY_TIME
GLOBAL.TUNING.CRITTER_HUNGERTIME = total_day_time * 3.14159265359 * 0.75
local seg_time = 30
GLOBAL.TUNING.CRITTER_WALK_SPEED = 6
GLOBAL.TUNING.CRITTER_HUNGERTIME = total_day_time * 3.25
GLOBAL.TUNING.CRITTER_HUNGERTIME_MIN = total_day_time * 2
GLOBAL.TUNING.CRITTER_HUNGERTIME_MAX = total_day_time * 4.5
GLOBAL.TUNING.CRITTER_HUNGERTIME_DELTA = seg_time * 4.0
GLOBAL.TUNING.CRITTER_EMOTE_DELAY = seg_time * 0.5

Assets = {
    Asset("IMAGE", "images/inventoryimages/magic_hat.tex"),
    Asset("ATLAS", "images/inventoryimages/magic_hat.xml"),
    Asset("IMAGE", "images/inventoryimages/book_ancientmagic.tex"),
    Asset("ATLAS", "images/inventoryimages/book_ancientmagic.xml"),
    Asset("ANIM", "anim/kitten_winter.zip"),
    Asset("ANIM", "anim/kittington_basic.zip"),
    Asset("ANIM", "anim/kittington_build.zip"),
    Asset("ANIM", "anim/kittington_emotes.zip"),
    Asset("ATLAS", "images/inventoryimages/critter_kitten_builder.xml"),
    Asset("ATLAS", "images/inventoryimages/kitten_winter.xml"),
    Asset("ATLAS", "images/lines_down.xml"),
    Asset("ATLAS", "images/lines_up.xml"),
    Asset("SOUND", "sound/kittington.fsb"),
    Asset("IMAGE", "images/inventoryimages/pumpkin_light.tex"),
    Asset("ATLAS", "images/inventoryimages/pumpkin_light.xml"),
    Asset("IMAGE", "images/inventoryimages/potions.tex"),
    Asset("ATLAS", "images/inventoryimages/potions.xml"),
    Asset("ATLAS", "images/saveslot_portraits/elena.xml"),
    Asset("IMAGE", "images/inventoryimages/elena.tex"),
    Asset("ATLAS", "images/inventoryimages/elena.xml"),
    Asset("ATLAS", "images/selectscreen_portraits/elena.xml"),
    Asset("ATLAS", "images/selectscreen_portraits/elena_silho.xml"),
    Asset("ATLAS", "bigportraits/elena.xml"),
    Asset("ATLAS", "bigportraits/elena_none.xml"),
    Asset("ATLAS", "bigportraits/hoki.xml"),
    Asset("ATLAS", "images/avatars/avatar_elena.xml"),
    Asset("ATLAS", "images/avatars/avatar_ghost_elena.xml"),
    Asset("ATLAS", "images/avatars/avatar_hoki.xml"),
    Asset("ATLAS", "images/avatars/self_inspect_elena.xml"),
    Asset("ATLAS", "images/names_elena.xml"),
    Asset("ATLAS", "images/map_icons/elena.xml"),
    Asset("ATLAS", "images/map_icons/hoki.xml")
}

PrefabFiles = {
    "elena", "elena_broom", "elena_hat", "elena_magicstar", "potion_magic",
    "potion_icepowder", "potion_soar", "potion_sourceliquid", "pumpkin_light",
    "book_ancientmagic", "blackcat_fish", "blackcat2", "light_projectile", "hoki",
    "elena_pack"
}

local IsDLC1 = GLOBAL.IsDLCEnabled(GLOBAL.REIGN_OF_GIANTS)
local IsDLC2 = GLOBAL.IsDLCEnabled(GLOBAL.CAPY_DLC)
local IsDLC3 = GLOBAL.IsDLCEnabled(GLOBAL.PORKLAND_DLC)

-- Character Strings
STRINGS.CHARACTER_TITLES.elena = "Elaina"
STRINGS.CHARACTER_NAMES.elena = "Elaina"
STRINGS.CHARACTER_DESCRIPTIONS.elena = "When you sigh, happiness slips away."
STRINGS.CHARACTER_QUOTES.elena = "Seems like it's not okay after all."
STRINGS.CHARACTERS.ELENA = require "speech_wendy"
STRINGS.NAMES.elena = "Elaina"
STRINGS.NAMES.ELENA = "Elaina"
GLOBAL.STRINGS.NAMES.elena = "Elaina"
GLOBAL.STRINGS.NAMES.ELENA = "Elaina"

GLOBAL.STRINGS.NAMES.HOKI = "Hoki"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOKI = "Elaina's faithful broom, awakened in human form!"
GLOBAL.STRINGS.CHARACTERS.ELENA.DESCRIBE.HOKI = "My precious broom. Thank you for always helping me, Hoki!"

AddModCharacter("elena", "FEMALE")
AddMinimapAtlas("images/map_icons/elena.xml")
AddMinimapAtlas("images/map_icons/hoki.xml")

-- Item and Critter Strings
GLOBAL.STRINGS.NAMES.CRITTER_KITTEN_BUILDER = "Little Kitten"
GLOBAL.STRINGS.RECIPE_DESC.CRITTER_KITTEN_BUILDER = "A cute little kitten!"
GLOBAL.STRINGS.NAMES.CRITTER_KITTEN = "Little Kitten"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.CRITTER_KITTEN = "It will grow into a lovely cat girl!"

GLOBAL.STRINGS.NAMES.ELENA_BROOM = "Witch's Broom"
GLOBAL.STRINGS.RECIPE_DESC.ELENA_BROOM = "A magical flying broom."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.ELENA_BROOM = "A witch's favorite broom."

GLOBAL.STRINGS.NAMES.ELENA_HAT = "Witch's Hat"
GLOBAL.STRINGS.RECIPE_DESC.ELENA_HAT = "A hat is an essential part of the persona."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.ELENA_HAT = "A classic pointed witch hat."

GLOBAL.STRINGS.NAMES.ELENA_MAGICSTAR = "Magic Wand"
GLOBAL.STRINGS.RECIPE_DESC.ELENA_MAGICSTAR = "Shoots homing magical bolts."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.ELENA_MAGICSTAR = "Magic wand with homing star projectiles."

GLOBAL.STRINGS.NAMES.PUMPKIN_LIGHT = "Witch Pumpkin Lantern"
GLOBAL.STRINGS.RECIPE_DESC.PUMPKIN_LIGHT = "A spooky glowing lantern."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.PUMPKIN_LIGHT = "A gentle flicker of flame."

GLOBAL.STRINGS.NAMES.POTION_SOURCELIQUID = "Primordial Water"
GLOBAL.STRINGS.RECIPE_DESC.POTION_SOURCELIQUID = "The origin of all life."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.POTION_SOURCELIQUID = "Filled with primal essence."

GLOBAL.STRINGS.NAMES.POTION_ICEPOWDER = "Frost Elixir"
GLOBAL.STRINGS.RECIPE_DESC.POTION_ICEPOWDER = "Chilling to the bone."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.POTION_ICEPOWDER = "Radiates intense cold."

GLOBAL.STRINGS.NAMES.POTION_MAGIC = "Mana Potion"
GLOBAL.STRINGS.RECIPE_DESC.POTION_MAGIC = "Is this magic?"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.POTION_MAGIC = "A vial of pure magical power."

GLOBAL.STRINGS.NAMES.POTION_SOAR = "Traveler's Potion"
GLOBAL.STRINGS.RECIPE_DESC.POTION_SOAR = "Run swift and fast."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.POTION_SOAR = "Grants great travel speed."

-- Potion Recipes in Magic Tab (Visible for inspection and previewing ingredients, locked behind Magic station)
local potion_magic_rec = Recipe("potion_magic", {Ingredient("petals", 4), Ingredient("nightmarefuel", 1), Ingredient("blue_cap", 1)}, RECIPETABS.MAGIC, TECH.MAGIC_TWO, nil, nil, true)
potion_magic_rec.atlas = "images/inventoryimages/potions.xml"
potion_magic_rec.image = "potion_magic.tex"

local potion_sourceliquid_rec = Recipe("potion_sourceliquid", {Ingredient("livinglog", 1), Ingredient("honey", 2), Ingredient("red_cap", 1)}, RECIPETABS.MAGIC, TECH.MAGIC_TWO, nil, nil, true)
potion_sourceliquid_rec.atlas = "images/inventoryimages/potions.xml"
potion_sourceliquid_rec.image = "potion_sourceliquid.tex"

local potion_icepowder_rec = Recipe("potion_icepowder", {Ingredient("ice", 3), Ingredient("bluegem", 1), Ingredient("butterflywings", 2)}, RECIPETABS.MAGIC, TECH.MAGIC_TWO, nil, nil, true)
potion_icepowder_rec.atlas = "images/inventoryimages/potions.xml"
potion_icepowder_rec.image = "potion_icepowder.tex"

local potion_soar_rec = Recipe("potion_soar", {Ingredient("feather_robin", 2), Ingredient("honey", 2), Ingredient("papyrus", 1)}, RECIPETABS.MAGIC, TECH.MAGIC_TWO, nil, nil, true)
potion_soar_rec.atlas = "images/inventoryimages/potions.xml"
potion_soar_rec.image = "potion_soar.tex"

-- Traveler's Warded Pack (75% armor, starlight, cooling/warming charm)
GLOBAL.STRINGS.NAMES.ELENA_PACK = "Traveler's Warded Pack"
GLOBAL.STRINGS.RECIPE_DESC.ELENA_PACK = "An enchanted satchel offering 75% defense, cooling, and starlight."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.ELENA_PACK = "A witch's enchanted travel satchel with magical protection."
local elena_pack_rec = Recipe("elena_pack", {Ingredient("cutgrass", 4), Ingredient("twigs", 4), Ingredient("rope", 1)}, RECIPETABS.SURVIVAL, TECH.NONE)
elena_pack_rec.atlas = "images/inventoryimages.xml"
elena_pack_rec.image = "backpack.tex"

GLOBAL.STRINGS.NAMES.BOOK_ANCIENTMAGIC = "Ancient Grimoire"
GLOBAL.STRINGS.RECIPE_DESC.BOOK_ANCIENTMAGIC = "This book..."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.BOOK_ANCIENTMAGIC = "Contains forgotten magic."

GLOBAL.STRINGS.NAMES.BLACKCAT = "Black Cat"
GLOBAL.STRINGS.NAMES.BLACKCAT2 = "Black Cat"
GLOBAL.STRINGS.RECIPE_DESC.BLACKCAT = "Mysterious feline."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.BLACKCAT = "A witch's loyal familiar."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.BLACKCAT2 = "A witch's loyal familiar."

GLOBAL.STRINGS.NAMES.BLACKCAT_FISH = "Fish for Cat"
GLOBAL.STRINGS.RECIPE_DESC.BLACKCAT_FISH = "Tasty fish treat."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.BLACKCAT_FISH = "A delicious meal for a black cat."

local NUZZLE = Action({})
NUZZLE.str = 'Nuzzle'
NUZZLE.id = "NUZZLE"
NUZZLE.fn = function(act)
    if act.target then
        return true
    end
end
AddAction(NUZZLE)

local function P_PI(inst)
    if inst and not inst.components.huapetleash then
        inst:AddComponent('huapetleash')
    end
end

local function onattacked(inst, data)
    if inst.components.follower.leader == data.attacker then
        inst:DoTaskInTime(1, function()
            inst.components.follower:SetLeader(data.attacker)
        end)
    end
end

local function F_CPN_PI(self, inst)
    local OldFn = self.KeepLeaderOnAttacked
    function self:KeepLeaderOnAttacked(...)
        if type(OldFn) == 'function' then
            OldFn(self, ...)
        end
        self.inst:ListenForEvent("attacked", onattacked)
    end
end

AddPlayerPostInit(P_PI)
AddComponentPostInit('follower', F_CPN_PI)

-- Fix: Prevents the head from disappearing when wearing vanilla/other hats
AddPlayerPostInit(function(inst)
    if inst.prefab == "elena" then
        inst.AnimState:OverrideSymbol("headbase_hat", "elena", "headbase")
    end
end)