local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Client.Replication.VFX.AnimationRetriever )


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

local VelocityUtil = require( ReplicatedStorage.Shared.Game.Velocity.VelocityUtil )
local Smoke = require( ReplicatedStorage.Client.Replication.Global.Smoke )
local Dialogue = require(ReplicatedStorage.Client.TekrinnDialogue)
---------------------------------------------------------------------

local StrokeColor = Color3.new(0, 0, 0)
local NameColor = ColorSequence.new(Color3.new(0.780392, 0.156863, 0.156863), Color3.new(0.294118, 0, 0.00392157))
local MainColor = ColorSequence.new(Color3.new(1, 0, 0))

local function Speak(Model, Phrase : number)
	if Phrase == 1 then
		Dialogue.Speak(Model, 
			{
				Text = "Don't thank me.",
				TextStrokeColor = StrokeColor,
				Color = MainColor,
				Shake = {
					Lifetime = 0.5,
					Enabled = true,
					Intensity = 3,
				},
				HigherUp = true,
				TypeSpeed = 0.038,
			}, 

			{
				StrokeColor = StrokeColor,
				Color = NameColor,
			}, 

			2
		)
	else
		Dialogue.Speak(Model, 
			{
				Text = "Please don't thank me for that.",
				TextStrokeColor = StrokeColor,
				Color = MainColor,
				Shake = {
					Lifetime = 0.5,
					Enabled = true,
					Intensity = 3,
				},
				HigherUp = true,
				TypeSpeed = 0.0275,
			}, 

			{
				StrokeColor = StrokeColor,
				Color = NameColor,
			}, 

			3
		)
	end
end

return {
	Play = function(Model : Model)
		EffectUtility.AddSFX(script.ExitSFX, SoundService, 0.01)
		
		Speak(Model, 1)
		task.wait(1.82)
		Speak(Model, 2)
	end,
}