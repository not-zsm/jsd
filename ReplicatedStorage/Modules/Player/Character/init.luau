local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

----------------------------------------------------------------------------------

local Modules = ReplicatedStorage.Modules
local Remotes = ReplicatedStorage.Remotes

local Shared = Modules.Shared
local SharedUtilities = Shared.Utilities

local EventService = require(SharedUtilities.EventService)
local Job = require( SharedUtilities.Job )
local Utility = require( SharedUtilities.Utility )
local NumberStack = require( SharedUtilities.NumberStack )

local MovementDegree = math.sqrt(2) / 2

----------------------------------------------------------------------------------

local LuaCharacter = {}
LuaCharacter.__index = LuaCharacter

local CurrentCamera = workspace.CurrentCamera

----------------------------------------------------------------------------------

function LuaCharacter:_Init()
	self.Combat = require( script.Combat ).new(self)
	self.Combat:_Init()
	
	self.Movement = require( script.Movement ).new(self)
	self.Movement:_Init()
	
	if self.HumanoidAlive then
		self.Movement:OnHumanoidLoaded()
	end
end

----------------------------------------------------------------------------------

function LuaCharacter:ConditionsToShiftlockRoot()
	return 
		(self.InShiftlock or self.CFRootPartToCameraLookVector) and 
		not self.LuaPlayer.Player:GetAttribute("InCameraAnimation") and
		not self.Humanoid:FindFirstChild("StopAutoRotate") and 
		not self.Humanoid:GetAttribute("LockShiftlockCFrame") and 
		not self.RootPart:FindFirstChildOfClass("BodyGyro") and
		not self:IsFlyingOrSitting()
end

--function LuaCharacter:ConditionsToBlockShiftlock()
--	return self.Model:GetAttribute("BlockShiftLock")
--end

function LuaCharacter:IsFlyingOrSitting()
	return self.Model:HasTag("Flying") or self.Humanoid.Sit
end

function LuaCharacter.new(LuaPlayer)
	local self = setmetatable({}, LuaCharacter)
	self.LuaPlayer = LuaPlayer

	self.HumanoidAlive = false
	self.HumanoidExists = false

	self.OnHumanoidAvailabilityChanged = EventService.new()
	self.OnHumanoidDied = EventService.new()

	self.HumanoidJob = Job.new()
	self.DeathJob = Job.new()

	self.InShiftlock = false
	
	self.HeadMovementEnabled = true
	self.HeadMovementSetting = true
	
	self.AccessorySetting = true

	self.CFRootPartToCameraLookVector = false

	self.LastHeadPosition = Vector3.zero

	local ShiftlockOffset = {
		[true] = CFrame.new(2, 0, 0),
		[false] = CFrame.identity
	}
	
	self.DefaultIcon = UserInputService.MouseIcon

	task.spawn(function()
		local ToggleHeadMovement : RemoteEvent = self.LuaPlayer.Remotes:WaitForChild("ToggleHeadMovement")

		ToggleHeadMovement.OnClientEvent:Connect(function(Value : boolean)
			--self.LastHeadPosition = Vector3.zero
			
			if (Value ~= nil) then
				self.HeadMovementEnabled = Value
			else
				self.HeadMovementEnabled = not self.HeadMovementEnabled
			end
			
			--self.LastHeadPosition = Vector3.zero
		end)
	end)
	
	task.spawn(function()
		local SetHeadMovementAttach : RemoteEvent = self.LuaPlayer.Remotes:WaitForChild("SetHeadMovementAttach")

		SetHeadMovementAttach.OnClientEvent:Connect(function(NewAttach : BasePart)
			self.CurrentHeadMovementAttach = NewAttach
		end)
	end)
	
	local SmoothSpeed = 5 -- Higher = Snappier
	
	RunService:BindToRenderStep("Shiftlock", Utility.ShiftlockRenderPriority, function(Delta : number)
		if not self.HumanoidExists then return end
		
		if self:ConditionsToShiftlockRoot() then
			local LookAlong = CurrentCamera.CFrame.LookVector * Vector3.new(1, 0, 1);
			
			if LookAlong == LookAlong and LookAlong ~= Vector3.zero then -- nan check
				local Coordinate = CFrame.lookAlong(self.RootPart.CFrame.Position, LookAlong);
				
				if Coordinate.Position == Coordinate.Position then
					self.RootPart.CFrame = Coordinate;
				end
			end;
		end
		
		local Zoom : number = self.ZoomController.GetZoomRadius()

		local Attach : BasePart = self.CurrentHeadMovementAttach or self.Head
		local RootCF : CFrame = self.RootPart.CFrame
		local ValueOffset = Vector3.zero

		if (self.HeadMovementEnabled and self.HeadMovementSetting and not self.HeadMovementDisabledAttribute) and Zoom > 1 then
			local HeadDifference = CFrame.new(0, (self.RootPart.Size.Y + Attach.Size.Y) / 2, 0)
			local HeadOffset = (RootCF * HeadDifference):PointToObjectSpace(Attach.Position)
			
			--local Alpha = math.clamp(0.1 * (Delta * 60), 0, 1)
			--ValueOffset = self.LastHeadPosition:Lerp(HeadOffset, Alpha)
			
			ValueOffset = self.LastHeadPosition:Lerp(HeadOffset, 
				(1 - math.exp(-SmoothSpeed * Delta))
			)
		end

		if (self.Combat and self.Combat.LockOn and self.Combat.LockOn.lock_on) or Zoom < 1 then
			CurrentCamera.CFrame = 
				(CurrentCamera.CFrame + RootCF.Rotation * ValueOffset)
		else
			CurrentCamera.CFrame = 
				(CurrentCamera.CFrame + RootCF.Rotation * ValueOffset) * ShiftlockOffset[self.InShiftlock]
		end
		
		if self.InShiftlock then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			
		elseif not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
		
		--if self.InShiftlock then
			
		--	if not self.CameraLockedCenter then
		--		self.CameraLockedCenter = true
		--		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		--	end

		--elseif not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			
		--	if self.CameraLockedCenter then
		--		self.CameraLockedCenter = false
		--		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		--	end
			
		--end

		self.LastHeadPosition = ValueOffset
	end)
	
	local function CharacterAdded(Model : Model)
		self:RegisterModel(Model)
	end

	if (self.LuaPlayer.Player.Character ~= nil) then
		task.spawn(CharacterAdded, self.LuaPlayer.Player.Character)
	end

	self.LuaPlayer.Player.CharacterAdded:Connect(CharacterAdded)

	self.ZoomController = require(self.LuaPlayer.RobloxPlayerModuleObject:WaitForChild("CameraModule"):WaitForChild("ZoomController"))
	self.Control = require(self.LuaPlayer.RobloxPlayerModuleObject:WaitForChild("ControlModule"))

	----------------------------------------
	return self
