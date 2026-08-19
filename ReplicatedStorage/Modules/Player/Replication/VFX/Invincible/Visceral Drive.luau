local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Invincible["Visceral Drive"]

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

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

---------------------------------------------------------------------

return {
	Hit = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Hit)
		if (Retrieved == nil) then return end
		local IsMainPlayer = (LocalPlayer.Character == Model)

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		
		-- SFX
		Job:Task(EffectUtility.AddSFX(script.Hit, Torso, 0.5)) -- ohh
		
		--local Ended = false
		--local HitSFX = script.Hit:Clone()

		--HitSFX.Parent = Retrieved.Torso
		--HitSFX:Play()

		--Job:Task(function()
		--	if Ended == false then
		--		HitSFX:Destroy()
		--	end
		--end)

		--task.delay(8, HitSFX.Destroy, HitSFX)
		
		local Velocity = VelocityUtil.Create(RootPart, "Sea Salt Start")
		Velocity.MaxForce =  Vector3.new(1, 0, 1) * 80000 --Vector3.one * 80000
		Velocity.Parent = RootPart

		local Max = 90
		local Multiply = 0

		Job:Task(Velocity)

		Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
			Velocity.Velocity = RootPart.CFrame.LookVector * Multiply
		end)
		
		local Data = {
			["4"] = 70,
			["5"] = 40,
			["6"] = 30,
			["7"] = 60,
			["8"] = 30,
			["9"] = 15,
			["10"] = 10,
			["11"] = 1,
			["12"] = 90,
			["13"] = 50,
		}
		
		Job:Task(Animation:GetMarkerReachedSignal("Velocity"):Connect(function(Parameter : Number)
			if Data[Parameter] then
				Multiply = Data[Parameter]
			end
			
			if Parameter == "14" then
				local Fade; Fade = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
					if (Multiply <= 0) then
						return Fade:Destroy()
					end

					Multiply = math.max(Multiply - (Delta * 60) * 1, 0)
				end)
			end
		end))
		
		local BloodEnabled = LocalPlayer:GetAttribute("Blood")
		local PlayerIsAttackerOrVictim = (Players:GetPlayerFromCharacter(Model) == LocalPlayer or Players:GetPlayerFromCharacter(VictimModel) == LocalPlayer)
		
		Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter : string)
			if Parameter == "6" then
				local Attachment
				
				
				if BloodEnabled then
					Attachment = Job:Task(script.Assets[Parameter]:Clone())
				else
					Attachment = Job:Task(script.NoBloodAssets[Parameter]:Clone())
				end
				
				Attachment.Parent = RootPart
				EffectUtility.ToggleForTime(Attachment, 0.7)
			else
				if BloodEnabled then
					EffectUtility.CloneAndEmit(script.Assets[tostring(Parameter)], RootPart)
				else
					EffectUtility.CloneAndEmit(script.NoBloodAssets[tostring(Parameter)], RootPart)
				end
			end
			
			-- Screen Effects
			local ScreenEffects = {
				["1"] = function()
					CameraShake(1.3, 10, 0.04, 0.5, Vector3.one * 0.8, Vector3.one * 0.4)
					Vignette(Color3.fromRGB(255, 0, 0), 0.85, 0.4)
				end,
				
				--["2"] = function()
					
				--end,
				
				["3"] = function()
					CameraShake(1.3, 10, 0.04, 0.5, Vector3.one * 0.8, Vector3.one * 0.4)
					Vignette(Color3.fromRGB(255, 0, 0), 0.85, 0.4)
				end,
				
				["4"] = function()
					CameraShake(0.7, 8, 0.05, 0.6, Vector3.one * 0.8, Vector3.one * 0.4)
				end,
				
				--["5"] = function()

				--end,
				
				["6"] = function()
					CameraShake(1.3, 10, 0.04, 0.5, Vector3.one * 0.8, Vector3.one * 0.4)
					Vignette(Color3.fromRGB(255, 0, 0), 0.85, 0.4)
					
					task.spawn(function()
						for i = 1, 7 do
							CameraShake(0.7, 15, 0.02, 0.3, Vector3.one * 0.8, Vector3.one * 0.4)
							Vignette(Color3.fromRGB(255, 0, 0), 0.9, 0.4)
							task.wait(0.1)
						end
					end)
					
					task.spawn(function()
						for i = 1, 35 do
							if (RootPart == nil and RootPart.Parent == nil) then
								break
							end

							RockHandler.Rocks("Side Dash", RootPart)

							task.spawn(RockHandler.Rockst, RootPart.Position, Vector3.yAxis * -5, {
								Size = {0.4, 0.7},
								Velocity = 25
							})

							Smoke(RootPart)

							task.wait(0.02)
						end
					end)
				end,
				
				["7"] = function()
					CameraShake(1.4, 10, 0.04, 0.5, Vector3.one * 0.8, Vector3.one * 0.4)
					Vignette(Color3.fromRGB(255, 0, 0), 0.85, 0.4)
					
					--Ended = true
				end,
			}
			
			if PlayerIsAttackerOrVictim then
				local Func = ScreenEffects[Parameter]
				
				if Func then
					Func()
				end
			end
		end))
	end,
	
	Finisher = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.UserFinisher)
		if (Retrieved == nil) then return end
		
		local IsMainPlayer = (LocalPlayer.Character == Model)

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		
		local PlayerIsAttackerOrVictim = (Players:GetPlayerFromCharacter(Model) == LocalPlayer or Players:GetPlayerFromCharacter(VictimModel) == LocalPlayer)
		
		if PlayerIsAttackerOrVictim then
			local Camera : Model = Job:Task(script.FinisherCamera:Clone())
			Camera:PivotTo(RootPart.CFrame)
			Camera.Parent = workspace.Visuals

			local CameraAnimation : AnimationTrack = Camera.AnimationController:LoadAnimation(ReplicatedStorage.Animations.Attacks.Invincible["Visceral Drive"].CameraFinisher)
			CameraAnimation:Play(0)

			Job:Task(CameraAnimation.Stopped:Connect(function()
				Camera:Destroy()
			end))

			Job:Task(RunCameraRig(RootPart, Camera, nil, {
				DontDoTransition = true
			}))
		end
		
		local function MarkerOnce(Name : string)
			local VFXTemplate = script.Finisher:FindFirstChild(Name)
			
			if VFXTemplate then
				local VFX : BasePart = VFXTemplate:Clone()
				VFX.CFrame = RootPart.CFrame
				VFX.Parent = workspace.Visuals
				
				EffectUtility.Emit(VFX)
			end	
		end
		
		for _, VFXObject in script.Finisher:GetChildren() do
			if VFXObject:IsA("BasePart") and VFXObject.Name == VFXObject.Name:lower() then
				Job:Task(Animation:GetMarkerReachedSignal(VFXObject.Name):Once(function()
					MarkerOnce(VFXObject.Name)
				end))
			end
		end
		
		Job:Task(Animation:GetMarkerReachedSignal("hit"):Connect(function()
			local HitVFX = script.Finisher.SecondHit:Clone()
			HitVFX.CFrame = RootPart.CFrame
			HitVFX.Parent = workspace.Visuals

			EffectUtility.Emit(HitVFX)
			
			Blood.BloodRaysWithoutPreset(VictimModel.Head.MouthAttachment, {
				Amount = Vector2.new(3, 5),
				Spread = Vector2.new(45, 45),
				Face = Enum.NormalId.Front,
				PoolSize = 0.75,
			})

			if PlayerIsAttackerOrVictim then
				Vignette(Color3.fromRGB(255, 0, 0), 0.9, 0.35)
				
				CameraShake(1, 10, 0.01, 0.35, Vector3.one * 0.8)
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("hit2"):Connect(function()
			local HitVFX = script.Finisher.ThirdHit:Clone()
			HitVFX.CFrame = RootPart.CFrame
			HitVFX.Parent = workspace.Visuals

			EffectUtility.Emit(HitVFX)
			
			Blood.BloodRaysWithoutPreset(VictimModel.Head.MouthAttachment, {
				Amount = Vector2.new(6, 10),
				Spread = Vector2.new(45, 45),
				Face = Enum.NormalId.Front,
				PoolSize = 1,
			})

			if PlayerIsAttackerOrVictim then
				Vignette(Color3.fromRGB(255, 0, 0), 0.65, 0.5)
				
				CameraShake(2, 10, 0.01, 0.35, Vector3.one * 0.8)
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("lasthit"):Once(function()
			local HitVFX = script.Finisher.ThirdHit:Clone()
			HitVFX.CFrame = RootPart.CFrame
			HitVFX.Parent = workspace.Visuals

			EffectUtility.Emit(HitVFX)
			
			Blood.BloodRaysWithoutPreset(VictimModel.Head.MouthAttachment, {
				Amount = Vector2.new(8, 11),
				Spread = Vector2.new(45, 45),
				Face = Enum.NormalId.Front,
				PoolSize = 1.15,
			})

			if PlayerIsAttackerOrVictim then
				Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.6)
				
				CameraShake(2.5, 10, 0.01, 0.5, Vector3.one * 0.8)
			end
		end))
	end,

	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		-- SFX
		--local Ended = false
		Job:Task(EffectUtility.AddSFX(script.Windup, Torso, 0.5))
		--local WindupSFX = script.Windup:Clone()

		--WindupSFX.Parent = Retrieved.Torso
		--WindupSFX:Play()

		--Job:Task(function()
		--	if Ended == false then
		--		WindupSFX:Destroy()
		--	end
		--end)

		--task.delay(4, WindupSFX.Destroy, WindupSFX)
		
		local Velocity = VelocityUtil.Create(RootPart, "Sea Salt Start")
		Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
		Velocity.Parent = RootPart
		
		local Max = 90
		local Multiply = 0
		
		Job:Task(Velocity)
		
		Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
			Velocity.Velocity = RootPart.CFrame.LookVector * Multiply
		end)
		
		Job:Task(Animation:GetMarkerReachedSignal("Velocity"):Connect(function(Parameter : Number)
			if Parameter == "1" then
				Multiply = 60
				
			elseif Parameter == "2" then
				Multiply = 30
				
			elseif Parameter == "3" then
				Multiply = 70
				
				local Fade; Fade = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
					if (Multiply <= 0) then
						return Fade:Destroy()
					end
					
					Multiply = math.max(Multiply - (Delta * 60) * 1.8, 0)
				end)
			end
		end))
	end,
}