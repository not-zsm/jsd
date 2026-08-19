local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local BuildTools = script.Parent.Parent;
local Builds = workspace:WaitForChild("Builds");
local Assets = BuildTools:WaitForChild("Assets");
local Sounds = BuildTools:WaitForChild("Sounds");
local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");
local Remotes = BuildPersistent:WaitForChild("Remotes");
local BuildAssets = BuildShared:WaitForChild("Assets");

local Schema = require( BuildTools.Schema );
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local PreferenceInfo = require( BuildShared.Data.Preferences );
local HelpInput = require( ReplicatedStorage.Packages.HelpInput )

local Help = {};
Help.__index = Help;

function Help.new(build_tools)
	local self = setmetatable(
		{
			build_tools = build_tools;
			enabled = false;
			
			ui = build_tools.elements.Help;
			body = build_tools.elements.Help.Body;
			
			tweens = {};
		}, 
		Help);
	
	self:initialise_tweens();
	self:initialise();
	
	return self;
end;

function Help:initialise_tweens()
	local info = TweenInfo.new(0.15);
	local open_info = {GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5)};
	local close_info = {GroupTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.25)};
	
	self.tweens.open = TweenService:Create(self.body, info, open_info);
	self.tweens.close = TweenService:Create(self.body, info, close_info);

	self.tweens.close:Play();

	self.tweens.close.Completed:Connect(function(status)
		if (status == Enum.PlaybackState.Completed) then
			self.ui.Enabled = false;
			self.body.Position = UDim2.fromScale(0.5, 0.5);
		end;
	end)
end

function Help:destroy()
	table.clear(self.tweens);
	table.clear(self);
end

function Help:initialise()
	self.build_tools.elements.Main.BodyLeft.Links.Help.MouseButton1Click:Connect(function()
		self:toggle();
	end)
	
	local function create_keybind_display(input: string, action: string)
		local label = self.body.Body.Body.Keybinds.KeybindDefault:Clone();
		label.Text = `<b>{input}</b> - {action}`;
		label.Visible = true;
		label.Name = "Keybind";
		label.Parent = self.body.Body.Body.Keybinds;
		
		return label;
	end;
	
	create_keybind_display("Ctrl+M1", "Persistent Selection");
	create_keybind_display("Alt+M1", "Raw Selection");
	create_keybind_display("Alt+Scale", "Local Part Scaling");
	create_keybind_display("Ctrl+Alt+Scale", "Opposite Face Scaling");
	create_keybind_display("M2", "Parent Into (Explorer Only)");
	create_keybind_display("Double Jump", "Toggle Flight");
	
	for index, info in Schema.data do
		local ctrl = if info.control then "Ctrl+" else "";
		local alt = if info.alt then "Alt+" else "";
		local keys: {string} = {};
		
		if typeof(info.keys) ~= "table" then
			table.insert(keys, HelpInput.DisplayInput(info.keys));
		else
			for index, key in info.keys do
				table.insert(keys, HelpInput.DisplayInput(key));
				table.insert(keys, if index ~= #info.keys then "/" else "");
			end
		end
		
		create_keybind_display(`{ctrl}{alt}{ table.concat(keys) }`, info.text);
	end;
end

function Help:toggle(value: boolean?)
	if value == nil then
		value = not self.enabled
	end;
	
	if self.enabled ~= value then
		self.build_tools:close_all(self);
		self.enabled = value;
		
		if value then
			self.ui.Enabled = true;
			self.tweens.open:Play();
			
			Stylus:tween_blur(15);
			SoundService:PlayLocalSound(Sounds.Flash);
		else
			self.tweens.close:Play();
			
			Stylus:tween_blur(0);
		end;
	end;
end;

table.freeze(Help);

return Help;