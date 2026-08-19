local ReplicatedStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");
local Remotes = BuildPersistent:WaitForChild("Remotes");
local BuildAssets = BuildShared:WaitForChild("Assets");
local Builds = workspace:WaitForChild("Builds");
local BuildTools = script.Parent.Parent;
local Assets = BuildTools:WaitForChild("Assets");

local Maid = require( ReplicatedStorage.Packages.Maid );
local Table = require( ReplicatedStorage.Packages.Table );
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local Signal = require( ReplicatedStorage.Packages.Signal )
local Attributes = require( ReplicatedStorage.Packages.Attributes )
local Asset = require( ReplicatedStorage.Packages.Asset )
local Type = require( ReplicatedStorage.Packages.Type )
local PropertiesUtil = require( BuildShared.Data.Properties.Utility );
local Build = require( BuildPersistent.Build );

local Retrieve = require("../SkillBuilder/Retrieve");

local COLLAPSE_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Sine);
local CLOSE_COLLAPSE_GOAL = {Padding = UDim.new(-0.125, 2)}
local OPEN_COLLAPSE_GOAL = {Padding = UDim.new(0, 2)}
local MAX_FRAME_SIZE = 200;

local ModifierFrame = {};
ModifierFrame.__index = ModifierFrame;
ModifierFrame.frames = {};
ModifierFrame.listen_state_array = {};
ModifierFrame.ignored_attributes = {Modifier = true, _InterestId = true, _CanvasPosition = true, _Collapsed = true};
ModifierFrame.dropdown_properties = {Property = true};

function ModifierFrame.remove_frame(instance)
	local frame = ModifierFrame.frames[instance];
	
	if frame then
		frame:destroy();
		ModifierFrame.frames[instance] = nil;
	end;
end

function ModifierFrame.clear()
	for _, frame in ModifierFrame.frames do
		frame:destroy();
	end;
	
	table.clear(ModifierFrame.frames);
end

function ModifierFrame:clear_properties(do_not_delete: any)
	for _, child in self.modifier.Modifier:GetChildren() do
		if not do_not_delete[child] and child:IsA("GuiObject") then
			child:Destroy();
		end
	end
end

function ModifierFrame.new(build_tools, instance: Instance, collateral: {Instance}, listen_index: number)
	if ModifierFrame.frames[instance] then
		ModifierFrame.frames[instance]:destroy();
	end;
	
	debug.profilebegin("Create ModifierFrame");
	
	local modifier = Assets.Modifier:Clone();
	local maid = Maid.removing(modifier);
	
	local self = setmetatable(
		{
			build_tools = build_tools;
			instance = instance;
			collateral = collateral;
			
			modifier = Assets.Modifier:Clone();
			boxes = {};
			last_attributes = {};
			debug_state = {};
			hiding = {};
			box_frames = {};
			
			is_collapsed = false;
			listen_index = listen_index;
			
			maid = maid;
			attributes = Attributes.new(instance);
		}, 
		ModifierFrame);
	
	ModifierFrame.frames[instance] = self;
	self:init()
	
	debug.profileend();
	
	return self;
end

