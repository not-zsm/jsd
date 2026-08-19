--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Unpacker = require( "../../Unpacker" );
local ModifierUtil = require( "../ModifierUtil" );
local Serialise = require( "../../Serialise" );
local PropertiesUtil = require( Unpacker.Shared.Data.Properties.Utility );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Sets constraint properties based on input signal";
TagModifier.icon = 9940311645;
TagModifier.color = Color3.fromRGB(190, 221, 188)
TagModifier.section = 2;
TagModifier.use_prompt = false;
TagModifier.signal_generator = false;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	UseAttachment1 = {
		Default = true;
	};
	Decouple = {
		Default = false;
	};
	Constraint = {
		Default = nil;
		Type = Type.Instance();
	};
};

local function set_enabled(self, signal)
	local data = self.attributes:all();
	local constraint: Constraint = data.Constraint;
	local origin: Vector3 = self:get_position();
	local nearest = ModifierUtil.get_nearest(origin, signal:get_humanoids())

	if nearest then
		local coordinate = signal.coordinate or nearest.RootPart.CFrame;

		if data.UseAttachment1 and self.has_attachment1 then
			constraint.Attachment1 = nearest.RootPart.RootAttachment;

		elseif self.has_part1 then
			constraint.Part1 = nearest.RootPart;

		elseif constraint:IsA("AlignOrientation") then
			constraint.CFrame = CFrame.lookAt(origin, coordinate.Position)

		elseif self.has_cframe then
			constraint.CFrame = coordinate;
		end;
	end;
end;

local function set_disabled(self, signal)
	local data = self.attributes:all();
	local constraint: Constraint = data.Constraint;
	
	if data.UseAttachment1 and self.has_attachment1 then
		constraint.Attachment1 = nil;

	elseif self.has_part1 then
		constraint.Part1 = nil;
	end
end

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	self.pulse_on_powered = false;
	
	self.has_attachment1 = false;
	self.has_part1 = false;
	self.has_cframe = false;
	
	return self;
end;

function TagModifier:on_powered_changed()
	self:pulse(self:get_signal(), {}, true);
end;

function TagModifier.attribute_updates:Constraint(value, was_init)
	if not value then return end;
	
	self.has_attachment1 = PropertiesUtil.is_property(value, "Attachment1");
	self.has_part1 = PropertiesUtil.is_property(value, "Part1");
	self.has_cframe = PropertiesUtil.is_property(value, "CFrame")
end

function TagModifier:pulse(signal, chain, power_pulse)
	local constraint: Constraint? = self.attributes:get("Constraint");

	if constraint then
		if (not power_pulse or self.powered) and not self.attributes:get("Decouple") then
			set_enabled(self, signal);
		else
			set_disabled(self, signal);
		end;
	end;
end;

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;