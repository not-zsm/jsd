--!strict
--!native

export type SpringProperties<T> = {
	time: number;
	position: T;
	velocity: T;
	target: T;
	damping: number;
	speed: number;
};

export type ClassSpring<T> = {
	__index: ClassSpring<T>;
	__call: (self: Spring<T>, properties: {[string]: any}) -> ();
	
	_update: (self: Spring<T>, now: number) -> ();
	
	new: (initial: T) -> Spring<T>;
	corrective_snap: (self: Spring<T>, position: Vector3) -> ();
	impulse: (self: Spring<T>, velocity: T) -> ();
	time_skip: (self: Spring<T>, delta: number) -> ();
	update: (self: Spring<T>, target: T?) -> T;
};

export type Spring<T> = typeof(setmetatable(
	{} :: SpringProperties<T>, 
	{} :: ClassSpring<T>)
);

local Spring = {} :: ClassSpring <number | Vector3 | Vector2>
Spring.__index = Spring;

--- Creates a new spring
-- @param initial A number or Vector3 (anything with * number and addition/subtraction defined)
function Spring.new(initial)
	return setmetatable(
		{
			time = os.clock();
			position = initial;
			velocity = initial;
			target = initial;
			damping = 1;
			speed = 1;
			
		}, Spring);
end;

function Spring:__call(properties)
	for property, value in properties do
		self[property] = value;
	end;
	
	return self;
end

function Spring:corrective_snap(position)
	assert(typeof(self.target) == "Vector3", "Expected Vector3");
	assert(typeof(self.position) == "Vector3", "Expected Vector3");
	
	if not self.target:FuzzyEq(position, 0.01) then
		self.position = position;
	end;
end

--- Impulse the spring with a change in velocity
-- @param velocity The velocity to impulse with
function Spring:impulse(velocity)
	self.velocity = self.velocity :: any + velocity
end

--- Skip forwards in now
-- @param delta now to skip forwards
function Spring:time_skip(delta)
	self:_update(os.clock() + delta);
end

function Spring:update(target)
	if target then
		self.target = target;
	end;
	
	self:_update(os.clock());
	
	return self.position;
end

function Spring:_update(now)
	local p0 = self.position :: any;
	local v0 = self.velocity :: any;
	local p1 = self.target :: any;
	
	local d = self.damping;
	local s = self.speed;

	local t = s*(now - self.time);
	local d2 = d*d;

	local h, si, co;
	
	if d2 < 1 then
		h = math.sqrt(1 - d2);
		local ep = math.exp(-d*t)/h;
		co, si = ep*math.cos(h*t), ep*math.sin(h*t);
		
	elseif d2 == 1 then
		h = 1;
		local ep = math.exp(-d*t)/h;
		co, si = ep, ep*t;
		
	else
		h = math.sqrt(d2 - 1);
		local u = math.exp((-d + h)*t)/(2*h);
		local v = math.exp((-d - h)*t)/(2*h);
		co, si = u + v, u - v;
	end;
	
	local a0 = h*co + d*si;
	local a1 = 1 - (h*co + d*si);
	local a2 = si/s;

	local b0 = -s*si;
	local b1 = s*si;
	local b2 = h*co - d*si;
	
	self.time = now;

	self.position = a0*p0 + a2*v0 + a1*p1;
	self.velocity = b0*p0 + b2*v0 + b1*p1;
end;

return Spring