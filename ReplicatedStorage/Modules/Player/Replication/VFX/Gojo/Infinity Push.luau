local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local Afterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.ATrainAfterimage )

local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )
local Yuki_InfinityBubble = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_InfinityBubble )

local Shockwave = require( ReplicatedStorage.Modules.Player.Replication.Global.Shockwave )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local VFX = {}

local RunDuration = 0.95

function VFX.Velocity(RootPart : BasePart)
	local Model : Model = RootPart.Parent
	local FoundKnockback = RootPart:FindFirstChild("Velocity")

	if (FoundKnockback ~= nil) then
		FoundKnockback:Destroy() -- nerfs 3 m1 infinity pull
	end
	
	local Velocity = Instance.new("BodyVelocity")
	Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
	Velocity.Parent = RootPart
	
	local Cancelled = false
	
	local CancelConnection : RBXScriptConnection; CancelConnection = Model:GetAttributeChangedSignal("InfinityPush"):Connect(function()
		if not Model:GetAttribute("InfinityPush") then
			CancelConnection:Disconnect()
			Cancelled = true
			
			Yuki_FOV.Reset()
			Afterimage(RootPart.Parent, false)
			
			Velocity:Destroy()
		end
	end)
	
	task.wait(0.075)
	
	if Cancelled then return end
	
	local Start = os.clock()
	
	Afterimage(RootPart.Parent, true)
	Yuki_FOV.Tween(95, {0.5})
	
	local Value = 0
	
	local ControllableVelocity = RunService.PreAnimation:Connect(function()
		if (Velocity.Parent == nil) then
			return
		end
	
		if (Value % 10 == 0) then
			RockHandler.Rocks("Blue Pull", RootPart)
			
			coroutine.wrap(RockHandler.Rockst)(RootPart.Position, Vector3.yAxis * -10, {
				Size = {0.6, 0.8},
				Count = 2,
				Velocity = 15,
			})
			
			--Shockwave(RootPart, nil, CFrame.new(0, Utility.Seed:NextNumber(-5, -7), 0), Vector3.new(15, 0.65, 15))
		end
		
		Value += 1
		Velocity.Velocity = RootPart.CFrame.LookVector * 145 * math.max(0, RunDuration - (os.clock() - Start) / RunDuration)
		
		local Raycast = workspace:Blockcast(RootPart.CFrame, Vector3.new(3, 1, 2), RootPart.CFrame.LookVector * 2, Utility.VisualParams)
		
		if Raycast ~= nil then
			Velocity.Velocity = Vector3.zero
		end
	end)

	task.delay(RunDuration - 0.4, function()
		Yuki_FOV.Tween(70, {1})
		Afterimage(RootPart.Parent, false)
	end)
	
	Velocity.Destroying:Connect(function()
		ControllableVelocity:Disconnect()
		CancelConnection:Disconnect()
	end)

	task.delay(RunDuration - 0.3, Velocity.Destroy, Velocity)
end

function VFX.Start(RootPart : BasePart)
	local RunEffects = script.Run:Clone()
	RunEffects.Weld.Part1 = RootPart
	RunEffects.Parent = workspace.Visuals

	local SmokeEffects = script.FloorSmoke:Clone()
	SmokeEffects.Weld.Part1 = RootPart
	SmokeEffects.Parent = workspace.Visuals
	
	EffectUtility.EmitEffects(script.SFX, RootPart)

	EffectUtility.Toggle(RunEffects, true)
	EffectUtility.Toggle(SmokeEffects, true)

	local Thread = coroutine.create(function()
		while (RootPart.Parent ~= nil) do
			Smoke(RootPart)

			task.wait(0.01)
		end
	end)

	task.delay(RunDuration - 0.4, function()
		EffectUtility.Toggle(RunEffects, false)
		EffectUtility.Toggle(SmokeEffects, false)
		
		task.delay(2, RunEffects.Destroy, RunEffects)
		task.delay(2, SmokeEffects.Destroy, SmokeEffects)

		coroutine.close(Thread)
	end)
end

function VFX.Swing(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if (Distance > 75) then return end
	
	if (Distance <= 20) then
		ScreenPulse("Blue Choose")
	end

	Yuki_InfinityBubble(RootPart, 0.35, Vector3.one * 15, 0.35)

	local Direction = Vector3.yAxis * -10
	
	coroutine.wrap(RockHandler.Crater)(RootPart.Position, Direction, {
		Amount = 8;
		Distance = 1.75;	

		Inverted = true;

		MinExposeLevel = -0.5;
		MaxExposeLevel = -0.35;

		BaseDuration = 3;

		BaseX = 3,
		BaseZ = 1.5,

		SizeMagnitude = 0.75,
	})

	coroutine.wrap(RockHandler.Crater)(RootPart.Position, Direction, {
		Amount = 10;
		Distance = 5;	

		Inverted = true;

		MinExposeLevel = -1.25;
		MaxExposeLevel = -0.75;

		BaseDuration = 4.5;

		SizeMagnitude = 1.35,
	})

	coroutine.wrap(RockHandler.Rockst)(RootPart.Position, Direction, {
		Size = {0.75, 1.5},
		Count = 6,
		Velocity = 25,
	})
	
	EffectUtility.EmitEffects(script.Blast, RootPart)
end

return VFX
