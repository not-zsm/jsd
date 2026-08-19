local HelperWidget = require( "./UI/HelperWidget" );
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Signal = require( ReplicatedStorage.Packages.Signal )
local Stylus = require( ReplicatedStorage.Packages.Stylus )

local ValueList = {};
ValueList.__index = ValueList;

function ValueList.new(build_tools, widget_based)
	local maid = build_tools.maid:limb();
	
	local self = setmetatable(
		{
			maid = maid;
			build_tools = build_tools;
			
			selected = nil;
			on_selected = maid:add(Signal.new());
		}, 
		ValueList);
	
	if widget_based then
		self.widget = HelperWidget.new(build_tools);
	end;
	
	self:initialise();
	
	return self;
end;

function ValueList:destroy()
	if self.widget then
		self.widget:destroy();
	end;
end

function ValueList:create_item(properties)
	local defacto_name = tostring(properties.name or properties.value);
	
	local frame = self.build_tools.assets.BuilderValueItem:Clone();
	frame.Name = defacto_name;
	
	if properties.text then
		frame.Button.RichText = true;
		frame.Button.TextScaled = false;
		frame.Button.TextWrapped = false;
		frame.Button.Text = properties.text;
		
		Stylus.bind_to_resize(frame.Button, function(abs)
			frame.Button.TextSize = abs.Y * 0.6;
		end)
	else
		frame.Button.Text = defacto_name;
	end;
	
	if properties.text_alignment then
		frame.Button.TextXAlignment = properties.text_alignment;
	end;
	
	if properties.color then
		frame.Button.BackgroundColor3 = properties.color;
	else
		frame.Button.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
		frame.Button.BackgroundTransparency = 0.75;
	end;

	frame.Button.MouseButton1Click:Connect(function()
		if properties.callback then
			properties.callback( properties.value );
		else
			self:select( properties.value );
		end
	end)
	
	if properties.callback_m2 then
		local button: TextButton = frame.Button;
		
		button.TouchTap:Connect(function(touch_positions)
			if #touch_positions >= 2 then
				properties.callback_m2( properties.value );
			end
		end);
		
		button.MouseButton2Click:Connect(function()
			properties.callback_m2( properties.value );
		end);
	end;
	
	frame.Parent = self.frame.ScrollingFrame;
	
	return frame;
end;

function ValueList:clear_items()
	for _, item in self.frame.ScrollingFrame:GetChildren() do
		if item:IsA("Frame") then
			item:Destroy();
		end;
	end;
end;

function ValueList:load_items(items, color)
	self:clear_items();
	
	for _, item in items do
		local name = tostring(item);
		
		if typeof(item) == "EnumItem" then
			name = item.Name;
		end;
		
		self:create_item({ 
			name = name,
			value = item, 
			color = color,
		})
	end;
end

function ValueList:select(item)
	self.selected = item;
	self.on_selected:Fire(item)
end

function ValueList:search(text: string)
	local query_text = string.gsub(string.lower(text), "^[%s%c]*", "");

	for _, frame in self.frame.ScrollingFrame:GetChildren() do
		local frame_text = string.lower(frame.Name);

		if frame:IsA("GuiObject") then
			frame.Visible = string.match(frame_text, query_text) ~= nil;
		end;
	end;
end;

function ValueList:generate_color(name: string): Color3
	local hash = string.len(name) * 137;

	for index = 1, string.len(name) do
		hash = (hash * 31 + string.byte(name, index)) % 3 ^ 32
	end;

	local color = Color3.fromHSV((hash / 1000) % 1, 1, 1);

	return color;
end

function ValueList:toggle(value: boolean?)
	if not self.widget then return end;
	
	self.widget:toggle(value);
end;

function ValueList:initialise()
	self.frame = self.build_tools.assets.BuilderValueList:Clone();
	self.frame.Size = UDim2.fromScale(1, 1);
	self.frame.SizeConstraint = Enum.SizeConstraint.RelativeXY;
	
	if self.widget then
		self.frame.BackgroundTransparency = 1;
		self.frame.Parent = self.widget.main;
	end;
	
	self.frame.Search:GetPropertyChangedSignal("Text"):Connect(function()
		self:search(self.frame.Search.Text);
	end);
	
	Stylus.bind_to_resize(self.frame.Search, function(size)
		self.frame.Search.TextSize = size.Y * 0.7;
	end);
end

table.freeze(ValueList);

return ValueList;