local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------

local Asset = require( ReplicatedStorage.Packages.Asset );
local Type = require( ReplicatedStorage.Packages.Type )

local AnimationViewer = require( "./Viewers/AnimationViewer" );
local ValueViewer = require( "./Viewers/ValueViewer" );
local ModifierViewer = require( "./Viewers/ModifierViewer" );

local PropertiesUtility = require( "../../../Data/Properties/Utility" )

------------------------------------------------------------------------------------

local PropertyPanel = {};
PropertyPanel.__index = PropertyPanel;
PropertyPanel.rendering = {};

function PropertyPanel.new(builder, name: string)
	assert(not PropertyPanel.rendering[name], `Already rendering {name}`);

	local self = setmetatable(
		{
			builder = builder,
			name = name;

			fields = {};
			frames = {};
			data = builder.skills_data.blocks[name];
			rendered = false;
			update_target = nil;
		}, 
		PropertyPanel);

	PropertyPanel.rendering[name] = self;
	
	builder.maid:add(function()
		self:destroy();
	end)

	return self;
end;

------------------------------------------------------------------------------------

function PropertyPanel.get(builder, name: string)
	local render = PropertyPanel.rendering[name];

	if not render then
		render = PropertyPanel.new(builder, name);
	end;

	return render;
end;

function PropertyPanel:destroy()
	if PropertyPanel.rendering[self.name] == self then
		PropertyPanel.rendering[self.name] = nil;
	end;
	
	for _, field in self.fields do
		field:destroy();
	end

	for _, frame in self.frames do
		frame:Destroy();
	end;

	table.clear(self.fields);
	table.clear(self.frames);
end

function PropertyPanel:set_property_value(property: string, value: any)
	local field = self.fields[property];
	local propery_data = self.data.Properties[property];
	
	if field then
		if field.__type == "Checkbox" then
			field.toggled = value;
			field:update(true);

		elseif typeof(field.set_value) == "function" then
			field:set_value( value );
		end;
	end;
end;

function PropertyPanel:update_render()
	if self.rendered then return end;

	self.rendered = true;

	local playback_sounds = {};
	
	for property, property_data in self.data.Properties do
		local value = property_data.Default;
		local field_name = property_data.DisplayName or Asset.pretty_string(property);
		
		if property_data.ViewingHelper then
			local viewer;
			
			if property_data.ViewingHelper.Type == "Animation" then
				viewer = AnimationViewer.new(self, property, property_data);

			elseif property_data.ViewingHelper.Type == "ValueList" then
				viewer = ValueViewer.new(self, property, property_data);
				
			elseif property_data.ViewingHelper.Type == "Modifier" then
				viewer = ModifierViewer.new(self, property, property_data)
			end;
			
			viewer.frame.LayoutOrder = property_data.Order or 0;
			
			table.insert(self.frames, viewer.frame);
			self.fields[property] = viewer;

		elseif not property_data.Hidden then
			local is_audio_type = property_data.AssetType == Enum.AssetType.Audio;
			local sound: Sound?;
			
			if is_audio_type then
				sound = Instance.new("Sound");
				sound.PlaybackRegionsEnabled = true;
				sound.Name = "SoundPlayback";
				sound.Parent = self.builder.ui;
				
				property_data._Sound = sound;
				playback_sounds[property] = sound;
			end;
			
			local box, field = self.builder:create_universal_property( field_name, value, property_data, 0.5, 0.65 );
			box.Visible = false;
			box.LayoutOrder = property_data.Order or 0;
			box.Parent = self.builder.edit_block_frame.ScrollingFrame;

			field.value_changed:Connect(function(value)
				if not self.update_target then return end;
				
				self.update_target:rawset_property_value(property, value);
				self.update_target:update_subtitle();
				
				if sound then
					sound.SoundId = Asset.get_rbx_asset(value);
				end;
			end)
			
			if field.gray_changed then
				field.gray_changed:Connect(function(value)
					if not self.update_target then return end;
					
					self.update_target:set_property_grayed(property, value);
				end);
			end;
			
			table.insert(self.frames, box);
			self.fields[property] = field;
		end
	end;
	
	for playback_property, sound in playback_sounds do
		for property, property_data2 in self.data.Properties do
			if not PropertiesUtility.is_property(sound, property) then
				continue;
			end;
			
			local field = self.fields[property];
			
			if field then
				field.value_changed:Connect(function(value)
					local caster = Type.define( sound[property] );
					local new_value, success = caster:cast(value);
					
					if success then
						sound[property] = new_value;
					end;
				end)
			end
		end;
	end
end;

function PropertyPanel:get_property_changed(name: string)
	self:update_render(); -- bruh
	
	return self.fields[name].value_changed;
end;

function PropertyPanel:set_update_target(block)
	local last_block = self.update_target;

	if last_block ~= block then
		self:update_render();
		self.update_target = block;
		
		if block then
			for index, frame in self.frames do
				frame.Visible = true;
				
				if frame.Name == "BuilderValueList" and frame.Parent == nil then
					frame.Parent = self.builder.edit_block_frame.ScrollingFrame;
				end;
			end;
			
			for property, property_data in self.data.Properties do
				local field = self.fields[property];
				
				if property_data.ViewingHelper then
					
					if field then
						-- Inshallah 🙏
						field:update_with_panel();
					end;
				else
					local data = block.property_data[property];
					
					self:set_property_value( property, data.Value );
					
					if property_data.Grayboxed ~= nil and field then
						field:set_grayboxed( data.Gray );
					end;
				end;
			end;
		else
			for _, frame in self.frames do
				frame.Visible = false;
				
				if frame.Name == "BuilderValueList" and frame.Parent == self.builder.edit_block_frame.ScrollingFrame then
					frame.Parent = nil;
				end;
			end;
		end;
	end;
end;

------------------------------------------------------------------------------------

table.freeze(PropertyPanel);

return PropertyPanel