local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------------------

local Stylus = require( ReplicatedStorage.Packages.Stylus )
local Asset = require( ReplicatedStorage.Packages.Asset )
local Type = require( ReplicatedStorage.Packages.Type )
local Table = require( ReplicatedStorage.Packages.Table )

------------------------------------------------------------------------------------

local PropertyPanel = require( "./PropertyPanel" );

------------------------------------------------------------------------------------

local BaseBlock = {};
BaseBlock.__index = BaseBlock;

function BaseBlock.new(builder, name: string)
	local data = builder.skills_data.blocks[name];
	local space = builder.build_items.Timeline.Timeline.Workspace;

	local block = builder.assets.InsertSkillBlock:Clone();
	block.Button.Display.Icon.Image = Asset.get_rbx_asset(data.Icon);
	block.Button.Title.Title.Text = Asset.pretty_string(name);
	block.Button.Title.SubTitle.Text = `[]`;
	block.Button.Highlight.BackgroundColor3 = data.Color;
	block.Button.Display.Icon.ImageColor3 = data.Color;
	block.Button.Title.Title.TextColor3 = data.Color;
	block.LayoutOrder = 1;

	local list_frame = Instance.new("Frame")
	list_frame.Name = "DummyFrame"
	list_frame.BackgroundTransparency = 1;
	list_frame.Interactable = false;
	list_frame.Size = block.Button.Size;

	local self = setmetatable(
		{
			builder = builder;
			name = name;
			block = block;
			dummy_frame = list_frame;
			space = space;
			position = -1;
			property_panel = PropertyPanel.get(builder, name);
			property_data = {};
			block_data = data;

			color_stack = {};
			destroyed = false;
			is_properties_ready = false;
			initialised = false;
		}, 
		BaseBlock);
	
	self:initialise();
	
	return self;
end;

------------------------------------------------------------------------------------

function BaseBlock:set_branch(branch, position: number?)
	local timeline = self.builder.build_items.Timeline.Timeline.Workspace;
	local last_branch = self.branch;
	
	if branch then
		if not position then
			position = #branch.blocks + 1;
		end;

		self.dummy_frame.LayoutOrder = position;
		
		self.array = branch.blocks;
		self.branch = branch;
		self.block.Parent = timeline.DummyFrames;
		self.dummy_frame.Parent = timeline.ScrollingFrame;
	else
		self.array = nil;
		self.branch = nil;
		self.block.Parent = nil;
		self.dummy_frame.Parent = nil;
	end;
	
	self.position = position;
	
	if last_branch ~= branch then
		if last_branch then
			last_branch:remove_block(self.position);
		end;
		
		branch:add_block(self, position);
	end;
end;

function BaseBlock:clone()
	assert(not self.destroyed, "Cannot clone destroyed block");
	
	local clone = BaseBlock.new(self.builder, self.name);
	
	clone.position = self.position;
	clone.property_data = Table.clone(self.property_data);
	
	return clone;
end;

function BaseBlock:scroll_to_position()
	local dummy_position = self.dummy_frame.AbsolutePosition;
	local dummy_size =  self.dummy_frame.AbsoluteSize;

	local scroll_position = self.space.ScrollingFrame.AbsolutePosition;
	local position = dummy_position - self.space.AbsolutePosition;

	if position.Y < 0 or position.Y > self.space.AbsoluteSize.Y - dummy_size.Y - 8 then
		local direction = if position.Y < 0 then -1 else 1;
		local size = self.dummy_frame.AbsoluteSize;
		local target_position: Vector2;

		if position.Y < 0 then
			target_position = Vector2.new(0, dummy_position.Y - scroll_position.Y + self.space.ScrollingFrame.CanvasPosition.Y );
		else
			target_position = Vector2.new(0, dummy_position.Y - scroll_position.Y + self.space.ScrollingFrame.CanvasPosition.Y - self.space.AbsoluteSize.Y + dummy_size.Y + 8 );
		end

		self.space.ScrollingFrame.CanvasPosition = target_position;
	end
end;

function BaseBlock:set_visible(value: boolean)
	self.block.Visible = value;
	self.dummy_frame.Visible = value;
end

function BaseBlock:update_position(position: number)
	self.position = position;
	self.dummy_frame.LayoutOrder = position;
end

function BaseBlock:initialise()
	if self.initialised then return end;
	
	self.initialised = true;
	self:initialise_defaults();
	
	local function get_position()
		local position = self.dummy_frame.AbsolutePosition - self.space.AbsolutePosition;

		return UDim2.fromOffset(position.X, position.Y);
	end;

	local time_start = tick();

	self.dummy_frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		local position = get_position();

		if tick() - time_start < 0.4 then
			-- Reduces lag when loading animations
			self.block.Position = position;
		else
			local tween = TweenService:Create(self.block, TweenInfo.new(0.06), { Position = position })
			tween:Play();
		end
	end)

	self.block.Button.MouseButton1Click:Connect(function()
		if self.builder.selected_skill_block == self then
			self.builder:select_block(nil)
		else
			self.builder:select_block(self);
		end;
	end);
	
	local function resize_block()
		local size = self.block.Button.AbsoluteSize;

		self.dummy_frame.Size = UDim2.new(1, 0, 0, size.Y);
		self.block.Size = UDim2.new(1, 0, 0, size.Y);

		-- Automatic Size is not reliable, this is a workaround.
		self.block.Button.Title.SubTitle.Size = UDim2.new(1, 0, 0, self.block.Button.Title.SubTitle.TextBounds.Y);
		self.block.Button.Title.Title.Size = UDim2.new(1, 0, 0, self.block.Button.Title.Title.TextBounds.Y);
	end;

	self.block.Button.Title.Title:GetPropertyChangedSignal("TextBounds"):Connect(resize_block)
	self.block.Button.Title.SubTitle:GetPropertyChangedSignal("TextBounds"):Connect(resize_block)
	Stylus.bind_to_resize(self.block.Button, resize_block);
	
	-- defer my beloved
	task.defer(function()
		self.block.Position = get_position();
	end);
	
	self:update_subtitle();
