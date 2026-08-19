local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")


----------------------------------------------------------------------------------

local Modules = ReplicatedStorage.Modules
local Remotes = ReplicatedStorage.Remotes

local CombatRemotes = Remotes.Combat

local Shared = Modules.Shared
local SharedUtilities = Shared.Utilities

local Animations = ReplicatedStorage.Animations

----------------------------------------------------------------------------------

local WallRunHandler = {}
WallRunHandler.__index = WallRunHandler	

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

----------------------------------------------------------------------------------

function WallRunHandler:OnHumanoidLoaded()
	for _, Animation : Animation in self.Animations do
		Animation:Destroy()
	end

	table.clear(self.Animations)

	local Animator : Animator = self.LuaCharacter.Animator

	for _, Animation : Animation in ipairs(Animations.ClientActions[script.Name]:GetChildren()) do
		if Animation:IsA("Animation") then
			self.Animations[Animation.Name] = Animator:LoadAnimation(Animation)
			self.Animations[Animation.Name].Priority = Enum.AnimationPriority.Movement
		end
	end
end


function WallRunHandler:_Init()
	self.Combat.OnSpaceChanged:Connect(function(Value : boolean)
		if Value then
			self:OnJump()
		else
			self.OnLetGo:Fire()
		end
	end)
end


function WallRunHandler:NotStunned()
	return 
		not self.Combat:GetState("Stunned") and 
		not self.Combat:GetState("Ragdolled") and 
		not self.Combat:GetState("Dashing") and
		not self.Combat:GetState("Blocking") and 
		not self.Combat:GetState("M1ing") and
		not self.Combat.ClientHandlers.Vault.Vaulting
end


function WallRunHandler:CanActivate()
	return 
		not self.Combat:GetState("Attacking") and 
		self:NotStunned() and 
		self.LuaCharacter.Humanoid.FloorMaterial == Enum.Material.Air and 
		not self.Wallrunning and 
		not workspace:GetAttribute("IsRankedLobby") and
		self.WallRuns < 3
end


function WallRunHandler:GetDirectionWithIndex(Index : number, Length : number)
	return (Index == 2 and self.LuaCharacter.RootPart.CFrame.RightVector * -Length or self.LuaCharacter.RootPart.CFrame.RightVector * Length)
end


function WallRunHandler:OnJump()
	self.SpaceTime = time()

	if self:CanActivate() then
		for Index = 1, 2 do
			self:Cast(Index)
		end
	end
end

