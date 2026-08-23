type Class = {
	TweenIn : {number | EnumItem | boolean}?,
	TweenOut : {number | EnumItem | boolean}?,

	LifeTime : number?,

	Color : number?,

	Contrast : number?,
	Brightness : number?,
	Saturation : number?,
}

local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Table = require(replicatedStorage.Packages.Table)

return function(Data : Class)
	Data = Table.reconcile(Data or {}, {
		TweenIn = {0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In},
		TweenOut = {0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut},

		LifeTime = 0.3,

		Color = Color3.new(1, 1, 1),

		Contrast = 0,
		Brightness = 0,
		Saturation = 0,
	})

	local Effect = Instance.new("ColorCorrectionEffect")

	TweenService:Create(Effect, TweenInfo.new(unpack(Data.TweenIn)), {
		TintColor = Data.Color;
		Contrast = Data.Contrast;
		Brightness = Data.Brightness;
		Saturation = Data.Saturation,
	}):Play()

	Effect.Parent = Lighting
	
	task.delay(Data.LifeTime, function()
		if not Effect then
			return
		end
		
		TweenService:Create(Effect, TweenInfo.new(unpack(Data.TweenOut)), {
			Contrast = 0;
			Brightness = 0;
			Saturation = 0,
			TintColor = Color3.new(1, 1, 1);
		}):Play()

		task.delay(Data.TweenOut[1] + 0.1, Effect.Destroy, Effect)
	end)
	
	return Effect
end