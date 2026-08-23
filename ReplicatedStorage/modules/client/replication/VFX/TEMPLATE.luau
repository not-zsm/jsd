local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = replicatedStorage.Animations.Attacks -- put anim folder

---------------------------------------------------------------------

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

local Yuki_FOV = require( replicatedStorage.modules.client.replication.Global.Yuki_FOV )

local Afterimage = require( replicatedStorage.modules.client.replication.Global.Afterimage )
local ATrainAfterimage = require( replicatedStorage.modules.client.replication.Global.ATrainAfterimage )

---------------------------------------------------------------------

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local VelocityUtil = require( replicatedStorage.modules.shared.Game.Velocity.VelocityUtil )

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