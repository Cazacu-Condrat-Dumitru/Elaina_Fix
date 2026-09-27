local assets =
{
    Asset("ANIM", "anim/potion_magic.zip"),
    Asset("ATLAS", "images/inventoryimages/potions.xml"), Asset("IMAGE", "images/inventoryimages/potions.tex") 
}

local function oneaten(inst, eater)
	local heju = eater:DoPeriodicTask(3, function()  eater.components.health:DoDelta(5)  eater.components.sanity:DoDelta(5) end)
	heju.limit = 12
end

local function fn(Sim)
    local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    
    MakeInventoryPhysics(inst)
    
    inst.AnimState:SetBank("potion_magic")
    inst.AnimState:SetBuild("potion_magic")
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
    inst.components.inventoryitem.imagename = "potion_magic"

    return inst
end

return Prefab("potion_magic", fn, assets)


