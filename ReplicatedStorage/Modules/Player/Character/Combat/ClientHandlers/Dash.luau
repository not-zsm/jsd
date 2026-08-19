local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local Modules = ReplicatedStorage.Modules
local Remotes = ReplicatedStorage.Remotes

local CombatRemotes = Remotes.Combat

local Shared = Modules.Shared
local SharedUtilities = Shared.Utilities

local Animations = ReplicatedStorage.Animations

----------------------------------------------------------------------------------

local DashHandler = {}
DashHandler.__index = DashHandler

local Replication = ReplicatedStorage.Modules.Player:WaitForChild("Replication", 100)

local EffectUtility = require( Replication.EffectUtility )
local DashRocks = require( Replication.Global.DashRocks )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Hitbox = require( ReplicatedStorage.Modules.Shared.Game.Hitbox.Type.Box )

local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )

local MovementReplicatorSettings = require( ReplicatedStorage.MovementReplicator.Settings )

----------------------------------------------------------------------------------

function DashHandler:_Init()
	CombatRemotes.EvasiveOutput.OnClientEvent:Connect(function(Direction : string, Was : string)
		self.Combat:AddCooldown("Evasive")
		self.Combat:AddCooldown("Front&Back Dash")
		self.Combat:AddCooldown("Side Dash")

		if self.CannotDashThread and coroutine.status(self.CannotDashThread) == "suspended" then
			task.cancel(self.CannotDashThread)
			self.CannotDashThread = nil
		end
		
		self.CannotDash = false
	end)

	task.spawn(function()
		local CancelClientDash : RemoteEvent = 	self.LuaPlayer.Remotes:WaitForChild("Combat"):WaitForChild("CancelClientDash")
		
		CancelClientDash.OnClientEvent:Connect(function()
			self.OnServerWantsCancel:Fire()
		end)
	end)
	
	CombatRemotes.FrontDashOutput.OnClientEvent:Connect(function()
		self.Combat:AddCooldown("Front&Back Dash")
		self:FrontDashFunction()
	end)

	CombatRemotes.WallComboOutput.OnClientEvent:Connect(function()
		self.Combat:AddCooldown("Wall Combo")
	end)

	CombatRemotes.WallComboFail.OnClientEvent:Connect(function()
		if not self.Combat:CooldownExists("Front&Back Dash") then
			self.LuaPlayer.Remotes.Combat.AttackInput:FireServer("Dash", true, {DashDirection = "Front", WallCombo = nil})
		end
	end)

	RunService.PostSimulation:Connect(function()
		if self:CanActivate() and self.KeyHeldDown then
			self:OnInput()
		end
	end)

	--for _, Name in {"Stunned", "Ragdolled", "Attacking", "Dashing", "Backdashing", "Blocking", "CannotDash"} do
	--	self.Combat:GetStateChanged(Name):Connect(function()
	--		if not self.Combat:GetState(Name) and self.KeyHeldDown then
	--			self:OnInput()
	--		end
	--	end)
	--end
end


function DashHandler:LoadAnimations(Folder: Instance)
	local function AddAnimation(CurrentTable, Item: Instance, Track : AnimationTrack)
		local Priority = Track.Animation:GetAttribute("Priority")
		CurrentTable[Item.Name] = Track

		if Priority then
			Track.Priority = Enum.AnimationPriority[Priority]
		end
	end

	local function Iterate(CurrentTable, CurrentFolder)
		for Index, Item : (Animation | Folder) in ipairs(CurrentFolder:GetChildren()) do
			if Item:IsA("Animation") then
				AddAnimation(CurrentTable, Item, self.LuaCharacter.Animator:LoadAnimation(Item))

			elseif Item:IsA("Folder") then
				CurrentTable[Item.Name] = {}
				Iterate(CurrentTable[Item.Name], Item)
			end
		end
	end

	Iterate(self.Animations, Folder);
end;


function DashHandler:ClearAllAnimations(): ()
	local function IterateRemove(Animation)
		if typeof(Animation) == "table" then
			for _, Value in Animation do
				IterateRemove(Value);
			end;
		else
			Animation:Stop();
			Animation:Destroy();
		end;
	end;

	IterateRemove(self.Animations);
	table.clear(self.Animations);
end;

