local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer;
local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");
local Remotes = BuildPersistent:WaitForChild("Remotes");
local BuildAssets = BuildShared:WaitForChild("Assets");
local InstancesBuild = BuildAssets:WaitForChild("Build");

local NotificationStatus = require( BuildShared.Data.NotificationStatus )
local Searcher = require( script.Parent.UI.Searcher );
local Maid = require( ReplicatedStorage.Packages.Maid )
local Table = require( ReplicatedStorage.Packages.Table )
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local Asset = require( ReplicatedStorage.Packages.Asset )

local ModifierInsert = {};
ModifierInsert.__index = ModifierInsert;

function ModifierInsert.new(build_tools)
	local maid = build_tools.maid:limb();
	
	local self = setmetatable(
		{
			maid = maid;
			build_tools = build_tools;
			enabled = false;
			
			tweens = {};
			
			insert_ui = build_tools.ui.Modifiers;
			body = build_tools.ui.Modifiers.Body.Body;
		}, 
		ModifierInsert);
	
	self:initialise_tweens();
	self:initialise();
	
	return self;
end;

export type ModifierInsert = typeof(ModifierInsert.new(...))

function ModifierInsert:destroy()
	self.maid:destroy();
	table.clear(self.tweens);
	
	Table.dispose(self);
end

function ModifierInsert:create_option(info: any, callback)
	local option = self.build_tools.assets.ModifierOption:Clone();
	local maid = Maid.removing(option);

	Stylus:set_tooltip(option, info.tooltip);

	option.Title.Title.TextScaled = false;
	option.Title.SubTitle.TextScaled = false;
	option.Title.Title.Text = Asset.pretty_string(info.Title or "???");
	option.Title.SubTitle.Text = info.Description or "";
	option.Display.Icon.Image = Asset.get_rbx_asset(info.Icon);
	option.Highlight.BackgroundColor3 = info.Color or Color3.fromRGB(255, 255, 255)
	option.Name = info.Title or "?";
	option.Visible = not info.Hidden;
	
	option.UIPadding:AddTag("UI-AutoPadding");
	option.UIListLayout:AddTag("UI-AutoPadding");

	local function update_size()
		option.Title.Title.TextSize = 6 + self.body.AbsoluteSize.Y * 0.02;
		option.Title.SubTitle.TextSize = 6 + self.body.AbsoluteSize.Y * 0.015;
	end

	update_size();
	maid:add(self.body:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_size))

	option.MouseButton1Click:Connect(function()
		callback(option);
	end);

	return option;
end

function ModifierInsert:create_section(info: any)
	local section = self.build_tools.assets.ModifierOptionSection:Clone();
	local maid = Maid.removing(section);

	section.Title.Body.Title.Text = info.Title or "???";
	section.Title.Body.SubTitle.Text = info.SubTitle or "";
	section.Title.Body.Title.TextScaled = false;
	section.Name = section.Title.Body.Title.Text;
	section.Visible = true;

	--section.Title.UIPadding:AddTag("UI-AutoPadding");
	--section.UIPadding:AddTag("UI-AutoPadding");
	section.UIListLayout:AddTag("UI-AutoPadding");

	local function update_size()
		section.Title.Body.Title.TextSize = 6 + self.body.AbsoluteSize.Y * 0.03;
		section.Title.Body.SubTitle.TextSize = 6 + self.body.AbsoluteSize.Y * 0.02;
	end

	update_size();
	maid:add(self.body:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_size));

	section.MouseButton1Click:Connect(function()
		section.Body.Visible = not section.Body.Visible;
	end);

	local update_maid = Maid.removing(section);
	local body = section.Body;

	local function update_children()
		update_maid:clean();

		local should_be_visible = false;

		for _, child in body:GetChildren() do
			if child:IsA("GuiObject") then
				update_maid:add(child:GetPropertyChangedSignal("Visible"):Connect(update_children))

				if not should_be_visible and child.Visible then
					should_be_visible = true;
				end
			end;
		end;

		section.Visible = should_be_visible;
	end

	task.spawn(update_children);
	body.ChildRemoved:Connect(update_children);
	body.ChildAdded:Connect(update_children);

	return section;
end

function ModifierInsert:initialise()

	self.build_tools.elements.Modifiers.Add.MouseButton1Click:Connect(function()
		self:toggle();
	end)
	
	self.body.Title.Close.Button.MouseButton1Click:Connect(function()
		self:toggle(false);
	end)
	
	self.body.Filter.Search:GetPropertyChangedSignal("Text"):Connect(function()
		self:search(self.body.Filter.Search.Text);
	end)
	
	self.build_tools.modifiers.bind_to_data_load(function()
		self:load_all();
	end)
end

function ModifierInsert:search(text: string)
	local clean_text = string.lower(tostring(text) or "");
	local empty_query = clean_text == "";
	
	for _, section in self.body.Items.List:GetChildren() do

		if section:IsA("GuiObject") then
			local sub_option_is_visible = false;
			
			for _, option in section.Body:GetChildren() do
				if not option:IsA("GuiObject") then
					continue;
				end;
				
				if string.match(string.lower(option.Name), clean_text) then
					local data = self.build_tools.modifiers.get_data_from_tag(option.Name);
					
					if empty_query and data and data.Hidden then
						option.Visible = false;
					else
						option.Visible = true;
					end;
					
					sub_option_is_visible = true;
				else
					option.Visible = false;
				end
			end
			
			section.Visible = sub_option_is_visible;
		end;
	end;
end

function ModifierInsert:load_all()
	local sections = {};
	local modifiers = self.build_tools.modifiers;
	
	for index, info in modifiers.data.sections do
		sections[index] = self:create_section(info);
		sections[index].LayoutOrder = info.Layout or index;
	end
	
	local function create_modifier_frame(info)
		local frame = self:create_option(info, function(option)
			self.build_tools.actions:add_modifier(self.build_tools.selection:get(), info.Title)
		end)
		
		if info.Section and sections[info.Section] then
			frame.Parent = sections[info.Section].Body;
		end;
	end

	for index, info in modifiers.data.list do
		if self.build_tools.marketplace:has_owned(info.NeedsProduct, info.NeedsGamepass) then
			create_modifier_frame(info);
		else
			self.build_tools.marketplace:bind_to_owned(info.NeedsProduct, info.NeedsGamepass, function()
				create_modifier_frame(info);
			end)
		end;
	end

	for index, section in sections do
		section.Parent = self.body.Items.List;
	end;
end

function ModifierInsert:initialise_tweens()
	local info = TweenInfo.new(0.15);
	local open_info = {GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5)};
	local close_info = {GroupTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.25)};

	self.tweens.open = TweenService:Create(self.insert_ui.Body, info, open_info);
	self.tweens.close = TweenService:Create(self.insert_ui.Body, info, close_info);

	self.tweens.close:Play();

	self.tweens.close.Completed:Connect(function(status)
		if (status == Enum.PlaybackState.Completed) then
			self.insert_ui.Enabled = false;
		end;
	end);
end

function ModifierInsert:toggle(value: boolean?)
	if value == nil then
		value = not self.enabled
	end;
	
	if self.enabled ~= value then
		self.build_tools:close_all(self);
		self.enabled = value;
		
		if value then
			self.insert_ui.Enabled = true;
			self.tweens.open:Play();
			
			Stylus:tween_blur(15);
			SoundService:PlayLocalSound(self.build_tools.sounds.Flash);
		else
			Stylus:tween_blur(0);
			self.tweens.close:Play();
		end;
	end;
end;

table.freeze(ModifierInsert);

return ModifierInsert;