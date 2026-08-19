local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local MeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.SwrermMeshVFX )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

function VFX.Camera(RootPart : BasePart)
	local Replication : Configuration = AttributeListener.GetReplicationFromSource(RootPart)
	local Offset = CFrame.new(0, -3.925, -1.5) * CFrame.Angles(0, -math.pi, 0)

	local Camera = script.Camera:Clone()
	Camera:PivotTo(RootPart.CFrame * Offset)
	Camera.Parent = workspace.Visuals

	local Animation = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Kratos.Camera)
	Animation:Play(0)

	Yuki_FOV.Tween(60, {1})
	local Clean = RunCameraRig(RootPart, Camera, Offset)

	local Connection : RBXScriptConnection
	
	local function Remove()
		Connection:Disconnect()
		Clean()
		Yuki_FOV.Reset()
	end

	Connection = Replication:GetAttributeChangedSignal("KratosWallComboCamera"):Connect(function()
		if not Replication:GetAttribute("KratosWallComboCamera") then
			Remove()
		end
	end)
end

function VFX.Smash(RootPart : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end

	local VFX = script.wallslam:Clone()
	VFX.CFrame = RootPart.CFrame * CFrame.new(0, 0, -3)
	VFX.Parent = workspace.Visuals
	
	EffectUtility.Emit(VFX)

	for Index, Mesh : Model in script.Meshes.wallslam:GetChildren() do
		Mesh:PivotTo(RootPart.CFrame * CFrame.new(0, 0, -2) * CFrame.Angles(0, math.rad(90), 0))
		MeshVFX.Emit(Mesh)
	end
	
	if (Distance <= 15) then
		CameraShake(4, 15, 0.1, 0.3, Vector3.one * 0.8)
	end
end

function VFX.Hit(RootPart : BasePart, Count : number)
	if (RootPart == nil or RootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end
	
	local Head : BasePart = RootPart.Parent.Head
	
	EffectUtility.EmitEffects(script.Hit, Head)
	
	for Index, Mesh : Model in script.Meshes[`hit{Count}`]:GetChildren() do
		Mesh:PivotTo(CFrame.new(Head.Position))
		MeshVFX.Emit(Mesh)
	end
	
	if (Distance <= 15) then
		CameraShake(1, 10, 0.05, 0.15, Vector3.one * 0.75)
	end
end 

function VFX.Uppercut(RootPart : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end

	local VFX = script.uppercut:Clone()
	VFX.CFrame = RootPart.CFrame * CFrame.new(0, 0.5, -1.5)
	VFX.Parent = workspace.Visuals

	EffectUtility.Emit(VFX)

	for Index, Mesh : Model in script.Meshes.uppercut:GetChildren() do
		Mesh:PivotTo(RootPart.CFrame * CFrame.new(0, 0.5, -1.25) * CFrame.Angles(math.rad(-10), 0, math.rad(-90)))
		MeshVFX.Emit(Mesh)
	end
	
	if (Distance <= 15) then
		CameraShake(3, 12, 0.05, 0.2, Vector3.one * 0.8)
	end
end 

return VFX