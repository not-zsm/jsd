local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effects = ReplicatedStorage.modules.effect.assets
local CharacterEffects = Effects.Characters

local Blood = require( ReplicatedStorage.modules.client.replication.Global.Blood )
local CameraShake = require( ReplicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.modules.client.replication.Global.Vignette )

local BugoVFX = require( ReplicatedStorage.modules.client.replication.EffectUtility.Bugo )

local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )

local AnimationRetriever = require(ReplicatedStorage.modules.client.replication.VFX.AnimationRetriever)

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
