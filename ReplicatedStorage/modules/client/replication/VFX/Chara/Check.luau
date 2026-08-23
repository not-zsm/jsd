local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CameraShake = require( ReplicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.modules.client.replication.Global.Vignette )

local Yuki_FOV = require( ReplicatedStorage.modules.client.replication.Global.Yuki_FOV )

local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )

local AnimationRetriever = require( ReplicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Chara.Check

local function InvisibleModel(Model : Model, Value : boolean)
	local Transparent = (Value and 1 or 0)
	
	for _, Item in ipairs(Model:GetDescendants()) do
		if Item:IsA("BasePart") then
			Item.Transparency = Transparent
		end
	end
end

return {
	Target = function(Attacker : Model, Target : Model, Debuff_Time : number)
		local IsMainPlayer = (LocalPlayer.Character == Attacker or LocalPlayer.Character == Target)

		if IsMainPlayer then
			CameraShake(1.5, 30, 0.01, 0.5, Vector3.one * 0.8, Vector3.one * 0.45)
			Vignette(Color3.fromRGB(253, 0, 0), 0.45, 0.5)

			Yuki_FOV.Set(50)
			Yuki_FOV.Tween(70, {0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
			
			local Highlight = Instance.new("Highlight")
			Highlight.FillTransparency = 1
			Highlight.OutlineTransparency = 1
			Highlight.FillColor = Color3.fromRGB(255, 24, 24)
			Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
			Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			Highlight.Parent = Target

			local UI = script.UI:Clone()
			UI.Name = "DEFReduced"
			UI.Value.TextTransparency = 1
			UI.Value.UIStroke.Transparency = 1
			UI.Parent = Target.Torso
			
			TweenService:Create(UI.Value, TweenInfo.new(0.1),
				{TextTransparency = 0}
			):Play()

			TweenService:Create(UI.Value.UIStroke, TweenInfo.new(0.1),
				{Transparency = 0}
			):Play()
			
			TweenService:Create(Highlight, TweenInfo.new(0.15),
				{FillTransparency = 0.6, OutlineTransparency = 0.6}
			):Play()

			task.delay(Debuff_Time, function()
				TweenService:Create(UI.Value, TweenInfo.new(0.75),
					{TextTransparency = 1}
				):Play()

				TweenService:Create(UI.Value.UIStroke, TweenInfo.new(0.75),
					{Transparency = 1}
				):Play()

				TweenService:Create(Highlight, TweenInfo.new(0.75),
					{FillTransparency = 1, OutlineTransparency = 1}
				):Play()

				task.delay(0.75, UI.Destroy, UI)
				task.delay(0.75, Highlight.Destroy, Highlight)
			end)
			
			EffectUtility.AddSFX(script.Hit_SFX, Target.PrimaryPart)
		end
		
		local Retrieved = AnimationRetriever.new(Attacker, Animations.Success)
		
		if (Retrieved ~= nil) then
			local function Toggle_Knife(Value : boolean)
				local Knife = Attacker:FindFirstChild("Knife")
				
				if Knife then
					Knife.Handle.BladeAttachment.Trail.Enabled = Value
				end
			end
			
			Retrieved.Job:Task(EffectUtility.AddSFX(script.Flourish, Retrieved.Torso, 0.5))

			Retrieved.Job:Task(function()
				Toggle_Knife(false)
			end)

			Toggle_Knife(true)
		end
	end,
	
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end
		
		local Animation = Retrieved.Animation
		local MainJob = Retrieved.Job

		local Act = script["act button"]:Clone()
		Act.Weld.Part0 = Retrieved.RootPart
		Act.Parent = Model
		
		local Check = script["check button"]:Clone()
		Check.Weld.Part0 = Retrieved.RootPart
		Check.Parent = Model
		
		Retrieved.Job:Task(Act)
		Retrieved.Job:Task(Check)

		InvisibleModel(Check, true)
		
		local function Toggle_Knife(Value : boolean)
			local Knife = Model:FindFirstChild("Knife")

			if Knife then
				Knife.Handle.BladeAttachment.Trail.Enabled = Value
			end
		end
	
		MainJob:Task(function()
			Toggle_Knife(false)
		end)
		
		Retrieved.Job:Task(EffectUtility.AddSFX(script.Start_SFX, Retrieved.Torso, 0.5))

		Toggle_Knife(true)
		
		local IsMainPlayer = (LocalPlayer.Character == Model)

		if IsMainPlayer then
			MainJob:Task(Animation:GetMarkerReachedSignal("act"):Connect(function()
				CameraShake(0.75, 12.5, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.fromRGB(253, 94, 14), 0.5, 0.4)

				Yuki_FOV.Set(60)
				Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
			end))
			
			MainJob:Task(Animation:GetMarkerReachedSignal("check"):Connect(function()
				CameraShake(0.75, 12.5, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.fromRGB(255, 255, 255), 0.5, 0.4)

				Yuki_FOV.Set(60)
				Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
			end))
		end
		
		MainJob:Task(Animation:GetMarkerReachedSignal("act_bye"):Connect(function()
			InvisibleModel(Act, true)
		end))
		
		MainJob:Task(Animation:GetMarkerReachedSignal("check_hi"):Connect(function()
			InvisibleModel(Check, false)
		end))
		
		MainJob:Task(Animation:GetMarkerReachedSignal("check_bye"):Connect(function()
			InvisibleModel(Check, true)
		end))
	end,
}