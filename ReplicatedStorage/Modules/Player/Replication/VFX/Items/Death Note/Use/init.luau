local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer


---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local CharacterTransparency = require( ReplicatedStorage.Modules.Player.Replication.Global.CharacterTransparency )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local JobModule = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local MeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.DojyanMeshEmit )
---------------------------------------------------------------------

local Book = nil

return {
	Destroy = function()
		if Book then
			Book:Destroy()
		end
	end,
	
	Open = function(Model : Model)
		if not Book then
			Book = require(script.NoteModule).new()
		end
		
		Book:Show()
	end,
	
	Close = function(Model : Model)
		Book:Hide()
	end,
}