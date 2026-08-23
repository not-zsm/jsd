--!native
--!strict

local replicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local GeometryService = game:GetService("GeometryService")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")

local Instances = {};

function Instances.position(object: Instance): Vector3
	assert(object, "Instance is nil");
	
	if object:IsA("BasePart") then
		return object.Position;
		
	elseif object:IsA("Attachment") then
		return object.WorldPosition;
		
	elseif object:IsA("PVInstance") then
		return object:GetPivot().Position;
	end
	
	error("Instance has no physical position");
end

function Instances.cframe(object: Instance): CFrame
	assert(object, "Instance is nil");
	
	if object:IsA("BasePart") then
		return object.CFrame;

	elseif object:IsA("Attachment") then
		return object.WorldCFrame;

	elseif object:IsA("PVInstance") then
		return object:GetPivot();
	end
	
	error("Instance has no physical position");
end

function Instances.color(object: Instance, material: Enum.Material?): Color3
	if object then
		if object:IsA("Terrain") and material then
			local success, color = pcall(object.GetMaterialColor, object, material);
			
			if success then
				return color;
			end;

		elseif object:IsA("BasePart") then
			return object.Color;
		end
	end
	
	return Color3.new(1, 1, 1);
end

function Instances.find_first_tagged(object: Instance, tag: string): Instance?
	for _, instance in object:GetDescendants() do
		if instance:HasTag(tag) then
			return instance;
		end;
	end;
	return nil;
end

function Instances.set_collision_group(instance: Instance, group: string): ()
	for _, part in instance:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = group or "Default";
		end;
	end;
end

function Instances.get_directory(instance: Instance, ancestor: Instance, seperator: string?): string?
	if not seperator then
		seperator = "/";
	end;
	
	assert(seperator);
	
	local parent: Instance? = instance;
	local result = {};
	
	while parent and parent ~= ancestor do
		table.insert(result, 1, parent.Name);
		parent = parent.Parent;
	end
	
	if not parent then
		return nil;
	end;
	
	return table.concat(result, seperator);
end

function Instances.find_directory(source: Instance, directory: string, seperator: string?): Instance?
	if not seperator then
		seperator = "/";
	end;

	assert(seperator);
	
	local found = source;
	local split = string.split(directory, seperator);
	
	for _, str in split do
		found = found:FindFirstChild(str);
		
		if not found then
			return nil;
		end;
	end;
	
	if found == source then
		return nil;
	end
	
	return found;
end

function Instances.geometric_split(part: BasePart, slices: number?, blast_power: number?, thickness: number?): {PartOperation}
	local splits = {};
	local rnd = Random.new();

	for count = 1, slices or 2 do
		local spliter = Instance.new("Part");
		
		local random = rnd:NextUnitVector() * math.pi;
		spliter.CFrame = part.CFrame * CFrame.Angles(random.X, random.Y, random.Z);
		spliter.Size = Vector3.new(thickness or 0.1, 128, 128);
		
		table.insert(splits, spliter);
	end;

	part.Archivable = true;
	
	local parts = GeometryService:SubtractAsync(part, splits, {SplitApart = true});

	for _, split in splits do
		split:Destroy();
	end;
	
	for _, split: Part in parts do
		split.Anchored = false;
		split.CanCollide = true;
		if blast_power then
			split.AssemblyLinearVelocity = (rnd:NextUnitVector() + Vector3.yAxis).Unit * blast_power;
			split.AssemblyAngularVelocity = (rnd:NextUnitVector() + Vector3.yAxis).Unit * blast_power;
		end;
		split.CollisionGroup = "Effects";
		split.Parent = workspace.Effects;
	end
	
	return parts;
end

function Instances.weld(part0: BasePart, part1: BasePart, c0: CFrame?): Weld
	local weld = Instance.new("Weld");
	weld.C0 = if c0 then c0 else part1.CFrame:ToObjectSpace(part0.CFrame);
	weld.Part0 = part0;
	weld.Part1 =  part1;
	weld.Parent = part0;
	
	return weld;
end

