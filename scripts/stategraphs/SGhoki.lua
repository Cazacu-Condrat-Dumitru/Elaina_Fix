require("stategraphs/commonstates")

local actionhandlers = {}

local events = {
    CommonHandlers.OnLocomote(true, false),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnAttack(),
}

local states = {
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)
        end,
    },

    State{
        name = "run_start",
        tags = {"moving", "running", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_pre")
        end,
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("run")
            end),
        },
    },

    State{
        name = "run",
        tags = {"moving", "running", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_loop", true)
        end,
        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,
    },

    State{
        name = "run_stop",
        tags = {"canrotate", "idle"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("run_pst")
        end,
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "notalking", "abouttoattack", "busy"},
        onenter = function(inst)
            inst.sg.statemem.target = inst.components.combat.target
            inst.components.combat:StartAttack()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
            inst.SoundEmitter:PlaySound("dontstarve/common/staff")

            if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                inst:FacePoint(Point(inst.sg.statemem.target.Transform:GetWorldPosition()))
            end
        end,

        timeline = {
            TimeEvent(8 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("abouttoattack")
                local target = inst.sg.statemem.target
                if target and target:IsValid() and not (target.components.health and target.components.health:IsDead()) then
                    local proj = SpawnPrefab("light_projectile")
                    if proj then
                        local x, y, z = inst.Transform:GetWorldPosition()
                        proj.Transform:SetPosition(x, 1.2, z)
                        if proj.components.weapon then
                            proj.components.weapon:SetDamage(inst.components.combat.defaultdamage or 34)
                        end
                        proj.components.projectile:Throw(inst, target)
                    end
                end
            end),
            TimeEvent(12 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
            TimeEvent(16 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("attack")
            end),
        },

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "hit",
        tags = {"busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/hurt")
        end,
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/death_voice")
        end,
    },

    State{
        name = "collect",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("pickup")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
        end,
        timeline = {
            TimeEvent(6 * FRAMES, function(inst)
                local target = inst.collect_target
                local leader = inst.components.follower and inst.components.follower.leader
                if target and target:IsValid() and not target:IsInLimbo() and leader and leader:IsValid() and leader.components.inventory then
                    local can_accept = not leader.components.inventory:IsFull()
                    if not can_accept and target.components.stackable and not target.components.stackable:IsFull() and leader.components.inventory:Has(target.prefab, 1) then
                        can_accept = true
                    end

                    if can_accept then
                        leader.components.inventory:GiveItem(target, nil, Vector3(TheSim:GetScreenPos(target.Transform:GetWorldPosition())))
                        if math.random() < 0.20 and (not inst.last_pickup_talk or GetTime() - inst.last_pickup_talk > 10) then
                            inst.last_pickup_talk = GetTime()
                            local quotes = {
                                "Gathered this for you, Lady Elaina!",
                                "Swept right into your bag!",
                                "Here you go, Lady Elaina~",
                                "Leave the tidying up to me!",
                                "Found something useful!"
                            }
                            inst.components.talker:Say(quotes[math.random(#quotes)])
                        end
                    else
                        if inst.components.talker and (not inst.last_full_warn or GetTime() - inst.last_full_warn > 15) then
                            inst.last_full_warn = GetTime()
                            inst.components.talker:Say("Lady Elaina, your inventory is full!")
                        end
                    end
                end
                inst.collect_target = nil
            end),
        },
        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
}

return StateGraph("hoki", states, events, "idle", actionhandlers)
