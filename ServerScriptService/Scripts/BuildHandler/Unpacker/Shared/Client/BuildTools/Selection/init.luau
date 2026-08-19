local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

-----------------------------------------------------------------------------------------------------------

local Player = Players.LocalPlayer;
local Builds = workspace:WaitForChild("Builds");
local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");
local Remotes = BuildPersistent:WaitForChild("Remotes");
local Haptics = script.Parent.Haptics;
local Assets = script.Assets;

-----------------------------------------------------------------------------------------------------------

local GetBoundingBox = require( script.GetBoundingBox )

local Signal = require( ReplicatedStorage.Packages.Signal )
local Table = require( ReplicatedStorage.Packages.Table )
local Math = require( ReplicatedStorage.Packages.Math )
local Maid = require( ReplicatedStorage.Packages.Maid )
local InstanceCache = require( ReplicatedStorage.Packages.InstanceCache )
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local Observer = require( ReplicatedStorage.Packages.Observer )
local NotificationStatus = require( BuildShared.Data.NotificationStatus )
local InstanceAllowed = require( BuildShared.Data.InstanceAllowed )
local Geometry = require( BuildShared.Utility.GapFill.Geometry )
local HelpInput = require( ReplicatedStorage.Packages.HelpInput )

-----------------------------------------------------------------------------------------------------------

local HighlightCache = InstanceCache.new(8, Assets.Highlight) :: InstanceCache.InstanceCache<typeof(Assets.Highlight)>
HighlightCache.limit = true;

local HighlightBoxCache = InstanceCache.new(1, Assets.HighlightBox) :: InstanceCache.InstanceCache<typeof(Assets.HighlightBox)>

-----------------------------------------------------------------------------------------------------------

export type ItemTracker = {
	parent: Instance, 
	maid: Maid.Maid, 
	highlight: (Highlight | SelectionBox)?, 
	index: number,
	collision_group: string?,
};

export type ClassSelection = {
	__index: ClassSelection;

	new: (build_tools: any) -> (Selection);
	init: (self: Selection) -> ();
	is_drag_detector_enabled: (self: Selection) -> boolean;
	set_drag_detector_enabled: (self: Selection, value: boolean) -> ();
	init_handles: (self: Selection) -> ();
	destroy: (self: Selection) -> ();
	get_ordered: (self: Selection) -> {Instance};
	get: (self: Selection) -> {Instance};
	next: (self: Selection) -> Instance?;
	sample: (self: Selection, sample: number) -> (...Instance);
	update_hover_box: (self: Selection) -> ();
	update_hover: (self: Selection) -> ();
	get_hover_edge: (self: Selection) -> ();
	draw_face: (parent: unknown, face: unknown, color: unknown, trans: unknown, zmod: unknown) -> ();
	show_hover_edge: (self: Selection, face: unknown) -> ();
	hide_hover_edge: (self: Selection) -> ();
	set_first_edge: (self: Selection, edge: unknown) -> ();
	get_cursor_coordinate_move: (self: Selection) -> (CFrame, RaycastResult?);
	get_cursor_face_pivot_move: (self: Selection, coordinate: CFrame, result: RaycastResult, bounds_size: Vector3) -> CFrame;
	move_to_cursor: (self: Selection) -> ();
	set_pivot: (self: Selection, pivot: CFrame) -> ();
	translate_by: (self: Selection, coordinate: Vector3) -> ();
	rotate_by: (self: Selection, angle: CFrame, is_local: boolean?) -> ();
	pivot_item: (self: Selection, pv_instance: PVInstance, bounding_cf: CFrame, coordinate: CFrame) -> ();
	pivot_to: (self: Selection, coordinate: CFrame) -> ();
	move_to: (self: Selection, coordinate: CFrame) -> ();
	scale_by: (self: Selection, dt: number) -> ();
	get_scale: (self: Selection) -> number;
	get_pivot: (self: Selection) -> CFrame;
	get_world_pivot: (self: Selection) -> CFrame;
	get_world_pivot_position: (self: Selection) -> CFrame;
	get_bounding_box: (self: Selection, orientation: CFrame?) -> (CFrame, Vector3);
	set_hover_instance: (self: Selection, instance: Instance?) -> ();
	get_outermost_model: (self: Selection, instance: Instance) -> Model?;
	cast_ray: (self: Selection, cursor_ray: Ray, ray_params: RaycastParams?, distance: number?) -> (RaycastResult, CFrame);
	cast_screen_ray: (self: Selection, rayParams: unknown) -> (RaycastResult, CFrame);
	get_selection_between_screen_points: (self: Selection, p1: Vector2, p2: Vector2) -> {Instance};
	update_all: (self: Selection) -> ();
	update_extents: (self: Selection, origin: CFrame?, size: Vector3?) -> ();
	is_selected: (self: Selection, instance: Instance) -> boolean;
	is_empty: (self: Selection) -> boolean;
	ready_multi_selection: (self: Selection) -> ();
	update_selection_rectangle: (self: Selection) -> ();
	start_multi_selection: (self: Selection, is_explorer: boolean?) -> ();
	end_multi_selection: (self: Selection) -> ();
	update_attachments_selected: (self: Selection) -> ();
	set_descendant_select_visibility: (self: Selection, instance: Instance, value: boolean) -> ();
	click_select_instance: (self: Selection, instance: Instance) -> ();
	deselect_instance: (self: Selection, instance: Instance) -> ();
	select_instance: (self: Selection, instance: Instance) -> ();
	is_selectable: (self: Selection, instance: Instance) -> boolean;
	get_pv_selection: (self: Selection) -> {PVInstance};
	get_physical_selection: (self: Selection) -> {PVInstance | Attachment};
	is_pivotable: (self: Selection, instance: Instance) -> boolean;
	update_traverse_hierarchy: (self: Selection, instance: PVInstance, tree: {[PVInstance]: boolean}) -> Instance?;
	update_hierarchy_resolve: (self: Selection, instance: PVInstance, tree: {[PVInstance]: boolean}) -> ();
	update_hierarchy: (self: Selection, instance: PVInstance) -> ();
	hook_hierarchy_resolver: (self: Selection, instance: PVInstance, item_tracking: ItemTracker) -> ();
	hook_collision_tracker: (self: Selection, instance: BasePart, item_tracking: ItemTracker) -> ();
	hook_attachment_visuals: (self: Selection, instance: Attachment, item_tracking: ItemTracker) -> ();
	deselect: (self: Selection, selection: {Instance}?) -> ();
	select: (self: Selection, selection: {Instance}) -> ();
	update_hover_edge: (self: Selection) -> ();
	set_hover_to_stylus_instance: (self: Selection) -> ();
};