function DashHandler:OnHumanoidLoaded()
	self.Combat:RemoveCooldown("Wall Combo")
	self.Combat:RemoveCooldown("Evasive")
	self.Combat:RemoveCooldown("Front&Back Dash")
	self.Combat:RemoveCooldown("Side Dash")

	self.CannotDash = false
	
	self:ClearAllAnimations();
	self:LoadAnimations(Animations.ClientActions.Dash)

	--for _, Item in ipairs(Animations.ClientActions[script.Name]:GetChildren()) do
	--	if Item:IsA("Animation") then
	--		self.Animations[Item.Name] = self.LuaCharacter.Animator:LoadAnimation(Item)

	--		if self.Animations[Item.Name].Animation:GetAttribute("Priority") then
	--			self.Animations[Item.Name].Priority = self.Animations[Item.Name].Animation:GetAttribute("Priority")
	--		end
	--	end
	--end
end


function DashHandler:DirectionOnCooldown(Direction : string)
	return 
		(Direction == "Left" or Direction == "Right") and self.Combat:CooldownExists("Side Dash") or 
		(Direction == "Front" or Direction == "Back") and self.Combat:CooldownExists("Front&Back Dash")
end


function DashHandler:CanActivate()
	return
		not self.Combat:GetState("Stunned") and 
		not self.Combat:GetState("Ragdolled") and 
		not self.Combat:GetState("Attacking") and
		not self.Combat:GetState("Dashing") and
		not self.Combat:GetState("Backdashing") and
		not self.Dashing and 
		not self.SentFrontDashToServer and
		not self.CannotDash and
		not workspace:GetAttribute("IsRankedLobby") and
		self.Combat.AttributeValues:GetAttribute("CombatEnabled")
end

function DashHandler:OnInput()
	if not self.LuaCharacter.HumanoidAlive or self.Combat:GetState("CannotDash") or self.CannotDash then return end

	local InEvasiveState = self.Combat:GetState("EvasiveState") and not self.Combat:CooldownExists("Evasive")
	local Direction = self.LuaCharacter:GetMoveDirection()

	if InEvasiveState then
		return self:Evasive(Direction)
	end

	if (Direction ~= "Front") then
		self:Dash(Direction)
	else
		self:FrontDash()
	end
end

function DashHandler:SmoothEvasive(Direction : string)
	if not self.LuaCharacter.HumanoidAlive then return end

	if MovementReplicatorSettings.use_replicator then
		local Replicator = self.LuaPlayer.Player:FindFirstChild("Replicator")

		if Replicator then
			Replicator:SetAttribute("Ragdoll", false)
		end

		if MovementReplicatorSettings.use_physics_based_ragdolls then
			for _, Item : Instance in ipairs(self.LuaCharacter.Model.RagdollComponents:GetChildren()) do
				if Item:IsA("BallSocketConstraint") then
					Item.Enabled = false

				elseif Item:IsA("BasePart") then
					Item.CanCollide = false
				end
			end

			for _, Item : Motor6D in ipairs(self.LuaCharacter.Model:GetDescendants()) do
				if Item:IsA("Motor6D") and not Item:HasTag("DontModifyOnRagdoll") then
					Item.Enabled = true
				end
			end

			self.LuaCharacter.Model.RagdollComponents.RagdollWeld.Enabled = false
		end
	end

	task.spawn(function()
		for _, Item : Configuration in ipairs(self.LuaCharacter.Humanoid:GetChildren()) do
			if Item:IsA("Configuration") and Item.Name == "StopAutoRotate" and Item:HasTag("Evasive") then
				Item:Destroy()
			end
		end
	end)
	
	task.spawn(function()
		for _, Item in ipairs(CollectionService:GetTagged("RemoveOnEvasive")) do
			local RemoveOn = Item:GetAttribute("RemoveOn")

			if RemoveOn and RemoveOn == self.LuaPlayer.Player.Name then
				Item:Destroy()
			end
		end
	end)
	
	task.spawn(function()
		for _, Item in ipairs(self.LuaCharacter.RootPart:GetChildren()) do
			if Item:HasTag("RemoveOnEvasive") then
				Item:Destroy()
			end
		end
	end)

	self.Combat:ToggleRagdollStates(false)
	self.Combat:StandUpright()

	task.spawn(function()
		EffectUtility.EmitEffects(Replication.VFX.Global.Dashing["Evasive"].Effects, self.LuaCharacter.RootPart)
	end)

	self:Fire(Direction)
end


function DashHandler:Evasive(Direction : string)
	if Direction ~= "Front" and not self:DirectionOnCooldown(Direction) then
		self.CannotDash = true

		self.CannotDashThread = task.delay(0.5 + self.LuaPlayer.Player:GetNetworkPing(), function()
			self.CannotDash = false
		end)

		self:SmoothEvasive(Direction)
		self.LuaPlayer.Remotes.Combat.AttackInput:FireServer("Dash", true, {DashDirection = Direction, Evasive = true})
	end
end

