local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local BuildTools = script.Parent;
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
local InstanceCache = require( ReplicatedStorage.Packages.InstanceCache )
local PropertyTable = require( BuildShared.Data.Properties )
local PropertyCustom = require( BuildShared.Data.Properties.Custom )
local PropertySection = require( BuildShared.Data.Properties.Section )
local Searcher = require( BuildTools.UI.Searcher );
local Type = require( ReplicatedStorage.Packages.Type )
local Table = require( ReplicatedStorage.Packages.Table )
local Maid = require( ReplicatedStorage.Packages.Maid )

local Properties = {};
Properties.__index = Properties;

function Properties.new(build_tools)
	local self = setmetatable(
		{
			build_tools = build_tools;
			enabled = false;
			
			ui = build_tools.elements.Properties;
			list = build_tools.elements.PropertiesScrolling;
			
			items = {};
			sections = {};
		}, 
		Properties);
	
	self:initialise();
	
	return self;
end;

function Properties:destroy()
	self:clear();
	table.clear(self);
end;

function Properties:clear()
	for child, stylus_box in self.items do
		child.Visible = false;
		child:SetAttribute("Hide", true);
		
		stylus_box:destroy();
		self.cache:release(child, true);
		
	end

	for _, section in self.sections do
		section.Visible = false;
		section:SetAttribute("Hide", true);
	end

	table.clear(self.items);
end

function Properties:create_section(info)
	local section = self.sections[info.Title];

	if not section then
		section = Assets.PropertySection:Clone();
		section.Name = info.Title;
		section.Title.Text = info.Title;
		section.LayoutOrder = info.LayoutOrder;
		section.Visible = false;
		section.Parent = self.list;
		
		local function update_size()
			section.Title.Size = UDim2.new(1, 0, 0, 10 + self.list.AbsoluteSize.Y * 0.04);	
		end;

		task.defer(update_size);
		
		self.list:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_size);
		self.sections[info.Title] = section;
	end;
	
	return section;
end

function Properties.get_section_for(property: string)
	local default;

	for info, map in PropertySection.Any do
		if map[property] then
			return info;

		elseif info.Title == "Data" then
			default = info;
		end;
	end;

	return default;
end

