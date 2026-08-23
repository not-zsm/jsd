local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local AnimationRetriever = require(ReplicatedStorage.modules.client.replication.VFX.AnimationRetriever)
local RunCameraRig = require(ReplicatedStorage.modules.client.replication.Global.RunCameraRig)
local CameraShake = require(ReplicatedStorage.modules.client.replication.Global.CameraShake)
local RockHandler = require(ReplicatedStorage.modules.client.replication.Global.RockHandler)
local VelocityUtil = require(ReplicatedStorage.modules.shared.Game.Velocity.VelocityUtil)
local EffectUtility = require(ReplicatedStorage.modules.client.replication.EffectUtility)
local BugoVFX = require(ReplicatedStorage.modules.client.replication.EffectUtility.Bugo)
local ModelTransparency = require( ReplicatedStorage.modules.client.replication.Global.CharacterTransparency )
local Vignette = require( ReplicatedStorage.modules.client.replication.Global.Vignette )
local AenoirMesh = require( ReplicatedStorage.modules.client.replication.EffectUtility.AenoirMesh )

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )
local Animations = ReplicatedStorage.Animations.Attacks.Chara.Atonement
local quickutil = require( script.quickutil )
local OldLighting = require( ReplicatedStorage.modules.shared.Game.GameLighting )
local Yuki_FOV = require( ReplicatedStorage.modules.client.replication.Global.Yuki_FOV )

------------------- [ Functions ]-------------------
-->> somebody get the door
local function EmitMesh(MeshFolder : Object, Where)
	--local Meshes = MeshFolder:Clone()
	--for _, Mesh in pairs(Meshes:GetChildren()) do
	--	if Mesh:GetAttribute("Weld") then
	--		for _, Part in pairs(Mesh:GetChildren()) do
	--			if Part:IsA("BasePart") then
	--				local Weld = Instance.new("Weld")
	--				Weld.C0 = Mesh:GetPivot()
	--				Part.Anchored = false
					
	--				Weld.Part0 = Where
	--				Weld.Part1 = Part
	--				Weld.Parent = Part
	--			end
	--		end
	--	else
	--		Mesh:PivotTo(Where.CFrame * Mesh:GetPivot())
	--	end
	--end
	
	--Meshes.Parent = workspace.Visuals
	
	--quickutil:mesh_emit(MeshFolder.Parent, Meshes, true)
	--return Meshes
	
	return BugoVFX(MeshFolder, Where)
end

local function EmitPart(Part : BasePart, Object : BasePart)
	local Effect : Object = Part:Clone()
	Effect:PivotTo(Object.CFrame * Part.CFrame)
	Effect.Parent = workspace.Visuals
	
	EffectUtility.Emit(Effect)
	return Effect
end

local function CreateVelocity(Name : String, RootPart : BasePart, BaseStrength : Number)
	local Velocity = VelocityUtil.Create(RootPart, Name)
	Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
	Velocity.Parent = RootPart

	local VelStrength = Instance.new("NumberValue")
	VelStrength.Value = BaseStrength
	VelStrength.Name = "Strength"
	VelStrength.Parent = Velocity

	Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function()
		Velocity.Velocity = RootPart.CFrame.LookVector * VelStrength.Value
	end)
	
	return Velocity
end

local function DashEffects(Image : ImageLabel, ColorCorrection : ColorCorrectionEffect, Duration : Number)
	Image.ImageTransparency = 0.2
	TweenService:Create(Image, TweenInfo.new(Duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 1}):Play()
	
	Lighting.Brightness = 0.45
	Lighting.ExposureCompensation = 1
	TweenService:Create(Lighting, TweenInfo.new(Duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Brightness = OldLighting.Brightness, ExposureCompensation = OldLighting.ExposureCompensation}):Play()
	
	ColorCorrection.TintColor = Color3.new(1, 0.741176, 0.741176)
	ColorCorrection.Contrast = 3
	task.wait()
	
	ColorCorrection.Contrast = 1
	TweenService:Create(ColorCorrection, TweenInfo.new(Duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TintColor = Color3.new(1, 1, 1), Contrast = 0}):Play()
