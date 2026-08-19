local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(139, 255, 216)
DerivedBlock.icon = "12431506368"
DerivedBlock.description = "Sets your skill's cooldown"
DerivedBlock.order = 33;
DerivedBlock.properties = {
	Cooldown = {
		Described = true;
		Order = 0,
		Default = 10
	};
	Override = {
		Order = 10,
		Default = false,
	};
	Additive = {
		Order = 20,
		Default = false;
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);
	
	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:activate(sequencer, combat)
	local attack = self:get_attack();
	local new_cooldown = tonumber(self.values.Cooldown);
	
	if self.values.Additive and attack.OnCooldown then
		local cooldown_elapsed = tick() - attack.CooldownStart;
		
		new_cooldown += math.max(0, attack.RemainingCooldown - cooldown_elapsed)
	end;
	
	if self.values.Override or self.values.Additive then
		attack:RemoveCooldown();
	end;
	
	attack:AddCooldown( new_cooldown );
end;

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;