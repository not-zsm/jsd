--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local TweenService = game:GetService('TweenService');
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

local VFX = {};

function VFX.Float(RootPart : BasePart)
	local Position = RootPart.Position

	local Model : Model = RootPart.Parent
	local Arm : BasePart = Model["Right Arm"]
	
	if Player == Players:GetPlayerFromCharacter(Model) then
		local Raycast = workspace:Raycast(RootPart.Position, Vector3.yAxis * 45, Utility.VisualParams)
		local FloatPosition = nil
		
		if (Raycast ~= nil and Raycast.Instance.CanCollide) then
			FloatPosition = (RootPart.CFrame * CFrame.new(0, Raycast.Distance - 4, 0)).Position
		else
			FloatPosition = (RootPart.CFrame * CFrame.new(0, 45, 0)).Position
		end

		local BodyPosition = Instance.new("BodyPosition")
		BodyPosition.MaxForce = Vector3.one * 4e4
		BodyPosition.Position = FloatPosition
		BodyPosition.P = 4e4
		BodyPosition.Parent = RootPart

		task.delay(3, BodyPosition.Destroy, BodyPosition)
	end
	
	EffectUtility.EmitEffects(script.SFX, RootPart)
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if Distance > 150 then return end
	
	if (Distance < 50) then
		CameraShake(1.5, 15, 0.05, 0.2)
	end
	
	local Direction = Vector3.yAxis * -10
	
	coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		Amount = 9,
		Distance = 5,

		LookAt = { -- Where the rocks face towards (y axis)
			Min = -3,
			Max = -3
		},

		Exposure = {
			Min = 0.3,
			Max = 0.5
		},

		BaseZ = 1.5,

		SizeMultiplier = 0.95,
	})

	coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		Amount = 15,
		Distance = 12.5,

		SizeMultiplier = 1.65,
	})

	coroutine.wrap(RockHandler.Rockst)(Position, Direction, {
		Count = 13,
		Size = {1, 1.25},
		Velocity = 55,
	})

	EffectUtility.RaycastCraterSmoke("Big", Position, Direction)
end

function VFX.Hand(Arm : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(Arm.Position)
	if Distance > 50 then return end
	
	local Attach = script.Assets.Holder.Charge:Clone()
	Attach.Parent = Arm

	for _, Item in ipairs(Attach:GetDescendants()) do
		if (Item:IsA('ParticleEmitter')) then
			if (Item.Parent.Name == "Emit") then
				Item:Emit(Item:GetAttribute("EmitCount"))
			else
				Item.Enabled = true
			end
		end
	end

	local function Finish()
		EffectUtility.Toggle(Attach, false)
		task.delay(2, Attach.Destroy, Attach)
	end

	task.delay(3, Finish)
end

local Balls = {}

function VFX.Ball(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if Distance > 400 then return end
	
	if (Distance < 25) then
		CameraShake(1.5, 15, 0.05, 0.2)
		ScreenPulse("Plasmic Degree")
	end
	
	local Ball = script.Assets.SphereNew:Clone()
	Ball.CFrame =  RootPart.CFrame * CFrame.new(0, 22.5, 0)
	Ball.Parent = workspace.Visuals
	
	for _, Item in ipairs(Ball:GetDescendants()) do
		if (Item:IsA('ParticleEmitter')) then
			if (Item.Parent.Name == "Emit") then
				Item:Emit(Item:GetAttribute("EmitCount"))
			else
				Item.Enabled = true
			end
		end
	end
	
	Balls[RootPart] = Ball
end

function VFX.Throw(RootPart : BasePart, RaycastPosition : Vector3, RaycastColor : Color3)
	if Balls[RootPart] == nil then return end

	local Ball = Balls[RootPart]

	local Tween = TweenService:Create(Ball, TweenInfo.new(0.6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{Position = RaycastPosition}
	)

	Tween:Play()

	Tween.Completed:Connect(function()
		local ex = script.Assets.TheExplos:Clone()
		ex.CFrame =  Ball.CFrame
		ex.Parent = workspace.Visuals
		
		for _, Item in ipairs(ex.Emit:GetChildren()) do
			if string.find(Item.Name, "Dust") then
				Item.Color = ColorSequence.new(RaycastColor)
			end
		end

		EffectUtility.Emit(ex)
		Ball:Destroy()

		if (Players.LocalPlayer:DistanceFromCharacter(RootPart.Position) < 85) then
			CameraShake(2.5, 40, 0.05, 0.5)
			ScreenPulse("Plasmic Degree Explosion")
		end

		local DIrection = Vector3.yAxis * -10
		
		coroutine.wrap(RockHandler.Crater)(RaycastPosition, DIrection, {
			Amount = 22,
			Distance = 25,

			Angle = { -- Adds randomness so the rocks dont form a perfect circle
				Min = -45,
				Max = 45
			},
			
			LookAt = { -- Where the rocks face towards (y axis)
				Min = -8,
				Max = -8
			},

			Exposure = {
				Min = 0.1,
				Max = 0.3
			},

			BaseZ = 1.5,

			SizeMultiplier = 1.25,
		})

		coroutine.wrap(RockHandler.Crater)(RaycastPosition, DIrection, {
			Amount = 27,
			Distance = 29,
			
			Angle = { -- Adds randomness so the rocks dont form a perfect circle
				Min = -55,
				Max = 55
			},
			
			LookAt = { -- Where the rocks face towards (y axis)
				Min = -17.5,
				Max = 17.5
			},
			
			Exposure = {
				Min = 0.55,
				Max = 0.75
			},

			SizeMultiplier = 1.75,
		})

		coroutine.wrap(RockHandler.Rockst)(RaycastPosition, DIrection, {
			Count = 18,
			Size = {1.25, 1.75},
			Velocity = 55,
		})
	end)
end

function VFX.ThrowFail(RootPart : BasePart)
	if (Balls[RootPart] == nil) then return end

	local Ball = Balls[RootPart]
	
	EffectUtility.Toggle(Ball, false)
	task.delay(2, Ball.Destroy, Ball)
end

return VFX