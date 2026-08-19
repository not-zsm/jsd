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
local Signal = require( ReplicatedStorage.Packages.Signal )

local Wizard = require( script.Wizard )


local Wizards = {};
Wizards.__index = Wizards;

function Wizards.new(build_tools)
	local maid = build_tools.maid:limb();
	
	local self = setmetatable(
		{
			maid = maid;
			build_tools = build_tools;
			current_wizard = nil;
			visible = true;
			wizards = {};
			ui = build_tools.ui.Wizards;
		}, 
		Wizards);
	
	self:initialise();
	
	return self;
end;

function Wizards:destroy()
	Table.dispose(self);
end

function Wizards:create(...)
	local wizard = Wizard.new(self.build_tools, ...);
	local name = wizard:get_name();
	
	assert(not self.wizards[name], "Wizard already exists");
	
	self.wizards[name] = wizard;
	
	return wizard;
end

function Wizards:toggle(value: boolean?)
	if value == nil then
		value = not self.visible;
	end;
	
	if self.visible ~= value then
		self.visible = value;
		
		if self.current_wizard then
			self.current_wizard:toggle(self.visible);
		end;
	end;
end

function Wizards:set(wizard: any)
	if typeof(wizard) == "string" then
		wizard = self.wizards[wizard];
	end;
	
	local current_wizard = self.current_wizard;
	
	if (current_wizard ~= wizard) then
		self.current_wizard = wizard;
		
		if current_wizard then
			current_wizard:toggle(false);
			
			if current_wizard.disable_selection then
				self.build_tools.status:animate_hide(self.active_status);
			end;
		end;
		
		if wizard then
			wizard:toggle(self.visible);
			
			self.build_tools.status:play_sound(self.active_status, NotificationStatus.info);
			
			if wizard.disable_selection then
				self.build_tools.status:animate_show(self.active_status);
			end;
		end
	end;
end

function Wizards:is_active()
	return self.current_wizard ~= nil;
end

function Wizards:is_selection_disabled()
	return not self:is_active() or self.current_wizard.disable_selection;
end

function Wizards:click()
	if self.current_wizard then
		self.current_wizard:click();
	end;
end

function Wizards:is_currently(wizard_name: string?)
	if not self.current_wizard then
		return wizard_name == nil;
	else
		return self.current_wizard:get_name() == wizard_name;
	end
end

