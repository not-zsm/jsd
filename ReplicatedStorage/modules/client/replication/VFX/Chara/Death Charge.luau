local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = replicatedStorage.Animations.Attacks.Chara["Atonement"]

---------------------------------------------------------------------

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

local Yuki_FOV = require( replicatedStorage.modules.client.replication.Global.Yuki_FOV )

local Afterimage = require( replicatedStorage.modules.client.replication.Global.Afterimage )
local ATrainAfterimage = require( replicatedStorage.modules.client.replication.Global.ATrainAfterimage )

local RunCameraRig = require( replicatedStorage.modules.client.replication.Global.RunCameraRig )

---------------------------------------------------------------------

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local VelocityUtil = require( replicatedStorage.modules.shared.Game.Velocity.VelocityUtil )

---------------------------------------------------------------------

local WindupAssets = script.Windup
local HitAssets = script.Hit

return {
	--Start = function(Model : Model)
	--	local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
	--	if (Retrieved == nil) then return end

	--	local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
	--	local Animation, MainJob = Retrieved.Animation, Retrieved.Job
		
	--	local IsMainPlayer = (LocalPlayer.Character == Model)
		
	--	local Multiply = 0
	--	local Boosted = false

	--	local Velocity = VelocityUtil.Create(RootPart, "MISS THE RAGE")
	--	Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
	--	Velocity.Parent = RootPart

	--	Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
	--		Velocity.Velocity = RootPart.CFrame.LookVector * Multiply
	--	end)
		
	--	MainJob:Task(Velocity)
		
	--	if IsMainPlayer then
	--		local Camera = WindupAssets.Camera:Clone()
	--		Camera:PivotTo(RootPart.CFrame)
	--		Camera.Parent = workspace.Visuals

	--		local CameraAnimation = Camera.Humanoid.Animator:LoadAnimation(Animations.WindupCamera)
			
	--		MainJob:Task(CameraAnimation.Stopped:Once(function()
	--			Camera:Destroy()
	--		end))

	--		MainJob:Task(Camera)
			
	--		CameraAnimation:Play(0)
	--		MainJob:Task(RunCameraRig(RootPart, Camera))
	--		MainJob:Task(Yuki_FOV.AnimateWithMoonFile(replicatedStorage.FOVFiles["Death Charge"]))
	--	end

	--	MainJob:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
	--		local Effect = WindupAssets.VFX:FindFirstChild(Parameter)

	--		if Effect and EffectUtility.Distance_Far(Model, 200) then
	--			EffectUtility.Arc.CloneAndEmit(Effect, Model[Effect:GetAttribute("attached")])
	--		end
			
	--		if IsMainPlayer then
				
	--			if Parameter == "2" then
	--				if not Boosted then
	--					Boosted = true
	--					Multiply = 100
	--				else
	--					local Fade; Fade = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
	--						if (Multiply <= 0) then
	--							return Fade:Destroy()
	--						end
							
	--						Multiply = math.max(Multiply - (Delta * 60) * 1.1, 0)
	--					end)
	--				end
	--			end
			
	--		end
	--	end))
	--end,
	
	Hit = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Win)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, MainJob = Retrieved.Animation, Retrieved.Job

		local IsMainPlayer = (LocalPlayer.Character == Model or LocalPlayer.Character == VictimModel)
		local Knife = Model:FindFirstChild("Knife")
		
		local Multiply = 0
		local Boosted = false
		
		-- Setup
		local SFX = MainJob:Task(EffectUtility.AddSFX(script.SFX, if IsMainPlayer then workspace else Torso, 0.5))
		
		local VictimKnife : Model = MainJob:Task(HitAssets.VictimHeadKnife:Clone())
		VictimKnife.Parent = VictimModel
		VictimKnife.Weld.Part0 = VictimModel:FindFirstChild("Head")
		
		-- Impact Frames
		local Videos
		if IsMainPlayer then
			local Videos = LocalPlayer.PlayerGui:FindFirstChild("AtonementImpactFrames")
			if Videos then
				local Video = Videos.Frame.Part1
				Video.Visible = true
				Video:Play()

				MainJob:Task(Video.Ended:Once(function()
					Video.Visible = false
					Video:Destroy()
				end))
			end
		end
		
		if IsMainPlayer then
			local Camera = HitAssets.Camera:Clone()
			Camera:PivotTo(RootPart.CFrame)
			Camera.Parent = workspace.Visuals

			local CameraAnimation = Camera.Humanoid.Animator:LoadAnimation(Animations.WinEtc.Camera)

			MainJob:Task(CameraAnimation.Stopped:Once(function()
				Camera:Destroy()
			end))

			MainJob:Task(Camera)

			CameraAnimation:Play(0)
			MainJob:Task(RunCameraRig(RootPart, Camera))
			MainJob:Task(Yuki_FOV.AnimateWithMoonFile(replicatedStorage.FOVFiles["Death Charge Hit"]))
			
			-- cam keeps getting offsynced so
			MainJob:Task(RunService.PreAnimation:Connect(function()
				CameraAnimation.TimePosition = Animation.TimePosition
			end))
		end
		
		if IsMainPlayer then
			local GUI = HitAssets.FightUI:Clone()
			local Room = HitAssets.BlackBox:Clone()
			local Color = HitAssets.ColorCorrection:Clone()
			local Sky = script.Sky:Clone()
			
			MainJob:Task(GUI)
			MainJob:Task(Room)
			MainJob:Task(Color)
			MainJob:Task(Sky)
			
			MainJob:Task(Animation:GetMarkerReachedSignal("room"):Connect(function()
				Sky.Parent = Lighting
			
				local Highlight = Instance.new("Highlight")
				Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
				Highlight.FillColor = Color3.fromRGB(77, 77, 77)
				Highlight.FillTransparency = 25
				Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				Highlight.OutlineTransparency = 0
				Highlight.Parent = Model
				
				MainJob:Task(Highlight)
				
				Color.Enabled = true
				Color.Parent = Lighting
				
				EffectUtility.Weld(Room, RootPart, CFrame.new(0, 14.75, 75))
				Room.Parent = workspace.Visuals
				
				EffectUtility.Weld(GUI, RootPart, HitAssets.FightUI.CFrame)
				GUI.Parent = workspace.Visuals
				
				for _, Item in ipairs(GUI:GetDescendants()) do
					if Item:IsA("ParticleEmitter") then
						Item:Emit(1)
						Item.Enabled = true
					end
				end
			end))
			
			MainJob:Task(Animation:GetMarkerReachedSignal("break"):Connect(function()
				Sky:Destroy()
				GUI:Destroy()
				
				local Break = HitAssets.FightBreak:Clone()
				EffectUtility.Weld(Break, RootPart, HitAssets.FightBreak.CFrame)
				Break.Parent = workspace.Visuals
				EffectUtility.Emit(Break)
			end))
			
			MainJob:Task(Animation:GetMarkerReachedSignal("Kill"):Connect(function()
				Room:Destroy()
				--local NewRoom = MainJob:Task(HitAssets.BlackBox:Clone())
				--NewRoom.CFrame = RootPart.CFrame
			end))
		end
		
		local CustomVFX = {
			["e1"] = function()
				if Knife then
					EffectUtility.Arc.CloneAndEmit(HitAssets.CustomVFX["e1"], Knife.BladeInner)
				end;
			end,
			
			["11"] = function()
				local Effect = HitAssets.VFX["11"]
				EffectUtility.Arc.CloneAndEmit(Effect, Model[Effect:GetAttribute("attached")])
				EffectUtility.Arc.EmitAttachment(VictimKnife.BladeInner["1"])
				EffectUtility.Arc.ToggleAttachment(VictimKnife.BladeInner["1"], true, 1)
			end,
			
			["Drag"] = function()
				local Effect = MainJob:Task(HitAssets.CustomVFX.drag:Clone())
				Effect.Parent = VictimModel.Torso
				
				EffectUtility.Arc.EmitAttachment(Effect)
				EffectUtility.Arc.ToggleAttachment(Effect, true, 1)
			end,
			
			["67"] = function()
				local Effect = MainJob:Task(HitAssets.CustomVFX["6"]:Clone())
				Effect.Parent = RootPart
				
				EffectUtility.Arc.EmitAttachment(Effect)
				EffectUtility.Arc.ToggleAttachment(Effect, true, 0.533)
			end,
		}

		MainJob:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
			if EffectUtility.Distance_Far(Model, 100) then
				if CustomVFX[Parameter] then
					CustomVFX[Parameter]()
				else
					local Effect = HitAssets.VFX:FindFirstChild(Parameter)

					if Effect then
						local on = Effect:GetAttribute("on")

						if on and on == "Victim" then

							if (VictimModel and VictimModel.Parent ~= nil) then
								EffectUtility.Arc.CloneAndEmit(Effect, VictimModel[Effect:GetAttribute("attached")])
							end

						else
							EffectUtility.Arc.CloneAndEmit(Effect, Model[Effect:GetAttribute("attached")])
						end
					end
				end
			end
		end))
	end,
}