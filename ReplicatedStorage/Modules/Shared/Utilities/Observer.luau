local CollectionService = game:GetService("CollectionService")

type InstanceStatus = "__inflight__" | "__dead__"

return function(tag: string, callback: (instance: T) -> (() -> ())?): () -> ()
	local instances: { [Instance]: InstanceStatus | () -> () } = {}

	local onInstAddedConn: RBXScriptConnection
	local onInstRemovedConn: RBXScriptConnection

	local function AttemptStartup(instance: Instance)
		-- Mark instance as starting up:
		instances[instance] = "__inflight__"

		-- Attempt to run the callback:
		task.defer(function()
			if instances[instance] ~= "__inflight__" then
				return
			end

			local success, cleanup = pcall(callback, instance)

			if success then
				if instances[instance] ~= "__inflight__" then
					if (cleanup ~= nil) then
						task.spawn(cleanup)
					end
				else
					-- Good startup; mark the instance with the associated cleanup function:
					instances[instance] = cleanup :: any
				end
			end
		end)
	end

	local function AttemptCleanup(instance: Instance)
		local cleanup = instances[instance]
		instances[instance] = "__dead__"

		if typeof(cleanup) == "function" then
			task.spawn(cleanup)
		end
	end

	local function OnInstanceAdded(instance: Instance)
		if not onInstAddedConn.Connected then
			return
		end
		
		if (instances[instance] == nil) then
			AttemptStartup(instance)
		end
	end

	local function OnInstanceRemoved(instance: Instance)
		AttemptCleanup(instance)
		instances[instance] = nil
	end

	onInstAddedConn = CollectionService:GetInstanceAddedSignal(tag):Connect(OnInstanceAdded)
	onInstRemovedConn = CollectionService:GetInstanceRemovedSignal(tag):Connect(OnInstanceRemoved)

	task.defer(function()
		if not onInstAddedConn.Connected then
			return
		end

		for _, instance in CollectionService:GetTagged(tag) do
			task.spawn(OnInstanceAdded, instance)
		end
	end)

	return function()
		onInstAddedConn:Disconnect()
		onInstRemovedConn:Disconnect()

		for _, instance in instances do
			OnInstanceRemoved(instance)
		end
	end
end