function DashHandler:Dash(Direction : string)
	if self:CanActivate() and not self:DirectionOnCooldown(Direction) then
		if (Direction == "Left" or Direction == "Right") then
			self.Combat:AddCooldown("Side Dash")
			
		elseif (Direction == "Back") then
			self.Combat:AddCooldown("Front&Back Dash")
		end

		self:Fire(Direction)
		self.LuaPlayer.Remotes.Combat.AttackInput:FireServer("Dash", true, {DashDirection = Direction})
	end
end

function DashHandler:FrontDash()
	if self.Dashing then return end

	if not self.Combat:CooldownExists("Wall Combo") and not self.TriedWallCombo then
		self.TriedWallCombo = true

		task.delay(0.4 + (self.LuaPlayer.Player:GetNetworkPing() * 2), function()
			self.TriedWallCombo = false
		end)

		local CF : CFrame = self.LuaCharacter.RootPart.CFrame
		local Raycast = workspace:Blockcast(CF, Vector3.new(3, 0.01, 0.01), CF.LookVector *  13.5, Utility.VisualParams)

		if (Raycast ~= nil and Raycast.Instance.CanCollide) then-- and Raycast.Normal:Dot(Vector3.yAxis) < 0.5) then
			return self.LuaPlayer.Remotes.Combat.AttackInput:FireServer("Dash", true, {DashDirection = "Front", WallCombo = {Position = Raycast.Position, Normal = Raycast.Normal}})
		end
	end

	if not self.Combat:CooldownExists("Front&Back Dash") then
		self.SentFrontDashToServer = true -- so you dont accidently waste your side dash as you front dash (happens more often with worse ping)
		self.LuaPlayer.Remotes.Combat.AttackInput:FireServer("Dash", true, {DashDirection = "Front"})

		task.delay(0.1 + self.LuaPlayer.Player:GetNetworkPing(), function()
			self.SentFrontDashToServer = false
		end)
	end
end

function DashHandler:FrontDashFunction(OnEnded : () -> ())
	local Ended = false
	local Velocity = nil

	local function RemovePush()
		if Ended then return end
		Ended = true

		Velocity:Destroy()
	end

	if not Ended then
		local BodyVelocity = self.Combat:CreateBodyVelocity("FrontDash")
		if (BodyVelocity == nil) then return end

		BodyVelocity.MaxForce = Vector3.new(1, 0, 1) * 80000
		BodyVelocity.Parent = self.LuaCharacter.RootPart

		local Force = 0
		local MaxForce = 144  -- 150 (keeping old values)
		local ForceValue = 43 -- 50 (keeping old values)
		local Duration = 0.895 -- 0.895 (keeping old values)

		local DashVelocity : RBXScriptConnection = nil
		local Cancel : RBXScriptConnection = nil

		BodyVelocity.Destroying:Connect(function()
			if (Cancel ~= nil and Cancel.Connected) then
				Cancel:Disconnect()
			end

			if (DashVelocity ~= nil and DashVelocity.Connected) then
				DashVelocity:Disconnect()
			end
			
			if OnEnded then
				task.spawn(OnEnded)
			end
		end)

		if not self.LuaPlayer.Replication.Attributes:GetAttribute("ForwardDash") then
			BodyVelocity:Destroy()
		end

		Cancel = self.LuaPlayer.Replication.Attributes:GetAttributeChangedSignal("ForwardDash"):Connect(function()
			if not self.LuaPlayer.Replication.Attributes:GetAttribute("ForwardDash") then	
				BodyVelocity:Destroy()
			end
		end)

		do
			local Start = os.clock()

			DashVelocity = RunService.PreSimulation:Connect(function(Delta)
				local LookVector = self.LuaCharacter.RootPart.CFrame.LookVector

				Force = math.min(MaxForce, Force + (ForceValue * (Delta * 60)))
				BodyVelocity.Velocity = (LookVector * Force) * math.max(0, Duration - (os.clock() - Start) / Duration)

				local Raycast = workspace:Raycast(self.LuaCharacter.RootPart.Position, LookVector * 2.5, Utility.VisualParams)

				if (Raycast ~= nil and Raycast.Instance.CanCollide) then
					BodyVelocity.Velocity = Vector3.zero
				end
			end)
		end

		task.delay(Duration, BodyVelocity.Destroy, BodyVelocity)
	end
end

