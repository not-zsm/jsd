local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local Yuki_Skeleton = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_Skeleton )

function VFX.Camera(RootPart : BasePart)
	local Replication : Configuration = AttributeListener.GetReplicationFromSource(LocalPlayer)
	local Offset = CFrame.new(0, -3, 0) * CFrame.Angles(0, math.rad(-180), 0)

	local Camera = script.Camera:Clone()
	Camera:PivotTo(RootPart.CFrame * Offset)
	Camera.Parent = workspace.Visuals

	local Animation = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Reigen["Emotional Damage"].Camera)
	Animation:Play(0)
	
	Yuki_FOV.Tween(57.5, {0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In})

	local Clean = RunCameraRig(RootPart, Camera, Offset)

	AttributeListener.new(RootPart, "ReigenCounterCamera", function()
		Clean()
		Yuki_FOV.Reset()
	end)
end
	
function VFX.Block(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.block, RootPart)
	
	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
		Yuki_FOV.Tween(50, {0.05, Enum.EasingStyle.Quart, Enum.EasingDirection.In, 0, true})
	end
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 10 then
		CameraShake(2, 20, 0.01, 0.3)
	end
end

function VFX.Catch(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.catch, RootPart)
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 10 then
		CameraShake(1.45, 13.5, 0.01, 0.9)
	end
end

function VFX.GutPunch(RootPart : BasePart, VictimRootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.gutpunch, RootPart)

	if Players:GetPlayerFromCharacter(RootPart.Parent) == LocalPlayer or Players:GetPlayerFromCharacter(VictimRootPart.Parent) == LocalPlayer then
		CameraShake(3.5, 30, 0.01, 0.2)
		Yuki_Skeleton(VictimRootPart.Parent.Torso, 0.1, 0.1)
		
		task.spawn(function()
			local Highlight = script.ImpactFrame.Highlight:Clone()
			Highlight.Enabled = true
			Highlight.Parent = VictimRootPart.Parent

			local Screen = script.ImpactFrame.Screen:Clone()
			Screen.Parent = Lighting

			task.wait(2 / 60)

			Screen:Destroy()

			task.wait(2 / 60)

			Highlight:Destroy()
		end)
	end
	
	for Index = 1, 6 do
		Blood.BloodRays("SpitOut", VictimRootPart.Parent.Head.MouthAttachment)
		task.wait(0.3)
	end
end

function VFX.End(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.endhit, RootPart)
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 10 then
		CameraShake(3.5, 30, 0.01, 0.3)
	end
end

return VFX
