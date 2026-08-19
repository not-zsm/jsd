local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CurrentCamera = workspace.CurrentCamera
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local ImpactFrames : Frame =  LocalPlayer.PlayerGui.ImpactFrames.GojoRuthlessMassacre

local VFX = {}

local function VFXOnPart(Directory : string, Type : string, Part : BasePart)
	local Effect = script[Directory][Type]:Clone()
	Effect.Parent = Part
	EffectUtility.Emit(Effect)
end

local BlackFlashes = {}
local Reds = {}
local Blues = {}

function VFX.Start(RootPart : BasePart)
	RootPart.Parent:SetAttribute("MuteUltimate", true)
	--EffectUtility.EmitEffects(script.StartupSFX, RootPart)
end

function VFX.Miss(RootPart : BasePart)
	RootPart.Parent:SetAttribute("MuteUltimate", false)
end

function VFX.Hit(RootPart : BasePart, VictimRootPart : BasePart)
	VictimRootPart.Parent:SetAttribute("MuteUltimate", true)
	
	local function Unmute()
		if (RootPart ~= nil and RootPart.Parent ~= nil) then
			RootPart.Parent:SetAttribute("MuteUltimate", false)
		end

		if (VictimRootPart ~= nil and VictimRootPart.Parent ~= nil) then
			VictimRootPart.Parent:SetAttribute("MuteUltimate", false)
		end
	end
	
	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or LocalPlayer == Players:GetPlayerFromCharacter(VictimRootPart.Parent) then
		SoundService:PlayLocalSound(script.HitSFX.hit)
		task.delay(script.HitSFX.hit.TimeLength, Unmute)
		
		EffectUtility.ToggleImpactFrames(ImpactFrames, true)
	else
		local _, Attahment = EffectUtility.EmitEffects(script.HitSFX, RootPart.Parent.Torso)
		Attahment.Destroying:Once(Unmute)
	end
end

function VFX.Footstep(Foot : Attachment)
	local Raycast = workspace:Raycast(Foot.WorldPosition + Vector3.yAxis * 2, Vector3.yAxis * -15, Utility.VisualParams)
	
	if (Raycast ~= nil) then
		CameraShake(0.6, 7.5, 0.1, 0.15, Vector3.one * 0.8)
		
		local Effect = script.Windup.Assets.Step:Clone()
		Effect.WorldPosition = Raycast.Position
		Effect.Parent = workspace.Terrain
		EffectUtility.Emit(Effect)
	end
end

function VFX.Swing(RootPart : BasePart)
	local Effect = script.Windup.Assets.Swing:Clone()
	Effect.Parent = RootPart
	EffectUtility.Emit(Effect)
end

function VFX.LeftArm1(Part : BasePart)
	VFXOnPart("LeftArm", "1", Part)
end

function VFX.LeftArm2(Part : BasePart)
	VFXOnPart("LeftArm", "2", Part)
end

