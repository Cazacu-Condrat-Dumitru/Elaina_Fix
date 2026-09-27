local magicpoint = Class(function(self, inst)
    self.inst = inst
    self.maxmagicpoint = 100 -- Max value
    self.current = self.maxmagicpoint
    self.penalty = 0
    self.percent = 1
end)
function magicpoint:DoDelta(delta)
    local newmagicpoint = self.current + delta
    local newPercent = newmagicpoint / self.maxmagicpoint
    self.current = newmagicpoint
    self.inst:PushEvent("magicpointdelta", {
        current = newmagicpoint,
        npercent = newPercent
    })
end

function magicpoint:GetPenaltyPercent()
    return (self.penalty * TUNING.EFFIGY_HEALTH_PENALTY) / self.maxmagicpoint
end

function magicpoint:GetPercent()
    return self.current / self.maxmagicpoint
end
return magicpoint

