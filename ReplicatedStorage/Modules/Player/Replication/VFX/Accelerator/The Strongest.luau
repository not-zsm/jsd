local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local CurrentCamera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local ImpactFrames = LocalPlayer.PlayerGui.ImpactFrames.AcceleratorStrongest

local function do_zat_impact_framu(Type : string)
	EffectUtility.ToggleImpactFrames(ImpactFrames, false)

	local FrameStage : Frame = ImpactFrames[Type]

	for _, Frame : ImageLabel in ipairs(FrameStage:GetDescendants()) do
		if Frame:IsA("ImageLabel") then
			Frame.Visible = true
		end
	end

	for Index = 1, #FrameStage:GetChildren(), 1 do
		task.wait(0.02)

		local Frame : ImageLabel = FrameStage[Index]
		Frame.Visible = false
	end
end

--function ImpactFrames(Type : string)
--local ImpactFrames : Frame = LocalPlayer.PlayerGui.ImpactFrames.AcceleratorStrongest[Type]
--EffectUtility.ToggleImpactFrames(ImpactFrames, true)

--do
--	EffectUtility.ToggleImpactFrames(ImpactFrames, false)

--	for _, Frame : ImageLabel in ipairs(ImpactFrames:GetDescendants()) do
--		if Frame:IsA("ImageLabel") then
--			Frame.Visible = true
--		end
--	end

--	for Index = 1, #ImpactFrames:GetChildren(), 1 do
--		task.wait(0.025)

--		local Frame : ImageLabel = ImpactFrames[Index]
--		Frame.Visible = false
--	end
--end
--end

function EmitAttachment(Attachment : Attachment, Parent : BasePart)
	local Lifetime = 0

	local NewAttachment = Attachment:Clone()
	NewAttachment.Parent = Parent

	for _, Particle : ParticleEmitter in ipairs(NewAttachment:GetDescendants()) do
		if Particle:IsA("ParticleEmitter") then
			local EmitCount : number = Particle:GetAttribute("EmitCount") or 1
			local EmitDelay : number = Particle:GetAttribute("EmitDelay") or 0
			local EnableDuration : number = Particle:GetAttribute("EnableDuration") or 0

			if (EnableDuration > 0) then
				Particle.Enabled = true

				task.delay(EnableDuration, function()
					Particle.Enabled = false
				end)
			end

			if (EmitDelay > 0) then
				task.delay(EmitDelay, Particle.Emit, Particle, EmitCount)
			else
				Particle:Emit(EmitCount)
			end

			Lifetime = math.max(Lifetime, EmitDelay + EnableDuration + (Particle.Lifetime.Min + Particle.Lifetime.Max) / Particle.TimeScale)
		end
	end

	task.delay(Lifetime, NewAttachment.Destroy, NewAttachment)
end

function VFX.Start(RootPart : BasePart)
	local CleanFOVRunner = Yuki_FOV.AnimateWithMoonFile(script.FOV)
	local Replication : Configuration = AttributeListener.GetReplicationFromSource(LocalPlayer)

	local Camera = script.Camera:Clone()
	Camera:PivotTo(RootPart.CFrame)
	Camera.Parent = workspace.Visuals

	local Animation = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Accelerator["The Strongest"].Camera)
	Animation:Play(0)

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

	local Clean = RunCameraRig(RootPart, Camera)

	task.spawn(function()
		local IconModule = require(ReplicatedStorage.Modules.Icon)
		IconModule.setTopbarEnabled(false)
	end)

	AttributeListener.new(LocalPlayer, "AcceleratorTheStrongest", function()
		Clean()
		CleanFOVRunner()

		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

		task.spawn(function()
			local IconModule = require(ReplicatedStorage.Modules.Icon)
			IconModule.setTopbarEnabled(true)
		end)
	end)

	EffectUtility.ToggleImpactFrames(ImpactFrames, true)

	local AllLoaded = false

	for _, Frame : ImageLabel in ipairs(ImpactFrames.Start:GetChildren()) do
		AllLoaded = Frame.IsLoaded
	end

	if AllLoaded then
		task.spawn(do_zat_impact_framu, "Start")
	end
end