export type Selection = typeof(setmetatable({} :: {
	
	update_flag: () -> ();
	update_reancestry: () -> ();
	
	build_tools: any;

	maid: Maid.Maid;
	multiselection_maid: Maid.Maid;

	selection_rectangle: any;
	explorer_body: any;
	selection_explorer: any;

	items: {[Instance]: ItemTracker};
	pivot_items: {[PVInstance]: boolean};
	physical_items: {[PVInstance]: boolean};
	
	hover: Instance?;
	last_selected: Instance?;
	count: number;
	max: number;
	scale: number;

	dragger: typeof(Assets.DragDetector);
	extents_part: typeof(Assets.SelectionBoundsHandle);
	extents_selection_box: typeof(Assets.SelectionBoundsHandle.SelectionBox);
	extents_hover_part: typeof(Assets.SelectionHoverBoundsHandle);
	extents_hover_selection_box: typeof(Assets.SelectionHoverBoundsHandle.SelectionBox);
	
	raycast_params: RaycastParams;
	raycast_full_params: RaycastParams;
	raycast_build_params: RaycastParams;
	
	pivot: CFrame?;
	only_attachments_selected: boolean;
	is_multiselecting: boolean;
	multiselection_type: string;
	multiselection_start: Vector2?;
	canvas_position_start: Vector2;
	drag_start: Vector2?;

	allow_dragging: boolean;
	fix_selection_hierarchy: boolean;
	
	hover_instance_box: SelectionBox?;
	hover_instance: Instance?;
	
	hover_edge: any;
	first_edge: any;
	first_hover_edge: any;

	on_selection_lost: Signal.Signal<>;
	on_selection_begin: Signal.Signal<>;
	on_selection_removed: Signal.Signal<Instance>;
	on_selection_added: Signal.Signal<Instance>;
	on_selection_changed: Signal.Signal<{Instance}, number, boolean>;
	on_selection_reancestry: Signal.Signal<>;
	
}, {} :: ClassSelection));

-----------------------------------------------------------------------------------------------------------

local Selection = {} :: ClassSelection;
Selection.__index = Selection;

function Selection.new(build_tools)
	local maid = build_tools.maid:limb()
	local multiselection_maid = build_tools.maid:limb();
	local explorer_body = build_tools.elements.Main.BodyRight.Explorer.Body.Body.Body;
	
	local extents_part = maid:add(Assets.SelectionBoundsHandle:Clone());
	local extents_hover_part = maid:add(Assets.SelectionHoverBoundsHandle:Clone());
	
	local self = setmetatable(
		{
			build_tools = build_tools;

			maid = maid;
			multiselection_maid = multiselection_maid;

			selection_rectangle = build_tools.elements.Main.Selection;
			explorer_body = explorer_body;
			selection_explorer = explorer_body.Body;
			
			items = {} :: {[Instance]: ItemTracker};
			pivot_items = {} :: {[PVInstance]: boolean};
			physical_items = {} :: {[PVInstance]: boolean};
			last_selected = nil;
			
			count = 0;
			max = 1_000;
			scale = 1;

			dragger = maid:add(Assets.DragDetector:Clone());
			
			extents_hover_part = extents_hover_part;
			extents_hover_selection_box = extents_hover_part.SelectionBox;
			extents_part = extents_part;
			extents_selection_box = extents_part.SelectionBox;

			raycast_params = RaycastParams.new();
			raycast_full_params = RaycastParams.new();
			raycast_build_params = RaycastParams.new();
			
			only_attachments_selected = false;
			is_multiselecting = false;
			multiselection_type = "viewport";
			multiselection_start = nil;
			drag_start = nil;

			allow_dragging = false;
			fix_selection_hierarchy = true;

			on_selection_lost = maid:add(Signal.new());
			on_selection_begin = maid:add(Signal.new());
			on_selection_removed = maid:add(Signal.new());
			on_selection_added = maid:add(Signal.new());
			on_selection_changed =maid:add( Signal.new());
			on_selection_reancestry =maid:add(Signal.new());
		}, 
		Selection);
	
	return self;
end;

