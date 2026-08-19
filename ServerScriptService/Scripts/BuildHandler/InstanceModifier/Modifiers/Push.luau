local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local MoveVelocity = require( "../MoveVelocity" )
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Apply velocities and ragdoll to players";
TagModifier.icon = 9657499712;
TagModifier.color = Color3.fromRGB(255, 238, 0)
TagModifier.section = 3;
TagModifier.properties = {
	RagdollDuration = {
		Default = 1;
	};
	PushType = {
		Default = "Difference";
		ValueList = {"Difference", "Part Local", "Player Local", "Global"};
	};
	PushPower = {
		Default = 20;
	};
	PushVector = {
		Default = Vector3.zero;
	};
	Axes = {
		Default = Vector3.one;
	};
	PushDuration = {
		Default = 0;
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end

function TagModifier:pulse(signal)
	if not self.part then
		return;
	end;
	
	local data = self.attributes:all();
	local push_type: string = data.PushType;
	local part_cframe = self:get_cframe();
	
	for _, combat in signal:get_combats() do
		MoveVelocity.push(combat, data, part_cframe);
	end;
end;

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;