local VFX = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local Data = require( script.Data )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local LocalPlayer = Players.LocalPlayer

local DaybreakList = {}

function VFX.Create(Model : Model, StartCF : CFrame, Velocity : Vector3)
	-- if (DaybreakList[Model] ~= nil) then return end
	
	EffectUtility.AddSFX(script.Throw, Model.Torso, 0.01)

	local MaxDistance = Data.MaxDistance
	local StartFallingAt =  Data.StartFallingAt
	local Gravity = Data.Gravity
	
	local CF = StartCF
	local RotCF = CFrame.identity

	if (LocalPlayer:DistanceFromCharacter(StartCF.Position) <= 15) then
		CameraShake(3, 25, 0.03, 0.4, Vector3.one * 0.8)
	end

	if LocalPlayer.Character == Model then
		Vignette(Color3.fromRGB(141, 189, 252), 0.9, 0.8)
	end
	
	local Daybreak = script.Daybreak:Clone()
	Daybreak.Name = `{Model.Name}'s Daybreak`
	Daybreak.CFrame = StartCF
	Daybreak.Parent = workspace.Visuals
	
	local Highlight = Instance.new("Highlight")
	Highlight.FillColor = Color3.new(1, 0.917647, 0.666667)
	Highlight.FillTransparency = 0.45
	Highlight.OutlineTransparency = 1
	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	Highlight.Parent = Daybreak


	local ProjectileJob; ProjectileJob = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Daybreak, function(Delta : number)
		local DistanceFromStart = (StartCF.Position - CF.Position).Magnitude
		
		if DistanceFromStart > MaxDistance then
			Daybreak.CanCollide = true 
			Daybreak.Anchored = false

			Daybreak.AssemblyLinearVelocity = Velocity.Unit * 20
			return
		end

		local NewDaybreakPosition = CF.Position + Velocity.Unit * (Velocity.Magnitude * Delta)
		local Raycast = workspace:Raycast(CF.Position, NewDaybreakPosition - CF.Position, Utility.VisualParams)

		if Raycast and Raycast.Instance.CanCollide then
			ProjectileJob:Destroy()
			
			Daybreak.Anchored = true
			-- Daybreak.CFrame = Daybreak.CFrame * CFrame.new(0, 0, 1.5)
			
			if Daybreak then
				-- Daybreak["Wall Hit"]:Play()
			end
			
			task.delay(3, function()
				local ExplodePosition = if Daybreak:FindFirstChild("ExplodeAttachment") then Daybreak.ExplodeAttachment.WorldPosition else Daybreak.Position
				
				local Explosion = script.Assets.Explode:Clone()
				Explosion.Parent = workspace.Terrain
				Explosion.WorldPosition = ExplodePosition

				task.delay(2, Explosion.Destroy, Explosion)
				EffectUtility.Emit(Explosion)

				Daybreak:Destroy()
			end)
			
			return
		end

		if DistanceFromStart > StartFallingAt then
			Velocity += Gravity * Delta
		end
		
		CF += Velocity * Delta
		local LookRotation = CFrame.lookAt(CF.Position, CF.Position + Velocity)
		Daybreak.CFrame = LookRotation * CFrame.Angles(0, math.rad(180), math.rad(90))
	end)

	DaybreakList[Model] = {
		Daybreak = Daybreak,
		ProjectileJob = ProjectileJob
	}

	local Remover : RBXScriptConnection; Remover = Model.AncestryChanged:Connect(function(_, Parent)
		if (Parent == nil) then
			Remover:Disconnect()
			VFX.Remove(Model)
		end
	end)

	Daybreak.Destroying:Once(function()
		Remover:Disconnect()
	end)
end


function VFX.StickToVictim(Model : Model, Torso : BasePart)
	local DaybreakTable = DaybreakList[Model]

	EffectUtility.AddSFX(script.Hit, Torso, 0.01)
	
	if DaybreakTable  then
		DaybreakTable.ProjectileJob:Destroy()
		
		-------------------------------------------------------
		
		local Daybreak : BasePart = DaybreakTable.Daybreak
		
		if (Daybreak and Daybreak.Parent ~= nil) then
			--Daybreak.CFrame = CFrame.lookAt(Torso.Position, Daybreak.Position) * CFrame.new(2, 0, 0)

			local Weld = Instance.new("WeldConstraint")
			Weld.Part0 = Daybreak
			Weld.Part1 = Torso

			Daybreak.Anchored = false
			Weld.Parent = Daybreak

			Torso.AncestryChanged:Connect(function(_, Parent) 
				if (Parent == nil) then
					Weld:Destroy()
					Daybreak.CanCollide = true
				end
			end)
			
			DaybreakTable.StickWeld = Weld
		end
	
		DaybreakTable.Sticked = true

		-------------------------------------------------------
		
		
		local FireVFX = {}
		
		for _, Effect in pairs(script.Assets.FireVFX:GetChildren()) do
			local EffectClone = Effect:Clone()
			EffectClone.Parent = Torso
			
			table.insert(FireVFX, EffectClone)
		end
		
		task.delay(3, function()
			local ExplodePosition = if Daybreak:FindFirstChild("ExplodeAttachment") then Daybreak.ExplodeAttachment.WorldPosition else Daybreak.Position
			
			local Explosion = script.Assets.Explode:Clone()
			Explosion.Parent = workspace.Terrain
			Explosion.WorldPosition = ExplodePosition
			
			task.delay(2, Explosion.Destroy, Explosion)
			EffectUtility.Emit(Explosion)
			
			Daybreak:Destroy()
			for _, Effect in FireVFX do
				Effect:Destroy()
			end
		end)
	end
end


return VFX
