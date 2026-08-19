local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Edgerunner[script.Name]

local AenoirEmit = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.AenoirEmit )
local Shockwave = require( ReplicatedStorage.Modules.Player.Replication.Global.Shockwave )

--if Is_Source then
--	local Velocity = Job:Task(VelocityUtil.Create(RootPart, "GROW A BLUE GARDEN!"))
--	Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
--	Velocity.Parent = RootPart

--	local NumberValue = Instance.new("NumberValue")
--	NumberValue.Parent = Velocity

--	Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
--		Velocity.Velocity = RootPart.CFrame.LookVector * NumberValue.Value
--	end)

--	TweenService:Create(NumberValue, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = 40}):Play()

--	Job:Task(Animation:GetMarkerReachedSignal("land"):Connect(function()
--		TweenService:Create(NumberValue, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Value = 0}):Play()
--	end))
--end

return {
	["Start"] = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end
		
		local RootPart = Retrieved.RootPart
		local Job = Retrieved.Job
		local Animation = Retrieved.Animation
		
		local VENSOUL_HOYAAHHH = script.HOYAA:Clone()
		VENSOUL_HOYAAHHH.Parent = RootPart
		VENSOUL_HOYAAHHH:Play()
		task.delay(1.3, VENSOUL_HOYAAHHH.Destroy, VENSOUL_HOYAAHHH)
		
		local Is_Source = (LocalPlayer.Character == Model)
		
		Job:Task(EffectUtility.AddSFX(script.Start, RootPart, 0.4))
		
		Job:Task(Animation:GetMarkerReachedSignal("jump"):Connect(function()
			AenoirEmit(script.Mesh, RootPart.CFrame * CFrame.Angles(math.rad(90), 0, 0))
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("land"):Connect(function()
			Job:Task(EffectUtility.AddSFX(script.Step, RootPart, 0.4))
			EffectUtility.AddSFX(script.Whiff, RootPart)
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("step"):Connect(function()
			EffectUtility.Arc.CloneAndEmit(script.Dash, RootPart)
			EffectUtility.Arc.CloneAndEmit(script.Stepping, RootPart)
		end))
		
		if Is_Source then
			local Velocity = Job:Task(VelocityUtil.Create(RootPart, "GROW A BLUE GARDEN!"))
			Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
			Velocity.Parent = RootPart

			local NumberValue = Instance.new("NumberValue")
			NumberValue.Parent = Velocity

			Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function()
				Velocity.Velocity = RootPart.CFrame.LookVector * NumberValue.Value
			end)

			TweenService:Create(NumberValue, TweenInfo.new(0.75, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = 25}):Play()

			Job:Task(Animation:GetMarkerReachedSignal("jump"):Connect(function()
				TweenService:Create(NumberValue, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Value = 35}):Play()
			end))
			
			Job:Task(Animation:GetMarkerReachedSignal("land"):Connect(function()
				TweenService:Create(NumberValue, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Value = 0}):Play()
			end))
			
			Job:Task(Animation:GetMarkerReachedSignal("lunge"):Connect(function()
				TweenService:Create(NumberValue, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Value = 35}):Play()
			end))
			
			Job:Task(Animation:GetMarkerReachedSignal("slide"):Connect(function()
				TweenService:Create(NumberValue, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Value = 0}):Play()
			end))
		end
	end,
	
	["GROW A HIT"] = function(AttackerRoot : BasePart, VictimRoot : BasePart)
		Shockwave(VictimRoot, AttackerRoot, nil, Vector3.new(0.2, 15, 15))
		
		--local GardenBack = script.Hit:Clone()
		--GardenBack.CFrame = CFrame.lookAt(VictimRoot.Position, AttackerRoot.Position) * CFrame.Angles(0, math.pi, 0)
		--GardenBack.Parent = workspace.Visuals
		--EffectUtility.Emit(GardenBack)
		
		EffectUtility.CloneAndEmit(script.Knockback, AttackerRoot)
		EffectUtility.CloneAndEmit(script.Hit, VictimRoot)
		
		Blood.BloodRays("SpitOut", VictimRoot)
		
		if EffectUtility.Distance_Close(VictimRoot.Parent) then
			Lighting.ExposureCompensation = 1

			TweenService:Create(Lighting, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ExposureCompensation = 0}
			):Play()
		end
	end,
}