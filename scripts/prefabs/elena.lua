local MakePlayerCharacter = require "prefabs/player_common"
local U = require "elena_util"

local assets = {Asset("ANIM", "anim/elena.zip")}
local prefabs = {"sparks_fx", "statue_transition", "elena_broom", "elena_hat", "elena_magicstar", "book_ancientmagic"}
local start_inv = {"elena_broom", "elena_hat", "elena_magicstar", "book_ancientmagic"}

local KEY_R = rawget(_G, "KEY_R") or 114
local KEY_L = rawget(_G, "KEY_L") or 108
local KEY_Z = rawget(_G, "KEY_Z") or 122

local FLIGHT_MIN_LEVEL = 10
local FLIGHT_COOLDOWN = 3
local GALE_COOLDOWN = 12
local GALE_SANITY_COST = 10
local GALE_RADIUS = 8
local GALE_DAMAGE = 25
local BARRIER_COOLDOWN = TUNING.TOTAL_DAY_TIME or 480
local BARRIER_HEAL = 25

local function Say(inst, text)
    if inst.components.talker then
        inst.components.talker:Say(text)
    end
end

local function IsAliveAndValid(inst)
    return inst:IsValid() and not inst:HasTag("playerghost")
        and not (inst.components.health and inst.components.health:IsDead())
end

-- Hotkeys only while playing (not in the console, pause menu, map, crafting text boxes...)
local function IsHUDActive()
    local frontend = rawget(_G, "TheFrontEnd")
    local screen = frontend and frontend:GetActiveScreen()
    return screen ~= nil and screen.name ~= nil and screen.name:find("HUD") ~= nil
end

local function IsBroom(item)
    return item ~= nil and (item.prefab == "elena_broom" or item:HasTag("elena_broom"))
end

---------------------------------------------------------------------------
-- Broom flight
---------------------------------------------------------------------------

local function SetGroundPhysics(inst)
    local change = rawget(_G, "ChangeToCharacterPhysics")
    if change then
        change(inst)
    else
        inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.WORLD)
        inst.Physics:CollidesWith(COLLISION.OBSTACLES)
        inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    end
end

-- Flying passes over obstacles and creatures, but still respects the edge of
-- the world, the sea and Hamlet interior walls, so Elaina can never be dropped
-- into water or out of a room.
local function SetFlightPhysics(inst)
    local get_world = rawget(_G, "GetWorldCollision")
    local get_water = rawget(_G, "GetWaterCollision")
    local world_col = get_world and get_world() or COLLISION.WORLD
    local water_col = get_water and get_water() or nil

    inst.Physics:SetCollisionGroup(COLLISION.FLYERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(world_col or COLLISION.WORLD)
    if water_col then
        inst.Physics:CollidesWith(water_col)
    end
    if COLLISION.INTWALL then
        inst.Physics:CollidesWith(COLLISION.INTWALL)
    end
end

local function CancelTask(inst, name)
    if inst[name] then
        inst[name]:Cancel()
        inst[name] = nil
    end
end

local function StopFlight(inst, reason)
    if not inst.is_flying then
        return
    end
    inst.is_flying = false

    CancelTask(inst, "flight_timer_task")
    CancelTask(inst, "flight_warning_task")
    CancelTask(inst, "flight_sanity_task")
    CancelTask(inst, "flight_fx_task")
    CancelTask(inst, "flight_magnet_task")

    if inst:IsValid() then
        SetGroundPhysics(inst)
        U.SetSpeedMult(inst, "broom_flight", 1.0)
        inst:RemoveTag("flying")
        inst:RemoveTag("notraptrigger")
        if inst.DynamicShadow then
            inst.DynamicShadow:SetSize(1.3, .6)
        end
        U.PlaySound(inst, "dontstarve/movement/bodyfall_dirt")
        if reason ~= "silent" then
            Say(inst, reason or "A graceful landing, as expected of me.")
        end
    end

    inst.flight_cooldown = GetTime() + FLIGHT_COOLDOWN
end

local function CanCarry(inst, item)
    local inv = inst.components.inventory
    if not inv then return false end
    if not inv:IsFull() then return true end
    local overflow = inv.overflow and inv.overflow.components.container
    return overflow ~= nil and not overflow:IsFull()
end

local MAGNET_EXCLUDE = {"INLIMBO", "NOCLICK", "FX", "catchable", "irreplaceable", "trap", "mine", "heavy", "fire"}

local function MagnetizeItems(inst)
    if not inst.is_flying then return end
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 5, nil, MAGNET_EXCLUDE)
    for _, item in ipairs(ents) do
        local invitem = item:IsValid() and item.components.inventoryitem
        if invitem and invitem.canbepickedup and invitem.cangoincontainer ~= false
            and not invitem:IsHeld()
            and not (item.components.burnable and item.components.burnable:IsBurning()) then
            if not CanCarry(inst, item) then
                return
            end
            inst.components.inventory:GiveItem(item)
            U.PlaySound(inst, "dontstarve/HUD/collect_resource")
        end
    end
