local VFX = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

function VFX.HeadHit(Torso : BasePart)
	if (Torso == nil or Torso.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(Torso.Position)
	
	if (Distance > 75) then return end
	
	local Head : BasePart = Torso.Parent.Head
	
	EffectUtility.EmitEffects(script.HeadHit, Head)
end 

function VFX.Hit(Torso : BasePart)
	if (Torso == nil or Torso.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(Torso.Position)

	if (Distance > 75) then return end

	EffectUtility.EmitEffects(script.Hit, Torso)
end 

return VFX