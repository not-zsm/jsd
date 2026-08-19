local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Powers["Starflare"]

---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local JobModule = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local quickutil = require( script.quickutil )
local effects = script.effects

local BugoVFX = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo )
local Flashbang = require( ReplicatedStorage.Modules.Player.Replication.Global.Flashbang )

---------------------------------------------------------------------

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		Job:Task(EffectUtility.AddSFX(script.SFX, Torso, 0.5))
		
		local Lights = Job:Task(effects.Lights:Clone())
		for _, Light in ipairs(Lights:GetChildren()) do
			Light.Weld.Part0 = Model[Light.Name]
		end
		
		Lights.Parent = workspace.Visuals
		EffectUtility.Toggle(Lights, true)
		
		local LoopCoroutine
		
		-- Frontend
		if IsMainPlayer then
			Yuki_FOV.Tween(75, {0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In})
			Job:Task(function()
				Yuki_FOV.Set(70)
			end)

			LoopCoroutine = coroutine.create(function()
				while true do
					Vignette(Color3.new(1, 0.984314, 0.576471), 0.85, 2)
					CameraShake(1, 12, 0.05, 0.1, Vector3.one * 0.8)

					task.wait(0.1)
				end
			end)

			Job:Task(LoopCoroutine)
			task.spawn(LoopCoroutine)
		end
		
		Job:Task(Animation:GetMarkerReachedSignal("Flash"):Connect(function()
			EffectUtility.Toggle(Lights, false)
			
			EffectUtility.CloneAndEmit(effects.flashbang["1"], RootPart)
			EffectUtility.CloneAndEmit(effects.flashbang["2"], RootPart)
			
			local Light = effects.flashbang.Light:Clone()
			Light.Parent = RootPart
			Light.PointLight.Enabled = true
			TweenService:Create(Light.PointLight, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Brightness = 0}):Play()
			task.delay(1, Light.Destroy, Light)
			
			if not IsMainPlayer then
				local Position = Model.HumanoidRootPart.Position
				Flashbang.create_flash({ 
					range = 20,
					inner_range = 10,
					distance = LocalPlayer:DistanceFromCharacter(Position),
					position = Model.HumanoidRootPart.Position,
					no_lobotomy = true
				})
			else
				Yuki_FOV.Tween(70, {0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
			end
			
			if EffectUtility.Distance_Close(Model, 10) then
				if LoopCoroutine then
					task.cancel(LoopCoroutine)
				end
				
				CameraShake(7, 21, 0.03, 0.3, Vector3.one * 0.7)
				Vignette(Color3.new(1, 0.984314, 0.576471), 0.7, 2)
			end
		end))
	end
}