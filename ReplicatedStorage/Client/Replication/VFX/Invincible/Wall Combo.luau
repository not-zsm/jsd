local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Client.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Invincible["Death Leap"]

---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Client.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Client.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Client.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Client.Replication.Global.Blood )

local RunCameraRig = require( ReplicatedStorage.Client.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Client.Replication.Global.Yuki_FOV )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )

local JobModule = require( ReplicatedStorage.Shared.Utilities.Job )

local VelocityUtil = require( ReplicatedStorage.Shared.Game.Velocity.VelocityUtil )
local Smoke = require( ReplicatedStorage.Client.Replication.Global.Smoke )

---------------------------------------------------------------------

return {
	Start = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, ReplicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Invincible.User)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job

		local BloodEnabled = LocalPlayer:GetAttribute("Blood")
		local PlayerIsAttackerOrVictim = (Players:GetPlayerFromCharacter(Model) == LocalPlayer or Players:GetPlayerFromCharacter(VictimModel) == LocalPlayer)
		
		---- Start Camera
		if PlayerIsAttackerOrVictim then
			local Camera : Model = Job:Task(ReplicatedStorage.Effects["Camera's"].MJJBA:Clone())
			-- EffectUtility.Weld(Camera, RootPart)
			Camera:PivotTo(RootPart.CFrame * CFrame.new(-1.525,-2,-1.827) * CFrame.Angles(0, math.rad(90), 0))
			Camera.Parent = workspace.Visuals

			local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Invincible.Camera)
			CameraAnimation:Play(0)

			Job:Task(Yuki_FOV.AnimateWithMoonFile(ReplicatedStorage.FOVFiles["Invincible Wall Combo"]))

			Job:Task(RunCameraRig(RootPart, Camera, nil, {
				DontSaveCameraPosition = true
			}))
		end
	end,
}