local replicatedStorage = game:GetService("ReplicatedStorage")

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = replicatedStorage.animations.Emotes.Erased

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local Bars = require( replicatedStorage.modules.client.replication.Global.BlackBars )

local Emotes = {}

return {
	Start = function(Model : Model)
		if Emotes[Model] then return end

		local RootPart = Model:FindFirstChild("HumanoidRootPart")
		if (RootPart == nil) then return end
		
		local Snow = script.Snow:Clone()
		EffectUtility.Weld(Snow, RootPart, CFrame.new(0, 6, 0))
		Snow.Parent = workspace.Visuals
		
		local EmoteJob = Job.new()
		local SFX = EmoteJob:Task(EffectUtility.AddSFX(script.ErasedSFX, RootPart, 0.5))
		
		EmoteJob:Task(Model.AncestryChanged:Once(function()
			if EmoteJob then
				EmoteJob:Destroy()
				EmoteJob = nil
			end
		end))
		
		EffectUtility.Toggle(Snow, true)
		
		EmoteJob:Task(Snow)
		EmoteJob:Task(SFX)
		
		Emotes[Model] = {Job = EmoteJob, Model = Snow}
	end,
	
	Stop = function(Model : Model, Cancelled : Bolean)
		if Emotes[Model] then
			if not Cancelled then
				EffectUtility.Toggle(Emotes[Model].Model, false)
				task.wait(1)
			end
			
			Emotes[Model].Job:Destroy()
			Emotes[Model] = nil
		end
	end,
	
	ToggleBars = function(Enabled : Bolean)
		Bars(Enabled, 0.3)
	end,
}