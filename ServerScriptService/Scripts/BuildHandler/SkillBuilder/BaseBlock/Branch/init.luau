local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(216, 116, 255)
DerivedBlock.icon = "76744041179777"
DerivedBlock.description = "Jumps to another branch"
DerivedBlock.help_description = require(script.Description);
DerivedBlock.order = 6;
DerivedBlock.properties = { 
	BranchTo = {
		Order = 10;
		Default = "Branch";
		Described = true;
		ValueList = "Branch",
		Filtered = false;
	};
	BlockIndex = {
		Order = 20;
		Default = 1;
		Described = true;
	};
	Conditional = {
		Order = 30,
		Default = false,
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);

	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:activate(sequencer, combat)
	if self.values.Conditional then
		local branch = self.sequence_skill:get_branch(self.values.BranchTo);
		
		if not branch:test_conditions() then
			return;
		end;
	end;
	
	sequencer:branch_to(self.values.BranchTo, self.values.BlockIndex - 1);
end

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;