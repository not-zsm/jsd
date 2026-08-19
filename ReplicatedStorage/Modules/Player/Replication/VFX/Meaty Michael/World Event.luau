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

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Velocities = require( ReplicatedStorage.BuildTools.Build.Velocities )
local AenoirEmit = EffectUtility.AenoirEmit

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Flashbang = require( ReplicatedStorage.Modules.Player.Replication.Global.Flashbang )
local Maid = require( ReplicatedStorage.Packages.Maid )

return {
	["Blast"] = function(Coordinate: CFrame)
		local MaxDistance = 1_000;
		local Distance = Player:DistanceFromCharacter(Coordinate.Position);
		local Taper = 1 - math.clamp(Distance, 150, MaxDistance) / MaxDistance;
		
		if Distance < MaxDistance then
			CameraShake(17.50 * Taper, 30, 0.01, 3, Vector3.one * 1.75, Vector3.one * 1.25 * Taper)
		end;
		
		Flashbang.create_flash({ 
			range = MaxDistance,
			inner_range = 125,
			only_screen_effect = true;
			distance = Distance,
			position = Coordinate.Position;
		});
		
		local Correction = Instance.new("ColorCorrectionEffect")
		Correction.Parent = Lighting;
		
		local CorrectionTween = TweenService:Create(Correction, TweenInfo.new(0.25), {TintColor = Color3.fromRGB(255, 162, 125), Brightness = 0.65 * Taper, Contrast = 6 * Taper})
		CorrectionTween:Play();

		CorrectionTween.Completed:Once(function()
			local Tween = TweenService:Create(Correction, TweenInfo.new(3), {TintColor = Color3.fromRGB(255, 255, 255); Brightness = 0; Contrast = 0})
			Tween:Play();
			Tween.Completed:Wait();

			Correction:Destroy();
		end);
	end,
};