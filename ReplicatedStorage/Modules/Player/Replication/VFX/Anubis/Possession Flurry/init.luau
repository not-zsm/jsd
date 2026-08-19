local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local AnimationRetriever = require(ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever)
local ColorCorrection = require(ReplicatedStorage.Modules.Player.Replication.Global.ColorCorrection)
local RunCameraRig = require(ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig)
local DepthOfField = require(ReplicatedStorage.Modules.Player.Replication.Global.DepthOfField)
local CameraShake = require(ReplicatedStorage.Modules.Player.Replication.Global.CameraShake)
local RockHandler = require(ReplicatedStorage.Modules.Player.Replication.Global.RockHandler)
local EffectBlood = require(ReplicatedStorage.Modules.Player.Replication.VFX.Global.Blood)
local VelocityUtil = require(ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil)
local EffectUtility = require(ReplicatedStorage.Modules.Player.Replication.EffectUtility)
local BugoVFX = require(ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo)
local Vignette = require(ReplicatedStorage.Modules.Player.Replication.Global.Vignette)
local Yuki_FOV = require(ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV)
local Blood = require(ReplicatedStorage.Modules.Player.Replication.Global.Blood)
local Utility = require(ReplicatedStorage.Modules.Shared.Utilities.Utility)
local Table = require(ReplicatedStorage.Packages.Table)
local EditedBugoVFX = require(script.EditedBugoVFX)

