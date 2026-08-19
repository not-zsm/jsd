local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Kratos["Spartan Rage"]

---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

---------------------------------------------------------------------

local DojyanMeshEmit = require( ReplicatedStorage.Modules.Player.Replication.Global.DojyanMeshEmit )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local ArcVFX = EffectUtility.Arc
local VFX = script.VFX

local VignetteColor = Color3.fromRGB(255, 143, 7)

---------------------------------------------------------------------

return {
	Start = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Finisher)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
	
		Job:Task(EffectUtility.AddSFX(script.SFX, Torso, 0.5))
		
		Job:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
			local Distance = LocalPlayer:DistanceFromCharacter(Torso.Position)

			if Distance <= 75 then
				local Attachment = ArcVFX.CloneAndEmit(VFX[Parameter], RootPart)

				if Parameter == "2" or Parameter == "3" then -- stab, pull

					if Distance <= 15 then
						CameraShake(1.15, 25, 0.015, 0.275, Vector3.one * 0.8, Vector3.one * 0.4)
						Vignette(VignetteColor, 0.65, 0.25)
						
						Yuki_FOV.Tween(62.5, {0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true})
					end

				elseif Parameter == "4" and VictimModel and VictimModel.Parent then -- head stab
					local HeadVFX = ArcVFX.CloneAndEmit(script.VictimHeadVFX["4.5"], VictimModel.Head)

					if Distance <= 15 then
						CameraShake(1.5, 25, 0.02, 0.3, Vector3.one * 0.8, Vector3.one * 0.4)
						Vignette(VignetteColor, 0.65, 0.25)
					end

					task.spawn(function()
						for Index = 1, 10 do
							CameraShake(0.5, 20, 0.01, 0.1, Vector3.one * 0.8)
							Vignette(Color3.fromRGB(255, 0, 0), 0.9, 0.1)
							
							Blood.BloodRaysWithoutPreset(HeadVFX, {
								Amount = Vector2.new(3, 4),
								Spread = Vector2.new(45, 45),

								Face = Enum.NormalId.Front,

								PoolSize = 1.15,
								PoolSizeRandom = Vector2.new(-0.25, 0.25),
							})

							task.wait(0.15)
						end
					end)
					
				elseif Parameter == "5" then -- head slam
					
					if Distance <= 15 then
						CameraShake(2, 25, 0.02, 0.4, Vector3.one * 0.8, Vector3.one * 0.35)
						Vignette(VignetteColor, 0.5, 0.35)
					end

				elseif Parameter == "6" or Parameter == "7" or Parameter == "8" then -- slices

					if Distance <= 15 then
						CameraShake(1.25, 25, 0.02, 0.3, Vector3.one * 0.8, Vector3.one * 0.4)
						Vignette(VignetteColor, 0.65, 0.25)
					end

					Blood.BloodRaysWithoutPreset(Attachment, {
						Amount = Vector2.new(3, 5),
						Spread = Vector2.new(45, 45),

						Face = Enum.NormalId.Front,

						PoolSize = 1.25,
						PoolSizeRandom = Vector2.new(-0.3, 0.3),
					})
					
					Yuki_FOV.Tween(68, {0.075, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, true})

				elseif (Parameter == "9" or Parameter == "10" or Parameter == "11" or Parameter == "12" or Parameter == "13") or (Parameter == "a1" or Parameter == "a2") then
					CameraShake(1.85, 27.5, 0.01, 0.1, Vector3.one * 0.8, Vector3.one * 0.35)
					Vignette(VignetteColor, 0.4, 0.1)
					
					Yuki_FOV.Tween(68, {0.075, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, true})

				elseif Parameter == "14" then
					CameraShake(2.4, 28, 0.02, 0.3, Vector3.one * 0.8, Vector3.one * 0.25)
					Vignette(VignetteColor, 0.35, 0.35)
				end
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("final"):Connect(function(Parameter : string)
			local Distance = LocalPlayer:DistanceFromCharacter(Torso.Position)

			if Distance <= 15 then
				CameraShake(5.5, 35, 0.01, 0.45, Vector3.one * 0.8, Vector3.one * 0.15)
				Vignette(VignetteColor, 0.35, 0.5)
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("meshvfx"):Connect(function(Parameter : string)
			local Mesh : Model = script.Meshes[Parameter]:Clone()
			Mesh:PivotTo(RootPart.CFrame)
			task.delay(1, Mesh.Destroy, Mesh)

			for _, Item in ipairs(Mesh:GetChildren()) do
				if Item:IsA("Model") then
					DojyanMeshEmit(Item, true)
				end
			end
		end))

		ArcVFX.CloneAndEmit(VFX["1"], RootPart)
	end,
}