local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )

local LoopAnim = nil

local function Wire(Source, Target, Name : String)
	local Wire = Instance.new("Wire")
	Wire.SourceInstance = Source
	Wire.TargetInstance = Target
	Wire.Parent = Source
	Wire.Name = Name or `{Source.Name} -> {Target.Name}`
	
	return Wire
end

return {
	Start = function(Player : Player, Character : Model)
		if Player == LocalPlayer then return end

		local Retrieved = AnimationRetriever.new(Character, replicatedStorage.Animations.Emotes["Mic Up"])
		if (Retrieved == nil) then return end

		local Job = Retrieved.Job
		
		local OriginalInput : AudioDeviceInput = Player:FindFirstChild("AudioDeviceInput")
		if OriginalInput then
			-- OriginalInput.Muted = true
			local Wires = {}
			
			-- Create New Input
			--local Input = Instance.new("AudioDeviceInput")
			--Input.Name = "MicUp Input"
			--Input.Parent = Player
			--Input.Player = Player
			
			local Effect = Instance.new("AudioReverb")
			Effect.ReferenceFrequency = 8000
			Effect.DecayRatio = 10
			Effect.LowShelfGain = 10
			Effect.DecayTime = 2.3
			Effect.Parent = OriginalInput -- Input
			
			table.insert(Wires, Wire(OriginalInput, Effect))
			
			local Emitter = Instance.new("AudioEmitter")
			Emitter.Name = "MicUp Emitter"
			Emitter.Parent = Character
			Emitter.AudioInteractionGroup = `MicUp`
			
			table.insert(Wires, Wire(Effect, Emitter))
			
			local Listener = LocalPlayer.Character:FindFirstChild("MicUp Listener")
			if not Listener then
				Listener = Instance.new("AudioListener")
				Listener.AudioInteractionGroup = "MicUp"
				Listener.Name = "MicUp Listener"
				Listener.Parent = workspace.Camera
			end
			
			local Output = LocalPlayer:FindFirstChild("MicUp Output")
			if not Output then
				Output = Instance.new("AudioDeviceOutput")
				Output.Name = "MicUp Output"
				Output.Parent = LocalPlayer
			end
			
			table.insert(Wires, Wire(Listener, Output))
			
			Job:Task(function()
				for _, Wire in Wires do
					Wire:Destroy()
				end
				OriginalInput.Muted = false
				
				-- Input:Destroy()
				Effect:Destroy()
				Emitter:Destroy()
			end)
		end
	end,
}
