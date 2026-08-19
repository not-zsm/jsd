local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local Hands = {}

function VFX.Start(RootPart : BasePart, Value : boolean)
	local Model : Model = RootPart.Parent

	EffectUtility.EmitEffects(script.User, RootPart.Parent.Torso)
	
	for _, Item in ipairs(RootPart.Parent:GetChildren()) do
		if Item.Name ~= "HumanoidRootPart" and Item:IsA("BasePart") or Item:IsA("Decal") then
			Item.Transparency = 0
		elseif Item:IsA("Accessory") then
			Item.Handle.Transparency = 0
		end
	end

	if (Value and Hands[Model] == nil) then
		local LeftHand = script.LeftHand:Clone()
		local RightHand = script.RightHand:Clone()

		LeftHand.Weld.Part0 = Model["Left Arm"]
		RightHand.Weld.Part0 = Model["Right Arm"]

		for _, Item in ipairs(LeftHand:GetChildren()) do
			if Item:IsA("BasePart") then
				Item.Color = Model["Left Arm"].Color
			end
		end

		for _, Item in ipairs(RightHand:GetChildren()) do
			if Item:IsA("BasePart") then
				Item.Color = Model["Right Arm"].Color
			end
		end

		LeftHand.Parent = Model
		RightHand.Parent = Model

		Hands[Model] = {LeftHand, RightHand}

	elseif (not Value and Hands[Model] ~= nil) then
		for _, Hand in Hands[Model] do
			Hand:Destroy()
		end
	end
end

function VFX.WallHit(Position, Normal)
	local Impact = script.Impact:Clone()
	Impact.CFrame = CFrame.lookAt(Position, Position + (Normal * -10)) * CFrame.Angles(math.rad(90), 0, 0)
	Impact.Parent = workspace.Visuals

	EffectUtility.Emit(Impact)
end

function VFX.Camera(RootPart : BasePart)
	local Replication : Configuration = AttributeListener.GetReplicationFromSource(LocalPlayer)
	local Offset = CFrame.identity

	local Camera = script.Camera:Clone()
	Camera:PivotTo(RootPart.CFrame * Offset)
	Camera.Parent = workspace.Visuals

	local Animation = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Gojo["Reverse Cursed Technique"].ReawakenCamera)
	Animation:Play(0)

	local NewJob = Job.new()

	NewJob:Task(RunCameraRig(RootPart, Camera, Offset))
	NewJob:Task(Yuki_FOV.AnimateWithMoonFile(ReplicatedStorage.FOVFiles.Reawakening))

	local function Remove()
		NewJob:Destroy()
		Animation:Stop(0)
	end

	AttributeListener.new(LocalPlayer, "GojoReawakening", Remove)
	Animation.Stopped:Once(Remove)
end

function VFX.GetUp(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.getup, RootPart)
end

function VFX.Step(RootPart : BasePart, Parameter : string)
	EffectUtility.CloneAndEmit(script.Assets["step" .. Parameter], RootPart)
end

local Hollows = {}
local ScreenFX = {}

function VFX.Hollow(RootPart : BasePart)
	local Model : Model = RootPart.Parent

	local Hand = script.Assets.handpurple:Clone()
	Hand.Parent = Model["Right Arm"]

	EffectUtility.Toggle(Hand, true)

	Hollows[RootPart] = Hand

	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
		local ColorCorrection = Instance.new("ColorCorrectionEffect")
		ColorCorrection.Enabled = true
		ColorCorrection.Parent = game.Lighting

		ScreenFX[RootPart] = ColorCorrection

		TweenService:Create(ScreenFX[RootPart], TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Contrast = 0.5, Brightness = 0.1, Saturation = 0.25, TintColor = Color3.fromRGB(170, 85, 255)}):Play()
		Yuki_FOV.Tween(55, {0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In})
		TweenService:Create(game.Lighting, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Brightness = 0}):Play()
	end
end

function VFX.ScreenFXEnd(RootPart : BasePart)
	if ScreenFX[RootPart] and LocalPlayer.Name == RootPart.Parent.Name then
		Yuki_FOV.Tween(70, {1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut})
		
		TweenService:Create(ScreenFX[RootPart], TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Contrast = 0, Brightness = 0, Saturation = 0, TintColor = Color3.fromRGB(255, 255, 255)}):Play()
		TweenService:Create(game.Lighting, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = 3}):Play()

		task.delay(1, ScreenFX[RootPart].Destroy, ScreenFX[RootPart])
	end
end

function VFX.Purple(RootPart : BasePart)
	local Model : Model = RootPart.Parent

	if Hollows[RootPart] then
		Hollows[RootPart]:Destroy()
		Hollows[RootPart] = nil
	end

	EffectUtility.EmitEffects(script.Release, RootPart.Parent.Torso)

	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
		Yuki_FOV.Tween(150, {0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})

		CameraShake(6, 10, 0.1, 0.25, Vector3.one)

		if ScreenFX[RootPart] then
			TweenService:Create(ScreenFX[RootPart], TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Contrast = 0, Brightness = 0, Saturation = 0, TintColor = Color3.fromRGB(255, 255, 255)}):Play()
		end

		TweenService:Create(game.Lighting, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = 3}):Play()

		task.wait(0.75)

		VFX.ScreenFXEnd(RootPart)
	end
end

return VFX
