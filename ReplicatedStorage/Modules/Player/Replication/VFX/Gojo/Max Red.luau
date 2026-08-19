local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Utility = require(ReplicatedStorage.Modules.Shared.Utilities.Utility)
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Afterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.ATrainAfterimage )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local Assets = script.Assets

local VFX = {}

function VFX.Velocity(RootPart : BasePart)
	local Model : Model = RootPart.Parent

	local ShakeObject = CameraShake(2, 20, 0.1, 0, Vector3.one * 0.8)
	Yuki_FOV.Tween(105, {0.25})

	local CancelConnection : RBXScriptConnection; CancelConnection = Model:GetAttributeChangedSignal("MaxRed"):Connect(function()
		if not Model:GetAttribute("MaxRed") then
			if ShakeObject then
				ShakeObject:StartFadeOut(0.1)
			end
			
			Yuki_FOV.Tween(70, {0.75})
		end
	end)
	
	task.delay(1.6, function()
		if not CancelConnection.Connected then return end
		
		Yuki_FOV.Tween(120, {0.5})
	end)
	
	task.delay(3.5, function()
		if ShakeObject then
			ShakeObject:StartFadeOut(0.3)
		end
	end)

	task.delay(5, function()
		if not CancelConnection.Connected then return end
		
		CancelConnection:Disconnect()
		
		if ShakeObject then
			ShakeObject:StartFadeOut(0.1)
		end
		
		Yuki_FOV.Tween(70, {0.75})
	end)
end

function VFX.Start(RootPart : BasePart)
	local Model : Model = RootPart.Parent

	local Sound = script.StartSFX.Start:Clone()
	Sound.Parent = RootPart
	Sound:Play()
	task.delay(8, Sound.Destroy, Sound)

	local CancelConnection : RBXScriptConnection; CancelConnection = Model:GetAttributeChangedSignal("MaxRed"):Connect(function()
		if not Model:GetAttribute("MaxRed") then
			Sound:Destroy()
			CancelConnection:Disconnect()
		end
	end)
	
	task.wait(0.5)
	
	if not CancelConnection.Connected then return end

	local FakeArms = {}

	for _, Item in ipairs(Model:GetChildren()) do
		if Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart" then
			local FakeArm = EffectUtility.WeldArmTrail(Item)
			table.insert(FakeArms, FakeArm)
		end
	end
	
	local Boost = script.Run.Assets.fxEmit:Clone()
	Boost.Parent = RootPart
	EffectUtility.Emit(Boost)

	local RunVFX = script.Run.LineFx:Clone()
	RunVFX.Weld.Part0 = RootPart
	RunVFX.Parent = workspace.Visuals;
	
	EffectUtility.Toggle(RunVFX, true)

	task.delay(1.5, function()
		if not CancelConnection.Connected then return end
		
		EffectUtility.Toggle(RunVFX, false)
		task.delay(1.5, RunVFX.Destroy, RunVFX)
		
		local Boost = script.Run.Assets.fxEmit2:Clone()
		Boost.Parent = RootPart
		EffectUtility.Emit(Boost)

		local RunVFX2 = script.Run.LineFx2:Clone()
		RunVFX2.Weld.Part0 = RootPart
		RunVFX2.Parent = workspace.Visuals;

		EffectUtility.Toggle(RunVFX2, true)

		task.delay(1.85, function()
			EffectUtility.Toggle(RunVFX2, false)
			task.delay(1.5, RunVFX2.Destroy, RunVFX2)
		end)
	end)
	
	Afterimage(RootPart.Parent, true)
	
	local function Cancel()
		for _, FakeArm in FakeArms do
			FakeArm:Destroy()
		end
		
		RunVFX:Destroy()
		Afterimage(RootPart.Parent, false)
	end

	local Start = os.clock()
	local RunDuration = 1.65
	local RunDuration2 = 2.25

	local Value = 0
	local Connection : RBXScriptConnection
	
	Connection = RunService.PostSimulation:Connect(function()
		if not Model:GetAttribute("MaxRed") then 
			Cancel()
			
			return Connection:Disconnect()
		end
		
		local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

		if (Distance > 100) then
			return
		end

		if (Value % 5 == 0 and os.clock() - Start < 3.5) then
			RockHandler.Rocks("Blue Pull", RootPart)
		end

		Value += 1
	end)
	
	task.delay(3.5, function()
		if CancelConnection.Connected then
			Cancel()
		end
	end)
end

function VFX.RunCriticalHit(AttackerRootPart : BasePart, VictimRootPart : BasePart)
	if Players.LocalPlayer == Players:GetPlayerFromCharacter(AttackerRootPart.Parent) or Players.LocalPlayer == Players:GetPlayerFromCharacter(VictimRootPart.Parent) then
		ScreenPulse("Black Flash")
	end
	
	if Players.LocalPlayer == Players:GetPlayerFromCharacter(VictimRootPart.Parent) then
		local Blur = Instance.new("BlurEffect")
		Blur.Name = "InhumaneSpeedBlur"
		Blur.Size = 0

		local Tween = TweenService:Create(Blur, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), 
			{Size = 7.5}
		)

		Tween:Play()

		Tween.Completed:Connect(function(State)
			if State == Enum.PlaybackState.Completed then
				Blur.Enabled = false
				Blur:Destroy()
			end
		end)
	end

	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)
	
	if Distance < 100 then
		EffectUtility.EmitEffects(script.RunCriticalHit, VictimRootPart)
	end
