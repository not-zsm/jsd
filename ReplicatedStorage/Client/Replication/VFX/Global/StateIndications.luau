local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local Distort = require( ReplicatedStorage.Client.Replication.Global.Distort )

local VFX = {}

function VFX.IFrames(RootPart : BasePart)
	if not LocalPlayer:GetAttribute("Hit_IFrame_Effect") then return end
	
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance < 75) then
		Distort{Character = RootPart.Parent, Rate = 6}
		EffectUtility.EmitEffects(script.IFrames, RootPart)
	end
end

return VFX
