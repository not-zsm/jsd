
local replicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Table = require( "../Table" )
local Maid = require( "../Maid" )
local Signal = require( "../Signal" )

local ButtonCheckbox = script:WaitForChild("Checkbox");
local Assets = script.Parent.Assets;

-----------------------------------------------------------------------

export type ClassStylusBase = {
	__index: ClassStylusBase;
	__type: string;
	__themes: {[string]: {BoxTransparency: number, BoxColor: Color3}};
	cache_list: {[string]: {Instance}};
	
	new: (stylus: any, defaults: any) -> StylusBase;
	destroy: (self: StylusBase) -> ();
	on_property_changed: (self: StylusBase, instance: Instance, property: string, callback: (value: any) -> ()) -> ();
	get_instance: (self: StylusBase) -> ();
	draw: (self: StylusBase) -> ();
	set_theme: (self: StylusBase, theme_id: string) -> ();
	is_focused: (self: StylusBase) -> ();
	set_value: (self: StylusBase, value: any) -> ();
	get_value: (self: StylusBase) -> any;
	update: (self: StylusBase) -> ();
	init: (self: StylusBase) -> ();
};

export type StylusBase = typeof(setmetatable({} :: {
	
	stylus: any;
	instance: GuiObject?;
	defaults: any?;
	maid: Maid.Maid;
	value_changed: Signal.Signal<...any>;
	
}, {} :: ClassStylusBase));

-----------------------------------------------------------------------

local StylusBase = {} :: ClassStylusBase
StylusBase.__type = "StylusBase"
StylusBase.__index = StylusBase;
StylusBase.__themes = {
	["bg_transparent"] = {
		BoxTransparency = 0.8;
		BoxColor = Color3.fromRGB(32, 32, 32);
	};
};
StylusBase.cache_list = {};

function StylusBase.new(stylus, defaults)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			stylus = stylus;
			instance = nil;
			defaults = nil;
			maid = maid;
			value_changed  = maid:add(Signal.new());
			interacted = maid:add(Signal.new());
		}, 
		StylusBase);
	
	return self;
end;

function StylusBase:destroy()
	if self.is_grayboxed ~= nil then
		self.is_grayboxed = nil;
		
		self.gray_overlay:Destroy();
		self.gray_overlay = nil;

		self.gray_checkbox:Destroy();
		self.gray_checkbox = nil;

		self.gray_changed:Destroy();
		self.gray_changed = nil;
	end;
	
	self.maid:destroy();
	
	if not self.cache_list[self.__type] then
		self.cache_list[self.__type] = {};
	end;
	
	if self.instance then
		self.instance.Visible = false;
		
		if self.instance.Parent then
			table.insert(self.cache_list[self.__type], self.instance);
		else
			self.instance:Destroy();
		end
	end;
	
	self.instance = nil;
end;

function StylusBase:on_property_changed(instance: Instance, property: string, callback: (value: any) -> ()): RBXScriptConnection?
	local success, connection = pcall(instance.GetPropertyChangedSignal, instance, property);

	if success then
		return self.maid:add(connection:Connect(function()
			callback( instance[property] );
		end))
	end;
	
	return nil;
end

function StylusBase:create_instance(reference: GuiObject)
	assert(reference, "No reference was given");
	assert(reference:IsA("GuiObject"), "Reference is not a GuiObject");
	
	if self.cache_list[self.__type] then
		self.instance = table.remove(self.cache_list[self.__type]);
		
		if self.instance and not self.instance:FindFirstChild("Layout") then
			self.instance = nil;
		end
	end;
	
	if not self.instance then
		self.instance = reference:Clone();
	end
	
	self.layout = self.instance:FindFirstChild("Layout");
	
	if self.layout then
		self.value_frame = self.layout:FindFirstChild("Value");
	else
		warn("Error occured when creating stylus instance: Layout frame does not exist.")
		print("Instance:", self.instance:GetFullName());
		
		for _, child in self.instance:GetDescendants() do
			print(child.Name, ":", child.ClassName);
		end;
		
		warn(debug.traceback());
	end
end

local function reparent(instance: Instance, parent: Instance?): ()
	instance.Parent = parent;
end;

