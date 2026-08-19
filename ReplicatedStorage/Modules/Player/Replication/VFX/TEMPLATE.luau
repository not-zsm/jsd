local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks -- put anim folder

---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local Afterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.Afterimage )
local ATrainAfterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.ATrainAfterimage )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )

---------------------------------------------------------------------


return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, MainJob = Retrieved.Animation, Retrieved.Job
		
		MainJob:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
			local Effect = script.Assets:FindFirstChild(Parameter)

			if Effect and EffectUtility.Distance_Far(Model) then
				EffectUtility.Arc.CloneAndEmit(Effect, Model[Effect:GetAttribute("attached")])
			end
		end))
	end,
	
	Hit = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Hit)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, MainJob = Retrieved.Animation, Retrieved.Job
		
		MainJob:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
			local Effect = script.Assets:FindFirstChild(Parameter)

			if Effect and EffectUtility.Distance_Far(Model) then
				EffectUtility.Arc.CloneAndEmit(Effect, Model[Effect:GetAttribute("attached")])
			end

		end))
	end,
}