function DashHandler:BackdashFunction(OnEnded : () -> ())
	local BodyVelocity = self.Combat:CreateBodyVelocity("Dash")
	if (BodyVelocity == nil) then return end

	BodyVelocity.MaxForce = Vector3.new(1, 0, 1) * 80000
	BodyVelocity.Parent = self.LuaCharacter.RootPart

	local DashVelocity : RBXScriptConnection = nil
	local RemoveRocks = nil

	local Connections = {}

	self.Dashing = true

	local Animation : AnimationTrack = nil
	local CurrentCharacter = self.Combat:GetCurrentCharacter()
	
	if self.Combat:IsInUltimate() and self.Animations[CurrentCharacter] and self.Animations[CurrentCharacter].Ultimate and self.Animations[CurrentCharacter].Ultimate.Back then
		Animation = self.Animations[CurrentCharacter].Ultimate.Back
	else
		Animation = self.Animations.Back
	end
	
	Animation:Play()
	Animation.TimePosition = 0.15

	local FakeArms = {}

	task.spawn(function()
		for _, Item in ipairs(self.LuaCharacter.Model:GetChildren()) do
			if Item:IsA("BasePart") and (string.find(Item.Name, "Right") or string.find(Item.Name, "Left")) then
				local FakeArm = EffectUtility.WeldArmTrail(Item)
				table.insert(FakeArms, FakeArm)
			end
		end
	end)

	local SFX = nil

	task.spawn(function() -- i think this is erroring and breaking stuff
		SFX = Replication.VFX.Global.Dashing["Backward Dash"].SFX:Clone()
		SFX.Parent = self.LuaCharacter.RootPart

		local function Play()
			SFX:Play()
			task.delay(SFX.TimeLength, SFX.Destroy, SFX)
		end

		if not SFX.IsLoaded then
			SFX.Loaded:Once(Play)
		else
			Play()
		end
	end)

	local GotCancelled = false

	local function Cancel()
		GotCancelled = true

		if SFX then
			SFX:Destroy()
		end

		BodyVelocity:Destroy()
		RemoveRocks()
	end

	RemoveRocks = DashRocks(self.LuaCharacter.RootPart, "Backward Dash", 1.1, function()
		for _, Arm in FakeArms do
			EffectUtility.Toggle(Arm, false)
			task.delay(1, Arm.Destroy, Arm)
		end
	end)

	for _, Name in {"Stunned", "Ragdolled", "Attacking"} do
		Connections[Name] = self.Combat:GetStateChanged(Name):Connect(function()
			if self.Combat:GetState(Name) then
				Cancel()
			end
		end)
	end
	
	Connections["ServerCancelling"] = self.OnServerWantsCancel:Connect(Cancel)

	local Force = 60
	local Duration = 0.85

	self.LuaCharacter.CFRootPartToCameraLookVector = true

	task.delay(1.1, BodyVelocity.Destroy, BodyVelocity)

	local Start = os.clock()
	local TimeInAir = os.clock()

	Connections.DashVelocity = RunService.PreSimulation:Connect(function(Delta)
		BodyVelocity.Velocity = -self.LuaCharacter.RootPart.CFrame.LookVector * Force * math.max(0, Duration - (os.clock() - Start) / Duration)

		local Raycast = workspace:Raycast(self.LuaCharacter.RootPart.Position, -self.LuaCharacter.RootPart.CFrame.LookVector * 2, Utility.VisualParams)

		if (Raycast ~= nil and Raycast.Instance.CanCollide) then
			BodyVelocity.Velocity = Vector3.zero
		end
	end)

	task.delay(0.125, function()
		if self.LuaCharacter.Humanoid.FloorMaterial == Enum.Material.Air then
			Animation:AdjustSpeed(0.35)

			Connections["StateChanged"] = self.LuaCharacter.Humanoid.StateChanged:Connect(function(_, New)
				if New == Enum.HumanoidStateType.Landed or New == Enum.HumanoidStateType.FallingDown then
					Animation:AdjustSpeed(1.5)

					task.delay(0.25, function()
						Animation:AdjustSpeed(1)
					end)
				end
			end)
		end

		task.delay(0.345, function()
			if GotCancelled then return end

			Force = 110
			Duration = 0.8

			Start = os.clock()
		end)
	end)

	BodyVelocity.Destroying:Once(function()
		for _, Connection in Connections do
			if Connection.Connected then
				Connection:Disconnect()
			end
		end

		if Animation.IsPlaying then
			Animation:Stop(0.15)
		end

		self.LuaCharacter.CFRootPartToCameraLookVector = false
		self.Dashing = false

		if OnEnded then
			task.spawn(OnEnded)
		end
	end)
end

