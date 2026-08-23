local replicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local network = require( replicatedStorage.modules.network )

----------------------------------------------------------------------------------

local Replication = {}
Replication.__index = Replication

----------------------------------------------------------------------------------

function Replication:Destroy()
	self.Attributes:Destroy()
end

-- table.pack rather than {...} so a call ending in nil keeps its arity
local function Effect(Directory : string, Function : string, ...)
	return {
		directory = Directory,
		fn = Function,
		args = if select("#", ...) > 0 then table.pack(...) else nil,
	}
end

function Replication:FireVFX(Directory, Function, ...)
	network.vfx.sendToAll(Effect(Directory, Function, ...))
end

function Replication:FireReliableVFX(Directory, Function, ...)
	network.vfxReliable.sendToAll(Effect(Directory, Function, ...))
end

function Replication:FireReliableVFXTo(Player: Player, Directory, Function, ...)
	if not Player or not Player:IsA("Player") then 
		return;
	end;
	
	network.vfxReliable.sendTo(Effect(Directory, Function, ...), Player)
end

function Replication:FireVFXToSelf(Directory, Function, ...)
	if (not self.LuaPlayer.IsNPC and self.LuaPlayer.Player and self.LuaPlayer.Player.Parent ~= nil) then
		network.vfx.sendTo(Effect(Directory, Function, ...), self.LuaPlayer.Player)
	end
end

function Replication:FireReliableVFXToSelf(Directory, Function, ...)
	if (not self.LuaPlayer.IsNPC and self.LuaPlayer.Player and self.LuaPlayer.Player.Parent ~= nil) then
		network.vfxReliable.sendTo(Effect(Directory, Function, ...), self.LuaPlayer.Player)
	end
end

----------------------------------------------------------------------------------

function Replication.new(LuaPlayer)
	local self = setmetatable({}, Replication)
	
	self.LuaPlayer = LuaPlayer
	
	self.Attributes = Instance.new("Configuration")
	self.Attributes.Name = "Replication"
	self.Attributes.Parent = self.LuaPlayer.Player
	
	return self
end

----------------------------------------------------------------------------------

table.freeze(Replication)

return Replication
