local U = require "elena_util"

local assets = {
    Asset("ANIM", "anim/book_j.zip"),
    Asset("ATLAS", "images/inventoryimages/book_ancientmagic.xml"),
    Asset("IMAGE", "images/inventoryimages/book_ancientmagic.tex")
}

local prefabs = {"statue_transition", "statue_transition_2"}

-- Reading the grimoire calms the mind (+40 sanity, as in the original mod),
-- but the pages need a full day to recharge.
local SANITY_GAIN = 40
local COOLDOWN = TUNING.TOTAL_DAY_TIME or 480

local function GetRemaining(inst)
    if inst.ready_at then
        return math.max(0, inst.ready_at - GetTime())
    end
    return 0
end

local function StartCooldown(inst, time)
    inst.ready_at = GetTime() + time
end

local function onread(inst, reader)
    if not (reader and reader:IsValid()) then
        return false
    end

    local remaining = GetRemaining(inst)
    if remaining > 0 then
        if reader.components.talker then
            reader.components.talker:Say("The runes are still dim. (" .. math.ceil(remaining / 60) .. " min)")
        end
        return true
    end

    if reader.components.sanity then
        reader.components.sanity:DoDelta(SANITY_GAIN)
    end

    local x, y, z = reader.Transform:GetWorldPosition()
    for _, fxname in ipairs(prefabs) do
        local fx = SpawnPrefab(fxname)
        if fx then
            fx.Transform:SetPosition(x, y, z)
        end
    end
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_appear")
    end

    StartCooldown(inst, COOLDOWN)
    return true
end

local function describe(inst, viewer)
    local remaining = GetRemaining(inst)
    if remaining > 0 then
        return "Its runes are recharging. About " .. math.ceil(remaining / 60) .. " more minutes."
    end
    return "Its runes are glowing. Reading it would clear my mind."
end

local function onsave(inst, data)
    local remaining = GetRemaining(inst)
    if remaining > 0 then
        data.cooldown = remaining
    end
end

local function onload(inst, data)
    if data and data.cooldown and data.cooldown > 0 then
        StartCooldown(inst, data.cooldown)
    end
end

local function fn(sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("book_maxwell")
    inst.AnimState:SetBuild("book_j")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    U.MakeFloatable(inst)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/book_ancientmagic.xml"

    inst:AddComponent("inspectable")
    inst.components.inspectable.description = describe

    inst:AddComponent("book")
    inst.components.book.onread = onread

    MakeSmallPropagator(inst)

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("common/book_ancientmagic", fn, assets, prefabs)
