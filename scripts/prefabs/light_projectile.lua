local assets = {Asset("ANIM", "anim/staff_projectile.zip")}

local prefabs = {"impact"}

-- Homing star bolt fired by Elaina's Magic Wand. Damage comes from the wand.
local function SpawnImpact(inst, target)
    local impactfx = SpawnPrefab("impact")
    if not impactfx then return end

    if target and target:IsValid() and target.components.combat and target.components.combat.hiteffectsymbol then
        local follower = impactfx.entity:AddFollower()
        follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
    elseif target and target:IsValid() then
        impactfx.Transform:SetPosition(target.Transform:GetWorldPosition())
    else
        impactfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
    impactfx:FacePoint(inst.Transform:GetWorldPosition())
end

local function OnHit(inst, owner, target)
    SpawnImpact(inst, target)
    inst:Remove()
end

local function OnMiss(inst, owner, target)
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("projectile")
    inst.AnimState:SetBuild("staff_projectile")
    inst.AnimState:PlayAnimation("ice_spin_loop", true)

    inst:AddTag("projectile")

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(25)
    inst.components.projectile:SetLaunchOffset(Vector3(2, .5, 0))
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnMiss)

    inst.persists = false

    return inst
end

return Prefab("common/inventory/light_projectile", fn, assets, prefabs)
