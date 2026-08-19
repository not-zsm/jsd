-- Client representation of a Modifier to hook displays.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")

local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");
local BuildAssets = BuildShared:WaitForChild("Assets");
local Remotes = BuildPersistent:WaitForChild("Remotes");

local Maid = require( ReplicatedStorage.Packages.Maid )
local Signal = require( ReplicatedStorage.Packages.Signal )
local Asset = require( ReplicatedStorage.Packages.Asset )

local visual_y_scale = script:WaitForChild("ModifierVisualUI").Size.Y.Scale;
local visual_sort_queue = {};

local unknown_tag_data = table.freeze{ 
	Title = "Unknown";
	Icon = 10653378249,
	Color = Color3.fromRGB(255, 255, 255)
};

local Modifiers = {};
Modifiers.__index = Modifiers;
Modifiers.data = {};
Modifiers.data_tag_map = {};
Modifiers.data_loaded = Signal.new();
Modifiers.pool = {};
Modifiers.pool_parts = {};

local function remove_from_part_pool(part: BasePart, instance: any): ()
	if Modifiers.pool_parts[part] then
		Modifiers.pool_parts[part][instance] = nil;

		if not next(Modifiers.pool_parts) then
			Modifiers.pool_parts[part] = nil;
		end;
	end;
end

local function add_to_part_pool(part: BasePart, instance: any): ()
	if not Modifiers.pool_parts[part] then
		Modifiers.pool_parts[part] = {};
	end;

	Modifiers.pool_parts[part][instance] = true;
end;

function Modifiers.get_data_from_tag(tag: string)
	if tag then
		local tag_data = Modifiers.data_tag_map[ string.lower(tag) ];
		
		if tag_data then
			return tag_data;
		end;
	end;
	
	return unknown_tag_data;
end

function Modifiers.request()
	print("[Build Tools]: Requesting Instance Modifiers");
	
	task.spawn(function()
		local data = Remotes.RequestInstanceModifiers:InvokeServer();
		
		if data then
			table.clear(Modifiers.data);
			table.clear(Modifiers.data_tag_map);
			
			Modifiers.data.list = data.list;
			Modifiers.data.sections = data.sections;
			
			for index, value in data.list do
				if value.Title then
					Modifiers.data_tag_map[ string.lower(value.Title) ] = value;
				end;
			end;
			
			Modifiers.data_loaded:Fire();
		end;
	end)
end

function Modifiers.bind_to_data_load(callback)
	if not next(Modifiers.data) then
		Modifiers.data_loaded:Once(callback);
	else
		task.spawn(callback);
	end
end

function Modifiers.set_all_visible(visible: boolean, visualiser: boolean?, beam_visualiser: boolean?): ()
	for modifier in Modifiers.pool do
		modifier:set_beams_enabled(visible and beam_visualiser);
		modifier:set_visualiser_enabled(visible and visualiser);
	end;
end

function Modifiers.new(build_tools, modifier: Configuration)
	local self = setmetatable(
		{
			build_tools = build_tools;
			maid = Maid.light();
			modifier = modifier;
			data = Modifiers.get_data_from_tag(modifier:GetAttribute("Modifier"));
			
			part = nil;
			beams_visualised = false;
			visualised = false;
		}, 
		Modifiers);
	
	self:initialise();
	
	Modifiers.pool[self] = true;
	
	return self;
end;

function Modifiers:destroy()
	local part = self.part;
	
	Modifiers.pool[self] = nil;
		
	self:remove_beams();
	
	if self.visual_ui then
		self.visual_ui:Destroy();
		self.visual_ui = nil;
	end

	if self.visual_box then
		self.visual_box:Destroy();
		self.visual_box = nil;
	end
	
	self.visualised = false;
	self.maid:destroy();
	
	if part then
		remove_from_part_pool(part, self);
		Modifiers.sort_visualisers(part);
	end;
end;

local function sort_visualisers(part: BasePart): ()
	if not Modifiers.pool_parts[part] then
		return;
	end;
	
	local order = {};

	for modifier in Modifiers.pool_parts[part] do
		if modifier.visualised then
			table.insert(order, modifier);
		end;
	end;

	table.sort(order, function(a, b)
		return a.data.Title > b.data.Title;
	end);

	for index, modifier in order do
		modifier.visual_ui.StudsOffset = Vector3.new(0, (visual_y_scale + 0.25) * (index - 1), -0.01);

		if index ~= 1 and modifier.visual_box then
			modifier.visual_box:Destroy();
			modifier.visual_box = nil;
		end;
	end;
	
	local modifier = order[1];
	
	if modifier and not modifier.visual_box then
		modifier.visual_box = script.ModifierVisualBox:Clone();
		modifier.visual_box.Archivable = false;
		modifier.visual_box.Visible = true;
		modifier.visual_box.Color3 = modifier:get_color();
		modifier.visual_box.Adornee = part;
		modifier.visual_box.Parent = part;
	end