function ModifierFrame:init()
	self.modifier.Visible = true;
	self.modifier:AddTag("TemporaryModifier");
	self.modifier.Parent = self.build_tools.elements.Right.Modifiers.Body.Canvas.List;
	
	self.modifier.Title:AddTag("UI-ButtonClick");
	self.modifier.Modifier.UIPadding:AddTag("UI-Padding");
	
	do
		local function update_size()
			self.modifier.Title.Size = UDim2.new(1, 0, 0, 6 + self.build_tools.elements.Right.AbsoluteSize.Y * 0.03);
			self.modifier.Title.Label.TextSize = self.modifier.Title.AbsoluteSize.Y * 0.6;
		end
		
		update_size();
		self.maid:add(self.build_tools.elements.Right:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_size));
		
		local function update_canvas_y()
			local content_size_y = self.modifier.Modifier.UIListLayout.AbsoluteContentSize.Y + 8;
			local frame_size = MAX_FRAME_SIZE;
			
			if not self.build_tools.preferences:get("compact_scrolling_modifiers") then
				frame_size = content_size_y;
			end
			
			self.modifier.Modifier.Size = UDim2.new(1, 0, 0, math.min(frame_size, content_size_y));
			
			if content_size_y > frame_size then
				self.modifier.Modifier.AutomaticCanvasSize = Enum.AutomaticSize.Y;
				self.modifier.Modifier.ScrollingEnabled = true;
			else
				self.modifier.Modifier.AutomaticCanvasSize = Enum.AutomaticSize.None;
				self.modifier.Modifier.ScrollingEnabled = false;
			end
		end;
		
		update_canvas_y();
		self.maid:add(self.modifier.Modifier.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update_canvas_y))
	end
	
	self.maid:add(self.modifier.Title.MouseButton1Click:Connect(function()
		self.instance:SetAttribute("_Collapsed", not self.instance:GetAttribute("_Collapsed"));
		self:update_collapsed(false);
	end));
	
	self.maid:add(self.attributes:observe("Modifier", function(value, ...)
		self:update_tag_modifier(value);
	end))
	
	self.maid:add(self.attributes.changed:Connect(function(attribute)
		self:update_attributes(attribute);
	end))
	
	self.maid:add(self.modifier.Title.Delete.MouseButton1Click:Connect(function()
		self.build_tools.actions:delete(self.collateral, true);
	end))
	
	self.maid:add(self.modifier.Modifier:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		self.instance:SetAttribute("_CanvasPosition", self.modifier.Modifier.CanvasPosition)
	end))
	
	local powering_modifier = false;
	local sent_notify_debug = false;
	
	self.maid:add(self.modifier.Title.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.E then
			Remotes.Debugging.DumpModifierStat:FireServer(self.instance);
			
		elseif not processed and not powering_modifier and input.KeyCode == Enum.KeyCode.T then
			powering_modifier = true;
			Remotes.Debugging.PowerModifier:FireServer(self.instance, powering_modifier);
			
			local time_now = tick();
			
			if not sent_notify_debug and ( not self.build_tools._mdpomt or time_now - self.build_tools._mdpomt > 120 ) then
				self.build_tools._mdpomt = time_now;
				sent_notify_debug = true;
				
				self.build_tools:notify(3, "Use key 'T' on modifier banner to power the modifier for debugging", 10);
			end;
		end;
	end))
	
	self.maid:add(self.modifier.Title.InputEnded:Connect(function(input)
		if powering_modifier and input.KeyCode == Enum.KeyCode.T then
			powering_modifier = false;
			Remotes.Debugging.PowerModifier:FireServer(self.instance, powering_modifier);
		end;
	end));
	
	self.maid:add()
	
	self:update_attributes()
	self:update_collapsed(true);
	self.modifier.Modifier.CanvasPosition = self.instance:GetAttribute("_CanvasPosition") or Vector2.zero;
end

function ModifierFrame:update_collapsed(instant: boolean?)
	local collapsed = self.instance:GetAttribute("_Collapsed") or false;

	if self.is_collapsed ~= collapsed then
		self.is_collapsed = collapsed;
		self.modifier.Modifier.Visible = true;
		self.modifier.Title.UIStroke.Enabled = not collapsed;
		
		if instant then
			self.modifier.Modifier.UIListLayout.Padding = if collapsed then CLOSE_COLLAPSE_GOAL.Padding else CLOSE_COLLAPSE_GOAL.Padding;
			self.modifier.Modifier.Visible = not collapsed;
		else
			if collapsed then
				local close_tween = TweenService:Create(self.modifier.Modifier.UIListLayout, COLLAPSE_INFO, CLOSE_COLLAPSE_GOAL);
				close_tween:Play()
				close_tween.Completed:Once(function(status)
					if (status == Enum.PlaybackState.Completed) then
						self.modifier.Modifier.Visible = false;
					end
				end)
			else
				local open_tween = TweenService:Create(self.modifier.Modifier.UIListLayout, COLLAPSE_INFO, OPEN_COLLAPSE_GOAL);
				open_tween:Play();
			end
		end;
	end;
end

