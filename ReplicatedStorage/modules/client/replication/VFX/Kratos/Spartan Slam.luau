local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

local DojyanMeshEmit = require( replicatedStorage.modules.client.replication.Global.DojyanMeshEmit )

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )

local Assets = script.Assets
local Animations = replicatedStorage.Animations.Attacks.Kratos["Spartan Slam"]

return {
	Start = function(Model : Model)
		local ImpactEvent : RemoteEvent = Model:WaitForChild("SpartanSlamLand", 10)

		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)

		local NewJob, WindupAnimation = Retrieved.Job, Retrieved.Animation
		local Humanoid, RootPart, Animator = Retrieved.Humanoid, Retrieved.RootPart, Retrieved.Animator

		local LoopAnimation = Animator:LoadAnimation(Animations.Loop)
		local ImpactAnimation = Animator:LoadAnimation(Animations.Impact)

		local IsMe = LocalPlayer.Character == Model

		local Jump = Assets.jump:Clone()
		Jump.CFrame = RootPart.CFrame * CFrame.new(0, -1.5, 0)
		Jump.Parent = workspace.Visuals
		EffectUtility.Emit(Jump)

		local Impacted = false
		
		local Duration = 0.6
		local Time = 0

		local startPosition = RootPart.Position
		local endPosition = startPosition + RootPart.CFrame.LookVector * 80
		local apexHeight = 100
	
		local Fly = Assets.flying:Clone()
		local FlyMeshes = Assets.flymeshes:Clone()

		local FlyOffset = CFrame.Angles(math.rad(-90), math.rad(-90), 0)
		
		EffectUtility.Weld(FlyMeshes, RootPart, FlyOffset)
		EffectUtility.Weld(Fly, RootPart, FlyOffset)

		Fly.Parent = workspace.Visuals
		EffectUtility.Emit(Fly, true)
		EffectUtility.Toggle(Fly, true)

		task.spawn(function()
			while not Impacted do
				for _, Item in ipairs(FlyMeshes:GetChildren()) do
					if Item:IsA("Model") then
						DojyanMeshEmit(Item, true)
					end
				end

				task.wait(0.2)
			end

			task.delay(2, Fly.Destroy, Fly)
			task.delay(2, FlyMeshes.Destroy, FlyMeshes)
		end)

		--local Connection : RBXScriptConnection; Connection = RunService.PostSimulation:Connect(function(Delta)
		--	if Impacted then return end

		--	endPosition = startPosition + RootPart.CFrame.LookVector * 80
		--	Time += Delta

		--	local alpha = math.clamp(Time / Duration, 0, 1)

		--	-- XZ interpolation
		--	local horizontalPos = startPosition:Lerp(endPosition, alpha)

		--	-- Y position using a parabolic arc
		--	local height = 4 * apexHeight * alpha * (1 - alpha)
		--	local finalPos = Vector3.new(horizontalPos.X, startPosition.Y + height, horizontalPos.Z)

			
		--	RootPart.CFrame = RootPart.CFrame:Lerp(CFrame.lookAlong(finalPos, RootPart.CFrame.LookVector), 0.2 * (Delta * 60))

		--	if alpha >= 1 then
		--		Connection:Disconnect()
		--		Impacted = true

		--		WindupAnimation:Stop(0)
		--		LoopAnimation:Stop(0)
		--		ImpactAnimation:Play(0)

		--		if IsMe then
		--			ImpactEvent:FireServer();
		--			RootPart.AssemblyLinearVelocity = -Vector3.yAxis * 25
		--		end
		--	end
		--end)
		
		NewJob:Task(WindupAnimation:GetMarkerReachedSignal("loop"):Once(function()
			if Impacted then return end
			
			WindupAnimation:Stop(0)
			LoopAnimation:Play(0)
			
			local Connection : RBXScriptConnection; Connection = RunService.PostSimulation:Connect(function(Delta)
				if Impacted then return end

				local Result = workspace:Raycast(RootPart.Position + Vector3.new(0, 3, 0), Vector3.yAxis * -10, Utility.VisualParams)

				if Result then
					Connection:Disconnect()
					Impacted = true

					WindupAnimation:Stop(0)
					LoopAnimation:Stop(0)
					ImpactAnimation:Play(0)

					if IsMe then
						ImpactEvent:FireServer();
						RootPart.AssemblyLinearVelocity = -Vector3.yAxis * 25
					end
				end
			end)
		end))
	end,

	Impact = function(Model : Model, Coordinate : CFrame)
		local Retrieved = AnimationRetriever.new(Model, Animations.Impact)

		local NewJob, WindupAnimation = Retrieved.Job, Retrieved.Animation
		local Humanoid, RootPart = Retrieved.Humanoid, Retrieved.RootPart

		--local Origin = RootPart.CFrame * CFrame.new(0, -1.5, -3)

		local Meshes = Assets.floormeshes:Clone()
		Meshes:PivotTo(Coordinate)
		task.delay(2, Meshes.Destroy, Meshes)

		for _, Item in ipairs(Meshes:GetChildren()) do
			if Item:IsA("Model") then
				DojyanMeshEmit(Item, true)
			end
		end

		local Impact = Assets.impact:Clone()
		Impact.CFrame = Coordinate
		Impact.Parent = workspace.Visuals
		EffectUtility.Emit(Impact)
	end,
}