local _G = getfenv(1)
local rawget = rawget
local MakePlayerCharacter = require "prefabs/player_common"
local assets = {Asset("ANIM", "anim/elena.zip")}

local prefabs = {"sparks_fx", "hoki", "book_ancientmagic"}
local start_inv = {"elena_hat", "elena_magicstar", "book_ancientmagic"}
local TUNING = rawget(_G, "TUNING") or TUNING or {}
if (TUNING.HOKI_START_MODE or "broom") ~= "hoki" then
    table.insert(start_inv, 1, "elena_broom")
end

local TheInput = rawget(_G, "TheInput") or TheInput
local KEY_R = rawget(_G, "KEY_R") or 114
local KEY_L = rawget(_G, "KEY_L") or 108
local ChangeToCharacterPhysics = rawget(_G, "ChangeToCharacterPhysics") or ChangeToCharacterPhysics
local COLLISION = rawget(_G, "COLLISION") or COLLISION
local EQUIPSLOTS = rawget(_G, "EQUIPSLOTS") or EQUIPSLOTS

local function ApplySpeedBonus(inst, key, mult)
    if not (inst and inst.components and inst.components.locomotor) then return end
    if inst.components.locomotor.SetExternalSpeedMultiplier then
        if mult and mult ~= 1.0 then
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, key, mult)
        else
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, key)
        end
    else
        inst.speed_mults = inst.speed_mults or {}
        if mult and mult ~= 1.0 then
            inst.speed_mults[key] = mult
        else
            inst.speed_mults[key] = nil
        end
        local total = 1.0
        for _, m in pairs(inst.speed_mults) do
            total = total * m
        end
        local base_run = TUNING.WILSON_RUN_SPEED or 6
        inst.components.locomotor.bonusspeed = base_run * (total - 1.0)
    end
end

local function StopFlight(inst, reason)
    if not inst.is_flying then
        return
    end

    inst.is_flying = false

    if inst.flight_timer_task then
        inst.flight_timer_task:Cancel()
        inst.flight_timer_task = nil
    end

    if inst.flight_warning_task then
        inst.flight_warning_task:Cancel()
        inst.flight_warning_task = nil
    end

    if inst.flight_sanity_task then
        inst.flight_sanity_task:Cancel()
        inst.flight_sanity_task = nil
    end

    if inst.flight_fx_task then
        inst.flight_fx_task:Cancel()
        inst.flight_fx_task = nil
    end

    if inst.flight_magnet_task then
        inst.flight_magnet_task:Cancel()
        inst.flight_magnet_task = nil
    end

    -- Restore normal character physics
    if ChangeToCharacterPhysics then
        ChangeToCharacterPhysics(inst)
    else
        inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.WORLD)
        inst.Physics:CollidesWith(COLLISION.OBSTACLES)
        inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    end

    -- Remove speed multiplier
    ApplySpeedBonus(inst, "broom_flight", 1.0)

    -- Remove flight tags
    inst:RemoveTag("flying")
    inst:RemoveTag("ignorecreep")
    inst:RemoveTag("notraptrigger")
    if inst.flight_added_amphibious then
        inst:RemoveTag("amphibious")
        inst.flight_added_amphibious = nil
    end

    -- Restore shadow size
    if inst.DynamicShadow then
        inst.DynamicShadow:SetSize(2, .75)
    end

    inst.flight_cooldown = (_G.GetTime and _G.GetTime() or 0) + 3

    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
    end

    if inst.components.talker and reason ~= "silent" then
        if reason then
            inst.components.talker:Say(reason)
        else
            inst.components.talker:Say("A graceful landing.")
        end
    end
end