function Wizards:initialise()
	self.active_status = self.build_tools.status:create_info("Currently using wizard, selection disabled.");
	
	local create_mesh_part = self:create("CreateMesh")

	create_mesh_part.on_enable:Once(function()
		local items_list = create_mesh_part.frame.Body.Items;
		
		local shape = Stylus:new_stringbox({
			text = "Collision";
			value = "Precise";
			parent = items_list;
			theme = "bg_transparent";
			button_based = true;
			ratio = 0.5;
			height = 0.08;
		});
		
		local shape_enums = {["Box"] = Enum.CollisionFidelity.Box, ["Hull"] = Enum.CollisionFidelity.Hull, ["Precise"] = Enum.CollisionFidelity.PreciseConvexDecomposition};
		local shapes = {"Precise", "Hull", "Box"};
		local shape_index = 1;
		
		shape.focus_start:Connect(function()
			shape_index = (shape_index % #shapes) + 1;
			shape:set_text(shapes[shape_index]);
		end)

		local mesh_id = Stylus:new_stringbox({
			text = "Mesh Id";
			value = "";
			parent = items_list;
			theme = "bg_transparent";
			ratio = 0.5;
			height = 0.08;
		});

		local texture_id = Stylus:new_stringbox({
			text = "Texture Id";
			value = "";
			parent = items_list;
			theme = "bg_transparent";
			ratio = 0.5;
			height = 0.08;
		});
		
		create_mesh_part.frame.Body.Create.MouseButton1Click:Connect(function()
			Remotes.Operations.CreateMesh:FireServer(mesh_id:get_text(), texture_id:get_text(), shape_enums[shapes[shape_index]])
		end)
	end)
	
	local text_writer = self:create("TextWriter");

	text_writer.on_enable:Once(function()
		local frame = text_writer.frame.Body;

		Stylus.bind_to_resize(frame.Box, function(size)
			frame.Box.TextSize = size.Y * 0.5;
		end)

		frame.Write.MouseButton1Click:Connect(function()
			Remotes.Operations.WriteText:FireServer(frame.Box.Text);
			self.build_tools:notify("info", "Writing Text")
		end);
	end)
	
	local import_export = self:create("ImportExport");
	
	import_export.on_enable:Once(function()
		local frame = import_export.frame.Body;
		
		Stylus.bind_to_resize(frame.Box, function(size)
			frame.Box.TextSize = size.Y * 0.6;
		end)
		
		frame.Import.MouseButton1Click:Connect(function()
			Remotes.Operations.Import:FireServer(frame.Box.Text);
			self.build_tools:notify("info", "Importing data from text box")
		end);
		
		frame.Export.MouseButton1Click:Connect(function()
			local instances = self.build_tools.selection:get();
			
			if #instances > 0 then
				Remotes.Operations.Export:FireServer(instances);
				
				if #instances == 1 then
					self.build_tools:notify("info", `Exporting instance '{instances[1].Name}'`)
				else
					self.build_tools:notify("info", `Exporting multiple instances`)
				end;
			else
				self.build_tools:notify("info", "You need to select instance(s) to export")
			end
		end);
		
		Remotes.Operations.Export.OnClientEvent:Connect(function(data_string: string)
			local success = pcall(function()
				frame.Box.Text = data_string;
			end);
			
			if success then
				self.build_tools:notify("success", "Selected instance(s) were successfully exported")
			else
				self.build_tools:notify("error", "Instance(s) were successfully exported, but the given data exceeds the 200,000 character limit of text boxes 😢")
			end
		end)
	end)
	
	local global_variables = self:create("Variables")
	
	global_variables.on_enable:Once(function()
		local variable_frames = {};
		
		local function delete_variable(value_base: ValueBase)
			if variable_frames[value_base] then
				variable_frames[value_base]:Destroy();
				variable_frames[value_base] = nil;
			end;
		end;
		
		local function add_variable(value_base: Instance)
			if not value_base:IsA("ValueBase") then
				return;
			end;

			delete_variable(value_base);
			
			local frame = script.Parent.Assets.GlobalVariable:Clone();
			variable_frames[value_base] = frame;

			local temp_maid = Maid.destroying(frame);

			local function update_value(value: number)
				frame.Title.Text = `{value_base.Name}: <font color='rgb(143,186,255)'><b>{value}</b></font>`
			end;

			update_value(value_base.Value);
			temp_maid:add(value_base.Changed:Connect(update_value));

			temp_maid:add(Stylus.bind_to_resize(frame.Title, function(size)
				frame.Title.TextSize = size.Y * 0.95;
			end));
			
			frame.Parent = global_variables.frame.Body.Items;
		end;
		
		for _, value_base in BuildPersistent.Variables:GetDescendants() do
			task.spawn(add_variable, value_base);
		end;
		
		BuildPersistent.Variables.DescendantAdded:Connect(add_variable);
		BuildPersistent.Variables.DescendantRemoving:Connect(delete_variable)
	end)
	
	local voxel_breaker = self:create("VoxelBreaker")
	voxel_breaker.disable_selection = true;
	
	voxel_breaker.on_enable:Once(function()
		local items_list = voxel_breaker.frame.Body.Items;
		local visual_ball = script.Parent.Assets.VoxelBreakerSelection:Clone();
		
		local shape = Stylus:new_stringbox({
			text = "Shape";
			value = "Sphere";
			parent = items_list;
			theme = "bg_transparent";
			button_based = true;
			ratio = 0.5;
			height = 0.08;
		});

		local shapes = {"Sphere", "Box"};
		local shape_index = 1;

		shape.focus_start:Connect(function()
			shape_index = (shape_index % #shapes) + 1;
			shape:set_text(shapes[shape_index]);
		end)

		local radius = Stylus:new_sliderbox({
			text = "Radius";
			value = 10;
			increment = 0.01;
			range = NumberRange.new(0, 50);
			parent = items_list;
			theme = "bg_transparent";
			ratio = 0.5;
			height = 0.075;
		});

		local block_size = Stylus:new_sliderbox({
			text = "Block Size";
			value = 4;
			increment = 1/12;
			range = NumberRange.new(0, 12);
			parent = items_list;
			theme = "bg_transparent";
			ratio = 0.5;
			height = 0.075;
		});

		local character_based = Stylus:new_checkbox({
			text = "Character Based";
			toggled = false;
			parent = items_list;
			theme = "bg_transparent";
			ratio = 0.5;
			height = 0.075;
		})
		
		local break_only_selected = Stylus:new_checkbox({
			text = "Break Only Selected";
			toggled = false;
			parent = items_list;
			theme = "bg_transparent";
			ratio = 0.5;
			height = 0.075;
		})
		
		local use_greedy_meshing = Stylus:new_checkbox({
			text = "Use Tolerences";
			toggled = true;
			parent = items_list;
			theme = "bg_transparent";
			ratio = 0.5;
			height = 0.075;
		})
		
		local function update_enable_state()
			if not voxel_breaker.enabled then return end;
			
			voxel_breaker.active_maid:add(RunService.PreSimulation:Connect(function(dt)
				local is_sphere = shapes[shape_index] == "Sphere";
				visual_ball.SelectionBox.Visible = not is_sphere;
				visual_ball.SelectionSphere.Visible = is_sphere;
				visual_ball.Size = Vector3.one * radius:get_value() * (if is_sphere then 2 else 1);
				visual_ball.Parent = workspace.Terrain;
				
				if character_based:get_value() then
					if Player.Character then
						visual_ball.CFrame = Player.Character:GetPivot();
					end;
				else
					local _, target = self.build_tools.selection:cast_screen_ray(self.build_tools.selection.raycast_full_params);
					visual_ball.CFrame = target;
				end;
			end));

			voxel_breaker.active_maid:add(function()
				visual_ball.Parent = nil;
			end);
		end;
		
		update_enable_state();
		voxel_breaker.on_enable:Connect(update_enable_state);
		
		function voxel_breaker:click()
			local result: RaycastResult?, coordinate: CFrame;
			
			if character_based.toggled then
				result, coordinate = nil, Player.Character:GetPivot();
			else
				result, coordinate = self.build_tools.selection:cast_screen_ray(self.build_tools.selection.raycast_full_params);
			end
			
			self.build_tools.actions:voxel_break({
				origin = coordinate;
				shape = shapes[shape_index], 
				block_size = block_size.value, 
				radius = radius.value;
				size = Vector3.one * radius.value, 
				greedy_meshing = use_greedy_meshing.toggled,
				among = if break_only_selected.toggled then self.build_tools.selection:get() else nil;
			})
		end
	end)
	
	local skill_builder = self:create("SkillBuilder")
	
	skill_builder.on_enable:Once(function()
		
	end)
	
	-- race condition
	task.defer(function()
		skill_builder.opens = self.build_tools.skill_builder;
	end)
end

table.freeze(Wizards);

return Wizards;