local assets = {
    Asset("ANIM", "anim/elena.zip"),
    Asset("ANIM", "anim/elena_broom.zip"),
    Asset("ANIM", "anim/swap_elena_broom.zip"),
    Asset("ATLAS", "images/map_icons/hoki.xml"),
    Asset("IMAGE", "images/map_icons/hoki.tex")
}

local prefabs = {
    "elena_broom",
    "light_projectile",
    "sparks_fx",
    "statue_transition"
}

-- Dialogue lines tailored to Hoki's canon personality
local IDLE_DIALOGUE = {
    "Only calling upon me when you need an extra pair of hands, Lady Elaina? Tee-hee, just teasing!",
    "I'm always so happy to walk by your side, Lady Elaina.",
    "The world is so big and wonderful when we travel together!",
    "Is there anything I can carry or sweep away for you?",
    "Please leave the heavy lifting to me, Lady Elaina!",
    "I'll make sure no dust lands on your hat, Lady Elaina!"
}

local COMBAT_DIALOGUE = {
    "Stay back, Lady Elaina! I will protect you!",
    "Leave this opponent to me!",
    "Shoo! Do not dare touch Lady Elaina!",
    "Magic bolt, go!"
}

local function GetLeader(inst)
    return inst.components.follower and inst.components.follower.leader
end

local function RevertToBroom(inst, reason)
    if inst.is_reverting then
        return
    end
    inst.is_reverting = true

    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("statue_transition") or SpawnPrefab("sparks_fx")
    if fx then
        fx.Transform:SetPosition(x, y + 0.5, z)
    end

    if inst.SoundEmitter then
        inst.SoundEmitter:PlaySound("dontstarve/common/staff")
    end

    local broom = SpawnPrefab("elena_broom")
    if broom then
        broom.Transform:SetPosition(x, y, z)
        -- Carry over weapon upgrade bonuses if any
        if inst.bonus_damage and broom.components.weapon then
            broom.components.weapon:SetDamage(broom.components.weapon.damage + inst.bonus_damage)
        end

        local leader = GetLeader(inst)
        if leader and leader.components.inventory and not leader.components.inventory:IsFull() then
            leader.components.inventory:GiveItem(broom)
        end
    end

    if inst.components.talker and reason then
        inst.components.talker:Say(reason)
    end

    inst:DoTaskInTime(0.5, function()
        inst:Remove()
    end)
end

local function SetMode(inst, mode_id)
    inst.hoki_mode = mode_id or "farm"

    if mode_id == "battle" then
        if inst.components.combat then
            inst.components.combat:SetRange(10, 12)
            inst.components.combat:SetAttackPeriod(1.6)
        end
    elseif mode_id == "passive" then
        if inst.components.combat then
            inst.components.combat:DropTarget()
            inst.components.combat:SetRange(6, 8)
            inst.components.combat:SetAttackPeriod(2.0)
        end
    else
        -- farm mode (balanced)
        if inst.components.combat then
            inst.components.combat:SetRange(8, 10)
            inst.components.combat:SetAttackPeriod(2.0)
        end
    end
end

local function RetargetFn(inst)
    if inst.hoki_mode == "passive" then
        -- Passive mode: do not seek out targets, hold fire
        return nil
    end

    local leader = GetLeader(inst)
    if not leader then
        return nil
    end

    -- Target whatever attacked Elaina or whatever Elaina is currently attacking
    local leader_target = leader.components.combat and leader.components.combat.target
    if leader_target and leader_target:IsValid() and not leader_target:HasTag("player") then
        return leader_target
    end

    local search_radius = (inst.hoki_mode == "battle") and 14 or 10
    local x, y, z = leader.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, search_radius, nil, {"player", "companion", "wall", "INLIMBO"})
    for _, ent in ipairs(ents) do
        if ent.components and ent.components.combat then
            if ent.components.combat.target == leader then
                return ent
            end
            -- In Battle Mode, aggressively intercept hostiles/monsters near Elaina
            if inst.hoki_mode == "battle" and (ent.components.combat.target == inst or ent:HasTag("hostile") or ent:HasTag("monster")) then
                if not ent:HasTag("prey") and not ent:HasTag("bird") then
                    return ent
                end
            end
        end
    end

    return nil
end

local function KeepTargetFn(inst, target)
    if inst.hoki_mode == "passive" then
        return false
    end
    local max_dist = (inst.hoki_mode == "battle") and 18 or 14
    return target and target:IsValid() and not target:HasTag("player") and inst:IsNear(target, max_dist)
