local U = require "elena_util"

local assets = {Asset("ANIM", "anim/elena_broom.zip"), Asset("ANIM", "anim/swap_elena_broom.zip"),
                Asset("ATLAS", "images/inventoryimages/elena.xml"), Asset("IMAGE", "images/inventoryimages/elena.tex")}

local function onequip(inst, owner)
    inst:AddTag("elena_broom")
    owner.AnimState:OverrideSymbol("swap_object", "swap_elena_broom", "swap_elena_broom")
    -- Override player's "swap_object" symbol with the broom build
    owner.AnimState:Show("ARM_carry")
    -- Show the carrying arm when equipped
    owner.AnimState:Hide("ARM_normal")
    -- Hide the normal idle arm
end

local function onunequip(inst, owner)
    inst:RemoveTag("elena_broom")
    owner.AnimState:Hide("ARM_carry")
    -- Hide the carrying arm when unequipped
    owner.AnimState:Show("ARM_normal")
    -- Show the normal idle arm
end

local function fn(Sim)
    local inst = CreateEntity()

    local trans = inst.entity:AddTransform()

    local anim = inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)
    U.MakeFloatable(inst)

    anim:SetBank("elena_broom")

    anim:SetBuild("elena_broom")

    anim:PlayAnimation("idle")

    inst:AddTag("broom")
    inst:AddTag("elena_broom")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.BROOM_DAMAGE or 34)
    inst.components.weapon:SetRange(TUNING.BROOM_RANGE)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/elena.xml"
    inst.components.inventoryitem.imagename = "elena_broom"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    return inst
end

return Prefab("common/inventory/elena_broom", fn, assets)
