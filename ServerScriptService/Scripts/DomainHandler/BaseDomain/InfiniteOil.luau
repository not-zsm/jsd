local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Domains;

local BaseDomain = require(script.Parent);

local InfiniteOil = setmetatable({}, BaseDomain)
InfiniteOil.__index = InfiniteOil;
InfiniteOil.name = script.Name;
InfiniteOil.shared = require(Shared.DomainHandler.BaseDomain[script.Name]);

function InfiniteOil.new(...)
	local self = setmetatable(BaseDomain.new(...), InfiniteOil);
	
	return self;
end;

table.freeze(InfiniteOil);

return InfiniteOil;