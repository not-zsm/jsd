

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local Remotes = ReplicatedStorage.Remotes

local CombatRemotes = Remotes.Combat

local Shared = ReplicatedStorage.modules.shared
local SharedUtilities = Shared.Utilities

local Job = require( ReplicatedStorage.modules.shared.Utilities.Job )
local MovementReplicatorSettings = require( ReplicatedStorage.modules.shared.movementReplicator.Settings )

----------------------------------------------------------------------------------

local Ragdoll = {}
Ragdoll.__index = Ragdoll

local Utility = require( SharedUtilities.Utility )
local Data = require(script.Data)

----------------------------------------------------------------------------------

function Ragdoll:Toggle(Value : boolean, Duration : number?)
	if (self.Folder == nil or not self.LuaCharacter.HumanoidExists) then return end

	if Value then
		self:ClearTimer()
		
		if (Duration ~= nil) then
			self.RagdollDelay = task.delay(Duration * self.TimeMultiplier, self.Toggle, self, false)
		end
	end
	
	if not (Value == false and not self.LuaCharacter.HumanoidAlive) then 
		self:_Toggle(Value)
	end
end

function Ragdoll:ForceToggleOff()
	if (self.Folder == nil or not self.LuaCharacter.HumanoidExists) then return end
	self:_Toggle(false)
end

function Ragdoll:ClearTimer()
	if (self.RagdollDelay ~= nil and coroutine.status(self.RagdollDelay) == "suspended") then
		task.cancel(self.RagdollDelay)
	end
end

function Ragdoll:_Toggle(Value : boolean, DontStandUpright : boolean)
	if self.Combat:GetState("Ragdolled") ~= Value then
		self.Combat:StackState("EvasiveState", Value)
		self.Combat:StackState("Ragdolled", Value)

		if Value then
			self.Combat:StackState("StunImmunity", true)
			self.Combat:CancelAllAttacks()
			
			self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
			self:SetCollisionGroupOfColliders("NoPlayerCollision")
			
			if self.RagdollJob then
				self.RagdollJob:Destroy()
			end
			
			self.RagdollJob = Job.new()
			
			local SimulatedRoot : BasePart = self.Combat:GetSimulatedRoot()
			
			self.RagdollJob:Task(task.spawn(function()
				local Velocity : Vector3 = Vector3.zero
				local WaitTime = 0
				
				while (SimulatedRoot ~= nil and SimulatedRoot.Parent ~= nil) do
					Velocity = self.LuaCharacter.RootPart.AssemblyLinearVelocity;
					
					local Magnitude = Velocity.Magnitude
					local WaitDiv = Utility.cmap(Magnitude, 40, 225, 5, 60)
					WaitTime = 1 / WaitDiv;

					if (Magnitude > 3) then
						local CF : CFrame = SimulatedRoot.CFrame + Velocity / 10;

						self.Combat.Hitbox:CreateHavocReplicated({
							parameters = {
								origin = CF,
								radius = 3.45 * Utility.cmap(Magnitude, 40, 225, 1, 4),
								shape = "Sphere", 
								block_size = 4 + Utility.cmap(Magnitude, 40, 250, 1, 4)
							},

							debris = {
								scale = 0.9,
								velocity = function(cube)
									local Power = Utility.cmap(Magnitude, 20, 200, 1, 10)

									return (Velocity.Unit * (15 + cube:GetMass() / 2 + Power)) + Random.new():NextUnitVector() * 10;
								end 
							},
						})
					end
			
					task.wait(WaitTime)
				end
			end))
		else
			if self.RagdollJob then
				self.RagdollJob:Destroy()
				self.RagdollJob = nil
			end
			
			if not self.Combat:GetState("Grabbed") then
				self.LuaCharacter:SetCollisionGroup("Player")
			end
			
			self:SetCollisionGroupOfColliders("Default")
			
			self.GettingUpArmor = true
			
			task.delay(0.5, function()
				self.GettingUpArmor = false
				self.Combat:StackState("StunImmunity", false)
			end)

			if not DontStandUpright then
				self.LuaCharacter:StandUpright()
			end
			
			self.Combat.Animations.GetUp:Play()
		end	

		if Value then
			self.StopAutoRotateConfig = Utility.StopAutoRotate(self.LuaCharacter.Humanoid, "Evasive")
		else
			if self.StopAutoRotateConfig then
				self.StopAutoRotateConfig:Destroy()
				self.StopAutoRotateConfig = nil
			end
		end
		
		if self.LuaPlayer.IsNPC then
			self.LuaCharacter:SetOwnership(nil)
			self.LuaCharacter.Humanoid.PlatformStand = Value
		else
			if not DontStandUpright then
				CombatRemotes.Ragdoll:FireClient(self.LuaPlayer.Player, Value)
			end
		end
	
		local UsePhysicsBasedRagdolls = not MovementReplicatorSettings.use_replicator or self.LuaPlayer.IsNPC or MovementReplicatorSettings.use_physics_based_ragdolls
		
		if UsePhysicsBasedRagdolls then
			for _, Item : Motor6D in ipairs(self.LuaCharacter.Torso:GetChildren()) do
				if Item:IsA("Motor6D") and not Item:HasTag("DontModifyOnRagdoll") then
					Item.Enabled = not Value
				end
			end
		end
		
		for _, Item : Instance in ipairs(self.Folder:GetChildren()) do
			if UsePhysicsBasedRagdolls and Item:IsA("BallSocketConstraint") then
				Item.Enabled = Value

			elseif Item:IsA("BasePart") then
				Item.CanCollide = Value
			end
		end
		
		local Replicator = self.LuaPlayer.Player:FindFirstChild("Replicator");

		if Replicator then
			Replicator:SetAttribute("Ragdoll", Value);
		end;

		self.RagdollWeld.Enabled = Value
		self.LuaPlayer.Replication.Attributes:SetAttribute("CraterImpact", Value)
		self.LuaPlayer.Replication.Attributes:SetAttribute("RagdollImpact", Value)
		
		if Value then
			self.LuaPlayer.Replication:FireReliableVFX("Global/Impact", "RagdollImpact", self.LuaCharacter.RootPart)
		end
	end
