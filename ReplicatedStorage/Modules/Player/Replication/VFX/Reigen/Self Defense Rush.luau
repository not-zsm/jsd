local VFX = {}

---------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

---------------------------------------------------

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )

---------------------------------------------------

local Shockwave = require( ReplicatedStorage.Modules.Player.Replication.Global.Shockwave )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

---------------------------------------------------

local Speed = 7
local TimeTilNextArm = 0.01

local EndDist = -8
local ShockwaveWidth = 0.2

local RaycastSteps = 3

---------------------------------------------------

local Finishers = setmetatable({}, {__mode = "k"})

---------------------------------------------------

function VFX.Barrage(Model : Model)
	local Humanoid : Humanoid = Model:WaitForChild("Humanoid")
	local RootPart = Humanoid.RootPart
	
	local RightArm = Model:FindFirstChild("Right Arm")
	local LeftArm = Model:FindFirstChild("Left Arm")
	
	if (RightArm == nil or LeftArm == nil) then return end

	local Replication : Configuration = AttributeListener.GetReplicationFromSource(Model)
	
	if not Replication:GetAttribute("SelfDefenseRush") then 
		return 
	end
	
	RightArm.Transparency = 1
	LeftArm.Transparency = 1

	local Side = false

	local Arms = Instance.new("Folder")
	Arms.Name = "Barrage"
	Arms.Parent = workspace.Visuals

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {Model, Arms, workspace.Visuals, workspace.Terrain}

	local Shirt = Model:FindFirstChildOfClass("Shirt")

	local RightArmColor : Color3 = RightArm.Color
	local LeftArmColor  : Color3 = LeftArm.Color

	local PreviousHolder = nil
	local MainLoopTime = 0

	local NewJob = Job.new()

	local function EndBarrage()
		NewJob:Destroy()
		
		if (Model.Parent ~= nil and LeftArm and RightArm and RightArm.Parent ~= nil and LeftArm.Parent ~= nil) then
			RightArm.Transparency = 0
			LeftArm.Transparency = 0
		end

		task.delay(10, Arms.Destroy, Arms)
	end

	NewJob:Task(task.spawn(function()
		local Time = time()
		
		while (Model.Parent ~= nil and Replication:GetAttribute("SelfDefenseRush")) do
			local Raycast = workspace:Raycast(RootPart.Position, Vector3.yAxis * -10, Utility.VisualParams)

			if (Raycast ~= nil) then
				local Items = EffectUtility.EmitEffects(script.Dust, workspace.Terrain, RootPart.CFrame * CFrame.new(0, -Raycast.Distance, 0)) 

				for Item in Items do
					Item.Color = ColorSequence.new(Raycast.Instance.Color)
				end
			end
			
			task.wait(0.2)
		end
	end))

	NewJob:Task(RunService.PreSimulation:Connect(function(Delta)
		MainLoopTime += Delta 

		while MainLoopTime >= TimeTilNextArm do
			MainLoopTime -= TimeTilNextArm
			
			Side = not Side

			if (Players.LocalPlayer:DistanceFromCharacter(RootPart.Position) < 100) then
				local Holder = nil

				if (Shirt ~= nil and Side) then
					Holder = script.Holder:Clone()
					Shirt:Clone().Parent = Holder
					Holder.Parent = Arms
				end

				local Offset = Side and -1 or 1

				local Start = RootPart.CFrame * CFrame.new(Offset, 0.5, 0)
				local Middle = RootPart.CFrame * CFrame.new(Offset + Utility.Seed:NextNumber(-7.5, 7.5), 0.5 + Utility.Seed:NextNumber(-4.25, 3), EndDist/2)
				local End = RootPart.CFrame * CFrame.new(Offset + Utility.Seed:NextNumber(-2, 2), 0.5 + Utility.Seed:NextNumber(-3.5, 3), EndDist)

				local Angle = CFrame.Angles(math.rad(90), 0, Side and math.rad(10) or math.rad(-10))

				local Arm = ReplicatedStorage.Effects.Parts.Arm:Clone()
				Arm:PivotTo(Start * Angle)
				Arm.Color = (Side and RightArmColor or LeftArmColor)
				Arm.Name = (Side and "Right" or "Left") .. " Arm"
				Arm.Parent = PreviousHolder or Holder or Arms
			
				local Time = 0

				local LastPosition = Start.Position
				local RealEnd = End

				local Stop = EventService.new()

				local Connection : RBXScriptConnection; Connection = RunService.PostSimulation:Connect(function(Delta)
					Time += math.min(Delta * Speed, 1)

					if Time > 1 then
						return Stop:Fire()
					end

					local Position = Utility.QuadBezier(Time, Start.Position, Middle.Position, End.Position)
					local LookAtPosition = Utility.QuadBezier(Time + 0.001, Start.Position, Middle.Position, End.Position)

					local Raycast
					local ZeroSteps = (math.floor(Time / Speed) % RaycastSteps == 0)
					
					if ZeroSteps then
						Raycast = workspace:Raycast(LastPosition, (Position - LastPosition) * 1.01, Params)
					end

					if Raycast then
						Position = Raycast.Position
						RealEnd = Utility.VectorToRotation(Raycast.Normal) * CFrame.new(0, 0, -(ShockwaveWidth / 2)) + Position
					end

					Arm.CFrame = CFrame.lookAt(Position, LookAtPosition) * Angle

					if ZeroSteps then
						LastPosition = Position
					end

					if Raycast then
						return Stop:Fire()
					end
				end)

				Stop:Once(function()
					Stop:Destroy()
					
					Connection:Disconnect()
					Arm:Destroy(); 

					local Size = Utility.Seed:NextNumber(2, 3)
					Shockwave({CFrame = RealEnd}, nil, nil, Vector3.new(ShockwaveWidth, Size, Size))
				end)
				
				Arm.Transparency = 0
				EffectUtility.Toggle(Arm, true)
			
				PreviousHolder = Holder
			end
		end
	end))
	
	AttributeListener.new(Model, "SelfDefenseRush", EndBarrage)
