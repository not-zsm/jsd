local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Emotes.Erased

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local Emotes = {}

return {
	Start = function(Model : Model)
		if Emotes[Model] then return end

		local RootPart = Model:FindFirstChild("HumanoidRootPart")
		if (RootPart == nil) then return end
	
		Emotes[Model] = Job.new()
		
		Emotes[Model]:Task(Model.AncestryChanged:Once(function()
			if Emotes[Model] then
				Emotes[Model]:Destroy()
				Emotes[Model] = nil
			end
		end))

		local Snow = script.Snow:Clone()
		EffectUtility.Weld(Snow, RootPart, CFrame.new(0, 6, 0))
		Snow.Parent = workspace.Visuals
		
		local Butterfly = script.Butterfly:Clone()
		EffectUtility.Weld(Butterfly, RootPart, CFrame.new(0, -2, 0) * CFrame.Angles(0, math.rad(-180), 0))
		Butterfly.Parent = workspace.Visuals
		
		local Animation = Butterfly.Humanoid.Animator:LoadAnimation(Animations.Butterfly)
		
		Emotes[Model]:Task(Animation:GetMarkerReachedSignal("end"):Connect(function(Name)
			Animation:AdjustSpeed(0)
		end))
		
		EffectUtility.Toggle(Snow, true)
		Animation:Play(0)
		
		Emotes[Model]:Task(Snow)
		Emotes[Model]:Task(Butterfly)
	end,
	
	Stop = function(Model : Model)
		if Emotes[Model] then
			Emotes[Model]:Destroy()
			Emotes[Model] = nil
		end
	end,
}