end

function Ragdoll:CreateFolder()
	if (self.Folder ~= nil) then
		self.Folder:Destroy()
	end
	
	self.LuaCharacter.Humanoid.BreakJointsOnDeath = false

	self.Folder = Instance.new("Folder")
	self.Folder.Name = "RagdollComponents"
	self.Folder.Parent = self.LuaCharacter.Model
	
	self.RagdollWeld = Instance.new("Weld")
	self.RagdollWeld.Name = "RagdollWeld"
	self.RagdollWeld.Part0 = self.LuaCharacter.RootPart
	self.RagdollWeld.Part1 = self.LuaCharacter.Torso
	self.RagdollWeld.Enabled = false
	self.RagdollWeld.Parent = self.Folder

	self.RagdollDelay = nil

	local function CreateCollider(Limb : BasePart)
		local Collider = Instance.new("Part")
		Collider.Name = Limb.Name
		Collider.Size = Limb.Size/1.25
		Collider.CanCollide = false
		Collider.CanQuery = false
		Collider.CanTouch = false
		Collider.Massless = true
		Collider.CFrame = Limb.CFrame
		Collider.Transparency = 1
		Collider.CollisionGroup = "RagdollCollider"
		Collider:AddTag("RagdollCollider")

		local Weld = Instance.new("WeldConstraint", Collider)
		Weld.Part0 = Collider
		Weld.Part1 = Limb

		local NoCollisionConstraint = Instance.new("NoCollisionConstraint", Collider)
		NoCollisionConstraint.Part1 = Collider
		NoCollisionConstraint.Part0 = Limb

		Collider.Parent = self.Folder
	end

	CreateCollider(self.LuaCharacter.Torso)
	
	for _, Motor : Motor6D in pairs(self.LuaCharacter.Torso:GetChildren()) do
		if Motor:IsA("Motor6D") and Data.AttachmentCFrames[Motor.Name] then
			local Limb : BasePart? = Motor.Part1

			if not Limb then
				continue;
			end;

			CreateCollider(Limb)

			local Attachment0, Attachment1 = Instance.new("Attachment"), Instance.new("Attachment")
			Attachment0.CFrame = Data.AttachmentCFrames[Motor.Name][1]
			Attachment1.CFrame = Data.AttachmentCFrames[Motor.Name][2]
			Attachment0.Name = "RagdollAttachment"
			Attachment1.Name = "RagdollAttachment"

			local Socket = Instance.new("BallSocketConstraint")
			Socket.Name = Motor.Name
			Socket.Attachment0 = Attachment0
			Socket.Attachment1 = Attachment1
			
			Socket.Radius = 0.15
			Socket.LimitsEnabled = true
			Socket.TwistLimitsEnabled = false
			Socket.MaxFrictionTorque = 1
			Socket.Restitution = 1
			Socket.UpperAngle = 90
			Socket.TwistLowerAngle = -45
			Socket.TwistUpperAngle = 45

			if Motor.Name == "Neck" then
				Socket.TwistLimitsEnabled = true
				Socket.UpperAngle = 45
				Socket.TwistLowerAngle = -70
				Socket.TwistUpperAngle = 70
			end
			
			Socket.Enabled = false

			Attachment0.Parent = Motor.Part0
			Attachment1.Parent = Limb
			Socket.Parent = self.Folder
		end
	end
end

function Ragdoll:SetCollisionGroupOfColliders(Group : string)
	self.CurrentColliderGroup = Group
	
	for _, Item : Instance in ipairs(self.Folder:GetChildren()) do
		if Item:IsA("BasePart") and Item:HasTag("Collider") then
			Item.CollisionGroup = Group
		end
	end
end

----------------------------------------------------------------------------------

function Ragdoll.new(Combat)
	local self = setmetatable({}, Ragdoll)

	self.Combat = Combat
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaPlayer
	
	self.TimeMultiplier = 1

	return self
end

----------------------------------------------------------------------------------

table.freeze(Ragdoll)

return Ragdoll