local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

local Animations = ReplicatedStorage.Animations.Attacks.Kratos["Father Son Bonding"]

local Effects = script.Effects
local down_a_lil = Vector3.new(0, 3, 0)

local function VFX(want : BasePart, root : BasePart)
	local vfx = want:Clone()
	vfx.CFrame = root.CFrame * want.CFrame - down_a_lil
	vfx.Parent = workspace.Visuals
	EffectUtility.Emit(vfx)
	
	return vfx
end

return {
	Startup = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model,	Animations.Windup)
		if (Retrieved == nil) then return end

		local KratosAnimation = Retrieved.Animation
		local Job = Retrieved.Job

		local Humanoid = Retrieved.Humanoid
		local RootPart = Retrieved.RootPart
		
		Job:Task(EffectUtility.AddSFX(script.WindupSFX, Retrieved.Torso, 0.3))
		
		Job:Task(KratosAnimation:GetMarkerReachedSignal("dust"):Connect(function()
			VFX(Effects.step, RootPart)
		end))
		
		Job:Task(KratosAnimation:GetMarkerReachedSignal("swing"):Connect(function()
			VFX(Effects.swing, RootPart)
		end))
	end,
		
	Hit = function(Model : Model, VictimModel : Model, RandomFriend : {})
		local Retrieved = AnimationRetriever.new(Model,	Animations.Hit)
		if (Retrieved == nil) then return end

		local KratosAnimation = Retrieved.Animation
		local Job = Retrieved.Job

		local Torso = Retrieved.Torso
		local Humanoid = Retrieved.Humanoid
		local RootPart = Retrieved.RootPart

		local AnimationsToPosition = {}
		local PlayerIsAttackerOrVictim = (LocalPlayer.Character == Model or LocalPlayer.Character == VictimModel)

		if PlayerIsAttackerOrVictim then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			
			task.spawn(function()
				local IconModule = require(ReplicatedStorage.Modules.Icon)

				for _, Icon in IconModule.getIcons() do
					if (Icon.name ~= nil and Icon.name ~= "Settings") then
						Icon:setEnabled(false)
					end
				end
			end)
			
			Job:Task(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

				task.spawn(function()
					local IconModule = require(ReplicatedStorage.Modules.Icon)

					for _, Icon in IconModule.getIcons() do
						if (Icon.name ~= nil and Icon.name ~= "Settings") then
							Icon:setEnabled(true)
						end
					end
				end)
			end)
			
			local Camera : Model = Job:Task(script.Camera:Clone())
			EffectUtility.Weld(Camera, RootPart)
			Camera.Parent = workspace.Visuals

			local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(Animations.Camera)
			AnimationsToPosition[CameraAnimation] = true
			CameraAnimation:Play(0)
			
			Job:Task(Yuki_FOV.AnimateWithMoonFile(ReplicatedStorage.FOVFiles["Father Son Bonding"]))

			Job:Task(RunCameraRig(RootPart, Camera, nil, {
				DontSaveCameraPosition = true
			}))
			
			Job:Task(CameraAnimation.Stopped:Connect(function()
				CurrentCamera.CFrame = CFrame.lookAlong(CurrentCamera.CFrame.LookVector, RootPart.CFrame.LookVector)
				Camera:Destroy()
			end))
			
			Job:Task(KratosAnimation:GetMarkerReachedSignal("downhit"):Connect(function(param : string)
				EffectUtility.Emit(Camera.cameffect, true)
			end))
			
			Job:Task(KratosAnimation:GetMarkerReachedSignal("rush"):Connect(function(param : string)
				if param == "true" then
					EffectUtility.Toggle(Camera.rush, true)
					
				elseif param == "false" then
					EffectUtility.Toggle(Camera.rush, false)
				end
			end))
		end
		
		Job:Task(KratosAnimation:GetMarkerReachedSignal("end"):Connect(function()
			Model:SetAttribute("HeadMovementDisabled", true)
			KratosAnimation:Stop(0)
			
			do
				local EndOffset = -33.402
				local Raycast = workspace:Raycast(RootPart.Position, RootPart.CFrame.LookVector * -EndOffset, Utility.VisualParams)

				if (Raycast ~= nil) then
					RootPart.CFrame *= CFrame.new(0.993, 0, -Raycast.Distance)
				else
					RootPart.CFrame *= CFrame.new(0.993, 0, EndOffset)
				end
			end
			
			task.wait(3 / 60)
			
			Model:SetAttribute("HeadMovementDisabled", nil)
		end))
		
		Job:Task(KratosAnimation:GetMarkerReachedSignal("hit"):Connect(function(param : string)
			local hitVFX = VFX(Effects.Hits[param], RootPart)
			
			if LocalPlayer:GetAttribute("Blood") then
				local blood_vfx = Effects.ketchup:Clone()
				blood_vfx.CFrame = hitVFX.CFrame
				blood_vfx.Parent = workspace.Visuals
				EffectUtility.Emit(blood_vfx)
			end
		end))
			
		Job:Task(KratosAnimation:GetMarkerReachedSignal("downhit"):Connect(function(param : string)
			if param == "left" then
				VFX(Effects.DownHits["left"], RootPart)
				
			elseif param == "right" then
				VFX(Effects.DownHits["right"], RootPart)
			end
		end))
		
		Job:Task(KratosAnimation:GetMarkerReachedSignal("final"):Connect(function()
			VFX(Effects.final, RootPart)
		end))
			
		Job:Task(KratosAnimation:GetMarkerReachedSignal("jump"):Connect(function()
			VFX(Effects.jump, RootPart)
		end))
		
		Job:Task(KratosAnimation:GetMarkerReachedSignal("slam"):Connect(function()
			VFX(Effects.slam, RootPart)
		end))
		
		local Atreus = script.Atreus:Clone()
		EffectUtility.Weld(Atreus, RootPart)
		Atreus.Parent = workspace.Visuals

		Job:Task(Atreus)
		
		if RandomFriend then
			task.spawn(function()
				local Humanoid = Atreus:WaitForChild("Humanoid")
				local Description = Players:GetHumanoidDescriptionFromUserId(tonumber(RandomFriend.Id))

				if Description then
					Humanoid:ApplyDescription(Description)
				end
			end)
		end;
		
		local AtreusAnimation = Atreus.Humanoid.Animator:LoadAnimation(Animations.Atreus)
		AnimationsToPosition[AtreusAnimation] = true
		
		Job:Task(RunService.PreAnimation:Connect(function()
			for AnimationToPosition in AnimationsToPosition do
				if AnimationToPosition.IsPlaying then
					AnimationToPosition.TimePosition = KratosAnimation.TimePosition
				end
			end
		end))
		
		Job:Task(AtreusAnimation.Stopped:Once(function()
			Atreus:Destroy()
		end))
		
		local SFX = script.SFX:Clone()
		SFX.Parent = PlayerIsAttackerOrVictim and workspace or Torso
		Job:Task(SFX)
		
		AtreusAnimation:Play(0)
		SFX:Play()
		
		task.delay(2 / 60, VFX, Effects.starthit, RootPart)
	end,
}