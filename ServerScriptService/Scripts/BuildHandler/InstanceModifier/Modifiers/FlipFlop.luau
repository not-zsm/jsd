local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Changes powered state on pulse.";
TagModifier.icon = 116504444429222;
TagModifier.color = Color3.fromRGB(255, 166, 213)
TagModifier.section = 1;
TagModifier.use_prompt = false;
TagModifier.properties = {
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
	AutoDisable = {
		Default = 0;
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.pulse_on_powered = false;
	self.carry_pulse = false;
	
	return self;
end;

local function set_flip_flop(self, signal, value: boolean)
	self:set_always_active(value);

	for _, modifier in self:get_pulse_targets({}) do
		if modifier.attributes:get("Enabled") ~= nil then
			modifier.attributes:set("Enabled", value);
		end;
	end;
	
	if not value then
		self.active_signal:clear();
	end;
end;

function TagModifier:pulse(signal)
	set_flip_flop(self, signal, not self.always_active);
	
	self.active_signal:combine(signal); -- bruh
	
	local disable = self.attributes:get("AutoDisable");
	
	if disable > 0 then
		self.active_maid:add(task.delay(disable, function()
			if self.always_active then
				set_flip_flop(self, signal, false);
			end;
		end));
	end;
end;

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;