function Instances.motor6d(part0: BasePart, part1: BasePart, c0: CFrame?): Motor6D
	local motor = Instance.new("Motor6D");
	motor.C0 = if c0 then c0 else part1.CFrame:ToObjectSpace(part0.CFrame);
	motor.Part0 = part0;
	motor.Part1 =  part1;
	motor.Parent = part0;

	return motor;
end

function Instances.raycast_debug(Origin : Vector3, Direction : Vector3, Params : RaycastParams) : RaycastResult
	local Raycast = workspace:Raycast(Origin, Direction, Params)

	local Cone = Instance.new("ConeHandleAdornment")
	Cone.CFrame = CFrame.new(Origin, Origin + Direction)
	Cone.Height = Direction.Magnitude
	Cone.Radius = 0.25
	Cone.Transparency = 0.5
	Cone.Color3 = Color3.new()
	Cone.Adornee = workspace.Terrain
	Cone.Parent = workspace.Terrain

	Debris:AddItem(Cone, 2)

	return Raycast
end

function Instances.ray_color(ray: RaycastResult?): Color3
	if not ray then 
		return Color3.new(1, 1, 1); 
	end;
	
	return Instances.color(ray.Instance, ray.Material);
end

-- Works best in scenairos where the children are static and uniquely named.
function Instances.map_children(instance: Instance): {[string]: Instance}
	local children = {};
	
	for _, child in instance:GetChildren() do
		children[child.Name] = child;
	end;
	
	return children;
end

function Instances.get_scroll_percentage(scrolling_frame: ScrollingFrame): number
	return scrolling_frame.CanvasPosition.Y / (scrolling_frame.AbsoluteCanvasSize.Y - scrolling_frame.AbsoluteSize.Y)
end

function Instances.destroy_child(object: Instance, child: string): ()
	local instance = object:FindFirstChild(child);

	if instance then
		instance:Destroy()
	end;
end

function Instances.get_ancestor_humanoid(instance: Instance): Humanoid?
	local model = instance:FindFirstAncestorOfClass("Model");
	
	if model then
		return model:FindFirstChildOfClass("Humanoid");
	end;
	
	return nil;
end

function Instances.consistent_character_mass(character: Model): ()
	for _, item in character:GetDescendants() do
		if item:IsA("BasePart") and item.Parent ~= character then
			item.Massless = true;
		end
	end
end

function Instances.locate(directory: string, seperator: string?): Instance?
	local item = game;
	
	for _, sub in ipairs(string.split(directory, seperator or ".")) do
		item = item:FindFirstChild(sub);
		
		if not item then break end;
	end;
	
	return item;
end;

type FolderTree = {
	[string]: FolderTree;
};

function Instances.get_folder_tree(origin: Instance, authority, data: FolderTree): ()
	for name, children in data do
		local folder: Instance?;
		
		if not authority then
			folder = origin:WaitForChild(name);
		else
			folder = origin:FindFirstChild(name);
			
			if not folder then
				folder = Instance.new("Folder");
				folder.Name = name;
				folder.Parent = origin;
			end;
		end;
		
		if folder then
			Instances.get_folder_tree(folder, authority, children);
		end;
	end;
end

-- Returns a map of an instance's descendants in relation to the descendants of a clone of that instance. The clone must have been made using Instance:Clone().
function Instances.get_mirrored_map(base_instance: Instance, clone_instance: Instance, ignore_archivable: boolean?): {[Instance]: Instance}
	
	-- Apparently GetDescendants map to their cloned counterparts (not accounting for Archivable), it feels sketchy and undocumented but it works.
	local clone_descendants = clone_instance:GetDescendants();
	local map_descendants: {[Instance]: Instance} = { [base_instance] = clone_instance };
	local instance_index = 0;
	
	for _, item in base_instance:GetDescendants() do
		if ignore_archivable or item.Archivable then
			instance_index += 1;
			map_descendants[item] = clone_descendants[instance_index];
		end;
	end;
	
	return map_descendants;
end;

table.freeze(Instances);

return Instances;