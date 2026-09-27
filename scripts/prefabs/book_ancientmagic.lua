local assets = {
    Asset("ANIM", "anim/book_j.zip"), 
    Asset("ATLAS", "images/inventoryimages/book_ancientmagic.xml"),
    Asset("IMAGE", "images/inventoryimages/book_ancientmagic.tex")
}

local prefabs = {
    "hoki",
    "elena_broom",
    "sparks_fx",
    "statue_transition"
}

local function onread(inst, reader)
    if not (reader and reader:IsValid()) then
        return false
    end

    -- If reader is Elaina with the Grimoire command system, cycle command mode / awaken / rest
    if reader.CycleHokiMode then
        return reader:CycleHokiMode()
    end

    local x, y, z = reader.Transform:GetWorldPosition()

    -- Check if Hoki is currently active nearby -> Revert to Broom form
    local hoki = FindEntity(reader, 25, function(ent)
        return ent:HasTag("hoki") and ent.components.follower and ent.components.follower.leader == reader
    end)

    if hoki then
        if hoki.RevertToBroom then
            hoki:RevertToBroom("Returning to broom form, Lady Elaina~")
        else
            hoki:Remove()
            local broom = SpawnPrefab("elena_broom")
            if broom then
                reader.components.inventory:GiveItem(broom)
            end
        end
        if reader.components.talker then
            reader.components.talker:Say("Rest well, Hoki.")
        end
        return true
    end

    -- Look for the broom in inventory or equipped in hands
    local broom_item = nil
    if reader.components.inventory then
        local hand_item = reader.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if hand_item and (hand_item.prefab == "elena_broom" or hand_item:HasTag("broom") or hand_item:HasTag("elena_broom")) then
            broom_item = hand_item
        else
            for _, item in pairs(reader.components.inventory.itemslots) do
                if item and (item.prefab == "elena_broom" or item:HasTag("broom") or item:HasTag("elena_broom")) then
                    broom_item = item
                    break
                end
            end
        end
    end

    if not broom_item then
        -- Player has neither active Hoki nor broom in inventory: summon Hoki directly!
        local hoki_entity = SpawnPrefab("hoki")
        if hoki_entity then
            local theta = math.random() * 2 * PI
            local offset = FindWalkableOffset(reader:GetPosition(), theta, 2, 8, true) or Vector3(1, 0, 0)
            hoki_entity.Transform:SetPosition(x + offset.x, 0, z + offset.z)
            if hoki_entity.components.follower then
                hoki_entity.components.follower:SetLeader(reader)
            end
        end

        local fx = SpawnPrefab("statue_transition") or SpawnPrefab("sparks_fx")
        if fx then
            fx.Transform:SetPosition(x, y + 0.5, z)
        end
        if inst.SoundEmitter then
            inst.SoundEmitter:PlaySound("dontstarve/common/staff")
        end
        if reader.components.talker then
            reader.components.talker:Say("Awaken, Hoki!")
        end
        return true
    end

    -- Check sanity cost
    local cost = TUNING.ELENA_BROOM_COMPANION_COST or 25
    if cost > 0 and reader.components.sanity and reader.components.sanity.current < cost then
        if reader.components.talker then
            reader.components.talker:Say("I am too mentally drained to awaken Hoki right now.")
        end
        return false
    end

    -- Deduct sanity cost
    if cost > 0 and reader.components.sanity then
        reader.components.sanity:DoDelta(-cost)
    end

    -- Remove the broom item from owner
    if broom_item.components.inventoryitem and broom_item.components.inventoryitem.owner then
        broom_item.components.inventoryitem:RemoveFromOwner(true)
    end
    broom_item:Remove()

    -- Spawn Hoki companion in human form
    local hoki_entity = SpawnPrefab("hoki")
    if hoki_entity then
        local theta = math.random() * 2 * PI
        local offset = FindWalkableOffset(reader:GetPosition(), theta, 2, 8, true) or Vector3(1, 0, 0)
        hoki_entity.Transform:SetPosition(x + offset.x, 0, z + offset.z)
        if hoki_entity.components.follower then
            hoki_entity.components.follower:SetLeader(reader)
        end
    end

    -- Magical effects and sound
    local fx = SpawnPrefab("statue_transition") or SpawnPrefab("sparks_fx")
    if fx then
        fx.Transform:SetPosition(x, y + 0.5, z)
    end
    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve/common/staff")
    end

    if reader.components.talker then
        reader.components.talker:Say("Awaken, Hoki!")
    end

    return true
end

local function fn(sim)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    local anim = inst.AnimState
    anim:SetBank("book_maxwell")
    anim:SetBuild("book_j")
    anim:PlayAnimation("idle")

    MakeInventoryPhysics(inst)
    if IsDLCEnabled(CAPY_DLC) then
        MakeInventoryFloatable(inst, "idle_water", "idle")
    end
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/book_ancientmagic.xml"

    inst:AddComponent("inspectable")

    -- Book component allows reading the awakening incantation
    inst:AddComponent("book")
    inst.components.book.onread = onread

    MakeSmallPropagator(inst)

    return inst
end

return Prefab("common/book_ancientmagic", fn, assets, prefabs)