end;

function Modifiers.sort_visualisers(part: BasePart?): ()
	if part and Modifiers.pool_parts[part] and not visual_sort_queue[part] then
		visual_sort_queue[part] = task.defer(function()
			visual_sort_queue[part] = nil;
			sort_visualisers(part);
		end)
	end
end

function Modifiers:get_color(): Color3
	if self.data.Color then
		return self.data.Color;
	else
		return Color3.fromRGB(255, 255, 255);
	end;
end;

function Modifiers:set_beams_enabled(value: boolean): ()
	self.beams_visualised = value;
	
	if value then
		self:add_beams();
	end
	
	if self.beam then
		self.beam.Enabled = value;
	end;
end

function Modifiers:set_visualiser_enabled(value: boolean): ()
	if not self.part then return end;
	
	self.visualised = value;
	
	if value then
		local color = self:get_color();
		
		if not self.visual_ui then
			self.visual_ui = script.ModifierVisualUI:Clone();
			self.visual_ui.Archivable = false;
			
			if typeof(self.data.Icon) == "number" then
				self.visual_ui.Icon.Image = Asset.get_decal_id(tostring(self.data.Icon))
			else
				self.visual_ui.Icon.Image = self.data.Icon;
			end;
			
			self.visual_ui.Icon.ImageColor3 = color;
			self.visual_ui.Adornee = self.part;
			self.visual_ui.Enabled = true;
			self.visual_ui.Parent = self.part;
		end
		
		Modifiers.sort_visualisers(self.part);
	end;
	
	if self.visual_ui then
		self.visual_ui.Enabled = value;
	end;
	
	if self.visual_box then
		self.visual_box.Visible = value;
	end;
end

function Modifiers:get_inlet(part: BasePart)
	local inlet = part:FindFirstChild("Inlet") :: Attachment;

	if not inlet then
		inlet = Instance.new("Attachment");
		inlet.Name = "Inlet";
		inlet.Archivable = false;
		inlet.Parent = part;
	end;
	
	return inlet;
end

function Modifiers:update_inlet()
	if self.part then
		self.inlet = self:get_inlet(self.part);
	else
		self.inlet = nil;
	end;
	
	if self.beam then
		self.beam.Attachment0 = self.inlet;
	end
end;

function Modifiers:update_part()
	local last_part = self.part;
	local new_part = self.modifier:FindFirstAncestorWhichIsA("BasePart");
	
	if (new_part ~= last_part) then
		remove_from_part_pool(last_part, self);
		
		if new_part then
			add_to_part_pool(new_part, self);
		end;
		
		self.part = new_part;
		
		self:update_inlet();
		self:update_all_visualisers();
	end;
end;

function Modifiers:update_all_visualisers()
	self:set_beams_enabled(self.build_tools.enabled and self.build_tools.preferences:get("visualise_beams"));
	self:set_visualiser_enabled(self.build_tools.enabled and self.build_tools.preferences:get("visualise_modifiers"));
end

function Modifiers:initialise()
	self:update_part();
	
	self.maid:add(self.modifier.AncestryChanged:Connect(function()
		self:update_part();
	end));

	local function child_added(child: Instance): ()
		if (child.Name == "?Output") then
			self:initialise_output(child);
		end
	end
	
	for _, child: Instance in self.modifier:GetChildren() do
		child_added(child);
	end;
	
	self.maid:add(self.modifier.ChildAdded:Connect(child_added));
end

function Modifiers:remove_beams()
	if self.beam then
		self.beam:Destroy();
		self.beam = nil;
	end;
end;

function Modifiers:add_beams()
	if self.beam or not ( self.outlet and self.inlet and self.inlet ~= self.outlet ) then return end;
	
	self.beam = BuildAssets.Client.InputBeam:Clone();
	self.beam.Attachment0 = self.inlet
	self.beam.Attachment1 = self.outlet
	self.beam.Archivable = false;
	self.beam.Enabled = true;

	if self.data.Color then
		self.beam.Color = ColorSequence.new(self.data.Color)
	end
	
	self.beam.Parent = self.modifier;
end;

function Modifiers:update_output(output: ObjectValue)
	self:remove_beams();
	
	if output.Value then
		self.target_part = if output.Value:IsA("BasePart") then output.Value else output.Value:FindFirstAncestorWhichIsA("BasePart");
		
		if self.target_part then
			self.outlet = self:get_inlet(self.target_part);
			
			self:add_beams();
			self:update_all_visualisers();
		end;
	else
		self.target_part = nil;
	end;
end

function Modifiers:initialise_output(output: ObjectValue)
	self:update_output(output);
	
	self.maid:add(output.Changed:Connect(function()
		self:update_output(output);
	end))
end

table.freeze(Modifiers);

return Modifiers;