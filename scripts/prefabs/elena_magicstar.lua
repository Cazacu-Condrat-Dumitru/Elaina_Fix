local assets = {
    Asset("ANIM", "anim/elena_magic.zip"),
    Asset("ANIM", "anim/swap_elena_magic.zip"),
    Asset("ATLAS", "images/inventoryimages/elena.xml"),
    Asset("IMAGE", "images/inventoryimages/elena.tex")
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_elena_magic", "swap_elena_magic")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("elena_magic")
    inst.AnimState:SetBuild("elena_magic")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")

    inst:AddComponent("weapon")
-- Damage taken from menu settings
    inst.components.weapon:SetDamage(TUNING.MAGICSTAR_DAMAGE or 34)
    inst.components.weapon:SetRange(8, 10)
    inst.components.weapon:SetProjectile("light_projectile")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/elena.xml"
    inst.components.inventoryitem.imagename = "elena_magic"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    return inst
end

return Prefab("common/inventory/elena_magicstar", fn, assets)