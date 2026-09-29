-- Elaina's lines. Starts from a copy of Wendy's speech so every string the game
-- asks for exists, then gives the most common ones Elaina's voice: a confident,
-- slightly vain, pragmatic traveling witch who prefers not to get involved.

local S = deepcopy(require "speech_wendy")

-- Replace a line whether the original entry is a plain string or a table of
-- states (GENERIC, BURNT, ...). Only the GENERIC state is changed for tables.
local function set(tbl, key, text)
    local cur = tbl[key]
    if type(cur) == "table" then
        cur.GENERIC = text
    else
        tbl[key] = text
    end
end

local lines = {
    ACTIONFAIL_GENERIC = "Even a genius witch can't do that.",
    ANNOUNCE_ADVENTUREFAIL = "Well. That's one chapter I'd rather not write down.",
    ANNOUNCE_BEES = "Bees! Shoo! Not the hair!",
    ANNOUNCE_BOOMERANG = "Ow. Catching things was never part of the witch exam.",
    ANNOUNCE_CHARLIE = "Who's there? I'm armed. With magic.",
    ANNOUNCE_CHARLIE_ATTACK = "Ah! Something in the dark bit me!",
    ANNOUNCE_COLD = "My robe was not made for this cold.",
    ANNOUNCE_HOT = "It's far too hot. My hat is suffering.",
    ANNOUNCE_CRAFTING_FAIL = "I'm missing something. How unlike me.",
    ANNOUNCE_DEERCLOPS = "Something enormous is coming. I'd rather not meet it.",
    ANNOUNCE_DUSK = "The sun is setting. Travelers should find a fire.",
    ANNOUNCE_ENTER_DARK = "It's too dark! I need light, now!",
    ANNOUNCE_ENTER_LIGHT = "Light. Much better.",
    ANNOUNCE_HOUNDS = "Hounds. I can hear them coming.",
    ANNOUNCE_HUNGRY = "I'm starving. Some fresh bread would be lovely right now.",
    ANNOUNCE_INV_FULL = "My pockets are full, even for a witch.",
    ANNOUNCE_KNOCKEDOUT = "Ugh... how undignified.",
    ANNOUNCE_NODANGERSLEEP = "Sleep now? With danger nearby? I'm not that careless.",
    ANNOUNCE_NODAYSLEEP = "Napping in broad daylight? Only on a very slow broom ride.",
    ANNOUNCE_NOHUNGERSLEEP = "I can't sleep on an empty stomach.",
    ANNOUNCE_PECKED = "Stop that! I am not food!",
    ANNOUNCE_QUAKE = "The ground is shaking. That's never a good sign.",
    ANNOUNCE_THORNS = "Ouch. Thorns. Wonderful.",
    ANNOUNCE_TORCH_OUT = "My torch went out. How inconvenient.",
    ANNOUNCE_TRAP_WENT_OFF = "Oops.",
    ANNOUNCE_WORMHOLE = "That was disgusting. Let's never speak of it.",
    ANNOUNCE_DAMP = "A little rain never stopped a traveler.",
    ANNOUNCE_WET = "I'm getting soaked. My hair will be a mess.",
    ANNOUNCE_WETTER = "This is unacceptable. I'm drenched.",
    ANNOUNCE_SOAKED = "I'm completely soaked through!",
    ANNOUNCE_BURNT = "Hot! That was hot!",
    ANNOUNCE_TOOL_SLIP = "It slipped right out of my hands.",
    ANNOUNCE_SHELTER = "A good spot to wait out the weather.",
    ANNOUNCE_ACCOMPLISHMENT = "Another page for my travel journal.",
    ANNOUNCE_ACCOMPLISHMENT_DONE = "Well done, me.",
    ANNOUNCE_MOSQUITOS = "Mosquitoes. Go bite someone less charming.",
    ANNOUNCE_TREASURE = "Treasure! Traveling does pay off after all.",
    ANNOUNCE_MORETREASURE = "More treasure? I do like the sound of that.",
    ANNOUNCE_MESSAGEBOTTLE = "A message in a bottle. Every journey needs a mystery.",
    ANNOUNCE_BOAT_DAMAGED = "My boat is taking damage. I miss my broom.",
    ANNOUNCE_BOAT_SINKING = "This boat is sinking!",
    ANNOUNCE_BOAT_SINKING_IMMINENT = "I need to get to shore, right now!",
    ANNOUNCE_VOLCANO_ERUPT = "The volcano! Time to leave.",
    DESCRIBE_GENERIC = "Hmm. I've seen stranger things on my travels.",
    DESCRIBE_TOODARK = "It's too dark to see anything.",
}

for key, text in pairs(lines) do
    set(S, key, text)
end

