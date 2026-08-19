local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

return {
	FAH = function(Model : Model)
		if EffectUtility.Distance_Close(Model, 60) then
			CameraShake(10, 100, 0.01, 0.2, Vector3.one, Vector3.one)
			Vignette(Color3.fromRGB(255, 0, 0), 0, 0.2)
			Lighting.ExposureCompensation += 10
			TweenService:Create(Lighting, TweenInfo.new(0.5), {ExposureCompensation = Lighting.ExposureCompensation - 10}):Play()
		end
	end,
}