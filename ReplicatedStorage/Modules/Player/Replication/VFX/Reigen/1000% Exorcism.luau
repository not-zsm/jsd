local VFX = {}
local Assets = script.VFX

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CurrentCamera = workspace.CurrentCamera

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Arms = {}

local function Effect(BasePart : BasePart, Effect : BasePart)
	local NewEffect = Effect:Clone()
	NewEffect.CFrame = BasePart.CFrame * Effect.CFrame
	NewEffect.Parent = workspace.Visuals
	EffectUtility.Emit(NewEffect)
end

local Trailers = {}

function VFX.Ready(RootPart : BasePart)
	if (Trailers[RootPart] == nil) then
		local Trails = script.Trails:Clone()

		EffectUtility.Weld(Trails, RootPart, CFrame.new(0, 0, -0.8))
		EffectUtility.Toggle(Trails, true)

		Trails.Parent = workspace.Visuals

		local Animation = Trails.Controller.Animator:LoadAnimation(script.TrailAnimation)

		Animation.Stopped:Once(function()
			Trails:Destroy()
		end)

		Trailers[RootPart] = Trails
		Animation:Play(0)
	end
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 50 then
		Vignette(Color3.fromRGB(90, 255, 115), 0.5, 0.3)
		CameraShake(2.5, 25, 0.02, 0.3)
	end

	Effect(RootPart, Assets.ready)
end

function VFX.PowerUp(RootPart : BasePart)
	if Trailers[RootPart] then
		EffectUtility.Toggle(Trailers[RootPart], false)
		Trailers[RootPart] = nil
	end
	
	if (Arms[RootPart] == nil) then
		local Arm = Assets.arm:Clone()
		EffectUtility.Weld(Arm, RootPart.Parent["Right Arm"], CFrame.new(0, -0.62, 0))
		Arm.Parent = workspace.Visuals

		EffectUtility.Emit(Arm.powerup)

		for _, Item in ipairs(Arm:GetChildren()) do
			if Item:IsA("ParticleEmitter") then
				Item.Enabled = true
			end
		end
		
		Arms[RootPart] = Arm
	end
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 50 then
		Vignette(Color3.fromRGB(90, 255, 115), 0.5, 0.3)
		CameraShake(2.5, 25, 0.02, 0.3)
	end
end

function VFX.PowerDown(RootPart : BasePart)
	if (Arms[RootPart] ~= nil) then
		EffectUtility.Toggle(Arms[RootPart], false)
		task.delay(1, Arms[RootPart].Destroy, Arms[RootPart])
		Arms[RootPart] = nil
	end
end

