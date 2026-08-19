local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV)
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

local JobApplication = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local ATrainAfterimage = require(ReplicatedStorage.Modules.Player.Replication.Global.ATrainAfterimage)
local Afterimage = require(ReplicatedStorage.Modules.Player.Replication.Global.Afterimage)

local CreateSpin3D = require(script:FindFirstChild("3DSpinVFX").Create)

local ImpactFrames = LocalPlayer.PlayerGui.ImpactFrames.GreatSplitVerical

local function Clear(RootPart : BasePart, Type : "BodyVelocity" | "LinearVelocity")
	for _, Item in RootPart:GetDescendants() do
		if not Item:IsA(Type) then
			continue
		end
		
		Item:Destroy()
	end
end

return {
	Start = function(Character : Model, Reference : Configuration)
		local Retrieved = AnimationRetriever.new(Character, ReplicatedStorage.Animations.Attacks["Gebura Red Mist"].Kali.Windup)
		if (Retrieved == nil) then return end

		local Job = Retrieved.Job
		local Animation = Retrieved.Animation
		local RootPart = Retrieved.RootPart
		
		local Effects = script.VFX:Clone()
		Effects.Join.Part0 = RootPart
		Effects.Parent = workspace.Visuals
		
		Job:Task(function()
			EffectUtility.Toggle(Effects, false)
			task.delay(3, Effects.Destroy, Effects)
		end)
		
		Job:Task(Animation:GetMarkerReachedSignal("Boost"):Once(function()
			Clear(RootPart, "BodyVelocity")

			local UserBodyVelocity = Job:Task(Instance.new("BodyVelocity"))
			UserBodyVelocity.Name = "Kali Cutscne Startup Boost"
			UserBodyVelocity.Velocity = RootPart.CFrame.LookVector * 0
			UserBodyVelocity.MaxForce = vector.create(80_000, 0, 80_000)
			UserBodyVelocity.Parent = RootPart

			task.delay(1.73, UserBodyVelocity.Destroy, UserBodyVelocity)

			Reference.Destroying:Once(function()
				if not UserBodyVelocity then
					return
				end

				UserBodyVelocity:Destroy()
			end)

			local NumberValue = Instance.new("NumberValue")
			NumberValue.Value = 0
			NumberValue.Parent = UserBodyVelocity

			TweenService:Create(NumberValue, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Value = 75
			}):Play()

			task.delay(100/60, function()
				TweenService:Create(NumberValue, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Value = 0
				}):Play()
			end)

			while UserBodyVelocity:IsDescendantOf(workspace) and RootPart:IsDescendantOf(game) do
				UserBodyVelocity.Velocity = RootPart.CFrame.LookVector * NumberValue.Value
				task.wait()
			end

			if UserBodyVelocity then
				UserBodyVelocity:Destroy()
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("ShortBoost"):Connect(function()
			Clear(RootPart, "BodyVelocity")

			local UserBodyVelocity = Job:Task(Instance.new("BodyVelocity"))
			UserBodyVelocity.Name = "Kali short boost"
			UserBodyVelocity.Velocity = RootPart.CFrame.LookVector * 0
			UserBodyVelocity.MaxForce = vector.create(80_000, 0, 80_000)
			UserBodyVelocity.Parent = RootPart

			task.delay(0.25, UserBodyVelocity.Destroy, UserBodyVelocity)

			local NumberValue = Instance.new("NumberValue")
			NumberValue.Value = 75
			NumberValue.Parent = UserBodyVelocity

			TweenService:Create(NumberValue, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Value = 35
			}):Play()

			while UserBodyVelocity:IsDescendantOf(workspace) and RootPart:IsDescendantOf(game) do
				UserBodyVelocity.Velocity = RootPart.CFrame.LookVector * NumberValue.Value
				task.wait()
			end

			if UserBodyVelocity then
				UserBodyVelocity:Destroy()
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("Emit"):Connect(function(Name : string)
			local ToEmit = Effects:FindFirstChild(Name)
			
			if not ToEmit then
				return
			end
			
			EffectUtility.EmitAttachment(ToEmit, true)
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("Enable"):Connect(function(Name : string)
			local ToEnable = Effects:FindFirstChild(Name)

			if not ToEnable then
				return
			end

			EffectUtility.Toggle(ToEnable, true)
			
			if Name == "1" then
				local MeshSpin, MeshConnection = CreateSpin3D(RootPart)
				Job:Task(MeshSpin); Job:Task(MeshConnection)
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("Disable"):Connect(function(Name : string)
			local ToEnable = Effects:FindFirstChild(Name)

			if not ToEnable then
				return
			end

			EffectUtility.Toggle(ToEnable, false)
		end))
	end,
}