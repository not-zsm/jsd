local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService")
local MaterialService = game:GetService("MaterialService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Maid = require( ReplicatedStorage.Packages.Maid );
local Table = require( ReplicatedStorage.Packages.Table );
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local Signal = require( ReplicatedStorage.Packages.Signal )
local Attributes = require( ReplicatedStorage.Packages.Attributes )
local HelpInput = require( ReplicatedStorage.Packages.HelpInput )
local Asset = require( ReplicatedStorage.Packages.Asset )
local Instances = require( ReplicatedStorage.Packages.Instances )
local Searcher = require( "./UI/Searcher" );
local Retrieve = require( "./SkillBuilder/Retrieve" );

local BuildShared = ReplicatedStorage:WaitForChild("BuildTools");
local Remotes = BuildShared:WaitForChild("Remotes");
local Builds = workspace:WaitForChild("Builds");
--local UI = script:FindFirstAncestorWhichIsA("ScreenGui");
--local MainUI = UI:WaitForChild("Main");
--local Assets = UI.BuildTools:WaitForChild("Assets");

local Dropdown = {};
Dropdown.target_size = UDim2.fromScale(0.65, 1);
Dropdown.__index = Dropdown;

function Dropdown.new(build_tools)
	local self = setmetatable(
		{
			build_tools = build_tools;
			frame = build_tools.assets.Dropdown:Clone();
			options = {};
			tweens = {};
			is_hovering = false;
			is_mounted = false;

			mount_hovers = 0;
			mount = nil;
			mount_maid = Maid.new();

			on_option_clicked = Signal.new();

			main_ui = build_tools.elements.Main;
		}, 
		Dropdown);
	
	self:initialise();
	
	return self;
end;

function Dropdown:initialise()
	do
		self.tweens.open = TweenService:Create(self.frame.Body, TweenInfo.new(0.25), {Position = UDim2.fromScale(0, 0.5)})
		self.tweens.close = TweenService:Create(self.frame.Body, TweenInfo.new(0.25), {Position = UDim2.fromScale(1, 0.5)})

		self.tweens.close.Completed:Connect(function(status)
			if (status == Enum.PlaybackState.Completed) then
				self.frame.Visible = false;
			end
		end)
	end
	
	Searcher.new(self.frame.Body.Search.Box, self.frame.Body.Items);
end

function Dropdown:clear()
	for _, option in self.options do
		option:Destroy();
	end;
	
	table.clear(self.options);
end

function Dropdown:destroy()
	self:clear();
	table.clear(self.tweens);
	table.clear(self);
end

function Dropdown:add_option(label, callback)
	if self.options[label] then
		return-- warn(`Option {label} already exists, did create option`);
	end;
	
	local option = self.build_tools.assets.DropdownOption:Clone();
	option.Name = label;
	option.Visible = true;
	
	option.Button.Text = label;
	option.Button.MouseButton1Click:Connect(function()
		self.on_option_clicked:Fire(label, option);
		
		if callback then
			callback();
		end;
	end);
	
	Stylus:bind_hover_highlight(option);
	option.Parent = self.frame.Body.Items
	
	self.options[label] = option;
	
	return option;
end

function Dropdown:update_position()
	if not self.mount then return end;
	
	local mount_abs_pos = self.mount.AbsolutePosition;
	local mount_abs_size = self.mount.AbsoluteSize;
	
	local mount_position = UDim2.fromOffset(mount_abs_pos.X, mount_abs_pos.Y + mount_abs_size.Y + 2);
	
	self.frame.Position = mount_position
end

function Dropdown:update_input(input, processed)
	if HelpInput.IsInteract(input) and not self.hovering_on_input then
		self:unmount();
	end
end

function Dropdown:mount_to(frame, aggregator, parent: (Instance | boolean)?)
	if not parent then
		parent = self.build_tools.ui;
		
	elseif typeof(parent) ~= "Instance" then
		parent = frame;
	end;
	
	self:unmount();
	
	self.aggregator = aggregator;
	self.mount = frame;
	self.is_mounted = true;
	self.hovering_on_input = Stylus:is_hovering_over_any{self.mount, self.frame, self.aggregator};
	
	if self.mount then
		self.mount_maid:add(self.mount:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			self:update_position();
		end))
		
		self.mount_maid:add(self.mount:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			self:update_position();
		end))
	end;
	
	self.mount_maid:add(UserInputService.InputBegan:Connect(function()
		self.hovering_on_input = Stylus:is_hovering_over_any{self.mount, self.frame, self.aggregator}
	end))
	
	self.mount_maid:add(UserInputService.InputEnded:Connect(function(input, processed)
		task.defer(self.update_input, self, input, processed);
	end))
	
	self:update_position();
	
	self.frame.Visible = true;
	
	if self.frame.Parent ~= parent then
		self.frame.Parent = parent;
	end;
end

function Dropdown:unmount(frame: GuiObject?)
	
	if not frame or self.mount == frame then
		self.mount_maid:clean();
		self.mount = nil;
		self.aggregator = nil;
		self.is_mounted = false;
		
		self:reset();
		self.tweens.close:Play();
	end;
end

function Dropdown:is_aggregated_by(instance)
	return self.aggregator == instance;
end

function Dropdown:is_enabled()
	return self.is_mounted;
end

function Dropdown:reset()
	-- self.frame.Size = UDim2.fromOffset(150, 250);
	
	self.target_size = nil;
	self.frame.Size = self.target_size;
end

function Dropdown:populate_with_materials(option_callback)
	self:clear();

	for _, material in MaterialService:GetDescendants() do
		if not material:IsA("MaterialVariant") then continue end;

		self:add_option(material.Name, function()
			option_callback(material);
		end)
	end;
end

function Dropdown:populate_with_enum(enum: Enum, option_callback)
	self:clear();

	for _, enum in enum:GetEnumItems() do
		self:add_option(enum.Name, function()
			option_callback(enum);
		end)
	end;
end

function Dropdown:populate_with_effects(option_callback)
	self:clear();
	
	local effects = Retrieve.get_effects();
	local effects_folder = ReplicatedStorage.BuildTools.Effects;
	local vfx_folder = ReplicatedStorage.Modules.Player.Replication.VFX;
	
	for _, effect in effects do
		local is_regular_effect = effect.Parent == effects_folder;
		local name = effect.Name;
		
		if is_regular_effect then
			name = Instances.get_directory(effect, effects_folder, "/");
		else
			name = Instances.get_directory(effect, vfx_folder, "/");
		end;
		
		local option = self:add_option(name, function()
			option_callback(name);
		end);
		
		if option then
			option.Size = UDim2.new(1, 0, 0.035, 6);
		end;
	end;
end;

function Dropdown:set_size(size: UDim2)
	self.target_size = size;
	self.frame.Size = size;
end;

function Dropdown:mount_to_properties(aggregator)
	self.build_tools:close_all_property_docks();
	self:mount_to(self.main_ui.BodyRight.Properties.Function, aggregator, true)
	
	self.frame.Position = UDim2.fromScale(1, 0);
	self.frame.AnchorPoint = Vector2.new(1, 0);
	self.frame.Size = self.target_size;
	
	SoundService:PlayLocalSound(self.build_tools.sounds.DockToggle);
	self.tweens.open:Play();
end

table.freeze(Dropdown);

return Dropdown;