function VFX.VFX(RootPart : BasePart, Parameter : string)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if Parameter == "star" or Parameter == "camera" and Distance <= 125 then
		local Colors = {
			Color3.fromRGB(162, 85, 255),
			Color3.fromRGB(105, 185, 255),
			Color3.fromRGB(90, 255, 115),
			Color3.fromRGB(146, 113, 255),
		}

		if Distance <= 125 then
			Vignette(Colors[math.random(1, #Colors)], 0.25, 0.1)
			CameraShake(10, 100, 0.01, 0.03, Vector3.one * 0.8, Vector3.one * 0.5)
			Yuki_FOV.Tween(CurrentCamera.FieldOfView + 15, {0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out})
		end
	end
	
	if Parameter == "star" then
		Effect(RootPart, Assets[Parameter])
	end
	
	if Parameter == "camera" and Distance <= 125 then
		local ImpactFrame = Instance.new("ColorCorrectionEffect")
		ImpactFrame.TintColor = Color3.fromRGB(255, 248, 237)
		ImpactFrame.Brightness = -0.035
		ImpactFrame.Contrast = 0.075
		ImpactFrame.Saturation = 0.5
		ImpactFrame.Parent = Lighting

		local Tween1 = TweenService:Create(ImpactFrame, TweenInfo.new(2 / 60),
			{Contrast = 5}
		)

		Tween1:Play()
		Tween1.Completed:Wait()

		local Tween2 = TweenService:Create(ImpactFrame, TweenInfo.new(2 / 60),
			{Contrast = 9999, Brightness = 0, Saturation = 0.5}
		)

		Tween2:Play()
		Tween2.Completed:Wait()

		local Tween3 = TweenService:Create(ImpactFrame, TweenInfo.new(2 / 60),
			{Contrast = -9999, Saturation = -1}
		)

		Tween3:Play()
		Tween3.Completed:Wait()

		ImpactFrame:Destroy()
	end
end

local Blurs = {}

function VFX.AboutToShoot(RootPart : BasePart)
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 150 then
		local Blur = Instance.new("BlurEffect")
		Blur.Size = 0
		Blur.Parent = Lighting

		TweenService:Create(Blur, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Size = 12.5}
		):Play()

		task.delay(1, Blur.Destroy, Blur)

		if (RootPart ~= nil and Blurs[RootPart] == nil) then
			Blurs[RootPart] = Blur
		end
	end
end

function VFX.Unshoot(RootPart : BasePart)
	if RootPart and Blurs[RootPart] then
		Blurs[RootPart]:Destroy()
		Blurs[RootPart] = nil
	end
end

function VFX.Shoot(RootPart : BasePart)
	VFX.PowerDown(RootPart)
	VFX.Unshoot(RootPart)
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 225 then
		CameraShake(7.5, 100, 0.01, 2)
		Yuki_FOV.Tween(CurrentCamera.FieldOfView + 75, {0.25})

		task.delay(1, function()
			Yuki_FOV.Tween(70, {2, Enum.EasingStyle.Quad, Enum.EasingDirection.In})
		end)
	end
	
	local RootCF = CFrame.lookAlong(RootPart.Position, RootPart.CFrame.LookVector)
	local SmallOffset =  RootCF * CFrame.new(0, 0, -2.671)
	
	local Punch = Assets.punch:Clone()
	Punch:PivotTo(RootCF * CFrame.new(0, 0, -468.534))
	
	local Beam1 = Assets.beam:Clone()
	Beam1.CFrame = RootCF
	
	local Beam2 = Assets.Sbeam:Clone()
	Beam2.CFrame = RootCF
	
	Beam1.Parent = workspace.Visuals
	Beam2.Parent = workspace.Visuals
	Punch.Parent = workspace.Visuals
	
	EffectUtility.Emit(Punch)

	for _, Beam in pairs(Beam1.beam1:GetChildren()) do
		if Beam:IsA("Beam") then
			Beam.Brightness = 1
			Beam.TextureSpeed = 5
			
			TweenService:Create(Beam, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Brightness = 0}):Play()
			TweenService:Create(Beam, TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextureSpeed = 0}):Play()
		end
	end
	
	for _, Beam in pairs(Beam1.beam2:GetChildren()) do
		if Beam:IsA("Beam") then
			Beam.Brightness = 1
			Beam.TextureSpeed = 5
			
			TweenService:Create(Beam, TweenInfo.new(7, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Brightness = 0}):Play()
			TweenService:Create(Beam, TweenInfo.new(8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextureSpeed = 0}):Play()
		end
	end
	
	for _, Beam in pairs(Beam2.beam1:GetChildren()) do
		if Beam:IsA("Beam") then
			Beam.Brightness = 0.5
			Beam.TextureSpeed = 2
			
			TweenService:Create(Beam, TweenInfo.new(7, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Brightness = 0}):Play()
			TweenService:Create(Beam, TweenInfo.new(8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextureSpeed = 0}):Play()
		end
	end

	for _, Beam in pairs(Beam2.beam2:GetChildren()) do
		if Beam:IsA("Beam") then
			Beam.Brightness = 0.5
			Beam.TextureSpeed = 3
			
			TweenService:Create(Beam, TweenInfo.new(9, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Brightness = 0}):Play()
			TweenService:Create(Beam, TweenInfo.new(10, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextureSpeed = 0}):Play()
		end
	end
	
	task.delay(9, Beam1.Destroy, Beam1)
	task.delay(11, Beam2.Destroy, Beam2)

	-------------------------------------- 

	local M1Info = TweenInfo.new(146 / 60, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local M2Info = TweenInfo.new(57 / 60, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local M3Info = TweenInfo.new(246 / 60, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	local M4Info = TweenInfo.new(203 / 60, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	
	local M1 = script.Meshes.M1:Clone()
	M1.Size = Vector3.new(600, 600, 26.278)
	M1.Transparency = 0.6
	M1.CFrame = SmallOffset * CFrame.Angles(0, 0, math.rad(-180))
	
	local M2 = script.Meshes.M2:Clone()
	M2.Size = Vector3.new(900, 900, 26.278)
	M2.Transparency = 0.6
	M2.CFrame = SmallOffset * CFrame.Angles(0, 0, math.rad(-162.786))
	
	local M3 = script.Meshes.M3:Clone()
	M3.CFrame = RootCF * CFrame.new(0, 0, -22.308) * CFrame.Angles(math.rad(90), 0, math.rad(-162.786))
	M3.Mesh.Scale = Vector3.new(13, 3.078, 13)
	M3.Decal.Transparency = 0.8
	
	local M4 = script.Meshes.M4:Clone()
	M4.Size = Vector3.new(400, 12.919, 400)
	M4.Transparency = 0.7
	M4.CFrame = RootCF * CFrame.Angles(math.rad(90), math.rad(90), 0)
	
	M1.Parent = workspace.Visuals
	M2.Parent = workspace.Visuals
	M3.Parent = workspace.Visuals
	M4.Parent = workspace.Visuals

	--------------------------------------- 

	TweenService:Create(M1, M1Info, {
		CFrame = RootCF * CFrame.new(0, 0, -499.983) * CFrame.Angles(0, 0, math.rad(84.826)),
		Size = Vector3.new(300, 300, 1020.903)
	}):Play()
	
	TweenService:Create(M1, TweenInfo.new(151 / 60, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		Transparency = 1
	}):Play()
	
	--------------------------------------- 

	TweenService:Create(M2, M2Info, {
		CFrame = RootCF * CFrame.new(0, 0, -1013.532) * CFrame.Angles(0, 0, math.rad(-162.786)),
		Size = Vector3.new(100, 100, 2048),
		Transparency = 1
	}):Play()
	
	--------------------------------------- 

	TweenService:Create(M3, M3Info, {
		CFrame = RootCF * CFrame.new(0, 0, -541.008) * CFrame.Angles(math.rad(90), math.rad(90), 0),
	}):Play()
	
	TweenService:Create(M3.Decal, M3Info, {
		Transparency = 1
	}):Play()
	
	TweenService:Create(M3.Mesh, M3Info, {
		Scale = Vector3.new(13, 47.68, 13)
	}):Play()

	--------------------------------------- 

	TweenService:Create(M4, M4Info, {
		CFrame = RootCF * CFrame.new(0, 0, -919.296) * CFrame.Angles(math.rad(90), math.rad(-45), 0),
		Size = Vector3.new(400, 1851.511, 400),
		Transparency = 1
	}):Play()

	--------------------------------------- 

	task.delay(151 / 60, M1.Destroy, M1)
	task.delay(M2Info.Time, M2.Destroy, M2)
	task.delay(M3Info.Time, M3.Destroy, M3)
	task.delay(M4Info.Time, M4.Destroy, M4)
end

return VFX
