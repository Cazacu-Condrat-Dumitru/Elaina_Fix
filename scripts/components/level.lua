local _G = getfenv(1)

local function ApplySpeedBonus(inst, key, mult)
    if not (inst and inst.components and inst.components.locomotor) then return end
    if inst.components.locomotor.SetExternalSpeedMultiplier then
        if mult and mult ~= 1.0 then
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, key, mult)
        else
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, key)
        end
    else
        inst.speed_mults = inst.speed_mults or {}
        if mult and mult ~= 1.0 then
            inst.speed_mults[key] = mult
        else
            inst.speed_mults[key] = nil
        end
        local total = 1.0
        for _, m in pairs(inst.speed_mults) do
            total = total * m
        end
        local base_run = TUNING.WILSON_RUN_SPEED or 6
        inst.components.locomotor.bonusspeed = base_run * (total - 1.0)
    end
end

local function ApplyDamageBonus(inst, bonus_ratio)
    if not (inst and inst.components and inst.components.combat) then return end
    local base_mult = TUNING.WENDY_DAMAGE_MULT or 0.75
    local total_mult = base_mult + (bonus_ratio or 0)
    if inst.components.combat.AddDamageModifier then
        inst.components.combat:AddDamageModifier("level_bonus", 1 + (bonus_ratio or 0))
    else
        inst.components.combat.damagemultiplier = total_mult
    end
end

local function onlevel(self)
    if not (self.inst and self.inst:IsValid()) then return end

    if self.inst.components.hunger then
        self.inst.components.hunger.max = TUNING.ELENA_HUNGER + self.level * 2 - 2
    end
    if self.inst.components.health then
        self.inst.components.health.maxhealth = TUNING.ELENA_HEALTH + self.level * 2 - 2
    end
    if self.inst.components.sanity then
        self.inst.components.sanity.max = TUNING.ELENA_SANITY + self.level * 2 - 2
    end

    -- Configurable attack bonus per level
    local bonus_rate = TUNING.ELENA_LEVEL_DAMAGE_BONUS or 0.01
    local bonus = (self.level - 1) * bonus_rate
    ApplyDamageBonus(self.inst, bonus)

    -- Visual & Ability Evolution across Light Novel Phases
    local old_tier = self.elaina_tier or 1
    local new_tier = 1

    if self.level >= 50 then
        new_tier = 3 -- Legendary Ashen Witch (Volume 7 mid-20s & Animate 2025 Grand Form)
    elseif self.level >= 20 then
        new_tier = 2 -- Wandering Sorceress (Volume 4-15 Advanced Traveling Form)
    else
        new_tier = 1 -- Apprentice Traveler (Volume 1-3 & Anime Form)
    end

    self.elaina_tier = new_tier

    -- Ensure Light entity exists
    if not self.inst.Light then
        self.inst.entity:AddLight()
    end

    if new_tier == 1 then
        if self.inst.Light then
            self.inst.Light:Enable(false)
        end
        ApplySpeedBonus(self.inst, "elaina_tier_speed", 1.0)
    elseif new_tier == 2 then
        -- Tier 2: Warm ambient magical glow, +10% travel speed
        if self.inst.Light then
            self.inst.Light:SetRadius(2.4)
            self.inst.Light:SetIntensity(0.7)
            self.inst.Light:SetFalloff(0.6)
            self.inst.Light:SetColour(255/255, 230/255, 190/255)
            self.inst.Light:Enable(true)
        end
        ApplySpeedBonus(self.inst, "elaina_tier_speed", 1.10)
    elseif new_tier == 3 then
        -- Tier 3: Brilliant celestial starlight aura, +20% travel speed, weather resilience
        if self.inst.Light then
            self.inst.Light:SetRadius(4.0)
            self.inst.Light:SetIntensity(0.85)
            self.inst.Light:SetFalloff(0.5)
            self.inst.Light:SetColour(255/255, 240/255, 220/255)
            self.inst.Light:Enable(true)
        end
        ApplySpeedBonus(self.inst, "elaina_tier_speed", 1.20)
        -- Passive thermal protection
        if self.inst.components.temperature then
            self.inst.components.temperature.mintemp = 15
            self.inst.components.temperature.maxtemp = 60
        end
    end

    -- Trigger fanfare and dialogue upon advancing tiers
    if self.inst.components.talker and new_tier > old_tier then
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local fx = _G.SpawnPrefab("sparks_fx") or _G.SpawnPrefab("statue_transition")
        if fx then
            fx.Transform:SetPosition(x, y + 0.5, z)
        end
        if self.inst.SoundEmitter then
            self.inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/level_up")
        end
        if new_tier == 2 then
            self.inst.components.talker:Say("My magical capacity has expanded! The world has so much more to teach me.")
        elseif new_tier == 3 then
            self.inst.components.talker:Say("Behold, the Ashen Witch at the pinnacle of sorcery! Yes, that beautiful genius is none other than me!")
        end
    end

    -- Synchronize with companion Hoki if nearby
    if _G.TheSim and self.inst:IsValid() then
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local ents = _G.TheSim:FindEntities(x, y, z, 20, {"hoki"})
        for _, hoki in ipairs(ents) do
            if hoki.UpdateStage then
                hoki:UpdateStage()
            end
        end
    end
end

local level = Class(function(self, inst)
    self.inst = inst
    self.exp = 0
    self.level = 1
end, nil, {
    level = onlevel
})

function level:DoDelta(amount)
    self.exp = self.exp + amount
    local needsexp = self.level * 400

    while self.exp >= needsexp and self.level < (TUNING.ELENA_MAXLEVEL or 100) do
        self.exp = self.exp - needsexp
        self.level = self.level + 1
        onlevel(self)
        
        if self.inst.components.talker then
            self.inst.components.talker:Say("Level Up! Current Level: " .. self.level .. "! Next level needs: " .. math.floor(self.exp) .. "/" .. (self.level * 400))
        end
        
        needsexp = self.level * 400
    end
end

function level:OnSave()
    return {
        exp = self.exp,
        level = self.level,
        elaina_tier = self.elaina_tier
    }
end

function level:OnLoad(data)
    if data then
        self.exp = data.exp or 0
        self.level = data.level or 1
        self.elaina_tier = data.elaina_tier or 1
        onlevel(self)
    end
end

return level