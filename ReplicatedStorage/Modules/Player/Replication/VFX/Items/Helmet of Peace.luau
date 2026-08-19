local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer


---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local CharacterTransparency = require( ReplicatedStorage.Modules.Player.Replication.Global.CharacterTransparency )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local JobModule = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local MeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.DojyanMeshEmit )
---------------------------------------------------------------------

local Highlights = {}

return {
	Start = function(Model : Model)
		local Highlight = Instance.new("Highlight")
		Highlight.FillTransparency = 1
		Highlight.OutlineTransparency = 1
		Highlight.OutlineColor = Color3.new(0.631373, 0.858824, 1)
		Highlight.FillColor = Color3.new(0.631373, 0.858824, 1)
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.Parent = Model
		
		Highlights[Model] = Highlight
		
		local HighlightTween = TweenService:Create(Highlight, TweenInfo.new(1.8), {
			FillTransparency = 0.85,
			OutlineTransparency = 0
		})
		
		HighlightTween:Play()
		local SFX = EffectUtility.AddSFX(script.Use, Model.HumanoidRootPart, 0.5)
		task.delay(8, SFX.Destroy, SFX)
		
		task.delay(5, Highlights[Model].Destroy, Highlights[Model]) -- incase it somehow doesnt get destroyed in the explode
	end,
	
	Explode = function(Model : Model)
		local ExplodeModel = script.Explode:Clone()
		ExplodeModel:PivotTo(Model.HumanoidRootPart.CFrame)
		ExplodeModel.Parent = workspace.Visuals
		
		EffectUtility.Emit(ExplodeModel)
		
		task.delay(4, ExplodeModel.Destroy, ExplodeModel)
		
		local Distance = LocalPlayer:DistanceFromCharacter(Model.HumanoidRootPart.Position)
		--if Distance < 200 then
		--	CameraShake(((200 - Distance) / 15), 50, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.4)
		--end
		
		if Distance < 60 then
			CameraShake(18, 65, 0.04, 0.3, Vector3.one * 0.8)
		end
		
		local Position = Model.HumanoidRootPart.Position
		local Direction = Vector3.yAxis * -10
		
		task.defer(RockHandler.Crater, Position, Direction, {
			Amount = 20,
			Distance = {Min = 15, Max = 35},
			LookAt = {Min = 5, Max = 10},
			Timing = {
				In = {Min = 0.05, Max = 0.35},
				Idle = {Min = 4.7, Max = 5.1},
				Out = 4,
			},
			Exposure = {Min = 0.5, Max = 2},
			BaseZ = 1.25,
			SizeMultiplier = 2.5,
		})

		task.defer(RockHandler.Crater, Position, Direction, {
			Amount = 45,
			Distance = {Min = 35, Max = 55},
			LookAt = {Min = -5, Max = -10},
			Timing = {
				In = {Min = 0.05, Max = 0.35},
				Idle = {Min = 4.7, Max = 5.1},
				Out = 4,
			},
			Exposure = {Min = 2, Max = 3},
			BaseZ = 0.75,
			SizeMultiplier = 5,
		})

		--task.defer(RockHandler.Rockst, Position, Direction, {
		--	Size = {1.5, 3.5},
		--	Count = 60,
		--	Velocity = 125,
		--	SpawnVariance = 35;
		--})
		
		if Highlights[Model] then
			Highlights[Model]:Destroy()
			Highlights[Model] = nil
		end
	end,
	
	Finisher = function(Model : Model)
		if LocalPlayer:DistanceFromCharacter(Model.HumanoidRootPart.Position) < 200 then
			--EffectUtility.EmitEffects(ReplicatedStorage.Effects.Blood.Splash, Model.HumanoidRootPart)
			EffectUtility.CloneAndEmit(script.VFX.Finisher, Model.HumanoidRootPart)

			Blood.BloodRaysWithoutPreset(Model.HumanoidRootPart, {
				Amount = Vector2.new(30, 35),

				Spread = Vector2.new(-360, 360),
				Power = 60,
				Face = Enum.NormalId.Top,

				PoolSize = 2,
			})
		end
		
		CharacterTransparency(Model, 1)
	end,
}