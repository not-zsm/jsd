local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

function VFX.Stab(RootPart : BasePart)
	-- Base Stab VFX
	EffectUtility.CloneAndEmit(script.Assets.stab, RootPart)
	
	-- Red Vignette
	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
		Vignette(Color3.fromRGB(255, 0, 0), 0.85, 0.5)
	end
	
	-- CameraShake
	if (LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 15) then
		CameraShake(2, 30, 0.015, 0.2, Vector3.one * 0.8)
	end
end

function VFX.StabHit(VictimRootpart : BasePart)
	Blood.BloodRays("SpitOut", VictimRootpart)
end

return VFX
