local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Havoc = require("../Havoc");

local Shared = ReplicatedStorage.Havoc;

local ClientDestruction = setmetatable({}, Havoc);
ClientDestruction.__index = ClientDestruction;

function ClientDestruction.new(DestructionHandler, ...)
	local self = setmetatable(Havoc.create(...), ClientDestruction);
	
	self.destruction_handler = DestructionHandler;
	self.rollback = {};
	self.time = time();
	self.preset = nil;
	
	self:query();
	self.affected = self:get_query_destructed();
	self.reference = self.affected[1];
	
	self:initialise();
	
	return self;
end;

function ClientDestruction:initialise()
	
end

function ClientDestruction:destroy()
	table.clear(self.rollback);
	table.clear(self.affected);
	self.havoc = nil;
	self.reference = nil;
end

function ClientDestruction:serialise()
	return {
		id = self.id,
		crater = self.crater,
		debris = self.debris,
		havoc = self:get_parameters(),
		rollback = self.rollback,
		preset = self.preset,
		time = self.time,
	};
end

function ClientDestruction:create_effects()
	--Shared.Remotes.CreateEffects
end

function ClientDestruction:destruct(parameters)
	local destructed = self:destruct_using_query(parameters)

	for _, part in destructed do
		table.insert(self.rollback, {part, Havoc.destructs[part].properties})
	end
end

function ClientDestruction:create_crater(info)
	local crater = Havoc.create_crater(self, info);
	
	for _, part in crater do
		part.Parent = Havoc.folder.StaticServer;
	end
	
	self.crater = info;
end

function ClientDestruction:create_debris(parameters)
	
	-- Debris are not made on the server.
	-- local debris = Havoc.create_debris(self, parameters);
	
	self.debris = parameters;
end

table.freeze(ClientDestruction);

return ClientDestruction;