local EffectFolder = script.Effects
local finisher_effects = script.VFX

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
		local retrieved = AnimationRetriever.new(character, ReplicatedStorage.Animations.Attacks.Anubis["Possession Flurry"].Windup)
		if (retrieved == nil) then return end
		
		local root_part = retrieved.RootPart
		local track = retrieved.Animation
		
		local is_me = (LocalPlayer.Character == character)
		local shake_ended = false
		local looping_shake
		
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
		
		local function clean_looping_shake()
			if shake_ended or looping_shake == nil then
				return
			end

			shake_ended = true
			
			looping_shake:StartFadeOut(0.2)
		end

		add(clean_looping_shake)
		
		add(track:GetMarkerReachedSignal("Emit"):Connect(function(effect_name)
			if not is_in_range(150) then
				return
			end
			
			BugoVFX(EffectFolder:FindFirstChild(effect_name), root_part)
			
			if effect_name == "FirstStab" then
				if is_in_range(10) then
					CameraShake(2, 4, 0.05, 0.75, vector.create(0.65, 0.65, 0.65))
					Vignette(Color3.new(0.639216, 0.0588235, 1), 0.75, 0.15, not is_me)
				end
				
				if is_me then
					local jab_velocity = add(VelocityUtil.Create(root_part, "Possession Flurry Jab"))
					jab_velocity.Velocity = root_part.CFrame.LookVector * 25
					jab_velocity.MaxForce = vector.create(1, 0, 1) * 80000
					jab_velocity.Parent = root_part
					
					task.delay(0.15, jab_velocity.Destroy, jab_velocity)
				end
			elseif effect_name == "Slash" then -- im adding depth of field thing rn
				if is_in_range(10) then -- oh fyre
					CameraShake(10, 20, 0.05, 0.75, vector.create(0.65, 0.65, 0.65))
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
				end
			end
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
			
			if effect_name == "Stabs" and is_me then
				looping_shake = CameraShake(2.75, 8.5, 0.1, 0, vector.create(0.65, 0.65, 0.65))
			end
		end))
		
		add(track:GetMarkerReachedSignal("Disable"):Connect(function(effect_name)
			local effect_part = root_part:FindFirstChild(effect_name)

			if not effect_part then
				return warn(`{effect_name} is not an effect inside the rootpart`)
			end
			
			EffectUtility.Toggle(effect_part, false)
			
			task.delay(get_max_lifetime(effect_part), effect_part.Destroy, effect_part)
			
			if effect_name == "Stabs" then
				clean_looping_shake()
			end
		end))
		
		if is_me then
			add(track:GetMarkerReachedSignal("BoostBack"):Once(function()
				local back_velocity = add(VelocityUtil.Create(root_part, "Possession Flurry End"))
				back_velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
				back_velocity.Parent = root_part
				
				local velocity_strength = Instance.new("NumberValue")
				velocity_strength.Value = -75
				velocity_strength.Parent = back_velocity
				
				TweenService:Create(velocity_strength, TweenInfo.new(0.75, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
					Value = 0
				}):Play()
				
				Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, back_velocity, function()
					back_velocity.Velocity = root_part.CFrame.LookVector * velocity_strength.Value
				end)
				
				task.delay(1, back_velocity.Destroy, back_velocity)
			end))
		end
	end,
	
	Emit = function(target_part : BasePart, effect_name : string)
		BugoVFX(EffectFolder:FindFirstChild(effect_name), target_part)
		
		if effect_name == "HitEffectSlash" then
			EffectUtility.AddSFX(script.SFX.FinalStab, target_part)
		else
			EffectUtility.AddSFX(script.SFX.Stab.Random:FindFirstChild(`{Utility.Seed:NextInteger(1, #script.SFX.Stab.Random:GetChildren())}`), target_part)
		end
	end,
	
	Finisher = function(character : Model, victim : Model)
		local retrieved = AnimationRetriever.new(character, ReplicatedStorage.Animations.Attacks.Anubis["Possession Flurry"].FinisherEnd)
		if (retrieved == nil) then return end

		local root_part = retrieved.RootPart
		local track = retrieved.Animation

		local is_me = (table.find({character, victim}, LocalPlayer.Character) ~= nil)
		local shake_ended = false
		local looping_shake

		local function add<T>(object : T) : T
			return retrieved.Job:Task(object)
		end
		
		add(EffectUtility.AddSFX(script.Finisher, retrieved.RootPart, 0.4))

		local function is_in_range(desired_range : number?)
			desired_range = desired_range or 50

			if is_me then
				return true
			end

			return LocalPlayer:DistanceFromCharacter(root_part.Position) <= desired_range
		end
		
		local function synced_frame_delay(duration : number, callback : (...any) -> (), ...)
			return add(task.delay(math.max(0, (duration/60) - track.TimePosition), callback, ...))
		end
		
		if is_me then
			local camera_rig = add(script.Camera:Clone())
			camera_rig:PivotTo(root_part.CFrame)
			camera_rig.Parent = workspace.Visuals
			
			local camera_animation = camera_rig.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Anubis["Possession Flurry"].FinisherCam)
			camera_animation:Play(0)

			add(RunService.PreSimulation:Connect(function()
				camera_animation.TimePosition = track.TimePosition
			end))

			add(RunCameraRig(root_part, camera_rig, CFrame.identity))
			
			add(camera_animation.Stopped:Once(function()
				camera_rig:Destroy()
			end))
			
			add(Yuki_FOV.AnimateWithMoonFile(ReplicatedStorage.FOVFiles.AnubisPossessionFlurryFinisher))
			
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			LocalPlayerGui.Statistics.Enabled = false

			task.spawn(function()
				local IconModule = require(ReplicatedStorage.Modules.Icon)
				IconModule.setTopbarEnabled(false)
			end)
			
			local fixed_gui = false
			
			local function fix_gui()
				if fixed_gui then
					return
				end
				
				fixed_gui = true
				
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
				LocalPlayerGui.Statistics.Enabled = true

				task.spawn(function()
					local IconModule = require(ReplicatedStorage.Modules.Icon)
					IconModule.setTopbarEnabled(true)
				end)
			end

			add(fix_gui) -- bro tasked a boolean 😭
			
			synced_frame_delay(132, fix_gui)
		end
		
		local effect_folder = Instance.new("Folder")
		effect_folder.Name = "AnubisFinisherCacheFolder"
		effect_folder.Parent = workspace.Visuals
		
		task.delay(5, effect_folder.Destroy, effect_folder)
		
		synced_frame_delay(0, function()
			local enabled_effect = finisher_effects:FindFirstChild("ClientSideThing"):Clone()
			enabled_effect.Join.Part0 = root_part
			EffectUtility.Toggle(enabled_effect, true)
			enabled_effect.Parent = effect_folder
			
			EditedBugoVFX(finisher_effects:FindFirstChild("Slash3"), root_part, effect_folder)
			
			if is_in_range(20) then
				Vignette(Color3.new(1, 0.313725, 0.313725), 0.5, 0.5, not is_me)
				DepthOfField({
					TweenIn = {0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out},
					TweenOut = {0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out},

					LifeTime = 1,

					FarIntensity = 0.1,
					FocusDistance = 0,
					InFocusRadius = 10,
					NearIntensity = 0,
				})
			end
		end)
		
		synced_frame_delay(1, function()
			local enabled_effect = finisher_effects:FindFirstChild("SlashEnabled"):FindFirstChild("Emit"):FindFirstChild("SlashHitTime"):Clone()
			enabled_effect.Join.Part0 = root_part
			EffectUtility.Toggle(enabled_effect, true)
			enabled_effect.Parent = effect_folder
			
			EditedBugoVFX(finisher_effects:FindFirstChild("SlashHit3"), root_part, effect_folder)
		end)
		
		synced_frame_delay(4, function()
			for _, particle in pairs(effect_folder:FindFirstChild("SlashHitTime"):GetDescendants()) do
				if not particle:IsA("ParticleEmitter") then
					continue
				end
				
				particle.TimeScale = 0
			end
			
			for _, particle in pairs(effect_folder:FindFirstChild("SlashHit"):GetDescendants()) do
				if not particle:IsA("ParticleEmitter") then
					continue
				end

				particle.TimeScale = 0.01
			end
			
			for _, particle in pairs(effect_folder:FindFirstChild("Slash"):GetDescendants()) do
				if not particle:IsA("ParticleEmitter") then
					continue
				end

				particle.TimeScale = 0.01
			end
			
			for _, particle in pairs(effect_folder:FindFirstChild("ClientSideThing"):GetDescendants()) do
				if not particle:IsA("ParticleEmitter") then
					continue
				end

				particle.TimeScale = 0
			end
		end)
		
		synced_frame_delay(81, function()
			local handle = character:FindFirstChild("Anubis"):FindFirstChild("Handle")
			
			if not handle then
				return
			end
			
			for _, effect in finisher_effects.Handle:GetChildren() do
				local clone = add(effect:Clone())
				clone:AddTag("PossessionFlurryFinisherEffect")
				clone.Enabled = true
				clone.Parent = handle
			end
		end)
		
		synced_frame_delay(120, function()
			local handle = character:FindFirstChild("Anubis"):FindFirstChild("Handle")

			if not handle then
				return
			end
			
			for _, effect in handle:GetChildren() do
				if not effect:HasTag("PossessionFlurryFinisherEffect") then
					continue
				end
				
				effect:Destroy()
			end
		end)
		
		synced_frame_delay(132, function()
			EffectUtility.ToggleForTime(effect_folder:FindFirstChild("ClientSideThing"), 0)
			EffectUtility.ToggleForTime(effect_folder:FindFirstChild("SlashHitTime"), 0)
			EffectUtility.ToggleForTime(effect_folder:FindFirstChild("SlashHit"), 0)
			EffectUtility.ToggleForTime(effect_folder:FindFirstChild("Slash"), 0)
			
			EditedBugoVFX(finisher_effects:FindFirstChild("Shealth"), root_part, effect_folder)
			
			task.spawn(function()
				--local blood_attachment = Instance.new("Attachment")
				--blood_attachment.CFrame = root_part.CFrame * CFrame.new(0, 0, -9)
				--blood_attachment.Parent = workspace.Terrain
				
				EffectBlood.Explode(victim.HumanoidRootPart)
			end)
			
			if is_in_range(20) then
				CameraShake(5, 10, 0.05, 0.75, vector.create(0.65, 0.65, 0.65))
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
			end
		end)
	end,
}