function Selection:init()
	self.raycast_params.CollisionGroup = "BuildPlacement"
	self.raycast_params.FilterType = Enum.RaycastFilterType.Exclude

	self.raycast_build_params.FilterDescendantsInstances = {Builds}
	self.raycast_build_params.FilterType = Enum.RaycastFilterType.Include
	
	self.raycast_full_params.FilterDescendantsInstances = { Builds };
	self.raycast_full_params.FilterType = Enum.RaycastFilterType.Include
	
	if workspace:FindFirstChild("Map") then
		self.raycast_full_params:AddToFilter(workspace.Map);
	end;
	
	self.dragger.Archivable = false;
	self.dragger.ReferenceInstance = self.extents_part;
	
	self.extents_hover_part.Archivable = false;
	self.extents_hover_part.CollisionGroup = "BuildPlacement";
	self.extents_hover_part.Parent = workspace.CurrentCamera;
	
	self.extents_part.Archivable = false;
	self.extents_part.CollisionGroup = "BuildPlacement";
	self.extents_part.Parent = workspace.CurrentCamera;
	
	do
		local quick_tap_fix_flag = false;
		
		self.dragger.DragStart:Connect(function()
			quick_tap_fix_flag = true;
		end)
		
		self.dragger.DragEnd:Connect(function()
			quick_tap_fix_flag = false;
		end)
		
		self.dragger:SetDragStyleFunction(function(...)
			if not quick_tap_fix_flag then return end;
			
			self:move_to_cursor();
			self:update_extents();
		end)
	end;
	
	self.maid:add(self.build_tools.preferences:observe("use_drag_detectors", function(value)
		self:set_drag_detector_enabled( value )
	end))
	
	self.maid:add(Remotes.CaptureSelection.OnClientEvent:Connect(function(instances)
		self:deselect();
		self:select(instances);
	end))
	
	self.maid:add(Remotes.ReliableCaptureSelection.OnClientEvent:Connect(function(tag, count)
		local all_select = {};
		
		local stop_observing; stop_observing = Observer.observe_tag(tag, function(instance: Instance)
			table.insert(all_select, instance);

			if #all_select >= count then
				self:deselect();
				task.defer(self.select, self, all_select);
				task.defer(stop_observing);
			end
		end);

		task.delay(30, stop_observing)
	end))
	
	self:init_handles();
end

function Selection:is_drag_detector_enabled()
	return self.dragger.Parent == self.extents_part;
end

function Selection:set_drag_detector_enabled(value: boolean)
	if value then
		self.dragger.Parent = self.extents_part;
	else
		self.dragger.Parent = nil;
	end
end

function Selection:init_handles()
	do
		local thread: thread?;
		
		function self.update_flag()
			if thread then return end;
			
			thread = task.defer(function()
				thread = nil;
				
				if self.update_all then
					self:update_all();
				end;
			end)
		end
	end
	
	do
		local thread: thread?;

		function self.update_reancestry(instance: Instance?)
			if thread or (instance and not instance.Archivable) then return end;
			
			thread = task.defer(function()
				thread = nil;
				self.on_selection_reancestry:Fire();
			end)
		end
	end
end

function Selection:destroy()
	self.maid:destroy();
	self:deselect();
	Table.dispose(self);
end

function Selection:get_ordered()
	local array = table.create(self.count);

	for instance, item_tracking in self.items do
		if array[item_tracking.index] then
			warn("array count overlap occurred");
		end;

		array[item_tracking.index] = instance;
	end;

	return array;
end

function Selection:get(): {Instance}
	return Table.keys(self.items);
end

function Selection:next(): Instance?
	return next(self.items);
end;

function Selection:sample(sample: number): (...Instance)
	local items = {};
	local item, count = next(self.items), 0;
	
	while item and count <= sample do
		table.insert(items, item);
		
		item = next(self.items, item);
		count += 1;
	end;
	
	return unpack(items);
end

do
	local function getSimpleExtension(fromPart: BasePart, point: Vector3, dir: Vector3): (BasePart?, number?)
		local params = OverlapParams.new();
		params.FilterDescendantsInstances = {fromPart};
		
		local parts = workspace:GetPartBoundsInBox(CFrame.new(point), Vector3.new(0.1, 0.1, 0.1), params);
		
		for _, part in parts do
			local geometry = Geometry.getGeometry(part, point);
			
			for _, edge in geometry.edges do
				local dot = edge.direction:Dot(dir)
				
				if dot > 0.99 and (edge.a - point).Magnitude < 0.01 then
					return part, edge.length;
					
				elseif dot < -0.99 and (edge.b - point).Magnitude < 0.01 then
					return part, edge.length;
				end;
			end;
		end;
		
		return nil, nil;
	end;
	
	-- Try to extend an edge out in each direction
	local function tryExtendEdgePositive(fromPart, edge): BasePart?
		-- Try to extend the edge in each direction
		local newFrom, extB = getSimpleExtension(fromPart, edge.b, edge.direction);
		
		if extB then
			edge.b += edge.direction * extB;
			edge.length += extB;
			
			return newFrom;
		end;
		
		return nil;
	end

	local function tryExtendEdgeNegative(fromPart, edge): BasePart?
		local newFrom, extA = getSimpleExtension(fromPart, edge.a, -edge.direction)
		
		if extA then
			edge.a -= edge.direction * extA;
			edge.length += extA;
			
			return newFrom;
		end;
		
		return nil;
	end

	function getHoverEdgeSimple(hit: RaycastResult)
		local point = hit.Position
		local geom = Geometry.getGeometry(hit.Instance, point)
		
		local bestEdge, bestDist = nil, math.huge;

		for _, edge in pairs(geom.edges) do
			local dist = (point - edge.a - edge.direction*(point - edge.a):Dot(edge.direction)).magnitude;
			
			if dist < bestDist then
				bestDist = dist;
				bestEdge = edge;
			end;
		end;
		
		if bestEdge then
			bestEdge.click = point;
			
			if (bestEdge.a - bestEdge.click).magnitude < (bestEdge.b - bestEdge.click).magnitude then
				bestEdge.a, bestEdge.b = bestEdge.b, bestEdge.a;
				bestEdge.direction = -bestEdge.direction;
			end;
		end;
		
		local bestFace, bestDist = nil, math.huge;
		
		for _, face in geom.faces do
			local dist = math.abs((point - face.point):Dot(face.normal));
			
			if dist < bestDist then
				bestDist = dist;
				bestFace = face;
			end;
		end;
		
		return bestEdge, bestFace;
	end

	local function getPrimaryEdge(result: RaycastResult)
		-- Try to use raycasts to identify the closest mesh edge for MeshParts / Unions
		if result.Instance:IsA("MeshPart") or result.Instance:IsA("UnionOperation") then
			local edge = Geometry.blackboxFindClosestMeshEdge(result, workspace.CurrentCamera.CFrame.LookVector);
			
			if edge then
				edge.click = result.Position;
				return edge;
			end
		end

		-- Failing that, just use the simple getGeometry based result
		return getHoverEdgeSimple(result)
	end

	local EXTEND_EDGE = false;
	
	function Selection:get_hover_edge()
		local result = self:cast_screen_ray(self.raycast_build_params);

		if result then
			local primaryEdge, bestFace = getPrimaryEdge(result)
			
			if EXTEND_EDGE then
				local fromPart = primaryEdge.part
				
				while fromPart do
					fromPart = tryExtendEdgePositive(fromPart, primaryEdge)
				end
				
				fromPart = primaryEdge.part
				
				while fromPart do
					fromPart = tryExtendEdgeNegative(fromPart, primaryEdge)
				end
			end
			
			return primaryEdge, bestFace
		else
			return nil;
		end
	end