end

function LuaCharacter:FixCenter()
	self.RootPart.CustomPhysicalProperties = PhysicalProperties.new(
		self.MassProperties.Density - 0.01, 
		self.MassProperties.Friction, 
		self.MassProperties.Elasticity, 
		self.MassProperties.FrictionWeight,
		self.MassProperties.ElasticityWeight
	)
	
	task.wait()
	
	self.RootPart.CustomPhysicalProperties = self.MassProperties
end

function LuaCharacter:RegisterModel(Model : Model)
	self.HumanoidJob:Clean()

	if self.Model then
		self.Model:Destroy()
	end
	
	self.Model = Model

	if (self.Model.Parent ~= workspace.Models) then
		warn("model wasn't in the models folder as this was checked, waiting now")
		self.Model.AncestryChanged:Wait()
	end
	
	self.Humanoid = self.Model:WaitForChild("Humanoid") :: Humanoid?
	self.Torso = self.Model:WaitForChild("Torso") :: BasePart?
	self.Head = self.Model:WaitForChild("Head") :: BasePart?
	self.RightArm = self.Model:WaitForChild("Right Arm") :: BasePart?
	self.RightLeg = self.Model:WaitForChild("Right Leg") :: BasePart?
	self.LeftArm = self.Model:WaitForChild("Left Arm") :: BasePart?
	self.LeftLeg = self.Model:WaitForChild("Left Leg") :: BasePart?
	self.Animator = self.Humanoid:WaitForChild("Animator") :: Animator?
	self.RootPart = self.Humanoid.RootPart or self.Model:WaitForChild("HumanoidRootPart")
	self.RootJoint = self.RootPart:WaitForChild("RootJoint") :: Motor6D
	self.RootAttachment = self.RootPart:WaitForChild("RootAttachment") :: Attachment
	self.Mouth = self.Head:WaitForChild("MouthAttachment") :: Attachment
	self.MassProperties = self.RootPart.CurrentPhysicalProperties

	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

	self.HumanoidJob:Task(UserInputService.InputBegan:Connect(function(Input, Typing)
		if Typing then return end

		if Input.KeyCode == Enum.KeyCode.LeftShift or Input.KeyCode == Enum.KeyCode.ButtonL3 then
			self:ToggleShiftlock()
		end
	end))
	
	self.Model:GetAttributeChangedSignal("HeadMovementDisabled"):Connect(function()
		self.LastHeadPosition = Vector3.zero
		self.HeadMovementDisabledAttribute = self.Model:GetAttribute("HeadMovementDisabled")
		self.LastHeadPosition = Vector3.zero
	end)
	
	self.Model:GetAttributeChangedSignal("BlockShiftlock"):Connect(function()
		self:BlockShiftlock(self.Model:GetAttribute("BlockShiftlock"))
	end)

	local function ChildChanged()
		self:UpdateAutoRotate()
	end

	local function DescendantChanged(...)
		self:FixCenter()
	end

	self.Humanoid.ChildAdded:Connect(ChildChanged)
	self.Humanoid.ChildRemoved:Connect(ChildChanged)
	
	self.Model.DescendantAdded:Connect(DescendantChanged)
	self.Model.DescendantRemoving:Connect(DescendantChanged)

	task.defer(function()
		self:SetHumanoidAvailability(true, true)

		local Connection : RBXScriptConnection; Connection = self.DeathJob:Task(self.RootPart.AncestryChanged:Connect(function(_, Parent)
			if (Parent == nil) then
				Connection:Disconnect()

				self:SetHumanoidAvailability(false, false)
				self.DeathJob:Clean()
			end
		end))
		
		self.HumanoidJob:Task(self.LuaPlayer.Remotes.OnHumanoidDied.OnClientEvent:Connect(function()
			if self.HumanoidAlive then
				self:SetHumanoidAvailability(false, true)
				self.OnHumanoidDied:Fire()
				self.DeathJob:Clean()
			end
		end))
		
		self.HumanoidJob:Task(self.LuaPlayer.Remotes.OnHumanoidRevived.OnClientEvent:Connect(function()
			if not self.HumanoidAlive then
				self.HumanoidAlive = true
				self.HumanoidExists = true
			end
		end))
		
		if self.Movement then
			self.Movement:OnHumanoidLoaded()
		end
	end)
