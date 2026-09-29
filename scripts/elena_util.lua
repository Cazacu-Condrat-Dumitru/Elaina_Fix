-- Shared helpers for Elaina's prefabs and components.
-- Don't Starve runs with strict globals: never read a global that may not exist
-- (DST-only names, DLC-only helpers) without rawget, or the game crashes.

local U = {}

-- Normalized additive modifier for Wendy's damage penalty.
-- Vanilla/RoG tuning stores it as 0.75 (multiplier), SW/Hamlet as -0.25 (additive).
function U.WendyDamageModifier()
    local v = TUNING.WENDY_DAMAGE_MULT or 0.75
    if v >= 0.5 then
        return v - 1
    end
    return v
end

-- Named, additive damage bonuses (e.g. 0.25 = +25%). Works with both the
-- SW/Hamlet modifier API and the older plain damagemultiplier field.
function U.SetDamageBonus(inst, key, amount)
    local combat = inst and inst.components and inst.components.combat
    if not combat then return end

    amount = amount or 0
    inst.elena_damage_bonuses = inst.elena_damage_bonuses or {}
    local old = inst.elena_damage_bonuses[key] or 0
    inst.elena_damage_bonuses[key] = (amount ~= 0) and amount or nil

    if combat.AddDamageModifier then
        if amount ~= 0 then
            combat:AddDamageModifier(key, amount)
        elseif combat.RemoveDamageModifier then
            combat:RemoveDamageModifier(key)
        end
    else
        -- Apply only the change, so other multipliers on this character stay intact
        combat.damagemultiplier = math.max(0.1, (combat.damagemultiplier or 1) - old + amount)
    end
end

-- Named speed multipliers (1.6 = +60%).
function U.SetSpeedMult(inst, key, mult)
    local loco = inst and inst.components and inst.components.locomotor
    if not loco then return end

    local active = mult and mult ~= 1.0

    if loco.AddSpeedModifier_Mult then
        -- SW/Hamlet: multiplier modifiers are summed, so store the delta
        if active then
            loco:AddSpeedModifier_Mult(key, mult - 1.0)
        else
            loco:RemoveSpeedModifier_Mult(key)
        end
        return
    end

    inst.elena_speed_mults = inst.elena_speed_mults or {}
    inst.elena_speed_mults[key] = active and mult or nil
    local total = 1.0
    for _, m in pairs(inst.elena_speed_mults) do
        total = total * m
    end
    loco.bonusspeed = (TUNING.WILSON_RUN_SPEED or 6) * (total - 1.0)
end

function U.PlaySound(inst, path)
    if inst and inst.SoundEmitter then
        inst.SoundEmitter:PlaySound(path)
    end
end

function U.SpawnFxAt(prefab, x, y, z)
    local fx = SpawnPrefab(prefab)
    if fx then
        fx.Transform:SetPosition(x, y, z)
    end
    return fx
end

function U.IsInInterior(inst)
    return inst.GetIsInInterior ~= nil and inst:GetIsInInterior() == true
end

-- Is this point solid land a creature can stand on?
function U.IsLandAt(x, y, z)
    local world = GetWorld()
    local map = world and world.Map
    if not map then return false end
    local tile = map:GetTileAtPoint(x, y, z)
    if tile == nil or tile == GROUND.IMPASSABLE or (GROUND.INVALID ~= nil and tile == GROUND.INVALID) then
        return false
    end
    if map.IsWater and map:IsWater(tile) then
        return false
    end
    return true
end

-- Something that is actually a threat to `player` (never neutral wildlife,
-- the player's own followers, walls or other players).
function U.IsHostileTo(ent, player)
    if not (ent and ent:IsValid() and ent ~= player) then return false end
    if not (ent.components.combat and ent.components.health) or ent.components.health:IsDead() then
        return false
    end
    if ent:HasTag("player") or ent:HasTag("companion") or ent:HasTag("wall") or ent:HasTag("INLIMBO") then
        return false
    end
    local follower = ent.components.follower
    if follower and follower.leader == player then
        return false
    end
    if ent.components.combat.target == player then
        return true
    end
    return ent:HasTag("monster") or ent:HasTag("hostile")
end

-- Heal/restore effect spread over time, safe for eaters without sanity.
function U.StartRegen(eater, key, period, ticks, health, sanity)
    if not (eater and eater:IsValid() and eater.components.health) then return end
    if eater[key] then
        eater[key]:Cancel()
    end
    local count = 0
    eater[key] = eater:DoPeriodicTask(period, function()
        count = count + 1
        if eater.components.health and not eater.components.health:IsDead() then
            eater.components.health:DoDelta(health)
            if sanity ~= 0 and eater.components.sanity then
                eater.components.sanity:DoDelta(sanity)
            end
        end
        if count >= ticks and eater[key] then
            eater[key]:Cancel()
            eater[key] = nil
        end
    end)
end

-- Shipwrecked: items without a floatable component sink when dropped in the
-- sea. The mod's items only have an "idle" animation, so reuse it on water.
-- MakeInventoryFloatable does not exist without the SW/Hamlet scripts.
function U.MakeFloatable(inst)
    local make = rawget(_G, "MakeInventoryFloatable")
    if make then
        make(inst, "idle", "idle")
    end
end

return U
