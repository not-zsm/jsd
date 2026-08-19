local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )
local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local Shockwave = require( ReplicatedStorage.Modules.Player.Replication.Global.Shockwave )
local Bubble = require( ReplicatedStorage.Modules.Player.Replication.Global.Bubble )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

function VFX.Kick(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.kick, RootPart)
	Shockwave(RootPart, nil, CFrame.new(0, 0, -3))
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 15 then
		CameraShake(1.5, 15, 0.01, 0.25, Vector3.one * 0.8)
	end
end

function VFX.Slam(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.onwall, RootPart)
end

function VFX.Land(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.fall, RootPart)
end

function VFX.Infinity(RootPart : BasePart)
	local Torso : BasePart = RootPart.Parent.Torso

	local NewJob = Job.new()
	
	local Infinity = script.Assets.infinity:Clone()
	Infinity.Parent = RootPart
	EffectUtility.Toggle(Infinity, true)
	
	task.spawn(function()
		if Players:GetPlayerFromCharacter(RootPart.Parent) == LocalPlayer then
			local Shake = CameraShake(3, 17.5, 0.1, 0, Vector3.one * 0.8, Vector3.one * 0.35)

			NewJob:Task(function()
				if Shake then
					Shake:StartFadeOut(0.1)
				end
			end)
			
			local ScreenEffect = script.Vignette:Clone()
			ScreenEffect.Parent = LocalPlayer.PlayerGui

			TweenService:Create(ScreenEffect["Image"], TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				ImageTransparency = 0.25
			}):Play()

			NewJob:Task(function()
				TweenService:Create(ScreenEffect["Image"], TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
					ImageTransparency = 1
				}):Play()

				task.delay(0.6, ScreenEffect.Destroy, ScreenEffect)
			end)
		end
	end)
	
	local Step = 0
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 75 then
		NewJob:Task(RunService.PostSimulation:Connect(function()
			Step += 1

			if Step % (14 - Utility.GetQuality()) == 0 and LocalPlayer:DistanceFromCharacter(RootPart.Position) < 25 then
				Bubble(Torso, 4, Vector3.zero, Vector3.one * 20, 0.15)

				local Circle = script.Wind:Clone()
				Circle.Position = Torso.Position + Vector3.new(0, 3, 0)
				Circle.Orientation = Vector3.new(Utility.Seed:NextNumber(-180, 180), Utility.Seed:NextNumber(-180, 180), Utility.Seed:NextNumber(-180, 180))
				Circle.Parent = workspace.Visuals

				TweenService:Create(Circle, TweenInfo.new(0.35), {
					Transparency = 1, 
					Size = Vector3.new(35, 1.5, 35),
					Orientation = Vector3.new(Utility.Seed:NextNumber(-180, 180), Utility.Seed:NextNumber(-180, 180), Utility.Seed:NextNumber(-180, 180))
				}):Play()
			end
		end))
	end
	
	NewJob:Task(function()
		EffectUtility.Toggle(Infinity, false)
		task.delay(1, Infinity.Destroy, Infinity)
	end)
	
	AttributeListener.new(RootPart, "GojoWallCombo", function()
		NewJob:Destroy()
	end)
end

function VFX.Step(RootPart : BasePart, Type : string)
	EffectUtility.CloneAndEmit(script.Assets[`step{Type}`], RootPart)
end

function VFX.End(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.boom, RootPart)
end

return VFX