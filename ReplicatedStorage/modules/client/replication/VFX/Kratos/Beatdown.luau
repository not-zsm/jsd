local replicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------------------

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

---------------------------------------------------------------------------------

local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )
local Smoke = require( replicatedStorage.modules.client.replication.Global.Smoke )
local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

local Yuki_FOV = require( replicatedStorage.modules.client.replication.Global.Yuki_FOV )

---------------------------------------------------------------------------------

local SwrermMeshVFX = require( replicatedStorage.modules.client.replication.Global.SwrermMeshVFX )
local RunCameraRig = require( replicatedStorage.modules.client.replication.Global.RunCameraRig )

---------------------------------------------------------------------------------

local function Emit(name : string, rootpart : BasePart, cf : CFrame)
	local VFX = script.VFX:FindFirstChild(name)

	if VFX then
		VFX = VFX:Clone()
		
		if name == "breath" then
			EffectUtility.Weld(VFX, rootpart.Parent.Head)
		else
			VFX.CFrame = rootpart.CFrame * (cf or (VFX.CFrame + Vector3.yAxis * -3))
		end
	
		VFX.Parent = workspace.Visuals
		EffectUtility.Arc.EmitAttachment(VFX)

		return VFX :: BasePart
	end
end

local function EmitMesh(Model : Model, RootPart : BasePart)
	Model:PivotTo(RootPart.CFrame)

	for _, Mesh in ipairs(Model:GetChildren()) do
		if Mesh:IsA("Model") then
			SwrermMeshVFX.Emit(Mesh)
		end
	end
end

---------------------------------------------------------------------------------

return {
	OnStart = function(AttackerModel : Model)
		local Trail = EffectUtility.WeldArmTrail(AttackerModel["Right Arm"])

		if Trail then
			task.delay(0.75, Trail.Destroy, Trail)
		end
	end,

	OnHit = function(AttackerModel : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(AttackerModel,
			replicatedStorage.Animations.Attacks.Kratos["Leviathan Rush"].BeatdownHit
		)
		
		if (Retrieved == nil) then return end

		local Animation, NewJob = Retrieved.Animation, Retrieved.Job
		local RootPart = Retrieved.RootPart

		local function InRangeForVFX()
			if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 100 then
				return true
			end
		end

		local function InRangeForScreenEffects()
			if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25 then
				return true
			end
		end

		local function BloodIfSettingOn()
			if (VictimModel and VictimModel.Parent ~= nil) then
				local Head = VictimModel:FindFirstChild("Head")

				if Head then
					Blood.BloodRays("SpitOut", Head.MouthAttachment)
				end
			end
		end

		local function Trail(Arm : string)
			local Trail = EffectUtility.WeldArmTrail(AttackerModel[Arm])
			task.delay(0.6, Trail.Destroy, Trail)
		end

		local function Hit(SwingArm : string)
			if InRangeForScreenEffects() then
				CameraShake(1.75, 23, 0.01, 0.1, Vector3.one * 0.8)
			end

			if InRangeForVFX() then
				Emit("hit", RootPart, CFrame.new(0, 0, -3))
			end
		end

		local Mesh = script.Mesh:Clone()
		NewJob:Task(Mesh)

		NewJob:Task(Animation:GetMarkerReachedSignal("hit"):Connect(Hit))

		NewJob:Task(Animation:GetMarkerReachedSignal("uppercut"):Connect(function()
			if InRangeForScreenEffects() then
				CameraShake(3, 25, 0.01, 0.12, Vector3.one * 0.5, Vector3.one)
			end

			if InRangeForVFX() then
				Emit("uppercut", RootPart, CFrame.new(0, 0, -3))
				BloodIfSettingOn()
			end
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("swing"):Connect(function(Parameter : string)
			local Arm = nil

			if Parameter == "right" then
				Arm = "Right Arm"

			elseif Parameter == "left" then
				Arm = "Left Arm"
			end

			Trail(Arm)
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("grab"):Connect(function()
			Trail("Right Arm")
			Trail("Left Arm")
		end))


		NewJob:Task(Animation:GetMarkerReachedSignal("throw"):Once(function(Parameter : string)
			if InRangeForScreenEffects() then
				CameraShake(3, 30, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.5)
			end

			if InRangeForVFX() then
				Emit("throw", RootPart, CFrame.new(0, 0, -3))
				EmitMesh(Mesh, RootPart)
			end
		end))

		Hit("right")
	end,

	OnFinisher = function(AttackerModel : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(AttackerModel,
			replicatedStorage.Animations.Attacks.Kratos["Leviathan Rush"].BeatdownFinisher
		)
		
		if (Retrieved == nil) then return end

		local Animation, NewJob = Retrieved.Animation, Retrieved.Job
		local RootPart = Retrieved.RootPart

		local function InRangeForVFX()
			if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 100 then
				return true
			end
		end

		local function InRangeForScreenEffects()
			if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 10 then
				return true
			end
		end

		local function BloodIfSettingOn()
			if (VictimModel and VictimModel.Parent ~= nil) and InRangeForVFX() then
				local Head = VictimModel:FindFirstChild("Head")

				if Head then
					Blood.BloodRays("SpitOut", Head.MouthAttachment)
				end
			end
		end
		
		local PlayerIsAttackerOrVictim = (Players:GetPlayerFromCharacter(AttackerModel) == LocalPlayer or Players:GetPlayerFromCharacter(VictimModel) == LocalPlayer)

		local SFX = script.FinisherSFX:Clone()
		SFX.Parent = PlayerIsAttackerOrVictim and workspace or RootPart
		SFX:Play()

		NewJob:Task(SFX)
		
		if PlayerIsAttackerOrVictim then
			NewJob:Task(Animation:GetMarkerReachedSignal("camera"):Connect(function()
				Yuki_FOV.Tween(85, {1})
				Yuki_FOV.Immune = true

				local Camera = replicatedStorage.modules.effect.assets["Camera's"].MJJBA:Clone()
				local DestroyCameraRunner = NewJob:Task(RunCameraRig(RootPart, Camera, CFrame.new(0, -2, -2)))
				Camera.Parent = workspace.Visuals

				local Animation = Camera.Humanoid.Animator:LoadAnimation(replicatedStorage.Animations.Attacks.Kratos["Leviathan Rush"].BeatdownFinisherCamera)
				Animation:Play(0)

				NewJob:Task(function()
					Yuki_FOV.Immune = false
					Yuki_FOV.Tween(70, {0.75})
				end)

				NewJob:Task(Animation.Stopped:Once(DestroyCameraRunner))
				NewJob:Task(Camera)
			end))
		end
		
		NewJob:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
			Emit(Parameter, RootPart)
			
			if InRangeForScreenEffects() then
				CameraShake(1.75, 23, 0.01, 0.1, Vector3.one * 0.8)
			end
			
			if (Parameter == "default" or Parameter == "morepower" or Parameter == "final") then
				if InRangeForScreenEffects() then
					Lighting.ExposureCompensation += 0.75
					
					TweenService:Create(Lighting, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
						{ExposureCompensation = 0}
					):Play()
				end
				
				BloodIfSettingOn()
			end
		end))

		if InRangeForScreenEffects() then
			CameraShake(1.75, 23, 0.01, 0.1, Vector3.one * 0.8)
		end

		if InRangeForVFX() then
			Emit("uppercut", RootPart, CFrame.new(0, 0, -3))
		end
	end
}
