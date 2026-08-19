local RunService = game:GetService("RunService")

local Data = require( script.Data )

local Ragdoll = {};
Ragdoll.__index = Ragdoll;

function Ragdoll:create_joints()
	if (self.joints_folder ~= nil) then
		self.joints_folder:Destroy()
		self.joints_folder = nil;
	end
	
	if self.humanoid then
		self.humanoid.BreakJointsOnDeath = false;
		self.humanoid.RequiresNeck = false;
	end;
	
	self.joints_folder = Instance.new("Folder")
	self.joints_folder.Name = "RagdollComponents"
	self.joints_folder.Parent = self.character

	self.smoothing_weld = Instance.new("Weld")
	self.smoothing_weld.Name = "RagdollWeld"
	self.smoothing_weld.Part0 = self.root_part
	self.smoothing_weld.Part1 = self.torso;
	self.smoothing_weld.Enabled = false
	self.smoothing_weld.Parent = self.joints_folder;

	local function CreateCollider(Limb : BasePart)
		local Collider = Instance.new("Part")
		Collider.Name = Limb.Name
		Collider.Size = Limb.Size/1.25*self.collider_size_multiplier
		Collider.CanCollide = false
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

		Collider.Parent = self.joints_folder
		
		return Collider
	end
	
	CreateCollider(self.torso)
	
	for _, Motor: Instance in self.torso:GetChildren() do
		if Motor:IsA("Motor6D") and Data.AttachmentCFrames[Motor.Name] then
			local Limb : BasePart? = Motor.Part1

			if not Limb then
				continue
			end
			
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
			Socket.Parent = self.joints_folder
		end
	end
end;

function Ragdoll:get_ball_sockets(): {BallSocketConstraint}
	local sockets = {};
	
	for _, joint in self.joints_folder:GetChildren() do
		if joint:IsA("BallSocketConstraint") then
			table.insert(sockets, joint);
		end;
	end;
	
	return sockets;
end;

function Ragdoll:set_enabled(value: boolean, do_not_joint: boolean)
	self.enabled = value;
	
	if not do_not_joint then
		for _, Item : Motor6D in self.torso:GetChildren() do
			if Item:IsA("Motor6D") and not Item:HasTag("DontModifyOnRagdoll") then
				Item.Enabled = not value
			end
		end
	end;
	
	for _, Item : Instance in self.joints_folder:GetChildren() do
		if not do_not_joint and Item:IsA("BallSocketConstraint") then
			Item.Enabled = value

		elseif Item:IsA("BasePart") then
			Item.CanCollide = value
		end
	end
	
	if RunService:IsServer() and self.humanoid then
		self.humanoid:SetAttribute("Ragdoll", value);
		self.humanoid.AutoRotate = not value;
		self.humanoid.PlatformStand = value;
	end;
	
	self.smoothing_weld.Enabled = value;
end

function Ragdoll.new(character: Model, collider_size_multiplier: number?)
	local self = setmetatable({}, Ragdoll);
	
	self.enabled = false;
	self.character = character;
	self.humanoid = character:FindFirstChild("Humanoid");
	self.root_part = character:WaitForChild("HumanoidRootPart");
	self.torso = character:WaitForChild("Torso");
	self.collider_size_multiplier = collider_size_multiplier or 1;
	
	self:create_joints();
	
	return self;
end;

table.freeze(Ragdoll);

return Ragdoll;