end

local function StartFlight(inst)
    if inst.is_flying then
        StopFlight(inst, "Landing early.")
        return
    end

    local now = GetTime()
    if inst.flight_cooldown and now < inst.flight_cooldown then
        Say(inst, "Catching my breath... (" .. math.max(1, math.ceil(inst.flight_cooldown - now)) .. "s)")
        return
    end

    local level = inst.components.level and inst.components.level.level or 1
    if level < FLIGHT_MIN_LEVEL then
        Say(inst, "I need to reach Level " .. FLIGHT_MIN_LEVEL .. " to fly on my broom.")
        return
    end

    local hands = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if not IsBroom(hands) then
        Say(inst, "I need to hold my broom to take flight.")
        return
    end

    if U.IsInInterior(inst) then
        Say(inst, "The ceiling is far too low to fly in here.")
        return
    end

    if inst.components.driver and inst.components.driver.GetIsDriving and inst.components.driver:GetIsDriving() then
        Say(inst, "I can't take off from a rocking boat.")
        return
    end

    if inst.components.rider and inst.components.rider.IsRiding and inst.components.rider:IsRiding() then
        Say(inst, "Not while I'm riding.")
        return
    end

    local cost_per_sec = TUNING.ELENA_FLIGHT_SANITY_COST or 1.0
    if cost_per_sec > 0 and inst.components.sanity and inst.components.sanity.current < 5 then
        Say(inst, "I'm too mentally exhausted to fly right now.")
        return
    end

    inst.is_flying = true

    -- Base duration + 1 second for every 5 levels above 10
    local duration = (TUNING.ELENA_FLIGHT_BASE_DURATION or 10) + math.floor((level - FLIGHT_MIN_LEVEL) / 5)

    SetFlightPhysics(inst)
    inst:AddTag("flying")
    inst:AddTag("notraptrigger")
    U.SetSpeedMult(inst, "broom_flight", 1.6)
    if inst.DynamicShadow then
        inst.DynamicShadow:SetSize(1.2, 0.4)
    end
    U.PlaySound(inst, "dontstarve/wilson/use_gemstaff")
    Say(inst, "Off I go! (" .. duration .. "s)")

    if cost_per_sec > 0 and inst.components.sanity then
        inst.flight_sanity_task = inst:DoPeriodicTask(1, function()
            if not inst.is_flying then return end
            inst.components.sanity:DoDelta(-cost_per_sec)
            if inst.components.sanity.current <= 1 then
                StopFlight(inst, "My focus slipped away!")
            end
        end)
    end

    inst.flight_fx_task = inst:DoPeriodicTask(0.35, function()
        if not inst.is_flying then return end
        local x, y, z = inst.Transform:GetWorldPosition()
        U.SpawnFxAt("sparks_fx", x + (math.random() - 0.5) * 0.4, 0.2, z + (math.random() - 0.5) * 0.4)
    end)

    inst.flight_magnet_task = inst:DoPeriodicTask(0.5, MagnetizeItems)

    if duration > 4 then
        inst.flight_warning_task = inst:DoTaskInTime(duration - 3, function()
            if inst.is_flying then
                Say(inst, "My flight magic is waning...")
            end
        end)
    end

    inst.flight_timer_task = inst:DoTaskInTime(duration, function()
        inst.flight_timer_task = nil
        StopFlight(inst)
    end)
