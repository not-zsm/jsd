local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);
local Math = require( ReplicatedStorage.Packages.Math )

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(255, 175, 207)
DerivedBlock.icon = "13492316854"
DerivedBlock.description = "Cancel (or branch) if damage was not dealt within last period of time"
DerivedBlock.help_description = require( script.Description );
DerivedBlock.deprecated = true;
DerivedBlock.order = 6;
DerivedBlock.properties = { 
	Inverted = {
		Order = 1;
		Default = false;
	};
	Time = {
		Order = 2;
		Default = 1;
		Described = true;
	};
	Endlag = {
		Order = 3;
		Default = 1;
	};
	BranchTo = {
		Order = 5;
		Default = "Branch";
		Grayboxed = true;
		Described = true;
		ValueList = "Branch",
		Filtered = false;
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);
	
	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:activate(sequencer, combat)
	local attack = self:get_attack();
	
	local time_now = tick();
	local time_range = self.values.Time / self.sequence_skill:get_speed_multiplier();
	
	if Math.XOr(time_now - combat.LastAfflictedDamage > time_range, self.values.Inverted) then
		if self.values.Endlag > 0 then
			combat:StackState("Attacking", true, self.values.Endlag);
		end;
		
		if not self.data.BranchTo.Gray then
			sequencer:branch_to(self.values.BranchTo);
		else
			attack:Close();
		end;
	end;
end

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;