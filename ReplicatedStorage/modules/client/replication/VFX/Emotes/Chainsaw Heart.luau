local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local replicatedStorage = game:GetService("ReplicatedStorage")

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local MoonUtil = require( replicatedStorage.modules.client.replication.Global.MoonUtil )
local Animations = replicatedStorage.Animations.Emotes["Chainsaw Heart"]

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local OldLighting = require( replicatedStorage.modules.shared.Game.GameLighting )
local Job = require( replicatedStorage.modules.shared.Utilities.Job )
local Yuki_FOV = require(replicatedStorage.modules.client.replication.Global.Yuki_FOV)
local RunCameraRig = require(replicatedStorage.modules.client.replication.Global.RunCameraRig)

local function tweenBeamTransparency(
	beam: Beam,
	targetTrans: number,
	length: number,
	easingStyle: Enum.EasingStyle,
	easingDirection: Enum.EasingDirection,
	textureSpeed: number
)
	local startSeq = beam.Transparency
	local startKps = startSeq.Keypoints
	local numKps = #startKps

	local startTarget, endTarget
	if typeof(targetTrans) == "number" then
		startTarget, endTarget = targetTrans, targetTrans
	elseif typeof(targetTrans) == "string" then
		local firstNum, secondNum = targetTrans:match("([^,]+),([^,]+)")
		startTarget = tonumber(firstNum)
		endTarget = tonumber(secondNum)
	end

	if not startTarget then
		return
	end

	if beam.Enabled then
		warn("BEAM MUST BE DISABLED TO AVOID OVERWRITING ORIGINAL BEAM VALUES!")
		return
	end

	beam.Enabled = true

	easingStyle = easingStyle or Enum.EasingStyle.Linear
	easingDirection = easingDirection or Enum.EasingDirection.In

	local currentTextureSpeed = beam.TextureSpeed
	local currentTransparency = beam.Transparency
	local origValues = table.create(numKps)
	local goalVals = table.create(numKps)

	for i, kp in ipairs(startKps) do
		origValues[i] = kp.Value

		local t = kp.Time
		goalVals[i] = startTarget + (endTarget - startTarget) * t
	end

	TweenService:Create(beam, TweenInfo.new(length, easingStyle, easingDirection), { TextureSpeed = textureSpeed })
		:Play()

	local connection
	local passedTime = 0
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		passedTime += deltaTime

		if passedTime > length then
			connection:Disconnect()
			connection = nil
			return
		end

		local alpha = math.clamp(passedTime / length, 0, 1)
		alpha = TweenService:GetValue(alpha, easingStyle, easingDirection)

		local newKps = table.create(numKps)
		for i, kp in ipairs(startKps) do
			local currentValue = origValues[i] + (goalVals[i] - origValues[i]) * alpha
			newKps[i] = NumberSequenceKeypoint.new(kp.Time, currentValue, kp.Envelope)
		end

		beam.Transparency = NumberSequence.new(newKps)
	end)

	return function()
		beam.Enabled = false
		beam.TextureSpeed = currentTextureSpeed
		beam.Transparency = currentTransparency
	end
end

local function ArcEmit(Attachment : Attachment, Parent : BasePart, ToggleDuration : number)
	local Effect = Attachment:Clone()
	Effect.Parent = Parent

	EffectUtility.Arc.EmitAttachment(Effect)
	EffectUtility.Arc.ToggleAttachment(Effect, true, ToggleDuration)
	
	return Effect
end

