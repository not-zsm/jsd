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

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

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

--local function clear_velocities(root_part : BasePart, velocity_type : "BodyVelocity" | "LinearVelocity")
--	for _, item in root_part:GetDescendants() do
--		if not item:IsA(velocity_type) then
--			continue
--		end
		
--		item:Destroy()
--	end
--end

return {
	Start = function(character : Model) --, velocity_reference : RemoteEvent)
		local retrieved = AnimationRetriever.new(character, ReplicatedStorage.Animations.Attacks.Anubis["Wailing Fang"].Leap)
		if (retrieved == nil) then return end
		
		--local velocity_reference_job = Job.Extend(retrieved.Job)
		local velocity_reference = character:WaitForChild("ImpactLand")
		
		--velocity_reference_job:Task(velocity_reference.Destroying:Once(function()
		--	velocity_reference_job:Destroy()
		--end))
		
		local root_part = retrieved.RootPart
		local track = retrieved.Animation
		
		local up_velocity : LinearVelocity = nil
		local user_body_velocity : BodyVelocity = nil
		
		local is_me = (LocalPlayer.Character == character)
		
		local function is_in_range(desired_range : number?)
			if is_me then
				return true
			end
			
			return LocalPlayer:DistanceFromCharacter(root_part.Position) <= (desired_range or 50)
		end
		
		retrieved.Job:Task(track:GetMarkerReachedSignal("EmitA"):Connect(function(effect_name)
			if not is_in_range(150) then
				return
			end
			
			BugoVFX(EffectFolder:FindFirstChild(effect_name), root_part)
			
			if effect_name:lower():match("slam") then
				if is_in_range(20) then
					CameraShake(3, 4, 0.25, 1, vector.create(0.65, 0.65, 0.65))
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
				
				coroutine.wrap(RockHandler.Crater)((root_part.CFrame * CFrame.new(0, 0, -1)).Position, vector.create(0, -10, 0), {
					Amount = 7;
					Distance = 5;
					
					ExposeLevel = -0.75;
					SizeMagnitude = 1.5,
				})
				
				task.spawn(function()
					local Origin = root_part.CFrame * CFrame.new(0, 0, -1)
					local Ground = workspace:Raycast(Origin.Position + vector.create(0, 10, 0), vector.create(0, -100, 0), Utility.VisualParams)

					if (Ground == nil) then
						return
					end

					for Index = 1, 7 do
						local Part = Instance.new("Part")
						Part.CollisionGroup = "Rockst"
						Part.Size = vector.one * Utility.Seed:NextNumber(0.5, 2)

						Part.Material = Ground.Material
						Part.Color = Ground.Instance.Color

						for _, Texture in Ground.Instance:GetChildren() do
							if not Texture:IsA("Texture") then
								continue
							end

							Texture:Clone().Parent = Part
						end

						Part.CFrame = Origin * CFrame.new(Utility.Seed:NextInteger(-6, 6), 3, Utility.Seed:NextInteger(-6, 6))
						Part.Parent = workspace.Visuals

						local Mover = Instance.new("BodyVelocity")
						Mover.MaxForce = vector.one * 1e6
						Mover.Velocity = vector.create(Utility.Seed:NextInteger(-10, 10), Utility.Seed:NextInteger(5, 10), Utility.Seed:NextInteger(-10, 10)) * Utility.Seed:NextInteger(1, 3)
						Mover.Parent = Part

						task.delay(0.35, Mover.Destroy, Mover)

						task.delay(10, function()
							TweenService:Create(Part, TweenInfo.new(1), {
								Size = vector.zero,
								Transparency = 1,
							}):Play()

							task.delay(1, Part.Destroy, Part)
						end)
					end
				end)
			end
		end))
		
		retrieved.Job:Task(track:GetMarkerReachedSignal("Leap"):Once(function()
			--clear_velocities(root_part, "LinearVelocity")
			--clear_velocities(root_part, "BodyVelocity")

			up_velocity = Instance.new("LinearVelocity")
			up_velocity.Name = "SkyFangUp"
			up_velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
			up_velocity.RelativeTo = Enum.ActuatorRelativeTo.World
			up_velocity.LineDirection = vector.create(0, 1, 0)
			up_velocity.MaxForce = math.huge
			up_velocity.Attachment0 = root_part.RootAttachment
			up_velocity.LineVelocity = 40
			up_velocity.Parent = root_part

			task.delay(0.45, up_velocity.Destroy, up_velocity)

			user_body_velocity = VelocityUtil.Create(root_part, "SkyFangBoost")
			user_body_velocity.Velocity = root_part.CFrame.LookVector * 0
			user_body_velocity.MaxForce = vector.create(80_000, 0, 80_000)
			user_body_velocity.Parent = root_part

			task.delay(0.75, user_body_velocity.Destroy, user_body_velocity)
			
			retrieved.Job:Task(up_velocity)
			retrieved.Job:Task(user_body_velocity)

			local number_value = Instance.new("NumberValue")
			number_value.Value = 60
			number_value.Parent = user_body_velocity

			while user_body_velocity:IsDescendantOf(workspace) and root_part:IsDescendantOf(game) do
				user_body_velocity.Velocity = root_part.CFrame.LookVector * number_value.Value
				task.wait()
			end
			
			user_body_velocity.Velocity = vector.zero
		end))
		
		local anticipating_ground = false
		local has_landed = false
		
		retrieved.Job:Task(function()
			has_landed = true
		end)
		
		local function detect_ground()
			if not is_me then
				return
			end
			
			if not track.IsPlaying then
				return
			end
			
			if anticipating_ground then
				return
			end
			
			if not velocity_reference then
				return
			end
			
			anticipating_ground = true
			
			retrieved.Job:Task(RunService.PostSimulation:Connect(function()
				local ray_result = workspace:Raycast(root_part.Position, vector.create(0, -10, 0), Utility.VisualParams);

				if ray_result and not has_landed then
					has_landed = true
					
					velocity_reference:FireServer()
				end
			end))
		end
		
		retrieved.Job:Task(task.delay(math.max(0, (50/60) - track.TimePosition), detect_ground))
	end,
	
	Emit = function(target_part : BasePart, effect_name : string)
		BugoVFX(EffectFolder:FindFirstChild(effect_name), target_part)
	end,
}

