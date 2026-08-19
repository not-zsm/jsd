local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local Afterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.Afterimage )

local VFX = {}

local Assets = script.Assets

function VFX.Velocity(RootPart : BasePart, Velocity : number, Duration : number, DestroyTime : number)
	local FoundKnockback = RootPart:FindFirstChild("Velocity")

	if (FoundKnockback ~= nil) then
		FoundKnockback:Destroy()
	end

	local Push = Instance.new("BodyVelocity")
	Push.MaxForce = Vector3.new(1, 0, 1) * 80000
	Push.Parent = RootPart
	
	local Start = os.clock()
	
	local ControllableVelocity = RunService.PostSimulation:Connect(function()
		if (Push.Parent == nil) then
			return
		end

		Push.Velocity = RootPart.CFrame.LookVector * Velocity * math.max(0, Duration - (os.clock() - Start) / Duration)
	end)
	
	Push.Destroying:Connect(function()
		ControllableVelocity:Disconnect()
	end)
	
	task.delay(DestroyTime, Push.Destroy, Push)
end

function VFX.Hand(Arm : BasePart)
	local Hand = Assets.Hand:Clone()
	Hand.Name = "Hand"
	Hand.Parent = Arm

	EffectUtility.EmitAttachment(Hand, true)

	task.delay(1.5, function()
		for _, Item in ipairs(Hand:GetChildren()) do
			Item.Enabled = false
		end
		
		task.delay(1, Hand.Destroy, Hand)
	end)
end

function VFX.Hit(AttackerRootPart : BasePart, VictimRootPart : BasePart, Count : string)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)
	
	if (Distance < 75) then
		if Count < "7" then
			Afterimage(AttackerRootPart.Parent, {0.75}, {0.5}, 2)

			if Count == "6" then
				EffectUtility.EmitEffects(script.Spin, AttackerRootPart)

				task.delay(0.45, function()
					EffectUtility.EmitEffects(script.Spin, AttackerRootPart)
				end)
			end
		end

		EffectUtility.EmitEffects(script.BlueHit, VictimRootPart)
		EffectUtility.EmitEffects(script.Hit, VictimRootPart)
	end
end

function VFX.Start(AttackerRootPart : BasePart)
	VFX.Velocity(AttackerRootPart, 100, 0.525, 0.3)

	local Model : Model = AttackerRootPart.Parent
	
	local RockThread = coroutine.create(function()
		while (Model.Parent ~= nil) do
			RockHandler.Rocks("Flowing Hands", AttackerRootPart)

			task.wait(0.1)
		end
	end)

	local SmokeThread = coroutine.create(function()
		while (Model.Parent ~= nil) do
			Smoke(AttackerRootPart)

			task.wait(0.025)
		end
	end)
	
	coroutine.resume(RockThread)
	coroutine.resume(SmokeThread)
	
	Model:GetAttributeChangedSignal("FlowingHands"):Once(function()
		task.cancel(RockThread)
		task.cancel(SmokeThread)
	end)
end

return VFX
