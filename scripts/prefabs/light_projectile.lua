local assets = {Asset("ANIM", "anim/staff_projectile.zip")}

---------------------------------------- Core Logic -------------------------------------------
local function Bounce(inst, owner, target)

    inst.components.projectile:SetLaunchOffset(Vector3(2, .5, 0))

    inst.components.projectile:Throw(owner, target)
end

local function FindTarget(inst) -- Find nearby target
    if inst.hitcount > 8 then
        inst:Remove()
        return nil
    end

    local radius = 8 -- Search radius
    local x, y, z = inst:GetPosition():Get()
    local ents = TheSim:FindEntities(x, 0, z, 8, {'combat'}, {'FX', 'NOCLICK', 'INLIMBO', 'DECOR', 'hiding', 'player'})
    for k, v in pairs(ents) do
        if not inst.hittargets[v] then
            if v.components.health and not v.components.health:IsDead() and not v:HasTag("wall") and
                not v:HasTag("companion") and not v:HasTag("chester") and not v:HasTag("abigail") and
                not v:HasTag("glommer") then
                return v
            end
        end
    end
end
----------------------------------------------------------------------------------------------
local function OnHit(inst, owner, target)
    local hit_target = target
    if hit_target then
        inst.hittargets[hit_target] = true
    end
    inst.hitcount = (inst.hitcount or 0) + 1

    if inst.components.projectile then
        inst.components.projectile:SetLaunchOffset(Vector3(2, .5, 0))
    end

    if owner and hit_target and owner == hit_target then
        inst:Remove()
    else
        local next_target = FindTarget(inst)
        if next_target then
            Bounce(inst, owner, next_target)
        else
            inst:Remove()
        end
    end

    local impactfx = SpawnPrefab("impact")
    if impactfx then
        if hit_target and hit_target:IsValid() and hit_target.components and hit_target.components.combat and hit_target.components.combat.hiteffectsymbol then
            local follower = impactfx.entity:AddFollower()
            follower:FollowSymbol(hit_target.GUID, hit_target.components.combat.hiteffectsymbol, 0, 0, 0)
        elseif hit_target and hit_target:IsValid() then
            impactfx.Transform:SetPosition(hit_target.Transform:GetWorldPosition())
        else
            impactfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
        impactfx:FacePoint(inst:GetPosition())
    end
end

local function OnHitMiss(inst, owner, target)
    inst:Remove()
end

-- local function OnHitIce(inst, owner, target)
--     if not target:HasTag("freezable") then
--         local fx = SpawnPrefab("shatter")
--         fx.Transform:SetPosition(target:GetPosition():Get())
--         fx.components.shatterfx:SetLevel(2)
--     end    

--     inst:Remove()
-- end

local function common()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    anim:SetBank("projectile")
    anim:SetBuild("staff_projectile")

    inst:AddTag("projectile")

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(25)
    inst.components.projectile:SetLaunchOffset(Vector3(2, .5, 0))
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnHitMiss)

    return inst
end

local function light()
    local inst = common()

    inst.hitcount = 0
    inst.hittargets = {}

    inst.AnimState:PlayAnimation("ice_spin_loop", true)
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(25)
    return inst
end

return Prefab("common/inventory/light_projectile", light, assets)
