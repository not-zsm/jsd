local VFX = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks["Stardust Crusader"]["Star Finger"]

function VFX.Start(Stand : Model)
	local Retrieved = AnimationRetriever.new(Stand, Animations.Stand)
	if (Retrieved == nil) then return end
	
	local Jotaro : Model = Stand.Parent
	
	local StandAnimation = Retrieved.Animation
	local StandJob = Retrieved.Job
	local StandRootPart = Retrieved.RootPart

	StandJob:Task(EffectUtility.AddSFX(script.Shout, StandRootPart, 0.5))
	
	StandJob:Task(StandAnimation:GetMarkerReachedSignal("finger"):Connect(function()
		if EffectUtility.Distance_Close(Jotaro) then
			CameraShake(1.5, 15, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.3)
			Vignette(Color3.fromRGB(109, 60, 255), 0.75, 0.2)
		end
		
		local VFX = script.VFX:Clone()
		EffectUtility.Weld(VFX, StandRootPart, CFrame.new(0.75, 0.65, -6.75) * CFrame.Angles(0, math.rad(-90), math.rad(-90)))
		VFX.Parent = workspace.Visuals
		EffectUtility.Arc.EmitAttachment(VFX)
		
		local Finger : MeshPart = Stand["Right Arm"]:FindFirstChild("Finger")
		
		if Finger then
			local Info = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			
			Finger.Weld.C1 = CFrame.new(0.35, -1, -0.25) * CFrame.Angles(0, math.rad(90), math.rad(-180))
			Finger.Size = Vector3.new(0.45, 0.001, 0.225)
			
			Finger.Transparency = 0

			TweenService:Create(Finger, Info, 
				{Size = Finger.Size + Vector3.yAxis * 5}
			):Play()
			
			TweenService:Create(Finger.Weld, Info, 
				{C1 = Finger.Weld.C1 - Vector3.yAxis * 2.5}
			):Play()
			
			task.delay(0.5, function()
				TweenService:Create(Finger, Info, 
					{Size = Finger.Size - Vector3.yAxis * 5, Transparency = 1}
				):Play()

				TweenService:Create(Finger.Weld, Info, 
					{C1 = Finger.Weld.C1 + Vector3.yAxis * 2.5}
				):Play()
			end)
		end
	end))
end

return VFX