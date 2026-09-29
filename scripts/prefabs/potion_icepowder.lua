local U = require "elena_util"

local Assets = {Asset("ANIM", "anim/potion_icepowder.zip"), Asset("ATLAS", "images/inventoryimages/potions.xml"),
                Asset("IMAGE", "images/inventoryimages/potions.tex")}

local BUFF_DURATION = 30
local DAMAGE_BONUS = 0.25
local NOVA_RADIUS = 12
local NOVA_COLDNESS = 4

local function FreezeHit(attacker, target)
    if not (target and target:IsValid()) then return end
    if target.components.freezable then
        target.components.freezable:AddColdness(1)
        target.components.freezable:SpawnShatterFX()
    end
    if target.components.burnable and target.components.burnable:IsBurning() then
        target.components.burnable:Extinguish()
    end
end

-- Adds a freezing touch to the held weapon for a while, keeping (and later
-- restoring) whatever on-hit effect the weapon already had.
local function EnchantWeapon(item)
    local weapon = item and item.components.weapon
    if not weapon then
        return -- umbrellas, lanterns, tools without a weapon component
    end

    if item.elena_frost_task then
        item.elena_frost_task:Cancel()
    else
        item.elena_frost_orig = weapon.onattack
    end

    local orig = item.elena_frost_orig
    weapon:SetOnAttack(function(w, attacker, target, projectile)
        if orig then
            orig(w, attacker, target, projectile)
        end
        FreezeHit(attacker, target)
    end)

    item.elena_frost_task = item:DoTaskInTime(BUFF_DURATION, function()
        item.elena_frost_task = nil
        if item.components.weapon then
            item.components.weapon:SetOnAttack(item.elena_frost_orig)
        end
        item.elena_frost_orig = nil
    end)
end

local function FrostNova(eater)
    local x, y, z = eater.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, NOVA_RADIUS, nil, {"player", "companion", "INLIMBO", "FX", "NOCLICK"})
    for _, ent in ipairs(ents) do
        if ent:IsValid() then
            if ent.components.burnable and ent.components.burnable:IsBurning() then
                ent.components.burnable:Extinguish()
            end
            if ent.components.freezable and U.IsHostileTo(ent, eater) then
                ent.components.freezable:AddColdness(NOVA_COLDNESS)
                ent.components.freezable:SpawnShatterFX()
            end
        end
    end
    U.PlaySound(eater, "dontstarve/common/gem_shatter")
end

local function oneaten(inst, eater)
    -- Only players can channel the elixir; animals just get the food value
    if not (eater and eater:IsValid() and eater:HasTag("player")) then
        return
    end

    if eater.components.inventory then
        EnchantWeapon(eater.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS))
    end

    if eater.components.combat then
        U.SetDamageBonus(eater, "elena_frost", DAMAGE_BONUS)
        if eater.elena_frost_buff_task then
            eater.elena_frost_buff_task:Cancel()
        end
        eater.elena_frost_buff_task = eater:DoTaskInTime(BUFF_DURATION, function()
            eater.elena_frost_buff_task = nil
            U.SetDamageBonus(eater, "elena_frost", 0)
        end)
    end

    FrostNova(eater)

    if eater.components.talker then
        eater.components.talker:Say("Frost Nova!")
    end
end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)
    U.MakeFloatable(inst)

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
