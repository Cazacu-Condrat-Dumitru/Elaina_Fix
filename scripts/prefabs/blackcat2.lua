-- Based on critter implementation
local brain = require("brains/crittersbrain")

local WAKE_TO_FOLLOW_DISTANCE = 6 -- Follower distance
local SLEEP_NEAR_LEADER_DISTANCE = 5 -- Sleep near leader distance

local HUNGRY_PERIESH_PERCENT = 0.5 -- Hunger threshold percentage
local STARVING_PERIESH_PERCENT = 0.2 -- matches spoiked tag

-- local function PetSanityAura(inst, observer) -- Small radius sanity aura
--     if inst.components.follower and inst.components.follower.leader == observer then
--         return TUNING.SANITYAURA_TINY
--     end
--     return 0
-- end

local function IsLeaderSleeping(inst) -- Check if leader is sleeping
    return inst.components.follower.leader and inst.components.follower.leader:HasTag("sleeping")
end

local function ShouldWakeUp(inst)
    return (DefaultWakeTest(inst) and not IsLeaderSleeping(inst)) or
               not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE)
end

local function ShouldSleep(inst)
    return (DefaultSleepTest(inst) or IsLeaderSleeping(inst)) and
               inst.components.follower:IsNearLeader(SLEEP_NEAR_LEADER_DISTANCE)
end

local function oneat(inst, food)
    if food ~= nil then
        local pt = Vector3(inst.Transform:GetWorldPosition())
        -- local spawn_pt = GetSpawnPoint(pt)
        if math.random() > 0.1 then
            local potion = SpawnPrefab("potion_sourceliquid")
            if potion then
                potion.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
        end
        local FOOD = {
            taffy = true,
            honeyham = true,
            dragonpie = true,
            bonestew = true,
            corn = true,
            atermelon = true,
            meat = true,
            drumstick = true,
            bird_egg = true,
            fish = true,
            honey = true,
            meat_dried = true
        }
        if food and food.components.edible and FOOD[food.prefab] then
            inst.sg.mem.queuethankyou = true
        end
    end
    local perish = inst.components.perishable:GetPercent()
    if perish <= STARVING_PERIESH_PERCENT then
        inst.components.perishable.perishtime = math.max(inst.components.perishable.perishtime -
                                                             TUNING.CRITTER_HUNGERTIME_DELTA,
            TUNING.CRITTER_HUNGERTIME_MIN)
    elseif perish <= HUNGRY_PERIESH_PERCENT then
        inst.components.perishable.perishtime = math.min(inst.components.perishable.perishtime +
                                                             TUNING.CRITTER_HUNGERTIME_DELTA,
            TUNING.CRITTER_HUNGERTIME_MAX)
    end

    inst.components.perishable:SetPercent(1)
    inst.components.perishable:StartPerishing()
end

-------------------------------------------------------------------------------
local function GetPeepChance(inst) -- Chance to peep/beg
    local hunger_percent = inst.components.perishable:GetPercent()
    if hunger_percent <= 0 then
        return 0.8
    elseif hunger_percent < 0.2 then
        return (0.2 - inst.components.perishable:GetPercent()) * 2
    elseif hunger_percent < HUNGRY_PERIESH_PERCENT then
        return 0.025
    end

    return 0
end

local function IsAffectionate(inst)
    return
        (inst.components.perishable == nil or inst.components.perishable:GetPercent() > HUNGRY_PERIESH_PERCENT) -- no affection if hungry
        or false
end

local CRITTER_AVOID_COMBAT_CHECK_RADIUS = 10 -- Combat avoidance detection radius
local CRITTER_AVOID_COMBAT_TIME = 10 -- Combat avoidance duration

local function onfinishedavoidingcombat(inst) -- Reset combat avoidance task
    inst._avoidcombattask = nil
end

local function AvoidCombatCheck(inst) -- Check whether to avoid combat
    if inst._avoidcombattask ~= nil then
        return true
    end
    local owner = inst.components.follower.leader
    if owner then
        local x, _, z = owner.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, 0, z, CRITTER_AVOID_COMBAT_CHECK_RADIUS, nil, {"wall", "INLIMBO"}) -- Find nearby combat entities
        for _, ent in pairs(ents) do
            local combat = ent.components.combat
            if combat and combat:HasTarget() then
                inst._avoidcombattask = inst:DoTaskInTime(CRITTER_AVOID_COMBAT_TIME, onfinishedavoidingcombat)
                return true
            end
        end
    end

    return false