end

---------------------------------------------------------------------------
-- Gale Repulsion (Z)
---------------------------------------------------------------------------

local function DoGaleRepulsion(inst)
    if not inst:IsValid() then return end
    local x, y, z = inst.Transform:GetWorldPosition()
    U.SpawnFxAt("sparks_fx", x, y, z)
    U.PlaySound(inst, "dontstarve/wilson/use_gemstaff")

    local indoors = U.IsInInterior(inst)
    local ents = TheSim:FindEntities(x, y, z, GALE_RADIUS, nil, {"player", "companion", "INLIMBO", "FX", "NOCLICK", "wall"})
    for _, enemy in ipairs(ents) do
        if U.IsHostileTo(enemy, inst) then
            local ex, ey, ez = enemy.Transform:GetWorldPosition()
            local dx, dz = ex - x, ez - z
            local dist = math.sqrt(dx * dx + dz * dz)

            -- Knock back only onto solid land, never bosses, never indoors
            if dist > 0.1 and not indoors and not enemy:HasTag("epic") then
                local push = math.max(2.5, 7.0 - dist)
                local nx, nz = ex + dx / dist * push, ez + dz / dist * push
                if U.IsLandAt(nx, 0, nz) then
                    enemy.Transform:SetPosition(nx, ey, nz)
                end
            end

            if enemy.components.locomotor then
                enemy.components.locomotor:Stop()
            end
            enemy.components.combat:GetAttacked(inst, GALE_DAMAGE)
            U.SpawnFxAt("sparks_fx", ex, ey, ez)
        end
    end
end

local function TryGale(inst)
    local now = GetTime()
    if inst.gale_cooldown and now < inst.gale_cooldown then
        Say(inst, "Gale spell recharging... (" .. math.max(1, math.ceil(inst.gale_cooldown - now)) .. "s)")
        return
    end
    if inst.components.sanity and inst.components.sanity.current < GALE_SANITY_COST then
        Say(inst, "I don't have the focus for that spell.")
        return
    end
    inst.gale_cooldown = now + GALE_COOLDOWN
    if inst.components.sanity then
        inst.components.sanity:DoDelta(-GALE_SANITY_COST)
    end
    DoGaleRepulsion(inst)
    Say(inst, "Gale Repulsion!")
end

---------------------------------------------------------------------------
-- Mana Barrier: survives one lethal hit per day
---------------------------------------------------------------------------

local function StartBarrierCooldown(inst, time)
    CancelTask(inst, "barrier_task")
    inst.components.health:SetMinHealth(0)
    inst.barrier_ready_at = GetTime() + time
    inst.barrier_task = inst:DoTaskInTime(time, function()
        inst.barrier_task = nil
        inst.barrier_ready_at = nil
        if inst.components.health and not inst.components.health:IsDead() then
            inst.components.health:SetMinHealth(1)
            Say(inst, "My Mana Barrier is ready again.")
        end
    end)
end

local function OnMinHealth(inst)
    local health = inst.components.health
    -- Only an armed barrier (minhealth 1) reacts; at 0 the hit is simply lethal
    if inst.barrier_task or health:IsDead() or (health.minhealth or 0) <= 0 then
        return
    end
    StartBarrierCooldown(inst, BARRIER_COOLDOWN)
    inst.components.health:DoDelta(BARRIER_HEAL)

    local x, y, z = inst.Transform:GetWorldPosition()
    U.SpawnFxAt("statue_transition", x, y, z)
    DoGaleRepulsion(inst)
    Say(inst, "Mana Barrier! ...That was far too close.")
