local assets = {
    Asset("ANIM", "anim/elena_hat.zip"),
    Asset("ANIM", "anim/swap_elena_hat.zip"),
    Asset("ANIM", "anim/elena.zip"),
    Asset("ATLAS", "images/inventoryimages/elena.xml"),
    Asset("IMAGE", "images/inventoryimages/elena.tex")
}

local function onequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:OverrideSymbol("headbase_hat", "swap_elena_hat", "headbase_hat")
    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")
    if owner:HasTag("player") then
        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("headbase_hat")
    owner.AnimState:OverrideSymbol("headbase_hat", "elena", "headbase")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
    end
end

local function fn(sim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("elena_hat")
    inst.AnimState:SetBuild("elena_hat")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("elena_hat")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/elena.xml"
    inst.components.inventoryitem.imagename = "elena_hat"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst.components.equippable.insulated = true
    inst.components.equippable.dapperness = TUNING.DAPPERNESS_LARGE

    -- Configurable water resistance
    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.ELENA_HAT_WATERPROOF or 1.0)

    return inst
end

return Prefab("common/inventory/elena_hat", fn, assets)