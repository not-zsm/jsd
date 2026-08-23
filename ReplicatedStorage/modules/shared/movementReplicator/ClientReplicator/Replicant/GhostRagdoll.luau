local replicatedStorage = game:GetService("ReplicatedStorage")

local Ragdoll = require( replicatedStorage.modules.shared.movementReplicator.Lib.Ragdoll )
local Settings = require( replicatedStorage.modules.shared.movementReplicator.Settings )

local Assets = replicatedStorage.modules.shared.movementReplicator.Assets;

local GhostRagdoll = {};
GhostRagdoll.__index = GhostRagdoll;

function GhostRagdoll.new(character: Model)
	local rig = Assets.GhostRig:Clone();
	
	local self = setmetatable(
		{
			character = character;
			rig = rig;
			root = rig.HumanoidRootPart;
			ragdoll = Ragdoll.new(rig, 1);
			body_parts = {};
		}, 
		GhostRagdoll);
	
	self:initialise();
	
	return self;
end;

function GhostRagdoll:initialise()
	self.rig.Archivable = false
	self.rig.Parent = workspace.Terrain;
	
	for _, limb in self.rig:GetChildren() do
		if limb:IsA("BasePart") and limb.Name ~= "HumanoidRootPart" then
			self.body_parts[limb] = self.character:FindFirstChild(limb.Name);
		end;
	end
end

function GhostRagdoll:set_enabled(value: boolean)
	if self.ragdoll.enabled == value then return end;
	
	for ghost_limb, limb in self.body_parts do
		if limb.Name == "Torso" then
			ghost_limb.CanCollide = value
		else
			ghost_limb.CanCollide = false;
		end;
		
		ghost_limb.AssemblyLinearVelocity = Vector3.zero;
		ghost_limb.AssemblyAngularVelocity = Vector3.zero;
	
		limb.CanCollide = not value and (limb.Name == "Head" or limb.Name == "Torso");
		limb.Anchored = value;
		limb.AssemblyLinearVelocity = Vector3.zero;
		limb.AssemblyAngularVelocity = Vector3.zero;
	end;
	
	if Settings.use_ghost_linear_velocity_fix then
		local root = self.character:FindFirstChild("HumanoidRootPart");
		
		if root then
			-- Awkward but a transition from regular ragdoll and ghost ragdoll with the root part anchored causes freak-outs 
			root.AssemblyAngularVelocity = Vector3.zero;
			root.AssemblyLinearVelocity = Vector3.zero;
		else
			warn("No HumanoidRootPart to apply velocity fix to")
		end
	end;

	self.ragdoll:set_enabled(value);
	
	local joints = self.character:FindFirstChild("RagdollComponents");

	if joints then
		for _, part in joints:GetChildren() do
			if part:IsA("BasePart") then
				part.CanCollide = false;
			end
		end
	end
end

function GhostRagdoll:destroy()
	self.rig:Destroy();

	for ghost_limb, limb in self.body_parts do
		limb.CanCollide = (limb.Name == "Head" or limb.Name == "Torso");
		limb.Anchored = false;
	end;

	self.rig = nil;
	self.ragdoll = nil;
	self.body_parts = nil;
end


table.freeze(GhostRagdoll);

return GhostRagdoll;