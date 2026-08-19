local Spring = require(script.Parent);

export type ClassCFSpring = {
	__index: ClassCFSpring;

	new: (initial: CFrame) -> CFSpring;
	update: (self: CFSpring, target: CFrame?) -> ();
	_update: (self: CFSpring, now: number) -> ();
};

export type CFSpring = typeof(setmetatable({} :: {
	p_spring: Spring.Spring<Vector3>;
	tv_spring: Spring.Spring<Vector3>;
	bv_spring: Spring.Spring<Vector3>;

	time: number;
	position: CFrame;
	velocity: CFrame;
	target: CFrame;
	damping: number;
	speed: number;
	
}, {} :: ClassCFSpring));

local function cframe_cross(pos: Vector3, up: Vector3, back: Vector3): CFrame
	local right = up:Cross(back);

	return CFrame.new(
		pos.X, pos.Y, pos.Z,
		right.X, up.X, back.X,
		right.Y, up.Y, back.Y,
		right.Z, up.Z, back.Z)
end

local CFSpring = {} :: ClassCFSpring;
CFSpring.__index = CFSpring;

--- Creates a new spring
-- @param initial A number or Vector3 (anything with * number and addition/subtraction defined)
function CFSpring.new(initial)
	return setmetatable(
		{
			time = os.clock();
			target = initial;
			position = initial;
			velocity = initial;
			damping = 1;
			speed = 1;
			
			p_spring = Spring.new(initial.Position);
			tv_spring = Spring.new(initial.Position);
			bv_spring = Spring.new(initial.Position);

		}, CFSpring);
end;

function CFSpring:update(target)
	if target then
		self.target = target;
	end;
	
	self:_update(os.clock())
end

function CFSpring:_update(now)
	local p0 = self.position;
	local v0 = self.velocity;
	local p1 = self.target;
	local d, s = self.damping, self.speed;
	local p, tv, bv = self.p_spring, self.tv_spring, self.bv_spring;
	
	p.target = p1.Position;
	tv.target = p1.UpVector;
	bv.target = -p1.LookVector;
	p.speed, tv.speed, bv.speed  = s, s, s;
	p.damping, tv.damping, bv.damping = d, d, d;
	
	p:_update(now);
	tv:_update(now);
	bv:_update(now)
	
	local new_crossed_cframe = cframe_cross(p.position, tv.position, bv.position);
	
	self.position = new_crossed_cframe.Rotation:Orthonormalize() + new_crossed_cframe.Position;
end

return CFSpring;