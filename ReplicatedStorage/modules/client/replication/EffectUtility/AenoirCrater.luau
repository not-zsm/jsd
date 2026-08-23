local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Math = require( ReplicatedStorage.Packages.Math )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Instances = require( ReplicatedStorage.Packages.Instances )
local Table = require( ReplicatedStorage.Packages.Table )
local InstanceCache = require( ReplicatedStorage.Packages.InstanceCache )
local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )
local Signal = require( ReplicatedStorage.Packages.Signal )
local DefaultParams = require( script.DefaultParams )

-----------------------------------------------------------------------

local Assets = script.Assets;

-----------------------------------------------------------------------

local ROCK_BRIGHTNESS_MODIFIER = 0.05;
local XZ = Vector3.new(1, 0, 1);
local RND = Random.new();
local FADE_OUT_INFO = TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In);
local STRAIGHT_UP = CFrame.lookAt(Vector3.zero, Vector3.yAxis);
local VISUALS_FOLDER = workspace.Visuals;
local RAY_PARAMS = Utility.VisualParams;

-----------------------------------------------------------------------

local RubbleCache: InstanceCache.InstanceCache<typeof(Assets.Crater)> = InstanceCache.new(80, function()
	return Assets.Crater:Clone();
end)

local SplashCache: InstanceCache.InstanceCache<typeof(Assets.Splash)> = InstanceCache.new(80, function()
	return Assets.Splash:Clone();
end)

function SplashCache.cleanup_release(splash)
	splash.Anchored = true;
	splash.Trail.Enabled = false;
end

function SplashCache.cleanup_get_deferred(splash)
	splash.Trail.Enabled = true;
end

-----------------------------------------------------------------------

export type WaterResult = "NoWater" | "WaterSplash" | "Water";
export type CraterParams = typeof(DefaultParams);

export type ClassCrater = {
	__index: ClassCrater;

	new: (params: any) -> Crater;
	get_direction_cast: (self: Crater) -> Vector3;
	get_next_offset: (self: Crater, radius: number) -> CFrame;
	cast: (self: Crater, origin: Vector3, direction: Vector3) -> RaycastResult?;
	get_coordinate: (self: Crater) -> CFrame;
	spread_rotation: (self: Crater) -> CFrame;
	spread_angle: (self: Crater, direction: Vector3?) -> Vector3;
	add_rubble_debris: (self: Crater, rubble: BasePart) -> Tween;
	spawn_rubble: (self: Crater, coordinate: CFrame, params: any) -> ();
	spawn_splash: (self: Crater, ground_ray: RaycastResult?) -> ();
	spawn_crater: (self: Crater, ground_ray: RaycastResult?) -> ();
	spawn_cone: (self: Crater, ground_ray: RaycastResult?) -> ();
	frame_spawn: (self: Crater, delta: number) -> ();
	cast_ray_for_ground: (self: Crater) -> RaycastResult?;
	get_water_result: (self: Crater, ray: RaycastResult) -> (WaterResult);
	start: (self: Crater, duration: number) -> (WaterResult);
	stop: (self: Crater) -> ();
};

export type Crater = typeof(setmetatable({} :: {
	params: CraterParams;
	rnd: Random;
	frame: number;
	delay_stop: number;
	attachment: Attachment;
	reduced_graphics: boolean;
	reduced_value: number;
	quality_alpha: number;
	quality_alpha_low: number;
	maid: Maid.Maid;
	active_maid: Maid.Maid;
	last_ground_ray: RaycastResult?;
	updated: Signal.Signal<>;
	
}, {} :: ClassCrater));

-----------------------------------------------------------------------

local Crater = {} :: ClassCrater
Crater.__index = Crater;

function Crater.new(params)
	local maid = Maid.new();
	local new_params = Table.mirror(DefaultParams, params) :: CraterParams;
	
	local self = setmetatable({}, Crater)
	
	self.params = new_params;
	
	self.maid = maid;
	self.active_maid = maid:limb();
	self.updated = Signal.new(true);
	
	self.rnd = Random.new();
	self.frame = 0;
	self.delay_stop = 0;
	
	self.reduced_graphics = false;
	self.reduced_value = if self.reduced_graphics then 1 else 0;
	self.quality_alpha = (if self.reduced_graphics then 1.5 else 1) + 0;
	self.quality_alpha_low = (if self.reduced_graphics then 2  else 1) + 0;
	
	self.last_ground_ray = nil;
	
	return self;
end

local function apply_ray_to_part(ray: RaycastResult, part: BasePart): ()
	part.Material = ray.Material;
	part.Color = Math.Brighten(Instances.ray_color(ray), ROCK_BRIGHTNESS_MODIFIER)

	if ray.Instance and ray.Instance:IsA("BasePart") then
		part.MaterialVariant = ray.Instance.MaterialVariant;
	end
end

function Crater:get_direction_cast()
	if self.params.local_to_adornee then
		return self:get_coordinate().LookVector * self.params.raycast_distance;
	end;

	return -Vector3.yAxis * self.params.raycast_distance;
end

