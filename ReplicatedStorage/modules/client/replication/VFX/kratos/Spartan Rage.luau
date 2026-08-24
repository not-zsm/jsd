local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local SwrermMeshVFX = require( replicatedStorage.modules.client.replication.Global.SwrermMeshVFX )

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )
local Smoke = require( replicatedStorage.modules.client.replication.Global.Smoke )

local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

---------------------------------------------------------------------

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )

---------------------------------------------------------------------

local MeshesFolder = script.Meshes

return {
	Hit = function(AttackerModel : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(AttackerModel, replicatedStorage.animations.Attacks.kratos["Spartan Rage"].Hit)
		if (Retrieved == nil) then return end

		local Animation = Retrieved.Animation
		local Job = Retrieved.Job

		local RootPart = Retrieved.RootPart

		local function Hit(Parameter : string)
			if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 30 then
				CameraShake(2, 25, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.25)
				Vignette(Color3.fromRGB(255, 81, 0), 0.5, 0.15)
			end

			task.spawn(function()
				for Index = 1, 3 do
					RockHandler.Rocks("Side Dash", RootPart)
					Smoke(RootPart)
					
					task.wait(0.08)
				end
			end)
			
			if VictimModel then
				local Head = VictimModel:FindFirstChild("Head")
				
				if Head then
					Blood.BloodRays("SpitOut", Head)
				end
			end
			
			local HitFX : BasePart = script["Hit".. Parameter]:Clone()
			HitFX.CFrame = VictimModel.HumanoidRootPart.CFrame
			HitFX.Parent = workspace.Visuals

			EffectUtility.Emit(HitFX)

			for _, Object in MeshesFolder.Glass1:GetChildren() do
				local Mesh = Object:Clone()
				
				for _, highlight in ipairs(Mesh:GetDescendants()) do
					if highlight:IsA("Highlight") then highlight.Enabled = true end
				end
				
				Mesh:PivotTo(RootPart.CFrame * CFrame.new(0, 0, -1) * CFrame.Angles(math.rad(90), 0, 0))
				Mesh.Parent = workspace.Visuals

				SwrermMeshVFX.Emit(Mesh)

				task.delay(0.2, Mesh.Destroy, Mesh)
			end

			for _, Object in MeshesFolder["Hit"..Parameter]:GetChildren() do
				local Mesh = Object:Clone()

				Mesh:PivotTo(RootPart.CFrame * CFrame.new(0, 0, -1) * CFrame.Angles(0, -math.rad(90), 0))
				Mesh.Parent = workspace.Visuals

				SwrermMeshVFX.Emit(Mesh)

				task.delay(4, Mesh.Destroy, Mesh)
			end
		end

		Job:Task(Animation:GetMarkerReachedSignal("hit"):Connect(Hit))

		Job:Task(Animation:GetMarkerReachedSignal("finalhit"):Connect(function(Parameter : string)
			if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 30 then
				if VictimModel.Humanoid.Health <= 6 then
					CameraShake(7, 25, 0.01, 0.4, Vector3.one * 0.8)
					Vignette(Color3.fromRGB(255, 81, 0), 0.2, 0.55)
				else
					CameraShake(3.25, 35, 0.01, 0.3, Vector3.one * 0.7, Vector3.one * 0.5)
					Vignette(Color3.fromRGB(255, 81, 0), 0.4, 0.45)
				end
			end

			local FinalHitFX : BasePart = script.FinalHit:Clone()
			FinalHitFX.CFrame = VictimModel.HumanoidRootPart.CFrame * CFrame.Angles(0, math.pi, 0)
			FinalHitFX.Parent = workspace.Visuals

			EffectUtility.Emit(FinalHitFX)

			for Index = 1, 3 do
				local Mesh = MeshesFolder["Last"..Index]:Clone()

				Mesh:PivotTo(RootPart.CFrame * CFrame.new(0, 0, -1) * CFrame.Angles(math.rad(-90), 0, 0))
				Mesh.Parent = workspace.Visuals

				SwrermMeshVFX.Emit(Mesh)

				task.delay(4, Mesh.Destroy, Mesh)
			end

			for _, Object in MeshesFolder.LastHit:GetChildren() do
				local Mesh = Object:Clone()

				Mesh:PivotTo(RootPart.CFrame * CFrame.new(0, 0, -1) * CFrame.Angles(0, -math.rad(90), 0))
				Mesh.Parent = workspace.Visuals

				SwrermMeshVFX.Emit(Mesh)

				task.delay(4, Mesh.Destroy, Mesh)
			end

			for _, Object in MeshesFolder.Glass2:GetChildren() do
				local Mesh = Object:Clone()
				
				for _, highlight in ipairs(Mesh:GetDescendants()) do
					if highlight:IsA("Highlight") then highlight.Enabled = true end
				end

				Mesh:PivotTo(RootPart.CFrame * CFrame.new(0, 0, -1) * CFrame.Angles(math.rad(90), 0, 0))
				Mesh.Parent = workspace.Visuals

				SwrermMeshVFX.Emit(Mesh)

				task.delay(0.2, Mesh.Destroy, Mesh)
			end
		end))

		Hit(1)
	end,
}