end

local function OnAttacked(inst, data)
    if data and data.attacker and inst.components.combat then
        inst.components.combat:SuggestTarget(data.attacker)
    end
end

local function GetTotalPower(inst)
    local leader = GetLeader(inst)
    local leader_level = 10
    if leader and leader.components.level then
        leader_level = leader.components.level.level or 10
    elseif leader and leader.components.magicpoint then
        leader_level = leader.components.magicpoint.level or 10
    end
    local upgrade_score = ((inst.bonus_health or 0) / 10) + ((inst.bonus_damage or 0) / 2)
    return leader_level + upgrade_score
end

local function GetRemainingPowerMsg(inst)
    local total_power = GetTotalPower(inst)
    local stage = inst.hoki_stage or 1
    if stage == 1 then
        local needed = math.max(0, 25 - total_power)
        return string.format(" (Power: %d/25, %d more for Stage 2 Crimson form!)", math.floor(total_power), math.ceil(needed))
    elseif stage == 2 then
        local needed = math.max(0, 45 - total_power)
        return string.format(" (Power: %d/45, %d more for Stage 3 Starlight form!)", math.floor(total_power), math.ceil(needed))
    else
        return string.format(" (Power: %d - Maximum Stage achieved!)", math.floor(total_power))
    end
end

local function GetHokiProgressDescription(inst, viewer)
    local total_power = GetTotalPower(inst)
    local stage = inst.hoki_stage or 1
    local mode_labels = {
        farm = "Resource Farm",
        battle = "Battle Stance",
        passive = "Passive Guard"
    }
    local cur_mode = mode_labels[inst.hoki_mode or "farm"] or "Resource Farm"
    local desc = ""

    if stage == 1 then
        local needed = math.max(0, 25 - total_power)
        desc = string.format("Hoki [Stage 1: Apprentice] [Mode: %s] (Power: %d/25, needs %d more for Stage 2 Crimson form!)", 
            cur_mode, math.floor(total_power), math.ceil(needed))
    elseif stage == 2 then
        local needed = math.max(0, 45 - total_power)
        desc = string.format("Hoki [Stage 2: Crimson Witch] [Mode: %s] (Power: %d/45, needs %d more for Stage 3 Starlight form!)", 
            cur_mode, math.floor(total_power), math.ceil(needed))
    else
        desc = string.format("Hoki [Stage 3: Starlight Arch-Witch] [Mode: %s] (Power: %d - Max Stage! HP: %d, Atk: %d)", 
            cur_mode, math.floor(total_power), inst.components.health.maxhealth, inst.components.combat.defaultdamage)
    end

    -- Hoki also responds directly with her progress status
    inst:DoTaskInTime(0.6, function()
        if inst:IsValid() and inst.components.talker and not inst.sg:HasStateTag("busy") then
            if stage == 1 then
                local needed = math.max(0, 25 - total_power)
                inst.components.talker:Say(string.format("[%s] Need %d more power for Crimson form, Lady Elaina!", cur_mode, math.ceil(needed)))
            elseif stage == 2 then
                local needed = math.max(0, 45 - total_power)
                inst.components.talker:Say(string.format("[%s] Only %d more power until Starlight ascension, Lady Elaina!", cur_mode, math.ceil(needed)))
            else
                inst.components.talker:Say(string.format("[%s] Maximum power reached! Always by your side, Lady Elaina!", cur_mode))
            end
        end
    end)

    return desc
end

local function OnTrade(inst, giver, item)
    if not item then return end

    -- Check if fed sweets (Honey, Taffy, Waffles, Cake, Jam)
    local is_sweet = item:HasTag("sweet") or item.prefab == "taffy" or item.prefab == "honey" 
                    or item.prefab == "waffles" or item.prefab == "fruitmedley"
    
    -- Check if fed magic potion
    local is_potion = item.prefab == "potion_magic" or item.prefab == "potion_sourceliquid"

    if is_sweet then
        inst.bonus_health = (inst.bonus_health or 0) + 10
        local new_max = (TUNING.HOKI_HEALTH or 250) + inst.bonus_health
        inst.components.health:SetMaxHealth(new_max)
        inst.components.health:DoDelta(40)
        inst:UpdateStage()
        inst.components.talker:Say("So sweet and delicious! Thank you, Lady Elaina~" .. GetRemainingPowerMsg(inst))
        if inst.SoundEmitter then
            inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/emote")
        end
    elseif is_potion then
        inst.bonus_damage = (inst.bonus_damage or 0) + 2
        local new_damage = (TUNING.HOKI_DAMAGE or 34) + inst.bonus_damage
        inst.components.combat:SetDefaultDamage(new_damage)
        inst.components.health:SetPercent(1)
        inst:UpdateStage()
        inst.components.talker:Say("My magical energy is overflowing!" .. GetRemainingPowerMsg(inst))
        local fx = SpawnPrefab("sparks_fx")
        if fx then
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
    else
        inst.components.talker:Say("Thank you, Lady Elaina! I will treasure this.")
    end