function StylusBase:draw()
	assert(self.instance, "Needs instance");
	
	self.maid:add(self.instance.Destroying:Once(function()
		self.maid:destroy();
	end));
	
	self.maid:add(function()
		self:destroy();
	end);
	
	local text_label = self.layout.TextLabel;
	local text_box = self.value_frame:FindFirstChild("TextBox");
	local padding = self.instance:FindFirstChild("StylusPadding");
	local aspect_ratio = self.instance:FindFirstChild("StylusAspectRatio");
	local text_scale = self.defaults.text_scale or 0.85;
	
	self.instance.Visible = true;
	
	text_label.Text = self.defaults.text;
	text_label.TextWrapped = false;
	text_label.TextTruncate = Enum.TextTruncate.SplitWord;
	
	self.maid:add(self.stylus.bind_to_resize(text_label, function(size)
		text_label.TextSize = size.Y * text_scale;
	end));
	
	if self.defaults.height then
		self.instance.SizeConstraint = Enum.SizeConstraint.RelativeXX;
		self.instance.Size = UDim2.fromScale(1, self.defaults.height);
	end
	
	self.maid:add(self.stylus:bind_hover_highlight(self.instance, {
		Info = TweenInfo.new(0.25),
		Transparency = 0.9;
	}));
	
	if text_box then
		self.maid:add(self.stylus.bind_to_resize(text_box, function(size)
			text_box.TextSize = size.Y * text_scale;
		end));
	end
	
	if self.defaults.padding then
		if not padding then
			padding = Instance.new("UIPadding", self.instance);
			padding.Name = "StylusPadding";
		end;
		
		padding.PaddingTop = self.defaults.padding.Top or UDim.new(0, 0);
		padding.PaddingBottom = self.defaults.padding.Bottom or UDim.new(0, 0);
		padding.PaddingLeft = self.defaults.padding.Left or UDim.new(0, 0);
		padding.PaddingRight = self.defaults.padding.Right or UDim.new(0, 0);
	end

	if self.defaults.ui_ratio then
		if not aspect_ratio then
			aspect_ratio = Instance.new("UIAspectRatioConstraint", self.instance);
			aspect_ratio.Name = "StylusAspectRatio";
		end;
		
		aspect_ratio.AspectRatio = self.defaults.ui_ratio;
	end
	
	if self.defaults.tooltip then
		self.instance:SetAttribute("Tooltip", self.defaults.tooltip);
		self.instance:AddTag("UI-Tooltip");
	end
	
	if self.defaults.grayboxed ~= nil then
		self.gray_changed = Signal.new();
		
		self.gray_checkbox = Assets.Checkbox:Clone();
		self.gray_checkbox.LayoutOrder = -1;
		self.gray_checkbox.Parent = self.layout;

		self.gray_overlay = Assets.GrayboxOverlay:Clone();
		self.gray_overlay.Visible = false;
		self.gray_overlay.Parent = self.instance;

		self:set_grayboxed(self.defaults.grayboxed or false);

		self.gray_checkbox.Check.MouseButton1Click:Connect(function()
			self:set_grayboxed( not self.is_grayboxed );
		end)
	end;

	if self.defaults.theme then
		self:set_theme(self.defaults.theme);
	end

	task.defer(reparent, self.instance, self.defaults.parent);
end

function StylusBase:set_grayboxed(value: boolean)
	self.is_grayboxed = value;
	self.gray_overlay.Visible = value;

	local button = self.instance:FindFirstChildWhichIsA("GuiButton");

	if button then
		button.Interactable = not value;
	end;

	self.stylus:set_checkbox_icon(self.gray_checkbox.Check, not value);
	self.gray_changed:Fire(value);
end

function StylusBase:set_theme(theme_id: string)
	-- error("StylusBase:set_theme() is a virtual method", -2);
	
	local theme = self.__themes[theme_id];
	
	if theme then
		
		for _, item in self.instance.Layout:GetDescendants() do
			if item:GetAttribute("NoTheme") then
				continue;
			end;
			
			if item:IsA("TextBox") then
				item.BackgroundTransparency = theme.BoxTransparency or item.BackgroundTransparency;
				item.BackgroundColor3 = theme.BoxColor or item.BackgroundColor3;
				
			elseif item:IsA("GuiButton") then
				if item.Name ~= "Color" then
					item.BackgroundTransparency = theme.BoxTransparency or item.BackgroundTransparency;
					item.BackgroundColor3 = theme.BoxColor or item.BackgroundColor3;
				end;
				
			elseif item.Name == "Slider" then
				item.BackgroundTransparency = theme.BoxTransparency or item.BackgroundTransparency;
				item.BackgroundColor3 = theme.BoxColor or item.BackgroundColor3;
			end
		end
	end
end

function StylusBase:is_focused()
	local box = self.instance.Layout:FindFirstChild("TextBox");

	if box then
		return UserInputService:GetFocusedTextBox() == box
	end;
	
	return false;
end

function StylusBase:get_value()	
	error("StylusBase:get_value() is a virtual method", -2)
end

function StylusBase:set_value()	
	error("StylusBase:set_value() is a virtual method", -2)
end

function StylusBase:update()	
	error("StylusBase:update() is a virtual method", -2)
end

function StylusBase:init()	
	error("StylusBase:init() is a virtual method", -2)
end

table.freeze(StylusBase);

return StylusBase;