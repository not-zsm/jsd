local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Table = require( "../../Table" )
local Maid = require( "../../Maid" )
local Signal = require( "../../Signal" )
local StylusBase = require( script.Parent );

local ButtonInstanceBox = script:WaitForChild("Instancebox");

-----------------------------------------------------------------------

export type Defaults = {
	text: string;
	text_scaled: boolean?;
	holder_text: string?;
	value: Instance;
	tooltip: string?;
	ui_ratio: number?;
	padding: {[string]: UDim}?;
	ratio: number;
	update_event: RBXScriptSignal?;
	parent: Instance?;
};

export type ClassInstancebox = {
	__index: ClassInstancebox;

	new: (stylus: any, defaults: Defaults) -> Instancebox;
	init: (self: Instancebox) -> ();
};

export type Instancebox = typeof(setmetatable({} :: {
	defaults: Defaults;
	instance: typeof(ButtonInstanceBox);
	
}, {} :: ClassInstancebox));

-----------------------------------------------------------------------

local Instancebox = setmetatable({} :: ClassInstancebox, StylusBase)
Instancebox.__index = Instancebox;
Instancebox.__type = "Instancebox";
Instancebox.defaults = {
	text = "Instancebox";
	text_scaled = false;
	value = nil;
	ratio = 0.5;
	parent = nil;
}

function Instancebox.new(stylus, defaults)
	debug.profilebegin("Instancebox");
	
	local self = setmetatable(StylusBase.new(stylus, defaults), Instancebox);
	
	self.defaults = Table.mirror(Instancebox.defaults, defaults or {})
	self:create_instance(ButtonInstanceBox);
	
	self.on_selection_start = self.maid:add(Signal.new());
	self.on_selection_end = self.maid:add(Signal.new());
	self.layout.TextLabel.Size = UDim2.fromScale(self.defaults.ratio, 1);
	self.layout.TextLabel.TextScaled = self.defaults.text_scaled;
	self.value_frame.TextBox.PlaceholderText = self.defaults.holder_text or "Nil";
	self.value_frame.TextBox.Text = tostring(self.defaults.value);
	self.instance.Visible = true;
	self.text_box = self.value_frame.TextBox;
	self.value = self.defaults.value;
	self.select_mode = false;
	
	self:set_label(self.defaults.text)
	self:set_text(self.defaults.value);
	self:init();
	self:draw();
	
	return self;
end;

function Instancebox:set_label(label: string): ()
	self.text_box.Text = tostring(label or "");
end

function Instancebox:set_text(label: string): ()
	self.text_box.Text = tostring(label or "");
end

function Instancebox:set_value(value: Instance?): ()
	if self.value ~= value then
		self.value = value;
		self.value_changed:Fire(value);
		self:set_text(if value then tostring(value) else "");
	end;
end

function Instancebox:get_value()
	return self.value;
end

function Instancebox:start_select()
	if not self.select_mode then
		self.select_mode = true;
		self.value_frame.Select.UIGradient.Enabled = true;
		
		self.stylus:set_active_instance_box(self);
		self.on_selection_start:Fire();
	end;
end

function Instancebox:stop_select(instance: (Instance | boolean)?)
	if self.select_mode then
		local last_value = self.value;
		
		if typeof(instance) ~= "boolean" then
			self:set_value(instance);
		end;
		
		self.select_mode = false;
		self.value_frame.Select.UIGradient.Enabled = false;
		
		self.stylus:set_active_instance_box(nil);
		self.on_selection_end:Fire(self.value);
		
		if self.value ~= last_value then
			self.interacted:Fire(self.value);
		end
	end;
end

function Instancebox:init()
	self.maid:add(function()
		if self.stylus.active_instance_box == self then
			self.stylus:set_active_instance_box(nil);
		end;
	end);
	
	self.maid:add(self.value_frame.Select.MouseButton1Click:Connect(function()
		if self.select_mode then
			self:stop_select(false);
		else
			self:start_select();
		end
	end))
end

table.freeze(Instancebox);

return Instancebox;