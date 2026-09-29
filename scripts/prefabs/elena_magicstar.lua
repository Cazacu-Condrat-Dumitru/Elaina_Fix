local U = require "elena_util"

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

-- Every bolt that lands costs a little focus (sanity): magic isn't free.
local function onattack(inst, attacker, target, projectile)
    local cost = TUNING.ELENA_WAND_SANITY_COST or 1
    if cost > 0 and attacker and attacker.components.sanity then
        attacker.components.sanity:DoDelta(-cost)
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)
    U.MakeFloatable(inst)

    inst.AnimState:SetBank("elena_magic")
    inst.AnimState:SetBuild("elena_magic")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")

    inst:AddComponent("weapon")
-- Damage taken from menu settings
    inst.components.weapon:SetDamage(TUNING.MAGICSTAR_DAMAGE or 25)
    inst.components.weapon:SetOnAttack(onattack)
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