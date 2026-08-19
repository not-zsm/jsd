local Unpacker = require( "../Unpacker" );
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Velocities = require( ReplicatedStorage.BuildTools.Build.Velocities )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Table = require( ReplicatedStorage.Packages.Table )
local BufferUtil = require( ReplicatedStorage.Packages.BufferUtil )
local Remotes = Unpacker.Remotes.Effects;

local VelocityId = 0;
local VelocityIdCap = 2^31-1;

local DefaultData = {
	PushType = "Local",
	PushPower = 20;
	PushVector = Vector3.new(0, 0, -1);
	Axes = Vector3.one,
	MaxForce = 150_000,
	PushDuration = 0,
	RagdollDuration = 0,
	Tapering = NumberSequence.new(1);
	Aligned = false,
};

local VelocityMover = {};
VelocityMover.__index = VelocityMover;

-- Applies a velocity to a combat
function VelocityMover.new(combat, reference: any, origin: CFrame)
	local humanoid = combat:get_humanoid();
	
	local maid = Maid.light();
	local data: {[string]: any};
	
	if typeof(reference) == "Instance" then
		data = reference:GetAttributes();
		
		for attribute, value in DefaultData do
			if data[attribute] == nil then
				reference:SetAttribute(attribute, value);
				data[attribute] = value;
			end;
		end;
	else
		data = Table.reconcile(reference, DefaultData)
	end;
	
	local self = setmetatable(
		{
			maid = maid;
			combat = combat,
			humanoid = humanoid;
			sim_root = combat:GetSimulatedRoot(),
			data = data,
			origin = origin;
		}, 
		VelocityMover);
	
	if typeof(reference) == "Instance" then
		self.reference = reference;
	end;
	
	return self;
end;

function VelocityMover.push(combat, data: any, origin: CFrame)
	local mover = VelocityMover.new(combat, data, origin);
	mover:apply( mover:get_velocity() );
	
	return mover;
end;

function VelocityMover.next_id()
	if VelocityId >= VelocityIdCap then
		VelocityId = -1;
	end;
	
	VelocityId += 1;
	
	return VelocityId;
end

function VelocityMover:apply(velocity: Vector3)
	local player = self.combat:get_player();
	local attachment = self.combat:get_root_attachment();
	local id = VelocityMover.next_id();
	
	if player and player:IsA("Player") then
		if self.reference then
			Remotes.ApplyVelocity:FireClient(player, id, attachment, velocity, self.reference);
		else
			Remotes.ApplyVelocity:FireClient(player, id, attachment, velocity, self.data.Axes, self.data.MaxForce, self.data.PushDuration, self.data.Tapering, self.data.Aligned);
		end;
		
		self.maid:add(function()
			Remotes.RemoveVelocity:FireClient(player, id);
		end);
	else
		Velocities.apply(id, attachment, velocity, self.data.Axes, self.data.MaxForce, self.data.PushDuration, self.data.Tapering, self.data.Aligned);
		
		self.maid:add(function()
			Velocities.remove(id);
		end);
	end;
	
	if self.data.RagdollDuration > 0 and self.combat.Ragdoll then
		self.combat.Ragdoll:Toggle(true, self.data.RagdollDuration);
	end;
end;

function VelocityMover:get_velocity(): Vector3
	local push_type = self.data.PushType;
	local root_part: BasePart = self.sim_root;
	local add_velocity: Vector3 = Vector3.zero;
	
	if push_type == "Difference" then
		local difference = (self.origin.Position - root_part.Position);
		
		if self.data.PushVector ~= Vector3.zero then
			difference = CFrame.lookAlong(Vector3.zero, difference):VectorToWorldSpace(-self.data.PushVector);
		end;

		add_velocity = difference.Unit;

	elseif push_type == "Part Local" then
		add_velocity = self.origin:VectorToWorldSpace(self.data.PushVector);

	elseif (push_type == "Player Local" or push_type == "Local") and (not self.data.Aligned or self.data.PushDuration <= 0) then
		add_velocity = root_part.CFrame:VectorToWorldSpace(self.data.PushVector);

	else
		add_velocity = self.data.PushVector;
	end;

	add_velocity = add_velocity.Unit * self.data.Axes * self.data.PushPower;
	
	if add_velocity ~= add_velocity then
		return Vector3.zero;
	end;
	
	return add_velocity;
end;

function VelocityMover:destroy()
	self.maid:destroy();
end;

table.freeze(VelocityMover);

return VelocityMover;