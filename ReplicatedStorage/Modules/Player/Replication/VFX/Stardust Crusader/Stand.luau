local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local StandHandler = require( ReplicatedStorage.Modules.Player.Replication.StandHandler )

return {
	["Move"] = function(StandUser : Model, CF : CFrame, Time : number)
		StandHandler.Move(StandUser, CF, Time);
	end,

	["Summon"] = function(StandUser : Model)
		local StarPlatinum = StandHandler.GetStand(StandUser)

		if StarPlatinum then
			StandHandler.SetStandVisible(StandUser, true);
			EffectUtility.EmitEffects(script.Callout, StarPlatinum.PrimaryPart)
		end;
	end,
	
	["Unsummon"] = function(StandUser : Model)
		StandHandler.SetStandVisible(StandUser, false);
	end,

	["StandShown"] = function(StandUser: Model, Value: boolean)
		StandHandler.SetStandVisible(StandUser, Value);
	end,
}