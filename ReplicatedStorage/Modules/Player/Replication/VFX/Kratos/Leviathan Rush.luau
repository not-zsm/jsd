local VFX = {};

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local MeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.MeshVFX )

local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

--VFX.Slam = function(RootPart : BasePart, Count : number)
--	local Slams = script.VFX[`slam{Count}`]:Clone()
--	Slams.CFrame = RootPart.CFrame * CFrame.new(0,-3,-9.5) * CFrame.Angles(0, math.rad(180), 0)
--	Slams.Parent = workspace.Visuals
--	EffectUtility.Emit(Slams)

--	if Count == 1 then
--		CameraShake(2.5, 25, 0.01, 0.35, Vector3.one * 0.8)

--		MeshVFX.new{ -- This is NOT mine i used the Yuki Mesh thing Since i assume its alr ingame? , it should be easier to Import into Jsd?
--			MeshPart = script.Start, 
--			CFrame = RootPart.CFrame*CFrame.new(0, -4, -9.5);

--			TweenDuration = .2;
--			TweenDelay = 0,
--			Duration = 0.2,

--			TweenProperties = {
--				Transparency = 1,
--				Size = Vector3.new(15.722, 0, 15.722) ,
--			}
--		}

--		--local IceSpike = MeshVFX.new{ -- This is NOT mine i used the Yuki Mesh thing Since i assume its alr ingame? , it should be easier to Import into Jsd?

--		--	MeshPart = script.IcePillar, 
--		--	CFrame = RootPart.CFrame*CFrame.new(0, 0, -9) * CFrame.Angles(0, math.rad(-90), 0),

--		--	TweenDuration = 0.15;
--		--	TweenDelay = 0,
--		--	Duration = 1.5,

--		--	TweenProperties = {
--		--		Transparency = 1,
--		--		Size = Vector3.one * 10,
--		--	}
--		--}

--		--task.delay(1.4, function()
--		--	local Part = script.VFX.Part:Clone()
--		--	Part.CFrame = IceSpike.CFrame
--		--	Part.Parent = workspace.Visuals
--		--	EffectUtility.Emit(Part)
--		--end)
--	else
--		CameraShake(2.5, 25, 0.01, 0.35, Vector3.one * 0.8)

--		MeshVFX.new{
--			MeshPart = script.Start, 
--			CFrame = RootPart.CFrame * CFrame.new(0 ,-5, -9.5);

--			TweenDuration = 0.7;
--			Duration = 0.7,

--			TweenProperties = {
--				Transparency = 1,
--				Size = Vector3.new(40, 0.075, 40),
--			},
--		}
--	end

--end

--VFX.Slash = function(RootPart : BasePart, Count : number)
--	local SlashVFX = script.VFX[`Slash{Count}`].Slash:Clone()
--	EffectUtility.Weld(SlashVFX, RootPart, CFrame.new(0,0, -0.5))
--	SlashVFX.Parent = workspace.Visuals
--	EffectUtility.Emit(SlashVFX)

--	CameraShake(1.5, 10, 0.01, 0.15, Vector3.one * 0.8)
--end

local Assets = script.VFX

local function NewEffect(RootPart : BasePart, Effect : BasePart)
	local Effect = Effect:Clone()
	Effect.CFrame = RootPart.CFrame * Effect.CFrame + Vector3.yAxis * -3
	Effect.Parent = workspace.Visuals
	EffectUtility.Emit(Effect)
	
	return Effect
end

