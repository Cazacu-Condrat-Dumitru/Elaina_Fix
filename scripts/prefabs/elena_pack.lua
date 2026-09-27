local assets = {
    Asset("ANIM", "anim/backpack.zip"),
    Asset("ANIM", "anim/swap_backpack.zip"),
}

local function onequip(inst, owner)
    if not (owner and owner:IsValid()) then return end

    owner.AnimState:OverrideSymbol("swap_body", "swap_backpack", "backpack")
    owner.AnimState:OverrideSymbol("swap_body", "swap_backpack", "swap_body")

    if owner.components.inventory then
        owner.components.inventory:SetOverflow(inst)
    end

    if inst.components.container then
        inst.components.container:Open(owner)
    end

    -- Enable hands-free starlight illumination while equipped
    if inst.Light then
        inst.Light:Enable(true)
    end
end

local function onunequip(inst, owner)
    if owner and owner:IsValid() then
        owner.AnimState:ClearOverrideSymbol("swap_body")
        owner.AnimState:ClearOverrideSymbol("backpack")

        if owner.components.inventory then
            owner.components.inventory:SetOverflow(nil)
        end

        if inst.components.container then
            inst.components.container:Close(owner)
        end
    end

    -- Turn off light when removed or dropped
    if inst.Light then
        inst.Light:Enable(false)
    end
end

local function onopen(inst)
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/backpack_open", "open")
    end
end

local function onclose(inst)
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/backpack_close", "open")
    end
end

local function get_container_layout()
    local slots_count = (TUNING and TUNING.ELENA_PACK_SLOTS) or 14
    local slotpos = {}

    if slots_count == 8 then
        for y = 0, 3 do
            table.insert(slotpos, Vector3(-162, -y * 75 + 114, 0))
            table.insert(slotpos, Vector3(-162 + 75, -y * 75 + 114, 0))
        end
        return {
            slotpos = slotpos,
            animbank = "ui_backpack_2x4",
            animbuild = "ui_backpack_2x4",
            pos = Vector3(-5, -50, 0),
        }
    elseif slots_count == 10 then
        for y = 0, 4 do
            table.insert(slotpos, Vector3(-162, -y * 75 + 114, 0))
            table.insert(slotpos, Vector3(-162 + 75, -y * 75 + 114, 0))
        end
        return {
            slotpos = slotpos,
            animbank = "ui_krampusbag_2x5",
            animbuild = "ui_krampusbag_2x5",
            pos = Vector3(-5, -70, 0),
        }
    else
        -- Default: 14 slots (matching Krampus Sack layout)
        for y = 0, 6 do
            table.insert(slotpos, Vector3(-162, -y * 75 + 240, 0))
            table.insert(slotpos, Vector3(-162 + 75, -y * 75 + 240, 0))
        end
        return {
            slotpos = slotpos,
            animbank = "ui_krampusbag_2x8",
            animbuild = "ui_krampusbag_2x8",
            pos = Vector3(-5, -75, 0),
        }
    end
end

local function fn(Sim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    -- Starlight crystal illumination
    local light = inst.entity:AddLight()
    light:Enable(false)
    light:SetRadius(2.5)
    light:SetFalloff(0.7)
    light:SetIntensity(0.75)
    light:SetColour(220 / 255, 205 / 255, 255 / 255)

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("backpack1")
    inst.AnimState:SetBuild("swap_backpack")
    inst.AnimState:PlayAnimation("anim")

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("backpack.png")

    -- Klei native tags: fridge halves food spoilage rate
    inst:AddTag("fridge")
    inst:AddTag("backpack")
    inst:AddTag("elena_pack")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.foleysound = "dontstarve/movement/foley/backpack"

    -- Magical Protective Ward: 75% damage absorption
    inst:AddComponent("armor")
    inst.components.armor:InitCondition(1200, 0.75)

    -- Weather Insulation: Protects against freezing in winter and heat in summer
    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(120)
    if inst.components.insulator.SetSummer then
        inst.components.insulator:SetSummer(120)
    end

    -- Water Resistance: 50% waterproof
    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0.5)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    local layout = get_container_layout()

    inst:AddComponent("container")
    inst.components.container:SetNumSlots(#layout.slotpos)
    inst.components.container.widgetslotpos = layout.slotpos
    inst.components.container.widgetanimbank = layout.animbank
    inst.components.container.widgetanimbuild = layout.animbuild
    inst.components.container.widgetpos = layout.pos
    inst.components.container.side_widget = true
    inst.components.container.type = "pack"
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose

    return inst
end

return Prefab("common/inventory/elena_pack", fn, assets)
