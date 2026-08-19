local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(78, 100, 222)
DerivedBlock.icon = "71746708111913"
DerivedBlock.description = "Change the UI appearence"
DerivedBlock.help_description = require(script.Description);
DerivedBlock.order = 9;
DerivedBlock.properties = {
	DisplayName = {
		Order = 1,
		Default = "",
		Described = true,
		Grayboxed = true,
	};
	ToolTip = {
		Order = 1,
		Default = "",
		Described = true;
		Grayboxed = true;
	};
	FlashColor = {
		Order = 2,
		Default = Color3.new(1, 1, 1),
		Described = true;
		Grayboxed = true;
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);

	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:activate()
	DerivedBlock.set_display( self.data, self.sequence_skill.attack );
end;

function DerivedBlock.set_display(data, attack)
	local changed, display = DerivedBlock.flash_display(data, {DisplayName = attack.DisplayName});
	
	if changed then
		attack:ChangeAttackDisplayWithFormatting(display.DisplayName, display.Settings);
	end;
end;

function DerivedBlock.flash_display(data, display)
	local changed = false;
	
	if not display.Settings then
		display.Settings = {};
	end;
	
	if not data.DisplayName.Gray then
		display.DisplayName = data.DisplayName.Value;
		changed = true;
	end;
	
	if not data.ToolTip.Gray then
		display.Settings.Tip = data.ToolTip.Value;
		changed = true;
	end;

	if not data.FlashColor.Gray then
		display.Settings.FlashColor = data.FlashColor.Value;
		changed = true;
	end;
	
	return changed, display;
end

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;