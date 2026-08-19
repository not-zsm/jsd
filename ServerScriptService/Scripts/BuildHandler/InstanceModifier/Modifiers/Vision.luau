local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Unpacker = require( "../../Unpacker" );
local ModifierUtil = require( "../ModifierUtil" );
local Type = require( Unpacker.Packages.Type );

local SightParams = RaycastParams.new()
SightParams.FilterDescendantsInstances = {};
SightParams.FilterType = Enum.RaycastFilterType.Include;

if workspace:FindFirstChild("Builds") then
	SightParams:AddToFilter(workspace.Builds);
end;

if workspace:FindFirstChild("Map") then
	SightParams:AddToFilter(workspace.Map);
end;

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Outputs a signal when a player is in peripherals of the sensor.";
TagModifier.icon = 78134819718605;
TagModifier.color = Color3.fromRGB(199, 130, 255)
TagModifier.section = 8;
TagModifier.use_prompt = false;
TagModifier.signal_generator = true;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Active = {
		Default = true;
	};
	AwareOfDummies = {
		Default = false;
	};
	Face = {
		Default = Enum.NormalId.Front;
	};
	Interval = {
		Default = 0.1;
	};
	Range = {
		Default = NumberRange.new(50);
	};
	FieldOfView = {
		Default = 90;
	};
	MovementThreshold = {
		Default = 0;
	};
	NeedsSight = {
		Default = false;
	};
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end;

function TagModifier.attribute_updates:Active(value, was_init)
	if value then
		self.signal_generator = true;
	else
		self.signal_generator = false;
	end

	self:set_always_active(value);
end

local function pulse_interval(self)
	local any_active = false;

	self.active_signal:clear();
	
	local data = self.attributes:all();
	local coordinate: CFrame = self:get_cframe();
	local range: NumberRange = ModifierUtil.normal_range(data.Range);
	local movement_threshold: number = data.MovementThreshold;
	local humanoids: {Humanoid};
	
	if self.attributes:get("AwareOfDummies") then
		humanoids = ModifierUtil.get_humanoids(coordinate.Position, range);
	else
		humanoids = ModifierUtil.get_player_humanoids(coordinate.Position, range);
	end;
	
	local look_direction = coordinate.Rotation * Vector3.FromNormalId(data.Face);
	local fov: number = math.rad(data.FieldOfView) * 0.5;
	
	for _, humanoid in humanoids do
		local root_part = humanoid.RootPart;
		local speed = root_part.AssemblyLinearVelocity.Magnitude;
		local direction = coordinate.Position - root_part.Position;
		
		if speed >= movement_threshold and look_direction:Angle(direction) < fov then
			
			if data.NeedsSight then
				local raycast = workspace:Raycast(coordinate.Position, -direction, SightParams);
			
				-- It hit something, and didn't fully reach the humanoid.
				if raycast then
					continue;
				end;
			end
			
			self.active_signal:add_humanoid(humanoid);
			any_active = true;
		end;
	end;
	
	self:set_powering(any_active);
end

function TagModifier:on_active_changed()
	self:set_powering(false);
	
	if not self.active then
		return;
	end;
	
	self.active_maid:add(task.defer(function()
		while task.wait(self.attributes:get("Interval")) do
			local success, result = pcall(pulse_interval, self);
			
			if not success then
				warn("Vision Modifier Error:", result);
			end
		end
	end))
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;