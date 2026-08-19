local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

------------------------------------------------------------------------------------

local Retrieve = require( "../Retrieve" )
local ValueList = require( "../../ValueList" );

local Stylus = require( ReplicatedStorage.Packages.Stylus )
local Instances = require( ReplicatedStorage.Packages.Instances )
local AnimationFolder = ReplicatedStorage.Animations;
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local Player = Players.LocalPlayer;

------------------------------------------------------------------------------------

local ValueViewer = {};
ValueViewer.__index = ValueViewer;

function ValueViewer.new(panel, name, data)
	local builder = panel.builder;

	local value_list = ValueList.new(builder.build_tools, false);
	value_list.frame.LayoutOrder = data.Order or 1;
	value_list.frame.Parent = builder.edit_block_frame.ScrollingFrame;
	
	local self = setmetatable(
		{
			name = name;
			panel = panel;
			builder = builder;
			data = data;
			
			frame = value_list.frame;
			value_list = value_list;
		}, 
		ValueViewer);

	self:initialise();

	return self;
end;

------------------------------------------------------------------------------------

function ValueViewer:create_item(properties)
	local frame = self.value_list:create_item(properties);
	
	return frame;
end;

function ValueViewer:reset_frame()
	local base = self.builder.assets.BuilderValueList;
	local size = base.Size;
	
	if self.data.ViewingHelper.Scale then
		size = UDim2.fromScale(size.X.Scale, self.data.ViewingHelper.Scale);
	end;
	
	self.frame.Size = size;
	self.frame.BackgroundTransparency = base.BackgroundTransparency;
	self.frame.SizeConstraint = base.SizeConstraint;
end;

function ValueViewer:select(item: any)
	local block = self.panel.update_target;
	
	if block then
		block:set_property_value(self.name, item);
	end
end

function ValueViewer:update_with_panel()

end;

function ValueViewer:emit_test(particle_folder: Instance, finished_callback)
	local block = self.panel.update_target;

	local parameters = {
		Tint = block:get_gray_value("Tint"),
		Scale = block:get_value("Scale");
		Density = block:get_value("Density"),
		Volume = block:get_value("Volume"),
		ConfirmFinish = 0.25;
		Finished = finished_callback,
	};
	
	local rot = block:get_value("Orientation") / 180 * math.pi;
	local pos = block:get_value("Position");
	
	local coordinate = CFrame.new( pos ) * CFrame.Angles(rot.X, rot.Y, rot.Z);
	
	EffectUtility.AenoirEmit.Emit(particle_folder, Player.Character:GetPivot() * coordinate, parameters);
end

