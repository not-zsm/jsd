--//Variables
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local TweenService = game:GetService('TweenService');
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local DepthOfField = require(ReplicatedStorage.Modules.Player.Replication.Global.DepthOfField)
local Vignette = require(ReplicatedStorage.Modules.Player.Replication.Global.Vignette)

local BugoVFX = require(ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo)
local Blood = require(ReplicatedStorage.Modules.Player.Replication.Global.Blood)

local AnimationRetriever = require(ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever)

local VFX = {};

function VFX.Hit(AttackerRootPart : BasePart, victim_root_part : BasePart)
	BugoVFX(script.Hit, victim_root_part)
	
	EffectUtility.EmitEffects(script.SFX, victim_root_part)

	local distsance_from_target = Players.LocalPlayer:DistanceFromCharacter(victim_root_part.Position)

	if (distsance_from_target < 20) then
		CameraShake(2, 4, 0.05, 0.75, vector.create(0.65, 0.65, 0.65))
		Vignette(Color3.new(0.639216, 0.0588235, 1), 0.55, 0.15)
	end
	
	if (distsance_from_target < 100) then
		EffectUtility.EmitEffects(script.SFX.FrontDashHit, victim_root_part)
	end
	
	if (distsance_from_target < 75) then
		Blood.BloodRays("SpitOut", victim_root_part.Parent.Head.MouthAttachment)
	end
end

function VFX.HitAnimStarted(model : Model)
	local retrieved_animation = AnimationRetriever.new(model, ReplicatedStorage.Animations.Attacks.Global.Dash.Anubis.Hit)

	if (retrieved_animation == nil) then
		return
	end
	
	local root_part = retrieved_animation.RootPart
	local retrieved_track = retrieved_animation.Animation

	local target_duration = 5/60

	local start_clock = os.clock()

	while (retrieved_track.IsPlaying) and (retrieved_track.TimePosition < target_duration) and (os.clock() - start_clock < 1) do
		task.wait()
	end

	if not retrieved_track.IsPlaying then
		return
	end

	if (Players.LocalPlayer:DistanceFromCharacter(root_part.Position) < 50) then
		BugoVFX(script.Slash, root_part)
	end
end

function VFX.Start(RootPart : BasePart)
	local distsance_from_target = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if (distsance_from_target < 100) then
		EffectUtility.EmitEffects(script.SFX.Dash, RootPart)
	end
end

return VFX