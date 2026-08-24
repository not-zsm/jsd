local replicatedStorage = game:GetService("ReplicatedStorage")

local Effects = replicatedStorage.modules.effect.assets
local CharacterEffects = Effects.Characters

local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )

local ScreenPulse = require( replicatedStorage.modules.client.replication.Global.ScreenPulse )

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local BugoVFX = require( replicatedStorage.modules.client.replication.EffectUtility.Bugo )

return {
	["chara"] = function(RootPart : BasePart, Type : string)
		local Knife : Model = RootPart.Parent:FindFirstChild("Knife")
		if (Knife == nil) then return end
		
		if Type == "Up" then
			Knife.Handle.BladeAttachment.Trail.Enabled = true

			task.delay(10 / 60, function()
				EffectUtility.EmitEffects(CharacterEffects.chara.Swing, RootPart)
			end)
				
			task.delay(20 / 60, function()
				local Effect = CharacterEffects.chara.Assets.uppercutslash:Clone()
				Effect.Parent = RootPart
				EffectUtility.Emit(Effect)
			end)

			task.delay(1, function()
				Knife.Handle.BladeAttachment.Trail.Enabled = false
			end)
		end
	end,
}
