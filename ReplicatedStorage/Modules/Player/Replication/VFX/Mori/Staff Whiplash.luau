local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Mori["Staff Whiplash"]

--------------------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

--------------------------------------------------------------------------------

local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Dojyan_Util = require( ReplicatedStorage.Modules.Player.Replication.Global.Dojyan_Util )
local MeshEmit = require( ReplicatedStorage.Modules.Player.Replication.Global.Dojyan_Util.MeshEmit )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

--------------------------------------------------------------------------------

return {
	["Start"] = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local MainAnimation, MainJob = Retrieved.Animation, Retrieved.Job
		local RootPart, Torso = Retrieved.RootPart, Retrieved.Torso
		
		local Medium_Pole = script.Medium_Poll:Clone()
		local Big_Pole = script.Big_Poll:Clone()
		local Very_Big_Pole = script.Very_Big_Poll:Clone()
		
		for _, Pole in {Medium_Pole, Big_Pole, Very_Big_Pole} do
			for _, Item in ipairs(Pole:GetChildren()) do
				local Weld = Item:FindFirstChildOfClass("Motor6D")
				
				if Weld then
					Weld.Part0 = RootPart
				end
			end
			
			Pole.Parent = Model
		end
		
		MainJob:Task(Medium_Pole)
		MainJob:Task(Big_Pole)
		MainJob:Task(Very_Big_Pole)
	end,
}