-- ANNOUNCE_EAT is a table of states in every version
if type(S.ANNOUNCE_EAT) == "table" then
    S.ANNOUNCE_EAT.GENERIC = "Delicious. A traveler must always eat well."
    S.ANNOUNCE_EAT.PAINFUL = "Ugh. That was a mistake."
    S.ANNOUNCE_EAT.SPOILED = "That was... not fresh."
    S.ANNOUNCE_EAT.STALE = "A bit stale, but I've had worse on the road."
end

local describe = {
    -- Elaina's own things
    ELENA_BROOM = "My broom. We've traveled a long way together.",
    ELENA_HAT = "My hat. It suits me perfectly, naturally.",
    ELENA_MAGICSTAR = "My wand. It's more reliable than most people I meet.",
    BOOK_ANCIENTMAGIC = "An old grimoire. Reading it clears my head.",
    POTION_MAGIC = "A mana potion. Tastes better than it looks.",
    POTION_SOURCELIQUID = "Primordial water. Very old magic.",
    POTION_ICEPOWDER = "A frost elixir. Handle with care.",
    POTION_SOAR = "A traveler's potion. My kind of drink.",

    -- The wilds
    ABIGAIL = "Just passing through. I'd rather not get involved.",
    ABIGAIL_FLOWER = "A strange flower. There's a sad story here, I can tell.",
    BERRYBUSH = "Berries. A traveler's snack.",
    CARROT = "A carrot. Simple, but it'll do.",
    CAVE_ENTRANCE = "It's blocked. Probably for a good reason.",
    EVERGREEN = "A tree. There are a lot of those.",
    FLOWER = "Pretty. Not as pretty as me, but still.",
    GRASS = "Grass. Useful for more than you'd think.",
    MANDRAKE = "A mandrake. Every witch knows not to wake one lightly.",
    RABBIT = "A rabbit. It's too quick for its own good.",
    RED_MUSHROOM = "Mushrooms. I'd really rather not.",
    GREEN_MUSHROOM = "Another mushroom. No thank you.",
    BLUE_MUSHROOM = "Mushrooms again. I'll pass.",
    RED_CAP = "I'm not eating that.",
    GREEN_CAP = "I'm not eating that either.",
    BLUE_CAP = "Useful for potions. Not for eating.",
    SAPLING = "A sapling. It's trying its best.",
    ROCKS = "Rocks. Heavy, and not very magical.",
    FLINT = "Sharp. Travelers can always use some.",
    TWIGS = "Twigs. My broom would disapprove.",
    CUTGRASS = "Cut grass. Could be woven into something.",
    LOG = "A log. Good for fires.",
    GOLDNUGGET = "Gold! Now that's worth picking up.",
    SILK = "Spider silk. Fine enough for a witch's hat.",
    PAPYRUS = "Paper. I should keep a proper travel journal.",
    NIGHTMAREFUEL = "It's made of bad dreams. Charming.",

    -- Creatures
    BEEFALO = "A big, fluffy beast. It doesn't seem to mind me.",
    SPIDER = "A spider. I'd prefer it keep its distance.",
    SPIDERDEN = "A spider nest. Best to fly over it.",
    PIGMAN = "A pig person. They seem to have their own customs.",
    PIGHOUSE = "A pig's house. Rather cozy, actually.",
    BUNNYMAN = "A bunny person. Friendly enough, I suppose.",
    HOUND = "Hounds. I really don't have time for this.",
    TENTACLE = "A tentacle. In the swamp. Of course.",
    KRAMPUS = "A thief! Keep your hands off my belongings.",
    DEERCLOPS = "That's a very big problem with one very big eye.",
    BUTTERFLY = "A butterfly. Free to go wherever it likes. I can relate.",
    CROW = "A crow. It keeps staring at me.",
    ROBIN = "A little red bird.",

    -- Camp and science
    CAMPFIRE = "A campfire. The best part of any journey.",
    FIREPIT = "A fire pit. Somewhere to rest for the night.",
    RESEARCHLAB = "A science machine. Crude, but it works.",
    RESEARCHLAB2 = "An alchemy engine. Now we're getting somewhere.",
    RESEARCHLAB3 = "A shadow manipulator. The magic here is... unpleasant.",
    COOKPOT = "A cooking pot. Travelers should eat well.",
    TENT = "A tent. Not quite an inn, but it'll do.",
    TREASURECHEST = "A chest for keeping things safe.",
    TORCH = "A torch. Useful when there's nothing better.",
    LANTERN = "A lantern. Every traveler should carry one.",
    COMPASS = "A compass. Not that I ever get lost.",
    UMBRELLA = "An umbrella. My hat can only do so much.",
    TOPHAT = "A fine hat. Mine is finer.",
    BACKPACK = "A backpack. Practical, if not very stylish.",
    MEATBALLS = "Meatballs. Filling and warm.",
    HONEY = "Honey. Sweet, like me.",
}

for key, text in pairs(describe) do
    set(S.DESCRIBE, key, text)
end

return S