end
-------------------------------------------------------------------------------
local function OnSave(inst, data)
    if inst.wormlight ~= nil then
        data.wormlight = inst.wormlight:GetSaveRecord()
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.wormlight ~= nil and inst.wormlight == nil then
        local wormlight = SpawnSaveRecord(data.wormlight) -- Spawn saved wormlight record
        if wormlight ~= nil and wormlight.components.spell ~= nil then
            wormlight.components.spell:SetTarget(inst)
            if wormlight:IsValid() then
                if wormlight.components.spell.target == nil then
                    wormlight:Remove()
                else
                    wormlight.components.spell:ResumeSpell()
                end
            end
        end
    end
end

----------------------------------------------------------------------------------------------
local function OnClientFadeUpdate(inst) -- Client fade update
    inst._fadeval = math.max(0, inst._fadeval - 2 * FRAMES)
    local k = inst._fadeval >= .6 and 0 or 1 - inst._fadeval * inst._fadeval / .36
    inst.AnimState:SetMultColour(k, k, k, k)

    if inst._fadeval <= 0 then
        inst._fadetask:Cancel()
        inst._fadetask = nil
    end
end

local function OnMasterFadeUpdate(inst) -- Master fade update
    OnClientFadeUpdate(inst)
    inst.DynamicShadow:Enable(inst._fadeval <= .8)
    if inst._fadetask == nil then
        inst:RemoveTag("NOCLICK")
    end
end

local function FadeIn(inst) -- Initialize fade-in effect
    inst._fadeval = 1
    if inst._fadetask == nil then
        inst._fadetask = inst:DoPeriodicTask(FRAMES, OnMasterFadeUpdate)
        inst:AddTag("NOCLICK")
    end
    OnMasterFadeUpdate(inst)
end

-------------------------------------------------------------------------------

local function MakeFlyingCharacterPhysics(inst, mass, rad)
    local phys = inst.entity:AddPhysics()
    phys:SetMass(mass)
    phys:SetCapsule(rad, 1)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.FLYERS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.WORLD)
    phys:CollidesWith(COLLISION.GROUND)
    phys:CollidesWith(COLLISION.FLYERS)
end

local function MakeFlyingAmphibiousCharacterPhysics(inst, mass, rad) -- Amphibious flying physics
    local phys = inst.entity:AddPhysics()
    phys:SetMass(mass)
    phys:SetCapsule(rad, 1)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.FLYERS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.FLYERS)

    phys:CollidesWith(COLLISION.GROUND)
    phys:CollidesWith(COLLISION.OBSTACLES)
    phys:CollidesWith(COLLISION.WAVES)
    inst:AddTag("amphibious")
end

local function CanAcceptFn(inst, food) -- Check if food can be accepted
    if inst.components.eater:CanEat(food) and not inst.sg:HasStateTag('busy') then
        -- if not inst.components.follower.leader then
        --     inst.components.follower:SetLeader(GetPlayer())
        -- end
        return true
    elseif not inst.sg:HasStateTag('busy') then
        inst.sg:GoToState('nuzzle') -- Nuzzle if not busy and cannot eat
    end
    return false
end

local function MakeCritterFeedablePet(inst, name, starvetime, diet) -- Setup feedable pet components
    if not inst.components.eater then
        inst:AddComponent("eater")
    end
    inst.components.eater:SetOnEatFn(oneat)
    inst.components.eater.foodprefs = {"MEAT", "VEGGIE", "INSECT", "SEEDS", "GENERIC"}
    inst.components.eater.ablefoods = {"MEAT", "VEGGIE", "INSECT", "SEEDS", "GENERIC"}
    if not inst.components.trader then
        inst:AddComponent('trader')
        inst.components.trader:SetAcceptTest(diet)
    end

    inst:AddComponent("perishable") -- Hunger timer via perishing
    inst.components.perishable:SetPerishTime(starvetime)
    inst.components.perishable:StartPerishing()

    inst:AddTag("show_spoilage")
    inst:AddTag("pet")
