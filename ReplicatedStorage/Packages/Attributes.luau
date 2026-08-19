--!strict
--!native

--[[
	Attribute wrapper that supports Instance values and uses caching.
	
	Warning:
	- Since this caches and relies on AttributeChanged, you must defer any of your own AttributeChanged calls for proper behaviour.
	- You should use the .changed signal this provides.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------------------

local Maid = require( "./Maid" )
local Signal = require( "./Signal" )

------------------------------------------------------------------------------------

local VALUE_PREFIX = "?";

------------------------------------------------------------------------------------

export type ClassAttributes = {
	__index: ClassAttributes;

	new: (instance: Instance) -> Attributes;
	initialise: (self: Attributes) -> ();
	set_value: (self: Attributes, attribute: string, value: any) -> ();
	set: (self: Attributes, attribute: string, value: any) -> ();
	get: (self: Attributes, attribute: string) -> any;
	rename: (self: Attributes, attribute: string, name: string) -> ();
	remove: (self: Attributes, attribute: string) -> ();
	destroy: (self: Attributes) -> ();
	clear: (self: Attributes) -> ();
	toggle: (self: Attributes, attribute: string) -> ();
	create: (self: Attributes, attribute: string) -> ObjectValue;
	get_object: (self: Attributes, attribute: string) -> ObjectValue?;
	get_changed: (self: Attributes, attribute: string) -> Signal.Signal<any>;
	observe: (self: Attributes, attribute: string, callback: (value: any) -> ()) -> Signal.Connection<any>;
	foreach: (self: Attributes, callback: (attribute: string, value: any) -> ()) -> ();
	all: (self: Attributes) -> {[string]: any};
};

export type Attributes = typeof(setmetatable({} :: {
	
	maid: Maid.Maid;
	instance: Instance;
	objects: {[string]: {o: ObjectValue, c: RBXScriptConnection}};
	values: {[string]: any};
	changed: Signal.Signal<string, any>;
	changed_signals: {[string]: Signal.Signal<any>}?;
	
}, {} :: ClassAttributes));

------------------------------------------------------------------------------------

@native local function is_value_prefixed(child: Instance): boolean
	return string.sub(child.Name, 1, #VALUE_PREFIX) == VALUE_PREFIX
end

@native local function get_value_postfix(child: Instance): string
	return string.sub(child.Name, #VALUE_PREFIX + 1, -1);
end

@native local function child_added(self: Attributes, child: Instance): ()
	if not ( is_value_prefixed(child) and child:IsA("ObjectValue") ) then
		return;
	end;

	local postfix = get_value_postfix(child);
	
	if not self.objects[postfix] then
		self:set_value(postfix, child.Value);
		
		self.objects[postfix] = {
			o = child,
			c = child.Changed:Connect(function(value)
				self:set_value(postfix, value);
			end);
		};
	end;
end

@native local function child_removed(self: Attributes, child: Instance): ()
	if is_value_prefixed(child) then
		local postfix = get_value_postfix(child);
		local object = self.objects[postfix];
		
		if object then
			object.c:Disconnect();
			table.clear(object);
			
			self.objects[postfix] = nil;
		end
	end
end

------------------------------------------------------------------------------------

local Attributes = {} :: ClassAttributes;
Attributes.__index = Attributes;

function Attributes.new(instance)
	local maid = Maid.removing(instance);
	
	local self = setmetatable(
		{
			maid = maid;
			instance = instance;
			values = {};
			objects = {};
			changed = maid:add(Signal.new());
		}, 
		Attributes);
	
	self:initialise();
	
	return self;
end;

function Attributes:initialise()
	for _, child in self.instance:GetChildren() do
		task.spawn(child_added, self, child);
	end
	
	for attribute, value in self.instance:GetAttributes() do
		self:set_value(attribute, value);
	end;
	
	self.maid:add(self.instance.ChildAdded:Connect(function(child: Instance)
		child_added(self, child);
	end))
	
	self.maid:add(self.instance.ChildRemoved:Connect(function(child: Instance)
		child_removed(self, child);
	end))

	self.maid:add(self.instance.AttributeChanged:Connect(function(attribute)
		self:set_value(attribute, self.instance:GetAttribute(attribute));
	end))

	self.maid:add(function()
		self:destroy()
	end)
end

function Attributes:destroy()
	self.maid:destroy();
	
	for attribute, data in self.objects do
		child_removed(self, data.o);
	end
	
	table.clear(self.objects);
	table.clear(self.values);
end

function Attributes:set_value(attribute: string, value: any): ()
	local last_value = self.values[attribute];
	
	if (last_value ~= value) then
		self.values[attribute] = value;
		
		if self.changed_signals and self.changed_signals[attribute] then
			self.changed_signals[attribute]:Fire(value);
		end;
		
		self.changed:Fire(attribute, value);
	end;
end

function Attributes:clear()
	for attribute, value in self.values do
		self.instance:SetAttribute(attribute, nil);
	end;

	for attribute, child in self.objects do
		child_removed(self, child.o);
	end;

	table.clear(self.values);
	table.clear(self.objects);
end

function Attributes:rename(attribute: string, name: string): ()
	self:set(name, self:get(attribute));
	self:remove(attribute);
end

function Attributes:remove(attribute: string): ()
	if self.objects[attribute] then
		child_removed(self, self.objects[attribute].o);
	end;
	
	self.instance:SetAttribute(attribute, nil);
	self:set_value(attribute, nil);
end

function Attributes:set(attribute: string, value: any): ()
	if self.objects[attribute] and (typeof(value) == "Instance" or value == nil) then
		self.objects[attribute].o.Value = value;
	else
		self.instance:SetAttribute(attribute, value);
	end;
	
	self:set_value(attribute, value);
end

function Attributes:get(attribute: string): any
	return self.values[attribute];
end

function Attributes:toggle(attribute)
	local value = not self:get(attribute);
	self:set(attribute, value);
	
	return value;
end

function Attributes:create(attribute)
	local attr_name = `{VALUE_PREFIX}{attribute}`;
	local value_base = self.objects[attribute];
	
	if not value_base then
		local new_value_base = Instance.new("ObjectValue");
		new_value_base.Name = attr_name;
		new_value_base.Parent = self.instance;
		
		child_added(self, new_value_base);
		
		return new_value_base;
	end;
	
	return value_base.o;
end

function Attributes:get_object(attribute: string)
	if self.objects[attribute] then
		return self.objects[attribute].o;
	end;
	
	return nil;
end

function Attributes:get_changed(attribute: string)
	if not self.changed_signals then
		self.changed_signals = {};
	end;
	
	assert(self.changed_signals);
	
	if not self.changed_signals[attribute] then
		self.changed_signals[attribute] = self.maid:add( Signal.new() );
	end
	
	return self.changed_signals[attribute];
end

function Attributes:observe(attribute: string, callback)
	task.spawn(callback, self:get(attribute));
	return self:get_changed(attribute):Connect(callback);
end

function Attributes:foreach(callback)
	for attribute, value in self.values do
		callback(attribute, value);
	end
	
	for attribute, data in self.objects do
		if (data.o.Value == nil) and (self.values[attribute] == nil) then
			callback(attribute, data.o.Value);
		end;
	end;
end

function Attributes:all()
	return table.clone(self.values);
end

table.freeze(Attributes);

return Attributes;