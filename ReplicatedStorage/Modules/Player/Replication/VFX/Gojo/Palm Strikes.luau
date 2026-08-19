local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local Yuki_Skeleton = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_Skeleton )

local LocalPlayer = Players.LocalPlayer

function VFX.Start(RootPart : BasePart)
	local Trail = EffectUtility.WeldArmTrail(RootPart.Parent["Left Arm"])
	task.delay(0.6, Trail.Destroy, Trail)

	EffectUtility.EmitEffects(script.Windup, RootPart)
end

function VFX.Land(RootPart : BasePart)
	EffectUtility.EmitEffects(script.Land, RootPart)
end

function VFX.Hit(AttackerRootPart : BasePart, VictimRootPart : BasePart, HitCount : number)
	if (VictimRootPart == nil or VictimRootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(AttackerRootPart.Position)
	if Distance > 80 then return end
	
	local BloodEnabled = LocalPlayer:GetAttribute("Blood")

	local Assets
	if BloodEnabled then
		Assets = script.Assets
	else
		Assets = script.NoBloodAssets
	end
	
	local Victim : Model = VictimRootPart.Parent
	local HitVFX : Attachment = Assets.Holder[tostring(HitCount)]:Clone()

	if (HitCount == 4) then
		HitVFX.WorldCFrame = AttackerRootPart.CFrame * CFrame.new(1.5, 1, -3.5) * CFrame.Angles(0, 0, math.rad(-35))

		if Distance < 25 then
			CameraShake(2.5, 25, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.5)
		end
	else
		if Distance < 25 then
			CameraShake(1.5, 15, 0.01, 0.125, Vector3.one * 0.8, Vector3.one * 0.25)
		end
	end

	HitVFX.Parent = (HitCount == 4 and workspace.Terrain or Victim.Torso)
	EffectUtility.Emit(HitVFX)

	local Highlight = Instance.new("Highlight")
	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	Highlight.FillTransparency = 0
	Highlight.OutlineTransparency = 1
	Highlight.FillColor = Color3.fromRGB(255, 255, 255)
	Highlight.Parent = Victim

	TweenService:Create(Highlight, TweenInfo.new(0.2), 
		{FillTransparency = 1}
	):Play()

	task.delay(0.2, Highlight.Destroy, Highlight)
end

local FinisherStuffs = {}

function VFX.FinisherHit(AttackerRootPart : BasePart, VictimRootPart : BasePart, HitCount : number)
	if (VictimRootPart == nil or VictimRootPart.Parent == nil) then return end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(AttackerRootPart.Position)
	if Distance > 80 then return end
	
	local BloodEnabled = LocalPlayer:GetAttribute("Blood")

	local Assets
	if BloodEnabled then
		Assets = script.Assets
	else
		Assets = script.NoBloodAssets
	end

	local Victim : Model = VictimRootPart.Parent
	local HitVFX : Attachment = Assets.Holder[tostring(HitCount)]:Clone()

	if (VictimRootPart ~= nil and VictimRootPart.Parent ~= nil) then
		Yuki_Skeleton(VictimRootPart.Parent.Torso, 0, 0.2)
	end

	if (HitCount == 4) then
		HitVFX.WorldCFrame = AttackerRootPart.CFrame * CFrame.new(0, 1, -3.5)

		if Distance < 25 then
			CameraShake(3, 30, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.5)
		end
	else
		if Distance < 25 then
			CameraShake(2, 20, 0.01, 0.125, Vector3.one * 0.8, Vector3.one * 0.25)
		end
	end

	HitVFX.Parent = (HitCount == 4 and workspace.Terrain or Victim.Torso)
	EffectUtility.Emit(HitVFX)

	local Highlight = Instance.new("Highlight")
	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	Highlight.FillTransparency = 0
	Highlight.OutlineTransparency = 1
	Highlight.FillColor = Color3.fromRGB(255, 0, 0)
	Highlight.Parent = Victim

	TweenService:Create(Highlight, TweenInfo.new(0.2), 
		{FillTransparency = 1}
	):Play()

	task.delay(0.2, Highlight.Destroy, Highlight)
end

function VFX.ChargeRed(RootPart : BasePart)
	EffectUtility.EmitEffects(script.FinisherSFX, RootPart)

	local Assets
	if LocalPlayer:GetAttribute("Blood") then
		Assets = script.Assets
	else
		Assets = script.NoBloodAssets
	end
	
	local RedVFX = Assets.Holder.RedCharge:Clone()
	RedVFX.Parent = RootPart.Parent["Left Arm"]
	
	local StartupVFX = Assets.Holder.ChargeRelease:Clone()
	StartupVFX.Parent = RootPart.Parent["Left Arm"]
	
	EffectUtility.Emit(RedVFX)
	EffectUtility.Emit(StartupVFX)
	
	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
		ScreenPulse("Black Flash", true)
		CameraShake(2.5, 25, 0.025, 0.25, Vector3.one * 0.8)
		Yuki_FOV.Tween(50, {0.75})
	end
end

function VFX.Fix(RootPart : BasePart)
	Yuki_FOV.Reset()
end

function VFX.ShootRed(RootPart : BasePart, VictimRootPart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	local Assets
	if LocalPlayer:GetAttribute("Blood") then
		Assets = script.Assets
	else
		Assets = script.NoBloodAssets
	end
	
	local RedVFX : Attachment = Assets.Holder.Red:Clone()
	RedVFX.WorldCFrame = RootPart.CFrame * CFrame.new(0, 13, -4.5) * CFrame.Angles(math.rad(-135), math.pi, 0)
	RedVFX.Parent = workspace.Terrain
	
	EffectUtility.Emit(RedVFX)

	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or LocalPlayer == Players:GetPlayerFromCharacter(VictimRootPart.Parent) then
		ScreenPulse("Black Flash")
		CameraShake(7.5, 75, 0.025, 0.5, Vector3.one * 0.8)
		
		Yuki_FOV.Tween(95, {0.15})
	end
	
	task.delay(0.2, function()
		if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or LocalPlayer == Players:GetPlayerFromCharacter(VictimRootPart.Parent) then
			Yuki_FOV.Tween(70, {1})
		end
	end)
end

function VFX.FinisherSlide(RootPart : BasePart, VictimTorso)
	local RunThread = coroutine.create(function()
		while (RootPart ~= nil and RootPart.Parent ~= nil) do
			RockHandler.Rocks("Side Dash", RootPart)
			
			task.spawn(RockHandler.Rockst, RootPart.Position, Vector3.yAxis * -5, {
				Size = {0.4, 0.7},
				Velocity = 25
			})
			
			Smoke(RootPart)

			task.wait(0.02)
		end
	end)

	local BloodThread = coroutine.create(function()
		while (VictimTorso ~= nil and VictimTorso.Parent ~= nil) do
			Blood.BloodRays("SpitOut", VictimTorso.Parent.Head.MouthAttachment)
			task.wait(0.15)
		end
	end)
	
	local Shake
	
	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or LocalPlayer == Players:GetPlayerFromCharacter(VictimTorso.Parent) then
		Shake = CameraShake(1, 15, 0.1, 0, Vector3.one * 0.7)
		Yuki_FOV.Tween(55, {1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
	end
	
	local Assets
	if LocalPlayer:GetAttribute("Blood") then
		Assets = script.Assets
	else
		Assets = script.NoBloodAssets
	end
	
	local Slide = Assets.Slide:Clone()
	Slide.Parent = workspace.Visuals
	
	EffectUtility.Toggle(Slide, true)

	local SlideConnection = RunService.PostSimulation:Connect(function()
		Slide:PivotTo(RootPart.CFrame)
	end)

	coroutine.resume(RunThread)
	coroutine.resume(BloodThread)

	FinisherStuffs[RootPart] = {RunThread, BloodThread, SlideConnection, Slide, Shake}	
end

function VFX.Slam(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if Distance < 25 then
		CameraShake(10, 25, 0.1, 0.25, Vector3.one * 0.75)
	end
	
	local Position = RootPart.Position + Vector3.yAxis * 4
	local Direction = Vector3.yAxis * -20
	
	local Raycast = workspace:Raycast(Position, Direction, Utility.VisualParams)

	if Raycast then
		local Attachment = Instance.new("Attachment")
		Attachment.WorldPosition = Raycast.Position
		Attachment.Parent = workspace.Terrain
		
		EffectUtility.EmitEffects(script.Slam, Attachment)
	end
	
	coroutine.wrap(RockHandler.Crater)(Position, Direction, {
		Amount = 7,
		Distance = 5,

		LookAt = {
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
		Amount = 8,
		Distance = 8,
		SizeMultiplier = 1.4,
	})
end

function VFX.FinisherSlideEnd(RootPart : BasePart, VictimRootPart : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) or (FinisherStuffs[RootPart] == nil) then return end

	for _, Item in FinisherStuffs[RootPart] do
		if typeof(Item) == "thread" then
			task.cancel(Item)
			
		elseif typeof(Item) == "RBXScriptConnection" then
			Item:Disconnect()
			
		elseif typeof(Item) == "Instance" and Item:IsA("BasePart") then
			EffectUtility.Toggle(Item, false)
			task.delay(2, Item.Destroy, Item)
			
		elseif typeof(Item) == "table" and Item.IsACameraShakeInstance then
			Item:StartFadeOut(0.1)
		end
	end
	
	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or LocalPlayer == Players:GetPlayerFromCharacter(VictimRootPart.Parent) then
		Yuki_FOV.Tween(70, {0.5})
	end

	table.clear(FinisherStuffs[RootPart])
	FinisherStuffs[RootPart] = nil
end

--function VFX.FinisherTrail(Leg : BasePart)
--	local Distance = Players.LocalPlayer:DistanceFromCharacter(Leg.Position)
--	if Distance > 80 then return end

--	local Trail = EffectUtility.WeldArmTrail(Leg)

--	task.delay(0.7, function()
--		EffectUtility.Toggle(Trail, false)
--		task.delay(1, Trail.Destroy, Trail)
--	end)
--end

--function VFX.FinisherKickDown(AttackerRootPart : BasePart, VictimRootPart : BasePart)
--	if (VictimRootPart == nil or VictimRootPart.Parent == nil) then return end

--	local Distance = Players.LocalPlayer:DistanceFromCharacter(AttackerRootPart.Position)
--	if Distance > 80 then return end

--	local Victim : Model = VictimRootPart.Parent
--	local HitVFX : Attachment = script.Assets.Holder.Finisher:Clone()

--	if (VictimRootPart ~= nil and VictimRootPart.Parent ~= nil) then
--		Yuki_Skeleton(VictimRootPart.Parent.Torso, 0, 0.1)
--	end

--	if Distance < 25 then
--		CameraShake(7.5, 75, 0.025, 0.5, Vector3.one * 0.8)
--	end	

--	HitVFX.WorldCFrame = AttackerRootPart.CFrame * CFrame.new(0, 0, -3.5) * CFrame.Angles(math.rad(-55), 0, 0)
--	HitVFX.Parent = workspace.Terrain

--	EffectUtility.Emit(HitVFX)

--	local Highlight = Instance.new("Highlight")
--	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
--	Highlight.FillTransparency = 0
--	Highlight.OutlineTransparency = 1
--	Highlight.FillColor = Color3.fromRGB(255, 0, 0)
--	Highlight.Parent = Victim

--	TweenService:Create(Highlight, TweenInfo.new(0.2), 
--		{FillTransparency = 1}
--	):Play()

--	task.delay(0.2, Highlight.Destroy, Highlight)
--end

return VFX