local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(139, 255, 216)
DerivedBlock.icon = "18416638478"
DerivedBlock.description = "Adds an amount of health"
DerivedBlock.order = 34;
DerivedBlock.properties = {
	Value = {
		Described = true;
		Order = 1,
		Default = 10
	};
	Targeting = {
		Order = 120,
		Default = "Default",
		IsBranchTargeting = true;
		ValueList = { "Default", "User", "Target" };
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);
	
	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:activate(sequencer, combat)
	combat.LuaCharacter:Heal( self.values.Value );
end

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;