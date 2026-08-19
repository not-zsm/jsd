local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-----------------------------------------------------------------------------------------------------------

local BuildShared = ReplicatedStorage:WaitForChild("BuildTools");
local Remotes = BuildShared:WaitForChild("Remotes");
local Table = require( ReplicatedStorage.Packages.Table )

-----------------------------------------------------------------------------------------------------------

export type ClassActions = {
	__index: ClassActions;

	new: (build_tools: any) -> Actions;
	init: (self: Actions) -> ();
	destroy: (self: Actions) -> ();
	clear_commit: (self: Actions) -> ();
	act_commit: (self: Actions, selection: unknown) -> ();
	load_slot: (self: Actions, slot: number) -> ();
	save_slot: (self: Actions, slot: number, slot_name: string) -> ();
	add_modifier: (self: Actions, instances: {Instance}, modifier: string) -> ();
	edit_modifier: (self: Actions, instances: {Instance}, attribute: string, value: any) -> ();
	clear_all: (self: Actions) -> ();
	clone: (self: Actions, instances: {Instance}) -> ();
	copy: (self: Actions, instances: {Instance}) -> ();
	paste: (self: Actions, into: Instance, coordinate: CFrame) -> ();
	spawn: (self: Actions, instance_name: string, into: Instance?, coordinate: CFrame?) -> ();
	load_map: (self: Actions, name: string) -> ();
	save_to_hotbar: (self: Actions, slot: number, instance: Instance?) -> ();
	load_from_hotbar: (self: Actions, slot: number, coordinate: CFrame) -> ();
	update_commit_cframe: (self: Actions) -> ();
	update_commit_size: (self: Actions) -> ();
	modify: (self: Actions, instance: Instance, properties: {[string]: {any}}, do_not_record: boolean?) -> ();
	bulk_modify: (self: Actions, instances: {Instance}, properties: any, do_not_record: boolean?) -> ();
	delete: (self: Actions, instances: {Instance}, no_deselect: boolean?) -> ();
	undo: (self: Actions) -> ();
	redo: (self: Actions) -> ();
	gap_fill: (self: Actions, edge_a: unknown, edge_b: unknown, extrude_direction_modifier: unknown, thickness_override: unknown, force_factor: unknown) -> ();
	group: (self: Actions, instances: {Instance}) -> ();
	ungroup: (self: Actions, instances: {Instance}) -> ();
	weld_all: (self: Actions, instances: {Instance}) -> ();
	break_welds: (self: Actions, instances: {Instance}) -> ();
	anchor: (self: Actions, instances: {Instance}, anchor: boolean) -> ();
};

export type Actions = typeof(setmetatable({} :: {
	build_tools: any;
	to_commit: {[string]: boolean};
	commit_debounces: {
		CFrame: number, 
		Size: number;
	};

	modify_queue: {
		mapping: {[Instance]: number};
		instances: {Instance};
		properties: {[string]: {[number]: any}};
		record: boolean;
		thread: thread?;
	};
	
}, {} :: ClassActions));

-----------------------------------------------------------------------------------------------------------

local REAL_TIME_UPDATE_FREQUENCY = 1 / 15;

local function run_queue_thread(queue)
	if queue.thread then return end;

	queue.thread = task.defer(function()
		queue.thread = nil;

		Remotes.Operations.Modify:FireServer(queue.instances, queue.properties, queue.record);

		queue.record = false;
		table.clear(queue.mapping);
		table.clear(queue.instances);
		table.clear(queue.properties);
	end)
end

-----------------------------------------------------------------------------------------------------------

local Actions = {} :: ClassActions;
Actions.__index = Actions;

function Actions.new(build_tools)
	local self = setmetatable(
		{
			build_tools = build_tools;
			to_commit = {};
			commit_debounces = {
				CFrame = -1, 
				Size = -1;
			};
			modify_queue = {
				mapping = {};
				instances = {};
				properties = {};
				record = false;
				thread = nil;
			};
		}, 
		Actions);
	
	return self;
end;

function Actions:init() end

