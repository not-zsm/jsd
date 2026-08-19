local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

--------------------------------------------------------------------------------------------

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

--------------------------------------------------------------------------------------------

local DimpleEffects = ReplicatedStorage.Effects.Characters.Reigen.Dimple
local EvasiveEffects = require( ReplicatedStorage.Modules.Player.Replication.VFX.Global.Dashing.Evasive )

--------------------------------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model,
			ReplicatedStorage.Animations.Attacks.Reigen["GO GREEN BLOB!"].Windup
		)

		if (Retrieved == nil) then return end

		local Animation, NewJob = Retrieved.Animation, Retrieved.Job
		local RootPart = Retrieved.RootPart

		local Dimple = DimpleEffects.Model:Clone()
		EffectUtility.Weld(Dimple, RootPart, CFrame.Angles(0, math.pi, 0))
		Dimple.Parent = workspace.Visuals

		NewJob:Task(Dimple)

		local DimpleAnimation = Dimple.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Reigen["GO GREEN BLOB!"].Dimple)
		DimpleAnimation:Play(0, 1, Animation.Speed)

		NewJob:Task(DimpleAnimation.Stopped:Once(function()
			Dimple:Destroy()
		end))
	end,

	DodgeFrames = function(Model : Model, Duration : number)
		local Highlight = Instance.new("Highlight")
		Highlight.OutlineTransparency = 1
		Highlight.FillTransparency = 0.6
		Highlight.FillColor = Color3.new(0, 1, 0.533333)
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.Parent = Model

		task.delay(Duration, function()
			TweenService:Create(Highlight, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{FillTransparency = 1}
			):Play()

			task.delay(0.1, Highlight.Destroy, Highlight)
		end)

		if Players:GetPlayerFromCharacter(Model) == LocalPlayer then
			local DodgeUI = script.DodgeUI:Clone()
			DodgeUI.Parent = LocalPlayer.PlayerGui

			task.delay(Duration, function()
				TweenService:Create(DodgeUI.TextLabel, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{TextTransparency = 1}
				):Play()

				TweenService:Create(DodgeUI.TextLabel.UIStroke, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{Transparency = 1}
				):Play()
			end)

			task.delay(Duration + 2, DodgeUI.Destroy, DodgeUI)
		end
	end,

	Possessed = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model,
			ReplicatedStorage.Animations.Attacks.Reigen["GO GREEN BLOB!"].Possess
		)

		if (Retrieved == nil) then return end

		local Animation, NewJob = Retrieved.Animation, Retrieved.Job
		local RootPart = Retrieved.RootPart

		local IsPossessed = Players:GetPlayerFromCharacter(Model) == LocalPlayer

		if IsPossessed then
			CameraShake(1, 20, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.3)

			local ScreenColor = Instance.new("ColorCorrectionEffect")
			ScreenColor.Parent = Lighting

			TweenService:Create(ScreenColor, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{TintColor = Color3.fromRGB(176, 255, 189)}
			):Play()

			task.delay(1.25, function()
				TweenService:Create(ScreenColor, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
					{TintColor = Color3.new(1, 1, 1)}
				):Play()

				task.delay(0.5, ScreenColor.Destroy, ScreenColor)
			end)
		else
			if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 30 then
				CameraShake(0.8, 15, 0.01, 0.275, Vector3.one * 0.8, Vector3.one * 0.25)
			end
		end

		local Aura = require(DimpleEffects.AuraScript)(Model)
		EffectUtility.EmitEffects(DimpleEffects.Possess, RootPart)

		NewJob:Task(function()
			for _, Item in Aura do
				Item.Enabled = false
				task.delay(1, Item.Destroy, Item)
			end
		end)

		NewJob:Task(Animation:GetMarkerReachedSignal("smack"):Connect(function()
			NewJob:Destroy()

			EffectUtility.EmitEffects(script.smack, Model.Head)
			EffectUtility.EmitEffects(DimpleEffects.Possess, RootPart)

			if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 30 then
				CameraShake(1.25, 20, 0.01, 0.3, Vector3.one * 0.75, Vector3.one * 0.35)
			end
		end))
	end,

	Flee = function(head : BasePart)
		local fleeingDimple = DimpleEffects.Model.Torso:Clone()
		fleeingDimple.Anchored = true
		fleeingDimple.CFrame = head.CFrame + Vector3.new(0, 1, 0)
		fleeingDimple.Parent = workspace.Visuals

		EffectUtility.Emit(fleeingDimple, true)

		local Flee = DimpleEffects.Flee:Clone()
		Flee.Parent = fleeingDimple
		Flee:Play()

		local center = fleeingDimple.Position
		local arcDirection = (head.CFrame.LookVector + Vector3.new(math.random(-1, 1), 0.3, math.random(-1, 1))).Unit
		local arcNormal = arcDirection:Cross(Vector3.yAxis).Unit

		local pathRadius = 15  -- Controls the size of the curved path
		local outwardSpeed = 35 -- Controls how fast Dimple moves away
		local rise = 7.5
		local spiralTime = 1.5
		local startTime = tick()

		local Connection; Connection = RunService.PreSimulation:Connect(function()
			local Time = (tick() - startTime)

			if Time >= 3.5 then
				return Connection:Disconnect()
			end

			if Time >= 2 then
				EffectUtility.Toggle(fleeingDimple, false)

				Flee:Stop()
				task.delay(2, fleeingDimple.Destroy, fleeingDimple)

				return
			end

			-- Adjust how far he should have traveled outward
			local outwardOffset = arcDirection * outwardSpeed * Time
			local theta = math.pi * 0.5 * (Time / spiralTime)
			local rotatedOffset = CFrame.fromAxisAngle(arcNormal, theta):VectorToWorldSpace(Vector3.new(pathRadius, 0, 0))

			local arcPos = center + outwardOffset + rotatedOffset + Vector3.new(0, Time * (rise / spiralTime), 0)

			-- Mild goofy spin
			local spin = CFrame.Angles(0, math.rad(Time * 180), 0)
			fleeingDimple.CFrame = CFrame.new(arcPos) * spin
		end)
	end,

	Go = function(StartPosition : Vector3, Duration : number, Target : BasePart)
		local StartTime = os.clock() --workspace:GetServerTimeNow()

		local Dimple = DimpleEffects.Model.Torso:Clone()
		Dimple.Anchored = true
		Dimple.CFrame = CFrame.new(StartPosition)
		Dimple.Parent = workspace.Visuals

		local Fly = DimpleEffects.Fly:Clone()
		Fly.Parent = Dimple
		Fly:Play()

		EffectUtility.Emit(Dimple, true)
		EffectUtility.Toggle(Dimple, true)
		
		task.delay(10, Dimple.Destroy, Dimple) -- anti mem leak

		local CurveX = 0.3
		local CurveY = Utility.Seed:NextNumber(0.4, 0.75)

		local Connection; Connection = RunService.PreSimulation:Connect(function()
			if (Dimple == nil or Dimple.Parent == nil) then
				return Connection:Disconnect()
			end
			
			if (Target == nil or Target.Parent == nil) then
				return Connection:Disconnect()
			end

			local Time = math.clamp((os.clock() - StartTime) / Duration, 0, 1)

			if (Time >= 1) then
				Connection:Disconnect()

				Fly:Stop()
				EffectUtility.Toggle(Dimple, false)

				return
			end

			local NewTargetPosition = Target.Position

			local Difference = (NewTargetPosition - StartPosition)
			local Direction = Difference.Unit
			local Distance = Difference.Magnitude

			local CurveStrength = CurveX * Distance
			local CurveAxis = Direction:Cross(Vector3.yAxis).Unit + (Vector3.yAxis * CurveY)
			local CurveOffset = CurveAxis * math.sin(Time * math.pi) * CurveStrength 

			local NewPosition = StartPosition + Direction * (Distance * Time) + CurveOffset

			Dimple.Position = NewPosition
			Dimple.CFrame = CFrame.lookAt(NewPosition, NewTargetPosition)
		end)
	end,

	Finisher = function(RootPart : BasePart)
		EffectUtility.EmitEffects(script.Finisher, RootPart)
	end,
}