end

function VFX.Hit(RootPart : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if Distance > 100 then return end
	
	EffectUtility.EmitEffects(script.Hit, RootPart, nil, CFrame.new(0,0,-2.5))

	if Distance < 25 then
		CameraShake(3.5, 25, 0.1, 0.5, Vector3.one * 0.8)
	end
	
	local Torso : BasePart = RootPart.Parent.Torso
	
	task.delay(0.1, function()
		for Index = 1, 15 do
			if (RootPart == nil or RootPart.Parent == nil) then break end
			
			Smoke(Torso)
			task.wait(0.05)
		end
	end)
end

function VFX.Red(RootPart : BasePart, Arm : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance < 100) then
		local Hand = script.Assets.Hand:Clone()
		Hand.Parent = Arm
		
		local Red = script.Assets.Red:Clone()
		Red.Parent = RootPart

		EffectUtility.Toggle(Hand, true)
		EffectUtility.Toggle(Red, true)
		
		if Distance < 25 then
			ScreenPulse("Black Flash")
			CameraShake(2.5, 20, 0.1, 0.25, Vector3.one * 0.8)
		end
		
		task.wait(2.5)

		EffectUtility.Toggle(Hand, false)
		EffectUtility.Toggle(Red, false)
		
		task.delay(2, Hand.Destroy, Hand)
		task.delay(2, Red.Destroy, Red)
	end
end


function VFX.Blast(RootPart : BasePart)
	if (RootPart == nil or RootPart.Parent == nil) then return end
	
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if (Distance < 100) then
		local CF = CFrame.lookAt(RootPart.Position, RootPart.Position + RootPart.CFrame.LookVector) * CFrame.new(0, 4, -3)
		
		local Blast = script.Blast:Clone()
		Blast.CFrame = CF
		Blast.Parent = workspace.Visuals

		if Distance < 25 then
			ScreenPulse("Black Flash")
			CameraShake(2, 15, 0.1, 0.5, Vector3.one * 0.8)
		end
		
		EffectUtility.EmitAttachment(Blast)
	end
end

--function VFX.Hit(Parent : BasePart)
--	EffectUtility.EmitEffects(script.Hit, Parent, nil, CFrame.new(0,0,-2.5))
--end

--function VFX.Main(RootPart : BasePart, VictimRootPart : BasePart)
--	EffectUtility.EmitEffects(script.Dust1, VictimRootPart, nil, CFrame.new(0, -3, -14.762))

--	task.wait(0.55)

--	EffectUtility.EmitEffects(script.Dust2, VictimRootPart, nil, CFrame.new(0, -3, -20.626))
	
--	task.wait(1.1)
	
--	local GroundFX = Assets.FxGroundEnable:Clone()
--	GroundFX.Parent = RootPart
	
--	EffectUtility.Toggle(GroundFX, true)
	
--	task.delay(2.35, function()
--		EffectUtility.EmitEffects(script.GroundEmit, RootPart, nil, CFrame.new(0, -3, 4.087))
		
--		EffectUtility.Toggle(GroundFX, false)
--		Debris:AddItem(GroundFX, 1)
--	end)
--end

--function VFX.Arm(Parent : BasePart)
--	local BeamParent = Assets.Beam1:Clone()
--	BeamParent.Parent = Parent

--	local FxStart = Assets.FxStart:Clone()
--	FxStart.Parent = Parent

--	EffectUtility.Toggle(FxStart, true) 
--	EffectUtility.EmitEffects(script.AppearEmit, Parent, nil, CFrame.new(0, -1.629, 0))

--	task.delay(2.65, function()
--		EffectUtility.Toggle(FxStart, false)
--		Debris:AddItem(FxStart, 2)
		
--		EffectUtility.EmitEffects(script.Explosion, Parent, nil, CFrame.new(0, -1.629, 0))
		
--		task.wait(2)
		
--		BeamParent:Destroy()
--	end)
--end

function VFX.Finisher(Victim : Model)
	local Attachment = Instance.new("Attachment")
	Attachment.WorldCFrame = Victim.HumanoidRootPart.CFrame
	Attachment.Parent = workspace.Terrain

	Blood.BloodRaysWithoutPreset(Attachment, {
		Gravity = 150,
		Power = 10,
		Amount = Vector2.new(12, 15),
		Spread = Vector2.new(90, 90),
		PoolSize = 1.25,
		PoolSizeRandom = Vector2.new(-0.25, 0.45),
		Face = Enum.NormalId.Top,
	})

	EffectUtility.EmitEffects(script.Crush, Attachment)
	
	for _, Item in ipairs(Victim:GetDescendants()) do 
		if Item:IsA("BasePart") or Item:IsA("Decal") then
			Item.Transparency = 1
		end
	end
	
	task.delay(2, Attachment.Destroy, Attachment)
end

return VFX
