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
		local retrieved = AnimationRetriever.new(character, ReplicatedStorage.Animations.Attacks.Anubis["Crypt Cutter"].Windup)
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
		
		local SFX = add(EffectUtility.AddSFX(script.SFX, root_part, 0.5))
		SFX.PlaybackSpeed = 1
		
		add(track:GetMarkerReachedSignal("Hitbox"):Connect(function(Data)
			SFX.PlaybackSpeed = 1.25
			
			if EffectUtility.Distance_Close(character) then
				CameraShake(1, 10, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.25)
				Vignette(Color3.new(0.639216, 0.0588235, 1), 0.75, 0.2)
			end
		end))
		
		add(track:GetMarkerReachedSignal("Emit"):Connect(function(effect_name)
			if not is_in_range(150) then
				return
			end

			BugoVFX(EffectFolder:FindFirstChild(effect_name), root_part)
		end))
		
		if is_me then
			add(track:GetMarkerReachedSignal("Boost"):Connect(function(data)
				local final = (data == "true")
				
				local forward_velocity = add(VelocityUtil.Create(root_part, "Crypt Cutter Boost"))
				forward_velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
				forward_velocity.Parent = root_part

				local velocity_strength = Instance.new("NumberValue")
				velocity_strength.Value = 60
				velocity_strength.Parent = forward_velocity

				TweenService:Create(velocity_strength, TweenInfo.new(final and 0.75 or 1, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
					Value = 0
				}):Play()

				Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, forward_velocity, function()
					forward_velocity.Velocity = root_part.CFrame.LookVector * velocity_strength.Value
				end)

				task.delay(final and 0.4 or 1.25, forward_velocity.Destroy, forward_velocity)
			end))
		end
	end,
	
	Emit = function(target_part : BasePart, effect_name : string)
		BugoVFX(EffectFolder:FindFirstChild(effect_name), target_part)
	end,
}