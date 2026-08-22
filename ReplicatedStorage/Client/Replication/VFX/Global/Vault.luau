local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )

local VFX = {}

function VFX.SFX(RootPart : BasePart, Client : boolean)
	if not Client and Players.LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then return end

	EffectUtility.EmitEffects(script.SFX, RootPart)
end

return VFX

