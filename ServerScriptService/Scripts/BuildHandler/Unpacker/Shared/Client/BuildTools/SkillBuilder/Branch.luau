local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Asset = require( ReplicatedStorage.Packages.Asset )
local Table = require( ReplicatedStorage.Packages.Table )

local BaseBlock = require( "./BaseBlock" );

local Branch = {};
Branch.__index = Branch;

function Branch.new(builder, name: string, position: number)
	if not name then
		name = "Branch";
	end;
	
	local block = builder.assets.BranchSkill:Clone();
	block.Button.Text = tostring(name);
	
	local self = setmetatable(
		{
			name = name;
			frame = block;
			builder = builder;
			blocks = {};
			property_data = {};
			destroyed = false;
			position = position;
		}, 
		Branch);
	
	self:initialise();
	
	return self;
end;

function Branch:initialise()
	self:initialise_defaults();
	
	self.frame.Button.MouseButton1Click:Connect(function()
		self.builder:select_branch(self);
	end);
	
	self:set_binded(true);
end;

function Branch:set_binded(value: boolean)
	if value then
		local space = self.builder.build_items.Timeline.Timeline.Skills.List;
		
		self.frame.LayoutOrder = self.position;
		self.frame.Parent = space.ScrollingFrame;
		
		for index, block in self.blocks do
			block:set_branch(self, index);
		end
	else
		self.frame.Parent = nil;
		
		for index, block in self.blocks do
			block:set_branch(nil);
		end
	end
end

function Branch:clone()
	assert(not self.destroyed, "Cannot clone destroyed branch");

	local clone = Branch.new(self.builder, self.name, self.position);
	clone.property_data = Table.clone(self.property_data);
	clone:set_binded(false);
	
	-- Need to clone the blocks
	for index, block in self.blocks do
		clone.blocks[index] = block:clone();
	end
	
	return clone;
end;

function Branch:initialise_defaults()
	for property, property_data in self.builder.skills_data.branches do
		self.property_data[property] = { Value = property_data.Default, Gray = property_data.Grayboxed };
	end;
	
	-- oh my days 🥀
	self.property_data.BranchName.Value = self.name;
end;

function Branch:create_block(name, position)
	local block = BaseBlock.new(self.builder, name);
	
	if self.builder.selected_branch ~= self then
		block:set_visible(false);
	end;
	
	block:set_branch(self, position);
	
	return block;
end;

function Branch:get_position(): number?
	return self.position; -- table.find( self.builder.branches, self );
end;

function Branch:remove_block(position: number)
	local block = table.remove(self.blocks, position);

	for index = position, #self.blocks do
		self.blocks[index]:update_position(index);
	end;
	
	return block;
end;

function Branch:add_block(block, position: number)
	if not position then
		position = #self.blocks + 1;
	end;
	
	table.insert(self.blocks, position, block);
	
	for index = position, #self.blocks do
		self.blocks[index]:update_position(index);
	end;
end

function Branch:swap_block(position_1, position_2)
	local this_position = math.clamp( position_1, 1, #self.blocks );
	local new_position = math.clamp( position_2, 1, #self.blocks );
	
	local this_block = self.blocks[this_position]
	local other_block = self.blocks[new_position];
	
	if this_block ~= other_block then
		-- Swaps the two indexes in the array.
		self.blocks[this_position], self.blocks[new_position] = self.blocks[new_position], self.blocks[this_position];
		
		this_block:update_position(new_position);
		other_block:update_position(this_position);
		
		for _, block in self.blocks do
			block:update_sequence_corrector();
		end;
		
		self.builder:done_changes();
	end;
end;

function Branch:shuffle_block(position: number, value: number)
	local block = self.blocks[position];
	
	self:swap_block(position, position + value);
	task.defer(block.scroll_to_position, block);
end;

function Branch:update_position(position: number)
	if not position then
		position = self:get_position();
	end;
	
	self.position = position;
	self.frame.LayoutOrder = position;
end;

function Branch:set_selected(value: boolean)
	local stroke = self.frame.Button.UIStroke
	
	if value then
		stroke.Transparency = 0.4;
		stroke.Thickness = 2;
		stroke.Color = Color3.fromRGB(255, 255, 255);
	else
		stroke.Transparency = 0.8;
		stroke.Thickness = 1;
		stroke.Color = Color3.fromRGB(255, 255, 255);
	end;
	
	self:set_blocks_visible(value);
end

function Branch:set_blocks_visible(value: boolean)
	for _, block in self.blocks do
		block:set_visible(value);
	end;
end;

function Branch:generate_edit_data()
	local edit_data = {
		Name = self.name;
		Properties = self.property_data;
		Blocks = {};
	};
	
	for index, block in self.blocks do
		edit_data.Blocks[index] = block:generate_edit_data();
	end;
	
	return edit_data;
end;

function Branch:set_property_data(property: string, data)
	self.property_data[property] = data;
end;

function Branch:get_property(property: string)
	return self.property_data[property];
end

function Branch:get_value(property: string)
	return self.property_data[property].Value;
end

function Branch:set_property(property: string, value: any)
	
	if self.property_data[property].Value ~= value then
		self.property_data[property].Value = value;
		self.builder:done_changes();
		
		if property == "BranchName" then
			self.name = value;
			self.frame.Button.Text = tostring(value) -- Asset.pretty_string(value);
			self.builder:update_branch_details();
		end;
	end;
end;

function Branch:destroy()
	--local position = self:get_position();
	
	self.destroyed = true;
	self.frame:Destroy();
	
	for index = #self.blocks, 1, -1 do
		self.blocks[index]:destroy();
	end;
	
	table.clear(self.blocks);
end

table.freeze(Branch);

return Branch;