function Properties:create_property(instance: Instance, property: string, value: any)
	debug.profilebegin("PropertyFrame");
	
	local build_tools = self.build_tools;
	local value_type = typeof(value);
	local value_form;

	if (value_type == "EnumItem") then
		value_form = Type.enum(value.EnumType);

	elseif Type[value_type] then
		value_form = Type[value_type]();

	else
		value_form = Type.string;
	end
	
	local button = self.cache:get();
	button.Name = property;

	local function commit_change(text: string)
		local new_value = value_form:cast(text);

		for instance in build_tools.selection.items do
			build_tools.actions:modify(instance, {[property] = new_value});
		end;
	end

	local tooltip = nil;
	local stylus_box;

	if value_type == "boolean" then

		stylus_box = Stylus:new_checkbox({
			text = property;
			toggled = value;
			parent = button.Body;
			theme = "bg_transparent";
			ratio = 0.6;
		})

		stylus_box.interacted:Connect(function(value)
			for instance in build_tools.selection.items do
				build_tools.actions:modify(instance, {[property] = value});
			end;
		end)
		
		stylus_box:on_property_changed(instance, property, function(value)
			stylus_box:set_value(value);
		end)

	elseif value_type == "nil" or value_type == "Instance" then

		stylus_box = Stylus:new_instancebox({
			text = property;
			value = value;
			holder_text = property;
			tooltip = tooltip;
			parent = button.Body;
			theme = "bg_transparent";
			ratio = 0.6;
		})

		stylus_box.interacted:Connect(function(value)
			for instance in build_tools.selection.items do
				build_tools.actions:modify(instance, {[property] = Table.nullable(stylus_box.value)});
			end;
		end)
		
		stylus_box:on_property_changed(instance, property, function(value)
			stylus_box:set_value(value);
		end)

	elseif value_type == "NumberSequence" then
		stylus_box = Stylus:new_stringbox({
			text = property;
			value = "<...>";
			holder_text = property;
			tooltip = tooltip;
			parent = button.Body;
			theme = "bg_transparent";
			button_based = true;
			ratio = 0.6;
		});

		stylus_box.focus_start:Connect(function()
			build_tools.number_editor:set_sequence(instance[property]);
		end)

		build_tools.number_editor:bind_stringbox(stylus_box, function(sequence: NumberSequence)
			for instance in build_tools.selection.items do
				build_tools.actions:modify(instance, {[property] = sequence});
			end;
		end)

	elseif property == "Texture" or property == "SoundId" or ( string.match(property, "TextureId$") or string.match(property, "^Skybox..$") ) then
		stylus_box = Stylus:new_stringbox({
			text = property;
			value = Type.stringenum:cast(value);
			holder_text = property;
			tooltip = tooltip;
			parent = button.Body;
			theme = "bg_transparent";
			dropdown_visible = true;
			ratio = 0.6;
		})
		
		stylus_box.interacted:Connect(commit_change);
		
		local asset_type = Enum.AssetType.Decal;
		
		if property == "SoundId" then
			asset_type = Enum.AssetType.Audio;
			
			button.UIListLayout.Padding = UDim.new(0.05, 0);
			
			local musicbox = Stylus:new_musicbox({
				text = "";
				value = value,
				parent = button,
				theme = "bg_transparent";
				ratio = 0.1;
				text_scale = 0.75;
			});

			musicbox.layout.TextLabel.Visible = false;
			musicbox.instance.Size = button.Body.Size;
			
			if instance:IsA("Sound") then
				musicbox:set_audio_referenced(instance) -- W
			end;
			
			stylus_box.maid:add(musicbox);
		end;
		
		local function open_toolbox()
			if build_tools.toolbox.affector_instance ~= stylus_box.instance then
				build_tools.toolbox:toggle(true, asset_type);
				build_tools.toolbox.affector_instance = stylus_box.instance;
			else
				build_tools.toolbox:toggle(false);
			end;
		end

		stylus_box:bind_to_dropdown(open_toolbox);

		build_tools.toolbox:bind_stringbox(stylus_box, function(asset_id: number)
			for instance in build_tools.selection.items do
				build_tools.actions:modify(instance, {[property] = tostring(asset_id)});
			end;
		end);
		
		stylus_box:on_property_changed(instance, property, function(value)
			stylus_box:set_text( value );
		end);

	elseif value_type == "Color3" or value_type == "ColorSequence" then
		stylus_box = Stylus:new_colorbox({
			text = property;
			value = Type.string:cast(value);
			holder_text = property;
			tooltip = tooltip;
			parent = button.Body;
			theme = "bg_transparent";
			ratio = 0.6;
		})

		stylus_box:set_color( value )

		build_tools.hue_picker:bind_colorbox(stylus_box, function(color: Color3)
			stylus_box:set_color( color );

			if value_type == "ColorSequence" then
				color = ColorSequence.new(color) :: any;
			end;

			for instance in build_tools.selection.items do
				build_tools.actions:modify(instance, {[property] = color});
			end;
		end)
		
		stylus_box:on_property_changed(instance, property, function(value)
			stylus_box:set_color( value );
		end)

	elseif value_type == "CFrame" then
		stylus_box = Stylus:new_stringbox({
			text = property;
			holder_text = property;
			tooltip = tooltip;
			parent = button.Body;
			theme = "bg_transparent";
			button_based = true,
			ratio = 0.6;
		})
		
		local position_body = Assets.PropertyFrame.Body:Clone();
		position_body.Name = "PositionBody";
		position_body.Parent = button;

		local position_box = Stylus:new_stringbox({
			text = "	Position";
			holder_text = property;
			tooltip = tooltip;
			parent = position_body;
			theme = "bg_transparent";
			ratio = 0.6;
		})

		stylus_box.maid:add(position_box);

		position_box.interacted:Connect(function(text)
			local offset = Type.Vector3:cast(text) or Vector3.zero;

			for instance in build_tools.selection.items do
				build_tools.actions:modify(instance, {[property] = instance[property].Rotation + offset});
			end;
		end)

		position_box.maid:add(function()
			position_body.Parent = nil;
		end)

		local angle_body = Assets.PropertyFrame.Body:Clone();
		angle_body.Name = "AngleBody";
		angle_body.Parent = button;

		local angle_box = Stylus:new_stringbox({
			text = "	Orientation";
			holder_text = property;
			tooltip = tooltip;
			parent = angle_body;
			theme = "bg_transparent";
			ratio = 0.6;
		})

		angle_box.interacted:Connect(function(text)
			local vec = (Type.Vector3:cast(text) or Vector3.zero) / 180 * math.pi
			local angle = CFrame.fromOrientation(vec.X, vec.Y, vec.Z);

			for instance in build_tools.selection.items do
				build_tools.actions:modify(instance, {[property] = angle + instance[property].Position});
			end;
		end)

		stylus_box.maid:add(angle_box);

		angle_box.maid:add(function()
			angle_body.Parent = nil;
		end)

		stylus_box.value_frame.TextBox.Visible = false;
		button.BackgroundTransparency = 0.9;

		local function set_value(new_value: CFrame)
			position_box:set_text(Type.stringenum:cast(new_value.Position))
			angle_box:set_text(Type.stringenum:cast(Vector3.new(new_value:ToOrientation()) / math.pi * 180))
		end

		set_value(value);
		stylus_box:on_property_changed(instance, property, set_value);

	elseif (property == "Transparency" or property == "Reflectance") and value_type == "number" then
		stylus_box = Stylus:new_sliderbox({
			text = property;
			value = value;
			increment = 0.05;
			range = NumberRange.new(0, 1);
			holder_text = property;
			tooltip = tooltip;
			parent = button.Body;
			theme = "bg_transparent";
			ratio = 0.6;
		});

		stylus_box.interacted:Connect(function()
			for instance in build_tools.selection.items do
				build_tools.actions:modify(instance, {[property] = stylus_box.value});
			end;
		end)
		
		stylus_box:on_property_changed(instance, property, function(value)
			stylus_box:set_alpha( value );
		end)
	else
		stylus_box = Stylus:new_stringbox({
			text = property;
			value = Type.stringenum:cast(value);
			holder_text = property;
			tooltip = tooltip;
			parent = button.Body;
			theme = "bg_transparent";
			dropdown_visible = property == "MaterialVariant" or value_type == "EnumItem";
			ratio = 0.6;
		})
		
		local function open_dropdown()
			if build_tools.dropdown:is_aggregated_by(stylus_box.instance) then 
				return build_tools.dropdown:unmount();
			end;

			if value_type == "EnumItem" then
				build_tools.dropdown:populate_with_enum(value.EnumType, function(enum)
					commit_change(enum.Name);
				end)
				build_tools.dropdown:mount_to_properties(stylus_box.instance);

			elseif property == "MaterialVariant" then
				build_tools.dropdown:populate_with_materials(function(material)
					for instance in build_tools.selection.items do
						build_tools.actions:modify(instance, {Material = material.BaseMaterial});
					end;

					commit_change(material.Name);
				end)
				build_tools.dropdown:mount_to_properties(stylus_box.instance);
			end
		end

		if stylus_box.defaults.dropdown_visible then
			stylus_box:bind_to_dropdown(open_dropdown);
		end

		stylus_box.interacted:Connect(commit_change)
		
		stylus_box:on_property_changed(instance, property, function(value)
			stylus_box:set_text( Type.stringenum:cast(value) );
		end)
	end
	
	assert(stylus_box, "No stylus box was created.");
	
	local section = Properties.get_section_for(property);
	local frame_section = self:create_section(section)
	
	frame_section:SetAttribute("Hide", false);
	frame_section.Visible = true;
	
	button:SetAttribute("Hide", false);
	button.Visible = true;
	button.Parent = frame_section.Body;
	
	self:update_property_frame_size(button);
	self.items[button] = stylus_box;
	
	debug.profileend();
	
	return button;
