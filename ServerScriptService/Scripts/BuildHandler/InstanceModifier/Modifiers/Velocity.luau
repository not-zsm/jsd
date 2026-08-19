local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Gives parts a permenant velocity";
TagModifier.icon = 96932333352456;
TagModifier.color = Color3.fromRGB(167, 212, 255)
TagModifier.section = 2;
TagModifier.use_prompt = true;
TagModifier.hidden = true;
TagModifier.properties = {
	Power = {
		Default = 20;
	};
	Direction = {
		Default = "0, 1, 0";
	};
	RefreshRate = {
		Default = 0.5;
	};
	Local = {
		Default = false;
	};
	Enabled = {
		Default = true;
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end

function TagModifier:on_active_changed()
	if not self.active then return end;
	
	self.active_maid:add(task.defer(function()
		while task.wait(self.attributes:get("RefreshRate")) do
			self:refresh();
		end
	end))
end

function TagModifier:refresh()
	local data = self.attributes:all();
	local affected = self.part :: BasePart;
	
	if not data.Enabled then
		affected.AssemblyLinearVelocity = Vector3.zero;
	else
		local direction = Type.Vector3:cast(data.Direction);

		if data.Local then
			direction = affected:GetPivot():VectorToWorldSpace(direction);
		end
		
		affected.AssemblyLinearVelocity = direction * data.Power;
	end
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;