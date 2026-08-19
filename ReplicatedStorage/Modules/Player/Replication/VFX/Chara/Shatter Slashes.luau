local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Chara["Shatter Slashes"]

---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local Afterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.Afterimage )
local ATrainAfterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.ATrainAfterimage )

local TekrinnDialogue = require( ReplicatedStorage.Modules.TekrinnDialogue )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )

---------------------------------------------------------------------

local function Distance_Close(Model : Model)
	return (if LocalPlayer.Character == Model then true else LocalPlayer:DistanceFromCharacter(Model.PrimaryPart.Position) < 35)
end

local function Distance_Far(Model : Model)
	return (if LocalPlayer.Character == Model then true else LocalPlayer:DistanceFromCharacter(Model.PrimaryPart.Position) < 85)
end

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job

		local Is_Source = (LocalPlayer.Character == Model)
		
		local Velocity
		
		if Is_Source then
			local Multiply = 0
			local Max = 30

			Velocity = VelocityUtil.Create(RootPart, "Bloody Mary Start")
			Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
			Velocity.Parent = RootPart

			Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
				Multiply = math.min(Multiply + (Delta * 60) * 0.25, Max)
				Velocity.Velocity = RootPart.CFrame.LookVector * Multiply
			end)

			Job:Task(Velocity)
		end

		Job:Task(EffectUtility.AddSFX(script.SFX[math.random(1, 2)], Torso, 0.3))
		
		local Slashes : Attachment = script.Assets["1"]:Clone()
		Slashes.Parent = RootPart
		Job:Task(Slashes)
		
		local Screen_Effect = script.ScreenEffect:Clone()
		Screen_Effect.Enabled = false
		Screen_Effect.Parent = Lighting

		local SlashShake = nil

		Job:Task(function()
			if SlashShake then
				SlashShake:StartFadeOut(0.15)
			end
		end)
		
		local DontResetFOV = false
		
		if Is_Source then
			Yuki_FOV.Tween(57.5, {5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out})

			Job:Task(function()
				if not DontResetFOV then
					Yuki_FOV.Reset()
				end
			end)
		end
		
		Job:Task(Screen_Effect)
		
		Job:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
			local Effect = script.Assets:FindFirstChild(Parameter)

			if Effect and Distance_Far(Model) then
				EffectUtility.Arc.CloneAndEmit(Effect, Model[Effect:GetAttribute("attached")])
			end

			if (Parameter == "s1" or Parameter == "s2") and Distance_Close(Model) then
				CameraShake(1, 20, 0.01, 0.125, Vector3.one * 0.8, Vector3.one * 0.2)
				Vignette(Color3.fromHSV(0, 1, 1), 0.75, 0.15)
			end
		end))
	
		Job:Task(Animation:GetMarkerReachedSignal("slashes"):Connect(function(Parameter : string)
			if (Parameter == "true") then
				EffectUtility.Arc.ToggleAttachment(Slashes, true)

				if Distance_Far(Model) then
					Screen_Effect.Enabled = true

					TweenService:Create(Screen_Effect, TweenInfo.new(4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
						{TintColor = Color3.fromRGB(255, 137, 137)}
					):Play()
					
					--TekrinnDialogue.Speak(Model, 

					--	{
					--		Text = "Hahahahh!~~",
					--		Image = "85316557846229",
					--		ExtraImageSize = UDim2.fromOffset(15, 15),
					--		TextStrokeColor = Color3.new(0, 0, 0),
					--		Color = ColorSequence.new({
					--			ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
					--			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(181, 53, 53)),
					--			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(109, 32, 32)),
					--			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(181, 53, 53)),
					--			ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
					--		}),
					--		Shake = {
					--			Lifetime = 0.5,
					--			Enabled = true,
					--			Intensity = 1.5,
					--		},
					--		HigherUp = true,
					--		TypeSpeed = 0.05,
					--	}, 

					--	{
					--		StrokeColor = Color3.new(0, 0, 0),
					--		Color = ColorSequence.new({
					--			ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
					--			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(181, 53, 53)),
					--			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(109, 32, 32)),
					--			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(181, 53, 53)),
					--			ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
					--		}),
					--	}, 

					--	3
					--)
				end
				
				if Distance_Close(Model) then
					SlashShake = CameraShake(1.8, 25, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.4)

					local Thread = coroutine.create(function()
						while RootPart and RootPart.Parent do
							Vignette(Color3.new(1, 0, 0), 0.3, 0.1)
							task.wait(0.03)
						end
					end)

					Job:Task(function()
						Utility.CloseThreadSafe(Thread)
					end)
					
					if Is_Source then
						Yuki_FOV.Tween(85, {5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out})
					end
				end
			else
				EffectUtility.Arc.ToggleAttachment(Slashes, false)

				if SlashShake then
					SlashShake:StartFadeOut(0.15)
					SlashShake = nil
				end
				
				if Screen_Effect.Enabled then
					task.delay(0.1, function()
						TweenService:Create(Screen_Effect, TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
							{TintColor = Color3.fromRGB(255, 255, 255)}
						):Play()
					end)
				end
				
				if Is_Source then
					Yuki_FOV.Tween(100, {0.75, Enum.EasingStyle.Quint, Enum.EasingDirection.Out})

					task.delay(0.75, function()
						Yuki_FOV.Tween(70, {1, Enum.EasingStyle.Sine, Enum.EasingDirection.In})
					end)
					
					DontResetFOV = true
				end
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("burst"):Once(function()
			EffectUtility.Arc.CloneAndEmit(script.Assets["2"], RootPart)
			
			if Velocity then
				Velocity:Destroy()
			end
		end))
	end,
}