function ValueViewer:generate_list()
	local helper = self.data.ViewingHelper;
	
	if helper.List then
		for _, name in helper.List do
			self:create_item({value = name});
		end;

	elseif helper.Folder then
		for _, item in helper.Folder:GetChildren() do
			self:create_item({value = item});
		end;

	elseif helper.Getter == "Effects" then
		local effects = Retrieve.get_effects();
		local effects_folder = ReplicatedStorage.BuildTools.Effects;
		local vfx_folder = ReplicatedStorage.Modules.Player.Replication.VFX;
		local resolved_paths = {};

		local function create_item_callback(value)
			if value.Parent == effects_folder then
				self.value_list:select( value.Name );
			else
				self.value_list:select( Instances.get_directory(value, vfx_folder, "/") );
			end;
		end;
		
		local function special_emit_callback(value)
			local selected = value.Name;

			if value.Parent ~= effects_folder then
				selected = Instances.get_directory(value, vfx_folder, "/");
			end;
			
			if selected then
				self.builder:push_transparent_mode();
				
				local timeout = task.delay(5, function()
					self.builder:pop_transparent_mode();
				end);
				
				self:emit_test(value, function()
					if coroutine.status(timeout) == "suspended" then
						task.cancel(timeout);
						self.builder:pop_transparent_mode();
					end;
				end)
			end;
		end;
		
		self:create_item({
			name = "None",
			value = "None",
			color = Color3.fromRGB(139, 173, 214);
			callback = create_item_callback,
			callback_m2 = special_emit_callback,
			text_alignment = Enum.TextXAlignment.Left;
		});

		local batch_count = 0;

		for _, instance: Instance in effects do
			batch_count += 1;

			if batch_count >= 25 then
				batch_count = 0;
				task.wait();
			end;
			
			if instance.Parent == effects_folder then
				self:create_item({
					name = instance.Name;
					value = instance,
					callback = create_item_callback,
					callback_m2 = special_emit_callback,
					text_alignment = Enum.TextXAlignment.Left;
					color = Color3.fromRGB(139, 173, 214);
				});
			else
				local module = instance:FindFirstAncestorWhichIsA("ModuleScript");

				if not module then
					continue;
				end;

				local path = Instances.get_directory(instance, vfx_folder, "/");

				if resolved_paths[path] then
					continue;
				end;

				local name = `[{module.Name}] {instance.Name}`;

				if instance:IsA("Attachment") then
					if instance.Name == "Attachment" then
						name = `[{module.Name}] {instance.Parent.Name}`;

					elseif tonumber(instance.Name) ~= nil then
						name = `[{module.Name}] {instance.Parent.Name} {instance.Name}`;
					end;
				end;

				name = string.gsub(name, "%b[]", "<font color='rgb(211,243,255)'>%0</font>");
				resolved_paths[path] = instance;

				self:create_item({
					name = path,
					text = name,
					value = instance,
					color = self.value_list:generate_color(module.Parent.Name);
					callback = create_item_callback,
					callback_m2 = special_emit_callback,
					text_alignment = Enum.TextXAlignment.Left;
				});
			end;
		end;

	elseif helper.Getter == "Skills" then
		local skill_sets = Retrieve.get_skill_sets();

		local function create_item_callback(value)
			self.value_list:select( value );
		end;

		self:create_item({
			name = "None",
			value = "None",
			color = Color3.fromRGB(139, 173, 214);
			callback = create_item_callback,
		})

		for character, list in skill_sets do

			for _, skill_name in list do
				self:create_item({
					name = skill_name,
					value = skill_name,
					color = self.value_list:generate_color(character);
					callback = create_item_callback,
				})
			end;
		end;

	elseif helper.Animation then

		local animations = Retrieve.get_animations();

		local function create_item_callback(value)
			local animation_view = self.panel.fields[helper.Animation];

			if animation_view then
				animation_view:set_animation(value);

				self.value_list:select( self.builder:parse_animation(value) )
			end;
		end

		local none_animation = Instance.new("Animation");
		none_animation.Name = "None";

		self:create_item({
			name = "None",
			value = none_animation,
			color = Color3.fromRGB(139, 173, 214);
			callback = create_item_callback,
			text_alignment = Enum.TextXAlignment.Left;
		})
		
		local batch_count = 0;

		for _, animation in animations do
			batch_count += 1;

			if batch_count >= 48 then
				batch_count = 0;
				task.wait();
			end;
			
			local parent = animation.Parent.Name;
			local color: Color3 = Color3.fromRGB(139, 173, 214);

			if animation:IsDescendantOf(AnimationFolder.Attacks) then
				color = self.value_list:generate_color(animation.Parent.Parent.Name);
			end;

			local name = `[{parent}] {animation.Name}`;

			self:create_item({
				name = name,
				text = string.gsub(name, "%b[]", "<font color='rgb(211,243,255)'>%0</font>"),
				value = animation,
				color = color;
				callback = create_item_callback,
				text_alignment = Enum.TextXAlignment.Left;
			})
		end
	end;
end

function ValueViewer:initialise()
	self.value_list.on_selected:Connect(function(item)
		self:select(item);
	end)
	
	self:reset_frame();
	
	task.defer(self.generate_list, self);
end;

function ValueViewer:destroy()
	self.value_list:destroy();
	self.frame:Destroy();
end

table.freeze(ValueViewer);

return ValueViewer;