end

local function UpdateStage(inst, silent)
    local leader = GetLeader(inst)
    local leader_level = 10
    if leader and leader.components.level then
        leader_level = leader.components.level.level or 10
    elseif leader and leader.components.magicpoint then
        leader_level = leader.components.magicpoint.level or 10
    end

    local upgrade_score = ((inst.bonus_health or 0) / 10) + ((inst.bonus_damage or 0) / 2)
    local total_power = leader_level + upgrade_score

    local old_stage = inst.hoki_stage or 1
    local new_stage = 1

    if total_power >= 45 then
        new_stage = 3 -- Starlight Arch-Witch Form (Light Novel Volume 16+ Master Form)
    elseif total_power >= 25 then
        new_stage = 2 -- Crimson Witch Form (Light Novel Volume 16 Advanced Form)
    else
        new_stage = 1 -- Apprentice Form (Light Novel Volume 3 & Anime Base Form)
    end

    inst.hoki_stage = new_stage

    if new_stage == 1 then
        -- Volume 3 & Anime Style: Soft pastel pink hair, standard scale
        inst.AnimState:SetMultColour(1.0, 0.85, 0.92, 1.0)
        inst.Transform:SetScale(1.0, 1.0, 1.0)
        if inst.Light then
            inst.Light:Enable(false)
        end
    elseif new_stage == 2 then
        -- Volume 16 Style: Deep crimson & rose hue, gentle glowing rose light, 1.06 scale
        inst.AnimState:SetMultColour(1.0, 0.78, 0.85, 1.0)
        inst.Transform:SetScale(1.06, 1.06, 1.06)
        if inst.Light then
            inst.Light:SetRadius(2.5)
            inst.Light:SetIntensity(0.7)
            inst.Light:SetFalloff(0.6)
            inst.Light:SetColour(255/255, 175/255, 200/255)
            inst.Light:Enable(true)
        end
    elseif new_stage == 3 then
        -- Celestial Master Form: Starlight aura, luminous radiance, 1.12 scale
        inst.AnimState:SetMultColour(1.0, 0.92, 0.98, 1.0)
        inst.Transform:SetScale(1.12, 1.12, 1.12)
        if inst.Light then
            inst.Light:SetRadius(3.8)
            inst.Light:SetIntensity(0.85)
            inst.Light:SetFalloff(0.5)
            inst.Light:SetColour(255/255, 220/255, 240/255)
            inst.Light:Enable(true)
        end
    end

    -- Trigger ascension effects and celebratory dialogue when advancing
    if not silent and new_stage > old_stage then
        local fx = SpawnPrefab("statue_transition") or SpawnPrefab("sparks_fx")
        if fx then
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
        if inst.SoundEmitter then
            inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/level_up")
        end
        if new_stage == 2 then
            inst.components.talker:Say("Lady Elaina, my magical resonance has deepened! Look at my crimson-gold aura!")
        elseif new_stage == 3 then
            inst.components.talker:Say("Lady Elaina, the stars themselves bless our bond! I will protect you anywhere!")
        end
    end
end

local function ShouldAcceptItem(inst, giver, item)
    if item and (item:HasTag("sweet") or item.prefab == "taffy" or item.prefab == "honey" 
        or item.prefab == "waffles" or item.prefab == "potion_magic" or item.prefab == "potion_sourceliquid") then
        return true
    end
    return false
end

