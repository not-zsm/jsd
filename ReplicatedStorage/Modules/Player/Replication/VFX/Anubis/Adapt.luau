local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )
local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Anubis.Adapt
local Afterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.Afterimage )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local AfterimageVanishInfo = {0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out}
local AfterimageMoveInfo = {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out}

local KillBuffs = {}

local function Afterimage_Effect(Afterimage : Model)
	local Highlight = Instance.new("Highlight")
	Highlight.FillColor = Color3.fromRGB(164, 7, 255)
	Highlight.FillTransparency = 0.6
	Highlight.OutlineTransparency = 1
	Highlight.Parent = Afterimage

	local Tween = TweenService:Create(Highlight, TweenInfo.new(table.unpack(AfterimageVanishInfo)),
		{FillTransparency = 1}
	)

	Tween:Play()

	Tween.Completed:Once(function()
		Highlight:Destroy()
	end)
end

return {
	Highlight = function(Model : Model, Sword : Model, Progress : number)
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		if EffectUtility.Distance_Far(Model) then
			local Highlight = Instance.new("Highlight")

			Highlight.FillColor = Color3.fromRGB(153, 64, 255)
			Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			Highlight.FillTransparency = 0.4
			Highlight.Parent = Sword

			TweenService:Create(Highlight, TweenInfo.new(0.8), {FillTransparency = 1, OutlineTransparency = 1}):Play()
			task.delay(0.8, Highlight.Destroy, Highlight)
		end
		
		if IsMainPlayer then
			Vignette(Color3.new(0.6, 0.25098, 1), 0.8, 1)
			
			local SFX
			
			if (Progress == 1) then
				SFX = script.Progress1
				
			elseif (Progress == 2) then
				SFX = script.Progress2
				
			elseif (Progress == 3) then
				SFX = script.Progress3
			end
			
			EffectUtility.AddSFX(SFX, SoundService, 0.3)
		end	
	end,
	
	Dodge = function(Model : Model, AnimName : String)
		local Retrieved = AnimationRetriever.new(Model, Animations[AnimName])
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		
		if EffectUtility.Distance_Far(Model) then
			local Highlight = Instance.new("Highlight")

			Highlight.FillColor = Color3.fromRGB(153, 64, 255)
			Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			Highlight.FillTransparency = 0.6
			Highlight.Parent = Model
			
			TweenService:Create(Highlight, TweenInfo.new(0.6), {FillTransparency = 1, OutlineTransparency = 1}):Play()
			task.delay(0.6, Highlight.Destroy, Highlight)
			
			local AfterImageThread = coroutine.create(function()
				for i = 1, 4 do
					Afterimage(Model, AfterimageVanishInfo, AfterimageMoveInfo, 2, Afterimage_Effect)
					task.wait(.06)
				end
			end)

			Job:Task(AfterImageThread)
			coroutine.resume(AfterImageThread)
		end
		
		if IsMainPlayer then
			Vignette(Color3.new(0.6, 0.25098, 1), 0.8, 0.5)
		end
		
		Job:Task(EffectUtility.AddSFX(script.Dash[`Dash{math.random(1, 3)}`], RootPart, 0.3))
	end,
	
	KillHighlight = function(Model : Model, Sword : Table, BuffDuration : Number)
		local IsMainPlayer = (LocalPlayer.Character == Model)
		local Highlight = Instance.new("Highlight")

		if EffectUtility.Distance_Far(Model) then
			Highlight.OutlineColor = Color3.new(1, 0, 0)
			Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			Highlight.FillTransparency = 1
			Highlight.Parent = Model

			TweenService:Create(Highlight, TweenInfo.new(1), {OutlineTransparency = 1}):Play()
			task.delay(1, Highlight.Destroy, Highlight)
		end
		
		if not KillBuffs[Model] then
			local AuraVFX = {}
			
			for _, Limb in pairs(script.AuraVFX:GetChildren()) do
				for _, Particle in pairs(Limb:GetChildren()) do
					local Clone = Particle:Clone()
					Clone.Parent = Model[Limb.Name]
					table.insert(AuraVFX, Clone)
					
					Clone.Enabled = true
				end
			end
			
			
			KillBuffs[Model] = AuraVFX
		end
		
		if IsMainPlayer then
			EffectUtility.AddSFX(script.KillSFX, SoundService, 0.3)
		end
	end,
	
	DestroyBuffVFX = function(Model : Model)
		local AuraVFX = KillBuffs[Model]
		
		if AuraVFX then	
			for _, Particle in AuraVFX do
				Particle.Enabled = false
				
				task.delay(2, Particle.Destroy, Particle)
			end
		end
		
		KillBuffs[Model] = nil
	end,
}

