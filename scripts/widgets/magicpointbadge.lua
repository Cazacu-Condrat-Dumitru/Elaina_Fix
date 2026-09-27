local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

local magicpointBadge = Class(Badge, function(self, owner)
    Badge._ctor(self, "magicpoint", owner)

    self.sanityarrow = self.underNumber:AddChild(UIAnim())
    self.sanityarrow:GetAnimState():SetBank("sanity_arrow")
    self.sanityarrow:GetAnimState():SetBuild("sanity_arrow")
    self.sanityarrow:GetAnimState():PlayAnimation("neutral")
    self.sanityarrow:SetClickable(false)

    self.topperanim = self.underNumber:AddChild(UIAnim())
    self.topperanim:GetAnimState():SetBank("effigy_topper")
    self.topperanim:GetAnimState():SetBuild("effigy_topper")
    self.topperanim:GetAnimState():PlayAnimation("anim")
    self.topperanim:SetClickable(false)

    self.owner = owner
    self.maxmagicpoint = 100
    self.percent = 1
    self.owner:ListenForEvent("magicpointdelta", function(inst, data)
        self:onmagicpointdelta(inst, data)
    end)

    self:SetPosition(0,35,0)
    self:SetPercent(self.owner.components.magicpoint:GetPercent(), self.owner.components.magicpoint.maxmagicpoint,
        self.owner.components.magicpoint:GetPenaltyPercent())
    -- self:StartUpdating()
end)

function magicpointBadge:SetPercent(val, max, penaltypercent)
    Badge.SetPercent(self, val, max)

    penaltypercent = penaltypercent or 0
    self.topperanim:GetAnimState():SetPercent("anim", penaltypercent)
end

function magicpointBadge:onmagicpointdelta(inst, data)
    if data then
        self.magicpoint = data.current
        self.percent = data.npercent
    end
end

return magicpointBadge
