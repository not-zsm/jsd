local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);
local Asset = require( ReplicatedStorage.Packages.Asset )
local Unpacker = require( "../../Unpacker" );
local MoveVelocity = require( "../../InstanceModifier/MoveVelocity" );

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(58, 255, 206)
DerivedBlock.icon = "96932333352456"
DerivedBlock.description = "Apply variable velocities to yourself"
DerivedBlock.help_description = require(script.Description);
DerivedBlock.order = 4;
DerivedBlock.properties = {
	PushType = {
		Order = 10;
		Default = "Local";
		ValueList = { "Local", "Global", };
		--ViewingHelper = {
		--	Type = "ValueList",
		--	List = {"Local", "Global"},
		--};
	};
	PushPower = {
		Default = 20;
		Described = true;
	};
	PushDuration = {
		Order = 30;
		Default = 0.1;
		Described = true;
	};
	PushVector = {
		Order = 40;
		Default = -Vector3.zAxis;
		Described = true;
	};
	MaxForce = {
		Order = 50;
		Default = 150_000;
	};
	Axes = {
		Order = 60;
		Default = Vector3.one;
	};
	RagdollDuration = {
		Order = 70;
		Default = 0;
	};
	Tapering = {
		Default = NumberSequence.new(1);
		Order = 80,
	};
	Aligned = {
		Order = 90;
		Default = true;
	};
	Cancellable = {
		Order = 100;
		Default = false;
	};
	Targeting = {
		Order = 120,
		Default = "Default",
		IsBranchTargeting = true;
		ValueList = { "Default", "User", "Target" };
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);

	self.velocities = {};
	
	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:cancel(forceful)
	if self.values.Cancellable or forceful then
		for _, mover in self.velocities do
			mover:destroy();
		end;
		
		table.clear(self.velocities);
	end;
end;

local function remove_velocity(self, mover)
	local index = table.find(self.velocities, mover);

	if index then
		table.remove(self.velocities, index);
	end;

	mover:destroy();
end;

function DerivedBlock:initialise_cache(cache: Configuration)
	local data = self:get_values();

	self.cache_setting = Instance.new("Configuration");
	self.cache_setting.Name = self:get_internal_name();
	
	for attribute, value in data do
		self.cache_setting:SetAttribute(attribute, value);
	end;
	
	self.cache_setting.Parent = cache;
end;

function DerivedBlock:activate(sequencer, combat)
	local data = self:get_values();
	local multiplier = self.sequence_skill:get_speed_multiplier();
	
	if data.PushType == "Local Aligned" then
		data.PushType = "Local";
		data.Aligned = true;
	end;
	
	data.PushPower *= multiplier;
	
	if data.PushVector ~= Vector3.zero then
		data.PushVector = data.PushVector.Unit;
	end;
	
	if data.PushDuration then
		data.PushDuration /= multiplier;
	end;
	
	for attribute, value in data do
		self.cache_setting:SetAttribute(attribute, value);
	end;
	
	local mover = MoveVelocity.push(combat, self.cache_setting, CFrame.identity);
	
	if data.PushDuration then
		table.insert(self.velocities, mover);
		
		task.delay(data.PushDuration, remove_velocity, self, mover);
	end;
end;

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;