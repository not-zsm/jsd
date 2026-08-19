local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

return {
	Feint = function(Model : Model, Duration : number)
		local Highlight = Instance.new("Highlight")
		Highlight.OutlineTransparency = 0.5
		Highlight.FillTransparency = 0.5
		Highlight.OutlineColor = Color3.new(1, 0, 0)
		Highlight.FillColor = Color3.new(1, 1, 1)
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.Parent = Model
		
		if EffectUtility.Distance_Close(Model, 15) then
			CameraShake(0.75, 10, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.25)
			Vignette(Color3.fromRGB(255, 255, 255), 0.8, 0.25)
		end
		
		EffectUtility.EmitEffects(script.SFX, Model.PrimaryPart)

		task.delay(0.1, function()
			Highlight.OutlineTransparency = 1
		end)
		
		--TweenService:Create(Highlight, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		--	{OutlineTransparency = 1}
		--):Play()
		
		task.delay(Duration, function()
			local Tween = TweenService:Create(Highlight, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{FillTransparency = 1}
			)
				
			Tween:Play()
			
			Tween.Completed:Once(function()
				Highlight:Destroy()
			end)
		end)
	end,
}