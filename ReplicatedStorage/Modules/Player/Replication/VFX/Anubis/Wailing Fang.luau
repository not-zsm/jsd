local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local AnimationRetriever = require(ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever)
local DepthOfField = require(ReplicatedStorage.Modules.Player.Replication.Global.DepthOfField)
local CameraShake = require(ReplicatedStorage.Modules.Player.Replication.Global.CameraShake)
local RockHandler = require(ReplicatedStorage.Modules.Player.Replication.Global.RockHandler)
local VelocityUtil = require(ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil)
local EffectUtility = require(ReplicatedStorage.Modules.Player.Replication.EffectUtility)
local BugoVFX = require(ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo)
local Vignette = require(ReplicatedStorage.Modules.Player.Replication.Global.Vignette)
local Yuki_FOV = require(ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV)
local Utility = require(ReplicatedStorage.Modules.Shared.Utilities.Utility)
local Table = require(ReplicatedStorage.Packages.Table)

local EffectFolder = script.Effects

local function get_max_lifetime(item : Instance | {})
	if typeof(item) == "Instance" and item:GetAttribute("Lifetime") then
		return item:GetAttribute("Lifetime")
	else
		local max_lifetime = 0

		local directory = if typeof(item) == "Instance" then item:GetDescendants() else item

		for _, emitter in directory do
			if typeof(emitter) ~= "Instance" then
				continue
			end

			if not emitter:IsA("ParticleEmitter") then
				continue
			end

			local emitter_attributes = emitter:GetAttributes()

			local emit_duration = emitter_attributes["EmitDuration"] or 0
			local emit_delay =  emitter_attributes["EmitDelay"] or 0
			local lifetime = (emitter.Lifetime.Max + emit_duration + emit_delay) / emitter.TimeScale

			if emitter_attributes["Lifetime"] then
				lifetime = math.max(lifetime, emitter_attributes["LifeTime"])
			end

			if max_lifetime < lifetime and lifetime < 1e999 then
				max_lifetime = lifetime
			end
		end

		return max_lifetime
	end
end

return {
	Start = function(character : Model)
		local retrieved = AnimationRetriever.new(character, ReplicatedStorage.Animations.Attacks.Anubis["Wailing Fang"].Ground)
		if (retrieved == nil) then return end
		
		local root_part = retrieved.RootPart
		local track = retrieved.Animation
		
		local is_me = (LocalPlayer.Character == character)
		
		local function add<T>(object : T) : T
			return retrieved.Job:Task(object)
		end
		
		local function is_in_range(desired_range : number?)
			desired_range = desired_range or 50
			
			if is_me then
				return true
			end
			
			return LocalPlayer:DistanceFromCharacter(root_part.Position) <= desired_range
		end
		
		add(track:GetMarkerReachedSignal("Emit"):Connect(function(effect_name)
			if not is_in_range(150) then
				return
			end
			
			BugoVFX(EffectFolder:FindFirstChild(effect_name), root_part)
			
			if is_in_range(20) and effect_name:match("Slash") then
				CameraShake(1.5, 15, 0.05, 0.4, Vector3.one * 0.8)
				Vignette(Color3.new(0.639216, 0.0588235, 1), 0.55, 0.15)

				DepthOfField({
					TweenIn = {0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out},
					TweenOut = {0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out},
					
					LifeTime = 0,
					
					FarIntensity = 0.1,
					FocusDistance = 0,
					InFocusRadius = 10,
					NearIntensity = 0,
				})
				
			elseif is_in_range(10) and effect_name:match("Step") then
				CameraShake(1, 0.5, 0.05, 0.75, vector.create(0.15, 0.15, 0.15))
			end
		end))
	end,
	
	Emit = function(target_part : BasePart, effect_name : string)
		BugoVFX(EffectFolder:FindFirstChild(effect_name), target_part)
		EffectUtility.AddSFX(script.HitSound.SFX, target_part)
	end,
}