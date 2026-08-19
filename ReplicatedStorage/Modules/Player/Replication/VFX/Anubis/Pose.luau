local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )
local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Anubis.Pose
local Afterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.Afterimage )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

return {
	Start = function(Model : Model, TimeUntilHealing : Number)
		local Retrieved = AnimationRetriever.new(Model, Animations.Loop)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		
		local AuraVFX = Job:Task(script.aura:Clone())
		AuraVFX.Weld.Part0 = RootPart
		AuraVFX.Parent = workspace.Visuals
		
		EffectUtility.Toggle(AuraVFX, true)
		
		local MenaceVFX = Job:Task(script.menace.menace:Clone())
		MenaceVFX.Parent = AuraVFX
		
		Job:Task(EffectUtility.AddSFX(script[`Song{math.random(1, 2)}`], RootPart, 0.5))
		
		if AuraVFX then
			AuraVFX.menace.Enabled = true
		end
		
		--Job:Task(function()
		--	EffectUtility.Toggle(AuraVFX, false)
		--	task.delay(2, AuraVFX.Destroy, AuraVFX)
		--end)
		
		--Job:Task(task.delay(TimeUntilHealing, function()
		--	if AuraVFX then
		--		AuraVFX.menace.Enabled = true
		--	end
		--end))
	end,
}