function Crater:get_next_offset(radius)
	return CFrame.new(self.rnd:NextNumber(-1, 1) * radius, 0, self.rnd:NextNumber(-1, 1) * radius)
end

function Crater:cast(origin: Vector3, direction: Vector3): RaycastResult?
	return --Instances.raycast_debug(origin, direction, RayParams) 
		 workspace:Raycast(origin, direction, RAY_PARAMS);
end

function Crater:blockcast(origin: Vector3, size: Vector3, direction: Vector3): RaycastResult?
	return --Instances.raycast_debug(origin, direction, RayParams) 
		workspace:Blockcast(CFrame.lookAlong(origin, direction), size, direction, RAY_PARAMS);
end

function Crater:get_coordinate()
	return Instances.cframe(self.params.adornee) * self.params.offset
end

function Crater:spread_rotation()
	local rot = self.params.rotation_angle;

	return CFrame.fromEulerAngles(
		math.rad(Math.RangeRandom(rot[1])), 
		math.rad(Math.RangeRandom(rot[2])), 0
	)
end

function Crater:spread_angle(direction)
	local rot = self.params.splash.spread_angle;

	local spread_angle = CFrame.fromEulerAngles(
		math.rad(self.rnd:NextNumber(-1, 1) * rot.X), 
		math.rad(self.rnd:NextNumber(-1, 1) * rot.Y), 0)

	--local facing_angle = Normals.GetFromNormal(Enum.NormalId.Top).rcf;
	local adornee_angle = Math.VectorToRotation(direction or self:get_coordinate().LookVector);

	return (adornee_angle * spread_angle).LookVector;
end

function Crater:add_rubble_debris(rubble)
	local ending = TweenService:Create(rubble, FADE_OUT_INFO, {
		Size = Vector3.zero;
	})
	
	local fade = self.params.fade_out_time;
	
	task.delay(RND:NextNumber(fade - 1, fade), ending.Play, ending);
	
	return ending;
end

function Crater:spawn_rubble(coordinate, params)
	local direction = self:get_direction_cast()
	local origin = coordinate.Position - direction.Unit + (coordinate.Rotation * self:get_next_offset(params.variance)).Position
	local ray = self:cast(origin, direction)
	
	if ray and self:get_water_result(ray) == "NoWater" then

		local ray_cf = Math.RayCFrame(ray);
		local size = params.size;
		local offset = params.variance;
		local tween_in = params.tween[1];
		local accent = params.accent;
		
		local look_to = self.attachment.WorldPosition + direction.Unit * accent;
		
		local new_coordinate = CFrame.lookAt(ray.Position, look_to, direction) 
			* self:spread_rotation() - (ray.Normal * params.depth)
		
		local starting = new_coordinate.Rotation + 
			(if params.spawn_middle then self.attachment.Position else new_coordinate.Position);
		
		local crater = RubbleCache:get()
		crater.CFrame = starting;
		crater.Size = Vector3.zero;
		
		apply_ray_to_part(ray, crater);
		crater.Parent = VISUALS_FOLDER;

		self:add_rubble_debris(crater).Completed:Once(function()
			RubbleCache:release(crater);
		end)

		local tween_info = TweenInfo.new(Math.RangeRandom(tween_in), select(2, unpack(params.tween)))
		local beginning = TweenService:Create(crater, tween_info, {Size = size; CFrame = new_coordinate})

		beginning:Play()

		return crater;
	end;
end

function Crater:spawn_splash(ground_ray)
	if not ground_ray then return end;
	if self:get_water_result(ground_ray) ~= "NoWater" then return end
	
	local origin = self:get_coordinate();
	local max_count = Math.RangeRandom(self.params.splash.count) // self.quality_alpha_low;
	
	for count = 1, max_count do
		local coordinate = origin.Rotation + ground_ray.Position;
		
		if self.params.splash.between_cone then
			local distance = math.random(self.params.splash.cone_distance.Min, math.min(self.params.cone.radius, self.params.splash.cone_distance.Max));
			local rotation = self.rnd:NextNumber(-self.params.cone.angle.Min, self.params.cone.angle.Max);
			
			coordinate = origin * CFrame.Angles(0, math.rad(rotation), 0) * CFrame.new(0, 0, -distance);
		end
		
		local random = Random.new():NextUnitVector() * math.pi;
		
		local splash = SplashCache:get();
		splash.CFrame = coordinate * CFrame.Angles(random.X, random.Y, random.Z);
		splash.Size = Vector3.one * Math.RangeRandom(self.params.splash.size);
		splash.Anchored = false;
		splash.CanCollide = true;
		splash.CollisionGroup = "Effects"
		splash.Trail.Color = ColorSequence.new(Instances.ray_color(ground_ray));
		
		if not self.params.splash.collidable then
			splash.CollisionGroup = "NoCollisions"
		end
		
		apply_ray_to_part(ground_ray, splash)
		splash.Parent = VISUALS_FOLDER;

		self:add_rubble_debris(splash).Completed:Once(function()
			SplashCache:release(splash);
		end)
		
		splash.AssemblyLinearVelocity = self:spread_angle(ground_ray.Normal) * Math.RangeRandom(self.params.splash.power);
		--duration = self.params.splash.velocity_duration;
	end;
