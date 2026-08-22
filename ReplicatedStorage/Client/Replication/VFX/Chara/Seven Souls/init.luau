local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer.PlayerGui

local AnimationRetriever = require( ReplicatedStorage.Client.Replication.VFX.AnimationRetriever )

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )

local Dojyan_Util = require( script.quickutil )
local MeshEmit = require( script.quickutil.MeshEmit )

local CameraShake = require( ReplicatedStorage.Client.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Client.Replication.Global.Vignette )
local Yuki_FOV = require( ReplicatedStorage.Client.Replication.Global.Yuki_FOV )

local RunCameraRig = require( ReplicatedStorage.Client.Replication.Global.RunCameraRig )
local HideAllUI = require( ReplicatedStorage.Client.Replication.Global.HideAllUI )
local DashRocks = require( ReplicatedStorage.Client.Replication.Global.DashRocks )

local Fight_UI = require( ReplicatedStorage.Effects.Characters.Chara.Fight_UI )
local Create_Clone = require( ReplicatedStorage.Effects.Characters.Chara.Create_Clone )

local Animations = ReplicatedStorage.Animations.Attacks.Chara["Seven Souls"]

local Effects = script.effects
local Windup_Effects = script.windup_effects
local Red_Color = Color3.fromRGB(255, 50, 50)

local function CreateDashAfterImage(Model : Model)
	for _, Part in ipairs(Model:GetChildren()) do
		if Part:IsA("BasePart") and Part.Name ~= "HumanoidRootPart" then
			local Clone = Instance.new("Part")
			Clone.Size = Part.Size
			Clone.CFrame = Part.CFrame
			Clone.Anchored = true
			Clone.CanCollide = false
			Clone.CanQuery = false
			Clone.CanTouch = false
			Clone.Material = Enum.Material.Neon
			Clone.Color = Red_Color
			Clone.Transparency = 0.3
			
			local SpecialMesh = Part:FindFirstChildOfClass("SpecialMesh")

			if SpecialMesh then
				SpecialMesh:Clone().Parent = Clone
			end
			
			Clone.Parent = workspace.Visuals
			TweenService:Create(Clone, TweenInfo.new(0.25), {Transparency = 1}):Play()
			task.delay(0.3, Clone.Destroy, Clone)
		end
	end
end

