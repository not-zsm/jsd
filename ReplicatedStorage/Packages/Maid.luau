--!native
-----------------------------------------------------

local RunService = game:GetService("RunService")

export type ClassMaid = {
	__index: ClassMaid;
	
	--Creates a new <code>Maid</code>, that is a vassal of the <code>Maid</code> used to create.
	--<br><strong>Note</strong>: if the <code>Maid</code> is destroyed, this will return a maid that is also destroyed.
	limb: typeof(function(self: Maid): Maid end);
	
	--Binds a function to RunService.PreRender and adds the connection to the <code>Maid</code> for later clean-up.
	bind_to_render: typeof(function(self: Maid, name: string, priority: number, callback: any): () end);
	
	--Adds the given item to the <code>Maid</code> for later clean-up.
	add: typeof(function<a>(self: Maid, item: a): a end);
	
	--<strong>This method no longer cleans-up the item passed. Use delete() instead if you want this behaviour</strong>
	--Removes the given item from the <code>Maid</code>.
	remove: typeof(function<a>(self: Maid, item: a): a end);
	
	--Removes the given item from the <code>Maid</code> and cleans the item.
	delete: typeof(function<a>(self: Maid, item: a): a end);
	
	--Cleans-up all <code>items</code> that have been added to the <code>Maid</code>.
	clean: typeof(function(self: Maid): () end);
	
	--Calls <code>Maid:clean()</code> on all of this object's vassals, and removes each one from the vassal pool.
	reconcile: typeof(function(self: Maid): () end);
	
	--Removes all added jobs to the <code>Maid</code> without cleaning them up.
	release: typeof(function(self: Maid): () end);
	
	--Locks the <code>Maid</code> object and cleans-up all items.
	--Any subsequent attempts to add items to the <code>Maid</code> will be immediately cleaned-up.
	destroy: typeof(function(self: Maid): () end);
	
	--Binds the <code>Maid</code> to the event of the given <strong>instance</strong> destroying.
	--You can only bind to <strong>one</strong> Instance at a time.
	destroying: typeof(function(self: Maid, instance: Instance): Maid end);
	
	--Binds the <code>Maid</code> to the event of the given <strong>instance</strong> being reparented to <code>nil</code>.
	--You can only bind to <strong>one</strong> Instance at a time.
	removing: typeof(function(self: Maid, instance: Instance): Maid end);
};

export type ClassLightMaid = {
	__index: ClassLightMaid;
	
	--Adds the given item to the <code>Maid</code> for later clean-up.
	add: typeof(function<a>(self: LightMaid, item: a): a end);

	--Removes the given item from the <code>Maid</code>.
	remove: typeof(function<a>(self: LightMaid, item: a): a end);
	
	--Cleans-up all <code>items</code> that have been added to the <code>Maid</code>.
	clean: typeof(function(self: LightMaid): () end);
	
	--Alias for Maid:clean()
	destroy: typeof(function(self: LightMaid): () end);
}

export type ClassMain = {
	__index: ClassMain;
	
	--Creates a new <code>Maid</code>.
	new: typeof(function(): Maid end);
	
	--Creates a new <code>LightMaid</code> which is a heavily cut-down version of a regular <code>Maid</code>. Useful if only used to keep connections.
	light: typeof(function(): LightMaid end);
	
	--Creates a new <code>Maid</code>. Shorthand for <br><code>Maid.new():removing(a):add(b)</code>
	removing: typeof(function(instance: Instance, ...: any): Maid end);
	
	--Creates a new <code>Maid</code>. Shorthand for <br><code>Maid.new():destroying(a):add(b)</code>
	destroying: typeof(function(instance: Instance, ...: any): Maid end);
	
	-- Destroys the given item immediately.
	cleanup: typeof(function(item: any): () end);
	
	-- Cancels the given thread
	cancel: typeof(function(thread: thread): () end);
};

export type LightMaid = typeof(setmetatable({} :: {
	[any]: boolean;
	
}, {} :: ClassLightMaid));
	
export type Maid = typeof(setmetatable({} :: {
	_children: {[Maid]: boolean}?;
	_binding: RBXScriptConnection?;
	_tasks: {[any]: boolean};
	
	parent: Maid?;
	destroyed: boolean?;
	
}, {} :: ClassMaid));

---------------------------------------------------------

local Main = {} :: ClassMain;

local LightMaid = {} :: ClassLightMaid;
LightMaid.__index = LightMaid;

local Maid = {} :: ClassMaid;
Maid.__index = Maid;

Maid.destroyed = false;
Maid.parent = nil;
Maid._binding = nil;
Maid._children = nil;

---------------------------------------------------------

local common_destroy_methods = table.freeze { "Destroy", "destroy", "Dispose", "dispose", "Disconnect", "disconnect", "Clean", "clean" }

local function table_destroy(item: any): ()
	for _, method in common_destroy_methods do
		local method_fn = item[method];
		
		if typeof( method_fn ) == "function" then
			local success, result = pcall(method_fn, item)
			
			if not success then
				warn(`Maid tried to call method {method} but failed: {result}`);
			end;
			
			return;
		end
	end
	
	table.clear(item);
	setmetatable(item, nil);
end

