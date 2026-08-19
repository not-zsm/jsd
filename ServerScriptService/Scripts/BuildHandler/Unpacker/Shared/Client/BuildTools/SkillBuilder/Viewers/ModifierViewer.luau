------------------------------------------------------------------------------------

local Retrieve = require( "../Retrieve" )
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stylus = require( ReplicatedStorage.Packages.Stylus )
local Remotes = ReplicatedStorage.BuildTools.Remotes;

------------------------------------------------------------------------------------

local ModifierViewer = {};
ModifierViewer.__index = ModifierViewer;

function ModifierViewer.new(panel, name, data)
	local builder = panel.builder;

	local frame = builder.assets.BuilderModifierView:Clone();
	frame.LayoutOrder = data.Order or 1;
	frame.Parent = builder.edit_block_frame.ScrollingFrame;

	local self = setmetatable(
		{
			name = name;
			frame = frame;
			panel = panel;
			builder = builder;
			data = data;
		}, 
		ModifierViewer);

	self:initialise();

	return self;
end;

------------------------------------------------------------------------------------

function ModifierViewer:create_item(item: any, callback)
	local frame = self.builder.assets.BuilderValueItem:Clone();
	frame.Button.Text = tostring(item);
	frame.Parent = self.frame.ScrollingFrame;

	frame.Button.MouseButton1Click:Connect(function()
		callback( item );
	end)

	return frame;
end;

function ModifierViewer:update_with_panel()
	local block = self.panel.update_target;

	if block then
		local serialised_instance = block:get_value("SerialisedInstance");
		local part_reference = block:get_value(self.name);
		
		if not part_reference then
			self.save_box:set_value(nil);
			
			if serialised_instance ~= "" then
				self.save_box:set_text("[Saved]");
			else
				self.save_box:set_text("");
			end;
		else
			self.save_box:set_text(tostring(part_reference));
		end;
	end;
	
	print(self.save_box.value)
end;

function ModifierViewer:initialise()
	local helper = self.data.ViewingHelper;
	
	local property = self.builder.assets.SkillProperty:Clone();
	property.Size = UDim2.fromScale(1, 0.12);
	property.SizeConstraint = Enum.SizeConstraint.RelativeXX;
	property.LayoutOrder = self.data.Order or 1;
	
	local box = Stylus:new_instancebox({
		text = "Save Part";
		value = nil;
		parent = property;
		placeholder_text = "empty",
		theme = "bg_transparent";
		read_only = true;
		ratio = 0.5;
		text_scale = 0.7;
	});
	
	box.value_changed:Connect(function(value)
		local block = self.panel.update_target;
		
		if block then
			block:set_property_value(self.name, value);
		end;
	end);
	
	property.Parent = self.frame.ScrollingFrame;
	
	self.save_box = box;
	
	self:create_item("Import", function(item)
		local block = self.panel.update_target;

		if block then
			local part_reference = block:get_value(self.name);
			local serialised_instance = block:get_value("SerialisedInstance");
			
			if part_reference ~= nil then
				Remotes.Operations.Cloning:FireServer( { part_reference } );
				
			elseif serialised_instance ~= "" then
				Remotes.Operations.Import:FireServer( serialised_instance );
			else
				self.builder.build_tools:notify(2, "No saved data to import.");
			end;
		end;
	end);
end;

function ModifierViewer:destroy()
	self.frame:Destroy();
end

table.freeze(ModifierViewer);

return ModifierViewer;