function DashHandler:SideDashFunction(Direction : string, OnEnded : () -> ())
	local BodyVelocity = self.Combat:CreateBodyVelocity("Dash")
	if (BodyVelocity == nil) then return end

	BodyVelocity.MaxForce = Vector3.new(1, 0, 1) * 80000
	BodyVelocity.Parent = self.LuaCharacter.RootPart

	local RemoveRocks = nil
	local CancelConnections = {}
	local DashVelocity : RBXScriptConnection = nil

	local Cancelled = false

	local function Cancel()
		if Cancelled then return end

		Cancelled = true
		BodyVelocity:Destroy()
		RemoveRocks()
	end

	local Animation : AnimationTrack = self.Animations[Direction]

	for _, Name in {"Stunned", "Ragdolled", "Attacking"} do
		CancelConnections[Name] = self.Combat:GetStateChanged(Name):Connect(function()
			if self.Combat:GetState(Name) then
				Cancel()

				if Animation.IsPlaying then
					Animation:Stop(0.075)
				end

				local AssemblyVelocity : Vector3 = self.LuaCharacter.RootPart.AssemblyLinearVelocity

				self.LuaCharacter.RootPart.AssemblyLinearVelocity = Vector3.new(
					AssemblyVelocity.X / 1.5, 
					AssemblyVelocity.Y, 
					AssemblyVelocity.Z / 1.5
				)
			end
		end)
	end
	
	CancelConnections["ServerCancelling"] = self.OnServerWantsCancel:Connect(Cancel)

	if Cancelled then return end

	self.Dashing = true

	Animation:Play()
	Animation.TimePosition = 0.05

	task.spawn(function() -- i think this is erroring and breaking stuff
		local Attachment = Instance.new("Attachment")
		Attachment.Name = "SideDashSound"
		Attachment.CFrame = CFrame.new(0, -3, 0)
		Attachment.Parent = self.LuaCharacter.RootPart

		local Sound : Sound = Replication.VFX.Global.Dashing["Side Dash"][tostring(math.random(1, 2))]:Clone()
		Sound.Parent = Attachment
		Sound:Play()

		Sound.Ended:Once(function()
			Attachment:Destroy()
		end)
	end)

	RemoveRocks = DashRocks(self.LuaCharacter.RootPart, "Side Dash", 0.325)

	local Force = 176.5
	local Duration = 0.6785
	local BodyVelocityDuration = 0.33

	self.LuaCharacter.CFRootPartToCameraLookVector = true

	local ForceValueBeforeDash = math.max(0, -(self.LuaCharacter.RootPart.CFrame:VectorToObjectSpace(self.LuaCharacter.RootPart.AssemblyLinearVelocity).Z))

	do
		local Start = os.clock()

		DashVelocity = RunService.PreSimulation:Connect(function(Delta)
			if Cancelled then
				BodyVelocity.Velocity = Vector3.zero
			else
				local RawDirection : Vector3 = 
					(Direction == "Left" and -self.LuaCharacter.RootPart.CFrame.RightVector) or 
					(Direction == "Right" and self.LuaCharacter.RootPart.CFrame.RightVector)

				BodyVelocity.Velocity = (RawDirection * (Force + ForceValueBeforeDash)) * math.max(0, Duration - (os.clock() - Start) / Duration)

				local Raycast = workspace:Raycast(self.LuaCharacter.RootPart.Position, RawDirection * 2.5, Utility.VisualParams)

				if (Raycast ~= nil and Raycast.Instance.CanCollide) then
					BodyVelocity.Velocity = Vector3.zero
				end
			end
		end)
	end

	task.delay(BodyVelocityDuration, BodyVelocity.Destroy, BodyVelocity)

	BodyVelocity.Destroying:Once(function()
		for _, Connection in CancelConnections do
			if (Connection.Connected) then
				Connection:Disconnect()
			end
		end

		if (DashVelocity ~= nil and DashVelocity.Connected) then
			DashVelocity:Disconnect()
		end

		self.LuaCharacter.CFRootPartToCameraLookVector = false
		self.Dashing = false

		if OnEnded then
			task.spawn(OnEnded)
		end
	end)

	return BodyVelocity
end

function DashHandler:Fire(Direction : string, OnEnded : () -> ())
	assert(Direction ~= "Front", "cannot call dashhandler fire with front direction")

	if (Direction == "Back") then
		self:BackdashFunction(OnEnded)
	else
		self:SideDashFunction(Direction, OnEnded)
	end
end

function DashHandler.new(Combat)
	local self = setmetatable({}, DashHandler)

	self.Combat = Combat
	self.UI = Combat.UI
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaCharacter.LuaPlayer

	self.Animations = {}
	self.KeyHeldDown = false
	self.CannotDash = false

	self.OnServerWantsCancel = EventService.new()
	
	self:_Init()

	return self
end

table.freeze(DashHandler)

return DashHandler