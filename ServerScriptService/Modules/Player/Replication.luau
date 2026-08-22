

local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local ReplicationRemotes = ReplicatedStorage.Remotes.Replication

----------------------------------------------------------------------------------

local Replication = {}
Replication.__index = Replication

----------------------------------------------------------------------------------

function Replication:Destroy()
	self.Attributes:Destroy()
end

local function GetRandomEvent()
	return math.random(1, ReplicationRemotes:GetAttribute("EventAmount"))
end;

function Replication:FireVFX(Directory, Function, ...)
	ReplicationRemotes.Unreliable[GetRandomEvent()]:FireAllClients(Directory, Function, ...)
end

function Replication:FireReliableVFX(Directory, Function, ...)
	ReplicationRemotes.Reliable[GetRandomEvent()]:FireAllClients(Directory, Function, ...)
end

function Replication:FireReliableVFXTo(Player: Player, Directory, Function, ...)
	if not Player or not Player:IsA("Player") then 
		return;
	end;
	
	ReplicationRemotes.Unreliable[GetRandomEvent()]:FireClient(Player, Directory, Function, ...)
end

function Replication:FireVFXToSelf(Directory, Function, ...)
	if (not self.LuaPlayer.IsNPC and self.LuaPlayer.Player and self.LuaPlayer.Player.Parent ~= nil) then
		ReplicationRemotes.Unreliable[GetRandomEvent()]:FireClient(self.LuaPlayer.Player, Directory, Function, ...)
	end
end

function Replication:FireReliableVFXToSelf(Directory, Function, ...)
	if (not self.LuaPlayer.IsNPC and self.LuaPlayer.Player and self.LuaPlayer.Player.Parent ~= nil) then
		ReplicationRemotes.Reliable[GetRandomEvent()]:FireClient(self.LuaPlayer.Player, Directory, Function, ...)
	end
end

----------------------------------------------------------------------------------

function Replication.new(LuaPlayer)
	local self = setmetatable({}, Replication)
	
	self.LuaPlayer = LuaPlayer
	
	--self.Attributes = Instance.new("Configuration")
	--self.Attributes.Name = self.LuaPlayer.Player.Name
	--self.Attributes.Parent = workspace.PlayerReplication
	
	self.Attributes = Instance.new("Configuration")
	self.Attributes.Name = "Replication"
	self.Attributes.Parent = self.LuaPlayer.Player
	
	return self
end

----------------------------------------------------------------------------------

coroutine.wrap(function()
	for Index = 1, ReplicationRemotes:GetAttribute("EventAmount") do
		local Unreliable = Instance.new("UnreliableRemoteEvent")
		Unreliable.Name = Index
		Unreliable.Parent = ReplicationRemotes.Unreliable
		
		local Reliable = Instance.new("RemoteEvent")
		Reliable.Name = Index
		Reliable.Parent = ReplicationRemotes.Reliable
	end
end)()

table.freeze(Replication)

return Replication