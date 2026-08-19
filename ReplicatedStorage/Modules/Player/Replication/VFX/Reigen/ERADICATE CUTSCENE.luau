local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

----------------------------------------------------------------------------------------------------------------------

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local MeterImpactFrames = LocalPlayer.PlayerGui.ImpactFrames.ReigenEradicate.Meter
local ExplosionImpactFrames = LocalPlayer.PlayerGui.ImpactFrames.ReigenEradicate.Explosion

----------------------------------------------------------------------------------------------------------------------

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local SwrermMeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.SwrermMeshVFX )

----------------------------------------------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local CharacterTransparency = require( ReplicatedStorage.Modules.Player.Replication.Global.CharacterTransparency )

local Part_Time_Employee = require( ReplicatedStorage.Modules.Player.Replication.VFX.Reigen["Part Time Employee"] )

local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )

----------------------------------------------------------------------------------------------------------------------

local Jobs = setmetatable({}, {__mode = "k"}) -- removes automatically if index is nil

----------------------------------------------------------------------------------------------------------------------

local function YieldUntilAnimationReady(Animation : AnimationTrack)
	if Animation.Length <= 0 then
		repeat task.wait() until Animation.Length > 0
	end
end

local Animations = ReplicatedStorage.Animations.Attacks.Reigen.ERADICATE

local Location = CFrame.new(0, 0, 20000)
local Map = workspace.Visuals["ERADICATE Map"]

function VFX.Crush(MainModel : Model, VictimModel : Model, Value : boolean) -- shawty gon let me crush
	if VictimModel then
		CharacterTransparency(VictimModel, Value and 1 or 0)
	end
	
	if Value and (MainModel and LocalPlayer == Players:GetPlayerFromCharacter(MainModel)) or (VictimModel and LocalPlayer == Players:GetPlayerFromCharacter(VictimModel)) then
		task.spawn(EffectUtility.EmitImpactFrames, MeterImpactFrames, 30)
		SoundService:PlayLocalSound(script["0-100"])
	end
end

function VFX.StartOthers(MainModel : Model, VictimModel : Model, Value : boolean)
	if MainModel then
		CharacterTransparency(MainModel, Value and 1 or 0)
	end
	
	if VictimModel then
		CharacterTransparency(VictimModel, Value and 1 or 0)
	end
end

function VFX.LoadImpactFrames(Root : BasePart)
	if Root and LocalPlayer:DistanceFromCharacter(Root.Position) <= 40 then
		EffectUtility.ToggleImpactFrames(MeterImpactFrames, true)
		
		task.delay(10, function()
			EffectUtility.ToggleImpactFrames(MeterImpactFrames, false)
		end)
	end
end

function VFX.Boom(MainPlayer : Player)
	local cf : CFrame = MainPlayer.Character.PrimaryPart.CFrame * CFrame.new(0, 0, -75)
	
	local boom_effects = script.Assets.vfx.boom:Clone()
	boom_effects.CFrame = cf
	boom_effects.Parent = workspace.Visuals
	EffectUtility.Emit(boom_effects)

	if LocalPlayer:DistanceFromCharacter(MainPlayer.Character.PrimaryPart.Position) <= 200 then
		CameraShake(10, 30, 0.01, 1, Vector3.one * 0.8, Vector3.one * 0.4)
		
		local Position = cf.Position
		local Direction = Vector3.yAxis * -50
		
		task.defer(RockHandler.Crater, Position, Direction, {
			Amount = 40,
			Distance = {Min = 15, Max = 40},
			LookAt = {Min = 5, Max = 10},
			Timing = {
				In = {Min = 0.075, Max = 0.2},
				Idle = {Min = 6.5, Max = 7.5},
				Out = {Min = 2.5, Max = 3},
			},
			Exposure = {Min = 0.5, Max = 2},
			BaseZ = 1.25,
			SizeMultiplier = 3,
		})

		task.defer(RockHandler.Crater, Position, Direction, {
			Amount = 65,
			Distance = {Min = 45, Max = 65},
			LookAt = {Min = -5, Max = -10},
			Timing = {
				In = {Min = 0.05, Max = 0.35},
				Idle = {Min = 6.5, Max = 7.5},
				Out = {Min = 2.5, Max = 3},
			},
			Exposure = {Min = 2, Max = 3},
			BaseZ = 0.75,
			SizeMultiplier = 5,
		})

		task.defer(RockHandler.Rockst, Position, Direction, {
			Size = {2.25, 4.5},
			Count = 80,
			Velocity = 125,
			SpawnVariance = 35;
		})
	end
