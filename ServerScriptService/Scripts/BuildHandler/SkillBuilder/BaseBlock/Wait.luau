local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(235, 235, 235)
DerivedBlock.icon = "4034150594"
DerivedBlock.description = "Waits a certain period of time"
DerivedBlock.order = 1;
DerivedBlock.properties = {
	Time = {
		Default = 1,
		Described = true;
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);

	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:activate()
	task.wait( self.values.Time / self.sequence_skill:get_speed_multiplier() )
end

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;