function VFX.Smoke(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if Distance < 100 then
		NewEffect(RootPart, Assets.SmokeFloor)
	end
end

function VFX.Slam(RootPart : BasePart, Count : number)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if Distance < 100 then
		local Effect = NewEffect(RootPart, Assets.Slam)
		
		local Position = Effect.Position
		local Direction = Vector3.yAxis * -5
		
		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 6,
			Distance = 2.75,

			LookAt = { -- Where the rocks face towards (y axis)
				Min = -5,
				Max = -5
			},

			Exposure = {
				Min = 0.3,
				Max = 0.5
			},

			BaseZ = 1.35,

			SizeMultiplier = 0.85,
		})

		coroutine.wrap(RockHandler.Crater)(Position, Direction, {
			Amount = 11,
			Distance = 5,
			
			LookAt = { -- Where the rocks face towards (y axis)
				Min = 7,
				Max = -7
			},
			
			Exposure = {
				Min = 0.3,
				Max = 0.4
			},

			SizeMultiplier = 1.1,
		})

		coroutine.wrap(RockHandler.Rockst)(Position, Direction, {
			Count = 20,
			Size = {0.35, 0.9},
			Velocity = 40,
		})
		
		local CF = RootPart.CFrame
		
		local Mesh = Assets.Mesh:Clone()
		Mesh.CFrame = CF * CFrame.new(0, -2, -7)
		Mesh.Size = Vector3.new(12, 2, 12)
		Mesh.Transparency = 0.95
		Mesh.Parent = workspace.Visuals

		local One = TweenService:Create(Mesh, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
			{CFrame = CF * CFrame.new(0, -4, -7)}
		)

		local Two = TweenService:Create(Mesh, TweenInfo.new(0.233, Enum.EasingStyle.Linear),
			{Size = Vector3.new(27, 2, 27)}
		)
		
		local Three = TweenService:Create(Mesh, TweenInfo.new(0.35, Enum.EasingStyle.Linear),
			{Transparency = 1}
		)

		One:Play()
		Two:Play()
		Three:Play()

		task.delay(2, Mesh.Destroy, Mesh)
	end

	if (Distance <= 15) then
		CameraShake(4, 40, 0.01, 0.5, Vector3.one * 0.8)
		Vignette(Color3.fromRGB(34, 152, 255), 0.25, 0.25)
	end
end

function VFX.Slash(RootPart : BasePart, Count : number)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if Distance < 100 then 
		local Slash : typeof(Assets.Slash1.Slash) = Assets[`Slash{Count}`].Slash:Clone()
		EffectUtility.Weld(Slash, RootPart, CFrame.new(0, 0, -0.125) * CFrame.Angles(0, 0, math.rad(180)))
		Slash.Parent = workspace.Visuals
		EffectUtility.Emit(Slash)
	end

	if (Distance <= 15) then
		CameraShake(1, 10, 0.01, 0.25, Vector3.one * 0.8)
		Vignette(Color3.fromRGB(66, 183, 255), 0.6, 0.2)
	end
end

function VFX.SlashHit(VictimRootPart : BasePart, Count : number)
	local Distance = LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)

	if Distance < 100 then
		local Hit : typeof(Assets.Slash1.Hit) = Assets[`Slash{Count}`].Hit.Attachment:Clone()
		Hit.Parent = VictimRootPart
		EffectUtility.Emit(Hit)
		
		local HitSFX : Sound = script.HitSFX[Count]:Clone()
		HitSFX.Parent = VictimRootPart
		HitSFX:Play()
		task.delay(2, HitSFX.Destroy, HitSFX)

		if LocalPlayer:GetAttribute("Blood") then
			local Hit = script.Parent.Hit.SmallerBlood:Clone()
			Hit.WorldCFrame = VictimRootPart.CFrame * RockHandler.GenerateRandomOrientation(true)
			Hit.Parent = workspace.Terrain
			EffectUtility.Emit(Hit)
		end
	
		Blood.BloodRaysWithoutPreset(VictimRootPart, {
			Amount = Vector2.new(3, 5),
			Spread = Vector2.new(45, 45),
			Face = Enum.NormalId.Front,
			PoolSize = 0.85,
		})
	end

	if (Distance <= 20) then
		CameraShake(1.5, 35, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.5)
	end
end

return VFX