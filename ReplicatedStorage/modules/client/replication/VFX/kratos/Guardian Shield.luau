local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = replicatedStorage.animations.Attacks.kratos["Guardian Shield"]

---------------------------------------------------------------------

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

---------------------------------------------------------------------

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

---------------------------------------------------------------------

return {
	Form = function(Model : Model)
		local Shield : Model? = Model:WaitForChild("Shield", 2) -- streaming enabled momento
		Shield:ScaleTo(0.001)

		local Alpha = 0
		local Min = 0.0001
		
		local Connection : RBXScriptConnection; Connection = RunService.PreRender:Connect(function(Delta)
			Alpha += Delta * 1.5

			local Clamped = math.clamp(Alpha, Min, 1)
	
			if (Clamped >= 1) then
				return Connection:Disconnect()
			end

			Shield:ScaleTo(TweenService:GetValue(Clamped, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
		end)
		
		local SFX = EffectUtility.AddSFX(script.Open, Model.PrimaryPart)
		task.delay(2, SFX.Destroy, SFX)
	end,
	
	Unform = function(Model : Model)
		local Shield = Model:WaitForChild("Shield", 2) -- streaming enabled momento
		Shield:ScaleTo(1)

		local Alpha = 1
		local Min = 0.0001

		local SFX = EffectUtility.AddSFX(script.Close, Model.PrimaryPart)
		task.delay(2, SFX.Destroy, SFX)
		
		local Connection : RBXScriptConnection; Connection = RunService.PreRender:Connect(function(Delta)
			Alpha -= Delta * 2

			local Clamped = math.clamp(Alpha, Min, 1)

			if (Clamped <= Min) then
				return Connection:Disconnect()
			end

			Shield:ScaleTo(TweenService:GetValue(Clamped, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
		end)
	end,
	
	Parry = function(Parrier : Model, Victim : Model)
		local SFX = EffectUtility.AddSFX(script.Parry, Parrier.PrimaryPart)
		task.delay(2, SFX.Destroy, SFX)
		
		local Highlight = Instance.new("Highlight")
		Highlight.OutlineTransparency = 1
		Highlight.FillTransparency = 0
		Highlight.FillColor = Color3.new(1, 0.529412, 0.145098)
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.Parent = Parrier
		
		local RedHighlight = Instance.new("Highlight")
		RedHighlight.OutlineTransparency = 1
		RedHighlight.FillTransparency = 0
		RedHighlight.FillColor = Color3.new(1, 0, 0)
		RedHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
		RedHighlight.Parent = Victim
		
		TweenService:Create(Highlight, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{FillTransparency = 1}
		):Play()
		
		TweenService:Create(RedHighlight, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{FillTransparency = 1}
		):Play()
		
		task.delay(0.35, Highlight.Destroy, Highlight)
		task.delay(0.35, RedHighlight.Destroy, RedHighlight)
		
		if LocalPlayer:DistanceFromCharacter(Parrier.PrimaryPart.Position) <= 20 then
			CameraShake(1.5, 20, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.2)
			
			Lighting.ExposureCompensation += 0.75

			TweenService:Create(Lighting, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
				{ExposureCompensation = 0}
			):Play()
		end
	end,
		
}