function VFX.AttackerRoot(RootPart : BasePart, Type : number)
	EmitAttachment(script.AttackerRoot[Type], RootPart)

	if Type == 1 then
		local Distance =  LocalPlayer:DistanceFromCharacter(RootPart.Position)
		
		if Distance < 40 then
			CameraShake(3.5, 22.5, 0.01, 0.4)
			Vignette(Color3.fromRGB(86, 24, 157), 0.4, 0.25)
		end
		
		if Distance < 75 then
			RockHandler.Crater((RootPart.CFrame * CFrame.new(0, 0,  -20)).Position, Vector3.yAxis * -10, {
				Amount = 24,
				Distance = 10,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -9,
					Max = 9
				},

				Exposure = {
					Min = 0.6,
					Max = 0.7
				},

				BaseX = 3,
				BaseZ = 2.25,
				
				SizeMultiplier = 1.25,
			})
		end
		
	elseif Type == 12 then
		task.spawn(VFX.Tornado, RootPart)
	end
end

function VFX.ImpactFrame(Type : string, Player : Player, VictimPlayer : Player)
	if LocalPlayer == Player or LocalPlayer == VictimPlayer then
		task.spawn(do_zat_impact_framu, Type)
	end
end

function VFX.AttackerTorso(Torso : BasePart, Type : number)
	EmitAttachment(script.AttackerTorso[Type], Torso)
end

function VFX.AttackerRightArm(Arm : BasePart, Type : number)
	EmitAttachment(script.AttackerRightArm[Type], Arm)
end

function VFX.VictimTorso(Torso : BasePart, Type : number)
	EmitAttachment(script.VictimTorso[Type], Torso)
end

function VFX.Tornado(RootPart : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) then return end
	
	local Tornado1 = script.Tornado.t1:Clone()
	Tornado1.CFrame = RootPart.CFrame * CFrame.new(-9.408, -50, -65.766)
	Tornado1.Size = Vector3.new(90.099, 80.343, 86.513)

	local Tornado2 = script.Tornado.t2:Clone()
	Tornado2.CFrame = RootPart.CFrame * CFrame.new(-9.408, -50, -65.766)
	Tornado2.Size = Vector3.new(100.019, 100, 115.994)

	Tornado1.Parent = workspace.Visuals
	Tornado2.Parent = workspace.Visuals

	TweenService:Create(Tornado1, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{CFrame = Tornado1.CFrame + Vector3.new(0, 80, 0)}
	):Play()

	TweenService:Create(Tornado2, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{CFrame = Tornado2.CFrame + Vector3.new(0, 80, 0)}
	):Play()

	Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Tornado1, function(Delta)
		Tornado1.Orientation -= Vector3.new(0, 10, 0)
	end)

	Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Tornado2, function(Delta)
		Tornado2.Orientation -= Vector3.new(0, 10, 0)
	end)

	task.delay(3.8, function()
		for _, Item in ipairs(Tornado2:GetDescendants()) do
			if Item:IsA("Beam") then
				Item.Enabled = false
			end
		end
		
		TweenService:Create(Tornado1, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{Transparency = 1}
		):Play()

		TweenService:Create(Tornado2, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{Transparency = 1}
		):Play()
	
		task.wait(0.4)

		Tornado1:Destroy()
		Tornado2:Destroy()
	end)
end

function VFX.Background(RootPart : BasePart)
	if LocalPlayer:GetAttribute("Cutscenes") then
		local Background = script.Background:Clone()
		Background.CFrame = RootPart.CFrame * CFrame.new(0, 560, -90)
		Background.Parent = workspace.Visuals
		task.delay(0.9166666666666666, Background.Destroy, Background)
	end
end

function VFX.HitSFX(RootPart : BasePart, VictimRootPart : BasePart)
	local PlayerIsAttackerOrVictim = (LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or LocalPlayer == Players:GetPlayerFromCharacter(VictimRootPart.Parent))

	local Sound = script.HitSFX:Clone()
	Sound.Parent = PlayerIsAttackerOrVictim and workspace or RootPart.Parent.Torso
	Sound:Play()

	AttributeListener.new(RootPart, "AcceleratorTheStrongest", function()
		TweenService:Create(Sound, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{Volume = 0}
		):Play()

		task.delay(1.5, Sound.Destroy, Sound)
	end)
end

return VFX
