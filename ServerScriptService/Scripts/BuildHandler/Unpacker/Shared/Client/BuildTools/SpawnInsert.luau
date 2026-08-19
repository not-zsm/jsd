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

local SpawnInsert = {};
SpawnInsert.__index = SpawnInsert;

function SpawnInsert.new(build_tools)
	local maid = build_tools.maid:limb();
	
	local self = setmetatable(
		{
			maid = maid;
			build_tools = build_tools;
			enabled = false;
			
			tweens = {};
			
			main_ui = build_tools.elements.Main;
			context = build_tools.elements.Right.Explorer.Body.ContextMenu;
		}, 
		SpawnInsert);
	
	self:initialise_tweens();
	self:initialise();
	
	return self;
end;

export type SpawnInsert = typeof(SpawnInsert.new(...))

function SpawnInsert:destroy()
	table.clear(self.tweens);
	
	Table.dispose(self);
end

function SpawnInsert:create(class_name: string, layout_order: number?)
	local instance = self.build_tools.assets.ExplorerItem:Clone();
	instance.Body.List.Label.Text = class_name;
	instance.LayoutOrder = layout_order or 0;
	instance.Visible = true;
	instance.Name = class_name;
	instance.Body.Select.BackgroundTransparency = 1;
	instance.Body.List.Label.TextScaled = false;
	instance.Body.List.UIListLayout.Padding = UDim.new(0.025, 0);

	instance.Body.List.Expand:Destroy();
	instance.Body.ExpandLine:Destroy();
	instance.Children:Destroy();
	
	instance.Body.Select:AddTag("UI-ButtonClick");
	
	Stylus:set_sprite_icon(instance.Body.List.Icon, class_name);
	Stylus:bind_hover_highlight(instance.Body.Select);

	local Body = self.context.Body;

	local function update_size()
		instance.Body.Size = UDim2.new(1, 0, 0, 6 + Body.AbsoluteSize.Y * 0.065);
		instance.Body.List.Label.TextSize = instance.Body.List.Label.AbsoluteSize.Y * 0.8;
	end

	update_size();
	Body:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_size)

	instance.Body.Select.MouseButton1Click:Connect(function()
		if self.build_tools.selection:is_empty() then
			self.build_tools.actions:spawn(class_name, nil, nil, true);
		else
			for instance in self.build_tools.selection.items do
				self.build_tools.actions:spawn(class_name, instance, nil, true);
			end;
		end
	end);

	instance.Parent = Body.Body.ScrollingFrame;
	
	return instance;
end

function SpawnInsert:initialise()
	local insert_list = InstancesBuild.Insert:GetChildren();

	-- oh nah this sus
	table.insert(insert_list, Instance.new("Attachment"));

	for index, instance in insert_list do
		task.spawn(self.create, self, instance.Name, index);
	end;
	
	self.build_tools.elements.Explorer.SideContext.Top.OpenContext.MouseButton1Click:Connect(function()
		self:toggle();
	end)
	
	Searcher.new(self.context.Body.SearchBox, self.context.Body.Body.ScrollingFrame);
end

function SpawnInsert:initialise_tweens()
	local info = TweenInfo.new(0.15);
	local open_info = { Position = UDim2.new(1, 0), AnchorPoint = Vector2.new(1, 0) };
	local close_info = { Position = UDim2.new(1, 0), AnchorPoint = Vector2.new(0, 0) };

	self.tweens.open = TweenService:Create(self.context.Body, info, open_info);
	self.tweens.close = TweenService:Create(self.context.Body, info, close_info);

	self.tweens.close:Play();

	self.tweens.close.Completed:Connect(function(status)
		if (status == Enum.PlaybackState.Completed) then
			self.context.Visible = false;
		end;
	end)
end

function SpawnInsert:toggle(value: boolean?)
	if value == nil then
		value = not self.enabled
	end;
	
	if self.enabled ~= value then
		self.build_tools:close_all(self);
		self.enabled = value;
		
		if value then
			self.context.Visible = true;
			self.tweens.open:Play();
			
			SoundService:PlayLocalSound(self.build_tools.sounds.Flash);
		else
			self.tweens.close:Play();
		end;
	end;
end;

table.freeze(SpawnInsert);

return SpawnInsert;