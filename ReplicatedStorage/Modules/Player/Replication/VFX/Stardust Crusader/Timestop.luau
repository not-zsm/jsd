local VFX = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local ArcUtility = EffectUtility.Arc

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
--local Animations = ReplicatedStorage.Animations.Attacks["Stardust Crusader"]["Timestop"]
local Animations = ReplicatedStorage.Animations.Attacks.Global.Ultimate["Stardust Crusader"]

local Bubble = require( ReplicatedStorage.Modules.Player.Replication.Global.Bubble )

local Stand_VFX = script.VFX.Stand
local User_VFX = script.VFX.User
local SFX = script.SFX

--local function AttachmentSFX(Position : Vector3, Name : string, Duration : number)
--	local Attach = Instance.new("Attachment")
--	Attach.WorldPosition = Position
--	Attach.Parent = workspace.Terrain
--	EffectUtility.AddSFX(SFX[Name], Attach)
--	task.delay(Duration, Attach.Destroy, Attach)
--end

function VFX.Start(Jotaro : Model, TimestopDuration : number)
	local Retrieved = AnimationRetriever.new(Jotaro, Animations.Start)
	if (Retrieved == nil) then return end

	local Stand : Model = Jotaro:FindFirstChild("Stand")
	if (Stand == nil) then return end
	
	local UserAnimation = Retrieved.Animation
	local MainJob = Retrieved.Job
	
	local StandRootPart = Stand and Stand:FindFirstChild("HumanoidRootPart")
	local StandTorso = Stand and Stand:FindFirstChild("Torso")

	if (StandRootPart == nil or StandTorso == nil) then return end 

	MainJob:Task(UserAnimation:GetMarkerReachedSignal("vfx_user"):Connect(function(Parameter : string)
		local VFX = User_VFX:FindFirstChild(Parameter)
		
		--if (Parameter == "1") then
		--	EffectUtility.EmitEffects(SFX.Callout, Retrieved.RootPart)
			
		--elseif (Parameter == "2") then
		--	EffectUtility.AddSFX(SFX["Za Warudo"], Retrieved.RootPart)
		--end
		
		if VFX then
			EffectUtility.CloneAndEmit(VFX, Jotaro:FindFirstChild(VFX:GetAttribute("attached")))
			
			if EffectUtility.Distance_Close(Jotaro) then
				CameraShake(0.9, 12.5, 0.01, 0.6, Vector3.one * 0.8, Vector3.one * 0.4)
			end
		end
	end))
	
	MainJob:Task(UserAnimation:GetMarkerReachedSignal("vfx_stand"):Connect(function(Parameter : string)
		local VFX = Stand_VFX:FindFirstChild(Parameter)

		if VFX then
			EffectUtility.CloneAndEmit(VFX, Stand:FindFirstChild(VFX:GetAttribute("attached")))
			
			if EffectUtility.Distance_Close(Jotaro) then
				CameraShake(0.9, 12.5, 0.01, 0.6, Vector3.one * 0.8, Vector3.one * 0.4)
			end
		end
	end))
	
	local TimestopPosition = Retrieved.RootPart.Position
	
	local SoundEmitter = script.SoundEmitter:Clone()
	SoundEmitter.Position = TimestopPosition
	SoundEmitter.Parent = workspace.Visuals
	EffectUtility.AddSFX(SFX.Start, SoundEmitter)
	task.delay(12, SoundEmitter.Destroy, SoundEmitter)
	
	--if EffectUtility.Distance_Close(Jotaro, 75) then
	--	local Viewport = script.Viewport.Screen:Clone()
	--	Viewport.Enabled = true
	--	Viewport.Parent = LocalPlayer.PlayerGui
		
	--	MainJob:Task(Viewport)
		
	--	local Frame = Viewport.Frame
	--	local WorldModel = Frame.WorldModel
	--	local Rig = WorldModel.Rig
		
	--	Frame.ImageTransparency = 1
		
	--	local Animation = Rig.Humanoid.Animator:LoadAnimation(script.Viewport.User)
		
	--	task.spawn(function()
	--		repeat task.wait() until Animation.Length > 0

	--		local Aura = script.Viewport.Aura:Clone()
	--		Aura.CFrame = CFrame.new(3, -1, -2)
	--		Aura.Parent = workspace.CurrentCamera
	--		MainJob:Task(Aura)

	--		local Info = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	--		TweenService:Create(Aura, Info, 
	--			{CFrame = Aura.CFrame * CFrame.new(-2, 0, 0)}
	--		):Play()
			
	--		TweenService:Create(Frame, Info,
	--			{ImageTransparency = 0}
	--		):Play()
	
	--		TweenService:Create(Rig.HumanoidRootPart, Info,
	--			{CFrame = Rig.HumanoidRootPart.CFrame * CFrame.new(2, 0, 0)}
	--		):Play()
			
	--		Animation:GetMarkerReachedSignal("pause"):Once(function()
	--			Animation:AdjustSpeed(0)
	--		end)

	--		Animation:Play(0)
	--	end)
	--end

	MainJob:Task(UserAnimation:GetMarkerReachedSignal("timestop"):Connect(function()
		local Affected = (LocalPlayer:DistanceFromCharacter(Jotaro.PrimaryPart.Position) <= 75)
		
		local Attachment1 = User_VFX["3"]:Clone()
		local Attachment2 = User_VFX["4"]:Clone()
		Attachment1.Parent, Attachment2.Parent = Retrieved.RootPart, Retrieved.RootPart
		EffectUtility.EmitAttachment(Attachment1)
		EffectUtility.EmitAttachment(Attachment2, true)
		
		local TimeScaleInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

		for _, ParticleEmitter in pairs(Attachment2:GetDescendants()) do 
			if ParticleEmitter.ClassName == "ParticleEmitter" then
				TweenService:Create(ParticleEmitter, TimeScaleInfo, {TimeScale = 0}):Play()
			end 
		end

		local Color1 = script.ColorCorrection:Clone()
		local Vignette = script.Vignette:Clone()
		
		local ClockTicking = true
		
		if Affected then
			local Color2 = script.ColorCorrection2:Clone()

			Color1.Parent, Color2.Parent = Lighting, Lighting
			Vignette.Parent = LocalPlayer.PlayerGui

			Color1.Enabled, Color2.Enabled = true, true

			Color2.Contrast = -2
			Color2.Saturation = -2
			
			CameraShake(3.5, 20, 0.01, 1.25, Vector3.one * 0.5, Vector3.one * 0.8)

			do
				Yuki_FOV.Tween(100, {0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out})

				task.delay(0.75, function()
					Yuki_FOV.Tween(80, {1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut})
				end)
			end
		
			task.spawn(function()
				for Index = 1, 10 do
					Bubble(TimestopPosition, 3, Vector3.zero, Vector3.one * 300, 0.65)
					task.wait(0.15)
				end
			end)
			
			task.spawn(function()
				while task.wait(1) do
					if not ClockTicking then
						break
					end
					
					SoundService:PlayLocalSound(SFX.ClockTick)
					--print("tick")
				end
			end)
			
			TweenService:Create(Vignette.Pulse, TimeScaleInfo, {ImageTransparency = 0.5}):Play()
			TweenService:Create(Color2, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Contrast = 0, Saturation = 0}):Play()

			task.delay(1.3, function()
				Color2.Enabled = false
			end)
		end
		
		--AttachmentSFX(TimestopPosition, "Timestop", 3)

		task.wait(TimestopDuration) -- timestop duration
		
		ClockTicking = false
		
		--if Affected then
		--	AttachmentSFX(TimestopPosition, "Timeresume", 2)
		--end

		Color1.Enabled = false
		TweenService:Create(Vignette.Pulse, TimeScaleInfo, {ImageTransparency = 1}):Play()

		for _, ParticleEmitter in pairs(Attachment2:GetDescendants()) do 
			if ParticleEmitter.ClassName == "ParticleEmitter" then 
				TweenService:Create(ParticleEmitter, TimeScaleInfo, {TimeScale = 1}):Play()
			end 
		end
		
		task.delay(5, Attachment2.Destroy, Attachment2)

		if Affected then
			Yuki_FOV.Tween(70, {TimeScaleInfo.Time, TimeScaleInfo.EasingStyle, TimeScaleInfo.EasingDirection})
		end
	end))
	
	if EffectUtility.Distance_Close(Jotaro) then
		CameraShake(1, 15, 0.01, 0.75, Vector3.one * 0.8, Vector3.one * 0.25)
		Yuki_FOV.Tween(50, {0.9666666666666667, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
	end
	
	ArcUtility.CloneAndEmit(Stand_VFX["1"], StandTorso) -- if you want to emit
	ArcUtility.CloneAndEmit(Stand_VFX["e1"], StandTorso) -- if you want to emit
end

return VFX