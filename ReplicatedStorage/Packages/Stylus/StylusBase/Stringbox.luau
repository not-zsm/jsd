local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Table = require( "../../Table" )
local Maid = require( "../../Maid" )
local Signal = require( "../../Signal" )
local Type = require( "../../Type" );
local StylusBase = require( script.Parent );

local ButtonStringbox = script:WaitForChild("Stringbox");

-----------------------------------------------------------------------

export type Defaults = {
	text: string;
	text_scaled: boolean?;
	holder_text: string?;
	value: string;
	tooltip: string?;
	ui_ratio: number?;
	padding: {[string]: UDim}?;
	ratio: number;
	on_focus_start: (Stringbox) -> ();
	on_focus_lost: (Stringbox) -> ();
	on_commit: (Stringbox, string) -> ();
	on_text_changed: (Stringbox, string) -> ();
	on_update: (Stringbox) -> (any);
	update_event: RBXScriptSignal?;
	parent: Instance?;
};

export type ClassStringbox = {
	__index: ClassStringbox;

	new: (stylus: any, defaults: Defaults) -> Stringbox;
	init: (self: Stringbox) -> ();
};

export type Stringbox = typeof(setmetatable({} :: {
	defaults: Defaults;
	instance: typeof(ButtonStringbox);
	maid: Maid.Maid;
	
}, {} :: ClassStringbox));

-----------------------------------------------------------------------

local Stringbox = setmetatable({} :: ClassStringbox, StylusBase)
Stringbox.__index = Stringbox;
Stringbox.__type = "Stringbox";
Stringbox.defaults = {
	text = "Stringbox";
	text_scaled = false;
	value = "";
	ratio = 0.5;
	parent = nil;
}

function Stringbox.new(stylus, defaults)
	debug.profilebegin("Stringbox");
	
	local self = setmetatable(StylusBase.new(stylus, defaults), Stringbox);
	
	self.defaults = Table.mirror(Stringbox.defaults, defaults or {})
	self:create_instance(ButtonStringbox);
	
	self.focus_start = self.maid:add(Signal.new());
	self.focus_lost = self.maid:add(Signal.new());
	
	self.layout.TextLabel.Size = UDim2.fromScale(self.defaults.ratio, 1);
	self.layout.TextLabel.TextScaled = self.defaults.text_scaled;
	self.value_frame.TextBox.PlaceholderText = self.defaults.holder_text or "Content";
	self.value_frame.TextBox.Text = Type.stringenum:cast(self.defaults.value or "");
	self.value_frame.TextBox.Visible = true;
	self.value_frame.Select.Interactable = true;
	self.text_box = self.value_frame.TextBox;
	
	if self.defaults.dropdown_visible then
		self.value_frame.Select.Visible = true;
	else
		self.value_frame.Select.Visible = false;
	end
	
	self.instance.Visible = true;
	
	self:set_label(self.defaults.text)
	self:set_value(self.defaults.value);
	
	self:init();
	self:draw();
	
	debug.profileend();
	
	return self;
end;

function Stringbox:set_label(label: string): ()
	self.text_box.Text = tostring(label or "");
end

function Stringbox:set_text(label: string): ()
	self.text_box.Text = tostring(label or "");
end

function Stringbox:get_text(): string
	return self.text_box.Text;
end

function Stringbox:bind_to_dropdown(callback)
	self.value_frame.Select.Interactable = true;
	self.value_frame.Select:AddTag("UI-ButtonClick");
	
	return self.maid:add(self.value_frame.Select.MouseButton1Click:Connect(callback));
end

function Stringbox:init()
	if self.defaults.button_based then
		self.text_box.Interactable = false;
		self.text_box.Selectable = false;
		self.instance.Button.Selectable = true;
		self.instance.Button.Visible = true;
		self.instance.Button:AddTag("UI-ButtonClick");
		
		self.maid:add(self.instance.Button.MouseButton1Click:Connect(function()
			self.focus_start:Fire();
			self.interacted:Fire(self.text_box.Text)
		end))
	else
		self.instance.Button.Selectable = false;
		self.text_box.Selectable = true;
		self.text_box.Interactable = true;
		self.instance.Button.Visible = false;
		
		self.maid:add(self.text_box.Focused:Connect(function()
			self.focus_start:Fire();
		end))
	end;
	
	if not self.defaults.variable then
		self.maid:add(self.text_box:GetPropertyChangedSignal("Text"):Connect(function()
			self.value_changed:Fire(self.text_box.Text)
		end))
	end;
	
	self.maid:add(self.text_box.FocusLost:Connect(function()
		if self.maid.destroyed or not self.text_box.Parent then return end;
		
		self.focus_lost:Fire();
		self.interacted:Fire(self.text_box.Text)
	end));
end

function Stringbox:set_value(value: any)
	if self.defaults.variable then
		self.value_changed:Fire(value)
	end;
	
	self.value = value;
	
	if typeof(value) == "NumberSequence" then
		self:set_text( "<...>" );
	else
		self:set_text( Type.format_string(value) )
	end;
end;

function Stringbox:get_value()
	if self.defaults.variable then
		return self.value;
	end;
	
	return self:get_text();
end;

table.freeze(Stringbox);

return Stringbox;