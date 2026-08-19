local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer;

local Maid = require( ReplicatedStorage.Packages.Maid )
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local HelpInput = require( ReplicatedStorage.Packages.HelpInput )

local HoverTweenStyle = { Info = TweenInfo.new(0.2) };

local Item = {};
Item.__index = Item;
Item.pool = {};

local function get_asset(inventory, frame_type: string)
	return inventory.build_tools.assets[frame_type or "InventoryItem"];
end

function Item.new(inventory, index: number, info)
	local frame_type = get_asset(inventory, info.frame_type);
	local frame = frame_type:Clone();
	local maid = Maid.destroying(frame)
	
	local self = setmetatable(
		{
			inventory = inventory;
			index = index;
			info = info;
			frame = frame;
			maid = maid;
		}, 
		Item);
	
	maid:add(self);
	
	self:initialise();
	
	return self;
end;

function Item:update_equipped()
	local value = self.inventory.hotbar.equipped == self.index;
	
	self.frame.Button.UIStroke.Enabled = value;
	self.frame.Delete.Visible = not self.inventory.enabled and value;
end

function Item:set_index(index: number)
	self.index = index;
	
	local input = self.inventory.hotbar.inputs[self.index];
	
	if input then
		self.frame.Body.Slot.Text = HelpInput.DisplayInput(input);
	else
		self.frame.Body.Slot.Text = "-"
	end;
	
	self:update_equipped();
end

function Item:update_trashing()
	if self.inventory.is_trashing then
		self:set_color( Color3.fromRGB(80, 12, 12) )
	else
		self:set_color();
	end
end

function Item:initialise_as_slot()
	self.frame.Selected:Destroy();
	
	self:update_trashing();
	
	self.frame.Button.MouseButton1Click:Connect(function()
		if self.inventory.is_trashing then
			self.inventory.hotbar:unequip_slot(self.index);
		else
			self.inventory.hotbar:select(self.index);
		end
	end)
	
	self.frame.Delete.MouseButton1Click:Connect(function()
		self.inventory.hotbar:unequip_slot(self.index);
	end)
	
	self:set_index(self.index);
end;

function Item:initialise_as_item()
	self.frame.Delete:Destroy();
	self.frame.Body.Slot.Visible = false;
end

function Item:set_color(color: Color3?): ()
	if not color then
		color = get_asset(self.inventory, self.info.frame_type).Button.BackgroundColor3;
	end;
	
	self.frame.Button.BackgroundColor3 = color;
end

function Item:set_icon(asset)
	self.frame.Body.Icon.Image = asset;
end

function Item:set_tool_label(text: string, hover_only: boolean?)
	self.frame.Body.ToolLabel.Text = text;
	
	if hover_only then
		self.frame.Body.ToolLabel.Visible = false;
		
		self.frame.MouseEnter:Connect(function()
			self.frame.Body.ToolLabel.Visible = true;
		end)

		self.frame.MouseLeave:Connect(function()
			self.frame.Body.ToolLabel.Visible = false;
		end)
	else
		self.frame.Body.ToolLabel.Visible = true;
	end
end

function Item:initialise()
	if self.info.model then
		self.frame.Name = self.info.model.Name;
		self:set_tool_label(self.info.model.Name, not self:get_should_viewport_disabled())
		
		local icon = self.info.model:GetAttribute("Thumbnail");
		
		if icon then
			self:set_icon(icon)
		else
			self.frame.Body.Icon:Destroy();
		end;
		
		Stylus:bind_hover_highlight(self.frame.Button, HoverTweenStyle);
	end;
	
	self.viewport_camera = Instance.new("Camera");
	self.viewport_camera.FieldOfView = 35;
	self.viewport_camera.Parent = self:get_viewport();
	self.viewport_camera.Parent.CurrentCamera = self.viewport_camera;
	
	Item.pool[self] = true;
end

function Item:get_should_viewport_disabled()
	return self.info.model:GetAttribute("NoViewport");
end

function Item:get_viewport()
	return self.frame.Body.ViewportFrame;
end

function Item:set_viewport_enabled(value: boolean)
	if not self.info.model then
		return;
	end;
	
	local viewport = self:get_viewport();
	local viewport_model = viewport.Model;
	
	if value and not self:get_should_viewport_disabled() then
		self.viewport_enabled = true;
		
		if not self.viewport_model then
			self.viewport_model = self.info.model:Clone();
		end;
		
		for _, child in self.viewport_model:GetDescendants() do
			if child:IsA("Sound") then
				child.Playing = false;
			end;
		end;
		
		self.viewport_model.Name = "Model";
		self.viewport_model:PivotTo(CFrame.identity);
		self.viewport_model.Parent = viewport_model;

		local _, size = viewport_model:GetBoundingBox();
		
		self.viewport_camera.CFrame = CFrame.lookAt(size * Vector3.new(1, 1.5, 1) * 1.5, Vector3.zero);
	else
		self.viewport_enabled = false;
		self.viewport_camera.CFrame = CFrame.new(0, 1_000, 0);
	end
end

function Item:destroy()
	Item.pool[self] = nil;
	
	if self.viewport_model then
		self.viewport_model:Destroy();
		self.viewport_model = nil;
	end;
	
	self.viewport_camera = nil;
	self.frame:Destroy();
	self.maid:destroy();
end

table.freeze(Item);

RunService.PreRender:Connect(function(dt)
	debug.profilebegin("Viewport Spinners");
	
	local rotate = CFrame.Angles(0, math.rad(30) * dt, 0);
	
	for item in Item.pool do
		if item.viewport_enabled then
			item.viewport_camera.CFrame = rotate * item.viewport_camera.CFrame;
		end;
	end;
	
	debug.profileend();
end)

return Item;