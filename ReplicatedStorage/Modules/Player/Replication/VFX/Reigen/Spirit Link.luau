local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

local DimpleEffects = ReplicatedStorage.Effects.Characters.Reigen.Dimple

return {
	Start = function(Model : Model, Duration : number)
		local Retrieved = AnimationRetriever.new(Model, ReplicatedStorage.Animations.Attacks.Reigen["Spirit Link"].UserStart)
		if (Retrieved == nil) then return end

		local MainAnimation = Retrieved.Animation
		local Job = Retrieved.Job

		local RootPart = Retrieved.RootPart

		local Dimple = DimpleEffects.Model:Clone()
		EffectUtility.Weld(Dimple, RootPart)
		Dimple.Parent = workspace.Visuals

		local Animation = Dimple.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Reigen["Spirit Link"].Blob)
		Animation:Play(0)

		Job:Task(Dimple)

		Job:Task(MainAnimation:GetMarkerReachedSignal("possess"):Connect(function()
			Dimple:Destroy()

			EffectUtility.EmitEffects(DimpleEffects.Possess, Model.Head)

			if LocalPlayer.Character == Model then
				ScreenPulse("Dimple", false)
				CameraShake(3.5, 12.5, 0.05, 0.25)
			end

			local Aura = require(DimpleEffects.AuraScript)(Model)

			task.delay(Duration, function()
				for _, Particle in Aura do
					Particle.Enabled = false
					task.delay(1.5, Particle.Destroy, Particle)
				end
			end)
		end))
	end
}