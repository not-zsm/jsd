local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Unpacker = require( "../../Unpacker" );
local Maid = require( Unpacker.Packages.Maid );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Pulses on touch.";
TagModifier.icon = "rbxasset://textures/ui/Controls/TouchTapIcon@3x.png";
TagModifier.color = Color3.fromRGB(39, 255, 158)
TagModifier.section = 8;
TagModifier.use_prompt = false;
TagModifier.signal_generator = true;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Touch = {
		Default = true;
	};
	Untouch = {
		Default = false;
	};
	Sticky = {
		Default = true;
	};
	Debounce = {
		Default = 0;
	};
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.touch_maid = self.maid:limb();
	
	return self;
end

function TagModifier.attribute_updates:Sticky(value, was_init)
	self:set_always_active(false);
end

function TagModifier.attribute_updates:Touch(value, was_init)
	local attribute = "Touch";

	self.touch_maid:clean();

	if value then
		local part = self.part :: BasePart;
		
		self.touch_maid:add(self:create_active_toucher(part, function(humanoid, touched)
			if touched then
				self:add_humanoid_to_signal(humanoid)
			else
				self:remove_humanoid_from_signal(humanoid);
			end
			
			if self.attributes:get("Sticky") then
				if self.active_signal.combat_count >= 1 then
					self:set_always_active(true);
				else
					self:set_always_active(false);
				end
				
			elseif self.attributes:get("Untouch") or touched then
				local signal = self:create_pulse();
				signal:add_humanoid(humanoid);
				
				for _, modifier in self:get_pulse_targets() do
					modifier:pulse(signal);
				end
			end
		end))
	else
		self:set_always_active(false);
	end;
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;