end
local animdata = {
    bank = "kittington",
    build = "kittington_build",
    assets = {"kittington_build", "kittington_basic", "kittington_emotes"}
}
local assets = {}
for _, v in pairs(animdata.assets) do
    table.insert(assets, Asset("ANIM", "anim/" .. v .. ".zip"))
end

local function ShouldKeepTarget(inst, target)
    return false -- chester can't attack, and won't sleep if he has a target
end

-- Custom setup
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()

    inst.DynamicShadow:SetSize(2, .75)

    local face = 6
    if face == 2 then
        inst.Transform:SetTwoFaced()
    elseif face == 4 then
        inst.Transform:SetFourFaced()
    elseif face == 6 then
        inst.Transform:SetSixFaced()
    elseif face == 8 then
        inst.Transform:SetEightFaced()
    end

    inst.AnimState:SetBank(animdata.bank)
    inst.AnimState:SetBuild(animdata.build)
    inst.AnimState:PlayAnimation("idle_loop")

    local flying = false
    if flying then
        if ACTIONS.HACK ~= nil then
            MakeFlyingAmphibiousCharacterPhysics(inst, 1, .5)
        else
            MakeFlyingCharacterPhysics(inst, 1, .5)
        end
        inst.Physics:CollidesWith(COLLISION.CHARACTERS)
        inst:AddTag("flying")
    else
        if ACTIONS.HACK ~= nil then
            MakeAmphibiousCharacterPhysics(inst, 1, .5)
        else
            MakeCharacterPhysics(inst, 1, .5)
        end
    end

    inst:AddTag("critter")
    inst:AddTag("companion")
    inst:AddTag("notraptrigger")
    inst:AddTag("noauradamage")
    inst:AddTag("small_livestock")
    inst:AddTag("NOBLOCK")
    inst:AddTag("blackcat")

    inst:AddComponent("combat")
    inst.components.combat:SetKeepTargetFunction(ShouldKeepTarget)

    -- print("   health")
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.CHESTER_HEALTH)
    inst.components.health:StartRegen(TUNING.CHESTER_HEALTH_REGEN_AMOUNT, TUNING.CHESTER_HEALTH_REGEN_PERIOD)
    inst:AddTag("noauradamage") -- Immune to aura damage
    -- if data ~= nil and data.flyingsoundloop ~= nil then
    --     inst.SoundEmitter:PlaySound(data.flyingsoundloop, "flying")
    -- end

    inst.GetPeepChance = GetPeepChance
    inst.AvoidCombatCheck = AvoidCombatCheck
    inst.IsAffectionate = IsAffectionate

    inst:AddComponent("inspectable")
    -- inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("follower")
    -- inst.components.follower:KeepLeaderOnAttacked()
    -- inst.components.follower.keepdeadleader = true
    if ACTIONS.HACK ~= nil and inst.components.follower.SetFollowExitDestinations then
        inst.components.follower:SetFollowExitDestinations({EXIT_DESTINATION.LAND, EXIT_DESTINATION.WATER})
    end

    inst:AddComponent("knownlocations")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3) -- Sleep resistance
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)

    local name = "critter_kitten"
    local diet = CanAcceptFn
    MakeCritterFeedablePet(inst, name, TUNING.CRITTER_HUNGERTIME, diet)

    -- inst:AddComponent("sanityaura")
    -- inst.components.sanityaura.aurafn = PetSanityAura

    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(not flying)
    inst.components.locomotor:SetTriggersCreep(false) -- Does not trigger web/creep
    inst.components.locomotor.walkspeed = TUNING.CRITTER_WALK_SPEED
    inst:AddComponent("dsskins")
    inst:AddComponent("crittertraits")

    inst:SetBrain(brain)
    inst:SetStateGraph("SG" .. name)

    inst:ListenForEvent('trade', function(inst, data)
        if data and data.item and inst.components.eater then
            inst.components.eater:Eat(data.item)
        end
    end)
    inst:DoTaskInTime(0.1, function()
        if GetPlayer() and GetPlayer().components.huapetleash ~= nil then
            if not GetPlayer().components.huapetleash:IsFull() then
                if GetPlayer().components.huapetleash.LoadPet then
                    GetPlayer().components.huapetleash:LoadPet(inst)
                end
            else
                inst:Remove()
            end
        end
    end)
    inst.FadeIn = FadeIn
    inst.FadeIn(inst)
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    return inst
end

