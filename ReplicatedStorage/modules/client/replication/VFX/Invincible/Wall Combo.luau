local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = replicatedStorage.Animations.Attacks.Invincible["Death Leap"]

---------------------------------------------------------------------

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

local RunCameraRig = require( replicatedStorage.modules.client.replication.Global.RunCameraRig )
local Yuki_FOV = require( replicatedStorage.modules.client.replication.Global.Yuki_FOV )

---------------------------------------------------------------------

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local JobModule = require( replicatedStorage.modules.shared.Utilities.Job )

local VelocityUtil = require( replicatedStorage.modules.shared.Game.Velocity.VelocityUtil )
local Smoke = require( replicatedStorage.modules.client.replication.Global.Smoke )

---------------------------------------------------------------------

return {
	Start = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, replicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Invincible.User)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job

		local BloodEnabled = LocalPlayer:GetAttribute("Blood")
		local PlayerIsAttackerOrVictim = (Players:GetPlayerFromCharacter(Model) == LocalPlayer or Players:GetPlayerFromCharacter(VictimModel) == LocalPlayer)
		
		---- Start Camera
		if PlayerIsAttackerOrVictim then
			local Camera : Model = Job:Task(replicatedStorage.modules.effect.assets["Camera's"].MJJBA:Clone())
			-- EffectUtility.Weld(Camera, RootPart)
			Camera:PivotTo(RootPart.CFrame * CFrame.new(-1.525,-2,-1.827) * CFrame.Angles(0, math.rad(90), 0))
			Camera.Parent = workspace.Visuals

			local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(replicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Invincible.Camera)
			CameraAnimation:Play(0)

			Job:Task(Yuki_FOV.AnimateWithMoonFile(replicatedStorage.FOVFiles["Invincible Wall Combo"]))

			Job:Task(RunCameraRig(RootPart, Camera, nil, {
				DontSaveCameraPosition = true
			}))
		end
	end,
}