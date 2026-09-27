require("stategraphs/commonstates")
require("stategraphs/SGcritter_common")

local actionhandlers = 
{
}

local events=
{
	--SGCritterEvents.OnGoToSleep(),
	SGCritterEvents.OnEat(),
	
	SGCritterEvents.OnSleepEx(),
	SGCritterEvents.OnWakeEx(),
	
    CommonHandlers.OnLocomote(false,true),
}

local states=
{
}

local emotes =
{
	{ anim="emote_stretch",
      timeline=
 		{
			TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("kittington/music/yawn") end),
		},
	},
	{ anim="emote_lick",
      timeline=
 		{
			TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("kittington/music/lick") end),
			TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("kittington/music/lick") end),
			TimeEvent(58*FRAMES, function(inst) inst.SoundEmitter:PlaySound("kittington/music/lick") end),
		},
	},
}

SGCritterStates.AddIdle(states, #emotes)
SGCritterStates.AddEmotes(states, emotes)
SGCritterStates.AddEat(states,
        {
          --  TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/together/kittington/eat_pre") end),
           TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("kittington/music/eat") end),
        })
SGCritterStates.AddHungry(states,
        {
           TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("kittington/music/disstress") end),
            TimeEvent(43*FRAMES, function(inst) inst.SoundEmitter:PlaySound("kittington/music/disstress") end),		
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("kittington/music/yawn") end),
        })
SGCritterStates.AddNuzzle(states, actionhandlers,
        {
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("kittington/music/nuzzle") end),
        })
 

CommonStates.AddWalkStates(states,
	{
		walktimeline =
		{
			TimeEvent(1*FRAMES, PlayFootstep),
			TimeEvent(6*FRAMES, PlayFootstep),
			TimeEvent(12*FRAMES, PlayFootstep),
			TimeEvent(16*FRAMES, PlayFootstep),
		},
		endtimeline =
		{
			TimeEvent(0*FRAMES, PlayFootstep),
			TimeEvent(3*FRAMES, PlayFootstep),
		},
	}, nil, true)

SGCritterStates.AddSleepExStates(states,
		{
			starttimeline = 
			{
				TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("kittington/music/yawn") end),
			},
			sleeptimeline = 
			{
				TimeEvent(31*FRAMES, function(inst) inst.SoundEmitter:PlaySound("kittington/music/sleep") end),
			},
		})

return StateGraph("SGcritter_kitten", states, events, "idle", actionhandlers)