end;

function Selection:draw_face(parent, face, color, trans, zmod)
	local scale = math.max(face.vertexMargin, 0.15) / 8
	if scale > 0.2 then
		scale = 0.2
	end

	local segmentCFrame = CFrame.new(face.a, face.b) * CFrame.new(0, 0, -face.length/2)
	local tipLength = math.min(0.3 * face.length, scale * 15)
	local tipRadius = 0.5 * tipLength
	local shaftRadius = 0.5 * 0.5 * math.min(0.3 * face.length, scale * 7)

	local line = Instance.new('CylinderHandleAdornment')
	line.CFrame = segmentCFrame * CFrame.new(0, 0, tipLength/2) * CFrame.Angles(0, 0, math.pi/2)
	line.Adornee = workspace.Terrain
	line.ZIndex = 0 + zmod
	line.Height = face.length - tipLength
	line.Radius = shaftRadius
	line.Color3 = color
	line.Transparency = trans
	line.Parent = parent
	line.AlwaysOnTop = false

	local lineOnTop = line:Clone()
	lineOnTop.Parent = parent
	lineOnTop.Transparency = 0.7
	lineOnTop.AlwaysOnTop = true

	local head = Instance.new('ConeHandleAdornment')
	head.CFrame = segmentCFrame * CFrame.new(0, 0, -(face.length/2 - tipLength)) * CFrame.Angles(0, 0, math.pi/2)
	head.Adornee = workspace.Terrain
	head.ZIndex = 1 + zmod
	head.Height = tipLength
	head.Radius = tipRadius
	head.Color3 = color
	head.Transparency = trans
	head.Parent = parent
	head.AlwaysOnTop = false

	local headOnTop = head:Clone()
	headOnTop.Parent = parent
	headOnTop.Transparency = 0.7
	headOnTop.AlwaysOnTop = true

	return {line, head, lineOnTop, headOnTop}
end

function Selection:show_hover_edge(face)
	self:hide_hover_edge();
	self.hover_edge = self:draw_face(workspace.Terrain, face, Color3.fromRGB(135, 255, 98), 0, 2)
end

function Selection:hide_hover_edge()
	if self.hover_edge then
		for _, instance in self.hover_edge do
			instance:Destroy();
		end;
		
		self.hover_edge = nil;
	end;
end

function Selection:update_hover_edge(): ()
	local hoverEdge = self:get_hover_edge();

	if hoverEdge then
		self:show_hover_edge(hoverEdge);
	else
		self:hide_hover_edge();
	end;
end;

function Selection:set_first_edge(edge)
	if self.first_edge ~= edge then
		self.first_edge = edge
		
		if self.first_hover_edge then
			for _, instance in self.first_hover_edge do
				instance:Destroy();
			end;
		end;
		
		if edge then
			self.first_hover_edge = self:draw_face(workspace.Terrain, edge, Color3.fromRGB(119, 56, 255), 0, 2);
		end;
	end;
end

function Selection:set_hover_to_stylus_instance()
	local hit = self:cast_screen_ray(self.raycast_build_params)

	if hit and hit.Instance and not hit.Instance.Locked then
		self:set_hover_instance(hit.Instance);
	else
		self:set_hover_instance(nil);
	end
end

function Selection:get_cursor_coordinate_move(): (CFrame, RaycastResult?)
	local result, cf = self:cast_screen_ray();
	
	if result then
		return cf.Rotation + self.build_tools.draggers:round_to_move_increment(cf.Position), result;
	else
		return cf, nil;
	end;
end

function Selection:get_cursor_face_pivot_move(coordinate: CFrame, result: RaycastResult, bounds_size: Vector3): CFrame
	return CFrame.new((coordinate - (result.Normal * result.Normal:Dot(coordinate.Position - result.Position))).Position + result.Normal * math.abs(CFrame.lookAlong(Vector3.zero, result.Normal):VectorToObjectSpace(bounds_size).Z) / 2)
end

function Selection:move_to_cursor(): ()
	local cf, result = self:get_cursor_coordinate_move();
	
	if result then
		if self.build_tools.draggers.alignment_mode == "FacePivot" then
			local _, size = self:get_bounding_box();
			
			self:pivot_to( self:get_cursor_face_pivot_move(cf, result, size) );
			
		elseif self.build_tools.draggers.alignment_mode == "Pivot" then
			self:pivot_to( cf );

		elseif self.build_tools.draggers.alignment_mode == "Move" then
			self:move_to( cf );
		end;
	else
		self:pivot_to( cf );
	end;
end

function Selection:set_pivot(pivot: CFrame): ()
	self.pivot = (pivot);
	self.build_tools.actions.to_commit["CFrame"] = true;
end

function Selection:translate_by(coordinate: Vector3): ()
	if self.only_attachments_selected then
		if self.build_tools.draggers.local_space then
			for attachment in self.items do
				attachment.CFrame += attachment.CFrame.Rotation * coordinate;
			end;
		else
			for attachment in self.items do
				attachment.WorldCFrame += coordinate;
			end;
		end
	else
		for pv_instance: PVInstance in self.pivot_items do
			pv_instance:PivotTo(pv_instance:GetPivot() + coordinate);
		end;
	end
	
	self:update_extents();
	self.build_tools.actions:update_commit_cframe();
