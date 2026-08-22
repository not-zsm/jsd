local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventService = require( ReplicatedStorage.Shared.Utilities.EventService )

local NumberStack = {}
NumberStack.__index = NumberStack

function NumberStack.new() : NumberStack
	return setmetatable({
		Value = 0,
		Threads = {} :: {[thread]: boolean},

		OnEnd = EventService.new(),
		OnStart = EventService.new(),
		OnChanged = EventService.new(),
		OnValueChanged = EventService.new()
	}, NumberStack)
end

export type NumberStack = typeof(NumberStack.new(...))

function NumberStack.IsTrue(self: NumberStack): boolean
	return (self.Value > 0)
end

function NumberStack.IsFalse(self: NumberStack): boolean
	return (self.Value == 0)
end

function NumberStack.Destroy(self: NumberStack): ()
	self:Reset()

	self.OnEnd:Destroy()
	self.OnStart:Destroy()
	self.OnChanged:Destroy()
	self.OnValueChanged:Destroy()
end

function NumberStack.Cancel(self: NumberStack): ()
	for Thread in self.Threads do
		if coroutine.status(Thread) == "suspended" then
			task.cancel(Thread)
		end
	end

	table.clear(self.Threads)
end

function NumberStack.Reset(self: NumberStack): ()
	self:Cancel()

	if (self.Value > 0) then
		self.Value = 0
		
		self.OnEnd:Fire()
		self.OnChanged:Fire(false)
	end
end

function NumberStack.Subtract(self: NumberStack): ()
	local Last = self.Value
	self.Value = math.max(0, self.Value - 1)

	if (self.Value ~= Last) then
		self.OnValueChanged:Fire(false);
	end

	if self:IsFalse() then
		self.OnEnd:Fire()
		self.OnChanged:Fire(false)
	end

	self.Threads[coroutine.running()] = nil
end

function NumberStack.Add(self: NumberStack, Duration : number?): ()
	local Last = self.Value
	self.Value += 1

	self.OnValueChanged:Fire(true);

	if (Last == 0) then
		self.OnStart:Fire()
		self.OnChanged:Fire(true)
	end

	if (typeof(Duration) == "number") then
		self.Threads[task.delay(Duration, self.Subtract, self)] = true
	end
end

function NumberStack.Change(self: NumberStack, Value : boolean, DurationUntilPop : number?): ()
	if (Value == true) then
		self:Add(DurationUntilPop)
	else
		self:Subtract()
	end
end

table.freeze(NumberStack)

return NumberStack