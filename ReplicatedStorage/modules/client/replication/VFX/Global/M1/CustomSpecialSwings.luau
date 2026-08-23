local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Effects = ReplicatedStorage.modules.effect.assets
local CharacterEffects = Effects.Characters

local Blood = require( ReplicatedStorage.modules.client.replication.Global.Blood )
local CameraShake = require( ReplicatedStorage.modules.client.replication.Global.CameraShake )

local ScreenPulse = require( ReplicatedStorage.modules.client.replication.Global.ScreenPulse )

local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )
local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )

local BugoVFX = require( ReplicatedStorage.modules.client.replication.EffectUtility.Bugo )

return {
	["Chara"] = function(RootPart : BasePart, Type : string)
		local Knife : Model = RootPart.Parent:FindFirstChild("Knife")
		if (Knife == nil) then return end
		
		if Type == "Up" then
			Knife.Handle.BladeAttachment.Trail.Enabled = true

			task.delay(10 / 60, function()
				EffectUtility.EmitEffects(CharacterEffects.Chara.Swing, RootPart)
			end)
				
			task.delay(20 / 60, function()
				local Effect = CharacterEffects.Chara.Assets.uppercutslash:Clone()
				Effect.Parent = RootPart
				EffectUtility.Emit(Effect)
			end)

			task.delay(1, function()
				Knife.Handle.BladeAttachment.Trail.Enabled = false
			end)
		end
	end,
}
