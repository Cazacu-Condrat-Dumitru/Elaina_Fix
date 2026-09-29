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
TUNING.BROOM_DAMAGE = GetModConfigData("broom_damage") or 34
TUNING.MAGICSTAR_DAMAGE = GetModConfigData("wand_damage") or 25
TUNING.ELENA_WAND_SANITY_COST = GetModConfigData("wand_sanity_cost") or 1
TUNING.ELENA_HAT_WATERPROOF = GetModConfigData("hat_waterproof") or 1.0
TUNING.ELENA_EXP_RATE = GetModConfigData("exp_rate") or 1.0
TUNING.ELENA_LEVEL_DAMAGE_BONUS = GetModConfigData("level_damage_bonus") or 0.005
TUNING.ELENA_STATS_PER_LEVEL = GetModConfigData("stats_per_level") or 1
TUNING.ELENA_FLIGHT_BASE_DURATION = GetModConfigData("flight_base_duration") or 10
TUNING.ELENA_FLIGHT_SANITY_COST = GetModConfigData("flight_sanity_cost") or 1.0

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
    Asset("ATLAS", "images/avatars/avatar_elena.xml"),
    Asset("ATLAS", "images/avatars/avatar_ghost_elena.xml"),
    Asset("ATLAS", "images/avatars/self_inspect_elena.xml"),
    Asset("ATLAS", "images/names_elena.xml"),
    Asset("ATLAS", "images/map_icons/elena.xml")
}

PrefabFiles = {
    "elena", "elena_broom", "elena_hat", "elena_magicstar", "potion_magic",
    "potion_icepowder", "potion_soar", "potion_sourceliquid", "pumpkin_light",
    "book_ancientmagic", "blackcat_fish", "blackcat2", "light_projectile"
}

local IsDLC1 = GLOBAL.IsDLCEnabled(GLOBAL.REIGN_OF_GIANTS)
local IsDLC2 = GLOBAL.IsDLCEnabled(GLOBAL.CAPY_DLC)
local IsDLC3 = GLOBAL.IsDLCEnabled(GLOBAL.PORKLAND_DLC)

-- Character Strings
STRINGS.CHARACTER_TITLES.elena = "Elaina"
STRINGS.CHARACTER_NAMES.elena = "Elaina"
STRINGS.CHARACTER_DESCRIPTIONS.elena = "When you sigh, happiness slips away."
STRINGS.CHARACTER_QUOTES.elena = "Seems like it's not okay after all."
-- Elaina's own voice (a copy of Wendy's lines with her personality on top;
-- a plain require would share, and overwrite, Wendy's table)
STRINGS.CHARACTERS.ELENA = require "speech_elena"
STRINGS.NAMES.elena = "Elaina"
STRINGS.NAMES.ELENA = "Elaina"
GLOBAL.STRINGS.NAMES.elena = "Elaina"
GLOBAL.STRINGS.NAMES.ELENA = "Elaina"

AddModCharacter("elena", "FEMALE")
AddMinimapAtlas("images/map_icons/elena.xml")

-- Item and Critter Strings
GLOBAL.STRINGS.NAMES.CRITTER_KITTEN_BUILDER = "Little Kitten"
GLOBAL.STRINGS.RECIPE_DESC.CRITTER_KITTEN_BUILDER = "A cute little kitten!"
GLOBAL.STRINGS.NAMES.CRITTER_KITTEN = "Little Kitten"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.CRITTER_KITTEN = "It will grow into a lovely cat girl!"

GLOBAL.STRINGS.NAMES.ELENA_BROOM = "Witch's Broom"
GLOBAL.STRINGS.RECIPE_DESC.ELENA_BROOM = "A witch's way to travel. (Fly: R, Lvl 10)"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.ELENA_BROOM = "A witch's favorite broom."

GLOBAL.STRINGS.NAMES.ELENA_HAT = "Witch's Hat"
GLOBAL.STRINGS.RECIPE_DESC.ELENA_HAT = "A hat is an essential part of the persona."
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.ELENA_HAT = "A classic pointed witch hat."

GLOBAL.STRINGS.NAMES.ELENA_MAGICSTAR = "Magic Wand"
GLOBAL.STRINGS.RECIPE_DESC.ELENA_MAGICSTAR = "Homing star bolts. Costs a little focus."
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

-- Potion Recipes (Magic tab, must stand at a Shadow Manipulator to craft)
local function AddPotionRecipe(name, ingredients)
    local rec = Recipe(name, ingredients, RECIPETABS.MAGIC, TECH.MAGIC_TWO)
    rec.nounlock = true -- set by field: SW/Hamlet insert a game_type argument before it
    rec.atlas = "images/inventoryimages/potions.xml"
    rec.image = name .. ".tex"
end

AddPotionRecipe("potion_magic", {Ingredient("petals", 4), Ingredient("nightmarefuel", 1), Ingredient("blue_cap", 1)})
AddPotionRecipe("potion_sourceliquid", {Ingredient("livinglog", 1), Ingredient("honey", 2), Ingredient("red_cap", 1)})
AddPotionRecipe("potion_icepowder", {Ingredient("ice", 3), Ingredient("bluegem", 1), Ingredient("butterflywings", 2)})
AddPotionRecipe("potion_soar", {Ingredient("feather_robin", 2), Ingredient("honey", 2), Ingredient("papyrus", 1)})

GLOBAL.STRINGS.NAMES.BOOK_ANCIENTMAGIC = "Ancient Grimoire"
GLOBAL.STRINGS.RECIPE_DESC.BOOK_ANCIENTMAGIC = "Reading it calms the mind. Once a day."
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
    local follower = inst.components.follower
    if follower and data and data.attacker and follower.leader == data.attacker then
        inst:DoTaskInTime(1, function()
            if inst:IsValid() and inst.components.follower and data.attacker:IsValid() then
                inst.components.follower:SetLeader(data.attacker)
            end
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