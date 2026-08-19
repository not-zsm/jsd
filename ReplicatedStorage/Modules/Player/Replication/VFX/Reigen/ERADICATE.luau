local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Animations = ReplicatedStorage.Animations.Attacks.Reigen.ERADICATE
local Claps = setmetatable({}, {__mode = "k"})

function VFX.Start(RootPart : BasePart)
	local LeftRock = script.Left:Clone()
	local RightRock = script.Right:Clone()

	EffectUtility.Weld(LeftRock, RootPart, CFrame.new(0, -1, 0))
	EffectUtility.Weld(RightRock, RootPart, CFrame.new(0, -1, 0))
	
	local StartupRubble = script.StartupRubble:Clone()
	StartupRubble.CFrame = RootPart.CFrame
	
	local LeftRaycast = workspace:Raycast(StartupRubble.left.WorldPosition + Vector3.yAxis * 1.5, Vector3.yAxis * -15, Utility.VisualParams)
	local RightRaycast = workspace:Raycast(StartupRubble.right.WorldPosition + Vector3.yAxis * 1.5, Vector3.yAxis * -15, Utility.VisualParams)
	
	if LeftRaycast then
		LeftRock:SetAttribute("Color", LeftRaycast.Instance.Color)
		
		for _, Mesh in ipairs(LeftRock:GetDescendants()) do
			if Mesh:IsA("MeshPart") then
				Mesh.Color = LeftRaycast.Instance.Color
			end
		end
		
		for _, Particle in ipairs(StartupRubble.left:GetChildren()) do
			if Particle:IsA("ParticleEmitter") then
				Particle.Color = ColorSequence.new(LeftRaycast.Instance.Color)
			end
		end
	end
	
	if RightRaycast then
		RightRock:SetAttribute("Color", RightRaycast.Instance.Color)
		
		for _, Mesh in ipairs(RightRock:GetDescendants()) do
			if Mesh:IsA("MeshPart") then
				Mesh.Color = RightRaycast.Instance.Color
			end
		end
		
		for _, Particle in ipairs(StartupRubble.right:GetChildren()) do
			if Particle:IsA("ParticleEmitter") then
				Particle.Color = ColorSequence.new(RightRaycast.Instance.Color)
			end
		end
	end
	
	LeftRock.Parent = workspace.Visuals
	RightRock.Parent = workspace.Visuals
	StartupRubble.Parent = workspace.Visuals
	
	local LeftRockAnimation = LeftRock.Humanoid.Animator:LoadAnimation(Animations.ClapLeft)
	local RightRockAnimation = RightRock.Humanoid.Animator:LoadAnimation(Animations.ClapRight)
	
	LeftRockAnimation.Stopped:Once(function()
		LeftRock:Destroy()
	end)
	
	RightRockAnimation.Stopped:Once(function()
		RightRock:Destroy()
	end)
	
	LeftRockAnimation:Play(0)
	RightRockAnimation:Play(0)
	
	EffectUtility.Toggle(StartupRubble, true)
	
	Claps[RootPart] = {
		LeftRock = LeftRock,
		RightRock = RightRock,
		StartupRubble = StartupRubble
	}
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 50 then
		CameraShake(3, 22.5, 0.01, 1)
	end
end

function VFX.RocksOut(RootPart : BasePart)
	if Claps[RootPart] then
		EffectUtility.Toggle(Claps[RootPart].StartupRubble, false)
		task.delay(1, Claps[RootPart].StartupRubble.Destroy, Claps[RootPart].StartupRubble)
	end
end

function VFX.Clap(RootPart : BasePart)
	local Clap = script.Clap:Clone()
	Clap.CFrame = RootPart.CFrame * CFrame.new(0, 4.81, -14.675)
	
	if (Claps[RootPart] ~= nil and Claps[RootPart].LeftRock:GetAttribute("Color") and Claps[RootPart].RightRock:GetAttribute("Color")) then
		for _, Particle in ipairs(Clap.Dust:GetChildren()) do
			if Particle:IsA("ParticleEmitter") then
				Particle.Color = ColorSequence.new(
					math.random(1, 2) == 1 and Claps[RootPart].LeftRock:GetAttribute("Color") or Claps[RootPart].RightRock:GetAttribute("Color")
				)
			end
		end
	end
	
	Clap.Parent = workspace.Visuals
	EffectUtility.Emit(Clap)
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 50 then
		CameraShake(6, 75, 0.01, 0.5)
	end
end

return VFX