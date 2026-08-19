local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local LocalPlayer = Players.LocalPlayer

local Info = TweenInfo.new(0.5)

local VFX = {}

function VFX.Face(Character : Model, TargetPart : Part, Duration : Number)
	if LocalPlayer.Character == Character then
		local RootPart = Character.HumanoidRootPart

		local BodyGyro = Instance.new("BodyGyro")
		BodyGyro.MaxTorque = Vector3.new(0, 1, 0) * 80000
		BodyGyro.P = 1500
		BodyGyro.D = 80
		BodyGyro.CFrame = CFrame.new(RootPart.Position, Vector3.new(TargetPart.Position.X, RootPart.Position.Y, TargetPart.Position.Z))
		BodyGyro.Parent = RootPart

		task.delay(1.5, function()
			BodyGyro:Destroy()
		end)
	end
end

return VFX