local function AmbientDialogueTask(inst)
    local leader = GetLeader(inst)
    if not leader or inst.sg:HasStateTag("busy") or inst.components.combat.target ~= nil then
        return
    end

    -- Check for form evolution periodically
    inst:UpdateStage()

    -- Health/Sanity checks for Elaina
    if leader.components.sanity and leader.components.sanity.current < 40 then
        inst.components.talker:Say("Lady Elaina, your mind seems weary... please take a short rest!")
        return
    elseif leader.components.hunger and leader.components.hunger.current < 45 then
        inst.components.talker:Say("Your tummy is rumbling, Lady Elaina! Shall we look for some sweets?")
        return
    end

    -- Random cute dialogue
    local line = IDLE_DIALOGUE[math.random(#IDLE_DIALOGUE)]
    inst.components.talker:Say(line)
end

local function OnSave(inst, data)
    data.bonus_health = inst.bonus_health
    data.bonus_damage = inst.bonus_damage
    data.hoki_stage = inst.hoki_stage
    data.hoki_mode = inst.hoki_mode
end

local function OnLoad(inst, data)
    if data then
        inst.bonus_health = data.bonus_health or 0
        inst.bonus_damage = data.bonus_damage or 0
        inst.hoki_stage = data.hoki_stage or 1
        inst:SetMode(data.hoki_mode or "farm")
        inst.components.health:SetMaxHealth((TUNING.HOKI_HEALTH or 250) + inst.bonus_health)
        inst.components.combat:SetDefaultDamage((TUNING.HOKI_DAMAGE or 34) + inst.bonus_damage)
        inst:UpdateStage(true)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetIcon("hoki.tex")
    inst.MiniMapEntity:SetPriority(5)

    inst.DynamicShadow:SetSize(1.5, 0.6)
    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 50, .5)

    -- Appearance: Based on Elena build with vibrant pastel pink tint to reflect anime/novel hair
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("elena")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetMultColour(1.0, 0.85, 0.92, 1.0)

    -- Carry broom symbol in hand
    inst.AnimState:OverrideSymbol("swap_object", "swap_elena_broom", "swap_elena_broom")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")

    -- Tags
    inst:AddTag("companion")
    inst:AddTag("character")
    inst:AddTag("hoki")
    inst:AddTag("amphibious")
    inst:AddTag("noauradamage")
    inst:AddTag("notraptrigger")

    -- Health
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.HOKI_HEALTH or 250)
    inst.components.health:StartRegen(1, 3)

    -- Combat (ranged magic projectile attacks)
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.HOKI_DAMAGE or 34)
    inst.components.combat:SetRange(8, 10)
    inst.components.combat:SetAttackPeriod(2.0)
    inst.components.combat:SetRetargetFunction(1.5, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    -- Locomotor
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 4.5
    inst.components.locomotor.runspeed = 6.8

    -- Follower
    inst:AddComponent("follower")
    inst.components.follower:KeepLeaderOnAttacked()

    -- Sanity Aura for Elaina
    local aura_per_minute = TUNING.HOKI_SANITY_AURA or 5.0
    if aura_per_minute > 0 then
        inst:AddComponent("sanityaura")
        inst.components.sanityaura.aura = aura_per_minute / 60
    end

    -- Talker with pastel pink text
    inst:AddComponent("talker")
    inst.components.talker.colour = Vector3(255/255, 175/255, 205/255)
    inst.components.talker.offset = Vector3(0, -500, 0)

    -- Trader (accepts sweets & potions for upgrades)
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnTrade

    inst.name = "Hoki"
    inst:AddComponent("inspectable")
    inst.components.inspectable.description = GetHokiProgressDescription

    -- Brain and StateGraph
    inst:SetBrain(require("brains/hokibrain"))
    inst:SetStateGraph("SGhoki")

    -- Events
    inst:ListenForEvent("attacked", OnAttacked)

    -- When defeated, revert back to broom instead of permanent death
    inst.components.health.nofadeout = true
    inst:ListenForEvent("death", function(inst)
        RevertToBroom(inst, "I'm exhausted... resting in broom form, Lady Elaina...")
    end)

    -- Periodic ambient dialogue
    inst:DoPeriodicTask(40, AmbientDialogueTask)

    -- Welcome greeting on spawn
    inst:DoTaskInTime(0.5, function()
        if inst.components.talker then
            inst.components.talker:Say("Reporting for duty! What can I do for you, Lady Elaina?")
        end
    end)

    inst.RevertToBroom = RevertToBroom
    inst.UpdateStage = UpdateStage
    inst.SetMode = SetMode
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("common/characters/hoki", fn, assets, prefabs)