end

function VFX.FinisherStart(Player : Player)
	if Finishers[Player] then
		return
	end
	
	local Character : Model = Player:IsA("Player") and Player.Character or Player
	if (Character == nil) then return end

	local Humanoid : Humanoid = Character:WaitForChild("Humanoid")
	if (Humanoid == nil) then return end

	local Animator : Animator = Humanoid:WaitForChild("Animator")
	if (Animator == nil) then return end

	local Folder = ReplicatedStorage.Animations.Attacks.Reigen["SELF DEFENSE RUSH!!!"]
	local ReigenAnimation = Utility.GetTrackById(Folder.Finisher.AnimationId, Animator)

	local NewJob = Job.new()
	
	local Colors = {
		Color3.fromRGB(162, 85, 255),
		Color3.fromRGB(105, 185, 255),
		Color3.fromRGB(90, 255, 115),
		Color3.fromRGB(146, 113, 255),
	}
	
	local ScreenVFX = coroutine.create(function()
		while true do
			Vignette(Colors[math.random(1, #Colors)], 0.3, 0.1)

			task.wait(0.075)
		end
	end)
	
	local function Shake(...)
		if LocalPlayer:DistanceFromCharacter(Humanoid.RootPart.Position) <= 15 then
			CameraShake(...)
		end
	end
	
	NewJob:Task(ReigenAnimation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
		local Attachment = script.Finisher.VFX[Parameter]:Clone()
		Attachment.Parent = Humanoid.RootPart
		EffectUtility.Arc.EmitAttachment(Attachment)
		
		if Parameter == "1" then
			Shake(1.75, 35, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.25)
			
		elseif Parameter == "1.5" then
			if LocalPlayer:DistanceFromCharacter(Humanoid.RootPart.Position) <= 15 then
				coroutine.resume(ScreenVFX)
				
				task.delay(5, function()
					if coroutine.status(ScreenVFX) == "suspended" then
						coroutine.close(ScreenVFX)
					end
				end)
			end
		
			Shake(1.3, 40, 0.01, 0.8, Vector3.one * 0.5, Vector3.one * 1)
			
		elseif Parameter == "2" then
			if coroutine.status(ScreenVFX) == "suspended" then
				coroutine.close(ScreenVFX)
			end
			
			Shake(2, 45, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.5)
			
		elseif Parameter == "4" then
			Shake(1.15, 40, 0.01, 0.6, Vector3.one * 0.8, Vector3.one * 0.25)
			
			if LocalPlayer:DistanceFromCharacter(Humanoid.RootPart.Position) <= 15 then
				coroutine.resume(ScreenVFX)
			end
			
		elseif Parameter == "5" then
			if coroutine.status(ScreenVFX) == "suspended" then
				coroutine.close(ScreenVFX)
			end
			
			Shake(2.75, 45, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.5)
			
			if LocalPlayer:DistanceFromCharacter(Humanoid.RootPart.Position) <= 15 then
				Vignette(Colors[math.random(1, #Colors)], 0.3, 0.1)
			end
		end
	end))

	local Rock = script.Finisher.Rock:Clone()
	EffectUtility.Weld(Rock, Humanoid.RootPart, CFrame.Angles(0, math.rad(90), -0))

	local Mob = ReplicatedStorage.Effects.Characters.Reigen.Mob:Clone()
	EffectUtility.Weld(Mob, Humanoid.RootPart, CFrame.new(0, 0, -2))
	
	for _, Limb in ipairs(Mob:GetChildren()) do
		if Limb:IsA("BasePart") and Limb.Name ~= "HumanoidRootPart" then
			for _, Item in ipairs(script.Finisher.Aura:GetChildren()) do
				Item:Clone().Parent = Limb
			end
		end
	end
	
	Rock.Parent = workspace.Visuals
	Mob.Parent = workspace.Visuals
	
	Rock.AnimationController.Animator:LoadAnimation(Folder.FinisherRock):Play(0)
	Mob.Humanoid.Animator:LoadAnimation(Folder.FinisherMob):Play(0)
	
	NewJob:Task(Mob)
	NewJob:Task(Rock)
	
	Finishers[Player] = NewJob
end

function VFX.FinisherEnd(Player : Player)
	if Finishers[Player] then
		Finishers[Player]:Destroy()
		Finishers[Player] = nil
	end
end

return VFX