end

function Properties:get_property_frame(name: string)
	for button, stylus_box in self.items do
		if button.Name == name then
			return button;
		end
	end
end

function Properties:update_property_frame_size(frame: typeof(Assets.PropertyFrame))
	for _, body in frame:GetChildren() do
		if body:IsA("GuiObject") then
			body.Size = UDim2.new(1, 0, 0, 8 + self.build_tools.elements.Right.AbsoluteSize.Y * 0.017);	
		end;
	end;
end

function Properties:initialise()
	local PropertiesBody = self.build_tools.elements.Right.Properties.Body.Body;
	
	local searching = Searcher.new(PropertiesBody.SearchBox, self.list);
	
	searching.update_results_now = function() 
		return searching:update_results_now_nested(true);
	end;
	
	self.cache = InstanceCache.new(0, function()
		local frame = Assets.PropertyFrame:Clone();
		frame.Name = "Frame";
		frame.Body.Size = UDim2.new(1, 0, 0.05, 6);
		
		self.build_tools.elements.Right:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			self:update_property_frame_size(frame);
		end)
		
		return frame;
	end)

	function self.cache.cleanup_release(frame)
		frame.BackgroundTransparency = Assets.PropertyFrame.BackgroundTransparency;
	end
end

table.freeze(Properties);

return Properties;