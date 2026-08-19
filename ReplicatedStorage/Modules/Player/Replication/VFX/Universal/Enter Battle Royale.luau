local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local CharacterTransparency = require( ReplicatedStorage.Modules.Player.Replication.Global.CharacterTransparency )

local VFX = {}

function VFX.Start(RootPart : BasePart)
	local Replication : Configuration = AttributeListener.GetReplicationFromSource(RootPart)
	local Offset = CFrame.identity

	local Camera = script.Camera:Clone()
	Camera:PivotTo(RootPart.CFrame * Offset)
	Camera.Parent = workspace.Visuals

	local Animation = Camera.Humanoid.Animator:LoadAnimation(script.CamAnim)
	Animation:Play(0)

	local NewJob = Job.new()

	NewJob:Task(Yuki_FOV.AnimateWithMoonFile(script.FOV))
	NewJob:Task(RunCameraRig(RootPart, Camera, Offset))

	local function Remove()
		NewJob:Destroy()
	end

	NewJob:Task(Replication:GetAttributeChangedSignal("ReigenUltimateCamera"):Connect(function()
		if not Replication:GetAttribute("ReigenUltimateCamera") then
			Remove()
		end
	end))
	
	NewJob:Task(Animation:GetMarkerReachedSignal("pause"):Connect(function()
		Animation:AdjustSpeed(0)
	end))
end

function VFX.Tp(RootPart : BasePart)
	CharacterTransparency(RootPart.Parent, 1)
end

return VFX