end

function Selection:rotate_by(angle: CFrame, is_local: boolean?, origin: CFrame?)
	if not origin then
		origin = self:get_bounding_box();
	end;
	
	if self.only_attachments_selected then
		if is_local then
			for attachment in self.items do
				attachment.CFrame *= angle;
			end;
		else
			for attachment in self.items do
				attachment.CFrame = angle * attachment.CFrame.Rotation + attachment.Position;
			end;
		end
		
		self:update_extents();
	else
		local pivot: CFrame = self:get_pivot();
		
		if is_local then
			for pv_instance in self.pivot_items do
				pv_instance:PivotTo(pv_instance:GetPivot() * angle);
			end;
			
			self:update_extents();
		else
			self:pivot_to( pivot * angle, origin )
		end
	end
	
	self.build_tools.actions:update_commit_cframe();
end

local mouse = Player:GetMouse()

function Selection:pivot_item(pv_instance: PVInstance, bounding_cf: CFrame, coordinate: CFrame): ()
	local pv_pivot = pv_instance:GetPivot();
	local pv_dif = bounding_cf:ToObjectSpace(pv_pivot);

	-- Honestly, BulkMoveTo would just be a right hassle to get working, PivotTo works on models, BulkMoveTo does not.
	-- Its not a super simple change and for the performance benefit, I really cannot be bothered. It is much easier to implement on the server-side.
	pv_instance:PivotTo(coordinate * pv_dif);
end
	
--No rounding
function Selection:pivot_to(coordinate: CFrame, origin: CFrame?): ()
	if not origin then
		origin = self:get_bounding_box();
	end;
	
	if self.only_attachments_selected then
		for attachment in self.items do
			attachment.WorldCFrame = coordinate;
		end;
	else
		for pv_instance in self.pivot_items do
			self:pivot_item(pv_instance, origin, coordinate);
		end
	end
	
	self:update_extents();
	self.build_tools.actions:update_commit_cframe();
end

--No rounding
function Selection:move_to(coordinate: CFrame): ()
	self:update_extents();
	self.build_tools.actions:update_commit_cframe();
end

--No rounding
function Selection:scale_by(dt: number?)
	local dt = dt or 0;
	
	for pv_instance in self.pivot_items do
		if pv_instance:IsA("Model") then
			local scale = pv_instance:GetScale();
			local scale_factor = math.max( 0.005, scale + dt );
			
			pv_instance:ScaleTo(scale_factor);
			
		elseif pv_instance:IsA("BasePart") then
			pv_instance.Size *= 1 + 16 * dt / pv_instance.Size.Magnitude;
		end
	end
	
	self:update_extents();
	
	self.build_tools.actions:update_commit_cframe();
	self.build_tools.actions:update_commit_size();
end

function Selection:get_scale(): number
	return 1;
end

function Selection:get_pivot(): CFrame
	local cf = self:get_bounding_box();
	
	return cf;
end

function Selection:get_world_pivot(): CFrame
	return self.pivot or CFrame.identity;
end

function Selection:get_world_pivot_position(): CFrame
	return CFrame.new(self:get_world_pivot().Position);
end

function Selection:get_bounding_box(orientation: CFrame?): (CFrame, Vector3)
	return GetBoundingBox(self.pivot_items, orientation or CFrame.identity);
end;

function Selection:set_hover_instance(instance: Instance?)
	local last_instance = self.hover_instance;
	
	if (instance ~= last_instance) then
		if self.hover_instance_box then
			self.hover_instance_box:Destroy();
		end;
		
		if instance then
			self.hover_instance_box = Assets.HighlightHoverBox:Clone();
			assert(self.hover_instance_box);
			
			self.hover_instance_box.Adornee = instance;
			self.hover_instance_box.Archivable = false;
			self.hover_instance_box.Parent = instance;
		end;
		
		self.hover_instance = instance;
	end;
end

function Selection:update_hover_box()
	if self.hover and not self:is_selected(self.hover) then
		local origin, size = GetBoundingBox({[self.hover] = true}, CFrame.identity)

		self.extents_hover_part.CFrame = origin;
		self.extents_hover_part.Size = size + Vector3.one * 0.01;
		self.extents_hover_selection_box.Visible = size ~= Vector3.zero;
	else
		self.extents_hover_part.Size = Vector3.zero;
		self.extents_hover_selection_box.Visible = false;
	end
end

function Selection:update_hover()
	local result, cf = self:cast_screen_ray(self.raycast_build_params);
	local selected: Instance;
	local model: Model?;
	
	if result and not (result.Instance:IsA("BasePart") and result.Instance.Locked) then
		if self.build_tools:is_alt_down() then
			selected = result.Instance;
		else
			model = self:get_outermost_model(result.Instance);
			selected = if model then model else result.Instance;
		end
	end;
	
	if self.hover ~= selected then
		self.hover = selected;
		self:update_hover_box()
	end;
	
	return selected;
end

function Selection:get_outermost_model(instance: Instance): Model?
	local model = instance:FindFirstAncestorOfClass("Model");
	
	if model then
		return self:get_outermost_model(model);

	elseif instance:IsA("Model") then
		return instance;
	end;

	return nil;
end

function Selection:cast_ray(cursor_ray: Ray, ray_params: RaycastParams?, distance: number?): (RaycastResult, CFrame)
	if not ray_params then
		ray_params = self.raycast_params;
	end
	
	local distance = distance or 2048;
	local raycast = workspace:Raycast(cursor_ray.Origin, cursor_ray.Direction * distance, ray_params)
	local target = CFrame.identity;

	if raycast then
		target = CFrame.new(raycast.Position);
	else
		target = CFrame.new(cursor_ray.Origin + cursor_ray.Direction * distance);
	end
	
	return raycast, target;
end