function VFX.RedEnable(Part : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(Part.Position)

	if Distance <= 30 then
		ScreenPulse("Black Flash")
		CameraShake(2.5, 25, 0.1, 0.25, Vector3.one * 0.8)
	end
	
	local Effect = script.LeftArm.red:Clone()
	Effect.Parent = Part
	EffectUtility.Emit(Effect, true)
	EffectUtility.Toggle(Effect, true)
	Reds[Part] = Effect
end

function VFX.RedDisable(Part : BasePart)
	if Reds[Part] then
		EffectUtility.Toggle(Reds[Part], false)
		task.delay(2, Reds[Part].Destroy, Reds[Part])
	end
end

function VFX.BlueEnable(Part : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(Part.Position)

	if Distance <= 30 then
		ScreenPulse("Blue Choose")
		CameraShake(2.5, 25, 0.1, 0.25, Vector3.one * 0.8)
	end
	
	local Effect = script.LeftArm.blue:Clone()
	Effect.Parent = Part
	EffectUtility.Emit(Effect, true)
	EffectUtility.Toggle(Effect, true)
	Blues[Part] = Effect
	
	task.delay(0.5, function()
		if Blues[Part] then
			EffectUtility.Toggle(Blues[Part], false)
			task.delay(2, Blues[Part].Destroy, Blues[Part])
		end
	end)
end

function VFX.BlueDisable(Part : BasePart)
	
end

function VFX.RightArm1(Part : BasePart)
	VFXOnPart("RightArm", "1", Part)
end

function VFX.RightArm2(Part : BasePart)
	VFXOnPart("RightArm", "2", Part)
end

function VFX.AttackerRootPart1(Part : BasePart)
	VFXOnPart("AttackerRootPart", "1", Part)
end

function VFX.AttackerRootPart2(Part : BasePart)
	VFXOnPart("AttackerRootPart", "2", Part)
end

function VFX.AttackerRootPart3(Part : BasePart)
	VFXOnPart("AttackerRootPart", "3", Part)
end

function VFX.ShootRed(Part : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(Part.Position)

	if Distance <= 30 then
		ScreenPulse("Black Flash")
		CameraShake(1, 10, 0.1, 0.2, Vector3.one * 0.8)
	end
	
	VFXOnPart("AttackerRootPart", "red", Part)
end

function VFX.AttackerRootPart25(Part : BasePart)
	VFXOnPart("AttackerRootPart", "25", Part)
end

function VFX.AttackerRootPart33(Part : BasePart)
	VFXOnPart("AttackerRootPart", "33", Part)
end

function VFX.AttackerRootPart36(Part : BasePart)
	VFXOnPart("AttackerRootPart", "36", Part)
end

function VFX.AttackerRootPart44(Part : BasePart)
	VFXOnPart("AttackerRootPart", "44", Part)
end

function VFX.Teleport(Part : BasePart)
	VFXOnPart("AttackerTorso", "1", Part)
end

function VFX.Victim1(Part : BasePart)
	VFXOnPart("VictimTorso", "1", Part)
end

function VFX.Victim2(Part : BasePart)
	VFXOnPart("VictimTorso", "2", Part)
end

function VFX.Victim3(Part : BasePart)
	VFXOnPart("VictimTorso", "3", Part)
end

function VFX.BlackFlash(Part : BasePart)
	VFXOnPart("VictimTorso", "BF", Part)
end

function VFX.ImpactFrames()
	ImpactFrames.AnchorPoint = Vector2.zero

	for Index = 1, 24, 1 do
		task.wait(1 / 24)

		local Frame : ImageLabel = ImpactFrames[Index]
		Frame.Visible = false
	end
end

function VFX.BlackFlashEnable(Part : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(Part.Position)

	if Distance <= 30 then
		ScreenPulse("Black Flash")
		local Shake = CameraShake(1.5, 15, 0.1, 0, Vector3.one * 0.8)
		
		if Shake then
			task.delay(1, function()
				Shake:StartFadeOut(0.3)
			end)
		end
	end

	if Part ~= nil and Part.Parent ~= nil then
		local Effect = script.VictimTorso.BFenablestuff:Clone()
		Effect.Parent = Part

		EffectUtility.Emit(Effect, true)
		EffectUtility.Toggle(Effect, true)

		BlackFlashes[Part] = Effect
		
		task.delay(1, function()
			EffectUtility.Toggle(BlackFlashes[Part], false)
			task.delay(2, BlackFlashes[Part].Destroy, BlackFlashes[Part])
		end)
	end
end

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

function VFX.BlackFlashDisable(Part : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(Part.Position)

	if Distance <= 30 then
		ScreenPulse("Black Flash")
		CameraShake(10, 100, 0.1, 0.7, Vector3.one * 0.8)
	end
	
	local Position = Part.Position
	local Direction = Vector3.yAxis * -10
	
	coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		Amount = 8,
		Distance = 6,

		LookAt = { -- Where the rocks face towards (y axis)
			Min = -3,
			Max = -3
		},

		Exposure = {
			Min = 0.3,
			Max = 0.5
		},

		BaseZ = 1.5,
		SizeMultiplier = 1,
	})

	coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		Amount = 13,
		Distance = 11,
		SizeMultiplier = 1.5,
	})

	Blood.BloodRaysWithoutPreset(Part, {
		Face = Enum.NormalId.Front, 
		SpreadAngle = Vector2.new(65, 65), 
		Amount = Vector2.new(8, 10), 
		Power = 35,
		PoolSize = 1.75	
	})
end

function VFX.Camera(AttackerRootPart : BasePart)
	local Replication : Configuration = AttributeListener.GetReplicationFromSource(LocalPlayer)
	local Offset = CFrame.new(0, -3.35, 0)---1.15)
	
	local Camera = script.Camera:Clone()
	Camera:PivotTo(AttackerRootPart.CFrame * Offset)
	Camera.Parent = workspace.Visuals
	
	local Animation = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Gojo["Ruthless Massacre"].Camera)
	Animation:Play(0)
	Animation.TimePosition = 22 / 60
	
	Yuki_FOV.Tween(80, {0.5})
	local Clean = RunCameraRig(AttackerRootPart, Camera, Offset)

	local Removed = false
	
	local function Remove()
		if Removed then return end
		
		Removed = true
		Clean()

		Animation:Destroy()
		Yuki_FOV.Tween(70, {0.5})
	end
	
	Animation.Stopped:Once(Remove)
	AttributeListener.new(LocalPlayer, "RuthlessMassacreCamera", Remove)
end

return VFX
