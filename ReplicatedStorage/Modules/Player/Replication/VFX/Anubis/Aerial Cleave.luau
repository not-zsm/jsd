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
		local retrieved = AnimationRetriever.new(character, ReplicatedStorage.Animations.Attacks.Anubis["Wailing Fang"].Cleave)
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
		end))

		add(track:GetMarkerReachedSignal("Enable"):Connect(function(effect_name)
			local effect_part = EffectFolder:FindFirstChild(effect_name)

			if not effect_part then
				return warn(`{effect_name} is not an effect for {script.Name}`)
			else
				effect_part = add(effect_part:Clone())
			end

			effect_part.Join.Part0 = root_part
			effect_part.Parent = root_part

			EffectUtility.Toggle(effect_part, true)
		end))

		add(track:GetMarkerReachedSignal("Disable"):Connect(function(effect_name)
			local effect_part = root_part:FindFirstChild(effect_name)

			if not effect_part then
				return warn(`{effect_name} is not an effect inside the rootpart`)
			end

			EffectUtility.Toggle(effect_part, false)

			task.delay(get_max_lifetime(effect_part), effect_part.Destroy, effect_part)
		end))
	end,

	Emit = function(target_part : BasePart, effect_name : string)
		BugoVFX(EffectFolder:FindFirstChild(effect_name), target_part)
	end,
}