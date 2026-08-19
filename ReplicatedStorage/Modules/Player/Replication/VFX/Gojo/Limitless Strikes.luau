local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local PullKickVFX = require( ReplicatedStorage.Modules.Player.Replication.VFX.Gojo["Pull&Kick"] )

function VFX.Hit(AttackerRootPart : BasePart, VictimRootPart : BasePart, HitCount : number)
	if (VictimRootPart == nil or VictimRootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(AttackerRootPart.Position)
	if Distance > 80 then return end

	local Victim : Model = VictimRootPart.Parent
	local HitVFX : Attachment = script.Assets.Holder[tostring(HitCount)]:Clone()

	if (HitCount == 4) then
		HitVFX.WorldCFrame = AttackerRootPart.CFrame * CFrame.new(0, 1, -3.5)

		if Distance < 25 then
			CameraShake(3.5, 35, 0.05, 0.4, Vector3.one * 0.8)
		end
	else
		if Distance < 25 then
			CameraShake(4, 40, 0.05, 0.1, Vector3.one * 0.8)
		end
	end

	HitVFX.Parent = (HitCount == 4 and workspace.Terrain or Victim.Torso)
	EffectUtility.Emit(HitVFX)
	
	local Mesh = ReplicatedStorage.Effects.Parts.MeshVFX.Start:Clone()
	Mesh.Transparency = 0.65
	Mesh.CFrame = (HitCount == 4 and VictimRootPart.CFrame or  Victim.Torso.CFrame) * CFrame.Angles(math.rad(90), 0, 0)
	Mesh.Parent = workspace.Visuals

	TweenService:Create(Mesh, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = HitCount == 4 and Vector3.new(15, 1.25, 15) or Vector3.new(10, 1, 10)
	}):Play()
	
	task.delay(0.25, Mesh.Destroy, Mesh)

	local Highlight = Instance.new("Highlight")
	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	Highlight.FillTransparency = 0
	Highlight.OutlineTransparency = 1
	Highlight.FillColor = Color3.fromRGB(255, 255, 255)
	Highlight.Parent = Victim

	TweenService:Create(Highlight, TweenInfo.new(0.35), 
		{FillTransparency = 1}
	):Play()

	task.delay(0.2, Highlight.Destroy, Highlight)
end

function VFX.FinisherLastHit(AttackerRootPart : BasePart, VictimRootPart : BasePart)
	local HitVFX : Attachment = script.Assets.Holder["4"]:Clone()
	HitVFX.WorldCFrame = AttackerRootPart.CFrame * CFrame.new(0, 1, -3.5)
	HitVFX.Parent = workspace.Terrain
	EffectUtility.Emit(HitVFX)
	
	local Mesh = ReplicatedStorage.Effects.Parts.MeshVFX.Start:Clone()
	Mesh.Transparency = 0.5
	Mesh.CFrame = VictimRootPart.CFrame * CFrame.Angles(math.rad(90), 0, 0)
	Mesh.Parent = workspace.Visuals

	TweenService:Create(Mesh, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = Vector3.new(20, 1.5, 20)
	}):Play()
	
	task.spawn(function()
		for Index = 1, 5 do
			if (VictimRootPart == nil or VictimRootPart.Parent == nil) then
				break	
			end
			
			task.wait(0.3)

			if (VictimRootPart ~= nil and VictimRootPart.Parent ~= nil) then
				Blood.BloodRays("SpitOut", VictimRootPart.Parent.Head.MouthAttachment)
			end
		end
	end)
	
	PullKickVFX.KickHit(AttackerRootPart, VictimRootPart)
end

return VFX