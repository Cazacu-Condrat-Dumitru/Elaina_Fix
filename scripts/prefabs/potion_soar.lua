local U = require "elena_util"

local assets=
{
	Asset("ANIM", "anim/potion_soar.zip"),
    Asset("ATLAS", "images/inventoryimages/potions.xml"),
    Asset("IMAGE", "images/inventoryimages/potions.tex")
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.AnimState:SetBank("potion_soar")
    inst.AnimState:SetBuild("potion_soar")
    inst.AnimState:PlayAnimation("idle")  
    
    MakeInventoryPhysics(inst)
    U.MakeFloatable(inst)

    
    inst:AddTag("catfood")

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_SMALL
    inst.components.edible.sanityvalue = TUNING.SANITY_SMALL
    inst.components.edible.caffeineduration = 240
    inst.components.edible.caffeinedelta = 10
    -- inst.components.edible.foodtype = "MEAT"
    
    
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")  
    inst.components.inventoryitem.atlasname = "images/inventoryimages/potions.xml"
    inst.components.inventoryitem.imagename = "potion_soar"

	return inst
end

return Prefab("common/inventory/potion_soar", fn, assets)
