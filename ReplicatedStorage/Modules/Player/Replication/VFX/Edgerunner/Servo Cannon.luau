local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Edgerunner[script.Name]

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

return {
	["Start"] = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end
		
		local RootPart = Retrieved.RootPart
		local Animation = Retrieved.Animation
		local Job = Retrieved.Job
		
		Job:Task(Animation:GetMarkerReachedSignal("glint"):Connect(function()
			local Arm : BasePart = Model:FindFirstChild("Left Arm")
			if (Arm == nil) then return end
			
			--local Highlight = Instance.new("Highlight")
			--Highlight.FillColor = Color3.fromRGB(211, 166, 103)
			--Highlight.OutlineTransparency = 1
			--Highlight.FillTransparency = 0.25
			--Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			--Highlight.Parent = Arm
			
			--TweenService:Create(Highlight, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FillTransparency = 1}):Play()
			--task.delay(0.5, Highlight.Destroy, Highlight)
			
			if EffectUtility.Distance_Close(Model, 30) then
				CameraShake(1, 15, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.fromRGB(255, 175, 37), 0.5, 0.1)
				--Yuki_FOV.Tween(60, {1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
			end
			
			local Glint = script.Arm_Glint:Clone()
			Glint.Weld.Part0 = Arm
			Glint.Parent = workspace.Visuals
			TweenService:Create(Glint, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = Glint.Size * 1.3, Transparency = 1}):Play()
			task.delay(0.5, Glint.Destroy, Glint)
			
			EffectUtility.EmitEffects(script.Glint, Arm, nil, CFrame.new(0, -1, 0))
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("shoot"):Connect(function()
			local Offset = CFrame.new(0, -3, -5)
			--local Offset = CFrame.new(0, -2, -5)
			
			local Position = (RootPart.CFrame * Offset).Position
			local Direction = Vector3.yAxis * -10
			
			--local Attachment = Instance.new("Attachment")
			--Attachment.WorldPosition = Position
			--Attachment.Parent = workspace.Terrain
			--task.delay(5, Attachment.Destroy, Attachment)
			--EffectUtility.AddSFX(script.Slam, Attachment)
			
			local Boom = script.Boom:Clone()
			Boom.Position = Position
			Boom.Parent = workspace.Visuals
			EffectUtility.Emit(Boom)
			
			if EffectUtility.Distance_Close(Model, 30) then
				CameraShake(2.3, 20, 0.01, 0.65, Vector3.one * 0.8, Vector3.one * 0.4)
				Vignette(Color3.fromRGB(255, 183, 0), 0.25, 0.15)
				Yuki_FOV.Tween(75, {0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
				
				Job:Task(function()
					Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out})
				end)
			end
			
			coroutine.wrap(RockHandler.Crater)(Position, Direction, {
				Amount = 4,
				Distance = 5,

				Burn = {
					Enabled = true,
					Color = Color3.fromRGB(255, 102, 0),
					Transparency = 0.25,
					Time = {
						Min = 0.4,
						Max = 0.6
					},
				},
				
				LookAt = { -- Where the rocks face towards (y axis)
					Min = -5,
					Max = -5
				},

				Exposure = {
					Min = 0.5,
					Max = 0.7
				},

				BaseZ = 1.35,

				SizeMultiplier = 0.85,
			})

			coroutine.wrap(RockHandler.Crater)(Position, Direction, {
				Amount = 7,
				Distance = 6.5,
				
				Burn = {
					Enabled = true,
					Color = Color3.fromRGB(255, 102, 0),
					Transparency = 0.25,
					Time = {
						Min = 0.4,
						Max = 0.6
					},
				},

				LookAt = { -- Where the rocks face towards (y axis)
					Min = 7,
					Max = -7
				},

				Exposure = {
					Min = 0.5,
					Max = 0.7
				},

				SizeMultiplier = 1.1,
			})
			
			--coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			--	Amount = 3.5,
			--	Distance = 4.5,

			--	LookAt = { -- Where the rocks face towards (y axis)
			--		Min = -5,
			--		Max = -5
			--	},

			--	Exposure = {
			--		Min = 0.5,
			--		Max = 0.7
			--	},

			--	BaseZ = 1.35,

			--	SizeMultiplier = 0.85,
			--})

			--coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			--	Amount = 6,
			--	Distance = 5.5,

			--	LookAt = { -- Where the rocks face towards (y axis)
			--		Min = 7,
			--		Max = -7
			--	},

			--	Exposure = {
			--		Min = 0.5,
			--		Max = 0.7
			--	},

			--	SizeMultiplier = 1.1,
			--})

			coroutine.wrap(RockHandler.Rockst)(Position + Vector3.new(0, 1, 0), Direction, {
				Count = 20,
				Size = {0.4, 0.9},
				SpawnVariance = 2,
				Velocity = 70,
			})
		end))
		
		Retrieved.Job:Task(EffectUtility.AddSFX(script.SFX, Retrieved.RootPart, 0.4))
	end,
	
	["Timed_Hit"] = function(Attacker : Model, Victim : Model)
		if LocalPlayer.Character == Attacker or LocalPlayer.Character == Victim then
			local White = Color3.new(1, 1, 1)
			local Exposure = 2
			local Time = 5 / 60
			
			CameraShake(3, 30, 0.01, Time, Vector3.one * 0.8)
			Vignette(White, 0, Time)
		
			local Highlight = Instance.new("Highlight")
			Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			Highlight.FillColor = White
			Highlight.FillTransparency = 0
			Highlight.OutlineTransparency = 1

			Lighting.ExposureCompensation += Exposure
			Highlight.Parent = Attacker

			task.wait(Time)

			Highlight:Destroy()
			--TweenService:Create(Lighting, TweenInfo.new(Time, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {ExposureCompensation = Lighting.ExposureCompensation - Exposure}):Play()
			Lighting.ExposureCompensation -= Exposure
		end
	end,
	
	["Hit"] = function(Victim : Model)
		local Blue_Auras = {}
		
		for _, Item in ipairs(Victim:GetChildren()) do
			if (Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart") then
				local Directory = (if Item.Name == "Torso" then "Torso" else "Limb")

				for _, Aura in ipairs(script.Victim_Fire[Directory]:GetChildren()) do
					local Clone = Aura:Clone()
					Clone.Enabled = true
					Clone:Emit()
					Clone.Parent = Item
					Blue_Auras[Clone] = true
				end
			end
		end
		
		task.delay(0.8, function()
			for Aura : ParticleEmitter in Blue_Auras do
				Aura.Enabled = false
				task.delay(1, Aura.Destroy, Aura)
			end
		end)
	end,
}
