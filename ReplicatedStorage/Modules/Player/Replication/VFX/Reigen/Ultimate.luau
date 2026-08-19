local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local Aura1s = {}

function VFX.OnUltimateStart(Model : Model)
	local Effect = script.Assets.Aura2:Clone()
	Effect:AddTag("UltimateAura")
	Effect.Parent = Model.Torso
	EffectUtility.Toggle(Effect, true)

	AttributeListener.new(Model, "Ultimate", function()
		EffectUtility.Toggle(Effect, false)
		task.delay(1, Effect.Destroy, Effect)
	end)
end

function VFX.Camera(RootPart : BasePart)
	local Replication : Configuration = AttributeListener.GetReplicationFromSource(RootPart)
	local Offset = CFrame.new(0, -3, 0) * CFrame.Angles(0, math.rad(180), 0)

	local Camera = script.Camera:Clone()
	Camera:PivotTo(RootPart.CFrame * Offset)
	Camera.Parent = workspace.Visuals

	local Animation = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Ultimate.Reigen.Camera)
	Animation:Play(0)

	local Clean = RunCameraRig(RootPart, Camera, Offset)

	local NewJob = Job.new()

	local function Remove()
		NewJob:Destroy()
		
		Clean()
		Yuki_FOV.Reset()
	end
	
	NewJob:Task(task.delay(7.783333333333333, function()
		Animation:AdjustSpeed(0.55)
	end))

	NewJob:Task(Replication:GetAttributeChangedSignal("ReigenUltimateCamera"):Connect(function()
		if not Replication:GetAttribute("ReigenUltimateCamera") then
			Remove()
		end
	end))
	
	Animation.Stopped:Once(Remove)
end

function VFX.Blue(Mob : Model, Type : string)
	EffectUtility.Toggle(Mob.Torso.Blue, (Type == "Enable"))
end

function VFX.Red(Mob : Model, Type : string)
	EffectUtility.Toggle(Mob.Torso.Red, (Type == "Enable"))
end

function VFX.MobInvis(Mob : Model, Parameter : string)
	if Parameter == "true" then
		Mob.Head.Transparency = 1

		for _, Item in ipairs(Mob:GetChildren()) do
			if Item:IsA("Accessory") then
				Item.Handle.Transparency = 1
			end
		end
	else
		Mob.Head.Transparency = 0

		for _, Item in ipairs(Mob:GetChildren()) do
			if Item:IsA("Accessory") then
				Item.Handle.Transparency = 0
			end
		end
	end
end
	

function VFX.Aura1(Torso : BasePart, Type : string)
	if not Aura1s[Torso] then
		local Effect = script.Assets.Aura1:Clone()
		Effect.Parent = Torso
		
		if LocalPlayer == Players:GetPlayerFromCharacter(Torso.Parent) then
			Aura1s[Torso] = {
				Effect = Effect,
				Shake = CameraShake(0.45, 4.5, 0.05, 0, Vector3.one * 0.8),
				CustomEffects = coroutine.create(function()
					while (Torso.Parent ~= nil) do
						local Colors = {
							Color3.fromRGB(162, 85, 255),
							Color3.fromRGB(105, 185, 255),
							Color3.fromRGB(90, 255, 115),
							Color3.fromRGB(146, 113, 255),
						}

						Vignette(Colors[math.random(1, #Colors)], 0.15, 0.1)

						task.wait(0.075)
					end
				end)
			}
		else
			Aura1s[Torso] = {
				Effect = Effect
			}
		end
	
		if Aura1s[Torso].CustomEffects then
			coroutine.resume(Aura1s[Torso].CustomEffects)
		end
		
	end
	
	if (Type == "Enable") then
		EffectUtility.Toggle(Aura1s[Torso].Effect, true)
	else
		EffectUtility.Toggle(Aura1s[Torso].Effect, false)
		task.delay(2, Aura1s[Torso].Effect.Destroy, Aura1s[Torso].Effect)
		
		if Aura1s[Torso].CustomEffects and coroutine.status(Aura1s[Torso].CustomEffects) == "suspended" then
			coroutine.close(Aura1s[Torso].CustomEffects)
		end
	
		if Aura1s[Torso].Shake then
			Aura1s[Torso].Shake:StartFadeOut(0.1)
		end
		
		table.clear(Aura1s[Torso])
		Aura1s[Torso] = nil
	end
end

function VFX.Burst(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.Burst, RootPart)
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25 then
		CameraShake(4.5, 45, 0.1, 1, Vector3.one * 0.8)
		Vignette(Color3.fromRGB(146, 113, 255), 0.15, 0.5)
	end
	
	local Position = RootPart.Position
	local LookVector = Vector3.yAxis * -10
	
	EffectUtility.RaycastCraterSmoke("Big", Position, LookVector)
	
	coroutine.wrap(RockHandler.Crater)(Position, LookVector, {
		Amount = 14,
		Distance = 10,

		LookAt = { -- Where the rocks face towards (y axis)
			Min = -8,
			Max = -8
		},
		
		Exposure = {
			Min = 0.55,
			Max = 0.75
		},

		BaseZ = 1.5,
		SizeMultiplier = 1,
	})

	coroutine.wrap(RockHandler.Crater)(Position, LookVector, {
		Amount = 18,
		Distance = 15,
		
		LookAt = { -- Where the rocks face towards (y axis)
			Min = -6,
			Max = -6
		},
		
		Exposure = {
			Min = 0.5,
			Max = 0.7
		},
		
		SizeMultiplier = 1.5,
	})
	
	coroutine.wrap(RockHandler.Rockst)(Position, LookVector, {
		Count = 20,
		Size = {0.25, 1},
		Velocity = 50,
	})
end

function VFX.FOV(Value : number)
	Yuki_FOV.Set(Value)
end

return VFX