local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
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
local ClientSpirit = require(script.Parent.ClientSpirit)
local Table = require(ReplicatedStorage.Packages.Table)

local CharacterTransparency = require( ReplicatedStorage.Modules.Player.Replication.Global.CharacterTransparency )
local BugoVFX = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo )

local EffectFolder = script.Effects

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

local function ToggleAccessories(Character, Hide)
	for _, Accessory in ipairs(Character:GetChildren()) do
		if Accessory:IsA("Accessory") then
			local Handle = Accessory:FindFirstChild("Handle")
			if Handle and Handle:IsA("BasePart") then
				Handle.Transparency = Hide and 1 or 0
			end
		end
	end
end

return { 
	Start = function(character : Model,  sword : Table)
		local retrieved = AnimationRetriever.new(character, ReplicatedStorage.Animations.Attacks.Global.Ultimate.Anubis.Start)
		if (retrieved == nil) then return end

		local root_part = retrieved.RootPart
		local track = retrieved.Animation

		local is_me = (table.find({character}, LocalPlayer.Character) ~= nil)
		
		local function add<T>(object : T) : T
			return retrieved.Job:Task(object)
		end
		
		add(EffectUtility.AddSFX(script.SFX, root_part, 0.3))

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

		local function StepShake()
			if EffectUtility.Distance_Close(character) then
				CameraShake(1, 10, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.4)
			end
		end

		local function Slash()
			if EffectUtility.Distance_Close(character) then
				CameraShake(1.75, 15, 0.01, 0.5, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.new(0.639216, 0.0588235, 1), 0.5, 0.35)
			end
		end
		
		synced_frame_delay(76, function()
			local stand = add(ClientSpirit.RigSpirit(character))
			
			local stand_track = stand.Controller.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Ultimate.Anubis.StandStart)
			stand_track:Play()

			retrieved.Job:Task(task.spawn(function()
				while stand and stand_track.IsPlaying and retrieved.Animation.IsPlaying do
					if retrieved.Animation.TimePosition > stand_track.Length then
						break
					end

					stand_track.TimePosition = retrieved.Animation.TimePosition
					task.wait()
				end
			end))

			retrieved.Job:Task(stand_track.Stopped:Once(function()
				if stand then
					stand:Destroy()
				end
			end))
			
			for _, possible_effect in stand:GetDescendants() do
				if not table.find(can_enable, possible_effect.ClassName) then
					continue
				end

				possible_effect.Enabled = true
			end
		end)
		
		synced_frame_delay(70, function()
			local user_velocity = VelocityUtil.Create(root_part, "Anubis Ultimate Start Up")
			user_velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
			user_velocity.Parent = root_part

			local velocity_strength = Instance.new("NumberValue")
			velocity_strength.Value = 0
			velocity_strength.Parent = user_velocity
			
			TweenService:Create(velocity_strength, TweenInfo.new(1.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Value = 70
			}):Play()
			
			task.delay(1.75, function()
				TweenService:Create(velocity_strength, TweenInfo.new(0.6, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
					Value = 0
				}):Play()
			end)
			
			Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, user_velocity, function()
				user_velocity.Velocity = root_part.CFrame.LookVector * velocity_strength.Value
			end)

			task.delay(3, user_velocity.Destroy, user_velocity)
		end)
		
		for _, Frame in {244, 260} do
			synced_frame_delay(Frame, function()
				local jab_velocity = add(VelocityUtil.Create(root_part, "Anubis Ultimate Slash"))
				jab_velocity.Velocity = root_part.CFrame.LookVector * 25
				jab_velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
				jab_velocity.Parent = root_part
				
				task.delay(0.15, jab_velocity.Destroy, jab_velocity)
			end)
		end
		
		synced_frame_delay(290, function()
			local up_velocity = Instance.new("LinearVelocity")
			up_velocity.Name = "SkyFangUp"
			up_velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
			up_velocity.RelativeTo = Enum.ActuatorRelativeTo.World
			up_velocity.LineDirection = Vector3.new(0, 1, 0)
			up_velocity.MaxForce = math.huge
			up_velocity.Attachment0 = root_part.RootAttachment
			up_velocity.LineVelocity = 50
			up_velocity.Parent = root_part

			task.delay(0.5, up_velocity.Destroy, up_velocity)

			local user_body_velocity = VelocityUtil.Create(root_part, "SkyFangBoost")
			user_body_velocity.Velocity = root_part.CFrame.LookVector * 0
			user_body_velocity.MaxForce = Vector3.new(80_000, 0, 80_000)
			user_body_velocity.Parent = root_part

			retrieved.Job:Task(up_velocity)
			retrieved.Job:Task(user_body_velocity)

			--local number_value = Instance.new("NumberValue")
			--number_value.Value = 75
			--number_value.Parent = user_body_velocity

			local CheckFloor = false
			
			task.delay(0.5, function()
				CheckFloor = true
			end)
			
			while user_body_velocity:IsDescendantOf(workspace) and root_part:IsDescendantOf(game) do
				if CheckFloor and retrieved.Humanoid.FloorMaterial ~= Enum.Material.Air then
					break
				end
				
				user_body_velocity.Velocity = root_part.CFrame.LookVector * 75
				task.wait()
			end

			user_body_velocity.Velocity = Vector3.zero
		end)
		
		synced_frame_delay(24, function()
			BugoVFX(EffectFolder.Prep, root_part)
			
			local BuffVFX = script.Effects.BuffVFX:Clone()
			BuffVFX.Weld.Part0 = sword.Model.Handle
			BuffVFX.Parent = sword.Model.Handle
			
			add(function()
				EffectUtility.Toggle(BuffVFX, false)
				task.delay(2, BuffVFX.Destroy, BuffVFX)
			end)

			EffectUtility.Toggle(BuffVFX, true)
		end)
		
		synced_frame_delay(82, function()
			if EffectUtility.Distance_Close(character) then
				CameraShake(0.75, 10, 0.01, 1, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.new(0.639216, 0.0588235, 1), 0.5, 0.35)
			end
			
			BugoVFX(EffectFolder.Spawn, root_part)
		end)

		synced_frame_delay(119, function()
			StepShake()
			BugoVFX(EffectFolder.Steps["1"], root_part)
		end)
		
		synced_frame_delay(131, function()
			StepShake()
			BugoVFX(EffectFolder.Steps["2"], root_part)
		end)
		
		synced_frame_delay(146, function()
			StepShake()
			BugoVFX(EffectFolder.Steps["3"], root_part)
		end)
		
		synced_frame_delay(160, function()
			StepShake()
			BugoVFX(EffectFolder.Steps["3"], root_part)
		end)
		
		synced_frame_delay(193, function()
			Slash()
			BugoVFX(EffectFolder.Slash, root_part)
		end)
		
		synced_frame_delay(241, function()
			Slash()
			BugoVFX(EffectFolder.Slash3, root_part)
		end)
		
		synced_frame_delay(261, function()
			Slash()
			BugoVFX(EffectFolder.Slash2, root_part)
		end)
		
		synced_frame_delay(304, function()
			BugoVFX(EffectFolder.Jump, root_part)
		end)
		
		synced_frame_delay(341, function()
			BugoVFX(EffectFolder.Prep2, root_part)
		end)
		
		synced_frame_delay(366, function()
			BugoVFX(EffectFolder.Slam1, root_part)
			
			if EffectUtility.Distance_Close(character) then
				CameraShake(4, 20, 0.01, 1, Vector3.one * 0.8, Vector3.one * 0.5)
			end
			
			coroutine.wrap(RockHandler.Crater)(root_part.Position, Vector3.new(0, -100, 0), {
				Amount = 27,

				Distance = {
					Min = 7.5, 
					Max = 20
				},

				LookAt = {
					Min = -5,
					Max = 5
				},

				Exposure = {
					Min = 0.55,
					Max = 0.75
				},

				BaseZ = 2,
				SizeMultiplier = 1.5,
			})

			task.spawn(function()
				local Origin = root_part.CFrame * CFrame.new(0, 0, -1)
				local Ground = workspace:Raycast(Origin.Position + Vector3.new(0, 10, 0), Vector3.new(0, -100, 0), Utility.VisualParams)

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

					Part.Massless = true
					Part.CFrame = Origin * CFrame.new(Utility.Seed:NextInteger(-6, 6), 3, Utility.Seed:NextInteger(-6, 6))
					Part.Parent = workspace.Visuals

					local Mover = Instance.new("BodyVelocity")
					Mover.MaxForce = vector.one * 1e6
					Mover.Velocity = Vector3.new(Utility.Seed:NextInteger(-10, 10), Utility.Seed:NextInteger(5, 10), Utility.Seed:NextInteger(-10, 10)) * Utility.Seed:NextInteger(1, 3)
					Mover.Parent = Part

					task.delay(0.35, Mover.Destroy, Mover)

					task.delay(10, function()
						TweenService:Create(Part, TweenInfo.new(1), {
							Size = Vector3.zero,
							Transparency = 1,
						}):Play()

						task.delay(1, Part.Destroy, Part)
					end)
				end
			end)
		end)
		
		synced_frame_delay(367, function()
			BugoVFX(EffectFolder.Slash4, root_part)
		end)
		
		synced_frame_delay(374, function()
			BugoVFX(EffectFolder.Slam, root_part)
		end)
	end,
	
	
	UltimateHit = function(Model : Model, VictimModel : Model, Sword : Table, Sheathe : Table)
		local Retrieved = AnimationRetriever.new(Model, ReplicatedStorage.Animations.Attacks.Global.Ultimate.Anubis.User)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		local Assets = script.HitAssets
		
		local IsPrimary = EffectUtility.SetPrimary({Model, VictimModel})
		local PlayerIsAttackerOrVictim = (LocalPlayer.Character == Model or LocalPlayer.Character == VictimModel)
		
		Job:Task(EffectUtility.AddSFX(script.HitSFX, PlayerIsAttackerOrVictim and workspace or RootPart, 0.35))

		local Stand = Job:Task((ClientSpirit.RigSpirit(Model)))

		local StandAnim = Stand.Controller.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Ultimate.Anubis.Stand)
		StandAnim:Play()

		Job:Task(task.spawn(function()
			while Stand and StandAnim.IsPlaying and Animation.IsPlaying do
				if Animation.TimePosition > StandAnim.Length then
					break
				end

				StandAnim.TimePosition = Animation.TimePosition
				task.wait()
			end
		end))

		Job:Task(StandAnim.Stopped:Once(function()
			if Stand then
				Stand:Destroy()
			end
		end))
		
		local VFXLoop = coroutine.create(function()
			while task.wait(0.1) do
				Vignette(Color3.new(0.639216, 0.0588235, 1), 0.8, 0.4)
			end
		end)
		
		Job:Task(VFXLoop)
		
		local BlackRoom = nil
		local Spinny = nil
		local Zone = nil
		
		-- Vids
		local Videos
		IsPrimary(function()
			Videos = Job:Task(script.Videos:Clone())
			Videos.Name = "AnubisImpactFrames"
			Videos.Parent = LocalPlayerGui
		end)
		
		local VFX = {
			["1"] = function()
				IsPrimary(function()
					Videos.Frame.Part1.Visible = true
					Videos.Frame.Part1:Play()

					Videos.Frame.Part1.Ended:Once(function()
						Videos.Frame.Part1.Visible = false
					end)
				end)
			end,
		
			["2"] = function()
				BugoVFX(Assets.Step1, RootPart)
			end,
			
			["3"] = function()
				BugoVFX(Assets.Step2, RootPart)
			end,
			
			["4"] = function()
				BugoVFX(Assets.Step3, RootPart)
			end,
			
			["5"] = function()
				BugoVFX(Assets.Charged, RootPart)
			end,
			
			["6"] = function()
				BugoVFX(Assets.Shealth, RootPart)
			end,
			
			["7"] = function()
				BugoVFX(Assets.Slash3, RootPart)
				
				IsPrimary(function()
					BlackRoom = Job:Task(Assets.UFWRoomForSpace:Clone())
					BlackRoom:PivotTo(RootPart.CFrame)
					BlackRoom.Parent = workspace.Visuals

					EffectUtility.Toggle(BlackRoom, true)
					
					Vignette(Color3.new(1, 0, 0), 0.75, 0.3)
				end)
				
				local TS = TweenService
				local Duration = 0.3
				local Path = Job:Task(Assets.DashBeams:Clone())
				local tValue = Instance.new("NumberValue")
				tValue.Parent = Path
				tValue.Value = 1
				
				Path:PivotTo(RootPart.CFrame)
				Path.Parent = workspace.Visuals

				local StartSequence = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 1),
				})

				TS:Create(tValue, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = 0}):Play()

				task.spawn(function()
					for i, beam in pairs(Path:GetDescendants()) do
						task.spawn(function()
							if beam:IsA("Beam") then
								beam.Enabled = true
								beam.Transparency = StartSequence
								beam.TextureSpeed = 5

								TS:Create(beam, TweenInfo.new(1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextureSpeed = 0.01}):Play()

								tValue.Changed:Connect(function()
									task.spawn(function()
										beam.Transparency = NumberSequence.new({
											NumberSequenceKeypoint.new(0, 1),
											NumberSequenceKeypoint.new(0.5, tValue.Value),
											NumberSequenceKeypoint.new(1, 1),
										})
									end)
								end)
								task.delay(Duration, function()
									tValue.Changed:Connect(function()
										task.spawn(function()
											beam.Transparency = NumberSequence.new({
												NumberSequenceKeypoint.new(0, tValue.Value),
												NumberSequenceKeypoint.new(1,1)
											})
										end)
									end)
									task.wait(1)
									beam.Enabled = false
									tValue:Destroy()
								end)
							end
						end)
					end
				end)

				task.delay(Duration, function()
					TS:Create(tValue, TweenInfo.new(.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = 1}):Play()
				end)
			end,
			["8"] = function()
				
			end,
			["9"] = function()
				BugoVFX(Assets.Wind, RootPart)
			end,
			["10"] = function()
				BugoVFX(Assets.Wind, RootPart)
			end,
			["11"] = function()
				BugoVFX(Assets.HUH, RootPart)
			end,
			["12"] = function()
				Spinny = Job:Task(Assets.spinny:Clone())
				Spinny:PivotTo(RootPart.CFrame)
				Spinny.Parent = workspace.Visuals
				
				local BEAM_SHRINK_TIME = 0.1
				local WAIT_TIME = .1

				local TweenService = game:GetService("TweenService")

				EffectUtility.Toggle(Spinny, true)
				
				task.delay(WAIT_TIME, function()
					for _ ,Particles in pairs(Spinny:GetDescendants()) do
						if Particles:IsA("ParticleEmitter") then
							Particles.Enabled = false
						end
					end

					for _,Particles in pairs(Spinny:GetDescendants()) do
						if Particles:IsA("Beam") then
							TweenService:Create(Particles, TweenInfo.new(BEAM_SHRINK_TIME), {Width0 = 0, Width1 = 0}):Play()
							task.delay(BEAM_SHRINK_TIME + 0.03, function()
								Particles.Enabled = false
								Particles.Width0 = 08; Particles.Width1 = 08;
							end)
						end
					end
				end)

				local effect = Spinny
				local TweenTime = 0.05
				local easingStyle = Enum.EasingStyle.Sine
				local easingDirection = Enum.EasingDirection.Out

				local rotacion = 120

				if effect:IsA("BasePart") then
					local rotationGoal = {
						CFrame = effect.CFrame * CFrame.Angles(0, math.rad(rotacion), 0)
					}

					local rotationTween = TweenService:Create(effect, TweenInfo.new(TweenTime, easingStyle, easingDirection), rotationGoal)
					rotationTween:Play()

					task.spawn(function()
						rotationTween.Completed:Wait()
						rotationTween:Destroy()
					end)
				end
				
				IsPrimary(function()
					task.spawn(VFXLoop)
				end)
			end,
			
			["13"] = function()
				Zone = Job:Task(Assets.Zone:Clone())
				Zone:PivotTo(RootPart.CFrame)
				Zone.Parent = workspace.Visuals
				
				EffectUtility.Toggle(Zone, true)
			end,
			
			["14"] = function()
				local RepeatCount = 39
				local RepeatDelay = 0.15

				for Amount = 1, RepeatCount do
					local BEAM_SHRINK_TIME = 0.1
					local WAITTIME = .01

					EffectUtility.Toggle(Spinny, true)

					task.delay(WAITTIME, function()
						for _,Particles in pairs(Spinny:GetDescendants()) do
							if Particles:IsA("ParticleEmitter") then
								Particles.Enabled = false
							end
						end

						for _,Particles in pairs(Spinny:GetDescendants()) do
							if Particles:IsA("Beam") then
								TweenService:Create(Particles, TweenInfo.new(BEAM_SHRINK_TIME), {Width0 = 0, Width1 = 0}):Play()
								task.delay(BEAM_SHRINK_TIME + 0.03, function()
									Particles.Enabled = false
									Particles.Width0 = 22; Particles.Width1 = 22;
								end)
							end
						end
					end)

					local TweenTime = 0.05
					local easingStyle = Enum.EasingStyle.Sine
					local easingDirection = Enum.EasingDirection.Out

					local rotacion = 120

					if Spinny:IsA("BasePart") then
						local rotationGoal = {
							CFrame = Spinny.CFrame * CFrame.Angles(0, math.rad(rotacion), 0)
						}

						local rotationTween = TweenService:Create(Spinny, TweenInfo.new(TweenTime, easingStyle, easingDirection), rotationGoal)
						rotationTween:Play()

						task.spawn(function()
							rotationTween.Completed:Wait()
							rotationTween:Destroy()
						end)
					end

					task.wait(RepeatDelay)
				end
			end,
			["15"] = function()
				BugoVFX(Assets.Cursed, RootPart)
				
				IsPrimary(function()
					Vignette(Color3.new(0.639216, 0.0588235, 1), 0.6, 0.5)
				end)
			end,
			
			["17"] = function()
				BugoVFX(Assets.PrepReal, RootPart)
			end,
			
			["18"] = function()
				EffectUtility.Toggle(Zone, false)
			end,
			
			["19"] = function()
				if BlackRoom then
					BlackRoom:Destroy()
				end
				
				if VFXLoop then
					task.cancel(VFXLoop)
				end
			end,
			
			["20"] = function()
				BugoVFX(Assets.HeadCut, RootPart)
				
				IsPrimary(function()
					Vignette(Color3.new(1, 0, 0), 0.65, 0.45)
				end)
			end,
			
			["21"] = function()
				BugoVFX(Assets.BloodVFX, RootPart)
			end,
		}
		
		Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter : string)
			local Func = VFX[Parameter]
			if Func then
				Func()
			end
		end))
		
		-- BuffVFX
		local BuffVFX = script.Effects.BuffVFX:Clone()
		BuffVFX.Weld.Part0 = Sword.Model.Handle
		BuffVFX.Parent = Sword.Model.Handle

		Job:Task(function()
			EffectUtility.Toggle(BuffVFX, false)
			task.delay(2, BuffVFX.Destroy, BuffVFX)
		end)

		EffectUtility.Toggle(BuffVFX, true)
		
		Job:Task(Animation:GetMarkerReachedSignal("user_disappear"):Connect(function()
			CharacterTransparency(Model, 1)
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("user_appear"):Connect(function()
			CharacterTransparency(Model, 0)
		end))
		
		IsPrimary(function()
			Job:Task(Animation:GetMarkerReachedSignal("VideoStart"):Connect(function()
				Videos.Frame.Part2.Visible = true
				Videos.Frame.Part2:Play()

				Videos.Frame.Part2.Ended:Once(function()
					Videos.Frame.Part2.Visible = false
				end)
				
				Job:Task(EffectUtility.AddSFX(script.ImpactFrame, workspace, 0.3))
			end))
		end)
		
		local SheatheVisible = true
		
		Job:Task(Animation:GetMarkerReachedSignal("SeatheAppear"):Connect(function()
			for _, Mesh in pairs(Sheathe.Model:GetChildren()) do
				if Mesh:IsA("MeshPart") then
					Mesh.Transparency = 0
				end
			end
			
			SheatheVisible = true
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("SeatheHidden"):Connect(function()
			for _, Mesh in pairs(Sheathe.Model:GetChildren()) do
				if Mesh:IsA("MeshPart") then
					Mesh.Transparency = 1
				end
			end
			
			SheatheVisible = false
		end))
		
		-- If Somehow cancelled
		Job:Task(function()
			if not SheatheVisible and Sheathe then
				for _, Mesh in pairs(Sheathe.Model:GetChildren()) do
					if Mesh:IsA("MeshPart") then
						Mesh.Transparency = 0
					end
				end
			end
		end)
		
		-- Start Camera
		if PlayerIsAttackerOrVictim then
			local Camera : Model = Job:Task(script.AnubisCam:Clone())
			Camera:PivotTo(RootPart.CFrame)
			Camera.Parent = workspace.Visuals

			local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Ultimate.Anubis.Camera)
			CameraAnimation:Play(0)
			
			Job:Task(RunService.PreAnimation:Connect(function()
				CameraAnimation.TimePosition = Animation.TimePosition
			end))

			Job:Task(CameraAnimation.Stopped:Connect(function()
				Camera:Destroy()
			end))

			Job:Task(RunCameraRig(RootPart, Camera, CFrame.new(-0.568, 0.435, -0.497), {
				AttachToListen = true
			}))
			
			local Toggled = false
			local Blur = Job:Task(Instance.new("BlurEffect"))
			
			Job:Task(Animation:GetMarkerReachedSignal("Attach"):Connect(function(Parameter : string)
				if Parameter == "Head" then
					Camera.AttachTo.Value = VictimModel.Head
					ToggleAccessories(VictimModel, true)
					
					Job:Task(function()
						if not Toggled then
							ToggleAccessories(VictimModel, false)
						end
					end)
					
					Job:Task(task.delay(1, function()
						Blur.Size = 0
						Blur.Parent = Lighting
						TweenService:Create(Blur, TweenInfo.new(2), {Size = 15}):Play()
					end))
				else
					ToggleAccessories(VictimModel, false)
					Toggled = true
					Camera:Destroy()
				end
			end))
			
			Job:Task(Animation:GetMarkerReachedSignal("KillVictim"):Connect(function(Parameter : string)
				if Blur then
					Blur:Destroy()
				end
			end))
			
			Job:Task(Yuki_FOV.AnimateWithMoonFile(ReplicatedStorage.FOVFiles["AnubisUltimateHit"]))
		end
	end,
	
	ProjectileHit = function(RootPart : BasePart)
		local Part = script.Effects.ProjectileHit;
		
		if Blood.CanShowBlood() then
			EffectUtility.CloneAndEmit(Part.ProjHit, RootPart)
		else
			local Name = "ProjHitNoBlood";
			local NoBlood = Part:FindFirstChild(Name);
			
			if not NoBlood then
				NoBlood = Part.ProjHit:Clone();
				NoBlood.Name = Name;
				NoBlood.blood:Destroy();
				NoBlood.Parent = Part;
			end;
			
			EffectUtility.CloneAndEmit(NoBlood, RootPart)
		end;
	end,
}