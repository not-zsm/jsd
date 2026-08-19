local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Serialise = require( "../../Serialise" )
local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );
local BufferUtil = require( Unpacker.Packages.BufferUtil )

local UniversalTween = Unpacker.Remotes.Effects.UniversalTween;

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Sets a property on the given output object";
TagModifier.icon = 12737534507;
TagModifier.color = Color3.fromRGB(119, 255, 164)
TagModifier.section = 2;
TagModifier.use_prompt = false;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Property = {
		Default = "Name",
		Order = 1,
	};
	Value = {
		Default = "Instance";
		TypeDependant = "Property";
		Order = 2,
	};
	Output = {
		Default = nil;
		Type = Type.Instance();
		Order = 3,
	};
	Tween = {
		Order = 4,
		Default = false;
	};
	EasingStyle = {
		Order = 5,
		Default = nil;
		Type = Type.EnumItem();
	};
	EasingDirection = {
		Order = 6,
		Default = nil;
		Type = Type.EnumItem();
	};
	EasingTime = {
		Order = 7,
		Default = nil;
		Type = Type.number();
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end

local function set_property(instance, property, value)
	instance[property] = value;
end

function TagModifier:pulse(signal)
	local data = self.attributes:all();
	local output = self:get_output_value();

	if data.Tween then
		local tween_info = TweenInfo.new(data.EasingTime, data.EasingStyle, data.EasingDirection);
		
		local packet = BufferUtil.create(256);
		BufferUtil.write_tween_info(packet, tween_info);
		BufferUtil.write_string(packet, data.Property);
		BufferUtil.truncate(packet);
		
		UniversalTween:FireAllClients(output, data.Value, packet.buffer);
		
		task.delay(data.EasingTime, pcall, set_property, output, data.Property, data.Value);
	else
		pcall(set_property, output, data.Property, data.Value);
	end;
end;

function TagModifier.attribute_updates:Tween(value, was_init)
	if was_init then return end;

	if value then
		self.attributes:set("EasingStyle", Enum.EasingStyle.Linear);
		self.attributes:set("EasingDirection", Enum.EasingDirection.Out);
		self.attributes:set("EasingTime", 1);
	else
		self.attributes:remove("EasingStyle");
		self.attributes:remove("EasingDirection");
		self.attributes:remove("EasingTime");
	end
end

function TagModifier.attribute_updates:Property(property, was_init)
	if was_init then return end;
	
	local current_value = self.attributes:get("Value");
	local output = self:get_output_value();
	local base_value = Serialise.get_default_property(output.ClassName, property);
	local define_value = if base_value == nil then game else base_value;
	
	if typeof(current_value) ~= typeof(define_value) then
		local caster = Type.define(define_value);
		
		if not caster then return end;

		local value, success, err = caster:cast(property)
		
		if success then
			self.attributes:set("Value", value);
		else
			self.attributes:set("Value", base_value);
		end
	end;
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;