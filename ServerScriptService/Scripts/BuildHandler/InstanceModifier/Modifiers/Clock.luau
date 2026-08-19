local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent.Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Pulses at a fixed interval";
TagModifier.icon = 4034150594;
TagModifier.color = Color3.fromRGB(255, 149, 114)
TagModifier.section = 1;
TagModifier.use_prompt = false;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Active = {
		Default = false;
	};
	Interval = { 
		Default = 1 
	};
	Toggles = { 
		Default = false;
	};
	SignalBased = { 
		Default = false;
	};
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	if self.attributes:get("Enabler") ~= nil then
		self.attributes:rename("Enabler", "Toggles");
	end;
	
	self.short_powered = true;
	
	return self;
end;

function TagModifier.attribute_updates:Active(value, was_init)
	self:set_always_active(value);
end

function TagModifier:on_active_changed()
	if not self.active then return end;
	
	self.active_maid:add(task.defer(function()
		while task.wait(self.attributes:get("Interval")) do
			if self.attributes:get("SignalBased") then
				self:set_powering(true);
				self:immediate_update_powering_source();
				self:set_powering(false);
			else
				local signal = self:create_target_pulse();
				
				for _, modifier in self:get_pulse_targets() do
					modifier:pulse(signal);
					
					if self.attributes:get("Toggles") and modifier.attributes:get("Enabled") ~= nil then
						modifier.attributes:toggle("Enabled");
					end;
				end;
			end
		end
	end))
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;