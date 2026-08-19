local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

local SharmMeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.SharmMeshVFX )

local VFX = {}

function VFX.OnUltimateStart(Model : Model)
	local NewJob = Job.new()

	for _, Limb in ipairs(Model:GetChildren()) do
		if Limb:IsA("BasePart") and Limb.Name ~= "HumanoidRootPart" then
			for _, Aura in ipairs(script.VFX.Aura:GetChildren()) do
				local NewAura = NewJob:Task(Aura:Clone())

				if NewAura:IsA("ParticleEmitter") then
					NewAura:Emit(2)
					NewAura.Enabled = true
				end

				NewAura.Parent = Limb
			end
		end
	end
	
	--local NewJob = Job.new()

	--for _, Limb in ipairs(RootPart.Parent:GetChildren()) do
	--	if Limb:IsA("BasePart") and Limb.Name ~= "HumanoidRootPart" then
	--		for _, Aura in ipairs(script.VFX.Aura.Particles:GetChildren()) do
	--			local NewAura = NewJob:Task(Aura:Clone())
	--			NewAura.Enabled = true
	--			NewAura.Parent = Limb
	--		end

	--		if Limb.Name == "Torso" then
	--			local VFX1 = NewJob:Task(script.VFX.Aura.Part1:Clone())
	--			VFX1.Parent = workspace.Terrain

	--			local VFX2 = NewJob:Task(script.VFX.Aura.Part2:Clone())
	--			VFX2.Parent = workspace.Terrain

	--			NewJob:Task(RunService.PostSimulation:Connect(function()
	--				VFX1.CFrame = Limb.CFrame
	--				VFX2.CFrame = Limb.CFrame
	--			end))
	--		end
	--	end
	--end

	NewJob:Task(Model.AncestryChanged:Connect(function(_, Parent)
		if (Parent == nil) then
			NewJob:Clean()
		end
	end))

	local Replication : Configuration? = AttributeListener.GetReplicationFromSource(Model)

	if Replication then
		NewJob:Task(Replication:GetAttributeChangedSignal("Ultimate"):Connect(function()
			if not Replication:GetAttribute("Ultimate") then
				NewJob:Clean()
			end
		end))
	else
		NewJob:Clean()
	end
end


function VFX.Drop(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if Distance > 100 then return end
	
	local Raycast = workspace:Raycast(RootPart.Position, Vector3.yAxis * -10, Utility.VisualParams)
	
	if (Raycast ~= nil) then
		EffectUtility.EmitEffects(script.VFX.Start, workspace.Terrain, Raycast.Position + Vector3.new(0, 0.5, 0))
	end
end

function VFX.Jump(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if Distance > 200 then return end
	
	coroutine.wrap(function()
		task.wait(0.05)
		
		for Index = 1, 20 do
			local RandomPosition = RootPart.Position + Vector3.new(Utility.Seed:NextNumber(-25, 25), 0, Utility.Seed:NextNumber(-25, 25))
			local Direction = Vector3.yAxis * -10
			
			local Raycast = workspace:Raycast(RandomPosition, Direction, Utility.VisualParams)
			if (Raycast == nil) then return end
			
			coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
				Amount = 6;
				Distance = 2;	

				LookAt = {
					Min = -3,
					Max = -3
				},

				Exposure = {
					Min = 0.7,
					Max = 0.9
				},

				SizeMagnitude = 0.5,
			})

			EffectUtility.CraterSmoke("Small", Raycast)

			local Rock = Instance.new("Part")
			Rock.Color = Raycast.Instance.Color
			Rock.Material = Raycast.Instance.Material
			
			Rock.CanCollide = false
			Rock.Size = Vector3.one * Utility.Seed:NextNumber(0.75, 1.5)
			
			Rock.Position = Raycast.Position

			local BodyPosition = Instance.new("BodyPosition")
			BodyPosition.MaxForce = Vector3.one * 80000
			BodyPosition.P = Utility.Seed:NextNumber(2900, 3100)
			BodyPosition.Position = RandomPosition + (Vector3.yAxis * Utility.Seed:NextNumber(37.5, 42.5))
			BodyPosition.Parent = Rock
			
			Rock.Parent = workspace.Visuals
			Rock.AssemblyAngularVelocity = Vector3.one * Utility.Seed:NextNumber(-7, 7)

			task.delay(1.75, function()
				BodyPosition:Destroy()
				
				Rock.AssemblyLinearVelocity = Vector3.yAxis * -300
				Rock.CanCollide = true

				local Touched : RBXScriptConnection; Touched = Rock.Touched:Connect(function(Part)
					if not Part:IsDescendantOf(workspace.Map) then return end
					
					if Touched.Connected then
						Touched:Disconnect()
					end

					coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
						Amount = 6;
						Distance = 2;	

						LookAt = {
							Min = -3,
							Max = -3
						},

						Exposure = {
							Min = 0.7,
							Max = 0.9
						},

						SizeMagnitude = 0.5,
					})

					EffectUtility.CraterSmoke("Small", Raycast)
					Rock.AssemblyLinearVelocity += Vector3.yAxis * 10
				end)

				task.delay(2, function()
					TweenService:Create(Rock, TweenInfo.new(1), {
						Size = Vector3.zero,
						Transparency = 1
					}):Play()
					
					task.delay(1, Rock.Destroy, Rock)
				end)
			end)
		end
	end)()
	
	local Raycast = workspace:Raycast(RootPart.Position, Vector3.yAxis * -10, Utility.VisualParams)

	if (Raycast ~= nil) then
		local Position = Raycast.Position
		
		EffectUtility.EmitEffects(script.VFX.Jump, workspace.Terrain, Position + Vector3.new(0, 0.5, 0))

		SharmMeshVFX.Create(script.VFX.Mesh.Jump.TBottom, Position, Vector3.new(0, 1.2, 0))
		SharmMeshVFX.Create(script.VFX.Mesh.Jump.Mesh1, Position + Vector3.new(0, -5.25, 0), Vector3.new(0, 29.7, 0))
		SharmMeshVFX.Create(script.VFX.Mesh.Jump.AnotherWind, Position + Vector3.new(0, -2, 0), Vector3.new(0, 9.75, 0))
	end