end

---------------------------------------------------------------------------
-- Experience
---------------------------------------------------------------------------

local function CalculateKillExp(victim)
    local maxhp = victim.components.health.maxhealth or 0

    if victim:HasTag("epic") or maxhp >= 2500 then
        return math.random(500, 800)
    end
    if victim:HasTag("prey") or victim:HasTag("smallcreature") or victim:HasTag("bird")
        or victim:HasTag("insect") or maxhp <= 50 then
        return math.random(2, 5)
    end
    if maxhp < 100 then
        return math.random(8, 15)
    elseif maxhp < 300 then
        return math.random(25, 50)
    elseif maxhp < 1000 then
        return math.random(70, 120)
    end
    return math.random(180, 300)
end

local function OnKilled(inst, data)
    local victim = data and data.victim
    if victim and victim.components.health and inst.components.level then
        local amount = math.floor(CalculateKillExp(victim) * (TUNING.ELENA_EXP_RATE or 1.0))
        if amount > 0 then
            inst.components.level:DoDelta(amount)
        end
    end
end

local function OnEat(inst, data)
    local edible = data and data.food and data.food.components.edible
    if not (edible and inst.components.level) then return end
    local best = math.max(edible.hungervalue or 0, (edible.healthvalue or 0) * 2, (edible.sanityvalue or 0) * 2)
    if best > 0 then
        local amount = math.max(1, math.floor(math.random() * best * 0.75 * (TUNING.ELENA_EXP_RATE or 1.0)))
        inst.components.level:DoDelta(amount)
    end
end

---------------------------------------------------------------------------
-- Witch crafting tab (lets Elaina remake her lost gear; no duplicates on load)
---------------------------------------------------------------------------

local function AddWitchRecipes(inst)
    local builder = inst.components.builder
    if not (builder and builder.AddRecipeTab) then return end

    local tab = {str = "WITCH", sort = 999, icon = "tab_book.tex"}
    builder:AddRecipeTab(tab)
    STRINGS.TABS.WITCH = "Witchcraft"

    local function add(name, ingredients, tech, image)
        local rec = Recipe(name, ingredients, tab, tech)
        rec.atlas = "images/inventoryimages/elena.xml"
        rec.image = image
    end

    add("elena_broom", {Ingredient("twigs", 6), Ingredient("cutgrass", 4), Ingredient("rope", 1)}, {SCIENCE = 0}, "elena_broom.tex")
    add("elena_hat", {Ingredient("silk", 6), Ingredient("goldnugget", 1)}, {SCIENCE = 1}, "elena_hat.tex")
    add("elena_magicstar", {Ingredient("twigs", 2), Ingredient("goldnugget", 2)}, {SCIENCE = 1}, "elena_magic.tex")

    local book = Recipe("book_ancientmagic", {Ingredient("papyrus", 2), Ingredient("nightmarefuel", 2)}, tab, {MAGIC = 2})
    book.atlas = "images/inventoryimages/book_ancientmagic.xml"
    book.image = "book_ancientmagic.tex"
end

local function GrantInnateKnowledge(inst)
    local builder = inst.components.builder
    if builder then
        builder.science_bonus = 1
        for _, rec in ipairs({"lantern", "compass", "sewing_kit"}) do
            builder:AddRecipe(rec)
        end
    end
end

---------------------------------------------------------------------------
-- Save / load
---------------------------------------------------------------------------

local function onsave(inst, data)
    if inst.barrier_ready_at then
        data.barrier_cooldown = math.max(0, inst.barrier_ready_at - GetTime())
    end
end