end

function VFX.Start(MainPlayer : (Player | Model), VictimPlayer : (Player | Model)) -- this is fired to both main player and victim player clients (reminder)
	VFX.Remove(MainPlayer)

	local NewJob = Job.new()

	local AttackerRealCharacter : Model = MainPlayer:IsA("Player") and MainPlayer.Character or MainPlayer
	local VictimRealCharacter : Model = VictimPlayer:IsA("Player") and VictimPlayer.Character or VictimPlayer

	local boom_effects = NewJob:Task(script.Assets.vfx.boom:Clone())
	boom_effects.CFrame = Location * boom_effects.CFrame
	boom_effects.Parent = workspace.Visuals

	local drag_effects = NewJob:Task(script.Assets.vfx.drag:Clone())
	drag_effects.Parent = workspace.Visuals
	
	local Camera = NewJob:Task(ReplicatedStorage.Effects["Camera's"].MJJBA:Clone())
	Camera:PivotTo(Location * CFrame.Angles(0, -math.pi, 0))

	local City = NewJob:Task(script.Assets.City:Clone())
	City:PivotTo(Location)

	local Cracks = NewJob:Task(script.Assets.Cracks:Clone())
	Cracks:PivotTo(Location)

	local Rocks = NewJob:Task(script.Assets.Rocks:Clone())
	Rocks:PivotTo(Location)
	
	Camera.Parent = workspace.Visuals
	City.Parent = workspace.Visuals
	Cracks.Parent = workspace.Visuals
	Rocks.Parent = workspace.Visuals
	
	local CameraAnimation = Camera.Humanoid.Animator:LoadAnimation(Animations.Camera)
	local CityAnimation = City.Humanoid.Animator:LoadAnimation(Animations.City)
	local CracksAnimation = Cracks.Humanoid.Animator:LoadAnimation(Animations.Crack)
	local RocksAnimation = Rocks.Humanoid.Animator:LoadAnimation(Animations.Rocks)

	local VictimAnimation = nil
	local AttackerAnimation = nil
	
	local doing_frames = false

	if VictimRealCharacter then
		local Success, Result = pcall(function()
			local VictimCutsceneCharacter = NewJob:Task(AenoirUtil.CloneCharacter(VictimRealCharacter))
			local VictimCutsceneHumanoid : Humanoid? = VictimCutsceneCharacter:WaitForChild("Humanoid")
			local VictimCutsceneAnimator : Animator? = VictimCutsceneHumanoid:WaitForChild("Animator")
			local VictimCutsceneRootPart = VictimCutsceneHumanoid.RootPart

			VictimCutsceneRootPart.Anchored = true
			VictimCutsceneCharacter:PivotTo(Location + Vector3.yAxis * 3)
			VictimCutsceneCharacter.Parent = workspace.Visuals

			EffectUtility.Weld(drag_effects, VictimCutsceneCharacter.Head)
			VictimAnimation = VictimCutsceneAnimator:LoadAnimation(Animations.Victim)
			
			NewJob:Task(VictimAnimation.Stopped:Once(function()
				VFX.Remove(MainPlayer)
			end))
		end)
		
		if not Success then
			warn(Result)
		end
	end
	
	if AttackerRealCharacter then
		local Success, Result = pcall(function()
			local AttackerCutsceneCharacter = NewJob:Task(AenoirUtil.CloneCharacter(AttackerRealCharacter))
			local AttackerCutsceneHumanoid : Humanoid? = AttackerCutsceneCharacter:WaitForChild("Humanoid")
			local AttackerCutsceneAnimator : Animator? = AttackerCutsceneHumanoid:WaitForChild("Animator")
			local AttackerCutsceneRootPart = AttackerCutsceneHumanoid.RootPart

			AttackerCutsceneRootPart.Anchored = true
			AttackerCutsceneCharacter:PivotTo(Location + Vector3.yAxis * 3)
			
			Part_Time_Employee.MobAura(AttackerCutsceneCharacter)
			AttackerCutsceneCharacter.Parent = workspace.Visuals
			
			AttackerAnimation = AttackerCutsceneAnimator:LoadAnimation(Animations.Attacker)
			
			local left_arm_effects = NewJob:Task(script.Assets.vfx.leftarm:Clone())
			EffectUtility.Weld(left_arm_effects, AttackerCutsceneCharacter["Left Arm"])
			left_arm_effects.Parent = workspace.Visuals

			NewJob:Task(AttackerAnimation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
				local Part : typeof(script.Assets.vfx["1"]) = script.Assets.vfx[Parameter]:Clone()
				Part.CFrame = Location * Part.CFrame
				Part.Parent = workspace.Visuals
				EffectUtility.Emit(Part)
				
				if Parameter == "4" then
					EffectUtility.Toggle(City, true)
				end
			end))

			NewJob:Task(AttackerAnimation:GetMarkerReachedSignal("leftarm_E1"):Connect(function(Parameter : string)
				EffectUtility.Toggle(left_arm_effects.E1, (Parameter == "true"))
			end))
	
			NewJob:Task(AttackerAnimation:GetMarkerReachedSignal("leftarm_E2"):Connect(function(Parameter : string)
				EffectUtility.Toggle(left_arm_effects.E2, (Parameter == "true"))
				
				if (Parameter == "true") then
					EffectUtility.Toggle(left_arm_effects.E1, false)
					EffectUtility.Emit(left_arm_effects.Emit, true)
				end
			end))

			NewJob:Task(AttackerAnimation:GetMarkerReachedSignal("drag"):Connect(function(Parameter : string)
				EffectUtility.Toggle(drag_effects.Attachment, (Parameter == "true"))
			end))
		
			NewJob:Task(AttackerAnimation:GetMarkerReachedSignal("boom"):Connect(function(Parameter : string)
				EffectUtility.Toggle(boom_effects, (Parameter == "true"))
				
				if Parameter == "true" then
					doing_frames = true
					
					EffectUtility.EmitImpactFrames(ExplosionImpactFrames, 42)
					EffectUtility.ToggleImpactFrames(ExplosionImpactFrames, false)
				end
			end))
			
			NewJob:Task(AttackerAnimation.Stopped:Once(function()
				VFX.Remove(MainPlayer)
			end))
		end)
		
		if not Success then
			warn(Result)
		end
	end
	
	YieldUntilAnimationReady(CameraAnimation)
	YieldUntilAnimationReady(CityAnimation)
	YieldUntilAnimationReady(CracksAnimation)
	YieldUntilAnimationReady(RocksAnimation)

	if VictimAnimation then
		YieldUntilAnimationReady(VictimAnimation)
	end

	if AttackerAnimation then
		YieldUntilAnimationReady(AttackerAnimation)
		AttackerAnimation:Play(0)
	end
	
	CameraAnimation:Play(0)
	CityAnimation:Play(0)
	CracksAnimation:Play(0)
	RocksAnimation:Play(0)
	VictimAnimation:Play(0)
	
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

	NewJob:Task(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	end)

	local Effects = EffectUtility.EmitEffectsOnBasePart(script.SFX, workspace)

	for _, Item in Effects do
		NewJob:Task(Item)
	end

	NewJob:Task(Yuki_FOV.AnimateWithMoonFile(ReplicatedStorage.FOVFiles.ERADICATE))

	NewJob:Task(RunCameraRig(nil, Camera, CFrame.Angles(0, -math.pi, 0), {
		DontDoTransition = true,
		DontSupportCutsceneSetting = true
	}))

	EffectUtility.ToggleImpactFrames(ExplosionImpactFrames, true)

	NewJob:Task(function()
		if not doing_frames then
			EffectUtility.ToggleImpactFrames(ExplosionImpactFrames, false)
		end
	end)

	NewJob:Task(RunService.PreAnimation:Connect(function()
		if AttackerAnimation then
			local ToTimePosition = AttackerAnimation.TimePosition

			CameraAnimation.TimePosition = ToTimePosition
			CityAnimation.TimePosition = ToTimePosition
			CracksAnimation.TimePosition = ToTimePosition
			RocksAnimation.TimePosition = ToTimePosition

			if VictimAnimation then
				VictimAnimation.TimePosition = ToTimePosition
			end
		end
	end))

	Jobs[MainPlayer] = NewJob
end

function VFX.Remove(MainPlayer : Player)
	if (MainPlayer and Jobs[MainPlayer] ~= nil) then
		Jobs[MainPlayer]:Destroy()
		Jobs[MainPlayer] = nil
	end
end

return VFX
