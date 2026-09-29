local U = require "elena_util"

-- EXP needed to go from `level` to `level + 1`.
-- Totals: Lv10 = 1,800 | Lv20 = 5,700 | Lv50 = 29,400 | Lv100 = 108,900
local function NeededExp(level)
    return 100 + 20 * level
end

local function RefreshMaxStats(self)
    local inst = self.inst
    local bonus = (self.level - 1) * (TUNING.ELENA_STATS_PER_LEVEL or 1)

    if inst.components.hunger then
        inst.components.hunger.max = TUNING.ELENA_HUNGER + bonus
        inst.components.hunger:DoDelta(0)
    end
    if inst.components.health then
        inst.components.health.maxhealth = TUNING.ELENA_HEALTH + bonus
        inst.components.health:DoDelta(0)
    end
    if inst.components.sanity then
        inst.components.sanity.max = TUNING.ELENA_SANITY + bonus
        inst.components.sanity:DoDelta(0)
    end

    U.SetDamageBonus(inst, "elena_level", (self.level - 1) * (TUNING.ELENA_LEVEL_DAMAGE_BONUS or 0.01))
end

local function GetTier(level)
    if level >= 50 then
        return 3 -- Seasoned traveler
    elseif level >= 20 then
        return 2 -- Wandering witch
    end
    return 1 -- Freshly-graduated witch
end

local function ApplyTier(self, announce)
    local inst = self.inst
    local old_tier = self.elaina_tier or 1
    local new_tier = GetTier(self.level)
    self.elaina_tier = new_tier

    if new_tier == 3 then
        U.SetSpeedMult(inst, "elaina_tier_speed", 1.20)
    elseif new_tier == 2 then
        U.SetSpeedMult(inst, "elaina_tier_speed", 1.10)
    else
        U.SetSpeedMult(inst, "elaina_tier_speed", 1.0)
    end

    -- Tier 3: a light warding spell against the weather (like a winter hat
    -- and a straw hat combined), not full immunity.
    local temp = inst.components.temperature
    if temp and temp.inherentinsulation ~= nil then
        local ward = (new_tier == 3) and 60 or 0
        temp.inherentinsulation = ward
        if temp.inherentsummerinsulation ~= nil then
            temp.inherentsummerinsulation = ward
        end
    end

    if announce and new_tier > old_tier and inst.components.talker then
        local x, y, z = inst.Transform:GetWorldPosition()
        U.SpawnFxAt("sparks_fx", x, y + 0.5, z)
        U.PlaySound(inst, "dontstarve/HUD/research_available")
        if new_tier == 2 then
            inst.components.talker:Say("My magic grows with every journey. Naturally.")
        else
            inst.components.talker:Say("Who is this dazzling, accomplished witch? Why, it's me, of course.")
        end
    end
end

local Level = Class(function(self, inst)
    self.inst = inst
    self.exp = 0
    self.level = 1
    self.elaina_tier = 1
end)

function Level:GetNeededExp()
    return NeededExp(self.level)
end

function Level:IsMaxLevel()
    return self.level >= (TUNING.ELENA_MAXLEVEL or 100)
end

function Level:Refresh(announce)
    if not (self.inst and self.inst:IsValid()) then return end
    RefreshMaxStats(self)
    ApplyTier(self, announce)
end

function Level:DoDelta(amount, silent)
    if self:IsMaxLevel() then
        self.exp = 0
        return
    end

    self.exp = self.exp + (amount or 0)
    local leveled = false
    while not self:IsMaxLevel() and self.exp >= NeededExp(self.level) do
        self.exp = self.exp - NeededExp(self.level)
        self.level = self.level + 1
        leveled = true
    end
    if self:IsMaxLevel() then
        self.exp = 0
    end

    if leveled then
        self:Refresh(not silent)
        if not silent and self.inst.components.talker then
            local msg = "Level " .. self.level .. "!"
            if self.level == 10 then
                msg = msg .. " I can finally fly on my broom. [R]"
            end
            self.inst.components.talker:Say(msg)
        end
    end
end

function Level:OnSave()
    return {
        exp = self.exp,
        level = self.level,
    }
end

function Level:OnLoad(data)
    if data then
        self.exp = data.exp or 0
        self.level = math.max(1, math.min(data.level or 1, TUNING.ELENA_MAXLEVEL or 100))
        -- Older saves may hold more EXP than the new curve needs
        self:DoDelta(0, true)
    end
    self:Refresh(false)
end

return Level
