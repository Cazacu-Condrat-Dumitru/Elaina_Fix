local U = require "elena_util"

local assets =
{
    Asset("ANIM", "anim/potion_sourceliquid.zip"),
    Asset("ATLAS", "images/inventoryimages/potions.xml"), Asset("IMAGE", "images/inventoryimages/potions.tex") 
}

-- Restores 5 health and 5 sanity every 3 seconds, 12 times.
-- Safe for any eater: pigs and birds have no sanity component.
local function oneaten(inst, eater)
    U.StartRegen(eater, "elena_source_regen", 3, 12, 5, 5)
end

local function fn(Sim)
    local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    
    MakeInventoryPhysics(inst)
    U.MakeFloatable(inst)
    
    inst.AnimState:SetBank("potion_sourceliquid")
    inst.AnimState:SetBuild("potion_sourceliquid")
    inst.AnimState:PlayAnimation("idle")
    
    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")
	
	inst:AddComponent("edible")
	inst.components.edible.healthvalue = 25
	inst.components.edible.hungervalue = 10
	inst.components.edible.sanityvalue = 25
	inst.components.edible:SetOnEatenFn(oneaten)
    

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/potions.xml"
    inst.components.inventoryitem.imagename = "potion_sourceliquid"

    return inst
end

return Prefab("potion_sourceliquid", fn, assets)


