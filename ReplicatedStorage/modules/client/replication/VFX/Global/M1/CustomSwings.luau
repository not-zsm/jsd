local replicatedStorage = game:GetService("ReplicatedStorage")

local Effects = replicatedStorage.modules.effect.assets
local CharacterEffects = Effects.Characters

local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )

local BugoVFX = require( replicatedStorage.modules.client.replication.EffectUtility.Bugo )

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

local AnimationRetriever = require(replicatedStorage.modules.client.replication.VFX.AnimationRetriever)

return {
	["chara"] = function(RootPart : BasePart, Count : number, Distance : number)
		if Count == 2 or Count == 4 then
			local Knife : Model = RootPart.Parent:FindFirstChild("Knife")
			if (Knife == nil) then return end

			EffectUtility.EmitEffects(CharacterEffects.chara.Swing, RootPart)
			Knife.Handle.BladeAttachment.Trail.Enabled = true

			task.delay(0.05, function()
				if Count == 2 then
					local Effect = CharacterEffects.chara.Assets.slash:Clone()
					Effect.Parent = RootPart
					EffectUtility.Emit(Effect)

				elseif Count == 4 then
					local Effect = CharacterEffects.chara.Assets.finalm1swing:Clone()
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
