local assets = {Asset("ANIM", "anim/pumpkin_lantern.zip"), Asset("ANIM", "anim/swap_pumpkin_lantern.zip"),
                Asset("ATLAS", "images/inventoryimages/pumpkin_light.xml"),
                Asset("IMAGE", "images/inventoryimages/pumpkin_light.tex")}

local prefabs = {"fireflies"}

local INTENSITY = .8

local function flicker_stop(inst)
    if inst.flickertask then
        inst.flickertask:Cancel()
        inst.flickertask = nil
    end
end

local function flicker_update(inst)
    local time = GetTime() * 30
    local flicker = (math.sin(time) + math.sin(time + 2) + math.sin(time + 0.7777)) / 2.0 -- range = [-1 , 1]
    flicker = (1.0 + flicker) / 2.0 -- range = 0:1
    inst.Light:SetRadius(3.5 + 0.1 * flicker)
    inst.flickertask = inst:DoTaskInTime(0.1, function()
        flicker_update(inst)
    end)
end

local function fade_in(inst)
    inst.components.fader:StopAll()
    inst.AnimState:PlayAnimation("idle_night_pre")
    inst.AnimState:PushAnimation("idle_night_loop", true)
    inst.Light:Enable(true)
    flicker_stop(inst)
    flicker_update(inst)
    inst.components.fader:Fade(0, INTENSITY, 5 * FRAMES, function(v)
        inst.Light:SetIntensity(v)
    end)
end

local function fade_out(inst)
    inst.components.fader:StopAll()
    inst.AnimState:PlayAnimation("idle_night_pst")
    inst.AnimState:PushAnimation("idle_day", false)
    flicker_stop(inst)
    inst.components.fader:Fade(INTENSITY, 0, 5 * FRAMES, function(v)
        inst.Light:SetIntensity(v)
    end, function()
        inst.Light:Enable(false)
    end)
end


local function fade_in_on(inst)
    inst.components.fader:StopAll()
    inst.Light:Enable(true)
    flicker_stop(inst)
    flicker_update(inst)
    inst.components.fader:Fade(0, INTENSITY, 5 * FRAMES, function(v)
        inst.Light:SetIntensity(v)
    end)
end

local function fade_out_on(inst)
    inst.components.fader:StopAll()
    flicker_stop(inst)
    inst.components.fader:Fade(INTENSITY, 0, 5 * FRAMES, function(v)
        inst.Light:SetIntensity(v)
    end, function()
        inst.Light:Enable(false)
    end)
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_pumpkin_lantern", "swap_pumpkin_lantern")
    -- owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    inst.Light:SetFalloff(.5)
    inst.Light:SetIntensity(INTENSITY)
    inst.Light:SetRadius(3.5)
    inst.Light:Enable(true)
    inst.Light:SetColour(200 / 255, 100 / 255, 170 / 255)

    -- inst:ListenForEvent("daytime", function()
    --     -- if not inst.components.inventoryitem.owner and not inst.components.health:IsDead() and not inst:HasTag("rotten") then
    --     if not inst.components.inventoryitem.owner then
    --         inst:DoTaskInTime(2 + math.random() * 1, function()
    --             fade_out_on(inst)
    --         end)
    --     end
    -- end, GetWorld())

    -- inst:ListenForEvent("dusktime", function()
    --     -- if not inst.components.inventoryitem.owner and not inst.components.health:IsDead() and not inst:HasTag("rotten") then
    --     if not inst.components.inventoryitem.owner then
    --         inst:DoTaskInTime(2 + math.random() * 1, function()
    --             if not inst.components.inventoryitem.owner then
    --                 fade_in_on(inst)
    --             end
    --         end)
    --     end
    -- end, GetWorld())
    
    -- inst.AnimState:PlayAnimation("idle")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

end

local function fn(Sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst:AddTag("veggie")

    local isday = GetClock():IsDay()
    inst.entity:AddPhysics()
    MakeInventoryPhysics(inst)

    local light = inst.entity:AddLight()
    light:SetFalloff(.5)
    light:SetIntensity(INTENSITY)
    light:SetRadius(3.5)
    light:Enable(false)
    light:SetColour(200 / 255, 100 / 255, 170 / 255)

    inst.AnimState:SetBank("pumpkin")
    inst.AnimState:SetBuild("pumpkin_lantern")
    inst.AnimState:PlayAnimation("idle_day")

    inst:AddComponent("fader")

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true

    inst.components.inventoryitem.atlasname = "images/inventoryimages/pumpkin_light.xml"
    inst.components.inventoryitem.imagename = "pumpkin_light"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst.components.inventoryitem:SetOnDroppedFn(function(inst)
        -- inst.components.perishable:StartPerishing()
        if not GetClock():IsDay() then
            fade_in(inst)
        end
    end)
    inst.components.inventoryitem:SetOnPutInInventoryFn(function(inst)
        -- inst.components.perishable:StopPerishing()
        fade_out(inst)
    end)

    inst:ListenForEvent("daytime", function()
        -- if not inst.components.inventoryitem.owner and not inst.components.health:IsDead() and not inst:HasTag("rotten") then
        if not inst.components.inventoryitem.owner then
            inst:DoTaskInTime(2 + math.random() * 1, function()
                fade_out(inst)
            end)
        end
    end, GetWorld())

    inst:ListenForEvent("dusktime", function()
        -- if not inst.components.inventoryitem.owner and not inst.components.health:IsDead() and not inst:HasTag("rotten") then
        if not inst.components.inventoryitem.owner then
            inst:DoTaskInTime(2 + math.random() * 1, function()
                if not inst.components.inventoryitem.owner then
                    fade_in(inst)
                end
            end)
        end
    end, GetWorld())

    if not inst.components.inventoryitem.owner and not isday then
        fade_in(inst)
    end
    return inst
end

return Prefab("common/objects/pumpkin_light", fn, assets, prefabs)

