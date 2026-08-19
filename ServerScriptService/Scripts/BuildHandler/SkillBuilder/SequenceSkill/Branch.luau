local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Math = require( ReplicatedStorage.Packages.Math )
local Utility = require( "../Utility" );
local ChangeDisplay = require("../BaseBlock/ChangeDisplay");

local Branch = {};
Branch.__index = Branch;
Branch.properties = {
	BranchName = {
		Order = 0,
		Default = "Default";
	};
	AutoBranchOnConditionsMet = {
		Order = 30;
		Default = false;
	};
	DisplayName = {
		Order = 40,
		Default = "",
		Grayboxed = true,
	};
	ToolTip = {
		Order = 50,
		Default = "",
		Grayboxed = true;
	};
	FlashColor = {
		Order = 60,
		Default = Color3.new(1, 1, 1),
		Grayboxed = true;
	};
	--Cooldown = {
	--	Order = 65,
	--	Default = 5,
	--	Grayboxed = true;
	--};
	InAirState = {
		Order = 70;
		Default = false;
		Grayboxed = true;
	};
	HoldSpaceState = {
		Order = 80;
		Default = false;
		Grayboxed = true;
	};
	IsAwakened = {
		Order = 90;
		Default = false;
		Grayboxed = true;
	};
	HasAwakening = {
		Order = 100;
		Default = false;
		Grayboxed = true;
	};
	HealthInRange = {
		Order = 110,
		Default = NumberRange.new(0, 20),
		Grayboxed = true;
	};
	HoldingItems = {
		Order = 120;
		Default = "";
		Grayboxed = true;
	};
};

function Branch.new(sequencer, data)
	local self = setmetatable(
		{
			sequencer = sequencer;
			blocks = {};
			data = data or {};
		}, 
		Branch);
	
	self.values = Utility.block_getter(self.data);
	
	return self;
end;

function Branch:destroy()
	for _, block in self.blocks do
		block:destroy();
	end;
	
	table.clear(self.blocks);
end

function Branch:get_value(name: string)
	if self.data[name] then
		return self.data[name].Value;
	end;
end;

function Branch:test_conditions()
	local combat = self.sequencer.combat;
	local attack = self.sequencer.attack;
	
	assert(combat, "No Combat 🥀");
	assert(attack, "No Attack 🥀")
	
	if not self.data.InAirState.Gray and not Math.XOr(combat.AirState == "", self.data.InAirState.Value) then
		return false;
	end;
	
	if not self.data.HoldSpaceState.Gray and not Math.XOr(not combat.SpaceHeld, self.data.HoldSpaceState.Value) then
		return false;
	end;
	
	if not self.data.IsAwakened.Gray and (attack.CurrentUltimate and Math.XOr(attack.CurrentUltimate.InUltimate, self.data.IsAwakened.Value)) then
		return false;
	end;
	
	if not self.data.HasAwakening.Gray and (attack.CurrentUltimate and Math.XOr(attack.CurrentUltimate.Value >= 100, self.data.HasAwakening.Value)) then
		return false;
	end;
	
	if not self.data.HoldingItems.Gray and not combat.LuaCharacter.Items:HasEquipped(self.data.HoldingItems.Value) then
		return false;
	end;
	
	if not self.data.HealthInRange.Gray then
		local health = combat.LuaCharacter.Humanoid.Health;
		local range = self.data.HealthInRange.Value;
		
		if health < range.Min or health > range.Max then
			return false;
		end;
	end;
	
	return true;
end;

function Branch:apply_display(data)
	return ChangeDisplay.flash_display(self.data, data);
end

function Branch:serialise()
	local serialised = {
		Blocks = {};
		Properties = {};
	};
	
	for name, info in self.properties do
		local value_data = self.data[name];
		local new_value_data = self.sequencer.serialise_property(value_data, info);

		if new_value_data then
			serialised.Properties[info.SaveTo or name] = new_value_data;
		end
	end;
	
	for index, block in self.blocks do
		serialised.Blocks[index] = block:serialise();
	end;
	
	return serialised;
end

table.freeze(Branch);

return Branch;