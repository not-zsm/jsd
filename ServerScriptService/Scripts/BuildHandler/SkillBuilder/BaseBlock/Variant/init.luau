local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);
local Math = require( ReplicatedStorage.Packages.Math )
local Maid = require( ReplicatedStorage.Packages.Maid )
local ChangeDisplay = require("./ChangeDisplay");

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(255, 175, 207)
DerivedBlock.icon = "84388726885769"
DerivedBlock.description = "Branch when the move is used again"
DerivedBlock.help_description = require(script.Description);
DerivedBlock.order = 6;
DerivedBlock.properties = { 
	Duration = {
		Order = 20;
		Default = 0.5;
		Described = true;
	};
	Persistence = {
		Order = 30,
		Default = false,
	};
	PreventCooldown = {
		Order = 40,
		Default = false;
	};
	ExpireCooldown = {
		Order = 50,
		Default = 0,
	};
	DisplayName = {
		Order = 70,
		Default = "",
		Described = true,
		Grayboxed = true,
	};
	ToolTip = {
		Order = 80,
		Default = "",
		Described = true;
		Grayboxed = true;
	};
	FlashColor = {
		Order = 90,
		Default = Color3.new(1, 1, 1),
		Described = true;
		Grayboxed = true;
	};
	BranchTo = {
		Order = 60;
		Default = "Branch";
		Grayboxed = false;
		Described = true;
		ValueList = "Branch",
		Filtered = false;
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);
	
	self.variant_maid = self.maid:limb();
	
	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:cancel()
	self.variant_maid:clean();
end;

function DerivedBlock:remove_interest()
	if self.variant_delay_thread then
		Maid.cancel(self.variant_delay_thread);
		self.variant_delay_thread = nil;
	end;
	
	if self.values.Persistence and self.sequence_skill.variant_interest == self then
		self.sequence_skill:set_variant_interest(nil);
	end;
	
	if self.values.ExpireCooldown > 0 then
		self:get_attack():AddCooldown(self.values.ExpireCooldown)
	end
end

function DerivedBlock:activate(sequencer, combat)
	local attack = self:get_attack();
	ChangeDisplay.set_display(self.data, attack);
	
	self:cancel();
	
	local function cancel_variant_interest()
		self:cancel();
		self:remove_interest();
	end;
	
	self.variant_maid:add(attack.OnVariant:Connect(function()
		cancel_variant_interest();
		self.sequence_skill:branch_to( self.values.BranchTo );
	end));
	
	if self.values.Duration >= 0 then
		local time_range = self.values.Duration / self.sequence_skill:get_speed_multiplier();
		
		self.variant_delay_thread = task.delay(time_range, function()
			if typeof(attack.ResetUIState) == "function" then
				attack:ResetUIState();
			end;
			
			cancel_variant_interest();
		end);
		
		if not self.values.Persistence then
			self.variant_maid:add(self.variant_delay_thread);
		end;
	end;
	
	if self.values.Persistence then
		self.sequence_skill:set_variant_interest(self);
		
	elseif attack:ThreadAvailable() then
		self.variant_maid:add(attack.Thread.OnClosed:Once(cancel_variant_interest));
	else
		cancel_variant_interest();
	end;
end

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;