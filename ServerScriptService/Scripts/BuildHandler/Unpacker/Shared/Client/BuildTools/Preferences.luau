local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Builds = workspace:WaitForChild("Builds");

local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");
local Remotes = BuildPersistent:WaitForChild("Remotes");
local BuildAssets = BuildShared:WaitForChild("Assets");

local Build = require( ReplicatedStorage.BuildTools.Build )
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local PreferenceInfo = require( BuildShared.Data.Preferences );

local Preferences = {};
Preferences.__index = Preferences;

function Preferences.new(build_tools)
	local self = setmetatable(
		{
			build_tools = build_tools;
			enabled = false;
			info_enabled = false;
			
			tweens = {};
			frames = {};
			sections = {};
			
			ui = build_tools.ui.Preferences;
			body = build_tools.ui.Preferences.Body;
			info = build_tools.ui.Preferences.Info;
		}, 
		Preferences);
	
	self:initialise_tweens();
	self:initialise();
	
	return self;
end;

function Preferences:initialise()
	for attribute, value in PreferenceInfo.data do
		self:create_preference(attribute);
	end
	
	Build.stream:bind_to_synchronise(function()
		for attribute, value in PreferenceInfo.data do
			if Build.stream:get({"Preferences", attribute}) == nil then
				Build.stream:raw_set({"Preferences", attribute}, value.default);
			end;
		end;
	end)
	
	self.build_tools.elements.LinkButtons.Preferences.MouseButton1Click:Connect(function()
		self:toggle();
	end)
	
	self.body.Body.Title.Close.MouseButton1Click:Connect(function()
		self:toggle(false);
	end)
	
	local function update_info_position()
		local position = self.body.AbsolutePosition + Vector2.new(self.body.AbsoluteSize.X + 4, 0);
		self.info.Position = UDim2.fromOffset(position.X, position.Y);
	end
	
	update_info_position()
	self.body:GetPropertyChangedSignal("AbsolutePosition"):Connect(update_info_position)
end

function Preferences:initialise_tweens()
	local info = TweenInfo.new(0.15);
	local open_info = {GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5)};
	local close_info = {GroupTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.25)};
	
	self.tweens.open = TweenService:Create(self.body, info, open_info);
	self.tweens.close = TweenService:Create(self.body, info, close_info);

	self.tweens.close:Play();

	self.tweens.close.Completed:Connect(function(status)
		if (status == Enum.PlaybackState.Completed) then
			self.ui.Enabled = false;
		end;
	end)
end

function Preferences:create_section(info)
	if self.sections[info] then 
		return self.sections[info] 
	end;
	
	local section = self.build_tools.assets.PreferencesSection:Clone();
	section.Description.Text = info.title;
	section.LayoutOrder = info.order or 0;
	section.Parent = self.body.Body.ItemsFrame;
	
	self.sections[info] = section;
	
	return section;
end

function Preferences:set(name: string, value: any): ()
	Remotes.SetPreference:FireServer(name, value);
end

function Preferences:get(name: string)
	local value = Build.stream:get({"Preferences", name});
	
	if (value == nil) then
		return PreferenceInfo.defaults[name];
	end;
	
	return value;
end

function Preferences:observe(name: string, callback): RBXScriptConnection
	if not PreferenceInfo.data[name] then
		warn(`{name} is not a valid preference`);
	end;
	
	return Build.stream:observe({"Preferences", name}, function()
		callback(self:get(name));
	end)
end

function Preferences:update_info(info)
	self.info.Body.Items.Icon.Image = info.image or "rbxassetid://13159725931";
	self.info.Body.Items.Title.Text = info.title;
	self.info.Body.Items.Description.Text = info.description;
end

function Preferences:toggle_info(value: boolean?)
	if (value == nil) then
		value = not self.info_enabled;
	end
	
	if self.info_enabled ~= value then
		self.info_enabled = value;
		self.info.Visible = true;
		
		if self.info_enabled then
			local open_tween = TweenService:Create(self.info, TweenInfo.new(0.1), {GroupTransparency = 0})
			open_tween:Play();
		else
			local close_tween = TweenService:Create(self.info, TweenInfo.new(0.1), {GroupTransparency = 1})
			close_tween:Play();
		end
	end
end

function Preferences:create_preference(name)
	local data = PreferenceInfo.data[name];
	
	if not data or self.frames[name] or not data.section then
		return;
	end
	
	local section = self:create_section(data.section);
	local preference = self.build_tools.assets.PreferenceFrame:Clone();
	local stylus_box: Stylus.StylusBase;
	
	if typeof(data.default) == "boolean" then
		stylus_box = Stylus:new_checkbox({
			text = data.title;
			toggled = self:get(name);
			parent = preference;
			theme = "bg_transparent";
		})
		
		stylus_box.maid:add(Build.stream:observe({"Preferences", name}, function(key, value)
			stylus_box:toggle(value);
		end))
	else
		stylus_box = Stylus:new_stringbox({
			text = data.title;
			value = self:get(name);
			ratio = 1.25;
			parent = preference;
			theme = "bg_transparent";
		})
		
		stylus_box.maid:add(Build.stream:observe({"Preferences", name}, function(key, value)
			stylus_box:set_text(value);
		end))
	end
	
	if stylus_box then
		stylus_box.interacted:Connect(function(value)
			Remotes.SetPreference:FireServer(name, value);
		end);
		
		stylus_box.maid:add(stylus_box.instance.MouseEnter:Connect(function()
			self:update_info(data);
			self:toggle_info(true);
		end));
		
		--stylus_box.maid:add(stylus_box.instance.MouseLeave:Connect(function()
		--	self:toggle_info(false);
		--end));
	end;
	
	preference.LayoutOrder = data.layout_order or 1;
	preference.Visible = true;
	preference.Parent = section.Body;
	
	return preference;
end

function Preferences:toggle(value: boolean?)
	if value == nil then
		value = not self.enabled
	end;
	
	if self.enabled ~= value then
		self:toggle_info(false);
		self.build_tools:close_all(self);
		self.enabled = value;
		
		if value then
			self.ui.Enabled = true;
			self.tweens.open:Play();
			
			Stylus:tween_blur(15);
			SoundService:PlayLocalSound(self.build_tools.sounds.Flash);
		else
			self.tweens.close:Play();
			
			Stylus:tween_blur(0);
		end;
	end;
end;

function Preferences:destroy()
	table.clear(self.tweens);
	table.clear(self.frames)
	table.clear(self.sections);
	
	table.clear(self);
end

table.freeze(Preferences);

return Preferences;