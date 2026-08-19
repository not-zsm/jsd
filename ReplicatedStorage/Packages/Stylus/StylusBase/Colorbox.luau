local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Table = require( "../../Table" )
local Maid = require( "../../Maid" )
local Signal = require( "../../Signal" )
local Type = require( "../../Type" );
local StylusBase = require( script.Parent );

local ButtonColorBox = script:WaitForChild("Colorbox");

-----------------------------------------------------------------------

export type Defaults = {
	text: string;
	text_scaled: boolean?;
	value: string;
	holder_text: string?;
	tooltip: string?;
	ui_ratio: number?;
	padding: {[string]: UDim}?;
	ratio: number;
	update_event: RBXScriptSignal?;
	parent: Instance?;
};

export type ClassColorbox = {
	__index: ClassColorbox;

	new: (stylus: any, defaults: Defaults) -> Colorbox;
	init: (self: Colorbox) -> ();
	set_color: (self: Colorbox, color: Color3) -> ();
	get_color: (self: Colorbox) -> Color3;
};

export type Colorbox = typeof(setmetatable({} :: {
	defaults: Defaults;
	instance: typeof(ButtonColorBox);
	ratio: number;
	value: string;
	text_scaled: boolean;
	text: string;
	maid: Maid.Maid;
	
}, {} :: ClassColorbox));

-----------------------------------------------------------------------

local Colorbox = setmetatable({} :: ClassColorbox, StylusBase)
Colorbox.__index = Colorbox;
Colorbox.__type = "Colorbox";
Colorbox.defaults = {
	text = "Colorbox";
	text_scaled = false;
	value = "";
	ratio = 0.5;
	parent = nil;
}

function Colorbox.new(stylus, defaults)
	debug.profilebegin("Colorbox");
	
	local self = setmetatable(StylusBase.new(stylus, defaults), Colorbox);
	
	self.defaults = Table.mirror(Colorbox.defaults, defaults or {})
	self:create_instance(ButtonColorBox);
	
	self.layout = self.instance.Layout;
	self.layout.TextLabel.Size = UDim2.fromScale(self.defaults.ratio, 1);
	self.layout.TextLabel.TextScaled = self.defaults.text_scaled;
	self.value_frame.TextBox.PlaceholderText = self.defaults.holder_text or "Nil";
	self.value_frame.TextBox.Text = tostring(self.defaults.value);
	self.instance.Visible = true;
	
	self:set_label(self.defaults.text)
	self:set_text(self.defaults.value);
	self:init();
	self:draw();
	
	debug.profileend();
	
	return self;
end;

function Colorbox:set_label(label: string): ()
	self.layout.TextLabel.Text = tostring(label or "");
end

function Colorbox:set_text(label: string): ()
	self.value_frame.TextBox.Text = tostring(label or "");
end

function Colorbox:set_color(color: Color3 | ColorSequence)
	if typeof(color) == "ColorSequence" then
		color = color.Keypoints[1].Value;
	end;
	
	self:set_text( Type.string:cast(color) );
	
	self.value_frame.Color.BackgroundColor3 = color;
	self.value_changed:Fire(color);
end;

function Colorbox:get_color(): Color3
	return self.value_frame.Color.BackgroundColor3;
end;

function Colorbox:init()
	self.maid:add(self.value_frame.Color.MouseButton1Click:Connect(function()
		self.interacted:Fire(self);
	end))

	self.maid:add(self.instance.Button.MouseButton1Click:Connect(function()
		self.interacted:Fire(self);
	end))
end;

Colorbox.set_value = Colorbox.set_color;
Colorbox.get_value = Colorbox.get_color;

table.freeze(Colorbox);

return Colorbox;