return {
	Start = function(Model : Model, Chainsaw : Model)
		------------------- [ Variables ]-------------------
		local Retrieved = AnimationRetriever.new(Model, Animations.Start)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local IsPrimary = EffectUtility.SetPrimary({Model})

		local Assets = script.Assets

		--------------------- [ Setup ]---------------------
		-->> Image Vignette & ColorCorrection
		local VignetteUI : ImageLabel
		IsPrimary(function()
			local _Vignette = Job:Task(script.Vignette:Clone())
			VignetteUI = _Vignette.Image
		end)

		-->> HOW Marker
		local Marker = Job:Task(Assets.HOVMarker01:Clone())
		Marker.Weld.Part0 = Torso
		Marker.HOVTorso.Parent = Torso
		Marker.Parent = Torso

		--------------------- [ Camera + Other ]---------------------
		local Camera : Model
		
		IsPrimary(function()
			-->> Lighting
			Job:Task(function()
				TweenService:Create(Lighting, TweenInfo.new(0.5), {ExposureCompensation = OldLighting.ExposureCompensation}):Play()
			end)
			
			Camera = Job:Task(script.CamRig:Clone())
			Camera:PivotTo(RootPart.CFrame)
			Camera.Parent = workspace.Visuals

			local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(Animations.Camera)
			CameraAnimation:Play(0)

			Job:Task(RunService.PreAnimation:Connect(function()
				CameraAnimation.TimePosition = Animation.TimePosition
			end))

			local RemoveFOV = Yuki_FOV.AnimateWithMoonFile(replicatedStorage.FOVFiles["Chainsaw Heart"])
			Job:Task(RemoveFOV)

			Job:Task(RunCameraRig(RootPart, Camera, nil, {}))

			Job:Task(CameraAnimation.Stopped:Connect(function()
				if RemoveFOV then
					RemoveFOV()
					RemoveFOV = nil
				end

				Camera:Destroy()
			end))

			Job:Task(MoonUtil.AnimateValueWithMoonFile(Lighting, "ExposureCompensation", script.ExposureCompensation))
		end)
		
		local Active = {}
		
		---------------------- [ VFX ]----------------------
		
		local VFX = {
			["1"] = function()
				local t1 = TweenService:Create(VignetteUI, TweenInfo.new(0.3), {ImageTransparency = 0}):Play()
				Job:Task(t1)
				
				task.delay(0.717, function()
					VignetteUI.ImageTransparency = 0.6
					VignetteUI.ImageColor3 = Color3.fromRGB(255, 101, 40)
				end)
				
				task.delay(1.35, function()
					VignetteUI.ImageColor3 = Color3.fromRGB(0, 0, 0)
				end)
			end,
			
			["2"] = function()
				IsPrimary(function()
					Active["rootbg"] = Job:Task(EffectUtility.CloneAndToggle(Assets.root.bg, RootPart, true))
				end)
			end,

			["3"] = function()
				if Active["rootbg"] then
					EffectUtility.Toggle(Active["rootbg"], false)
				end
				
				Job:Task(ArcEmit(Assets.head.stress, Model.Head, 0.5))
			end,

			["4"] = function()
				Job:Task(ArcEmit(Assets.head.explode:Clone(), Model.Head, 0.5))
				
				for _, Union in pairs(Chainsaw["Left Arm"]:GetChildren()) do
					if Union:IsA("UnionOperation") then
						Union.Transparency = 0
					end
				end
				
				for _, Union in pairs(Chainsaw["Right Arm"]:GetChildren()) do
					if Union:IsA("UnionOperation") then
						Union.Transparency = 0
					end
				end
			end,

			["5"] = function()
				if Camera then
					EffectUtility.EmitAttachment(Camera.Torso["1"])
				end
			end,

			["6"] = function()
				EffectUtility.EmitAttachment(Camera.Torso["2"])
			end,

			["7"] = function()
				Job:Task(ArcEmit(Assets.rightarm.b, Model["Right Arm"], 2.5))
				Job:Task(ArcEmit(Assets.leftarm.b, Model["Left Arm"], 2.5))
			end,
			
			["8"] = function()
				-- Arm Beams
				EffectUtility.Toggle(Chainsaw["Left Arm"].Union2, true)
				EffectUtility.Toggle(Chainsaw["Right Arm"].Union2, true)
				
				-- uhh
				Job:Task(ArcEmit(Assets.leftarm["1"], Model["Left Arm"], 0.3))
				Job:Task(ArcEmit(Assets.leftarm["1"], Model["Right Arm"], 0.3))
				
				EffectUtility.CloneAndEmit(Assets.root.ground, RootPart)
			end,
			
			-- kinda left this part unformatted 😊
			["9"] = function()
				local transparency = 1
				local duration = 1
				local speed = 0
				local beamEasingStyle = Enum.EasingStyle.Sine
				local beamEasingDirection = Enum.EasingDirection.Out
				
				local effect = Job:Task(Assets.leftarm.beam:Clone())
				effect.Parent = Model["Left Arm"]
				
				for _, beam in effect:GetDescendants() do
					if not beam:IsA("Beam") then
						continue
					end

					local cleanUp = tweenBeamTransparency(beam, transparency, duration, beamEasingStyle, beamEasingDirection, speed)
					task.delay(duration + 0.15, function()
						cleanUp()
					end)
				end
				
				Active["LeftBeam"] = effect
			end,
			
			["10"] = function()
				local transparency = 1
				local duration = 1
				local speed = 0
				local beamEasingStyle = Enum.EasingStyle.Sine
				local beamEasingDirection = Enum.EasingDirection.Out
				
				local effect = Job:Task(Assets.rightarm.beam:Clone())
				effect.Parent = Model["Right Arm"]
				
				for _, beam in effect:GetDescendants() do
					if not beam:IsA("Beam") then
						continue
					end

					local cleanUp = tweenBeamTransparency(beam, transparency, duration, beamEasingStyle, beamEasingDirection, speed)
					task.delay(duration + 0.15, function()
						cleanUp()
					end)
				end
				
				Active["RightBeam"] = effect
			end,
			
			["11"] = function()
				Job:Task(ArcEmit(Assets.head.scream, Model.Head, 1.5))
			end,
			
			["12"] = function()
				local transparency = 1
				local duration = 2
				local speed = 0
				local beamEasingStyle = Enum.EasingStyle.Sine
				local beamEasingDirection = Enum.EasingDirection.Out
				
				local effect = Active["LeftBeam"]
				
				for _, beam in effect:GetDescendants() do
					if not beam:IsA("Beam") then
						continue
					end

					local cleanUp = tweenBeamTransparency(beam, transparency, duration, beamEasingStyle, beamEasingDirection, speed)
					task.delay(duration + 0.15, function()
						cleanUp()
					end)
				end
			end,
			
			["13"] = function()
				local transparency = 1
				local duration = 2
				local speed = 0
				local beamEasingStyle = Enum.EasingStyle.Sine
				local beamEasingDirection = Enum.EasingDirection.Out
				
				local effect = Active["RightBeam"]
				
				for _, beam in effect:GetDescendants() do
					if not beam:IsA("Beam") then
						continue
					end

					local cleanUp = tweenBeamTransparency(beam, transparency, duration, beamEasingStyle, beamEasingDirection, speed)
					task.delay(duration + 0.15, function()
						cleanUp()
					end)
				end
			end,
		}
		
		--------------------- [ Hooks ]---------------------
		Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter : string)
			local Func = VFX[Parameter]
			if Func then
				Func()
			end
		end))
	end,
}