function Selection:cast_screen_ray(rayParams): (RaycastResult, CFrame)
	local mouse_pos = UserInputService:GetMouseLocation();
	local ray = workspace.CurrentCamera:ViewportPointToRay(mouse_pos.X, mouse_pos.Y);

	return self:cast_ray(ray, rayParams);
end

function Selection:get_selection_between_screen_points(p1: Vector2, p2: Vector2)
	-- if folders exist please make it recursive
	local selection = {};
	local rect = Rect.new(p1, p2);
	
	local is_alt_down = self.build_tools:is_alt_down();
	local children = if is_alt_down then Builds:GetDescendants() else Builds:GetChildren();
	
	for _, instance in children do
		if instance:IsA("PVInstance") then
			local pv_position: CFrame;
			local is_locked = false;
			
			if instance:IsA("Model") then
				if is_alt_down then continue end;
				
				pv_position = instance:GetBoundingBox();
				is_locked = instance:HasTag("ModelLocked");
			else
				pv_position = instance:GetPivot();
				is_locked = instance:IsA("BasePart") and instance.Locked;
			end;
			
			local position, in_view = workspace.CurrentCamera:WorldToViewportPoint(pv_position.Position);
			
			if not is_locked and in_view and Math.InRect(Vector2.new(position.X, position.Y), rect) then
				table.insert(selection, instance);
			end;
		end;
	end;
	
	return selection;
end

function Selection:update_all()
	self:update_extents();
	
	if self.build_tools.draggers.update_handles then
		self.build_tools.draggers:update_handles();
	end;
end

function Selection:update_extents(origin: CFrame?, size: Vector3?)
	if not origin then
		origin, size = self:get_bounding_box();
	end;
	
	if self.only_attachments_selected then
		local attachment = self:next();
		
		if self.build_tools.draggers.local_space then
			self.extents_part.CFrame = attachment.WorldCFrame;
		else
			self.extents_part.CFrame = CFrame.new(attachment.WorldPosition);
		end
		
		self.extents_part.Size = Vector3.one * 0.275;
		self.extents_selection_box.Visible = true;
	else
		self.extents_part.CFrame = origin;
		
		if size then
			self.extents_part.Size = size + Vector3.one * 0.01;
			self.extents_selection_box.Visible = size ~= Vector3.zero;
		end;
	end;
end

function Selection:is_selected(instance: Instance): boolean
	return self.items[instance] ~= nil;
end

function Selection:is_empty(): boolean
	return next(self.items) == nil;
end

function Selection:ready_multi_selection()
	if self.is_multiselecting then
		self:end_multi_selection();
	end;
	
	self.drag_start = UserInputService:GetMouseLocation();
	self.allow_dragging = false;
end

function Selection:update_selection_rectangle()
	if not self.is_multiselecting or not self.multiselection_start then return end;
	
	local selection_start: Vector2 = self.multiselection_start;
	local selection_end: Vector2 = UserInputService:GetMouseLocation();
	local inset: Vector2 = GuiService:GetGuiInset();
	
	if self.multiselection_type == "explorer" then
		local abs_position: Vector2 = self.selection_explorer.SelectionContainer.AbsolutePosition;
		local canvas = self.selection_explorer.ScrollingFrame.CanvasPosition;
		local start = self.canvas_position_start;
		
		selection_start -= (canvas - start) + abs_position;
		selection_end -= abs_position;
	end
	
	self.selection_rectangle.Size = UDim2.fromOffset(
		math.abs(selection_end.X - selection_start.X),
		math.abs(selection_end.Y - selection_start.Y)
	)

	self.selection_rectangle.Position = UDim2.fromOffset(
		(selection_start.X + (selection_end.X - selection_start.X) / 2),
		(selection_start.Y + (selection_end.Y - selection_start.Y) / 2)
	) 
	- UDim2.fromOffset(inset.X, inset.Y)
	
	self.selection_rectangle.Visible = (selection_start ~= selection_end)
end

function Selection:start_multi_selection(is_explorer: boolean?)
	self:end_multi_selection();
	
	HelpInput.LockCameraRotation();
	pcall(Haptics.SelectionStart.Play, Haptics.SelectionStart);
	
	local position = UserInputService:GetMouseLocation();
	
	self.multiselection_start = position;
	self.is_multiselecting = true;
	
	if is_explorer then
		self.multiselection_type = "explorer";
		self.canvas_position_start = self.selection_explorer.ScrollingFrame.CanvasPosition;
		
		self:update_selection_rectangle();
		self.selection_rectangle.Visible = true;
		self.selection_rectangle.Parent = self.selection_explorer.SelectionContainer;
		
		self.multiselection_maid:add(self.selection_explorer.ScrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			self:update_selection_rectangle()
		end))
	else
		self.multiselection_type = "viewport";
		
		self:update_selection_rectangle();
		self.selection_rectangle.Visible = true;
		self.selection_rectangle.Parent = self.build_tools.ui.Miscellaneous;
	end
end

function Selection:end_multi_selection()
	if not self.is_multiselecting then return end;
	
	self.is_multiselecting = false;
	HelpInput.UnlockCameraRotation();
	
	if self.multiselection_type == "viewport" then
		local selection_end = UserInputService:GetMouseLocation();
		local parts = self:get_selection_between_screen_points(self.multiselection_start or Vector2.zero, selection_end);

		self:select(parts)
	else
		local inset = GuiService:GetGuiInset();
		local rect = Rect.new(
			self.selection_rectangle.AbsolutePosition - inset, 
			self.selection_rectangle.AbsolutePosition + self.selection_rectangle.AbsoluteSize - inset
		);
		local parts = self.build_tools:get_instances_in_bounds_of_explorer(rect)
		
		if not self.build_tools:is_control_down() then
			self:deselect();
		end;
		
		self:select(parts)
	end;
	
	self.multiselection_start = nil;
	self.selection_rectangle.Visible = false;
	self.multiselection_maid:clean();
end

local function is_selection_all_attachments(self: Selection): boolean
	for instance: Instance in self.items do
		if instance.ClassName ~= "Attachment" then
			return false;
		end
	end

	return not self:is_empty();