function ModifierFrame:update_tag_modifier(value)
	self.tag_data = self.build_tools.modifiers.get_data_from_tag(value);
	self.modifier.Title.Label.Text = Asset.pretty_string(value or "Unknown Modifier");
	
	if self.tag_data then
		self.modifier.Title.BackgroundColor3 = self.tag_data.Color;
		self.modifier.Title.UIStroke.Color = self.tag_data.Color;
		
		self.modifier.Title.Icon.Image = Asset.get_rbx_asset(self.tag_data.Icon);
		
		-- Incase you haven't opened the skill builder yet 🥀
		for property, info in self.tag_data.Properties do
			if info.ValueList == "CustomSkill" then
				Build.skills_stream:synchronise();
				break;
			end
		end
	end;
end

function ModifierFrame:edit_modifier(attribute: string, value: any)
	self.build_tools.actions:edit_modifier(self.collateral, attribute, value);
end

function ModifierFrame:create_property(property, value)
	if not self.tag_data then
		return warn(`No tag data exists for modifier {self.instance.Name}`);
	end;
	
	local property_info = self.tag_data.Properties[property];
	
	if not property_info then
		return warn(`No property info exists for '{property}'`);
	end;
	
	local default = self.build_tools.assets.ModifierProperty:Clone();
	default.Visible = true;
	default.Name = property;
	
	if property_info.Order then
		default:SetAttribute("Order", property_info.Order);
	end
	
	local title = property_info.DisplayName or Asset.pretty_string(property);
	local value_type = typeof(value);
	
	if value_type == "boolean" then
		self.boxes[default] = Stylus:new_checkbox({
			text = title;
			toggled = value;
			parent = default.Body;
			theme = "bg_transparent";
			ratio = 0.6;
		})
		
		self.boxes[default].interacted:Connect(function(value)
			self:edit_modifier(property, value);
		end)
		
	elseif value_type == "nil" or value_type == "Instance" then
		self.boxes[default] = Stylus:new_instancebox({
			text = title;
			value = value;
			holder_text = property;
			parent = default.Body;
			theme = "bg_transparent";
			ratio = 0.6;
		})
		
		self.boxes[default].interacted:Connect(function(value)
			self:edit_modifier(property, value);
		end)
		
	elseif value_type == "Color3" or value_type == "ColorSequence" then
		self.boxes[default] = Stylus:new_colorbox({
			text = title;
			value = Type.string:cast(value);
			holder_text = property;
			parent = default.Body;
			theme = "bg_transparent";
			ratio = 0.6;
		})
		
		self.boxes[default]:set_color( value )
		
		self.build_tools.hue_picker:bind_colorbox(self.boxes[default], function(color: Color3)
			self.boxes[default]:set_color( color );
			if value_type == "ColorSequence" then
				color = ColorSequence.new(color) :: any;
			end;
			self:edit_modifier(property, color);
		end)
	else
		
		self.boxes[default] = Stylus:new_stringbox({
			text = title;
			value = Type.stringenum:cast(value);
			parent = default.Body;
			theme = "bg_transparent";
			dropdown_visible = value_type == "EnumItem" or ModifierFrame.dropdown_properties[property] or property_info.AssetType ~= nil or property_info.ValueList ~= nil;
			ratio = 0.6;
		});
		
		if property_info.AssetType ~= nil then
			local function open_toolbox()
				if self.build_tools.toolbox.affector_instance ~= self.boxes[default].instance then
					self.build_tools.toolbox:toggle(true, property_info.AssetType);
					self.build_tools.toolbox.affector_instance = self.boxes[default].instance;
				else
					self.build_tools.toolbox:toggle(false);
				end;
			end

			self.boxes[default]:bind_to_dropdown(open_toolbox);
			
			self.build_tools.toolbox:bind_stringbox(self.boxes[default], function(asset_id: number)
				self:edit_modifier(property, asset_id);
			end);
			
			if property_info.AssetType == Enum.AssetType.Audio then
				default.UIListLayout.Padding = UDim.new(0.05, 0);
				
				local musicbox = Stylus:new_musicbox({
					text = "";
					value = value,
					parent = default,
					theme = "bg_transparent";
					ratio = 0.1;
					text_scale = 0.75;
				});

				musicbox.layout.TextLabel.Visible = false;
				musicbox.instance.Size = default.Body.Size;
				musicbox.instance.SizeConstraint = Enum.SizeConstraint.RelativeXX;
				
				musicbox.on_played:Connect(function()
					local reference_sound = self.attributes:get("Reference");
					local clone_sound;
					
					if not reference_sound or not reference_sound:IsA("Sound") then
						clone_sound = Instance.new("Sound");
						clone_sound.SoundId = Asset.get_rbx_asset( self.attributes:get(property) );
						clone_sound.Volume = self.attributes:get("Volume") or 1;
						clone_sound.PlaybackSpeed = self.attributes:get("Pitch") or 1;
					else
						clone_sound = Instance.fromExisting(reference_sound);
					end;
					
					clone_sound.Name = "MusicboxSound";
					clone_sound.Parent = musicbox.instance;
					
					musicbox:set_audio(clone_sound);
				end)
				
				self.boxes[default].maid:add(musicbox);
			end
		else
			local function open_dropdown()
				if self.build_tools.dropdown:is_aggregated_by(self.boxes[default].instance) then 
					return self.build_tools.dropdown:unmount();
				end;
				
				self.build_tools.dropdown:clear();
				
				if typeof(property_info.ValueList) == "table" then
					for _, prop in property_info.ValueList do
						self.build_tools.dropdown:add_option(prop, function()
							self:edit_modifier(property, prop);
						end);
					end;
					self.build_tools.dropdown:mount_to_properties(self.boxes[default].instance);
					
				elseif value_type == "EnumItem" then
					self.build_tools.dropdown:populate_with_enum(value.EnumType, function(enum)
						self:edit_modifier(property, enum);
					end)
					self.build_tools.dropdown:mount_to_properties(self.boxes[default].instance);

				elseif property == "Property" then
					for prop in PropertiesUtil.get_properties(self.attributes:get("Output") or self.instance.Parent) do
						self.build_tools.dropdown:add_option(prop, function()
							self:edit_modifier(property, prop);
						end)
					end;

					self.build_tools.dropdown:mount_to_properties(self.boxes[default].instance);

				elseif property_info.ValueList == "Effects" then
					self.build_tools.dropdown:populate_with_effects(function(effect)
						self:edit_modifier(property, effect);
					end)
					
					self.build_tools.dropdown:mount_to_properties(self.boxes[default].instance);
					self.build_tools.dropdown:set_size(UDim2.fromScale(1.2, 1));
					
				elseif property_info.ValueList == "Skills" then
					for _, name in { "None", "Random", "Custom" } do
						self.build_tools.dropdown:add_option(name, function()
							self:edit_modifier(property, name);
						end);
					end;
					
					for _, character_skills in Retrieve.get_skill_sets() do
						for _, name in character_skills do
							self.build_tools.dropdown:add_option(name, function()
								self:edit_modifier(property, name);
							end)
						end;
					end;
					
					self.build_tools.dropdown:mount_to_properties(self.boxes[default].instance);
					
				elseif property_info.ValueList == "CustomSkill" then
					for slot, data in Build.skills_stream:get{"Slots"} do
						local name = data.Properties.SkillName.Value;
						
						self.build_tools.dropdown:add_option(name, function()
							self:edit_modifier(property, name);
						end)
					end
					
					self.build_tools.dropdown:mount_to_properties(self.boxes[default].instance);
				end
			end
			
			self.boxes[default]:bind_to_dropdown(open_dropdown);
		end;
		
		self.boxes[default].interacted:Connect(function(new_value)
			if value_type == "EnumItem" then
				local enum = value.EnumType:FromName(new_value);
				
				if enum then
					new_value = enum;
				end;
			end;
			
			self:edit_modifier(property, new_value);
		end)
	end
	
	default.Parent = self.modifier.Modifier;
	
	local function update_property_frame_size(frame: typeof(Assets.ModifierProperty))
		frame.Size = UDim2.new(1, 0, 0, 8 + self.build_tools.elements.Right.AbsoluteSize.Y * 0.017);	
	end
	
	update_property_frame_size(default);
	
	self.build_tools.elements.Right:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		update_property_frame_size(default);
	end)
	
	default.Destroying:Once(function()
		self.boxes[default] = nil;
	end)
	
	self.box_frames[property] = default;
	
	return default;