end

return { 
	Start = function(Model : Model)
		------------------- [ Variables ]-------------------
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local IsPrimary = EffectUtility.SetPrimary({Model})
		
		local Knife = Model:FindFirstChild("Knife")
		local Assets = script.Assets
		
		--------------------- [ Setup ]---------------------
		local SFX = Job:Task(EffectUtility.AddSFX(script.Windup, RootPart, 0.5))
		
		-->> Stunt Knife
		local StuntKnife = Job:Task(Assets.StuntKnife:Clone())
		ModelTransparency(StuntKnife, 1)
		StuntKnife.Weld.Part0 = RootPart
		StuntKnife.Parent = Model
		
		-->> Image Vignette & ColorCorrection
		local VignetteUI : ImageLabel
		local ColorCorrection : ColorCorrectionEffect
		IsPrimary(function()
			local _Vignette = Job:Task(script.Vignette:Clone())
			VignetteUI = _Vignette.Image
			
			ColorCorrection = Job:Task(Instance.new("ColorCorrectionEffect"))
			ColorCorrection.Parent = Lighting
		end)
		
		-->> Lighting
		Job:Task(function()
			Lighting.Brightness = OldLighting.Brightness
			Lighting.ExposureCompensation = OldLighting.ExposureCompensation
		end)
		
		---------------------- [ VFX ]----------------------
		--local Active = {}
		
		local VFX = {
			["1"] = function()
				EffectUtility.Emit(StuntKnife.Handle.flick)
				ModelTransparency(StuntKnife, 0);
				
				if Knife then
					ModelTransparency(Knife, 1)
				end;
				
				IsPrimary(function()
					CameraShake(1, 4, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.05)
					Vignette(Color3.new(1, 0, 0), 0.92, 0.5)
				end)
			end,
		
			["2"] = function()
				local Effect = Job:Task(EffectUtility.CloneAndToggle(Assets.character.spin, Torso, true))
				
				Job:Task(task.delay(0.19, function()
					EffectUtility.Toggle(Effect, false)
				end))
				
				Job:Task(task.delay(0.12, function()
					Job:Task(EmitMesh(Assets.meshes.spin1, RootPart))
				end))
				
				ModelTransparency(StuntKnife, 1);
				
				if Knife then
					ModelTransparency(Knife, 0)
				end;
				
				IsPrimary(function()
					CameraShake(1, 5, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.3)
				end)
			end,
			
			["3"] = function()
				local Effect = Job:Task(Assets.character.landspin1:Clone())
				Effect.CFrame = RootPart.CFrame
				Effect.Parent = workspace.Terrain
				EffectUtility.EmitAttachment(Effect)
				
				Job:Task(EmitMesh(Assets.meshes.spin2, RootPart))
				IsPrimary(function()
					CameraShake(1.2, 6, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.35)
				end)
			end,
			
			["4"] = function()
				local Dash1 = EffectUtility.CloneAndEmit(Assets.character.dash1, RootPart)
					quickutil:interact(Dash1, "PointLight", "Brightness", 3)
					quickutil:tween_descendant(Dash1, "PointLight", 1.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Brightness = 0}, false)
				Job:Task(EmitMesh(Assets.meshes.dash1, RootPart))
				
				local Beams = Job:Task(script.Assets.beams.normal:Clone())
				Beams.Parent = RootPart
				
				TweenService:Create(Beams,
					TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{["CFrame"] = Beams.CFrame * CFrame.new(0, 0, 2) * CFrame.Angles(0, 0, math.rad(180))}
				):Play()
				
				quickutil:tween_descendant(Beams, "Beam", 0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = 3, Brightness = 0}, true)
				IsPrimary(function()
					CameraShake(3, 7, 0.02, 0.3, Vector3.one * 0.8, Vector3.one * 0.3)
					DashEffects(VignetteUI, ColorCorrection, 1.6)
				end)
			end,
			
			["5"] = function()
				Job:Task(EmitPart(Assets.land, RootPart))
				Job:Task(EmitMesh(Assets.meshes.land, RootPart))
				
				IsPrimary(function()
					CameraShake(1.2, 6, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.5)
				end)
			end,
			
			["6"] = function()
				EffectUtility.CloneAndEmit(Assets.character.slash1, RootPart)
				EffectUtility.CloneAndEmit(Assets.knife.flick, Knife.Handle)
				
				IsPrimary(function()
					CameraShake(2, 6, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.5)
					Vignette(Color3.new(1, 0, 0), 0.83, 0.3)
				end)
			end,
			
			["7"] = function()
				local Dash2 = EffectUtility.CloneAndEmit(Assets.character.dash2, RootPart)
					quickutil:interact(Dash2, "PointLight", "Brightness", 3)
					quickutil:tween_descendant(Dash2, "PointLight", 1.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Brightness = 0}, false)
				Job:Task(EmitMesh(Assets.meshes.dash2, RootPart))
				
				local Beams = Job:Task(script.Assets.beams.normal:Clone())
				Beams.Parent = RootPart

				TweenService:Create(Beams,
					TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{["CFrame"] = Beams.CFrame * CFrame.new(0, 0, 2) * CFrame.Angles(0, 0, math.rad(180))}
				):Play()
				quickutil:tween_descendant(Beams, "Beam", 1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = 1, Brightness = 0}, true)
				
				IsPrimary(function()
					CameraShake(3, 7, 0.02, 0.3, Vector3.one * 0.8, Vector3.one * 0.3)
					DashEffects(VignetteUI, ColorCorrection, 1.7)
				end)
			end,
		}
		
		------------------- [ Velocities ]------------------
		local Velocities = {
			-->> Kick
			["1"] = function()
				local Velocity = Job:Task(CreateVelocity("Atonement Kick", RootPart, 0))
				
				-- Increase
				TweenService:Create(Velocity.Strength, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
					Value = 95
				}):Play()
				
				-- Decrease
				Job:Task(task.delay(0.2, function()
					TweenService:Create(Velocity.Strength, TweenInfo.new(1.25 , Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Value = 0
					}):Play()
				end))
				
				Job:Task(task.delay(1.5, Velocity.Destroy, Velocity))
			end,
			
			-->> Dash 1
			["2"] = function()
				local Velocity = Job:Task(CreateVelocity("Atonement Dash 1", RootPart, 0))
				
				-- Increase
				TweenService:Create(Velocity.Strength, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Value = 110
				}):Play()
				
				-- Decrease
				Job:Task(task.delay(0.3, function()
					TweenService:Create(Velocity.Strength, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						Value = 14
					}):Play()
				end))
			end,
			
			-->> Slice
			["3"] = function()
				local Velocity = Job:Task(CreateVelocity("Atonement Slice", RootPart, 55))
				
				-- Decrease
				TweenService:Create(Velocity.Strength, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					Value = 0
				}):Play()
			end,
			
			-->> Dash 2
			["4"] = function()
				local Velocity = Job:Task(CreateVelocity("Atonement Dash 2", RootPart, 0))

				-- Increase
				TweenService:Create(Velocity.Strength, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Value = 140
				}):Play()

				-- Decrease
				Job:Task(task.delay(0.25, function()
					TweenService:Create(Velocity.Strength, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Value = 0
					}):Play()
				end))
			end,
		}
		
		--------------------- [ Hooks ]---------------------
		Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter : string)
			local Func = VFX[Parameter]
			if Func then
				Func()
			end
		end))
		
		IsPrimary(function()
			Job:Task(Animation:GetMarkerReachedSignal("Velocity"):Connect(function(Parameter : string)
				local Func = Velocities[Parameter]
				if Func then
					Func()
				end
			end))
		end)	
	end,
	
	Hit = function(Model : Model, VictimModel : Model)
		------------------- [ Variables ]-------------------
		local Retrieved = AnimationRetriever.new(Model, Animations.Hit)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local IsPrimary = EffectUtility.SetPrimary({Model, VictimModel})
		local IsMe = (LocalPlayer.Character == Model)

		local Knife = Model:FindFirstChild("Knife")
		local Assets = script.HitAssets

		--------------------- [ Setup ]---------------------
		Job:Task(EffectUtility.AddSFX(script.Start, RootPart, 0.5))
		
		-->> Stunt Knife
		local StuntKnife = Job:Task(Assets.StuntKnife2:Clone())
		ModelTransparency(StuntKnife, 1)
		StuntKnife.Weld.Part0 = RootPart
		StuntKnife.Parent = Model

		---->> ColorCorrection
		local ColorCorrection : ColorCorrectionEffect
		IsPrimary(function()
			ColorCorrection = Instance.new("ColorCorrectionEffect")
			ColorCorrection.Parent = Lighting
		end)
		
		---->> Preload Impact Frames
		local Videos = script.Videos:Clone()
		Videos.Name = "AtonementImpactFrames"
		Videos.Parent = LocalPlayer.PlayerGui
		
		Job:Task(function()
			task.delay(10, Videos.Destroy, Videos)
		end)
		
		Job:Task(function()
			local OldHeadTracking = LocalPlayer:GetAttribute("Head_Tracking")

			if not OldHeadTracking then
				Job:Task(function()
					workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
					LocalPlayer:SetAttribute("Head_Tracking", OldHeadTracking)
				end)
			end
			
			LocalPlayer:SetAttribute("Head_Tracking", true)
		end)

		---------------------- [ VFX ]----------------------
		local Active = {}
		
		local VFX = {
			["1"] = function()
				EffectUtility.CloneAndEmit(Assets.character.land, RootPart)
				
				IsPrimary(function()
					CameraShake(3, 6, 0.03, 0.2, Vector3.one * 0.5, Vector3.one * 0.4)
				end)
			end,
			
			["2"] = function()
				local Highlight = Job:Task(Instance.new("Highlight"))
				Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
				Highlight.FillColor = Color3.new(0, 0, 0)
				Highlight.FillTransparency = 0.2
				Highlight.OutlineTransparency = 1
				Highlight.Parent = Model
				
				quickutil:tween_single(Highlight, 1.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {FillTransparency = 1}, true)
				
				EffectUtility.CloneAndEmit(Assets.character.slash1, RootPart)
				
				if Knife then
					EffectUtility.CloneAndEmit(Assets.knife.flicknormal, Knife.Handle)
				end;
				
				IsPrimary(function()
					CameraShake(3, 5, 0.04, 0.2, Vector3.one * 0.5, Vector3.one * 0.4)
					Vignette(Color3.new(1, 0, 0), 0.8, 0.3)
				end)
			end,
			
			["3"] = function()
				EffectUtility.CloneAndEmit(Assets.character.slash2, RootPart)
				
				if Knife then
					EffectUtility.CloneAndEmit(Assets.knife.flicknormal, Knife.Handle)
				end;
				
				IsPrimary(function()
					CameraShake(3, 5, 0.05, 0.3, Vector3.one * 0.8, Vector3.one * 0.6)
					Vignette(Color3.new(1, 0, 0), 0.8, 0.3)
				end)
			end,
			
			["4"] = function()
				Active["Slash3"] = Job:Task(EffectUtility.CloneAndEmit(Assets.character.slash3, RootPart, true))
				
				if Knife then
					Active["Flick"] = Job:Task(EffectUtility.CloneAndEmit(Assets.knife.flick, Knife.Handle, true))
				end;
				
				quickutil:interact(Active["Slash3"], "ParticleEmitter", "TimeScale", 1);
				
				if Knife then
					quickutil:interact(Active["Flick"], "ParticleEmitter", "TimeScale", 1);
				end;
				
				quickutil:tween_descendant(Active["Slash3"], "ParticleEmitter", .1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TimeScale = 0.02});
				
				if Knife then
					quickutil:tween_descendant(Active["Flick"], "ParticleEmitter", .1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TimeScale = 0.02})
				end;
				
				Job:Task(task.delay(0.684 + 0.1, function()
					quickutil:tween_descendant(Active["Slash3"], "ParticleEmitter", 1.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TimeScale = 1})
					
					if Knife then
						quickutil:tween_descendant(Active["Flick"], "ParticleEmitter", 1.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TimeScale = 1})
					end;
				end))
				
				IsPrimary(function()
					Vignette(Color3.new(1, 0, 0), 0.7, 3)
					
					Job:Task(Yuki_FOV.Tween(60, {0.684, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out}))
					Job:Task(task.delay(0.684, function()
						Job:Task(Yuki_FOV.Tween(70, {0.183, Enum.EasingStyle.Sine, Enum.EasingDirection.In}))
					end))
				end)
			end,
			
			--["5"] = function()
				
			--end,
			
			["6"] = function()
				Job:Task(EffectUtility.Emit(StuntKnife.Handle.flick, true))
				
				IsPrimary(function()
					CameraShake(5, 5, 0.05, 0.3, Vector3.one * 0.4, Vector3.one * 0.2)
					Vignette(Color3.new(1, 0, 0), 0.92, 0.5)
				end)
			end,
			
			["7"] = function()
				EffectUtility.CloneAndEmit(Assets.character.eye, Model.Head)
			end,
			
			["8"] = function()
				Job:Task(EmitPart(Assets.tp1, RootPart))
				Job:Task(EmitMesh(Assets.meshes.tp, RootPart))
				
				IsPrimary(function()
					CameraShake(3.5, 5, 0.05, 0.4, Vector3.one * 0.8, Vector3.one * 0.6)
				end)
			end,
			
			["9"] = function()
				Job:Task(EmitPart(Assets.tp2start, RootPart))
				
				local Effect : Object = Assets.tp2:Clone()
				Effect:PivotTo(RootPart.CFrame * Assets.tp2.CFrame)
				Effect.Parent = workspace.Visuals
				
				EffectUtility.ToggleForTime(Effect, 0.54)
				
				IsPrimary(function()
					Lighting.Brightness = 1
					Lighting.ExposureCompensation = 0.5
					ColorCorrection.TintColor = Color3.fromRGB(255, 91, 91)
					ColorCorrection.Contrast = 3
					Job:Task(task.wait(0.03))
					Lighting.Brightness = 1.325
					Lighting.ExposureCompensation = 0.25
					ColorCorrection.TintColor = Color3.fromRGB(255, 0, 0)
					ColorCorrection.Contrast = 0
					Job:Task(task.wait(0.03))
					Lighting.Brightness = OldLighting.Brightness
					Lighting.ExposureCompensation = OldLighting.ExposureCompensation
					ColorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
					ColorCorrection.Contrast = 0
					Job:Task(task.wait(0.03))
					
					local LightingTween = TweenService:Create(Lighting, TweenInfo.new(1.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Brightness = 1, ExposureCompensation = -0.2})
					local CCTween = TweenService:Create(ColorCorrection, TweenInfo.new(1.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TintColor = Color3.fromRGB(255, 206, 206), Contrast = 0.5})
					LightingTween:Play()
					CCTween:Play()
					
					Job:Task(Yuki_FOV.Tween(55, {1.184, Enum.EasingStyle.Quad, Enum.EasingDirection.Out}))
					Job:Task(task.delay(1.184, Yuki_FOV.Set, 70))
					
					Job:Task(function()
						Yuki_FOV.Reset()
						LightingTween:Destroy()
						CCTween:Destroy()
						
						TweenService:Create(Lighting, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Brightness = OldLighting.Brightness, ExposureCompensation = OldLighting.ExposureCompensation}):Play()
						TweenService:Create(ColorCorrection, TweenInfo.new(1.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TintColor = Color3.fromRGB(255, 255, 255), Contrast = 0}):Play()
						task.wait(1.05)
						ColorCorrection:Destroy()
					end)
				end)
			end,
		}
		
		--------------------- [ Hooks ]---------------------
		Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter : string)
			local Func = VFX[Parameter]
			if Func then
				Func()
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("KnifeTransparency"):Connect(function(Parameter : string)
			local Value = tonumber(Parameter)
			
			if Knife then
				ModelTransparency(Knife, Value);
			end;
			
			ModelTransparency(StuntKnife, if Value == 0 then 1 else 0)
		end))
		
		if IsMe then
			Job:Task(Animation:GetMarkerReachedSignal("Teleport"):Connect(function(Parameter : string)
				if Parameter == "Disappear" then
					LocalPlayer:SetAttribute("Head_Tracking", false)
					workspace.CurrentCamera.CameraSubject = VictimModel.Head
				end
			end))
		end
		
		Job:Task(function()
			for _, Effect in pairs(Active) do
				Effect:Destroy()
				Effect = nil
			end
			
			if Knife then
				ModelTransparency(Knife, 0);
			end;
		end)
	end,
	
	Lose = function(Model : Model, VictimModel : Model)
		------------------- [ Variables ]-------------------
		-->> User
		local Retrieved = AnimationRetriever.new(Model, Animations.Lose)
		--if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		
		-->> Victim
		local VictimRetrieved = AnimationRetriever.new(VictimModel, Animations.VictimLose)
		--if (VictimRetrieved == nil) then return end

		local VictimTorso, VictimRootPart = VictimRetrieved.Torso, VictimRetrieved.RootPart
		local VictimAnimation, VictimJob = VictimRetrieved.Animation, VictimRetrieved.Job
		
		-->> Etc
		local IsPrimary = EffectUtility.SetPrimary({Model, VictimModel})
		local IsMe = (LocalPlayer.Character == Model)

		local Knife = Model:FindFirstChild("Knife")
		local Assets = script.LoseAssets

		--------------------- [ Setup ]---------------------
		local SFX = Job:Task(EffectUtility.AddSFX(script.Lose, RootPart, 0.5))
		
		-->> Stunt Knife
		local StuntKnife = Job:Task(script.HitAssets.StuntKnife2:Clone())
		ModelTransparency(StuntKnife, 1)
		StuntKnife.Weld.Part0 = RootPart
		StuntKnife.Parent = Model
		
		---->> ColorCorrection
		local VignetteUI : ImageLabel
		local ColorCorrection : ColorCorrectionEffect
		IsPrimary(function()
			local _Vignette = Job:Task(script.Vignette:Clone())
			VignetteUI = _Vignette.Image

			ColorCorrection = Job:Task(Instance.new("ColorCorrectionEffect"))
			ColorCorrection.Parent = Lighting
		end)

		IsPrimary(function()
			local OldHeadTracking = LocalPlayer:GetAttribute("Head_Tracking")

			if not OldHeadTracking then
				Job:Task(function()
					workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
					LocalPlayer:SetAttribute("Head_Tracking", OldHeadTracking)
				end)
				LocalPlayer:SetAttribute("Head_Tracking", true)
			end
		end)
		
		-- FOV
		IsPrimary(function()
			Job:Task(Yuki_FOV.Reset())
		end)

		---------------------- [ VFX ]----------------------
		local Active = {}

		local VFX = {
			["1"] = function()
				EffectUtility.CloneAndEmit(Assets.character.start, RootPart)
				
				IsPrimary(function()
					CameraShake(3, 5, 0.1, 0.3, Vector3.one * 0.8, Vector3.one * 0.3)
				end)
			end,

			["2"] = function()
				Job:Task(EmitPart(Assets.tp1, RootPart))
				Job:Task(EmitMesh(Assets.meshes.tp, RootPart))
				--
				IsPrimary(function()
					CameraShake(3.4, 7, 0.05, 0.35, Vector3.one * 0.8, Vector3.one * 0.6)
				end)
			end,

			["3"] = function()
				Job:Task(EmitPart(Assets.tp2, RootPart))
				
				IsPrimary(function()
					CameraShake(3.7, 7, 0.05, 0.35, Vector3.one * 0.8, Vector3.one * 0.6)
					
					Job:Task(Yuki_FOV.Tween(55, {0.334, Enum.EasingStyle.Cubic, Enum.EasingDirection.In}))
					Job:Task(task.delay(0.334, Yuki_FOV.Reset))
				end)
			end,

			["4"] = function()
				-- Kick
				EffectUtility.CloneAndEmit(Assets.character.kick, RootPart)
				Job:Task(EmitMesh(Assets.meshes.kick, RootPart))
				
				-- Beams
				local Beams = Job:Task(Assets.beams.kick:Clone())
				Beams.Parent = RootPart

				TweenService:Create(Beams,
					TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{["CFrame"] = Beams.CFrame * CFrame.new(0, 0 ,-3) * CFrame.Angles(0, 0, math.rad(150))}
				):Play()

				quickutil:tween_descendant(Beams, "Beam", 0.71, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = 2, Brightness = 0}, true)
				
				--Highlight
				local Highlight = Job:Task(Instance.new("Highlight"))
				Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
				Highlight.FillColor = Color3.new(0, 0, 0)
				Highlight.FillTransparency = 0.2
				Highlight.OutlineTransparency = 1
				Highlight.Parent = Model

				quickutil:tween_single(Highlight, 1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {FillTransparency = 1}, true)
				
				-- Lighting
				IsPrimary(function()
					VignetteUI.ImageTransparency = 0.2
					Lighting.Brightness = 0.3
					Lighting.ExposureCompensation = -1
					
					Job:Task(task.wait(0.02))
					Lighting.ExposureCompensation = 0.5
					
					local t1 = Job:Task(TweenService:Create(VignetteUI, TweenInfo.new(1.33, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 1}))
					local t2 = Job:Task(TweenService:Create(Lighting, TweenInfo.new(1.33, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Brightness = OldLighting.Brightness, ExposureCompensation = OldLighting.ExposureCompensation}))
					
					t1:Play()
					t2:Play()
				end)
				
				IsPrimary(function()
					CameraShake(20, 20, 0.1, 0.2, Vector3.one * 0.3 * Vector3.one * 0.9)
				end)
			end,

			["5"] = function()
				EffectUtility.CloneAndEmit(Assets.character.nicetry, Model.Head)
			end,

			["6"] = function()
				local Effect : Object = Job:Task(Assets.pull:Clone())
				Effect:PivotTo(RootPart.CFrame * Assets.pull.CFrame)
				Effect.Parent = workspace.Visuals

				EffectUtility.Toggle(Effect, true)
				Active["Pull"] = Effect
			end,

			["7"] = function()
				if Active["Pull"] then
					EffectUtility.Toggle(Active["Pull"], false)
				end
				
				local ArmHighlight = Job:Task(Instance.new("Highlight"))
				ArmHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
				ArmHighlight.FillColor = Color3.fromRGB(57, 0, 0)
				ArmHighlight.FillTransparency = 0.2
				ArmHighlight.OutlineColor = Color3.fromRGB(186, 37, 37)
				ArmHighlight.OutlineTransparency = 0
				ArmHighlight.Parent = Model["Right Arm"]
				
				quickutil:tween_single(ArmHighlight, 1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {FillTransparency = 1, OutlineTransparency = 1}, true)
				
				IsPrimary(function()
					CameraShake(1.5, 1.5, 0.04, 0.2, Vector3.one * 0.4, Vector3.one * 0.3)
				end)
			end,
		}
		
		local VictimVFX = {
			["1"] = function()
				EffectUtility.CloneAndEmit(Assets.victimcharacter.roll, VictimRootPart)
				
				IsPrimary(function()
					CameraShake(3, 3, 0.01, 0.3, Vector3.one * 0.5, Vector3.one * 0.3)
				end)
			end,
			
			["2"] = function()
				-- Stab
				local Stab = EffectUtility.CloneAndEmit(Assets.character.stab, RootPart)
				
				-- Light
				local StabLight : PointLight = Stab:FindFirstChild("PointLight")
				if StabLight then
					StabLight.Brightness = 2
					quickutil:tween_descendant(StabLight, "PointLight", 2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Brightness = 0})
				end
				
				-- Pulse
				EffectUtility.Toggle(StuntKnife.BladeInner.pulsing, true)
				
				-- Beams
				local Beams = Job:Task(Assets.beams.normal:Clone())
				Beams.Parent = RootPart

				TweenService:Create(Beams,
					TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{["CFrame"] = Beams.CFrame * CFrame.new(0, 0 ,-6) * CFrame.Angles(0, 0, math.rad(180))}
				):Play()

				quickutil:tween_descendant(Beams, "Beam", 0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = 5, Brightness = 0}, true)
				
				-- Stab Mesh
				Job:Task(EmitMesh(Assets.meshes.stab, RootPart))
				
				--Highlight
				local Highlight = Job:Task(Instance.new("Highlight"))
				Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
				Highlight.FillColor = Color3.fromRGB(42, 136, 150)
				Highlight.FillTransparency = 13
				Highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
				Highlight.OutlineTransparency = 0.6
				Highlight.Parent = Model

				quickutil:tween_single(Highlight, 1.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {FillTransparency = 1, OutlineTransparency = 1}, true)
				
				-- Lighting
				IsPrimary(function()
					VignetteUI.ImageTransparency = 0
					Lighting.Brightness = 0.1
					Lighting.ExposureCompensation = 1

					Job:Task(task.wait(0.02))
					VignetteUI.ImageTransparency = 0.5

					local t1 = Job:Task(TweenService:Create(VignetteUI, TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 1}))
					local t2 = Job:Task(TweenService:Create(Lighting, TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Brightness = OldLighting.Brightness, ExposureCompensation = OldLighting.ExposureCompensation}))

					t1:Play()
					t2:Play()
				end)
				
				IsPrimary(function()
					CameraShake(6, 20, 0.07, 0.25, Vector3.one * 0.8, Vector3.one * 0.8)

					Yuki_FOV.Set(37)
					Job:Task(Yuki_FOV.Tween(70, {0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out}))
				end)
			end,
			
			["3"] = function()
				EffectUtility.Toggle(StuntKnife.BladeInner.pulsing, false) --
			end,
		}

		--------------------- [ Hooks ]---------------------
		Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter : string)
			local Func = VFX[Parameter]
			if Func then
				Func()
			end
		end))
		
		Job:Task(VictimAnimation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter : string)
			local Func = VictimVFX[Parameter]
			if Func then
				Func()
			end
		end))

		if IsMe then
			Job:Task(Animation:GetMarkerReachedSignal("Teleport"):Connect(function(Parameter : string)
				if Parameter == "Disappear" then
					LocalPlayer:SetAttribute("Head_Tracking", false)
					workspace.CurrentCamera.CameraSubject = VictimModel.Head
				else
					workspace.CurrentCamera.CameraSubject = Model.Humanoid
					LocalPlayer:SetAttribute("Head_Tracking", true)
				end
			end))
		end
		
		Job:Task(Animation:GetMarkerReachedSignal("KnifeTransparency"):Connect(function(Parameter : string)
			local Value = tonumber(Parameter)

			if Knife then
				ModelTransparency(Knife, Value);
			end;
			
			ModelTransparency(StuntKnife, if Value == 0 then 1 else 0)
		end))

		Job:Task(function()
			if Knife then
				ModelTransparency(Knife, 0);
			end;
		end)
	end,
}