--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local TweenService = game:GetService('TweenService');

local Players = game:GetService("Players")

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local VFX = {};

function VFX.Hit(AttackerRootPart : BasePart, VictimRootPart : BasePart)
	EffectUtility.EmitEffects(script.Hit, VictimRootPart)

	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)

	if (Distance < 10) then
		ScreenPulse("Bio Electric Burst Hit")
		CameraShake(3, 20, 0.1, 0.25, Vector3.one * 0.8)
	end

	if Distance < 75 then
		Blood.BloodRays("SpitOut", VictimRootPart.Parent.Head.MouthAttachment)
	end
end

return VFX