end

function ModifierFrame:update_debug_state()
	self:update_stroke();
end

function ModifierFrame:update_stroke()
	
	if self.debug_state.powering then
		self.modifier.UIStroke.Color = Color3.fromRGB(158, 134, 255);
		self.modifier.UIStroke.Transparency = 0;
		self.modifier.UIStroke.Thickness = 2;
		
	elseif self.debug_state.powered then
		self.modifier.UIStroke.Color = Color3.fromRGB(155, 255, 125);
		self.modifier.UIStroke.Transparency = 0;
		self.modifier.UIStroke.Thickness = 1;
		
	elseif self.debug_state.conflict then
		self.modifier.UIStroke.Color = Color3.fromRGB(234, 164, 0);
		self.modifier.UIStroke.Transparency = 0;
		self.modifier.UIStroke.Thickness = 1;
		
	else
		self.modifier.UIStroke.Color = Color3.fromRGB(196, 196, 196);
		self.modifier.UIStroke.Transparency = 0.5;
		self.modifier.UIStroke.Thickness = 1;
	end;
end

function ModifierFrame:update_attributes(attribute: string)
	if ModifierFrame.ignored_attributes[attribute] or not self.tag_data or not self.tag_data.Properties then
		return;
	end;
	
	local attributes = self.attributes:all();
	local do_not_delete = {};
	local hide_names = {};
	
	for property, data in self.tag_data.Properties do
		if data.Hidden then
			hide_names[property] = true;
		end;
	end
	
	for property, data in self.tag_data.Properties do
		if attributes[property] then
			if data.Hides then
				for _, value in data.Hides do
					hide_names[value] = true;
				end;
			end;

			if data.Shows then
				for index, value in data.Shows do
					if typeof(index) == "string" then
						if table.find(value, attributes[property]) ~= nil then
							hide_names[index] = false;
						end
					else
						hide_names[value] = false;
					end;
				end;
			end
		end;
	end;
	
	self.attributes:foreach(function(name, value)
		if ModifierFrame.ignored_attributes[name] or string.sub(name, 1, 1) == "_" then return end;
		
		local last_attribute = self.last_attributes[name];
		local frame = self.box_frames[name];
		
		if not frame or typeof(value) ~= typeof(last_attribute) then
			frame = self:create_property(name, value);
			
		elseif not attribute or attribute == name then
			local box = self.boxes[frame];
			
			if box and box.__type == "Stringbox" then
				if not box:is_focused() then
					box:set_text(Type.stringenum:cast(value));
				end;
				
			elseif box and box.__type == "Checkbox" then 
				box:toggle(value);
			end
		end;
		
		if frame then
			frame.Visible = not hide_names[name];
			do_not_delete[frame] = true;
		end;
	end)
	
	self:clear_properties(do_not_delete);
	self:sort();
	
	self.modifier.Modifier.UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder;
	self.last_attributes = attributes;
end;

local function order_sort(a, b)
	local order_1 = a:GetAttribute("Order");
	local order_2 = b:GetAttribute("Order");

	if order_1 and order_2 then
		return order_1 < order_2;

	elseif not order_1 and not order_2 then
		return a.Name < b.Name;
	else
		return order_2 ~= nil and order_1 == nil;
	end;
end;

function ModifierFrame:sort()
	local frames = {};

	for name, frame in self.box_frames do
		table.insert(frames, frame);
	end;

	table.sort(frames, order_sort);

	for order, frame in frames do
		frame.LayoutOrder = order;
	end;
end

function ModifierFrame:destroy()
	self.maid:destroy();
	self.modifier:Destroy();
	
	ModifierFrame.frames[self.instance] = nil;
	table.clear(self.boxes);
end

table.freeze(ModifierFrame);

return ModifierFrame;