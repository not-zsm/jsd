--!native
--!strict

local replicatedStorage = game:GetService("ReplicatedStorage")
local contextActionService = game:GetService("ContextActionService");
local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");
local Players = game:GetService("Players");

type callback = (any) -> cleanup?
type cleanup = () -> ();

local Observer = {};
Observer.__index = Observer;

function Observer.get_tagged(name: string): {Instance}
	return CollectionService:GetTagged(name);
end

function Observer.observe_tag_at(name: string, ancestor: Instance, callback: callback): cleanup
	assert(ancestor, "Ancestor is nil");

	return Observer.observe_tag(name, callback, ancestor);
end

function Observer.observe_tag(name: string, callback: callback, ancestor: Instance?): cleanup
	local instances: {[Instance]: any} = {};
	local descendant_waiting: {[Instance]: thread} = {};
	local active: boolean = true;

	local function cleanup(callback: cleanup?)
		if typeof(callback) == "function" then
			task.spawn(callback);
		end;
	end

	local function attempt_remove(instance: Instance)
		if descendant_waiting[instance] ~= nil then
			if coroutine.status(descendant_waiting[instance]) == "suspended" then
				task.cancel(descendant_waiting[instance]);
			end;

			descendant_waiting[instance] = nil;
		end;

		if instances[instance] ~= nil then
			cleanup(instances[instance]);

			instances[instance] = nil;
		end;
	end;

	local function attempt_add(instance: Instance)
		-- Check if master cleanup hasn't already ran
		if active then
			attempt_remove(instance);

			if ancestor and not instance:IsDescendantOf(ancestor) then
				descendant_waiting[instance] = coroutine.running();
				coroutine.yield();
			end;

			local moment = os.clock();
			instances[instance] = moment;

			-- callback might yield for some reason
			local cleanup_fn = callback(instance);

			-- If still equal to moment then it is safe to assign cleanup function
			if active and instance:HasTag(name) and instances[instance] == moment then
				instances[instance] = cleanup_fn;

				-- Either master cleanup is called or instance loses its tag during callback
			else
				cleanup(cleanup_fn);
			end;
		end;
	end

	-- Add every tagged instance, defer is for concurrency with calling master cleanup immediately
	for _, child in CollectionService:GetTagged(name) do
		task.defer(attempt_add, child);
	end

	local connections = {};

	table.insert(connections, CollectionService:GetInstanceAddedSignal(name):Connect(attempt_add))
	table.insert(connections, CollectionService:GetInstanceRemovedSignal(name):Connect(attempt_remove))

	if ancestor then
		table.insert(connections, ancestor.DescendantAdded:Connect(function(child)
			if descendant_waiting[child] ~= nil then
				if coroutine.status(descendant_waiting[child]) == "suspended" then
					task.spawn(descendant_waiting[child]);
				end

				descendant_waiting[child] = nil;
			end;
		end))

		table.insert(connections, ancestor.DescendantRemoving:Connect(function(child)
			if instances[child] ~= nil and not child:IsDescendantOf(ancestor) then
				attempt_remove(child);

				if child:HasTag(name) then
					attempt_add(child);
				end;
			end;
		end))
	end

	-- Master cleanup
	return function()
		active = false;

		for _, connection in connections do
			if connection.Connected then
				connection:Disconnect();
			end;
		end

		for instance in instances do
			attempt_remove(instance);
		end;
	end;
end;

return Observer;