function Actions:destroy()
	if self.modify_queue.thread then
		task.cancel(self.modify_queue.thread);
	end;
	
	self:clear_commit();
	table.clear(self.modify_queue);
	Table.dispose(self);
end

function Actions:clear_commit()
	table.clear(self.to_commit);
end

function Actions:act_commit(selection)
	if next(self.to_commit) then
		self:bulk_modify(selection or self.build_tools.selection:get_physical_selection(), Table.keys(self.to_commit));
		self:clear_commit();
	end;
end

function Actions:remove_from_inventory(instance: Instance): ()
	Remotes.Serialisation.RemoveFromInventory:FireServer(instance);
end

function Actions:save_to_inventory(instance: Instance): ()
	if not instance then
		self.build_tools:notify("warning", "Could not save object, nothing was selected!")
	else
		Remotes.Serialisation.SaveToInventory:FireServer(instance);
	end
end

function Actions:load_slot(slot: number, version_number: string?): ()
	Remotes.Serialisation.LoadFromSlot:FireServer(slot, version_number);
end

function Actions:save_slot(slot: number, slot_name: string): ()
	Remotes.Serialisation.SaveToSlot:FireServer(slot);
end

function Actions:voxel_break(info)
	Remotes.Operations.VoxelBreak:FireServer(info);
end

function Actions:add_modifier(instances: {Instance}, modifier: string)
	Remotes.Operations.AddModifier:FireServer(instances, modifier);
end

function Actions:edit_modifier(instances: {Instance}, attribute: string, value: any)
	Remotes.Operations.EditModifier:FireServer(instances, attribute, value);
end

function Actions:clear_all(): ()
	Remotes.Operations.Clear:FireServer();
end

function Actions:clone(instances: {Instance}): ()
	Remotes.Operations.Cloning:FireServer(instances);
end

function Actions:copy(instances: {Instance}): ()
	Remotes.Operations.Copy:FireServer(instances);
end

function Actions:paste(into: Instance, coordinate: CFrame): ()
	Remotes.Operations.Paste:FireServer(into, coordinate);
end

function Actions:spawn(instance_name: string, into: Instance?, coordinate: CFrame?, auto_select: boolean?): ()
	Remotes.Operations.Spawn:FireServer(instance_name, 1, into, coordinate, auto_select);
end

function Actions:load_map(name: string): ()
	Remotes.Serialisation.LoadMap:FireServer(name);
end

function Actions:save_to_hotbar(slot: number, instance: Instance?): ()
	Remotes.Serialisation.SaveToHotbar:FireServer(slot, instance);
end

function Actions:load_from_hotbar(slot: number, coordinate: CFrame): ()
	Remotes.Serialisation.LoadFromHotbar:FireServer(slot, coordinate);
end

