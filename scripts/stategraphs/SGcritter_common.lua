
SGCritterEvents = {}
SGCritterStates = {}

local seg_time = 30
TUNING.CRITTER_EMOTE_DELAY = seg_time * 0.5 
--------------------------------------------------------------------------
--SGCritterEvents.OnGoToSleep = function()
--    return EventHandler("gotosleep", function(inst) inst.sg:GoToState(inst.sg:HasStateTag("sleeping") and "sleeping" or "sleep") end)
--end

local function onsleepex(inst)
    inst.sg.mem.sleeping = true
    if not (inst.sg:HasStateTag("nosleep") or inst.sg:HasStateTag("sleeping") or
            (inst.components.health ~= nil and inst.components.health:IsDead())) then
        inst.sg:GoToState("sleep")
    end
end

local function onwakeex(inst)
    inst.sg.mem.sleeping = false
    if inst.sg:HasStateTag("sleeping") and not inst.sg:HasStateTag("nowake") and
        not (inst.components.health ~= nil and inst.components.health:IsDead()) then
        inst.sg.statemem.continuesleeping = true
        inst.sg:GoToState("wake")
    end
end

SGCritterEvents.OnSleepEx = function()
    return EventHandler("gotosleep", onsleepex)
end

SGCritterEvents.OnWakeEx = function()
    return EventHandler("onwakeup", onwakeex)
end

SGCritterEvents.OnEat = function()
    return EventHandler("oneat", function(inst) inst.sg:GoToState("eat") end)
end

--------------------------------------------------------------------------
SGCritterStates.AddIdle = function(states, num_emotes, timeline)
    table.insert(states, State
    {
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst, pushanim)
			if inst.components.locomotor ~= nil then
				inst.components.locomotor:StopMoving()
			end

			local r = math.random()
            if r <= inst:GetPeepChance() then
                inst.sg:GoToState("hungry")
            elseif r <= 0.1 and (GetTime() - (inst.sg.mem.prevemotetime or 0) > TUNING.CRITTER_EMOTE_DELAY) then
                inst.sg:GoToState("emote"..math.random(num_emotes))
            else
				inst.AnimState:PlayAnimation("idle_loop")
            end
        end,
        
        timeline = timeline,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    })
end

--------------------------------------------------------------------------
SGCritterStates.AddEat = function(states, timeline, fns)
    table.insert(states, State
    {
        name = "eat",
        tags = { "busy" },

        onenter = function(inst, pushanim)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end

            inst.AnimState:PlayAnimation("eat_pre")
            inst.AnimState:PushAnimation("eat_loop", false)
            inst.AnimState:PushAnimation("eat_pst", false)

            if fns ~= nil and fns.onenter ~= nil then
                fns.onenter(inst)
            end
        end,

		timeline = timeline,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
					local dest_state = inst.sg.mem.queuethankyou and "emote1" or "idle"
					inst.sg.mem.queuethankyou = nil
                    inst.sg:GoToState(dest_state)
                end
            end),
        },
		onexit = fns ~= nil and fns.onexit or nil,
    })
end

--------------------------------------------------------------------------
SGCritterStates.AddHungry = function(states, timeline)
    table.insert(states, State
    {
        name = "hungry",
        tags = {"idle"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("distress")
        end,
       
        timeline = timeline,

        events=
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    })
end

--------------------------------------------------------------------------
SGCritterStates.AddNuzzle = function(states, actionhandlers, timeline,fns)
    table.insert(actionhandlers, ActionHandler(ACTIONS.NUZZLE, "nuzzle"))

    table.insert(states, State
    {
		name = "nuzzle",
		tags = {"busy"},

		onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("emote_nuzzle")
			
            inst.sg.mem.prevemotetime = GetTime()

            if fns ~= nil and fns.onenter ~= nil then
                fns.onenter(inst)
            end			
		end,

		timeline = timeline,

		events =
		{
			EventHandler("animover", function(inst) 
                if inst.AnimState:AnimDone() then
					inst:PerformBufferedAction()
					inst.sg:GoToState("idle") 
				end
			end)
		},
		onexit = fns ~= nil and fns.onexit or nil,
    })
end


--------------------------------------------------------------------------
SGCritterStates.AddEmotes = function(states, emotes, timeline)
	for i,v in ipairs(emotes) do
		table.insert(states, State
		{
			name = "emote"..i,
			tags = { "busy", "canrotate" },

			onenter = function(inst, pushanim)
				if inst.components.locomotor ~= nil then
					inst.components.locomotor:StopMoving()
				end

				inst.AnimState:PlayAnimation(v.anim)
			end,

			timeline = v.timeline,

			events =
			{
				EventHandler("animover", function(inst)
					if inst.AnimState:AnimDone() then
						inst.sg:GoToState("idle")
					end
				end),
			},
		})
	end
end


local function sleepexonanimover(inst)
    if inst.AnimState:AnimDone() then
        inst.sg.statemem.continuesleeping = true
        inst.sg:GoToState(inst.sg.mem.sleeping and "sleeping" or "wake")
    end
end

local function sleepingexonanimover(inst)
    if inst.AnimState:AnimDone() then
        inst.sg.statemem.continuesleeping = true
        inst.sg:GoToState("sleeping")
    end
end

local function wakeexonanimover(inst)
    if inst.AnimState:AnimDone() then
        inst.sg:GoToState(inst.sg.mem.sleeping and "sleep" or "idle")
    end
end

SGCritterStates.AddSleepExStates = function(states, timelines, fns)
    table.insert(states, State
    {
        name = "sleep",
        tags = { "busy", "sleeping", "nowake" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("sleep_pre")
            if fns ~= nil and fns.onsleep ~= nil then
                fns.onsleep(inst)
            end
        end,

        timeline = timelines ~= nil and timelines.starttimeline or nil,

        events =
        {
            EventHandler("animover", sleepexonanimover),
        },

        onexit = function(inst)
            if not inst.sg.statemem.continuesleeping and inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
            if fns ~= nil and fns.onexitsleep ~= nil then
                fns.onexitsleep(inst)
            end
        end,
    })

    table.insert(states, State
    {
        name = "sleeping",
        tags = { "busy", "sleeping" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("sleep_loop")
            if fns ~= nil and fns.onsleeping ~= nil then
                fns.onsleeping(inst)
            end
        end,

        timeline = timelines ~= nil and timelines.sleeptimeline or nil,

        events =
        {
            EventHandler("animover", sleepingexonanimover),
        },

        onexit = function(inst)
            if not inst.sg.statemem.continuesleeping and inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
            if fns ~= nil and fns.onexitsleeping ~= nil then
                fns.onexitsleeping(inst)
            end
        end,
    })

    table.insert(states, State
    {
        name = "wake",
        tags = { "busy", "waking", "nosleep" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("sleep_pst")
            if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
            if fns ~= nil and fns.onwake ~= nil then
                fns.onwake(inst)
            end
        end,

        timeline = timelines ~= nil and timelines.waketimeline or nil,

        events =
        {
            EventHandler("animover", wakeexonanimover),
        },

        onexit = fns ~= nil and fns.onexitwake or nil,
    })
end
