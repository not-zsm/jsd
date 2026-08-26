local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
type R6 = typeof(script.Rigs.Friend)

local CollectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Yuki_FOV = require( replicatedStorage.modules.client.replication.Global.Yuki_FOV )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local RunCameraRig = require( replicatedStorage.modules.client.replication.Global.RunCameraRig )
local AttributeListener = require( replicatedStorage.modules.client.replication.Global.AttributeListener )

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Afterimage = require( replicatedStorage.modules.client.replication.Global.Afterimage )

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local CharacterTransparency = require( replicatedStorage.modules.client.replication.Global.CharacterTransparency )
local Dialogue = require(replicatedStorage.modules.effect.tekrinnDialogue)

local Animations = replicatedStorage.ass.emotes["The Final Showdown"]
local MeshEmit = require( script.MeshEmit )
local CFrameData = require( script.CFrameData )


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
	Start = function(Attacker : R6, Victim : R6)
		local Retrieved = AnimationRetriever.new(Attacker, Animations.Keyframeless)
		if (Retrieved == nil) then return end
		
		local StartTime = tick()

		local KeyframlessTrack = Retrieved.Animation
		local Job = Retrieved.Job
		
		local IsPrimary = EffectUtility.SetPrimary({Attacker, Victim})
		
		IsPrimary(function()
			-- START
			local StartupUserAnim = Attacker.Humanoid.Animator:LoadAnimation(Animations.WindupUser)
			local StartupVictimAnim = Victim.Humanoid.Animator:LoadAnimation(Animations.WindupVictim)
			
			StartupUserAnim.Priority = Enum.AnimationPriority.Action2
			StartupVictimAnim.Priority = Enum.AnimationPriority.Action2

			Job:Task(function()
				StartupUserAnim:Stop(0)
				StartupVictimAnim:Stop(0)
			end)

			-- CONFIG
			local MapOffset = CFrame.new(-10000, 0, 0)
			
			local Map = Job:Task(script.Map:Clone())
			--Map.PrimaryPart.CFrame = MapOffset
			Map.Parent = workspace.Visuals
	
			local Effects = Job:Task(script.Effects:Clone())
			Effects.Parent = workspace.Visuals

			local AttackerClone = Job:Task(script.Rigs.Friend:Clone())
			AttackerClone.Name = Attacker.Name
			AttackerClone.HumanoidRootPart.CFrame = CFrame.new(-279, 3, -240.5) * MapOffset
			AttackerClone.Parent = Map
			AttackerClone.Humanoid:ApplyDescription(Attacker.Humanoid:GetAppliedDescription())

			local RootPart = AttackerClone.HumanoidRootPart

			local VictimClone = Job:Task(script.Rigs.Friend:Clone())
			VictimClone.Name = Victim.Name
			VictimClone.HumanoidRootPart.CFrame = CFrame.new(-279, 3, -240.5) * MapOffset
			VictimClone.Parent = Map
			VictimClone.Humanoid:ApplyDescription(Victim.Humanoid:GetAppliedDescription())

			local Animation = AttackerClone.Humanoid.Animator:LoadAnimation(Animations.User)
			local VictimAnimation = VictimClone.Humanoid.Animator:LoadAnimation(Animations.Victim)

			Animation.Priority = Enum.AnimationPriority.Action4

			VictimAnimation.Priority = Enum.AnimationPriority.Action4

			local Camera = Job:Task(script.fx_CAM:Clone())
			Camera:PivotTo(RootPart.CFrame)
			Camera.Parent = workspace.Visuals

			local CameraAnimation = Camera.Humanoid.Animator:LoadAnimation(replicatedStorage.ass.emotes["The Final Showdown"].Camera)
			CameraAnimation:Play(0)

			--Job:Task(RunService.PreSimulation:Connect(function()
			--	CameraAnimation.TimePosition = Animation.TimePosition
			--end))

			local EyesVFX = Job:Task(Effects.head.Head:Clone())
			EyesVFX.Parent = AttackerClone.Head

			--Job:Task(Animation:GetMarkerReachedSignal("StartCam"):Connect(function(Parameter : string)
			--	BlackScreen:Destroy()
			--end))

			local MainCC = Job:Task(Instance.new("ColorCorrectionEffect"))
			MainCC.Parent = game:GetService("Lighting")
			MainCC.Enabled = true

			MainCC.Contrast = 0.13
			MainCC.Saturation = 0.05

			-- VFX
			local VFX = {
				["1"] = function()
					EffectUtility.Emit(Effects.land1, true)
				end,

				["2"] = function()
					EffectUtility.Emit(Effects.land2, true)
				end,

				["3"] = function()
					EffectUtility.Toggle(Effects.slide, true)

					local Targets = {
						{CF = CFrame.new(-10278.87, -0.197, -351.555), Time = 4/60},
						{CF = CFrame.new(-10278.87, -0.197, -355.469), Time = 6/60},
						{CF = CFrame.new(-10278.87, -0.197, -358.605), Time = 5/60}, 
						{CF = CFrame.new(-10278.87, -0.197, -361.587), Time = 5/60}, 
						{CF = CFrame.new(-10278.87, -0.197, -363.809), Time = 7/60}, 
					}

					Effects.slide.CFrame = CFrame.new(-10278.87, -0.197, -348.76)

					for _, Target in ipairs(Targets) do
						local Tween = TweenService:Create(Effects.slide, TweenInfo.new(Target.Time), {CFrame = Target.CF})
						Tween:Play()
						task.wait(Target.Time)
					end
				end,

				["4"] = function()
					EffectUtility.Toggle(Effects.slide, false)
				end,

				["5"] = function()
					EffectUtility.Emit(Effects.throw, true)
				end,

				["6"] = function()
					EffectUtility.Emit(Effects.tpweak, true)
				end,

				["7"] = function()
					EffectUtility.Emit(Effects.tpstrong, true)
					EffectUtility.Emit(Effects.cameffect, true)
				end,

				["8"] = function()
					EffectUtility.Emit(Effects.grab, true)
				end,

				["9"] = function()
					EffectUtility.Toggle(EyesVFX, true)
				end,

				["10"] = function()
					EffectUtility.Toggle(EyesVFX, false)
				end,

				["11"] = function()
					EffectUtility.Emit(Effects.knockback, true)
				end,

				["12"] = function()
					EffectUtility.Emit(Effects.knockback2, true)
				end,

				["13"] = function()
					EffectUtility.Emit(Effects.boom, true)
					MeshEmit(Effects.Meshes.fall.wind1.Start, true)
				end,

				["14"] = function()
					for _, Mesh in Effects.Meshes.preboom:GetDescendants() do
						if Mesh.Name == "Start" then
							MeshEmit(Mesh, true)
						end
					end

					for _, Mesh in Effects.Meshes.preboom_impacts:GetDescendants() do
						if Mesh.Name == "Start" then
							MeshEmit(Mesh, true)
						end
					end

					EffectUtility.Emit(Effects.sparks, true)
				end,

				["15"] = function()
					EffectUtility.Emit(Effects.text, true)
				end,

				["16"] = function()
					for _, Mesh in Effects.Meshes.boom:GetDescendants() do
						if Mesh.Name == "Start" then
							MeshEmit(Mesh, true)
						end
					end

					for _, Mesh in Effects.Meshes.boom_impacts:GetDescendants() do
						if Mesh.Name == "Start" then
							MeshEmit(Mesh, true)
						end
					end

					for _, ParticleEmitter in pairs(Effects.bigboom:GetDescendants()) do 
						if ParticleEmitter.ClassName == "ParticleEmitter" then 
							ParticleEmitter:Emit(ParticleEmitter:GetAttribute("EmitCount")) 

							local Tween = TweenService:Create(ParticleEmitter, TweenInfo.new(.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TimeScale = 0.02})
							Tween:Play()

							task.spawn(function()
								Tween.Completed:Wait()
								Tween:Destroy()
							end)

						end 
					end

					-- CC
					local CC = Job:Task(Instance.new("ColorCorrectionEffect"))
					CC.Parent = Lighting
					CC.Brightness = -1

					task.wait(1/60)
					CC.Brightness = 1
					CC.Contrast = -5
					CC.TintColor = Color3.new(1, 0.905882, 0.968627)

					task.wait(1/60)
					CC.TintColor = Color3.new(1, 1, 1)

					task.wait(1/60)
					CC:Destroy()
				end,

				["17"] = function()
					for _, ParticleEmitter in pairs(Effects.bigboom:GetDescendants()) do 
						if ParticleEmitter.ClassName == "ParticleEmitter" then 
							ParticleEmitter.TimeScale = 1
						end 
					end

					local BlackScreen = Job:Task(script.BlackScreen:Clone())
					BlackScreen.Parent = LocalPlayer.PlayerGui
					BlackScreen.Enabled = true
				end,
			}

			Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter : string)
				local Func = VFX[Parameter]
				if Func then
					Func()
				end
			end))

			Job:Task(Animation:GetMarkerReachedSignal("ColorCorrection"):Connect(function(Parameter)
				local CC = Job:Task(Instance.new("ColorCorrectionEffect"))
				CC.Parent = game:GetService("Lighting")
				CC.Enabled = true
				task.wait(1/60)
				CC.TintColor = Color3.new(255, 255, 255)
				CC.Brightness = 0.5
				CC.Contrast = 1
				CC.Saturation = -1
				task.wait(1/60)
				CC.Brightness = -0.3

				local CoverVignette = Job:Task(script.Vignette:Clone())
				CoverVignette.Parent = LocalPlayer.PlayerGui

				Lighting.Brightness = 0
				Lighting.ExposureCompensation = 0.1
				Lighting.Ambient = Color3.new(0, 0, 0)
				Lighting.ClockTime = 0

				local GameLighting = require( replicatedStorage.modules.shared.Game.GameLighting )

				Job:Task(function()
					Lighting.Brightness = GameLighting.Brightness
					Lighting.ExposureCompensation = GameLighting.ExposureCompensation
					Lighting.Ambient = GameLighting.Ambient
					Lighting.ClockTime = GameLighting.ClockTime
				end)

				local DarkCC = Job:Task(Instance.new("ColorCorrectionEffect"))
				DarkCC.Parent = game:GetService("Lighting")
				DarkCC.Enabled = false
				DarkCC.Contrast = 0.4
				DarkCC.Saturation = 0.13

				task.wait(1/60)
				CC.Brightness = 1
				CC.Saturation = 0
				CC.Contrast = 0
				task.wait(2 / 60)
				DarkCC.Enabled = true
				CC:Destroy()
			end))

			Job:Task(Animation:GetMarkerReachedSignal("FPV"):Connect(function(Param)
				local Visible = true
				
				if Param == "Start" then
					ToggleAccessories(Attacker, true)
					Visible = false
					
					Job:Task(function()
						if not Visible then
							ToggleAccessories(Attacker, false)
						end
					end)
				else
					ToggleAccessories(Attacker, false)
					Visible = true
				end
			end))

			Job:Task(Animation:GetMarkerReachedSignal("Explode"):Connect(function()
				local Craters = Job:Task(script.Craters:Clone())
				Craters.Parent = Map

				for _, v in Map:GetDescendants() do
					if v:HasTag("Dropkick Dream CFrame") then
						local StartCF = CFrameData.Start[v.Name]
						local EndCF = CFrameData.End[v.Name]

						if StartCF and EndCF then
							local Tween
							local Time = 5.367
							if v:IsA("Model") then
								v.PrimaryPart.CFrame = StartCF
								Tween = TweenService:Create(v.PrimaryPart, TweenInfo.new(Time), {CFrame = EndCF}):Play()
							else
								v.CFrame = StartCF
								Tween = TweenService:Create(v, TweenInfo.new(Time), {CFrame = EndCF}):Play()
							end

							local CraterSize = CFrameData.CraterSizes[v.Name]

							if CraterSize then
								v.Size = CraterSize
							end
						else
							local Transparency = CFrameData.Transparency[v.Name]

							if Transparency then
								v.Transparency = Transparency
							end
						end
					end
				end
			end))


			Job:Task(StartupUserAnim:GetMarkerReachedSignal("StartMain"):Connect(function()
				task.wait(2/60)
				local Sound = Job:Task(script.SFX:Clone())
				Sound.Parent = SoundService
				Sound:Play()
				Animation:Play(0)
				VictimAnimation:Play(0)

				--Animation.TimePosition = 3.333
				--VictimAnimation.TimePosition = 3.333
				--CameraAnimation.TimePosition = 3.333

				Job:Task(RunCameraRig(RootPart, Camera, CFrame.identity, {
					DontDoTransition = true,
					DontSupportCutsceneSetting = true
				}))

				Job:Task(RunService.PreSimulation:Connect(function()
					CameraAnimation.TimePosition = Animation.TimePosition
				end))

				local Clean = Job:Task(Yuki_FOV.AnimateWithMoonFile(replicatedStorage.fovFiles["The Final Showdown"]))

				Job:Task(Animation:GetMarkerReachedSignal("StopFOV"):Connect(function()
					Clean()
					Yuki_FOV.Set(50)

					Job:Task(function()
						Yuki_FOV.Set(70)
					end)
				end))
			end))

			-- discord died just servers, dms still work
			StartupUserAnim:Play(0)
			StartupVictimAnim:Play(0)
		end)
	end,
	
	OutsideView = function(Model : Model, VictimModel : Model)
		local IsMainPlayer = LocalPlayer.Character == Model or LocalPlayer.Character == VictimModel
		
		if IsMainPlayer then
			return
		end
		
		local Retrieved = AnimationRetriever.new(Model, Animations.Keyframeless)
		if (Retrieved == nil) then return end

		local StartTime = tick()

		local KeyframlessTrack = Retrieved.Animation
		local Job = Retrieved.Job
		
		-- Not Main Players (Everyone Else)
		local OutsideUserAnim = Model.Humanoid.Animator:LoadAnimation(Animations.Bicker["Player1"])
		local OutsideVictimAnim = VictimModel.Humanoid.Animator:LoadAnimation(Animations.Bicker["Player2"])
		
		OutsideUserAnim.Priority = Enum.AnimationPriority.Action
		OutsideVictimAnim.Priority = Enum.AnimationPriority.Action

		Job:Task(function()
			OutsideUserAnim:Stop(0)
			OutsideVictimAnim:Stop(0)
		end)

		OutsideUserAnim:Play(0.3)
		OutsideVictimAnim:Play(0.3)
	end,
}
