local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Trigger a pulse";
TagModifier.icon = 13286461072;
TagModifier.color = Color3.fromRGB(255, 255, 255)
TagModifier.section = 8;
TagModifier.use_prompt = true;
--TagModifier.signal_generator = true;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Debounce = {
		Default = 0.5;
	};
	Length = {
		Default = 0;
	};
	HoldDuration = {
		Default = 0;
	};
	LabelOff = {
		Default = "Button";
	};
	LabelOn = {
		Default = "";
	};
	Prompt = {
		Default = true;
	};
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	if self.attributes:get("Label") then
		self.attributes:rename("Label", "LabelOff");
	end
	
	return self;
end

local function get_label(self)
	local label_on, label_off = self.attributes:get("LabelOn"), self.attributes:get("LabelOff");
	
	if (label_on == "") then
		return label_off;
		
	elseif self.active then
		return label_on;
	end
	
	return label_off;
end

function TagModifier:prompt_set()
	self.prompt.Enabled = self.attributes:get("Prompt");
	self.prompt.ActionText = get_label(self);
	self.prompt.ObjectText = "";
end

function TagModifier:update()
	InstanceModifier.update(self);
	
	--self.prompt.Enabled = false;
end

function TagModifier.attribute_updates:HoldDuration(value, was_init)
	if self.prompt then
		self.prompt.HoldDuration = value;
	end
end

function TagModifier:on_active_changed()
	self:prompt_set();
end

function TagModifier:prompt_trigger(combat)
	local power_duration = self.attributes:get("Length");
	local humanoid = combat:get_humanoid();
	
	if not humanoid then
		return warn("No humanoid? This shouldn't be possible.");
	end;
	
	if power_duration > 0 then
		self:add_humanoid_to_signal(humanoid);
		self:set_powering(true);
		
		task.delay(power_duration, function()
			self:remove_humanoid_from_signal(humanoid);
			self:set_powering(false);
		end);
	else
		local signal = self:create_pulse();
		signal:add_humanoid(humanoid);
		
		for _, modifier in self:get_pulse_targets({}) do
			modifier:pulse(signal);
			
			if modifier.attributes:get("Enabled") ~= nil then
				modifier.attributes:toggle("Enabled");
			end;
		end;
	end;
end;

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;