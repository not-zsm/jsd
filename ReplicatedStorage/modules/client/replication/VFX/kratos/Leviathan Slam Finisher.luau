local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

---------------------------------------------------------------------------------

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Yuki_FOV = require( replicatedStorage.modules.client.replication.Global.Yuki_FOV )

local AttributeListener = require( replicatedStorage.modules.client.replication.Global.AttributeListener )
local RunCameraRig = require( replicatedStorage.modules.client.replication.Global.RunCameraRig )

local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )

local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )

---------------------------------------------------------------------------------

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )

---------------------------------------------------------------------------------

local Holder = script.Holder
local LocalPlayer = Players.LocalPlayer

local AuraTable = {}

return {
	OnStart = function(AttackerModel : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(AttackerModel, replicatedStorage.animations.Attacks.kratos["Leviathan Rush"].SlamFinisher)

		if (Retrieved == nil) then return end

		local Animation, NewJob = Retrieved.Animation, Retrieved.Job
		local RootPart = Retrieved.RootPart

		local Player = Players:GetPlayerFromCharacter(AttackerModel)
		local VictimPlayer = Players:GetPlayerFromCharacter(VictimModel)
		
		local BloodFX = NewJob:Task(script.Holder.Blood:Clone())
		
		local function VictimArmChop(Side : string, ActualVelocity)
			local Arm : BasePart = VictimModel[Side.. " Arm"]

			if Arm.Transparency == 1 then
				return
			end
			
			if (VictimModel == nil) then
				return
			end

			local ArmModel = Instance.new("Model")
			ArmModel.Name = "ArmEffect"
			ArmModel.Parent = workspace.Visuals

			if VictimModel:FindFirstChildOfClass("Shirt") then
				VictimModel.Shirt:Clone().Parent = ArmModel
			end

			for _, Item in VictimModel:GetChildren() do
				if Item:IsA("CharacterMesh") then
					Item:Clone().Parent = ArmModel
				end
			end

			local FakeArm = Arm:Clone()
			FakeArm.CanCollide = true
			FakeArm.CollisionGroup = "Rockst"
			
			local ArmHumanoid = Instance.new("Humanoid")
			ArmHumanoid.BreakJointsOnDeath = false
			ArmHumanoid.Parent = ArmModel

			FakeArm.Parent = ArmModel
			Arm.Transparency = 1

			FakeArm.AssemblyLinearVelocity = ActualVelocity
			FakeArm.AssemblyAngularVelocity = ActualVelocity / 2

			task.spawn(function()
				repeat
					FakeArm.CanCollide = true

					task.wait(0.25)
				until not ArmModel:IsDescendantOf(game)
			end)

			task.delay(7.5, function()
				ArmModel:Destroy()
				Arm.Transparency = 0
			end)
		end
		
		NewJob:Task(Animation:GetMarkerReachedSignal("BloodStart"):Connect(function()
			if not LocalPlayer:GetAttribute("Blood") then return end
			
			BloodFX.Parent = VictimModel.Torso
			
			EffectUtility.Toggle(BloodFX, true)
		end))
		
		NewJob:Task(Animation:GetMarkerReachedSignal("pullout1"):Connect(function()
			local BloodPull = script.Holder.HitPull:Clone()
			local WindPull = script.Holder.WindPull:Clone()
			
			BloodPull.Parent = VictimModel.Torso
			WindPull.Parent = VictimModel.Torso
			
			EffectUtility.Emit(BloodPull)
			EffectUtility.Emit(WindPull)
		end))
		
		NewJob:Task(Animation:GetMarkerReachedSignal("pullout2"):Connect(function()
			EffectUtility.Toggle(BloodFX, false)
			
			task.delay(1.5, BloodFX.Destroy, BloodFX)
		end))
		
		NewJob:Task(Animation:GetMarkerReachedSignal("slash1"):Connect(function()
			local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
			
			local FX = script.slash1:Clone()
			FX.CFrame = RootPart.CFrame * CFrame.new(-1.3, 0.15, -0.8) * CFrame.Angles(0, math.pi, math.rad(90))
			FX.Parent = workspace.Visuals
			
			EffectUtility.Emit(FX)

			local ActualVelocity = (VictimModel.HumanoidRootPart.CFrame.RightVector * -25) + Vector3.new(0, 20, 0)
			VictimArmChop("Right", ActualVelocity)
			
			Blood.BloodRaysWithoutPreset(VictimModel.Torso, {
				Face = Enum.NormalId.Top, 
				SpreadAngle = Vector2.new(65, 65), 
				Amount = Vector2.new(4, 6), 
				Power = 15,
				PoolSize = 1.25	
			})
			
			if (Distance <= 15) then
				CameraShake(3, 10, 0.01, 0.25, Vector3.one * 0.8)
				Vignette(Color3.fromRGB(170, 0, 0), 0.25, 0.5)
			end
		end))
		
		NewJob:Task(Animation:GetMarkerReachedSignal("slash2"):Connect(function()
			local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
			
			local FX = script.slash2:Clone()
			FX.CFrame = RootPart.CFrame * CFrame.new(-1.3, 0.15, -0.8) * CFrame.Angles(0, math.pi, math.rad(90))
			FX.Parent = workspace.Visuals

			EffectUtility.Emit(FX)

			local ActualVelocity = (VictimModel.HumanoidRootPart.CFrame.RightVector * 25) + Vector3.new(0, 20, 0)
			
			VictimArmChop("Left", ActualVelocity)
			
			Blood.BloodRaysWithoutPreset(VictimModel.Torso, {
				Face = Enum.NormalId.Top, 
				SpreadAngle = Vector2.new(35, 75), 
				Amount = Vector2.new(6, 8), 
				Power = 22,
				PoolSize = 1.5	
			})
			
			if (Distance <= 15) then
				CameraShake(4, 12, 0.01, 0.25, Vector3.one * 0.8)
				Vignette(Color3.fromRGB(184, 0, 0), 0.1, 0.5)
			end
		end))
		
		NewJob:Task(Animation:GetMarkerReachedSignal("slam1"):Connect(function()
			local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
			
			local SlashFX = script.slash3:Clone()
			SlashFX.CFrame = RootPart.CFrame * CFrame.new(-0, 0.15, -1.8) * CFrame.Angles(math.rad(90), 0, math.rad(-90))
			SlashFX.Parent = workspace.Visuals
			
			local SlamFX = script.slam:Clone()
			SlamFX.CFrame = RootPart.CFrame * CFrame.new(0.8, -2.25, -6.3)
			SlamFX.Parent = workspace.Visuals
			
			local Position = SlamFX.Position
			local Direction = Vector3.yAxis * -5

			EffectUtility.Emit(SlashFX)
			EffectUtility.Emit(SlamFX)
			
			coroutine.wrap(RockHandler.Crater)(Position, Direction, {
				Amount = 4,
				Distance = 4,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -5,
					Max = -5
				},

				Exposure = {
					Min = 0.3,
					Max = 0.5
				},

				BaseZ = 1.35,

				SizeMultiplier = 1.1,
			})

			coroutine.wrap(RockHandler.Crater)(Position, Direction, {
				Amount = 12,
				Distance = 7,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = 7,
					Max = -7
				},

				Exposure = {
					Min = 0.3,
					Max = 0.4
				},

				SizeMultiplier = 1.35,
			})
			
			if (Distance <= 15) then
				CameraShake(7, 15, 0.01, 0.4, Vector3.one * 0.8)
				Vignette(Color3.fromRGB(212, 0, 0), 0.1, 0.75)
			end
		end))
	end,
}