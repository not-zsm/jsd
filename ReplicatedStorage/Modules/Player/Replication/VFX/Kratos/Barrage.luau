local VFX = {};

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local MeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.MeshVFX )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Holder = script.Holder

function VFX.Spin(RootPart : BasePart)
	local VFX1 = Holder.wind:Clone()
	VFX1.Parent = RootPart
	EffectUtility.EmitAttachment(VFX1)
	
	task.wait(0.025)

	local CFs = {
		[1] = CFrame.new(2.461, -2.882, -8.844),
		[2] = CFrame.new(-3.196, -2.882, -8.844),
		[3] = CFrame.new(2.461, -2.882, 7.95),
		[4] = CFrame.new(-3.196, -2.882, 7.95),
	}
	
	local function HitSpark(Count : number)
		if (RootPart == nil or RootPart.Parent == nil) then
			return
		end
		
		local CF = RootPart.CFrame * CFs[Count]
		
		local F1 : Attachment = Holder["1"]:Clone()
		F1.WorldCFrame = CF

		local Mesh = ReplicatedStorage.Effects.Parts.MeshVFX.Start:Clone()
		Mesh.Transparency = 0.875
		Mesh.CFrame = CF + Vector3.yAxis * 1.25
		
		F1.Parent = workspace.Terrain
		Mesh.Parent = workspace.Visuals
		
		EffectUtility.EmitAttachment(F1)
		
		TweenService:Create(Mesh, TweenInfo.new(0.5), {
			Size = Vector3.new(15, 1, 15),
		}):Play()
		
		TweenService:Create(Mesh, TweenInfo.new(0.75), {
			Transparency = 1
		}):Play()
		
		task.delay(0.8, Mesh.Destroy, Mesh)
		
		RockHandler.Rockst(CF.Position, Vector3.yAxis * -10, {
			Count = 5,
			Size = {0.25, 1},
			Velocity = 20
		})
		
		if (LocalPlayer:DistanceFromCharacter(RootPart.Position) < 25) then
			Vignette(Color3.fromRGB(213, 110, 19), 0.35)
			CameraShake(5.8, 5.1, 0.05, 0.1, Vector3.one)
		end
	end
	
	local function TwoHits(Count : number)
		HitSpark(Count)
		
		task.wait(0.05)
		
		HitSpark(Count + 1)
	end

	task.spawn(TwoHits, 1)

	task.wait(0.2)
	
	task.spawn(TwoHits, 3)
end

function VFX.StartSpin(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	local VFX1 = Holder.wind:Clone()
	VFX1.Parent = RootPart

	EffectUtility.EmitAttachment(VFX1)

	if (Distance < 25) then
		CameraShake(3, 15, 0.1, 0.5, Vector3.one * 0.8, Vector3.one * 0.4)
	end
end

function VFX.FinalHit(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	local VFX1 = Holder.final:Clone()
	local VFX2 = Holder.wind:Clone()

	VFX1.Parent = RootPart
	VFX2.Parent = RootPart

	EffectUtility.EmitAttachment(VFX1)
	EffectUtility.EmitAttachment(VFX2)
	
	if (Distance < 25) then
		Vignette(Color3.fromRGB(213, 110, 19), 0.15)
		CameraShake(10, 7, 0.1, 0.5, Vector3.one)
	end
end

return VFX