local function instance_destroy(item: Instance): ()
	if item:IsA("AnimationTrack") then
		item:Stop(0);
	end;
	
	item:Destroy();
end

local function disconnect_all(item: {DisconnectAll: (any) -> ()}): ()
	item:DisconnectAll()
end

local function disconnect(item: RBXScriptConnection): ()
	if item.Connected then
		item:Disconnect();
	end;
end

local function cancel_thread(item: any): ()
	if coroutine.status(item) == "suspended" then
		task.cancel(item);
	end;
end;

local cleanup_method_directory = table.freeze {
	["RBXScriptConnection"] = disconnect;
	["table"] = table_destroy;
	["Instance"] = instance_destroy;
	["Signal"] = disconnect_all;
	["thread"] = cancel_thread;
};

local function cleanup(item: any, type_cast: string)
	local method = cleanup_method_directory[type_cast];
	
	if method then
		task.spawn(method, item);
		
	elseif type_cast == "function" then
		task.spawn(item);
	end;
end;

---------------------------------------------------------

function Maid.limb(self: Maid): Maid
	local maid = Main.new();
	maid.parent = self;
	
	if self.destroyed then
		maid:destroy();
	else
		if not self._children then
			self._children = {};
		end;
		
		assert(self._children)
		self._children[maid] = true;
	end;
	
	return maid;
end


function Maid:bind_to_render(name, priority, callback)
	RunService:BindToRenderStep(name, priority, callback);
	
	self:add(function()
		RunService:UnbindFromRenderStep(name);
	end)
end


function Maid.add<a>(self: Maid, item: a): a
	if self.destroyed then
		cleanup(item, typeof(item))
		
	elseif (item ~= nil) then
		self._tasks[item] = true;
	end
	
	return item;
end;


function Maid.delete<a>(self: Maid, item: a): a
	if (item ~= nil) then
		self._tasks[item] = nil;
		cleanup(item, typeof(item));
	end;
	
	return item;
end;


function Maid.remove<a>(self: Maid, item: a): a
	warn("maid remove was called:", debug.traceback());
	
	if (item ~= nil) then
		self._tasks[item] = nil;
	end;

	return item;
end;


function Maid.clean(self: Maid): ()
	-- May be cleared by another Job instance

	for item in self._tasks do
		self._tasks[item] = nil;
		cleanup(item, typeof(item));
	end
	
	table.clear(self._tasks);
	
	if self._children then
		for maid in self._children do
			maid:clean();
		end;
	end;
end


function Maid.release(self: Maid): ()
	table.clear(self._tasks);
end


function Maid.reconcile(self: Maid): ()
	if self._children then
		for maid in self._children do
			maid:clean();
		end;
		
		table.clear(self._children);
	end;
end



function Maid.destroy(self: Maid): ()
	if self.destroyed then return end;
	
	self.destroyed = true;
	
	self:clean();
	
	if self._binding and self._binding.Connected then
		self._binding:Disconnect();
	end
	
	if self.parent then
		assert(self.parent._children, "Parent maid has no children");
		
		self.parent._children[self] = nil;
		self.parent = nil;
	end;
	
	if self._children then
		for maid in pairs(self._children) do
			maid:destroy();
		end;
		
		table.clear(self._children);
	end;
	
	table.clear(self._tasks);
end



function Maid.destroying(self: Maid, instance: Instance): Maid
	if self.destroyed then return end;
	
	assert(not self._binding, "Maid is already bound to an Instance");
	assert(instance, "No Instance to bind to");
	
	self._binding = instance.Destroying:Connect(function()
		self:destroy()
	end)

	return self;
end;



function Maid.removing(self: Maid, instance: Instance): Maid
	if self.destroyed then return end;
	
	assert(not self._binding, "Maid is already bound to an Instance");
	assert(instance, "No Instance to bind to");
	
	self._binding = instance.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:destroy()
		end;
	end)

	return self;
end;


Maid.bind = Maid.destroying;


function LightMaid:add<a>(item: a): a
	if (item ~= nil) then
		self[item] = true;
	end;
	
	return item;
end

function LightMaid:remove<a>(item: a): a
	if (item ~= nil) then
		self[item] = nil;
	end;
	
	return item;
end

function LightMaid:clean()
	for item in self do
		cleanup(item, typeof(item));
	end;
	
	table.clear(self);
end

LightMaid.destroy = LightMaid.clean;


function Main.new(): Maid
	return setmetatable(
		{
			_tasks = {};
		}, 
		Maid);
end;


function Main.light()
	return setmetatable({}, LightMaid);
end


function Main.removing(instance: Instance, ...: any): Maid
	local maid = Main.new():removing(instance);
	
	for _, item in {...} do
		maid:add(item);
	end;
	
	return maid;
end


function Main.destroying(instance: Instance, ...: any): Maid
	local maid = Main.new():destroying(instance);

	for _, item in {...} do
		maid:add(item);
	end;

	return maid;
end


function Main.cleanup(item: any)
	return cleanup(item, typeof(item), nil);
end


function Main.cancel(thread: thread?): ()
	if thread and typeof(thread) == "thread" and coroutine.status(thread) == "suspended" then
		task.cancel(thread);
	end;
end

table.freeze(Maid);
table.freeze(Main);

return Main;