local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Powers["Solar Vision"]

---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local JobModule = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

---------------------------------------------------------------------

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		Retrieved.Job:Task(EffectUtility.AddSFX(script["Solar Vision Windup"], Retrieved.Torso, 0.4))
	end,
	
	Loop = function(ReplicateLaser : UnreliableRemoteEvent, Model : Model, ServerMousePosition : Vector3)
		local Retrieved = AnimationRetriever.new(Model, Animations.Loop)
		if (Retrieved == nil) then return end
		
		local IsMainPlayer = (LocalPlayer.Character == Model)

		local RootPart = Retrieved.RootPart
		local Head = RootPart.Parent.Head
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		
		if EffectUtility.Distance_Close(Model) then
			CameraShake(3, 30, 0.01, 0.5, Vector3.one * 0.8)
			
			if IsMainPlayer then
				local LoopCoroutine = coroutine.create(function()
					while true do
						Vignette(Color3.new(1, 0, 0), 0.85, 3)
						CameraShake(1.5, 15, 0.05, 0.1, Vector3.one * 0.8)

						task.wait(0.1)
					end
				end)

				Job:Task(LoopCoroutine)
				task.spawn(LoopCoroutine)
			end
		end

		Job:Task(EffectUtility.AddSFX(script["Solar Vision Loop"], Retrieved.Torso, 0.25))
		
		local Head : BasePart = Model:FindFirstChild("Head")
		if (Head == nil) then return end
		
		-- Server Sided vfx cause i had to
		local LaserEyes = script.laser.LaserEyes:Clone()
		local LaserGround = script.laser.Ground:Clone()
		LaserGround.WorldPosition = ServerMousePosition

		LaserEyes.LEye.Beam.Attachment1 = LaserGround.Left
		LaserEyes.REye.Beam.Attachment1 = LaserGround.Right

		LaserEyes.Parent = Head
		LaserGround.Parent = workspace.Terrain

		Job:Task(function()
			EffectUtility.Toggle(LaserEyes, false)
			EffectUtility.Toggle(LaserGround, false)

			task.delay(3, LaserEyes.Destroy, LaserEyes)
			task.delay(3, LaserGround.Destroy, LaserGround)
		end)
		
		local Goal = ServerMousePosition
		
		if IsMainPlayer then
			local RayParams = RaycastParams.new()
			RayParams.FilterDescendantsInstances = {workspace.Visuals, Model}
			RayParams.FilterType = Enum.RaycastFilterType.Exclude

			Job:Task(RunService.PreRender:Connect(function()
				local MousePosition = Mouse.Hit.Position
				local Origin = Head.Position
				
				local RayResult = workspace:Raycast(Origin, (MousePosition - Origin), RayParams)

				if RayResult then
					Goal = RayResult.Position
				end
			end))
		else
			Job:Task(ReplicateLaser.OnClientEvent:Connect(function(Position : Vector3)
				Goal = Position
			end))
		end
		
		Job:Task(RunService.PreRender:Connect(function(Delta)
			LaserGround.WorldPosition = LaserGround.WorldPosition:Lerp(Goal, 0.5 * (Delta * 60))
		end))
		
		EffectUtility.Toggle(LaserEyes, true)
		EffectUtility.Toggle(LaserGround, true)
	end,
}