local function DoGaleRepulsion(inst)
    if not (inst and inst:IsValid()) then return end
    local x, y, z = inst.Transform:GetWorldPosition()

    local fx = _G.SpawnPrefab("sparks_fx")
    if fx then fx.Transform:SetPosition(x, y, z) end

    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/wind_cast")
    end

    local enemies = _G.TheSim:FindEntities(x, y, z, 8, {"_combat"}, {"player", "companion", "INLIMBO"})
    for _, enemy in ipairs(enemies) do
        if enemy:IsValid() and enemy.components.combat and not enemy:HasTag("companion") and not enemy:HasTag("player") then
            local ex, ey, ez = enemy.Transform:GetWorldPosition()
            local dx = ex - x
            local dz = ez - z
            local dist = math.sqrt(dx * dx + dz * dz)
            if dist > 0 then
                local push_dist = math.max(2.5, 7.0 - dist)
                local nx = ex + (dx / dist) * push_dist
                local nz = ez + (dz / dist) * push_dist
                if enemy.Transform then
                    enemy.Transform:SetPosition(nx, ey, nz)
                end
            end

            if enemy.components.locomotor then
                enemy.components.locomotor:Stop()
            end

            if enemy.components.combat then
                enemy.components.combat:GetAttacked(inst, 25)
            end

            local enemy_fx = _G.SpawnPrefab("sparks_fx")
            if enemy_fx then enemy_fx.Transform:SetPosition(ex, ey, ez) end
        end
    end
end

local function IsOnWater(inst)
    local world = _G.GetWorld and _G.GetWorld()
    if world and world.Map then
        local x, y, z = inst.Transform:GetWorldPosition()
        local tile = world.Map:GetTileAtPoint(x, y, z)
        if _G.TileGroupManager and _G.TileGroupManager.IsOceanTile and _G.TileGroupManager:IsOceanTile(tile) then
            return true
        end
        local GROUND = _G.GROUND
        if GROUND and (tile == GROUND.OCEAN_COASTAL or tile == GROUND.OCEAN_SWELL or 
           tile == GROUND.OCEAN_ROUGH or tile == GROUND.IMPASSABLE) then
            return true
        end
    end
    return false
end