local function onload(inst, data)
    if data then
        -- Restore values clamped by the base maximums before the level loaded
        if data.health and data.health.health then
            inst.components.health.currenthealth = math.min(data.health.health, inst.components.health.maxhealth)
        end
        if data.hunger and data.hunger.hunger then
            inst.components.hunger.current = math.min(data.hunger.hunger, inst.components.hunger.max)
        end
        if data.sanity and data.sanity.current then
            inst.components.sanity.current = math.min(data.sanity.current, inst.components.sanity.max)
        end
        inst.components.health:DoDelta(0)
        inst.components.hunger:DoDelta(0)
        inst.components.sanity:DoDelta(0)
    end

    -- Hamlet saves minhealth itself, so always set the barrier state explicitly
    if data and data.barrier_cooldown and data.barrier_cooldown > 0 then
        StartBarrierCooldown(inst, data.barrier_cooldown)
    else
        inst.components.health:SetMinHealth(1)
    end

    GrantInnateKnowledge(inst)
end

local function onnewspawn(inst)
    GrantInnateKnowledge(inst)
end

---------------------------------------------------------------------------

local fn = function(inst)
    inst:AddTag("elena")
    inst.soundsname = "wendy"

    inst.AnimState:SetBuild("elena")
    inst.MiniMapEntity:SetIcon("elena.tex")

    inst.components.health:SetMaxHealth(TUNING.ELENA_HEALTH)
    inst.components.health:SetMinHealth(1)
    inst.components.hunger:SetMax(TUNING.ELENA_HUNGER)
    inst.components.hunger.hungerrate = TUNING.WILSON_HUNGER_RATE
    inst.components.sanity:SetMax(TUNING.ELENA_SANITY)
    inst.components.sanity.night_drain_mult = TUNING.WENDY_SANITY_MULT

    inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED

    -- Elaina is a witch, not a brawler: -25% physical damage
    U.SetDamageBonus(inst, "elena_witch", U.WendyDamageModifier())

    GrantInnateKnowledge(inst)
    AddWitchRecipes(inst)

    -- She can read grimoires
    if not inst.components.reader then
        inst:AddComponent("reader")
    end
    inst:AddTag("bookreader")

    inst:AddComponent("level")
    inst:ListenForEvent("killed", OnKilled)
    inst:ListenForEvent("oneat", OnEat)

    inst:ListenForEvent("minhealth", OnMinHealth)

    inst:ListenForEvent("unequip", function(inst, data)
        if inst.is_flying and data and IsBroom(data.item) then
            StopFlight(inst, "I dropped my broom!")
        end
    end)
    inst:ListenForEvent("death", function(inst)
        StopFlight(inst, "silent")
    end)
    inst:ListenForEvent("onremove", function(inst)
        StopFlight(inst, "silent")
    end)

    if TheInput and TheInput.AddKeyUpHandler then
        TheInput:AddKeyUpHandler(KEY_R, function()
            if IsHUDActive() and IsAliveAndValid(inst) then
                StartFlight(inst)
            end
        end)

        TheInput:AddKeyUpHandler(KEY_Z, function()
            if IsHUDActive() and IsAliveAndValid(inst) then
                TryGale(inst)
            end
        end)

        TheInput:AddKeyUpHandler(KEY_L, function()
            if IsHUDActive() and IsAliveAndValid(inst) and inst.components.level then
                local lvl = inst.components.level
                local exp = lvl:IsMaxLevel() and "MAX" or (math.floor(lvl.exp) .. "/" .. lvl:GetNeededExp())
                local flight = (lvl.level >= FLIGHT_MIN_LEVEL) and "[R] Fly" or ("[R] Fly (Lvl " .. FLIGHT_MIN_LEVEL .. ")")
                local barrier = inst.barrier_ready_at
                    and ("Barrier " .. math.ceil(inst.barrier_ready_at - GetTime()) .. "s")
                    or "Barrier ready"
                Say(inst, "Level " .. lvl.level .. " | EXP " .. exp .. "\n" .. flight .. " | [Z] Gale | " .. barrier)
            end
        end)
    end

    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.OnNewSpawn = onnewspawn
end

return MakePlayerCharacter("elena", prefabs, assets, fn, start_inv)
