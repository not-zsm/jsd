type Class = {
	TweenIn : {number | EnumItem | boolean}?,
	TweenOut : {number | EnumItem | boolean}?,

	LifeTime : number?,

	FarIntensity : number?,
	FocusDistance : number?,
	InFocusRadius : number?,
	NearIntensity : number?,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Table = require(ReplicatedStorage.Packages.Table)

return function(Data : Class)
	Data = Table.reconcile(Data or {}, {
		TweenIn = {0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In},
		TweenOut = {0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut},

		LifeTime = 0.3,

		FarIntensity = 0.75,
		FocusDistance = 0.05,
		InFocusRadius = 10,
		NearIntensity = 0.75,
	})

	local Effect = Instance.new(`DepthOfFieldEffect`)

	TweenService:Create(Effect, TweenInfo.new(unpack(Data.TweenIn)), {
		FarIntensity = Data.FarIntensity,
		FocusDistance = Data.FocusDistance,
		InFocusRadius = Data.InFocusRadius,
		NearIntensity = Data.NearIntensity,
	}):Play()

	Effect.Parent = Lighting
	
	task.delay(Data.LifeTime, function()
		if not Effect then
			return
		end
		
		TweenService:Create(Effect, TweenInfo.new(unpack(Data.TweenOut)), {
			FarIntensity = 0,
			FocusDistance = 0,
			InFocusRadius = 0,
			NearIntensity = 0,
		}):Play()

		task.delay(Data.TweenOut[1] + 0.1, Effect.Destroy, Effect)
	end)
	
	return Effect
end