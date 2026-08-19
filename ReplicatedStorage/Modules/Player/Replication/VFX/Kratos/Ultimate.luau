local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

----------------------------------------------------------------------------------------------------------------

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

----------------------------------------------------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )

----------------------------------------------------------------------------------------------------------------

local DojyanMeshEmit = require( ReplicatedStorage.Modules.Player.Replication.Global.DojyanMeshEmit )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Effects = script.Effects
local Meshes = script.Meshes

----------------------------------------------------------------------------------------------------------------

OnUltimateStart = function(Model : Model)
	local Aura = {}

	for _, Limb in ipairs(script.Aura:GetChildren()) do
		for _, VFX in ipairs(Limb:GetChildren()) do
			local NewVFX = VFX:Clone()
			NewVFX:AddTag("UltimateAura")
			NewVFX.Parent = Model[Limb.Name]
			NewVFX.Enabled = true
			Aura[NewVFX] = true
		end
	end

	AttributeListener.new(Model, "Ultimate", function()
		for VFX in Aura do
			VFX.Enabled = false
			task.delay(2, VFX.Destroy, VFX)
		end

		table.clear(Aura)
	end)
end

return {
	OnUltimateStart = OnUltimateStart,
	
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, ReplicatedStorage.Animations.Attacks.Global.Ultimate.Kratos.Start)
		if (Retrieved == nil) then return end
		
		local Animation = Retrieved.Animation
		local Job = Retrieved.Job
		
		local RootPart = Retrieved.RootPart
		local IsMainPlayer = LocalPlayer == Players:GetPlayerFromCharacter(Model) 
	
		local function OffsetVFXOnItself(VFX)
			return RootPart.CFrame * VFX.CFrame
		end
		
		local StartRage = Job:Task(Effects.StartRage:Clone())
		local StartRageMeshes = Job:Task(Meshes.Burst:Clone())
		local StartImpactMeshes = Job:Task(Meshes.Impact:Clone())
		local Flames = Job:Task(Effects.Flames:Clone())
		local EndRage = Effects.EndRage:Clone()
		
		local function VFX(Name : string, Distance : number?)
			if (Distance ~= nil and Distance >= 100) then return end
			if LocalPlayer:DistanceFromCharacter(RootPart.Position) >= 100 then return end
			
			local Effect : BasePart = Effects:FindFirstChild(Name)

			if Effect then
				local NewEffect = Effect:Clone()
				NewEffect.CFrame = OffsetVFXOnItself(NewEffect)
				NewEffect.Parent = workspace.Visuals
				
				EffectUtility.Emit(NewEffect)
			end
		end
		
		local SFX = script.SFX:Clone()
		SFX.Parent = RootPart
		SFX:Play()
		
		Job:Task(function()
			TweenService:Create(SFX, TweenInfo.new(0.5),
				{Volume = 0}
			):Play()

			task.delay(1, SFX.Destroy, SFX)
		end)
		
		task.spawn(function()
			local Theme = script.UltimateTheme:Clone()
			Theme.Parent = RootPart
			Theme:Play()
			
			AttributeListener.new(Model, "Ultimate", function()
				TweenService:Create(Theme, TweenInfo.new(0.5),
					{Volume = 0}
				):Play()
				
				task.delay(1, Theme.Destroy, Theme)
			end)
		end)
		
		-- Heartbeat
		if IsMainPlayer then
			local function heartbeat()
				Yuki_FOV.Tween(50, {0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.In})
				Vignette(Color3.fromRGB(255, 0, 0), 0.6, 0.1)

				task.delay(0.08, function()
					Yuki_FOV.Tween(70, {0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
					Vignette(Color3.fromRGB(255, 0, 0), 0.6, 0.1)
				end)
			end

			heartbeat()
			task.delay(0.3, heartbeat)
		end

		Job:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(VFX))
		
		Job:Task(Animation:GetMarkerReachedSignal("jump"):Connect(function(Parameter : string)
			VFX("Jump")
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("slam"):Connect(function(Parameter : string)
			local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
			if Distance <= 30 then
				CameraShake(3.1, 22.5, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.3)
			end
			
			if (Distance <= 100) then
				local CF = RootPart.CFrame * Effects.Slam.CFrame

				local Raycast = workspace:Raycast(CF.Position + Vector3.yAxis * 2.5, Vector3.yAxis * -15, Utility.VisualParams)
				local NewEffect = Effects.Slam:Clone()

				if Raycast then
					NewEffect.CFrame = (CFrame.lookAt(Raycast.Position, Raycast.Position + Raycast.Normal) * CFrame.Angles(math.rad(90), 0, 0)) + Vector3.new(0, 1, 0)
				else
					NewEffect.CFrame = OffsetVFXOnItself(NewEffect)
				end

				NewEffect.Parent = workspace.Visuals
				EffectUtility.Emit(NewEffect)
				
				coroutine.wrap(RockHandler.Crater)(NewEffect.Position, Vector3.yAxis * -10, {
					Amount = 15,
					Distance = 7.5,

					Exposure = {
						Min = 0.3,
						Max = 0.5
					},

					SizeMultiplier = 1,
				})

				coroutine.wrap(RockHandler.Crater)(NewEffect.Position, Vector3.yAxis * -10, {
					Amount = 20,
					Distance = 14,

					Exposure = {
						Min = 0.75,
						Max = 1
					},

					SizeMultiplier = 1.5,
				})
				

				coroutine.wrap(RockHandler.Rockst)(NewEffect.Position, Vector3.yAxis * -10, {
					Count = 8,
					Size = {0.85, 1},
					Velocity = 150,
				})

			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("startimpact"):Connect(function()
			local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
			
			if Distance <= 30 then
				CameraShake(3, 30, 0.01, 0.025, Vector3.one * 0.8)
			end
			
			VFX("StartImpact", Distance)
			if Distance <= 100 then
				StartImpactMeshes:PivotTo(RootPart.CFrame)
				StartImpactMeshes.Parent = workspace.Visuals

				for _, Mesh in ipairs(StartImpactMeshes:GetChildren()) do
					if Mesh:IsA("Model") then
						DojyanMeshEmit(Mesh, true)
					end
				end
			end
		end))
		
		do
			local RageShake = nil
			
			Job:Task(Animation:GetMarkerReachedSignal("endrage"):Connect(function(Parameter : string)
				local Raging = (Parameter == "true")

				if Raging then
					local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
					
					if (RageShake == nil and Distance <= 30) then
						RageShake = Job:Task(CameraShake(1.5, 17.5, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.3))
						Yuki_FOV.Tween(80, {0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out})
						
						Job:Task(Yuki_FOV.Reset)
					end
					
					if IsMainPlayer then
						Vignette(Color3.fromRGB(255, 81, 0), 0.4, 2.4)
					end
					
					VFX("EndImpact", Distance)
					
					if Distance <= 100 then
						EndRage.CFrame = OffsetVFXOnItself(EndRage)
						EndRage.Parent = workspace.Visuals
					end
				else
					if (RageShake ~= nil) then
						RageShake:StartFadeOut(0.3)
						Yuki_FOV.Tween(70, {0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out})
					end
					
					task.delay(4, StartRage.Destroy, EndRage)
				end

				EffectUtility.Toggle(EndRage, Raging)
			end))
		end
		
		Job:Task(Animation:GetMarkerReachedSignal("aura"):Connect(function()
			EffectUtility.Toggle(Flames, false)
			OnUltimateStart(Model)
		end))
		
		do
			local StartRaging = false
			local RageShake
			
			Job:Task(Animation:GetMarkerReachedSignal("startrage"):Connect(function(Parameter : string)
				StartRaging = (Parameter == "true")

				if StartRaging then
					local Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
					
					if (RageShake == nil and Distance <= 30) then
						RageShake = Job:Task(CameraShake(2.5, 20, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.6))
						Yuki_FOV.Tween(87.5, {0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out})
						
						Job:Task(Yuki_FOV.Reset)
					end
					
					if IsMainPlayer then
						Vignette(Color3.fromRGB(255, 81, 0), 0.4, 3)
					end
					
					if (Distance <= 100) then
						Utility.SafeCall(function()
							local DistortionWind = StartRageMeshes.DistorionWind
							local Fire = StartRageMeshes.Fire

							EffectUtility.Weld(StartRageMeshes, RootPart)
							StartRageMeshes.Parent = workspace.Visuals

							local RandomY = math.random(-180, 180)

							for _, Mesh : Model in ipairs(StartRageMeshes:GetChildren()) do
								if not Mesh:IsA("Model") then continue end

								task.spawn(function()
									while StartRaging do
										local RandomY = math.random(-180, 180)

										DistortionWind.End.Orientation = Vector3.new(0, RandomY + 90, 0)
										DistortionWind.Start.Orientation = Vector3.new(0, RandomY + 90, 0)

										Fire.End.Orientation = Vector3.new(0, RandomY + 90, 0)
										Fire.Start.Orientation = Vector3.new(0, RandomY + 90, 0)

										DojyanMeshEmit(Mesh, true)

										task.wait(0.3)
									end
								end)
							end
						end)
	
						StartRage.CFrame = OffsetVFXOnItself(StartRage)
						StartRage.Parent = workspace.Visuals
					end
				else
					if (RageShake ~= nil) then
						RageShake:StartFadeOut(0.3)
						Yuki_FOV.Tween(70, {0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out})
					end
				end
				
				EffectUtility.Toggle(StartRage, StartRaging)
			end))
		end
		
		EffectUtility.Weld(Flames, RootPart, Flames.CFrame)
		Flames.Parent = workspace.Visuals
		
		EffectUtility.Toggle(Flames, true)
		
		if IsMainPlayer then
			Yuki_FOV.Tween(52.5, {1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
			Job:Task(Yuki_FOV.Reset)
		end
	end,
}
