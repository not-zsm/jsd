local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
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
local AuraHolder = script.Aura

local can_enable = {"ParticleEmitter", "Beam", "Trail", "PointLight", "SpotLight"}

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

local function register_connections(retrieved)
	local root_part = retrieved.RootPart
	local track = retrieved.Animation

	local is_me = (LocalPlayer.Character == retrieved.Model)

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
end


return {
	OnStart = function(character : Model)
		local retrieved = AnimationRetriever.new(character, ReplicatedStorage.Animations.Attacks.Anubis["Evil Spirit"].Windup)
		if (retrieved == nil) then return end
		
		retrieved.Job:Task(EffectUtility.AddSFX(script.Start, retrieved.RootPart, 0.3))

		--retrieved.Job:Task(task.delay(4 / 60, function()
			BugoVFX(EffectFolder.StartUp, retrieved.RootPart)

			if EffectUtility.Distance_Close(character) then
				CameraShake(1, 10, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.25)
				Vignette(Color3.fromRGB(136, 0, 255), 0.75, 0.2)
			end
		--end))
	end,
	
	OnCounter = function(character : Model)
		local retrieved = AnimationRetriever.new(character, ReplicatedStorage.Animations.Attacks.Anubis["Evil Spirit"].Counter)
		if (retrieved == nil) then return end

		register_connections(retrieved)

		local stand = retrieved.Job:Task(require(script.Parent.ClientSpirit).RigSpirit(character))
		
		local stand_track = stand.Controller.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Anubis["Evil Spirit"].Stand)
		stand_track:Play()
		
		for _, possible_effect in stand:GetDescendants() do
			if not table.find(can_enable, possible_effect.ClassName) then
				continue
			end

			possible_effect.Enabled = true
		end
		
		retrieved.Job:Task(task.spawn(function()
			while stand and stand_track.IsPlaying and retrieved.Animation.IsPlaying do
				if retrieved.Animation.TimePosition > stand_track.Length then
					break
				end
				
				stand_track.TimePosition = retrieved.Animation.TimePosition
				task.wait()
			end
		end))
		
		retrieved.Job:Task(stand_track.Ended:Once(function()
			if stand then
				stand:Destroy()
			end
		end))
	end,

	OnVictimCountered = function(character : Model)
		local retrieved = AnimationRetriever.new(character, ReplicatedStorage.Animations.Global.GrabVictims.EvilSpiritVictim)
		if (retrieved == nil) then return end

		register_connections(retrieved)

		retrieved.Job:Task(EffectUtility.AddSFX(script.Counter, retrieved.RootPart, 1))

		local aura_instances = Table.weak_values({})
		
		retrieved.Job:Task(retrieved.Animation:GetMarkerReachedSignal("Aura"):Connect(function(aura_state)
			if aura_state == "Enable" then
				for _, aura_part in AuraHolder:GetChildren() do
					if not character:FindFirstChild(aura_part.Name) then
						continue
					end

					for _, aura_item in aura_part:GetChildren() do
						local cloned_item = retrieved.Job:Task(aura_item:Clone())
						table.insert(aura_instances, cloned_item)

						if table.find(can_enable, cloned_item.ClassName) then
							cloned_item.Enabled = true
						end

						for _, possible_effect in cloned_item:GetDescendants() do
							if not table.find(can_enable, possible_effect.ClassName) then
								continue
							end

							possible_effect.Enabled = true
						end

						cloned_item.Parent = character:FindFirstChild(aura_part.Name)
					end
				end
			elseif aura_state == "Disable" then
				for _, aura_instance in aura_instances do
					aura_instance:Destroy()
				end
			end
		end))
	end,

	Emit = function(target_part : BasePart, effect_name : string)
		BugoVFX(EffectFolder:FindFirstChild(effect_name), target_part)
	end,
}