end

function Crater:spawn_crater(ground_ray)
	local params = self.params.crater;
	local coordinate = self:get_coordinate();
	local max_count = Math.RangeRandom(params.count) // self.quality_alpha;
	local direction = Math.VectorToRotation(self:get_direction_cast());
	
	local sporadic = params.sporadic;
	
	for revolution = 0, math.max(0, params.revolutions - 1 - self.reduced_value) do
		local angle = math.rad(revolution * Math.RangeRandom(params.angle_variance))
		local rnd = Random.new(tick());
		
		for count = 1, max_count do
			local alpha = (count / max_count)
			
			local y = (if sporadic then math.rad(rnd:NextInteger(0, 360)) else math.pi * 2 * alpha) + angle;
			local z = params.radius + rnd:NextNumber(-params.magnitude_variance, params.magnitude_variance);
			
			local dome = direction * CFrame.Angles(math.rad(90), y, 0) * CFrame.new(0, 0, -z) + coordinate.Position
				
			self:spawn_rubble(dome, params);
		end
	end;
end;

function Crater:spawn_cone(ground_ray)
	local params = self.params.cone;
	local coordinate = self:get_coordinate();
	local max_count = Math.RangeRandom(params.count) // self.quality_alpha_low;
	local direction = Math.VectorToRotation(self:get_direction_cast());
	
	local iparams = {__index = params};
	
	local function next_revolution(revolution)
		local angle = math.rad(revolution * Math.RangeRandom(params.angle))
		
		local skip = 1 // (60 * params.delay);
		
		for count = 1, max_count do
			local alpha = (count / max_count)
			local pos = coordinate * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -params.radius * alpha)

			local mod = setmetatable({}, iparams);
			mod.size = params.size * alpha;

			self:spawn_rubble(direction + pos.Position + Vector3.yAxis * self.params.raycast_distance / 2, mod);

			if params.delay ~= 0 and (skip == 0 or count % skip == 0) then
				task.wait(params.delay)
			end
		end
	end;
	
	for revolution = -1, 1, 2 do
		task.spawn(next_revolution, revolution);
	end;
end

function Crater:frame_spawn(delta)
	self.frame += delta / self.quality_alpha_low;

	local count = math.floor(self.frame * self.params.rubble.rate)

	for index = 1, count do
		self.frame = 0;
		self:spawn_rubble(self:get_coordinate(), self.params.rubble)
	end;
end

function Crater:cast_ray_for_ground()
	local origin = self:get_coordinate();
	local direction = self:get_direction_cast();

	local ground_hit = self:cast(origin.Position - direction.Unit * 1, direction * 2);

	local end_point = 
		if ground_hit 
		then CFrame.lookAlong(ground_hit.Position, ground_hit.Normal) + ground_hit.Normal * 0.01
		else STRAIGHT_UP + (origin.Position + direction.Unit);
	
	self.attachment.WorldCFrame = end_point;
	self.last_ground_ray = ground_hit;
	self.updated:Fire();
	
	return ground_hit;
end

function Crater:get_water_result(ray)
	if not ray or ray.Material ~= Enum.Material.Water then
		return "NoWater";
		
	elseif self.params.cone.count.Max == 0 and self.params.crater.count.Max > 0 then
		return "WaterSplash";
	else
		return "Water";
	end
end

function Crater:start(duration)
	self:stop()
	
	self.attachment = Instance.new("Attachment");
	self.attachment.Name = "CraterHitAttachment";
	self.attachment.Parent = workspace.Terrain;
	
	local ground_hit = self:cast_ray_for_ground();
	local water_result = self:get_water_result(ground_hit)
	
	self.attachment.Parent = workspace.Terrain;
	
	if self.params.rubble.duration ~= 0 then
		self.active_maid:add(RunService.PostSimulation:Connect(function(delta)
			self:cast_ray_for_ground()
			self:frame_spawn(delta);
		end))

		if self.params.rubble.duration > 0 then
			self.delay_stop = math.max(self.delay_stop, self.params.rubble.duration);
		end
	end;
	
	if self.params.crater.count.Max > 0 then
		self:spawn_crater(ground_hit);
	end;

	if self.params.splash.count.Max > 0 then
		self:spawn_splash(ground_hit)
	end;

	if self.params.cone.count.Max > 0 then
		self:spawn_cone(ground_hit)
	end
	
	--if water_result == "WaterSplash" then
	--	ActorBindables.LoadEffects:Fire(AssetManager.get(self.params.if_water_effects), self.attachment);
	--end;
	
	if typeof(duration) == "number" and duration >= 0 then
		self.delay_stop = math.max(self.delay_stop, duration);
	end
	
	task.delay(self.delay_stop, self.stop, self);
	
	return water_result
end

function Crater:stop()
	self.active_maid:clean();
	
	Debris:AddItem(self.attachment, self.params.fade_out_time);
end

table.freeze(Crater);

return Crater;