local function StartFlight(inst)
    if inst.is_flying then
        StopFlight(inst, "Landing early.")
        return
    end

    local current_time = _G.GetTime and _G.GetTime() or 0
    if inst.flight_cooldown and current_time < inst.flight_cooldown then
        local wait_time = math.max(1, math.ceil(inst.flight_cooldown - current_time))
        inst.components.talker:Say("Catching my breath... (" .. wait_time .. "s)")
        return
    end

    -- Level 10 requirement
    local current_level = (inst.components.level and inst.components.level.level) or 1
    if current_level < 10 then
        inst.components.talker:Say("I need to reach Level 10 to master flying on my broom!")
        return
    end

    -- Require broom equipped in hands
    local hand_item = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local has_broom = hand_item and (hand_item.prefab == "elena_broom" or hand_item:HasTag("broom") or hand_item:HasTag("elena_broom"))
    if not has_broom then
        inst.components.talker:Say("I need to hold my broom to take flight!")
        return
    end

    -- Sanity check
    local cost_per_sec = TUNING.ELENA_FLIGHT_SANITY_COST or 1.0
    if cost_per_sec > 0 and inst.components.sanity and inst.components.sanity.current < 5 then
        inst.components.talker:Say("I am too mentally exhausted to fly right now.")
        return
    end

    inst.is_flying = true

    -- Duration: Base (default 10s) + 1 extra second for every 5 levels above level 10
    local base_duration = TUNING.ELENA_FLIGHT_BASE_DURATION or 10
    local bonus_seconds = math.floor((current_level - 10) / 5)
    local total_duration = base_duration + bonus_seconds

    -- Flight physics (glides over obstacles, walls, water, spider webs)
    inst.Physics:SetCollisionGroup(COLLISION.FLYERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:CollidesWith(COLLISION.FLYERS)

    -- Flying tags
    inst:AddTag("flying")
    inst:AddTag("ignorecreep")
    inst:AddTag("notraptrigger")
    if not inst:HasTag("amphibious") then
        inst:AddTag("amphibious")
        inst.flight_added_amphibious = true
    end

    -- Speed bonus (+60%)
    ApplySpeedBonus(inst, "broom_flight", 1.6)

    -- Elevated shadow
    if inst.DynamicShadow then
        inst.DynamicShadow:SetSize(1.2, 0.4)
    end

    -- Takeoff sound effect
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve/common/staff")
    end

    inst.components.talker:Say("Soaring high! (" .. total_duration .. "s)")

    -- Sanity drain per second
    if cost_per_sec > 0 and inst.components.sanity then
        inst.flight_sanity_task = inst:DoPeriodicTask(1, function()
            if not inst.is_flying then return end
            inst.components.sanity:DoDelta(-cost_per_sec)
            if inst.components.sanity.current <= 1 then
                StopFlight(inst, "My focus slipped away!")
            end
        end)
    end

    -- Magical sparks trail
    inst.flight_fx_task = inst:DoPeriodicTask(0.35, function()
        if not inst.is_flying then return end
        local x, y, z = inst.Transform:GetWorldPosition()
        local fx = _G.SpawnPrefab("sparks_fx")
        if fx then
            fx.Transform:SetPosition(x + (math.random() - 0.5) * 0.4, 0.2, z + (math.random() - 0.5) * 0.4)
        end
    end)

    -- Resource Magnetism during flight: vacuums ground resources directly into inventory/pack
    inst.flight_magnet_task = inst:DoPeriodicTask(0.5, function()
        if not inst.is_flying then return end
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = _G.TheSim:FindEntities(x, y, z, 5, {"_inventoryitem"}, {"INLIMBO", "catchable", "irreplaceable"})
        for _, item in ipairs(ents) do
            if item:IsValid() and item.components.inventoryitem and not item.components.inventoryitem:IsHeld() and item.components.inventoryitem.canbepickedup then
                if inst.components.inventory and not inst.components.inventory:IsFull() then
                    inst.components.inventory:GiveItem(item)
                    if inst.SoundEmitter then
                        inst.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
                    end
                elseif inst.components.inventory and inst.components.inventory:GetOverflow() and inst.components.inventory:GetOverflow().components.container and not inst.components.inventory:GetOverflow().components.container:IsFull() then
                    inst.components.inventory:GetOverflow().components.container:GiveItem(item)
                    if inst.SoundEmitter then
                        inst.SoundEmitter:PlaySound("dontstarve/HUD/collect_resource")
                    end
                end
            end
        end
    end)

    -- Warning when 3 seconds remaining
    if total_duration > 4 then
        inst.flight_warning_task = inst:DoTaskInTime(total_duration - 3, function()
            if inst.is_flying and inst.components.talker then
                inst.components.talker:Say("My flight magic is waning...")
            end
        end)
    end

    -- Landing timer
    inst.flight_timer_task = inst:DoTaskInTime(total_duration, function()
        if inst.is_flying then
            if IsOnWater(inst) then
                inst.components.talker:Say("I must reach land before my magic runs out!")
                inst:DoTaskInTime(3, function()
                    StopFlight(inst, "Emergency landing!")
                end)
            else
                StopFlight(inst, "A graceful landing.")
            end
        end
    end)
end

local function CalculateKillExp(victim)
    if not (victim and victim.components.health) then
        return 0
    end

    local maxhp = victim.components.health.maxhealth or 0

    -- Tier 5: Epic Bosses
    if victim:HasTag("epic") or maxhp >= 2500 then
        return math.random(500, 800)
    end

    -- Tier 0: Prey and tiny critters
    if victim:HasTag("prey") or victim:HasTag("smallcreature") or victim:HasTag("bird") or victim:HasTag("insect") or maxhp <= 50 then
        return math.random(2, 5)
    end

    -- Tier 1: Basic monsters
    if maxhp < 100 then
        return math.random(8, 15)
    -- Tier 2: Medium creatures
    elseif maxhp < 300 then
        return math.random(25, 50)
    -- Tier 3: Strong creatures
    elseif maxhp < 1000 then
        return math.random(70, 120)
    -- Tier 4: Mini-bosses
    else
        return math.random(180, 300)
    end
end

local function onsave(inst, data)
    data.hoki_initial_spawned = inst.hoki_initial_spawned
end

local function onload(inst, data)
    if data then
        inst.hoki_initial_spawned = data.hoki_initial_spawned
        if data.health and data.health.health then
            inst.components.health.currenthealth = data.health.health
        end
        if data.hunger and data.hunger.hunger then
            inst.components.hunger.current = data.hunger.hunger
        end
        if data.sanity and data.sanity.current then
            inst.components.sanity.current = data.sanity.current
        end
        inst.components.health:DoDelta(0)
        inst.components.hunger:DoDelta(0)
        inst.components.sanity:DoDelta(0)
    end

    if inst.components.builder then
        inst.components.builder.science_bonus = 1
        local bonus_recipes = {"lantern", "compass", "sewing_kit"}
        for _, rec in ipairs(bonus_recipes) do
            inst.components.builder:AddRecipe(rec)
        end
    end
end

local function onnewspawn(inst)
    onload(inst)
    if (TUNING.HOKI_START_MODE or "broom") == "hoki" then
        inst:DoTaskInTime(0.5, function()
            local x, y, z = inst.Transform:GetWorldPosition()
            local hoki = _G.SpawnPrefab("hoki")
            if hoki then
                hoki.Transform:SetPosition(x + 1.5, 0, z + 1.5)
                if hoki.components.follower then
                    hoki.components.follower:SetLeader(inst)
                end
            end
        end)
    end
end

local HOKI_MODES = {
    {
        id = "farm",
        name = "Resource Farm",
        quote_elaina = "[Grimoire Command] Hoki: Resource Gathering Mode!",
        quote_hoki = "Sweeping and collecting all resources nearby, Lady Elaina!",
        sound = "dontstarve/common/gem_shatter",
    },
    {
        id = "battle",
        name = "Battle Stance",
        quote_elaina = "[Grimoire Command] Hoki: Battle Stance!",
        quote_hoki = "Locked onto enemies! I won't let anyone harm you, Lady Elaina!",
        sound = "dontstarve/common/staff",
    },
    {
        id = "passive",
        name = "Passive Guard",
        quote_elaina = "[Grimoire Command] Hoki: Stay by my side and hold fire.",
        quote_hoki = "Holding position right beside you, Lady Elaina.",
        sound = "dontstarve/characters/wendy/emote",
    },
    {
        id = "broom",
        name = "Broom Form",
        quote_elaina = "[Grimoire Command] Rest well in broom form, Hoki.",
        quote_hoki = "Returning to broom form, Lady Elaina~",
        sound = "dontstarve/common/staff",
    },
}

local function CycleHokiMode(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local hoki = _G.FindEntity(inst, 35, function(ent)
        return ent:HasTag("hoki") and ent.components.follower and ent.components.follower.leader == inst
    end)

    if not hoki then
        -- Hoki is currently not summoned in human form -> Awaken Hoki directly into Farm Mode!
        local broom_item = nil
        if inst.components.inventory then
            local hand_item = inst.components.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
            if hand_item and (hand_item.prefab == "elena_broom" or hand_item:HasTag("broom")) then
                broom_item = hand_item
            else
                for _, item in pairs(inst.components.inventory.itemslots) do
                    if item and (item.prefab == "elena_broom" or item:HasTag("broom")) then
                        broom_item = item
                        break
                    end
                end
            end
        end

        local hoki_entity = _G.SpawnPrefab("hoki")
        if hoki_entity then
            local offset = _G.FindWalkableOffset(inst:GetPosition(), math.random() * 2 * _G.PI, 2, 8, true) or _G.Vector3(1, 0, 0)
            hoki_entity.Transform:SetPosition(x + offset.x, 0, z + offset.z)
            if hoki_entity.components.follower then
                hoki_entity.components.follower:SetLeader(inst)
            end
            if hoki_entity.SetMode then
                hoki_entity:SetMode("farm")
            end
            if broom_item and broom_item.bonus_damage and hoki_entity.components.combat then
                hoki_entity.bonus_damage = broom_item.bonus_damage
                hoki_entity.components.combat:SetDefaultDamage((TUNING.HOKI_DAMAGE or 34) + hoki_entity.bonus_damage)
            end
        end

        if broom_item then
            if broom_item.components.inventoryitem and broom_item.components.inventoryitem.owner then
                broom_item.components.inventoryitem:RemoveFromOwner(true)
            end
            broom_item:Remove()
        end

        local fx = _G.SpawnPrefab("statue_transition") or _G.SpawnPrefab("sparks_fx")
        if fx then
            fx.Transform:SetPosition(x, y + 0.5, z)
        end
        if inst.SoundEmitter then
            inst.SoundEmitter:PlaySound("dontstarve/common/staff")
        end
        if inst.components.talker then
            inst.components.talker:Say("Awaken, Hoki! [Resource Gathering Mode]")
        end
        return true
    end

    -- Hoki is active -> Find current mode and advance to next in the command cycle
    local current_mode = hoki.hoki_mode or "farm"
    local cur_idx = 1
    for i, m in ipairs(HOKI_MODES) do
        if m.id == current_mode then
            cur_idx = i
            break
        end
    end

    local next_idx = (cur_idx % #HOKI_MODES) + 1
    local next_mode = HOKI_MODES[next_idx]

    if next_mode.id == "broom" then
        if hoki.RevertToBroom then
            hoki:RevertToBroom(next_mode.quote_hoki)
        else
            hoki:Remove()
            local broom = _G.SpawnPrefab("elena_broom")
            if broom and inst.components.inventory then
                inst.components.inventory:GiveItem(broom)
            end
        end
        if inst.components.talker then
            inst.components.talker:Say(next_mode.quote_elaina)
        end
        return true
    end

    -- Switch to active mode (farm, battle, passive)
    if hoki.SetMode then
        hoki:SetMode(next_mode.id)
    else
        hoki.hoki_mode = next_mode.id
    end

    local fx = _G.SpawnPrefab("sparks_fx")
    if fx then
        fx.Transform:SetPosition(hoki.Transform:GetWorldPosition())
    end
    if hoki.SoundEmitter and next_mode.sound then
        hoki.SoundEmitter:PlaySound(next_mode.sound)
    end

    if inst.components.talker then
        inst.components.talker:Say(next_mode.quote_elaina)
    end
    inst:DoTaskInTime(0.5, function()
        if hoki:IsValid() and hoki.components.talker then
            hoki.components.talker:Say(next_mode.quote_hoki)
        end
    end)

    return true
end

local fn = function(inst)
    inst:AddTag("elena")
    inst.name = "Elaina"
    inst.soundsname = "wendy"

    inst.AnimState:SetBuild("elena")
    inst.MiniMapEntity:SetIcon("elena.tex")

    -- Tag dropped items with timestamp so companion won't immediately re-grab discarded items
    inst:ListenForEvent("dropitem", function(inst, data)
        if data and data.item then
            data.item.just_dropped_by_player = GetTime()
        end
    end)

    inst.components.health:SetMaxHealth(TUNING.ELENA_HEALTH)
    inst.components.health:SetMinHealth(1)
    inst.DoGaleRepulsion = DoGaleRepulsion

    -- Mana Barrier: Emergency Ward against lethal hit
    inst:ListenForEvent("minhealth", function(inst, data)
        if not inst.mana_barrier_cooldown and not (inst.components.health and inst.components.health:IsDead()) then
            inst.mana_barrier_cooldown = true
            inst.components.health:SetMinHealth(0)
            inst.components.health:DoDelta(25)

            local fx = _G.SpawnPrefab("statue_transition") or _G.SpawnPrefab("sparks_fx")
            if fx then fx.Transform:SetPosition(inst.Transform:GetWorldPosition()) end

            if inst.DoGaleRepulsion then
                inst:DoGaleRepulsion()
            end

            if inst.components.talker then
                inst.components.talker:Say("Mana Barrier triggered! That was far too close...")
            end

            inst:DoTaskInTime(180, function()
                if inst:IsValid() and inst.components.health and not inst.components.health:IsDead() then
                    inst.mana_barrier_cooldown = false
                    inst.components.health:SetMinHealth(1)
                    if inst.components.talker then
                        inst.components.talker:Say("Mana Barrier has restored its protective ward.")
                    end
                end
            end)
        end
    end)
    inst.components.hunger:SetMax(TUNING.ELENA_HUNGER)
    inst.components.hunger.hungerrate = TUNING.WILSON_HUNGER_RATE
    inst.components.sanity:SetMax(TUNING.ELENA_SANITY)

    inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED

    inst.components.sanity.night_drain_mult = TUNING.WENDY_SANITY_MULT
    inst.components.hunger.hungerrate = TUNING.WILSON_HUNGER_RATE
    if inst.components.combat.AddDamageModifier then
        inst.components.combat:AddDamageModifier("wendy", TUNING.WENDY_DAMAGE_MULT)
    else
        inst.components.combat.damagemultiplier = TUNING.WENDY_DAMAGE_MULT
    end

    -- Genius Witch: Science bonus (has innate Science Machine tier 1, and can craft tier 2 with only a Science Machine)
    if inst.components.builder then
        inst.components.builder.science_bonus = 1
        local bonus_recipes = {"lantern", "compass", "sewing_kit"}
        for _, rec in ipairs(bonus_recipes) do
            inst.components.builder:AddRecipe(rec)
        end
    end

    inst:AddComponent("level")

    -- EXP gained from enemies, multiplied by mod config setting
    inst:ListenForEvent("killed", function(inst, data)
        if data and data.victim and data.victim.components.health then
            local maxhp = data.victim.components.health.maxhealth or 0
            
            if inst.components.level and inst.components.level.level <= (TUNING.ELENA_MAXLEVEL or 100) then
                local base_amount = CalculateKillExp(data.victim)
                local rate = TUNING.ELENA_EXP_RATE or 1.0
                local final_amount = math.floor(base_amount * rate)
                if final_amount > 0 then
                    inst.components.level:DoDelta(final_amount)
                end
            end

            if maxhp >= 100 and TheSim:FindFirstEntityWithTag("broom") == nil then
                if math.random() > 0.1 then
                    local drop_broom = SpawnPrefab("elena_broom")
                    if drop_broom then
                        drop_broom.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    end
                end
            end
        end
    end)

    -- EXP gained from food, multiplied by mod config setting
    inst:ListenForEvent("oneat", function(inst, data)
        if inst.components.level and inst.components.level.level <= (TUNING.ELENA_MAXLEVEL or 100) then
            if data and data.food and data.food.components.edible then
                local edible = data.food.components.edible
                local hg = edible.hungervalue or 0
                local hp = edible.healthvalue or 0
                local sn = edible.sanityvalue or 0

                local best_val = math.max(hg, hp * 2, sn * 2)
                if best_val > 0 then
                    local rate = TUNING.ELENA_EXP_RATE or 1.0
                    local amount = math.max(1, math.floor(math.random() * best_val * 0.75 * rate))
                    inst.components.level:DoDelta(amount)
                end
            end
        end
    end)

    inst:AddComponent("talker")

    -- Flight hotkey: R (toggles flight when Level >= 10 and holding broom)
    local input = rawget(_G, "TheInput") or TheInput
    if input and input.AddKeyUpHandler then
        input:AddKeyUpHandler(KEY_R, function()
            if not inst:IsValid() or inst:HasTag("playerghost") or (inst.components.health and inst.components.health:IsDead()) then
                return
            end
            StartFlight(inst)
        end)

        -- Check level and stats hotkey: L
        input:AddKeyUpHandler(KEY_L, function()
            if inst.components.level then
                local needsexp = inst.components.level.level * 400
                local lvl = inst.components.level.level
                local flight_info = (lvl >= 10) and " | [R] Fly" or " | [R] Fly (Lvl 10)"
                inst.components.talker:Say("Level: " .. lvl .. " | EXP: " ..
                                               math.floor(inst.components.level.exp) .. "/" .. needsexp .. flight_info .. " | [Z] Gale")
            end
        end)

        -- Gale Repulsion defensive burst hotkey: Z
        local key_z = rawget(_G, "KEY_Z") or 122
        input:AddKeyUpHandler(key_z, function()
            if not inst:IsValid() or inst:HasTag("playerghost") or (inst.components.health and inst.components.health:IsDead()) then
                return
            end
            local current_time = _G.GetTime and _G.GetTime() or 0
            if inst.gale_repulsion_cooldown and current_time < inst.gale_repulsion_cooldown then
                local wait = math.max(1, math.ceil(inst.gale_repulsion_cooldown - current_time))
                inst.components.talker:Say("Gale spell recharging... (" .. wait .. "s)")
                return
            end
            inst.gale_repulsion_cooldown = current_time + 12
            if inst.DoGaleRepulsion then
                inst:DoGaleRepulsion()
            end
            if inst.components.talker then
                inst.components.talker:Say("Gale Repulsion!")
            end
        end)
    end

    -- Cancel flight if broom is unequipped
    inst:ListenForEvent("unequip", function(inst, data)
        if inst.is_flying and data and data.item and (data.item.prefab == "elena_broom" or data.item:HasTag("broom")) then
            StopFlight(inst, "Unequipped broom.")
        end
    end)

    -- Cancel flight on death
    inst:ListenForEvent("death", function(inst)
        if inst.is_flying then
            StopFlight(inst, "silent")
        end
    end)

    -- Innate Sorcery Genius: Ability to read magical books and grimoires
    inst:AddComponent("reader")
    inst:AddTag("bookreader")

    -- Guarantee starter items and Hoki companion on world load/start
    inst:DoTaskInTime(0.3, function()
        if not (inst and inst:IsValid()) then return end

        if inst.components.inventory then
            -- Guarantee hat
            if not inst.components.inventory:Has("elena_hat", 1) and not (inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "elena_hat") then
                local hat = _G.SpawnPrefab("elena_hat")
                if hat then inst.components.inventory:GiveItem(hat) end
            end

            -- Guarantee magic wand
            if not inst.components.inventory:Has("elena_magicstar", 1) and not (inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab == "elena_magicstar") then
                local wand = _G.SpawnPrefab("elena_magicstar")
                if wand then inst.components.inventory:GiveItem(wand) end
            end

            -- Guarantee ancient grimoire
            if not inst.components.inventory:Has("book_ancientmagic", 1) then
                local book = _G.SpawnPrefab("book_ancientmagic")
                if book then inst.components.inventory:GiveItem(book) end
            end

            -- Guarantee traveler's warded pack
            if not inst.components.inventory:Has("elena_pack", 1) and not (inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY).prefab == "elena_pack") then
                local pack = _G.SpawnPrefab("elena_pack")
                if pack then inst.components.inventory:GiveItem(pack) end
            end

            -- Guarantee broom if start mode is broom
            if (TUNING.HOKI_START_MODE or "broom") ~= "hoki" then
                if not inst.components.inventory:Has("elena_broom", 1) and not (inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab == "elena_broom") then
                    local broom = _G.SpawnPrefab("elena_broom")
                    if broom then inst.components.inventory:GiveItem(broom) end
                end
            end
        end

        -- Guarantee Hoki companion if start mode is hoki
        if (TUNING.HOKI_START_MODE or "broom") == "hoki" and not inst.hoki_initial_spawned then
            inst.hoki_initial_spawned = true
            local x, y, z = inst.Transform:GetWorldPosition()
            local existing = _G.TheSim:FindEntities(x, y, z, 30, {"hoki"})
            if #existing == 0 then
                local hoki = _G.SpawnPrefab("hoki")
                if hoki then
                    hoki.Transform:SetPosition(x + 1.5, 0, z + 1.5)
                    if hoki.components.follower then
                        hoki.components.follower:SetLeader(inst)
                    end
                end
            end
        end
    end)

    inst.CycleHokiMode = CycleHokiMode

    -- Register Hotkey Handler for Hoki Commands (Farm, Battle, Passive, Broom)
    local key_name = TUNING.HOKI_COMMAND_KEY or "KEY_V"
    if key_name and key_name ~= "disabled" and _G[key_name] and TheInput then
        TheInput:AddKeyDownHandler(_G[key_name], function()
            local screen = _G.TheFrontEnd and _G.TheFrontEnd:GetActiveScreen()
            if not (screen and screen.name and screen.name:find("HUD")) then
                return
            end
            if inst:IsValid() and not (inst.components.health and inst.components.health:IsDead()) then
                inst:CycleHokiMode()
            end
        end)
    end

    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.OnNewSpawn = onnewspawn
end

return MakePlayerCharacter("elena", prefabs, assets, fn, start_inv)