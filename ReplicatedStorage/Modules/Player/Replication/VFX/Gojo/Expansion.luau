local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local BlackBars = require( ReplicatedStorage.Modules.Player.Replication.Global.BlackBars )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local VFX = {}

local CurrentCameraRig = nil
local Domains = {}
local Hands = {}

function VFX.Start(Model : Model, Value : boolean)
	if Value then
		Model:SetAttribute("MuteUltimate", true)
		
		if (Hands[Model] == nil) then
			Hands[Model] = {}

			local LeftHand = script.LeftHand:Clone()
			LeftHand.Weld.Part1 = LeftHand.LeftHand
			LeftHand.Weld.Part0 = Model["Left Arm"]

			local RightHand = script.RightHand:Clone()
			RightHand.Weld.Part1 = RightHand.RightHand
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

			task.delay(5, LeftHand.Destroy, LeftHand)
			task.delay(5, RightHand.Destroy, RightHand)

			Hands[Model][LeftHand] = true
			Hands[Model][RightHand] = true
		end
	else
		if (Hands[Model] == nil) then return end
		
		for Hand in Hands[Model] do
			Hand:Destroy()
		end
		
		table.clear(Hands[Model])
		Hands[Model]= nil
	end
	
end

function VFX.Wind(RootPart : BasePart)
	local Raycast = workspace:Raycast(RootPart.Position - Vector3.new(0, 0.5, 0), Vector3.yAxis * -40, Utility.VisualParams)
	
	if (Raycast ~= nil) then
		EffectUtility.EmitEffects(script.Wind, workspace.Terrain, Raycast.Position)
	end
end

function VFX.Focus(RootPart : BasePart)
	EffectUtility.EmitEffects(script.Focus, RootPart)
end

function VFX.Camera(RootPart : BasePart)
	if (CurrentCameraRig ~= nil) then return end

	local PreviousCameraCFrame = CurrentCamera.CFrame

	CurrentCameraRig = script.CameraRig:Clone()
	CurrentCameraRig.PrimaryPart:PivotTo(RootPart.CFrame)
	CurrentCameraRig.Parent = workspace.Visuals

	local Animation = CurrentCameraRig.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Gojo["0.2 Expansion"].Camera)
	Animation:Play(0)

	BlackBars(true, 1.5)
	Yuki_FOV.Tween(40, {1.5})

	local Clean = RunCameraRig(RootPart, CurrentCameraRig)

	Animation:GetMarkerReachedSignal("zoom"):Once(function()
		CurrentCamera.FieldOfView = 80
	end)

	Animation.Stopped:Once(function()
		Clean()

		UserInputService.MouseIconEnabled = true

		BlackBars(false)
		Yuki_FOV.Tween(110, {0.5})
		
		task.delay(0.8, function()
			Yuki_FOV.Tween(70, {0.75})
		end)
	end)
end

function VFX.Eyes(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance <= 80) then
		EffectUtility.EmitEffects(script.Focus2, RootPart)
		
		local Eyes = script.Assets.CenterOfEye:Clone()
		Eyes.Parent = RootPart.Parent.Head
		EffectUtility.Emit(Eyes)
	end
end

function VFX.Domain(RootPart : BasePart)
	if (Domains[RootPart] ~= nil) then return end
	
	Domains[RootPart] = script.Domain:Clone()
	Domains[RootPart].Position = RootPart.Position
	Domains[RootPart].Parent = workspace.Visuals
	Domains[RootPart].Fill.Enabled = true
	
	if (CurrentCameraRig ~= nil) then
		CurrentCameraRig.camera.Fill:Emit(200)
	end
	
	TweenService:Create(Domains[RootPart].Fill, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		ShapePartial = 1
	}):Play()
end


function VFX.ClearDomain(RootPart : BasePart)
	if (Domains[RootPart] == nil) then return end

	Domains[RootPart]:Destroy()
	Domains[RootPart] = nil
end

function VFX.Cracks(RootPart : BasePart)
	if (CurrentCameraRig == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance < 25) then
		CameraShake(2, 33, 0.05, 0.3)
	end
	
	EffectUtility.Emit(CurrentCameraRig.camera.fxCraks, true)
end

function VFX.Break(RootPart : BasePart)
	if (Domains[RootPart] == nil) then return end
	
	Domains[RootPart].Fill:Destroy()
	EffectUtility.Emit(Domains[RootPart])
	Domains[RootPart] = nil

	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance <= 125) then
		CameraShake(1.5, 10, 0.05, 0.35)
	end
end

function VFX.Stunned(Head : BasePart)
	EffectUtility.EmitEffects(script.Stunned, Head)
end

return VFX

