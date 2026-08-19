--------------------------------------------------------------------------------------------

export type ClassDebounce = {
	__index: ClassDebounce;

	new: () -> Debounce;
	remove: (self: Debounce, name: string) -> ();
	add: (self: Debounce, name: string, duration: number) -> ();
	has: (self: Debounce, name: string) -> boolean;
	reset: (self: Debounce) -> ();
	destroy: (self: Debounce) -> ();
};

export type Debounce = typeof(setmetatable({} :: {

	debounces: {[string]: boolean};
	threads: {[string]: thread};

}, {} :: ClassDebounce));

--------------------------------------------------------------------------------------------

local Debounce = {} :: ClassDebounce;
Debounce.__index = Debounce;

function Debounce.new()
	local self = setmetatable(
		{
			debounces = {};
			threads = {};
		}, 
		Debounce);

	return self;
end;

function Debounce:destroy()
	self:reset();
end

function Debounce:remove(name: string)
	if self.threads[name] and coroutine.status(self.threads[name]) == "suspended" then
		task.cancel(self.threads[name]);
		self.threads[name] = nil;
	end;

	self.debounces[name] = false;
end

function Debounce:add(name: string, duration: number)
	if (duration == 0) then return end;
	
	self:remove(name);

	self.debounces[name] = true;
	self.threads[name] = task.delay(duration, self.remove, self, name);
end

function Debounce:has(name: string): boolean
	return not not self.debounces[name];
end

function Debounce:reset(): ()
	for name in self.debounces do
		self:remove(name);
	end;

	table.clear(self.debounces);
	table.clear(self.threads);
end

table.freeze(Debounce);

return Debounce;