end

function Selection:update_attachments_selected()
	local last_value = self.only_attachments_selected;
	local new_value = is_selection_all_attachments(self);
	
	self.only_attachments_selected = new_value
	
	if last_value ~= new_value then
		self.only_attachments_selected = new_value
	end;
end

function Selection:set_descendant_select_visibility(instance: Instance, value: boolean)
	for _, child in instance:GetDescendants() do -- Observer.get_tagged("BuildToolsSelectVisible") do
		--if not child:IsDescendantOf(instance) then
		--	continue;
		--end;
		
		if child:HasTag("BuildToolsSelectVisible") then
			if instance:IsA("Beam") then
				instance.Enabled = value;

			elseif instance:IsA("SelectionBox") then
				instance.Visible = value;
			end
		end;
	end
end

function Selection:click_select_instance(instance: Instance)
	if self.items[instance] then
		self:deselect_instance(instance);
	else
		self:select_instance(instance);
	end
end

function Selection:deselect_instance(instance: Instance): ()
	return self:deselect({instance});
end

function Selection:select_instance(instance: Instance): ()
	return self:select({instance});
end

function Selection:is_selectable(instance: Instance): boolean
	if not ( InstanceAllowed.can_modify(instance) or instance:HasTag("Placement") ) or instance == self.extents_part 
		--or instance:HasTag("SelectionIgnore")  
	then
		return false;
	end;
	
	return true;
end

function Selection:get_physical_selection()
	local selection = Table.keys(self.pivot_items);
	
	for item in self.items do
		if item:IsA("Attachment") then
			table.insert(selection, item);
		end;
	end;
	
	return selection;
end

function Selection:get_pv_selection(): {PVInstance}
	return Table.keys(self.pivot_items);
end

function Selection:is_pivotable(instance: Instance): boolean
	return instance:IsA("PVInstance") and instance:IsDescendantOf(Builds);
end

function Selection:update_traverse_hierarchy(instance: PVInstance, tree: {[PVInstance]: boolean}): Instance?
	local parent = instance.Parent;

	while parent and parent ~= Builds do
		local pv = self.pivot_items[parent] or tree[parent];

		if parent then
			self:update_hierarchy_resolve(parent, tree);
		end;

		if pv then
			return parent;
		end

		parent = parent.Parent;
	end

	return nil;
end

function Selection:update_hierarchy_resolve(instance: PVInstance, tree: {[PVInstance]: boolean})
	local item_tracking = self.items[instance];
	if not item_tracking then return end;

	local hierarch = self:update_traverse_hierarchy(instance, tree);
	local pv_tracked = self.pivot_items[instance] or tree[instance];
	
	if not hierarch and not pv_tracked then
		tree[instance] = true;

	elseif hierarch and pv_tracked then
		tree[instance] = false;
	end
	
	return tree;
end

function Selection:update_hierarchy(instance: PVInstance): ()
	local tree = self:update_hierarchy_resolve(instance, {});
	
	for pv_item, value in tree do
		local item_tracking = self.items[pv_item];
		local highlight = item_tracking.highlight;
		
		if value then
			if not instance:IsA("Part") then
				highlight = HighlightCache:get()
				
				if highlight then
					highlight.Adornee = instance;
					highlight.Enabled = true;
					highlight.Archivable = false;
					highlight.Parent = instance;
					
					item_tracking.highlight = highlight;
				end;
			end
			
			if not highlight then
				highlight = HighlightBoxCache:get();
				highlight.Adornee = instance;
				highlight.Visible = true;
				highlight.Archivable = false;
				highlight.Parent = instance;

				item_tracking.highlight = highlight
			end;
			
			if self.build_tools.preferences:get("no_selection_collision") then
				if instance:IsA("BasePart") then
					self:hook_collision_tracker(instance, item_tracking);
				end;
				
				for _, child in pv_item:GetDescendants() do
					if child:IsA("BasePart") then
						self:hook_collision_tracker(child, item_tracking);
					end;
				end
			end
			
			pv_item:AddTag("NoCameraOcclusion");
			
			self.pivot_items[pv_item] = true;
		else
			if highlight then
				if highlight:IsA("SelectionBox") then
					highlight.Adornee = nil;
					highlight.Visible = false;
					HighlightBoxCache:release(highlight);
				else
					highlight.Enabled = false;
					highlight.Adornee = nil;
					highlight.Parent = Builds;
					HighlightCache:release(highlight);
				end
			
				item_tracking.highlight = nil;
			end
			
			pv_item:RemoveTag("NoCameraOcclusion");
			
			self.pivot_items[pv_item] = nil;
		end
	end
end

function Selection:hook_hierarchy_resolver(instance: PVInstance, item_tracking: ItemTracker): ()
	self:update_hierarchy(instance);
	
	item_tracking.maid:add(instance.AncestryChanged:Connect(function()
		self:update_hierarchy(instance);
	end))
end

function Selection:hook_collision_tracker(instance: BasePart, item_tracking: ItemTracker): ()
	local attribute = "_TEMP_cg";
	
	instance:SetAttribute(attribute, instance.CollisionGroup);
	instance.CollisionGroup = "BuildPlacement";

	item_tracking.maid:add(instance:GetPropertyChangedSignal("CollisionGroup"):Connect(function()
		instance:SetAttribute(attribute, instance.CollisionGroup);
	end))
	
	item_tracking.maid:add(function()
		instance.CollisionGroup = instance:GetAttribute(attribute) or "Default";
		instance:SetAttribute(attribute, nil);
	end)
end