return Prefab("critter_kitten", fn, assets)

-- local function getstatus(inst) -- Return home on Alt press
--     if TheInput:IsKeyDown(KEY_ALT) then
--         local home = FindEntity(inst, 10, function(ent)
--             return ent.components.prototyper and ent:HasTag('critterlab')
--         end)
--         if home then
--             local x, y, z = home.Transform:GetWorldPosition()
--             inst:SetBrain(nil)
--             inst.sg:GoToState('idle')
--             inst.components.locomotor:GoToPoint(Point(x + 0.5, y, z + 0.5), nil, true)
--             -- GetPlayer().components.leader:RemoveFollower(inst)
--             inst:DoTaskInTime(1.5, function()
--                 inst:Remove()
--             end)
--         end
--     end
-- end

-- local function MakeCritter(name, animdata, face, diet, flying, data)
--     local assets = {}
--     for _, v in pairs(animdata.assets) do
--         table.insert(assets, Asset("ANIM", "anim/" .. v .. ".zip"))
--     end

--     local function fn()
--         local inst = CreateEntity()

--         inst.entity:AddTransform()
--         inst.entity:AddAnimState()
--         inst.entity:AddSoundEmitter()
--         inst.entity:AddDynamicShadow()

--         inst.DynamicShadow:SetSize(2, .75)

--         if face == 2 then
--             inst.Transform:SetTwoFaced()
--         elseif face == 4 then
--             inst.Transform:SetFourFaced()
--         elseif face == 6 then
--             inst.Transform:SetSixFaced()
--         elseif face == 8 then
--             inst.Transform:SetEightFaced()
--         end

--         inst.AnimState:SetBank(animdata.bank)
--         inst.AnimState:SetBuild(animdata.build)
--         inst.AnimState:PlayAnimation("idle_loop")

--         if flying then
--             if ACTIONS.HACK ~= nil then
--                 MakeFlyingAmphibiousCharacterPhysics(inst, 1, .5)
--             else
--                 MakeFlyingCharacterPhysics(inst, 1, .5)
--             end
--             inst.Physics:CollidesWith(COLLISION.CHARACTERS)
--             inst:AddTag("flying")
--         else
--             if ACTIONS.HACK ~= nil then
--                 MakeAmphibiousCharacterPhysics(inst, 1, .5)
--             else
--                 MakeCharacterPhysics(inst, 1, .5)
--             end
--         end

--         inst:AddTag("critter")
--         inst:AddTag("companion")
--         inst:AddTag("notraptrigger")
--         inst:AddTag("noauradamage")
--         inst:AddTag("small_livestock")
--         inst:AddTag("NOBLOCK")

--         if data ~= nil and data.flyingsoundloop ~= nil then
--             inst.SoundEmitter:PlaySound(data.flyingsoundloop, "flying")
--         end

--         inst.GetPeepChance = GetPeepChance
--         inst.AvoidCombatCheck = AvoidCombatCheck
--         inst.IsAffectionate = IsAffectionate

--         inst:AddComponent("inspectable")
--         inst.components.inspectable.getstatus = getstatus

--         inst:AddComponent("follower")
--         inst.components.follower:KeepLeaderOnAttacked()
--         inst.components.follower.keepdeadleader = true
--         if ACTIONS.HACK ~= nil then  
--             inst.components.follower:SetFollowExitDestinations({EXIT_DESTINATION.LAND, EXIT_DESTINATION.WATER}) --  
--         end

--         inst:AddComponent("knownlocations")

--         inst:AddComponent("sleeper")
--         inst.components.sleeper:SetResistance(3) 
--         inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
--         inst.components.sleeper:SetSleepTest(ShouldSleep)
--         inst.components.sleeper:SetWakeTest(ShouldWakeUp)

--         MakeCritterFeedablePet(inst, name, TUNING.CRITTER_HUNGERTIME, diet)

--         inst:AddComponent("sanityaura")
--         inst.components.sanityaura.aurafn = PetSanityAura

--         inst:AddComponent("locomotor")
--         inst.components.locomotor:EnableGroundSpeedMultiplier(not flying)
--         inst.components.locomotor:SetTriggersCreep(false)
--         inst.components.locomotor.walkspeed = TUNING.CRITTER_WALK_SPEED
--         inst:AddComponent("dsskins")
--         inst:AddComponent("crittertraits")

