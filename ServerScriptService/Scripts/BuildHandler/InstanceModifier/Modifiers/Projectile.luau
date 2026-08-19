local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Unpacker = require( "../../Unpacker" );
local ModifierUtil = require("../ModifierUtil");
local Maid = require( Unpacker.Packages.Maid );
local Type = require( Unpacker.Packages.Type );
local Instances = require( Unpacker.Packages.Instances );
local Math = require( Unpacker.Packages.Math );

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Shoots a projectile";
TagModifier.needs_gamepass = "TrapsPack1";
TagModifier.icon = 153287125;
TagModifier.color = Color3.fromRGB(78, 102, 255)
TagModifier.section = 5;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Face = { 
		Order = 1,
		Default = Enum.NormalId.Front, 
		Type = Type.enum(Enum.NormalId) 
	};
	Power = { 
		Order = 2,
		Default = 200 
	};
	Lifetime = {
		Order = 3,
		Default = 5;
	};
	SpreadAngle = { 
		Order = 4,
		Default = Vector2.zero 
	};
	
	AlignType = {
		Order = 6,
		Default = "Direction",
		ValueList = {"Direction", "None"};
	};
	AlignAngle = {
		Order = 5,
		Default = Vector3.new(0, 90, 0)
	};
	
	Collides = {
		Order = 7,
		Default = false 
	};
	HeatSeeking = {
		Order = 8,
		Default = false;
		Shows = {"HeatSeekingRange", "HeatSeekingType"};
	};
	HeatSeekingRange = {
		Order = 9,
		Default = 100;
		Hidden = true;
	};
	HeatSeekingType = {
		Order = 10,
		Default = "Nearest";
		ValueList = {"Nearest", "Input"};
		Hidden = true;
	};
	
	Reference = {
		Order = 20,
		Default = nil;
		Type = Type.Instance();
	};
	OnHit = { 
		Order = 21;
		Default = nil, 
		Type = Type.Instance() 
	};
	OnSpawn = {
		Order = 22;
		Default = nil,
		Type = Type.Instance()
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	self._reference = nil;
	self.projectiles = {};
	
	return self;
end

local function notify_builders(combats, ...)
	for _, combat in combats do
		local builder = combat:get_builder()

		if builder then
			builder:push_notification(...);
		end;
	end;
end;

function TagModifier.attribute_updates:Reference(value, was_init)
	self._reference = value or script.Arrow;
end

local function get_spread_angle(direction: CFrame, spread_angle: Vector2, face: Enum.NormalId): Vector3
	local spread_angle: CFrame = CFrame.fromEulerAngles(
		math.rad( (math.random() * 2 - 1) * spread_angle.X ), 
		math.rad( (math.random() * 2 - 1) * spread_angle.Y ), 0)

	local facing_angle: CFrame = CFrame.lookAlong(Vector3.zero, Vector3.FromNormalId(face))
	
	return ( direction.Rotation * facing_angle * spread_angle ).LookVector;
end;

local Projectile = {};
Projectile.__index = Projectile;

function Projectile.new(modifier, signal)
	local maid = Maid.new();
	local data = modifier.attributes:all();
	
	local self = setmetatable(
		{
			maid = maid;
			modifier = modifier;
			signal = signal;
			data = data;
			origin = modifier:get_cframe();
			input_humanoids = signal:get_humanoids();
			debounce = false;
		}, 
		Projectile);
	
	modifier.projectiles[self] = true;
	
	self:create_handle();
	self:initialise();
	
	return self;
end;

function Projectile:initialise()
	self.maid:add(task.spawn(function()
		self:step(0);
		
		while self do
			self:step( task.wait(1 / 10) )
		end;
	end))
end

function Projectile:create_handle()
	local reference = self.modifier._reference;
	local impulse = get_spread_angle(self.origin, self.data.SpreadAngle, self.data.Face) * self.data.Power;
	
	self.projectile = reference:Clone();
	
	local center = Instance.new("Attachment", self.projectile);

	if self.data.AlignType == "Direction" then
		self.projectile_alignment = script.AlignOrientation:Clone();
		self.projectile_alignment.Attachment0 = center;
		self.projectile_alignment.Parent = self.projectile;
	end
	
	if self.data.HeatSeeking then
		self.projectile_force = script.AlignPosition:Clone();
		self.projectile_force.Attachment0 = center;
		self.projectile_force.MaxForce = 300 * reference.AssemblyMass;
		self.projectile_force.Parent = self.projectile;
	end
	
	self.projectile:PivotTo(self.origin);
	self.projectile.Anchored = false;
	self.projectile.CanCollide = self.data.Collides;
	self.projectile.AssemblyLinearVelocity = impulse;
	self.projectile.Parent = workspace.Terrain;
	
	if self.projectile:IsGrounded() then
		for _, part in self.projectile:GetConnectedParts() do
			part.Anchored = false;
		end;
	end;
	
	self.projectile:SetNetworkOwner(nil);
	
	self.projectile.Touched:Connect(function(part)
		self:touch(part);
	end);
	
	if self.data.OnSpawn then
		local map_descendants = Instances.get_mirrored_map(reference, self.projectile);
		local on_spawn = map_descendants[self.data.OnSpawn] or self.data.OnSpawn;
		
		-- Wait for any modifiers that exist in the projectile.
		RunService.Heartbeat:Once(function()
			for _, modifier in self.modifier:get_pulse_targets_of(on_spawn, {}) do
				modifier:pulse( self.signal );
			end;
		end)
	end;
end;

function Projectile:touch(part: BasePart)
	local humanoid = Instances.get_ancestor_humanoid(part);

	if humanoid and not self.debounce and self.modifier then
		self.debounce = true;

		local signal = self.modifier:create_pulse();
		signal:add_humanoid(humanoid);
		
		if not self.pulse_targets then
			self.pulse_targets = self.modifier:get_pulse_targets_of(self.data.OnHit, {});
		end;
		
		for _, modifier in self.pulse_targets do
			modifier:pulse(signal);
		end;
	end;
end

function Projectile:step(dt: number)
	if self.data.HeatSeeking then
		local origin = self.projectile.Position;
		local humanoid_list: {Humanoid} = self.input_humanoids;
		
		if self.data.HeatSeekingType == "Nearest" then
			humanoid_list = ModifierUtil.get_humanoids(origin, NumberRange.new(0, self.data.HeatSeekingRange));
		end;

		local nearest = ModifierUtil.get_nearest(origin, humanoid_list);

		if nearest then
			self.projectile_force.Attachment1 = nearest.RootPart.RootAttachment;
		else
			self.projectile_force.Attachment1 = nil;
		end;
	end;
	
	if self.projectile_alignment then
		if self.projectile.AssemblyLinearVelocity.Magnitude > 5 then
			local orientation = self.data.AlignAngle;
			
			self.projectile_alignment.Enabled = true;
			
			self.projectile_alignment.CFrame = 
				CFrame.lookAlong(Vector3.zero, self.projectile.AssemblyLinearVelocity) * 
				CFrame.Angles(math.rad(orientation.X), math.rad(orientation.Y), math.rad(orientation.Z));
		else
			self.projectile_alignment.Enabled = false;
		end;
	end
end

function Projectile:destroy()
	if not self.maid or self.maid.destroyed then return end;
	
	self.maid:destroy();
	self.projectile:Destroy();
	
	self.modifier.projectiles[self] = nil;
	
	task.defer(table.clear, self);
end

function TagModifier:pulse(signal)
	if not self._reference:IsA("BasePart") then
		local combats = signal:get_combats();
		
		return notify_builders(combats, 1, `Unable to shoot: Reference is not a BasePart`);
	end;
	
	local projectile = Projectile.new(self, signal);
	
	if projectile.data.Lifetime > 0 then
		task.delay(projectile.data.Lifetime, function()
			projectile:destroy();
		end);
	end;
end;

function TagModifier:destroy()
	for projectile in self.projectiles do
		projectile:destroy();
	end;
	
	table.clear(self.projectiles);
	InstanceModifier.destroy(self);
end;

TagModifier:rebase();
table.freeze(TagModifier);
table.freeze(Projectile);

return TagModifier;