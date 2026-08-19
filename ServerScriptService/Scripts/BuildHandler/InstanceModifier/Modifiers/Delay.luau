local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

local PropgationDelay = 1 / 30;

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Delays an active signal";
TagModifier.icon = 12431506368;
TagModifier.color = Color3.fromRGB(173, 144, 0)
TagModifier.section = 1;
TagModifier.use_prompt = false;
TagModifier.properties = {
	Duration = {
		Default = 1;
	};
	DurationSustain = {
		Default = 0;
		Hidden = true;
	};
	Sustain = {
		Default = true;
		Shows = {"DurationSustain"};
	};
	Reversed = {
		Default = false;
	};
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	self.pulse_on_powered = false;
	self.power_maid = self.maid:limb();
	
	return self;
end;

local function power_sustain(self, signal): ()
	local duration: number = self.attributes:get("Duration");
	local invert: number = self.attributes:get("Reversed");
	
	if duration < PropgationDelay then
		duration = PropgationDelay;
	end;
	
	self.active_signal:clear();
	self.active_signal:combine(signal);
	
	self:set_always_active(true);
	
	if invert then
		self:set_powering(true);
		self:immediate_update_powering_source();
	end;
	
	self.power_maid:add(task.delay(duration, function()
		if invert then
			self:set_always_active(false);
			self:set_powering(false);
		else
			self:set_powering(true);
			self:immediate_update_powering_source();
			self:set_always_active(false);
		end;
		
		self.active_signal:clear();
	end));
end;

function TagModifier:pulse(signal, chain)
	if self.attributes:get("Sustain") and not self.always_active then
		self.power_maid:clean();
		
		local duration: number = self.attributes:get("Duration");
		local invert: number = self.attributes:get("Reversed");
		
		if invert then
			self.carry_pulse = true;
			InstanceModifier.pulse(self, signal, chain);
			self.carry_pulse = false;
		else
			task.delay(duration, function()
				self.carry_pulse = true;
				InstanceModifier.pulse(self, signal);
				self.carry_pulse = false;
			end);
		end;
	end;
end;

function TagModifier:on_powered_changed()
	self.power_maid:clean();
	
	local sustain = self.attributes:get("Sustain");
	
	if self.powering  then
		local duration_sustain: number = self.attributes:get("DurationSustain");
		
		if sustain and duration_sustain > 0 then
			self.power_maid:add(task.delay(duration_sustain, function()
				self:set_powering(false);
			end))
		else
			self:set_powering(false);
		end
	end;
	
	if sustain then
		if self.powered then
			power_sustain(self, self:get_signal());
		end
	else
		local duration = self.attributes:get("Duration");
		local invert = self.attributes:get("Reversed");
		
		self:set_powering(invert);
		
		if self.powered or invert then
			self.power_maid:add(task.delay(duration, function()
				self:set_powering(not invert);
			end))
		end;
	end;
end;

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;