function Actions:update_commit_cframe()
	self.to_commit.CFrame = true;
	
	if self.build_tools.preferences:get("real_time_updates") then
		local now = tick();
		
		if now - self.commit_debounces.CFrame > REAL_TIME_UPDATE_FREQUENCY then
			self.commit_debounces.CFrame = now;
			
			local items = self.build_tools.selection:get_physical_selection();
			
			if #items > 750 then
				return;
			end
			
			local current_index = 1;
			
			while current_index <= #items do
				local target_index = math.min(current_index + 40, #items)
				
				local send_items = table.move(items, current_index, target_index, 1, {});
				local send_cframes = {};
				
				for index = current_index, target_index do
					local pv_instance = items[index];
					
					if pv_instance:IsA("Model") then
						table.insert(send_cframes, pv_instance:GetPivot());
					else
						table.insert(send_cframes, pv_instance.CFrame);
					end;
					
					current_index += 1;
				end;
				
				Remotes.Operations.Move:FireServer(now, send_items, send_cframes);
			end;
		end;
	end;
end;

function Actions:update_commit_size()
	self.to_commit.Size = true;
	
	if self.build_tools.preferences:get("real_time_updates") then
		local now = tick();

		if now - self.commit_debounces.Size > REAL_TIME_UPDATE_FREQUENCY then
			self.commit_debounces.Size = now;
			
			local items = self.build_tools.selection:get_pv_selection();
			
			if #items > 750 then
				return;
			end
			
			local current_index = 1;

			while current_index <= #items do
				local target_index = math.min(current_index + 40, #items)

				local send_items = table.move(items, current_index, target_index, 1, {});
				local send_sizes = {};

				for index = current_index, target_index do
					local pv_instance = items[index];

					if pv_instance:IsA("BasePart") then
						table.insert(send_sizes, pv_instance.Size);
					end
					
					current_index += 1;
				end;

				Remotes.Operations.Size:FireServer(now, send_items, send_sizes);
			end;
		end
	end
end

function Actions:modify(instance: Instance, properties: {[string]: {any}}, do_not_record: boolean?): ()
	if not properties then return end
	
	local queue = self.modify_queue;

	run_queue_thread(queue);
	table.insert(queue.instances, instance)
	
	if not queue.mapping[instance] then
		queue.mapping[instance] = #queue.instances;
	end;
	
	if not do_not_record then
		queue.record = true;
	end;
	
	local index = queue.mapping[instance];

	for property, value in properties do
		if not queue.properties[property] then
			queue.properties[property] = {[index] = value};
		else
			queue.properties[property][index] = value;
		end
	end
end

local function get_property(instance: Instance, property: string)
	return instance[property];
end

local function pv_children(instance: Instance): {PVInstance}
	local items = {}

	for _, child in instance:GetChildren() do
		if child:IsA("PVInstance") then
			table.insert(items, child);
		end;
	end;

	return items;
end

local SizeModify, CFrameModify = {"Size"}, {"CFrame"};

function Actions:bulk_modify(instances: {Instance}, properties: any, do_not_record: boolean?): ()
	local selection = self.build_tools.selection;
	local fixed_hierarchy = selection.fix_selection_hierarchy;
	
	for _, instance in instances do
		local new_properties = {};
		
		for _, property in properties do
			local success, value = pcall(get_property, instance, property);

			if success then
				new_properties[property] = value;
			end;

			if fixed_hierarchy and instance:IsA("Model") then
				if (property == "CFrame") then
					--local center, size =  instance:GetBoundingBox();
					
					--instance.WorldPivot = center;
					new_properties[property] = instance:GetPivot() -- center;

				elseif (property == "Size") then
					new_properties[property] = instance:GetScale();
				end

			elseif not fixed_hierarchy and instance:IsA("PVInstance") then
				if (property == "CFrame") then
					self:bulk_modify(pv_children(instance), CFrameModify);

				elseif (property == "Size") then
					self:bulk_modify(pv_children(instance), SizeModify);
				end
			end
		end

		self:modify(instance, new_properties, do_not_record);
	end
end

function Actions:delete(instances: {Instance}, no_deselect: boolean?): ()
	if not no_deselect then
		self.build_tools.selection:deselect();
	end;
	
	Remotes.Operations.Delete:FireServer(instances);
end

function Actions:undo()
	Remotes.Operations.Undo:FireServer();
end

function Actions:redo()
	Remotes.Operations.Redo:FireServer();
end

function Actions:gap_fill(edge_a, edge_b, extrude_direction_modifier, thickness_override, force_factor)
	Remotes.Operations.GapFill:FireServer(edge_a, edge_b, extrude_direction_modifier, thickness_override, force_factor);
end

function Actions:group(instances: {Instance})
	Remotes.Operations.Group:FireServer(instances);
end

function Actions:ungroup(instances: {Instance})
	Remotes.Operations.Ungroup:FireServer(instances);
end

function Actions:weld_all(instances: {Instance})
	Remotes.Operations.Weld:FireServer(instances);
end

function Actions:break_welds(instances: {Instance})
	Remotes.Operations.Unweld:FireServer(instances);
end

function Actions:anchor(instances: {Instance}, anchor: boolean)
	if anchor then
		Remotes.Operations.Anchor:FireServer(instances);
	else
		Remotes.Operations.Unanchor:FireServer(instances);
	end
end

table.freeze(Actions);

return Actions;