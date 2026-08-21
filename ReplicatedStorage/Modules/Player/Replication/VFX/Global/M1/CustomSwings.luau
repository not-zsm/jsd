local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effects = ReplicatedStorage.Effects
local CharacterEffects = Effects.Characters

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local BugoVFX = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local AnimationRetriever = require(ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever)

return {
	["Chara"] = function(RootPart : BasePart, Count : number, Distance : number)
		if Count == 2 or Count == 4 then
			local Knife : Model = RootPart.Parent:FindFirstChild("Knife")
			if (Knife == nil) then return end

			EffectUtility.EmitEffects(CharacterEffects.Chara.Swing, RootPart)
			Knife.Handle.BladeAttachment.Trail.Enabled = true

			task.delay(0.05, function()
				if Count == 2 then
					local Effect = CharacterEffects.Chara.Assets.slash:Clone()
					Effect.Parent = RootPart
					EffectUtility.Emit(Effect)

				elseif Count == 4 then
					local Effect = CharacterEffects.Chara.Assets.finalm1swing:Clone()
					Effect.Parent = RootPart
					EffectUtility.Emit(Effect)
				end
			end)

			task.delay(0.3, function()
				Knife.Handle.BladeAttachment.Trail.Enabled = false
			end)
		end
	end,
}