end;

function BaseBlock:get_value(property: string)
	if self.property_data[property] ~= nil then
		local typer = Type[typeof(self.block_data.Properties[property].Default)];
		local value = self.property_data[property].Value;
		
		if typer then
			value = typer:cast(value);
		end;
		
		return value;
	end;
end;

function BaseBlock:get_gray_value(property: string)
	local data = self.property_data[property];
	
	if data and not data.Gray then
		return data.Value;
	end;
end;

function BaseBlock:initialise_defaults()
	for property, property_data in self.block_data.Properties do
		self.property_data[property] = { Value = property_data.Default, Gray = property_data.Grayboxed };
	end;
end;

function BaseBlock:set_property_data(property: string, data)
	self.property_data[property] = data;
	self:update_subtitle();
end

function BaseBlock:rawset_property_value(property: string, value: any)
	
	if self.property_data[property].Value ~= value then
		self.property_data[property].Value = value;
		
		self.builder:done_changes();
	end;
end;

function BaseBlock:set_property_value(property: string, value: any)
	self.property_panel:set_property_value(property, value);

	if self.property_data[property].Value ~= value then
		self.property_data[property].Value = value;
		self.builder:done_changes();
		self:update_subtitle();
	end;
end;

function BaseBlock:set_property_grayed(property: string, value: boolean)
	if self.property_data[property].Gray ~= value then
		self.property_data[property].Gray = value;
		self.builder:done_changes();
		self:update_subtitle();
	end;
end

function BaseBlock:set_as_panel(value: boolean)
	self:set_stroke(value);
	self.property_panel:set_update_target(if value then self else nil);
end

function BaseBlock:set_stroke(highlighted: boolean)
	local stroke = self.block.Button.UIStroke;

	if highlighted then
		stroke.Transparency = 0.1;
		stroke.Thickness = 2;
		stroke.Color = Color3.fromRGB(255, 255, 255)
	else
		stroke.Transparency = 0.8;
		stroke.Thickness = 1;
		stroke.Color = Color3.fromRGB(255, 255, 255)
	end;
end;

function BaseBlock:set_color_stack(other_block, value: boolean?)
	if value then
		self.color_stack[other_block] = true;
	else
		self.color_stack[other_block] = nil;
	end;
	
	local depth = 0;
	
	for block in self.color_stack do
		if block.color_value then
			depth += 1;
		end;
	end;
	
	if depth > 0 then
		self.block.Button.BackgroundTransparency = 0.85;
		self.block.Button.BackgroundColor3 = Color3.fromHSV( math.lerp(-0.03, 1, depth / 9) % 1, 0.8, 1 );
	else
		self.block.Button.BackgroundTransparency = 0.95;
		self.block.Button.BackgroundColor3 = Color3.new(1, 1, 1);
	end
end;

function BaseBlock:_update_subtitle()
	local data_mosh: {string} = {};
	
	for name, data in self.property_data do
		local value, gray = data.Value, data.Gray;
		local info = self.block_data.Properties[name];
		
		if info.Hidden or (not info.Described or typeof(info.Described) == "table" and not table.find(info.Described, value)) or gray then
			continue;
		end;
		
		if typeof(value) == "number" then
			value = Asset.pretty_number(value, 2);
		end

		if info.AssetType then
			-- This will yield but whatever 🥀
			local product = Asset.get_product_details(value);

			if product then
				value = product.Name;
				name = "Name";
			end;
		end;

		if typeof(value) == "boolean" then
			table.insert(data_mosh, `{name}: <font color='rgb({if value then '122,255,122' else '255,122,122'})'>{value}</font>`);
		else
			local string_value = Type.format_string(value)

			table.insert(data_mosh, `{name}: <i><font color='rgb(188,215,255)'>{ string_value }</font></i>`);
		end
	end

	self.block.Button.Title.SubTitle.Text = `[{table.concat(data_mosh, ", ")}]`;
	self:update_sequence_corrector();
end;

function BaseBlock:update_sequence_corrector()
	if self.builder.selected_skill_block == self then
		self.builder.edit_block_frame.BlockIndex.Text = `({self.position})`;
	end;
	
	if self.name == "Loop" then
		self.color_value = Color3.fromRGB(255, 145, 19);

		if self.branch then
			for _, block in self.branch.blocks do
				block:set_color_stack(self, nil);
			end;

			for index = self.position, self.position - self.property_data.Previous.Value, -1 do
				local block = self.branch.blocks[index];

				if block then
					block:set_color_stack(self, true);
				end;
			end;
		end;
	end;
end

function BaseBlock:update_subtitle()
	if not self._updating_subtitle then
		self._updating_subtitle = task.defer(function()
			self._updating_subtitle = nil;
			self:_update_subtitle();
		end);
	end;
end;

function BaseBlock:generate_edit_data()
	return {
		Name = self.name;
		Properties = self.property_data;
	};
end;

function BaseBlock:destroy()
	self.destroyed = true;
	
	if self.branch then
		for _, block in self.branch.blocks do
			block:set_color_stack(self, nil);
		end;

		self.branch:remove_block(self.position);
	end;
	
	self.dummy_frame:Destroy();
	self.block:Destroy();
	
	self.position = -1;
end

------------------------------------------------------------------------------------

table.freeze(BaseBlock);

return BaseBlock;