end

function VFX.Shine(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if Distance > 200 then return end
	
	local Character : Model = RootPart.Parent
	local Torso : BasePart = Character.Torso
	
	if Player == Players:GetPlayerFromCharacter(Character) then
		ScreenPulse("Gojo Ultimate Shine")
		Yuki_FOV.Tween(80, {1})
	end
	
	EffectUtility.EmitEffects(script.VFX.Shine, Torso)
	
	local Butterflies = script.VFX.Assets.Butterfly:Clone()
	Butterflies.Parent = Torso
	Butterflies.Fly.Enabled = true

	task.delay(2, function()
		Butterflies.Fly.Enabled = false
	end)

	task.delay(Butterflies.Fly.Lifetime.Min + Butterflies.Fly.Lifetime.Max, Butterflies.Destroy, Butterflies)
end

function VFX.Fall(RootPart : BasePart)
	local Character : Model = RootPart.Parent

	if Player == Players:GetPlayerFromCharacter(Character) then
		Yuki_FOV.Tween(80, {1})
	end
end

function VFX.Land(RootPart : BasePart)
	local Distance = Players.LocalPlayer:DistanceFromCharacter(RootPart.Position)
	if Distance > 100 then return end

	if Distance < 25 then
		CameraShake(3, 25, 0.1, 0.35, Vector3.one * 0.8)
	end
	
	local Raycast = workspace:Raycast(RootPart.Position, Vector3.yAxis * -10, Utility.VisualParams)

	if (Raycast ~= nil) then
		local Position = Raycast.Position
		
		EffectUtility.EmitEffects(script.VFX.GroundCrack, workspace.Terrain, Position)
		EffectUtility.EmitEffects(script.VFX.Land, workspace.Terrain, Position + Vector3.new(0, 1, 0))

		SharmMeshVFX.Create(script.VFX.Mesh.GroundHit.AnotherWind, Position + Vector3.new(0, 2.5, 0), Vector3.new(0, -0.7, 0))
		SharmMeshVFX.Create(script.VFX.Mesh.GroundHit.Mesh1, Position + Vector3.new(0, 27.75, 0), Vector3.new(0, -21.75, 0))
		SharmMeshVFX.Create(script.VFX.Mesh.GroundHit.Mesh2, Position + Vector3.new(0, 8.85, 0), Vector3.new(0, -4, 0))
		SharmMeshVFX.Create(script.VFX.Mesh.GroundHit.Mesh3, Position + Vector3.new(0, 43, 0), Vector3.new(0, -25.5, 0))
	end
end

function VFX.Stance(RootPart : BasePart)
	local Model = RootPart.Parent
	
	if Player == Players:GetPlayerFromCharacter(Model) then
		Yuki_FOV.Tween(50, {0.35})

		task.delay(1, function()
			Yuki_FOV.Tween(70, {1})
		end)
	end
	
	VFX.OnUltimateStart(Model)
end

return VFX

