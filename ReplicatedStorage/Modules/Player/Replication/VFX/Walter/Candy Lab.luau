local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer;

local Assets = script.Assets;
local Rnd = Random.new();

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
--local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Flashbang = require( ReplicatedStorage.Modules.Player.Replication.Global.Flashbang )
local ProjectileHandler = require( ReplicatedStorage.Projectiles.ProjectileHandler )

local Animations = ReplicatedStorage.Animations.Attacks.Walter["Candy Lab"]

return {
	["Cough"] = function(RootPart: BasePart)
		AenoirEmit(Assets.Cough, RootPart);
	end,
};