function WallRunHandler:Fire(Raycast : RaycastResult, Index : number)
	if not self:CanActivate() then return end

	local Velocity = self.Combat:CreateBodyVelocity()
	if (Velocity == nil) then return end

	Velocity.MaxForce = Vector3.one * 80000

	local Humanoid : Humanoid = self.LuaCharacter.Humanoid
	local RootPart : BasePart = self.LuaCharacter.RootPart

	self.WallRuns += 1
	self.Wallrunning = true

	if (self.WallRunReset ~= nil and coroutine.status(self.WallRunReset) == "suspended") then
		task.cancel(self.WallRunReset)
		self.Combat:RemoveCooldown("WallRun")
	end
	
	self.Combat:AddCooldown("WallRun", 6)

	self.WallRunReset = task.delay(6, function()
		self.WallRuns = 0
	end)

	self.WallCooldowns[Raycast.Instance] = true
	self.LuaPlayer.Remotes.Combat.AttackInput:FireServer("WallRun", true)

	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	local StopAutoRotate = Utility.StopAutoRotate(self.LuaCharacter.Humanoid)

	for _, Animation : AnimationTrack in self.Animations do
		if Animation.IsPlaying then
			Animation:Stop(0)
		end
	end

	local Side = Index == 1 and "Right" or "Left"

	local Animation = self.Animations[Side]
	Animation:Play(0.05)

	local WallRunning : thread = nil
	local Connection : RBXScriptConnection = nil
	local OnLetGo : RBXScriptConnection = nil

	local FakeArms = {}
	
	task.spawn(function()
		for _, Item in ipairs(RootPart.Parent:GetChildren()) do
			if  Item:IsA("BasePart") and (string.find(Item.Name, "Right") or string.find(Item.Name, "Left")) then
				local FakeArm = EffectUtility.WeldArmTrail(Item)
				table.insert(FakeArms, FakeArm)
			end
		end
	end)

	local RunVFX

	task.spawn(function()
		RunVFX = EffectUtility.EmitEffects(script.Run, RootPart)
	end)

	local ChosenY = 0

	local Slipped = false

	local function Stop(Jumped : boolean)
		if not self.Wallrunning then return end

		self.Wallrunning = false
		self.LuaPlayer.Remotes.Combat.AttackInput:FireServer("WallRun", false, {Slipped = Slipped})
		
		if RunVFX then
			for Item in RunVFX do
				Item:Destroy()
			end
		end
	
		if WallRunning ~= nil and coroutine.status(WallRunning) == "suspended" then
			task.cancel(WallRunning)

		end; WallRunning = nil

		if (OnLetGo ~= nil and OnLetGo.Connected) then
			OnLetGo:Disconnect()
		end

		if (Connection ~= nil and Connection.Connected) then
			Connection:Disconnect()
		end

		if not Jumped then
			for _, Arm in FakeArms do
				EffectUtility.Toggle(Arm, false)
				task.delay(1, Arm.Destroy, Arm)
			end

			Velocity:Destroy()
			StopAutoRotate:Destroy()
		end

		task.delay(0.25, function()
			if self:CanActivate() then
				Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			end

			self.WallCooldowns[Raycast.Instance] = nil
		end)

		Animation:Stop()
	end

	local function Jump()
		Stop(true)

		self.Animations["Jump" .. Side]:Play()
		self.Combat:ResetJumpFatigue()
	
		task.spawn(function()
			EffectUtility.EmitEffects(script.Jump, RootPart)
		end)
	
		local Finished = false

		local function Finish(StopAnimation : boolean)
			if Finished then return end

			Finished = true

			if Connection.Connected then
				Connection:Disconnect()
			end

			Velocity:Destroy()

			if StopAnimation then
				self.Animations["Jump" .. Side]:Stop()
			end

			for _, Arm in FakeArms do
				EffectUtility.Toggle(Arm, false)
				task.delay(1, Arm.Destroy, Arm)
			end
		end

		Connection = RunService.PreSimulation:Connect(function()
			if not self:NotStunned() then
				return Finish(true)
			end

			if (Velocity.Parent ~= nil) then
				Velocity.Velocity = (RootPart.CFrame.LookVector * 25 + (Index == 1 and -RootPart.CFrame.RightVector or RootPart.CFrame.RightVector) * 25 + Vector3.yAxis * 25)
			end
		end)

		StopAutoRotate:Destroy()

		task.delay(0.3, Velocity.Destroy, Velocity)
		task.delay(0.5, Finish)
	end

	Connection = RunService.PreSimulation:Connect(function()
		if not self:NotStunned() then
			return Stop()
		end

		if workspace:GetAttribute("Rain") and not self.LuaPlayer.Player:GetAttribute("UnderRoof") and math.random(1, 1000) == 1 then
			Slipped = true
			return Stop()
		end

		local WallRaycast = workspace:Raycast(RootPart.Position, self:GetDirectionWithIndex(Index, 3), Utility.VisualParams)

		if (WallRaycast == nil) then
			Jump()
		else
			RootPart.CFrame = CFrame.lookAt(RootPart.Position, RootPart.Position + WallRaycast.Normal) * CFrame.Angles(0, Index == 1 and -(math.pi / 2) or math.pi / 2, 0)
		end

		ChosenY += 0.05
		Velocity.Velocity = (RootPart.CFrame.LookVector * 35 + Vector3.yAxis * ChosenY)
	end)

	WallRunning = task.delay(1, Jump)

	OnLetGo = self.OnLetGo:Once(function()
		if (time() - self.SpaceTime) > 0.1 then
			Jump()
		end
	end)

	Velocity.Parent = RootPart
end



function WallRunHandler:Cast(Index : number)
	local RootPart : BasePart = self.LuaCharacter.RootPart

	local Raycast = workspace:Raycast(RootPart.Position, self:GetDirectionWithIndex(Index, 3), Utility.VisualParams)
	local ExtraRaycast = workspace:Raycast(RootPart.Position, self:GetDirectionWithIndex(Index, 3) + RootPart.CFrame.LookVector * 0.25, Utility.VisualParams)

	local ChosenRaycast = nil

	if (Raycast ~= nil and Raycast.Instance.CanCollide and self.WallCooldowns[Raycast.Instance] == nil) then
		ChosenRaycast = Raycast

	elseif (ExtraRaycast ~= nil and ExtraRaycast.Instance.CanCollide and self.WallCooldowns[ExtraRaycast.Instance] == nil) then
		ChosenRaycast = ExtraRaycast
	end

	if (ChosenRaycast ~= nil) then
		self:Fire(ChosenRaycast, Index)
	end
end


----------------------------------------------------------------------------------

function WallRunHandler.new(Combat)
	local self = setmetatable({}, WallRunHandler)

	self.Combat = Combat
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaCharacter.LuaPlayer

	self.Animations = {}

	self.OnLetGo = EventService.new()
	
	self.OnCooldown = false
	self.Wallrunning = false

	self.WallRuns = 0

	self.WallCooldowns = {}

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(WallRunHandler)

return WallRunHandler