end

function LuaCharacter:UpdateAutoRotate()
	if self.InShiftlock then
		self.Humanoid.AutoRotate = false
	else
		self.Humanoid.AutoRotate = (self.Humanoid:FindFirstChild("StopAutoRotate") == nil)
	end
end

function LuaCharacter:BlockShiftlock(Block : boolean)
	if self.InShiftlock and Block then
		self:ToggleShiftlock(true)
	end
	
	self.ShiftlockBlocked = Block
end

function LuaCharacter:ToggleShiftlock(Bypass)
	if self.ShiftlockBlocked then 
		return 
	end
	
	self.InShiftlock = not self.InShiftlock
	UserInputService.MouseIcon = self.InShiftlock and "rbxasset://textures/Cursors/Gamepad/Pointer.png" or self.DefaultIcon
	self:UpdateAutoRotate()
end

function LuaCharacter:SetHumanoidAvailability(Alive : boolean, Exists : boolean)
	local Available = (Alive and Exists)

	self.HumanoidAlive = Available 
	self.HumanoidExists = Exists 
	
	self.OnHumanoidAvailabilityChanged:Fire(Available, Exists)
end

function LuaCharacter:CheckIfMovingForward()
	if not self.HumanoidAlive then return false end

	local Direction = self:GetMoveVector()

	local CFr : CFrame = self.RootPart.CFrame
	local DirectionInWorldSpace : Vector3 = CFr:VectorToWorldSpace(Direction)

	local Forward = (CFr.LookVector:Dot(DirectionInWorldSpace) > 0.1)

	return Forward
end

function LuaCharacter:GetMoveVector()
	return self.Control:GetMoveVector()
end

function LuaCharacter:GetMoveDirection()
	local Vector : Vector3 = self:GetMoveVector()

	if Vector.Z < -MovementDegree then
		return "Front"

	elseif Vector.Z > MovementDegree then
		return "Back"

	elseif Vector.X > MovementDegree then
		return "Right"

	elseif Vector.X < -MovementDegree then
		return "Left"
	end

	return "Front"
end

----------------------------------------------------------------------------------

table.freeze(LuaCharacter)

return LuaCharacter