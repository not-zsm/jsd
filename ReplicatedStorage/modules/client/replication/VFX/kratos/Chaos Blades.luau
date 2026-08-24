local VFX = {};

local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local MeshVFX = require( replicatedStorage.modules.client.replication.Global.MeshVFX )

local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )

local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )

local VFXFolder = script.VFX

function VFX.Start(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	local Winds = VFXFolder.Winds
	local Middle = VFXFolder.Middle

	if (Distance < 200) then
		local Offset = CFrame.Angles(0, math.rad(-180), 0)

		local Base = Winds:Clone()
		Base.Parent = workspace.Visuals
		task.delay(3.2, Base.Destroy, Base)
		
		EffectUtility.Weld(Base, RootPart, Offset)

		EffectUtility.ToggleForTime(Base.ground,1.3)
		EffectUtility.ToggleForTime(Base.windleft,1.2)
		EffectUtility.ToggleForTime(Base.windright,1.2)

		task.delay(1.5, function()
			EffectUtility.Emit(Base.groundslash, true)
			EffectUtility.Emit(Base.slash1, true)
		end)

		task.delay(1.8, function()
			EffectUtility.Emit(Base.groundslash, true)
			EffectUtility.Emit(Base.slash2, true)
		end)
		
		do  --Impacts-- 
			local Offset = CFrame.new(0, -3, 0) * CFrame.Angles(0, math.rad(-180), 0)

			local Base = Middle:Clone()
			Base.Parent = workspace.Visuals
			task.delay(3.2, Base.Destroy, Base)
			
			EffectUtility.Weld(Base, RootPart, Offset)
			EffectUtility.ToggleForTime(Base.Attachment,1.3)

			local Start = os.clock()
			
			local LastSpark = nil
			local LastSlash = nil

			while os.clock() - Start < 1.38 do
				local Distance =  LocalPlayer:DistanceFromCharacter(RootPart.Position)
				
				local RandomSpark = Utility.PickRandom(Base.sparks:GetChildren(), function(Choice)
					return Choice ~= LastSpark
				end)
				
				local RandomSlash = Utility.PickRandom(Base.slashes:GetChildren(), function(Choice)
					return Choice ~= LastSlash
				end)
				
				LastSpark = RandomSpark
				LastSlash = RandomSlash
				
				EffectUtility.Emit(RandomSpark, true)
				EffectUtility.Emit(RandomSlash, true)

				if (Distance < 50) then
					RockHandler.Rockst(RandomSpark.Position, Vector3.yAxis * -10, {
						Count = 3,
						Size = {0.25, 1},
						Velocity = 15
					})
				end
				
				if (Distance < 25) then
					Vignette(Color3.fromRGB(213, 110, 19), 0.5, nil, true)
					CameraShake(1, 10, 0.05, 0.1, Vector3.one, Vector3.zero)
				end

				task.wait(0.03)
			end
			
			while os.clock() - Start < 1.38 do
				MeshVFX.new({ -- big mesh to show how powerful hes swinging
					MeshPart = replicatedStorage.modules.effect.assets.Parts.MeshVFX.Start, 
					CFrame = RootPart.CFrame * CFrame.new(0, -2.5, 0),

					TweenDuration = 0.45,
					Duration = 0.45,

					TweenProperties = {
						Transparency = 1,
						Size = Vector3.new(40.5, 3.5, 40.5)
					},
				})
				
				task.wait(0.06)
			end
		end
	end
end

function VFX.SwingUp1(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if Distance < 200 then
		local Effect = VFXFolder.FirstSlash:Clone()
		Effect.CFrame = RootPart.CFrame
		Effect.Parent = workspace.Visuals
		EffectUtility.Emit(Effect)

		RockHandler.RockLines(Effect.slash.WorldCFrame * CFrame.new(0, 0, 7), {
			Amount = 6,
			Angle = math.rad(35),
		})

		RockHandler.Rockst(Effect.slash.WorldPosition, Vector3.yAxis * -10, {
			Count = 5,
			Size = {0.25, 1},
			Velocity = 35
		})
	end
	
	if Distance < 25 then
		Vignette(Color3.fromRGB(213, 110, 19), 0.35)
		CameraShake(5.8, 5.1, 0.05, 0.1, Vector3.one, Vector3.zero)
	end
end

function VFX.SwingUp2(RootPart : BasePart)
	local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)

	if Distance < 200 then
		local Effect = VFXFolder.SecondSlash:Clone()
		Effect.CFrame = RootPart.CFrame
		Effect.Parent = workspace.Visuals
		EffectUtility.Emit(Effect)

		RockHandler.RockLines(Effect.slash.WorldCFrame * CFrame.new(0, 0, 7), {
			Amount = 6,
			Angle = math.rad(35),
		})

		RockHandler.Rockst(Effect.slash.WorldPosition, Vector3.yAxis * -10, {
			Count = 5,
			Size = {0.25, 1},
			Velocity = 35
		})
	end
	
	if Distance < 25 then
		Vignette(Color3.fromRGB(213, 110, 19), 0.35)
		CameraShake(5.8, 5.1, 0.05, 0.1, Vector3.one, Vector3.zero)
	end
end

function VFX.Hit(RootPart : BasePart)
	local RandomOrientation = RockHandler.GenerateRandomOrientation(true)
	
	local Hit = script.Parent.Hit.Effect:Clone()
	Hit.CFrame = RootPart.CFrame * RandomOrientation
	Hit.Parent = workspace.Terrain
	EffectUtility.Emit(Hit)
	
	if LocalPlayer:GetAttribute("Blood") then
		local Hit = script.Parent.Hit.Blood:Clone()
		Hit.CFrame = RootPart.CFrame * RandomOrientation
		Hit.Parent = workspace.Terrain
		EffectUtility.Emit(Hit)
	end
end

return VFX