local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Domains;

local BaseDomain = require(script.Parent);

local CandyLab = setmetatable({}, BaseDomain)
CandyLab.__index = CandyLab;
CandyLab.name = script.Name;
CandyLab.shared = require(Shared.DomainHandler.BaseDomain[script.Name]);

function CandyLab.new(...)
	local self = setmetatable(BaseDomain.new(...), CandyLab);
	
	return self;
end;

table.freeze(CandyLab);

return CandyLab;