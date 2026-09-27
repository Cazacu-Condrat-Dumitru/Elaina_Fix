require "behaviours/chaseandattack"
require "behaviours/follow"
require "behaviours/wander"
require "behaviours/faceentity"

local HokiBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local MIN_FOLLOW_DIST = 2
local TARGET_FOLLOW_DIST = 4
local MAX_FOLLOW_DIST = 7
local MAX_CHASE_TIME = 6
local MAX_WANDER_DIST = 4

local function GetLeader(inst)
    return inst.components.follower and inst.components.follower.leader
end

local function GetFaceTargetFn(inst)
    return GetLeader(inst)
end

local function KeepFaceTargetFn(inst, target)
    return GetLeader(inst) == target
end

local function FindItemToCollect(inst)
    -- Only active in Farm / Resource Gathering Mode!
    if (inst.hoki_mode or "farm") ~= "farm" then
        return nil
    end

    local leader = GetLeader(inst)
    if not leader or not leader:IsValid() or (leader.components.health and leader.components.health:IsDead()) then
        return nil
    end

    if not leader.components.inventory then
        return nil
    end

    -- If leader is too far (> 10 units), follow leader instead of hunting for items
    if inst:GetDistanceSqToInst(leader) > 10 * 10 then
        return nil
    end

    local inv_full = leader.components.inventory:IsFull()
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 8, nil, {"INLIMBO", "catchable", "fire", "irreplaceable", "heavy", "trap", "mine"})
    local closest = nil
    local closest_distsq = 8 * 8

    for _, ent in ipairs(ents) do
        if ent:IsValid() and not ent:IsInLimbo() and ent.components.inventoryitem and ent.components.inventoryitem.canbepickedup and not ent.components.inventoryitem:IsHeld() then
            if not (ent.components.burnable and ent.components.burnable:IsBurning()) then
                -- Respect player drop cooldown (so player can drop items without Hoki re-grabbing them instantly)
                local dropped_time = ent.just_dropped_by_player or 0
                if GetTime() - dropped_time > 4 then
                    local can_accept = not inv_full
                    if not can_accept and ent.components.stackable and not ent.components.stackable:IsFull() then
                        if leader.components.inventory:Has(ent.prefab, 1) then
                            can_accept = true
                        end
                    end

                    if can_accept then
                        local dist_leader_sq = ent:GetDistanceSqToInst(leader)
                        if dist_leader_sq <= 12 * 12 then
                            local distsq = inst:GetDistanceSqToInst(ent)
                            if distsq < closest_distsq then
                                closest_distsq = distsq
                                closest = ent
                            end
                        end
                    end
                end
            end
        end
    end

    return closest
end

local CollectItem = Class(BehaviourNode, function(self, inst)
    BehaviourNode._ctor(self, "CollectItem")
    self.inst = inst
    self.target = nil
end)

function CollectItem:Visit()
    if self.status == READY then
        local item = FindItemToCollect(self.inst)
        if item then
            self.target = item
            self.status = RUNNING
        else
            self.status = FAILED
        end
    end

    if self.status == RUNNING then
        local leader = GetLeader(self.inst)
        if not self.target or not self.target:IsValid() or self.target:IsInLimbo() or not leader or not leader:IsValid() or self.inst:GetDistanceSqToInst(leader) > 12 * 12 then
            self.target = nil
            self.status = FAILED
            return
        end

        local distsq = self.inst:GetDistanceSqToInst(self.target)
        if distsq <= 2.2 * 2.2 then
            self.inst.components.locomotor:Stop()
            self.inst:FacePoint(self.target.Transform:GetWorldPosition())
            self.inst.collect_target = self.target
            self.inst.sg:GoToState("collect")
            self.target = nil
            self.status = SUCCESS
        else
            self.inst.components.locomotor:GoToPoint(self.target:GetPosition(), nil, true)
            self:Sleep(0.2)
        end
    end
end

function HokiBrain:OnStart()
    local root = PriorityNode({
        -- 1. Attack active combat targets within chase limit
        ChaseAndAttack(self.inst, MAX_CHASE_TIME),

        -- 2. Collect nearby items when close to Elaina
        CollectItem(self.inst),

        -- 3. Follow Elaina closely
        Follow(self.inst, function() return GetLeader(self.inst) end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST, true),

        -- 4. Face Elaina when close
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),

        -- 5. Soft wander around Elaina's position (disabled in passive mode)
        Wander(self.inst, function()
            if self.inst.hoki_mode == "passive" then
                return nil
            end
            local leader = GetLeader(self.inst)
            return leader and leader:GetPosition() or self.inst:GetPosition()
        end, MAX_WANDER_DIST)
    }, 0.5)

    self.bt = BT(self.inst, root)
end

return HokiBrain
