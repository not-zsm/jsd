local AttributeListener = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Job = require( replicatedStorage.modules.shared.Utilities.Job )

--function AttributeListener.GetReplicationFromSource(ReplicationSource : (Player | Model | BasePart))
--	local Source = nil

--	if not ReplicationSource:IsA("Player") then

--		if ReplicationSource:IsA("Model") then
--			Source = (Players:GetPlayerFromCharacter(ReplicationSource) or ReplicationSource)

--		elseif ReplicationSource:IsA("BasePart") then
--			Source = (Players:GetPlayerFromCharacter(ReplicationSource.Parent) or ReplicationSource.Parent)
--		end

--	else
--		Source = ReplicationSource
--	end

--	if Source then
--		return workspace.PlayerReplication[Source.Name]
--	end
--end

function AttributeListener.GetReplicationFromSource(ReplicationSource : (Player | Model | BasePart))
	local Source = nil

	if not ReplicationSource:IsA("Player") then

		if ReplicationSource:IsA("Model") then
			Source = Players:GetPlayerFromCharacter(ReplicationSource) or ReplicationSource

		elseif ReplicationSource:IsA("BasePart") then
			local Model = ReplicationSource:FindFirstAncestorOfClass("Model")
			
			if Model then
				Source = Players:GetPlayerFromCharacter(Model) or Model
			end
		end

	else
		Source = ReplicationSource
	end

	if Source then
		local Replication = Source:WaitForChild("Replication", 2);
		assert(Replication, `Unable to get replication config in player: {Source}`);
		
		return Replication;
	end
end

function AttributeListener.new(ReplicationSource : (Player | Model | BasePart), ListenFor : string, Callback : () -> ())
	local Replication = AttributeListener.GetReplicationFromSource(ReplicationSource)
	local NewJob = Job.new()

	NewJob:Task(function()
		if Callback then
			task.spawn(Callback)
		end
	end)

	NewJob:Task(Replication.AncestryChanged:Connect(function(_, Parent)
		if (Parent == nil) then
			NewJob:Destroy()
		end
	end))

	if Replication:GetAttribute(ListenFor) then
		NewJob:Task(Replication:GetAttributeChangedSignal(ListenFor):Connect(function()
			if not Replication:GetAttribute(ListenFor) then
				NewJob:Destroy()
			end
		end))
	else
		NewJob:Destroy()
	end

	return NewJob, Replication
end

return AttributeListener
