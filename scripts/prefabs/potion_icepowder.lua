local Assets = {Asset("ANIM", "anim/potion_icepowder.zip"), Asset("ATLAS", "images/inventoryimages/potions.xml"),
                Asset("IMAGE", "images/inventoryimages/potions.tex")}

local function freezeAttack(inst, attacker, target)
    if target.components.freezable then
        target.components.freezable:AddColdness(1)
        target.components.freezable:SpawnShatterFX()
    end
    if target.components.sleeper and target.components.sleeper:IsAsleep() then
        target.components.sleeper:WakeUp()
    end
    if target.components.burnable and target.components.burnable:IsBurning() then
        target.components.burnable:Extinguish()
    end
    if target.components.combat then
        target.components.combat:SuggestTarget(attacker)
        if target.sg and not target.sg:HasStateTag("frozen") and target.sg.sg.states.hit then
            target.sg:GoToState("hit")
        end
    end
end

-- local function item_onuse(inst, doer)
--     print("---- icepowder item_onuse()")

--     -- if doer.components.health then
--     --     doer.components.health:DoDelta(10) -- health modification function
--     -- end
--     if doer.components.inventory.equipslots.hands ~= nil then
--         local onarm = doer.components.inventory.equipslots.hands.components.weapon
--         -- onarm:SetDamage(20)
--         -- onarm:SetOnAttack(freezeAttack)

--         -- doer:DoTaskInTime(TUNING.TOTAL_DAY_TIME , onarm:SetDamage(20))
--         -- doer:DoTaskInTime(TUNING.TOTAL_DAY_TIME , onarm:SetOnAttack(freezeAttack))

--         doer:DoTaskInTime(TUNING.SEG_TIME, onarm:SetDamage(20))
--         doer:DoTaskInTime(TUNING.SEG_TIME, onarm:SetOnAttack(freezeAttack))
--     end
--     -- eater.antihayfever_time = TUNING.ANTIHAYFEVER_TIME
--     -- --    if eater.antihayfever_task == nil then
--     -- if not eater:HasTag("has_hayfeverhat") then
--     --     eater.antihayfever_task = eater:DoTaskInTime(1, function()
--     --         preventHayfever(eater)
--     --     end)
--     -- end
--     print("----2 icepowder item_onuse()")
-- end

local function oneaten(inst, eater)
    if eater.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= nil then
        -- local onarm = eater.components.inventory.equipslots.hands.components.weapon
        local onarm = eater.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        onarm.components.weapon:SetOnAttack(freezeAttack)
        onarm:DoTaskInTime(30, function()
            onarm.components.weapon:SetOnAttack()
        end)
    end
    if eater.components.combat then
        if eater.components.combat.AddDamageModifier then
            eater.components.combat:AddDamageModifier("monika", 0.25)
            eater:DoTaskInTime(30, function()
                if eater:IsValid() and eater.components.combat then
                    eater.components.combat:RemoveDamageModifier("monika")
                end
            end)
        else
            local old_mult = eater.components.combat.damagemultiplier or 1
            eater.components.combat.damagemultiplier = old_mult + 0.25
            eater:DoTaskInTime(30, function()
                if eater:IsValid() and eater.components.combat then
                    eater.components.combat.damagemultiplier = math.max(0.5, (eater.components.combat.damagemultiplier or 1.25) - 0.25)
                end
            end)
        end
    end

    if eater and eater:IsValid() then
        local x, y, z = eater.Transform:GetWorldPosition()
        local ents = _G.TheSim:FindEntities(x, y, z, 12, {"_combat"}, {"player", "companion", "INLIMBO"})
        for _, target in ipairs(ents) do
            if target:IsValid() and target.components.freezable then
                target.components.freezable:AddColdness(4)
                target.components.freezable:SpawnShatterFX()
            end
            if target:IsValid() and target.components.sleeper and target.components.sleeper:IsAsleep() then
                target.components.sleeper:WakeUp()
            end
            if target:IsValid() and target.components.burnable and target.components.burnable:IsBurning() then
                target.components.burnable:Extinguish()
            end
        end

        if eater.SoundEmitter then
            eater.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
        end

        if eater.components.talker then
            eater.components.talker:Say("Frost Nova unleashed!")
        end
    end
end

-- local id = "USE"
-- local name = "use"
-- local fn = function(act)
--     if act.doer.component then
--         act.doer.component.health:DoDelta(10) -- health modification function
--     end
-- end

-- AddAction(id,name,fn)

-- -- Define action
-- local USE = Action() -- Action has id, str, fn; fn receives act parameter with doer, target, invobject, pos
-- USE.id = "USE"
-- USE.str = "Use"
-- -- The four common action fields are doer, target, invobject, pos
-- USE.fn = function(act)
--     if act.doer.component then
--         act.doer.component.health:DoDelta(10) 
--     end
-- end

-- Register action
-- AddAction(USE)

-- Bind component
-- local function usepotion(component)
--     local old = component.CollectInventoryActions
--     component.CollectInventoryActions = function(doer, actions)
--         if doer.components.health then
--             table.insert(actions, ACTIONS.USE) -- test 2
--         end
--         old(doer, actions)
--     end
-- end
-- AddComponentPostInit("healer", usepotion)   

-- Bind state
-- AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.USE, "dolongaction"))

-- Write a local function that creats, customizes, and returns an instance of the prefab.
local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)

    -- inst.AddTag("potion")

    inst.AnimState:SetBank("potion_icepowder")
    inst.AnimState:SetBuild("potion_icepowder")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/potions.xml"
    inst.components.inventoryitem.imagename = "potion_icepowder"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = 25
    inst.components.edible.hungervalue = 10
    inst.components.edible.sanityvalue = 25
    inst.components.edible:SetOnEatenFn(oneaten)

    inst:AddComponent("inspectable")

    return inst
end

return Prefab("common/inventory/potion_icepowder", fn, Assets)

