local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local Animations = ReplicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Mori

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.User)
		if (Retrieved == nil) then return end
		
		local Job = Retrieved.Job
		local Animation = Retrieved.Animation
		
		local StopSFX = true
		
		Job:Task(Animation:GetMarkerReachedSignal("end"):Once(function()
			StopSFX = false
		end))
		
		local SFX : Sound? = EffectUtility.AddSFX(script.SFX, Retrieved.RootPart, 0.3)
		
		Job:Task(function()
			if SFX and StopSFX then
				SFX:Destroy()
			end
		end)
	end,
}