return {
	Slash = function(RootPart : BasePart)
		local Hit = Windup_Effects.Hit:Clone()
		Hit:PivotTo(RootPart.CFrame * CFrame.new(0, 0.5, -2.75))
		Hit.Parent = workspace.Visuals
		EffectUtility.Emit(Hit)

		if EffectUtility.Distance_Close(RootPart.Parent) then
			Vignette(Color3.fromRGB(255, 50, 50), 0.5, 0.5)
			CameraShake(1.5, 15, 0.01, 0.5, Vector3.one * 0.8, Vector3.one * 0.2)
		end
	end,

	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local RootPart, Torso = Retrieved.RootPart, Retrieved.Torso

		local Clone = Job:Task(Create_Clone(Model))

		for _, Part : BasePart | Decal in ipairs(Clone:GetDescendants()) do
			if Part:IsA("BasePart") or Part:IsA("Decal") then
				Part.Transparency = 1
			end
		end
		
		Job:Task(EffectUtility.AddSFX(script.sfx.windup, Retrieved.IsLocalSource and workspace or RootPart, 0.3))

		Clone.Parent = workspace.Visuals

		local HeadVFX = Job:Task(Windup_Effects.head:Clone())
		EffectUtility.Arc.ToggleAttachment(HeadVFX, true)
		EffectUtility.Emit(HeadVFX, true)
		HeadVFX.Parent = Model.Head

		local Dash = Job:Task(Windup_Effects.dash:Clone())
		Dash.Parent = RootPart

		local Aura = Windup_Effects.aura:Clone()
		Aura.Parent = Torso

		Job:Task(function()
			EffectUtility.Arc.ToggleAttachment(Aura, false)
			task.delay(2, Aura.Destroy, Aura)
		end)

		Job:Task(Animation:GetMarkerReachedSignal("step"):Connect(function(Leg : string)
			if EffectUtility.Distance_Close(Model) then
				CameraShake(1.25, 12.5, 0.01, 0.5, Vector3.one * 0.8)
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("boost"):Once(function()
			Job:Task(DashRocks(RootPart, "Side Dash", -1))

			EffectUtility.Arc.ToggleAttachment(HeadVFX, false)
			EffectUtility.Arc.ToggleAttachment(Dash, true)
			EffectUtility.Arc.ToggleAttachment(Aura, true)

			EffectUtility.Arc.CloneAndEmit(Windup_Effects.dash_burst, RootPart)
			EffectUtility.Emit(Dash, true)

			if Retrieved.IsLocalSource then
				CameraShake(0.85, 8.5, 0.01, 2.5, Vector3.one * 0.8, Vector3.one * 0.25)
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("dash"):Connect(function()
			task.spawn(function()
				for _ = 1, 4 do
					CreateDashAfterImage(Model)

					if Retrieved.IsLocalSource then
						Vignette(Color3.fromRGB(255, 50, 50), 0.35, 0.35)
					end

					task.wait(0.05)
				end
			end)

			if EffectUtility.Distance_Close(Model) then
				CameraShake(1.5, 15, 0.01, 0.5, Vector3.one * 0.8, Vector3.one * 0.3)
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("jump"):Once(function()
			EffectUtility.Arc.ToggleAttachment(Dash, false)
		end))

		Job:Task(task.delay(208 / 60, function()
			local Clone_Animation = Clone.Humanoid.Animator:LoadAnimation(Animations.Windup_Clone)
			Clone_Animation:Play(0)
			Clone_Animation.Stopped:Once(function()
				Clone:Destroy()
			end)

			for _, Part : BasePart | Decal in ipairs(Clone:GetDescendants()) do
				if (Part:IsA("BasePart") and Part.Name ~= "HumanoidRootPart") or Part:IsA("Decal") then
					TweenService:Create(Part, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0}):Play()
				end
			end

			Job:Task(Animation:GetMarkerReachedSignal("dash"):Connect(function()
				task.spawn(function()
					for _ = 1, 4 do
						CreateDashAfterImage(Clone)
						task.wait(0.05)
					end
				end)
			end))
		end))

		if Retrieved.IsLocalSource then
			local Time = 1.1
			local EasingStyle, EasingDirection = Enum.EasingStyle.Quad, Enum.EasingDirection.Out

			Yuki_FOV.Tween(55, {Time, EasingStyle, EasingDirection})

			Job:Task(function()
				Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out}, true)
			end)

			local ColorConnection = script.ColorCorrection:Clone()
			ColorConnection.Contrast = 0.75
			ColorConnection.Parent = Lighting
			Job:Task(ColorConnection)

			local DarkTween = TweenService:Create(ColorConnection, TweenInfo.new(Time, EasingStyle, EasingDirection), {
				TintColor = Color3.fromRGB(140, 140, 140),
				Contrast = 0
			})

			DarkTween:Play()

			DarkTween.Completed:Once(function()
				DarkTween = TweenService:Create(ColorConnection, TweenInfo.new(0.75, EasingStyle, Enum.EasingDirection.Out), {
					TintColor = Color3.fromRGB(140, 75, 75),
				})

				DarkTween:Play()
			end)

			local PreviousBrightness = Lighting.Brightness

			TweenService:Create(Lighting, TweenInfo.new(Time, EasingStyle, EasingDirection), {
				Brightness = 2,
			}):Play()

			Job:Task(Animation:GetMarkerReachedSignal("boost"):Connect(function()
				DarkTween:Cancel()

				TweenService:Create(ColorConnection, TweenInfo.new(0.3, EasingStyle, EasingDirection), {
					TintColor = Color3.fromRGB(255, 215, 215),
				}):Play()

				TweenService:Create(Lighting, TweenInfo.new(0.3, EasingStyle, EasingDirection), {
					Brightness = PreviousBrightness,
				}):Play()

				Yuki_FOV.Tween(100, {0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut})

				Job:Task(task.delay(1.25, function()
					Yuki_FOV.Tween(70, {2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut})
				end))
			end))

			Job:Task(Animation:GetMarkerReachedSignal("jump"):Connect(function()
				TweenService:Create(ColorConnection, TweenInfo.new(0.5, EasingStyle, EasingDirection), {
					TintColor = Color3.fromRGB(255, 255, 255),
				}):Play()
			end))

			--local ColorConnection = script.ColorCorrection:Clone()
			--ColorConnection.TintColor = Color3.fromRGB(70, 70, 70)
			--ColorConnection.Contrast = 0.3
			--ColorConnection.Parent = Lighting

			--TweenService:Create(ColorConnection, TweenInfo.new(Time, EasingStyle, EasingDirection), {
			--	TintColor = Color3.fromRGB(255, 255, 255),
			--	Contrast = 0
			--}):Play()

			--local PreviousBrightness = Lighting.Brightness
			--Lighting.Brightness = 1.5

			--TweenService:Create(Lighting, TweenInfo.new(Time, EasingStyle, EasingDirection), {
			--	Brightness = PreviousBrightness,
			--}):Play()

			--Job:Task(Animation:GetMarkerReachedSignal("boost"):Connect(function()
			--	Yuki_FOV.Tween(80, {0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})

			--	Job:Task(task.delay(0.65, function()
			--		Yuki_FOV.Tween(70, {0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out})
			--	end))
			--end))
		end
	end,

	Hit = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Full)
		if (Retrieved == nil) then return end

		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local RootPart, Torso = Retrieved.RootPart, Retrieved.Torso

		local VictimIsLocalSource = LocalPlayer.Character == VictimModel
		local IsLocalSource = (Retrieved.IsLocalSource or VictimIsLocalSource)
		
		Job:Task(EffectUtility.AddSFX(script.sfx.hit, IsLocalSource and workspace or RootPart, 0.2))
		
		local Clone, CloneHumanoid, CloneRootPart = Create_Clone(Model)
		Clone.Parent = workspace.Visuals

		local Clone_Animation = Clone.Humanoid.Animator:LoadAnimation(Animations.Full_Clone)
		Clone_Animation:Play(0)

		local DontDestroyClone = false

		Job:Task(function()
			if not DontDestroyClone then
				Clone:Destroy()
			end
		end)

		Clone_Animation.Stopped:Once(function()
			Clone:Destroy()
		end)

		local Clone_Spin = Effects.spin:Clone()
		EffectUtility.Weld(Clone_Spin, Clone.Torso)
		Clone_Spin.Parent = workspace.Visuals

		local Chara_Eye = Effects.head:Clone()
		EffectUtility.Weld(Chara_Eye, Model.Head)
		Chara_Eye.Parent = workspace.Visuals

		local PlayerSlashes = Effects.playerslashes:Clone()
		EffectUtility.Weld(PlayerSlashes, RootPart)
		PlayerSlashes.Parent = workspace.Visuals

		local CloneSlashes = Effects.cloneslashes:Clone()
		EffectUtility.Weld(CloneSlashes, CloneRootPart or RootPart)
		CloneSlashes.Parent = workspace.Visuals

		Job:Task(Clone_Spin)
		Job:Task(Chara_Eye)
		Job:Task(PlayerSlashes)
		Job:Task(CloneSlashes)

		Job:Task(Animation:GetMarkerReachedSignal("slash"):Connect(function(Parameter : string)
			if EffectUtility.Distance_Close(Model) then
				CameraShake(1, 10, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.25)
				Vignette(Color3.fromRGB(255, 50, 50), 0.35, 0.35)
			end

			Dojyan_Util:emit(PlayerSlashes[Parameter])
		end))

		Job:Task(Clone_Animation:GetMarkerReachedSignal("slash"):Connect(function(Parameter : string)
			if EffectUtility.Distance_Close(Model) then
				CameraShake(1, 10, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.25)
				Vignette(Color3.fromRGB(255, 50, 50), 0.35, 0.35)
			end
			
			Dojyan_Util:emit(CloneSlashes[Parameter])
		end))

		Job:Task(Clone_Animation:GetMarkerReachedSignal("spin"):Connect(function(Parameter : string)
			if EffectUtility.Distance_Close(Model) then
				CameraShake(0.5, 5, 0.01, 0.6, Vector3.one * 0.2, Vector3.one * 0.8)
			end
			
			Dojyan_Util:interact(Clone_Spin, "ParticleEmitter", "Enabled", (Parameter == "true"))
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("on_qte"):Connect(function(Parameter : string)
			if (Parameter == "1") then
				Job:Task(EffectUtility.AddSFX(script.sfx.qte_1, IsLocalSource and workspace or RootPart, 0.2))
				
			elseif (Parameter == "2") then
				Job:Task(EffectUtility.AddSFX(script.sfx.qte_2, IsLocalSource and workspace or RootPart, 0.2))
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("eye"):Once(function()
			if EffectUtility.Distance_Close(Model) then
				CameraShake(0.1, 5, 0.01, 0.4, Vector3.one * 0.7)
				Vignette(Color3.fromRGB(255, 50, 50), 0.6, 0.4, true)
			end
			
			Dojyan_Util:emit(Chara_Eye)
		end))

		Job:Task(Animation:GetMarkerReachedSignal("big_slash"):Connect(function()
			if EffectUtility.Distance_Close(Model, 50) then
				CameraShake(1, 10, 0.01, 0.75, Vector3.one * 0.8, Vector3.one * 0.3)
			end

			local BigSlash = Effects.bigslash:Clone()
			BigSlash.CFrame = RootPart.CFrame * CFrame.new(0.067, 4.312, 1.263)
			BigSlash.Parent = workspace.Visuals
			Dojyan_Util:emit(BigSlash)

			Dojyan_Util:interact(BigSlash.beam, "Beam", "Brightness", 2)
			Dojyan_Util:interact(BigSlash.beam, "Beam", "TextureSpeed", -6)
			Dojyan_Util:interact(BigSlash.beam, "Beam", "Width1", 34)

			Dojyan_Util:tweendescendant(BigSlash.beam, "Beam", 1.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Brightness = 0, TextureSpeed = -0.6, Width1 = 6})

			Dojyan_Util:interact(BigSlash, "PointLight", "Brightness", 2)
			Dojyan_Util:tweendescendant(BigSlash, "PointLight", 3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Brightness = 0})

			Dojyan_Util:interact(BigSlash.beams, "Beam", "Brightness", 2)
			Dojyan_Util:interact(BigSlash.beams, "Beam", "TextureSpeed", 8)
			Dojyan_Util:interact(BigSlash.beams, "Beam", "Width1", 35)

			Dojyan_Util:tweendescendant(BigSlash.beams, "Beam", 1.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Brightness = 0, TextureSpeed = 0.6, Width1 = 25})

			task.delay(10, BigSlash.Destroy, BigSlash)
		end))

		Job:Task(Animation:GetMarkerReachedSignal("boom"):Connect(function()
			if EffectUtility.Distance_Close(Model, 50) then
				CameraShake(1.3, 13, 0.01, 0.75, Vector3.one * 0.8, Vector3.one * 0.3)
			end

			local SoulBeam = Effects.soulbeam:Clone()
			SoulBeam:PivotTo(RootPart.CFrame * CFrame.new(0, 1, -6.032))
			SoulBeam.Parent = workspace.Visuals
			task.delay(10, SoulBeam.Destroy, SoulBeam)

			Dojyan_Util:interact(SoulBeam, "Beam", "Width0", 130)
			Dojyan_Util:interact(SoulBeam, "Beam", "Width1", 150)

			Dojyan_Util:tweendescendant(SoulBeam, "Beam", .1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, {Width1 = 90, Width0 = 40})

			task.delay(0.05, function()
				Dojyan_Util:tweendescendant(SoulBeam, "Beam", 2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Width1 = 0, Width0 = 0})
			end)

			SoulBeam.att2.Position = Vector3.new(0, 213.13, 0)
			Dojyan_Util:tweensingle(SoulBeam.att2, 2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Position = Vector3.new(0, 107.661, 0)})

			Dojyan_Util:interact(SoulBeam, "ParticleEmitter", "Enabled", true)

			task.delay(0.9, function()
				Dojyan_Util:interact(SoulBeam, "ParticleEmitter", "Enabled", false)
			end)

			local SoulActivate = Effects.soulactivate:Clone()
			SoulActivate.CFrame = RootPart.CFrame * CFrame.new(0, 1, -6.032)
			SoulActivate.Parent = workspace.Visuals
			Dojyan_Util:emit(SoulActivate)
			task.delay(10, SoulActivate.Destroy, SoulActivate)

			local Mesh = Effects.meshes.beam:Clone()
			Mesh:PivotTo(RootPart.CFrame)

			for _, Start in ipairs(Mesh:GetDescendants()) do
				if Start.Name == "Start" then
					MeshEmit(Start, true)
				end
			end

			Mesh:Destroy()
		end))

		if IsLocalSource then
			local HitFirstQTE = false

			if Retrieved.IsLocalSource then
				Job:Task(Animation:GetMarkerReachedSignal("qte"):Connect(function(Parameter : string)
					local Remote : RemoteEvent? = Model:FindFirstChild("CharaSevenSoulsRemote")
					if (Remote == nil) then return end

					local Time = Utility.Seed:NextNumber(0.725, 0.9)

					local Clean_UI = Fight_UI(Model, Remote, Enum.KeyCode.Four, Job, {
						AttackTime = Time,

						RemoteFire = function(WasInRange : boolean)
							local Type = tonumber(Parameter)

							if (Type == 1) then
								HitFirstQTE = WasInRange
							end

							return Remote:FireServer(WasInRange, Type)
						end,
					})

					task.wait(Time)

					Clean_UI()
				end))

				Job:Task(Animation:GetMarkerReachedSignal("on_qte"):Connect(function(Parameter : string)
					if (Parameter == "1" and not HitFirstQTE) then
						DontDestroyClone = true

						local New_Clone_Animation = Clone.Humanoid.Animator:LoadAnimation(Animations.FirstQTEMiss_Clone)
						Clone_Animation:Destroy()
						Clone_Animation:Stop(0)
						New_Clone_Animation:Play(0)

						New_Clone_Animation.Stopped:Once(function()
							Clone:Destroy()
						end)
					end
				end))
			end
			
			local Videos = Job:Task(script.Videos:Clone())
			Videos.Name = "CharaVideos"
			Videos.Parent = LocalPlayerGui

			Job:Task(Animation:GetMarkerReachedSignal("camera"):Connect(function()
				if not VictimIsLocalSource and not HitFirstQTE then return end

				Job:Task(HideAllUI())

				local Vignette = ReplicatedStorage.Effects.Moon_Vignette:Clone()
				Vignette.Parent = LocalPlayerGui
				Job:Task(Vignette)

				local Camera = script.Camera:Clone()
				EffectUtility.Weld(Camera, RootPart)
				Camera.Parent = workspace.Visuals
				Job:Task(Camera)

				local CameraDisabled = false

				local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(Animations.Full_Camera)
				CameraAnimation:Play(0)

				task.delay(1 / 60, function()
					do
						local Hearts = script.Heart:Clone()

						for _, Item in ipairs(Hearts:GetChildren()) do
							if Item:IsA("BasePart") then
								local Weld = Instance.new("Motor6D")
								Weld.Part0 = RootPart
								Weld.Part1 = Item
								Weld.Name = Item.Name
								Weld.Parent = RootPart
							end
						end

						Job:Task(Animation:GetMarkerReachedSignal("boom"):Once(function()
							local Info = TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

							for _, Item in ipairs(Hearts:GetDescendants()) do
								if (Item:IsA("BasePart") and Item.Transparency == 0) then
									TweenService:Create(Item, Info,	{Transparency = 1}):Play()

								elseif Item:IsA("Light") then
									TweenService:Create(Item, Info, {Brightness = 0}):Play()
								end
							end
						end))

						Hearts.Parent = Model

						Job:Task(function()
							task.delay(0.5, Hearts.Destroy, Hearts)
						end)
					end

					Job:Task(RunCameraRig(RootPart, Camera, nil, {
						DontSaveCameraPosition = true,
						DontDoTransition = true,

					}, function(Value)
						CameraDisabled = not Value
					end))
				end)

				Job:Task(CameraAnimation:GetMarkerReachedSignal("wind"):Connect(function(Parameter : string)
					if CameraDisabled then return end

					Dojyan_Util:interact(Camera.wind, "ParticleEmitter", "Enabled", (Parameter == "true"))
				end))

				Job:Task(Animation:GetMarkerReachedSignal("big_slash"):Connect(function()
					Job:Task(task.delay(0.6, function()
						if LocalPlayer:GetAttribute("Epileptic_Mode") or math.random(1, 5) ~= 1 then return end

						Videos.Frame.SevenSouls.Visible = true
						Videos.Frame.SevenSouls:Play()

						Videos.Frame.SevenSouls.Ended:Once(function()
							Videos.Frame.SevenSouls.Visible = false
						end)
					end))
				end))

				Job:Task(Animation:GetMarkerReachedSignal("boom"):Connect(function()
					Animation:AdjustSpeed(0.8) -- Server does it already, but just to be more precise with camera.
					CameraAnimation:AdjustSpeed(0.8)

					local Time = 0.9833333333333333

					do
						local ColorConnection = script.ColorCorrection:Clone()
						ColorConnection.Contrast = 0.25
						ColorConnection.Parent = Lighting

						TweenService:Create(ColorConnection, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Contrast = 0
						}):Play()

						task.delay(Time, ColorConnection.Destroy, ColorConnection)
					end

					do
						local PreviousBrightness, PreviousExposureCompensation = Lighting.Brightness, Lighting.ExposureCompensation

						Lighting.Brightness = 0
						Lighting.ExposureCompensation = 0.35

						TweenService:Create(Lighting, TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
							Brightness = PreviousBrightness,
							ExposureCompensation = PreviousExposureCompensation
						}):Play()
					end

					do
						Vignette.Image.ImageTransparency = 0.2

						TweenService:Create(Vignette.Image, TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
							ImageTransparency = 1
						}):Play()
					end

					do
						local Bloom = Lighting:FindFirstChildOfClass("BloomEffect")
						if (Bloom == nil) then return end

						local PreviousBloom = Bloom.Intensity
						Bloom.Intensity = 1.4

						TweenService:Create(Bloom, TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
							Intensity = PreviousBloom
						}):Play()
					end
				end))

				Job:Task(CameraAnimation.Stopped:Connect(function()
					Camera:Destroy()
				end))
			end))
		end
	end,
}