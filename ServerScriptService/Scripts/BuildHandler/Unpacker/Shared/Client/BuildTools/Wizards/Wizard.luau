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
local Maid = require( ReplicatedStorage.Packages.Maid )
local Table = require( ReplicatedStorage.Packages.Table )
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local Signal = require( ReplicatedStorage.Packages.Signal )

local Wizard = {};
Wizard.__index = Wizard;

function Wizard.new(build_tools, frame, first_open_callback)
	local maid = build_tools.maid:limb();
	local ui = build_tools.ui.Wizards;
	local name = "Wizard";
	
	if typeof(frame) == "string" then
		name = frame;
		frame = ui:FindFirstChild(frame);
	else
		name = frame.Name;
	end;
	
	local self = setmetatable(
		{
			maid = maid;
			build_tools = build_tools;
			enabled = false;
			disable_selection = false;
			
			on_enable = Signal.new();
			active_maid = maid:limb();
			
			ui = ui;
			frame = frame;
			name = name;
		}, 
		Wizard);
	
	self:initialise();
	
	return self;
end;

function Wizard:initialise()
	if not self.frame then
		self.frame = Instance.new("Frame") -- Dummy
		self.frame.Name = self.name;
	end;
	
	self.frame.Visible = false;
	self.frame.Parent = self.ui;
	
	if self.frame:FindFirstChild("Close") then
		self.frame.Close.MouseButton1Click:Connect(function()
			self.build_tools.wizards:set(nil);
		end)
	end
end

function Wizard:destroy()
	local wizards_list = self.build_tools.wizards.wizards;
	local name = self:get_name();
	
	if wizards_list[name] then
		wizards_list[name] = nil;
	end
	
	Table.dispose(self);
end

function Wizard:get_name()
	return self.frame.Name;
end

function Wizard:click() end

function Wizard:toggle(value: boolean?)
	if value == nil then
		value = not self.enabled;
	end;
	
	if self.enabled ~= value then
		self.enabled = value;
		self.frame.Visible = value;
		
		if self.opens then
			self.opens:toggle(value);
		end;
		
		self.active_maid:clean();
		self.on_enable:Fire(value);
	end;
end

table.freeze(Wizard);

return Wizard;