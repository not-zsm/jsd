local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local StandHandler = require( ReplicatedStorage.Modules.Player.Replication.StandHandler )

return {
	["Move"] = function(StandUser : Model, CF : CFrame, Time : number)
		StandHandler.Move(StandUser, CF, Time);
	end,

	["Summon"] = function(StandUser: Model)
		local Meaty = StandHandler.GetStand(StandUser)

		if Meaty then
			StandHandler.SetStandVisible(StandUser, true);
			
			EffectUtility.EmitEffects(script.Callout, Meaty.PrimaryPart)
			EffectUtility.AenoirEmit(script.Summon, Meaty.PrimaryPart.RootAttachment);
		end;
	end,

	["Unsummon"] = function(StandUser : Model)
		local Meaty = StandHandler.GetStand(StandUser)

		if Meaty then
			StandHandler.SetStandVisible(StandUser, false);
			EffectUtility.AenoirEmit(script.Unsummon, Meaty.PrimaryPart.RootAttachment);
		end
	end,
	
	["StandShown"] = function(StandUser: Model, Value: boolean)
		StandHandler.SetStandVisible(StandUser, Value);
	end,
}