--         inst:SetBrain(brain)
--         inst:SetStateGraph("SG" .. name)

--         inst:ListenForEvent('trade', function(inst, data)
--             if data and data.item and inst.components.eater then
--                 inst.components.eater:Eat(data.item)
--             end
--         end)
--         inst:DoTaskInTime(0.1, function()
--             if GetPlayer() and GetPlayer().components.huapetleash ~= nil then
--                 if not GetPlayer().components.huapetleash:IsFull() then
--                     if GetPlayer().components.huapetleash.LoadPet then
--                         GetPlayer().components.huapetleash:LoadPet(inst)
--                     end
--                 else
--                     inst:Remove()
--                 end
--             end
--         end)
--         inst.FadeIn = FadeIn
--         inst.FadeIn(inst)
--         inst.OnSave = OnSave
--         inst.OnLoad = OnLoad
--         return inst
--     end

--     return Prefab(name, fn, assets)
-- end

-- -------------------------------------------------------------------------------
-- local function builder_onbuilt(inst, data)
--     local builder = GetPlayer()
--     local theta = math.random() * 2 * PI
--     local pt = builder:GetPosition()
--     local radius = 1
--     local offset = FindWalkableOffset(pt, theta, radius, 6, true)
--     if offset ~= nil then
--         pt.x = pt.x + offset.x
--         pt.z = pt.z + offset.z
--     end
--     if data and data.skin ~= nil then
--         builder.components.huapetleash:SpawnPetAt(pt.x, 0, pt.z, inst.pettype, data.skin)
--     else
--         builder.components.huapetleash:SpawnPetAt(pt.x, 0, pt.z, inst.pettype)
--     end
--     inst:Remove()
-- end

-- local function MakeBuilder(prefab)
--     local function fn()
--         local inst = CreateEntity()

--         inst.entity:AddTransform()

--         inst:AddTag("CLASSIFIED")

--         inst.persists = false
--         inst:DoTaskInTime(0, function()
--             inst:Remove()
--         end)

--         inst.pettype = prefab

--         inst:ListenForEvent('onbuilt', builder_onbuilt)
--         return inst
--     end

--     return Prefab(prefab .. "_builder", fn, nil, {prefab})
-- end

-- -------------------------------------------------------------------------------

-- local standard_diet = CanAcceptFn

-- return MakeCritter("critter_lamb", {
--     bank = "sheepington",
--     build = "sheepington_build",
--     assets = {"sheepington_build", "sheepington_basic", "sheepington_emotes"}
-- }, 6, standard_diet, false), MakeBuilder("critter_lamb"), MakeCritter("critter_puppy", {
--     bank = "pupington",
--     build = "pupington_build",
--     assets = {"pupington_build", "pupington_basic", "pupington_emotes"}
-- }, 4, standard_diet, false), MakeBuilder("critter_puppy"), MakeCritter("critter_kitten", {
--     bank = "kittington",
--     build = "kittington_build",
--     assets = {"kittington_build", "kittington_basic", "kittington_emotes"}
-- }, 6, standard_diet, false), MakeBuilder("critter_kitten"), MakeCritter("critter_dragonling", {
--     bank = "dragonling",
--     build = "dragonling_build",
--     assets = {"dragonling_build", "dragonling_basic", "dragonling_emotes"}
-- }, 6, standard_diet, true, {
--     flyingsoundloop = "dontstarve_DLC001/creatures/together/dragonling/fly_LP"
-- }), MakeBuilder("critter_dragonling"), MakeCritter("critter_glomling", {
--     bank = "glomling",
--     build = "glomling_build",
--     assets = {"glomling_build", "glomling_basic", "glomling_emotes"}
-- }, 6, standard_diet, true, {
--     flyingsoundloop = "dontstarve_DLC001/creatures/together/glomling/flap_LP"
-- }), MakeBuilder("critter_glomling"), MakeCritter("critter_perdling", {
--     bank = "perdling",
--     build = "perdling_build",
--     assets = {"perdling_build", "perdling_basic", "perdling_emotes", "perdling_traits"}
-- }, 4, standard_diet, false), MakeBuilder("critter_perdling")
