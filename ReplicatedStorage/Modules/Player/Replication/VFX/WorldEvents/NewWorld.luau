local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------
local CharacterTransparency = require( ReplicatedStorage.Modules.Player.Replication.Global.CharacterTransparency )

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.WorldEvents.InvincibleBoss

---------------------------------------------------------------------

local JobModule = require( ReplicatedStorage.Modules.Shared.Utilities.Job )
--local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Dialogue = require(ReplicatedStorage.Modules.TekrinnDialogue)

local Animations = ReplicatedStorage.Animations.WorldEvents.NewWorld

---------------------------------------------------------------------

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Obtainment.User)

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		if not IsMainPlayer then
			CharacterTransparency(Model, 1)
			
			Job:Task(function()
				CharacterTransparency(Model, 0)
			end)
		else
			-- Create Ryuk
			local Ryuk = script.Ryuk:Clone()
			CharacterTransparency(Ryuk, 1)
			Ryuk.UserWeld.Part0 = RootPart
			--Ryuk.HumanoidRootPart.CFrame = RootPart.CFrame
			Ryuk.Parent = Model

			-- Play Animation
			local RyukAnim = Ryuk.Humanoid.Animator:LoadAnimation(Animations.Obtainment.Ryuk)
			RyukAnim.Priority = Enum.AnimationPriority.Action2
			RyukAnim:Play()
			
			-- Play Idle
			local RyukIdle = Ryuk.Humanoid.Animator:LoadAnimation(Animations.Idle.Ryuk)
			RyukIdle.Priority = Enum.AnimationPriority.Action
			RyukIdle.Looped = true
			RyukIdle:Play()
			
			Job:Task(RyukAnim:GetMarkerReachedSignal("Appear"):Once(function()
				CharacterTransparency(Ryuk, 0)
			end))
			
			Job:Task(RyukAnim:GetMarkerReachedSignal("End"):Once(function()
				RyukAnim:Stop(0.6)
			end))
		end
	end,
}