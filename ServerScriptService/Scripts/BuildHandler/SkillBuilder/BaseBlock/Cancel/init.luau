local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);
local Math = require( ReplicatedStorage.Packages.Math )

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(255, 114, 114)
DerivedBlock.icon = "14219436180"
DerivedBlock.description = "Cancel any blocks that are active."
DerivedBlock.help_description = require(script.Description);
DerivedBlock.order = 6;
DerivedBlock.properties = { 
	
	ToPrevious = {
		Order = 1;
		Default = 1;
		Grayboxed = true;
	};
	IncludeUpToPrevious = {
		Order = 2,
		Default = false;
	};
	IgnoreCancellable = {
		Order = 2.4;
		Default = true;
	};
	CurrentBranchOnly = {
		Order = 2.5;
		Default = false;
	};
	Skill = {
		Order = 3;
		Default = false;
		Described = {true};
		TitleColor = Color3.fromRGB(182, 221, 220),
	};
	Sound = {
		Order = 4;
		Default = false;
		Described = {true};
		TitleColor = Color3.fromRGB(182, 221, 220),
	};
	Velocity = {
		Order = 5;
		Default = false;
		Described = {true};
		TitleColor = Color3.fromRGB(182, 221, 220),
	};
	Animation = {
		Order = 6;
		Default = false,
		Described = {true};
		TitleColor = Color3.fromRGB(182, 221, 220),
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);
	
	return self;
end;

-------------------------------------------------------------------------

local function cancel_block(self, block)
	local to_cancel = self.data[block.name];
	
	if to_cancel and to_cancel.Value then
		block:cancel(self.values.IgnoreCancellable);
	end
end;

function DerivedBlock:activate(sequencer, combat)
	local attack = self:get_attack();
	
	if self.data.ToPrevious.Gray then
		
		if self.values.CurrentBranchOnly then
			for _, block in self.branch:get_blocks() do
				cancel_block(self, block);
			end;
		else
			for _, block in self.sequence_skill:get_blocks() do
				cancel_block(self, block);
			end;
		end
	else
		local previous = sequencer:get_previous_blocks();
		local to_previous = self.values.ToPrevious;
		
		if self.values.CurrentBranchOnly then
			-- Clamps the value to the within current branches blocks (self.position is the position in the branch)
			to_previous = math.min(to_previous, self.position - 1);
		end;
		
		if self.values.IncludeUpToPrevious then
			for index = 1, to_previous do
				local block = previous[index];
				
				if block then
					cancel_block(self, block);
				else
					break;
				end;
			end;
		else
			local block = previous[to_previous];
			
			if block then
				cancel_block(self, block);
			end;
		end;
	end;
end;

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;