function Selection:hook_attachment_visuals(instance: Attachment, item_tracking: ItemTracker)
	local attachment = Instance.new("Attachment");
	attachment.Name = "HighlightAttachment";
	attachment.Visible = true;
	attachment.Archivable = false;
	attachment.Parent = instance;
	
	local cone_up = Instance.new("CylinderHandleAdornment")
	cone_up.Adornee = instance.Parent;
	cone_up.Archivable = false;
	cone_up.Visible = true
	cone_up.Color3 = Color3.fromRGB(57, 110, 255)
	cone_up.Height = 0.75;
	cone_up.Radius = 0.025;
	cone_up.Parent = attachment;

	local arrow_up = Instance.new("ConeHandleAdornment")
	arrow_up.Adornee = instance.Parent;
	arrow_up.Archivable = false;
	arrow_up.Visible = true
	arrow_up.Color3 = Color3.fromRGB(50, 100, 225)
	arrow_up.Height = 0.4;
	arrow_up.Radius = 0.15;
	arrow_up.Parent = attachment;
	
	local cone = Instance.new("CylinderHandleAdornment")
	cone.Adornee = instance.Parent;
	cone.Archivable = false;
	cone.Visible = true
	cone.Color3 = Color3.fromRGB(255, 172, 39)
	cone.Height = 1;
	cone.Radius = 0.025;
	cone.Parent = attachment;
	
	local arrow = Instance.new("ConeHandleAdornment")
	arrow.Adornee = instance.Parent;
	arrow.Archivable = false;
	arrow.Visible = true
	arrow.Color3 = Color3.fromRGB(231, 153, 35)
	arrow.Height = 0.4;
	arrow.Radius = 0.15;
	arrow.Parent = attachment;
	
	item_tracking.maid:add(RunService.PreSimulation:Connect(function(dt)
		cone.CFrame = instance.CFrame * CFrame.new(0, 0, -0.25);
		arrow.CFrame = instance.CFrame * CFrame.new(0, 0, -0.75)
		
		cone_up.CFrame = instance.CFrame * CFrame.Angles(math.rad(90), 0, 0) * CFrame.new(0, 0, -0.125)
		arrow_up.CFrame = instance.CFrame * CFrame.Angles(math.rad(90), 0, 0) * CFrame.new(0, 0, -0.5)
	end));
	item_tracking.maid:add(attachment);
end

-- Use deselect instead of using deselect_instance on all instances (your pc will thank you)
function Selection:deselect(selection: {Instance}): ()
	if not selection then
		selection = Table.keys(self.items);
	end;
	
	if Stylus:has_active_instance_box() then
		Stylus:give_instance_buffered(nil);
	end;
	
	local new_deselection = nil;
	
	for _, instance in ipairs(selection) do
		if not self.items[instance] then
			continue;
		end;
		
		local item_tracking: ItemTracker = self.items[instance];
		
		for other, tracking in self.items do
			if tracking.index > item_tracking.index then
				tracking.index -= 1;
			end
		end
		
		self.count -= 1;
		self.items[instance] = nil;
		self.pivot_items[instance] = nil;
		self.physical_items[instance] = nil;
		self.on_selection_removed:Fire(instance);
		
		instance:RemoveTag("NoCameraOcclusion");
		
		new_deselection = instance;
		item_tracking.maid:destroy();
		
		if item_tracking.collision_group then
			instance.CollisionGroup = item_tracking.collision_group;
		end;
		
		if item_tracking.highlight then
			if item_tracking.highlight:IsA("SelectionBox") then
				item_tracking.highlight.Visible = false;
				item_tracking.highlight.Adornee = nil;
				
				HighlightBoxCache:release(item_tracking.highlight);
			else
				item_tracking.highlight.Enabled = false;
				item_tracking.highlight.Adornee = nil;
				item_tracking.highlight.Parent = Builds;
				
				HighlightCache:release(item_tracking.highlight);
			end
		end;

		self:set_descendant_select_visibility(instance, false);
	end
	
	for pv_item in self.physical_items do
		self:update_hierarchy(pv_item);
	end
	
	if new_deselection then
		self.on_selection_changed:Fire(new_deselection, #selection, false);
	end
	
	if self:is_empty() then
		self.on_selection_lost:Fire();
	end
	
	self:set_first_edge(nil);
	self:update_attachments_selected();
	self.update_flag();
	
	selection = nil :: any;
end

function Selection:select(selection: {Instance}): ()
	
	local had_selection = not self:is_empty();
	local new_selection = nil;
	
	for _, instance in ipairs(selection) do
		if self.items[instance] or not self:is_selectable(instance) then
			continue;
		end;
		
		local item_tracking: ItemTracker = {
			parent = instance.Parent, 
			maid = Maid.light(), 
			highlight = nil;
			index = self.count + 1;
		}
		
		new_selection = instance;
		
		self.count += 1;
		self.items[instance] = item_tracking;
		self.on_selection_added:Fire(instance);
		
		if self:is_pivotable(instance) then
			self.physical_items[instance] = true;
			self:hook_hierarchy_resolver(instance, item_tracking)

		elseif instance:IsA("Attachment") then
			self:hook_attachment_visuals(instance, item_tracking)
		end;
		
		self:set_descendant_select_visibility(instance, true);
		
		item_tracking.maid:add(instance.DescendantAdded:Connect(self.update_reancestry));
		item_tracking.maid:add(instance.DescendantRemoving:Connect(self.update_reancestry));
	end
	
	local has_selection = not self:is_empty();
	
	if not had_selection and has_selection then
		self.on_selection_begin:Fire();
		self.dragger.Enabled = true;
		
	elseif had_selection and not has_selection then
		self.on_selection_lost:Fire();
		self.dragger.Enabled = false;
		
	end
	
	for pv_item in self.physical_items do
		self:update_hierarchy(pv_item);
	end
	
	if new_selection then
		self.raycast_params.FilterDescendantsInstances = Table.keys(self.pivot_items);
		self.raycast_params:AddToFilter(Player.Character);
		self.on_selection_changed:Fire(new_selection, #selection, true);
	end;
	
	self:update_attachments_selected();
	self.update_flag();
	
	selection = nil :: any;
end

table.freeze(Selection);

return Selection;