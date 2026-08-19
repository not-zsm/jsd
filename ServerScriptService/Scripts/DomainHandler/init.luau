local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local BaseDomain = require(script.BaseDomain);
local DomainList = script.BaseDomain;

local Shared = ReplicatedStorage.Domains;


local DomainHandler = {};
DomainHandler.__index = DomainHandler;
DomainHandler.folder = Instance.new("Folder");
DomainHandler.folder.Name = "Domains";
DomainHandler.folder.Parent = workspace;

function DomainHandler.new()
	local self = setmetatable(
		{
			active_domains = {};
			active_domain_ids = {};
			domain_count = 0;
			domain_id = 0;
		}, 
		DomainHandler);
	
	self:initialise();
	
	return self;
end;

function DomainHandler:initialise()
	Players.PlayerAdded:Connect(function(player)
		local domains = {};
		
		for id, domain in self.active_domain_ids do
			table.insert(domains, domain:serialise());
		end;
		
		if domains[1] then
			Shared.Remotes.BulkCreateDomain:FireClient(player, domains);
		end;
	end)
end

function DomainHandler:get_id()
	if self.domain_count >= 65536 then
		return;
	end;
	
	local identifier;
	
	for current_id = 1, 65536 do
		if not self.active_domain_ids[current_id] then
			identifier = current_id;
			break;
		end
	end
	
	assert(identifier, "No id could be found");
	
	return identifier;
end

function DomainHandler:from_model(model: WorldModel): any
	return self.active_domains[model];
end

function DomainHandler:from_id(id: number)
	return self.active_domain_ids[id];
end

function DomainHandler:remove(domain): ()
	if self.active_domains[domain.model] then
		self.active_domains[domain.model] = nil;
		self.active_domain_ids[domain.id] = nil;
		self.domain_count -= 1;
		
		Shared.Remotes.DestroyDomain:FireAllClients(domain.model);
	end;
end;

function DomainHandler:get_domain_engulfed_in(character: Model): BaseDomain.BaseDomain?
	for model, domain in self.active_domains do
		if domain.trapped[character] then
			return domain;
		end;
	end;
	
	return nil;
end

function DomainHandler:get_domains_in_space(coordinate: CFrame, tolerance: number)
	local domains = {};
	
	for model, domain in self.active_domains do
		if domain.world:inside_of(coordinate, tolerance) or domain.world:inside_of_world(coordinate, tolerance) then
			table.insert(domains, domain);
		end;
	end;
	
	return domains;
end

function DomainHandler:create(domain_type: string, info): BaseDomain.BaseDomain
	local domain = DomainList:FindFirstChild(domain_type);
	
	assert(domain, `No domain exists named {domain_type}`);
	
	if info.origin then
		local plant = workspace:Raycast(info.origin.Position, Vector3.yAxis * 20, Utility.GroundParams);
		
		if plant then
			info.origin = info.origin.Rotation + plant.Position;
		end;
	end;
	
	local new_domain = require(domain).new(self, info);
	local id = self:get_id();
	
	self.active_domains[new_domain.model] = new_domain;
	self.active_domain_ids[id] = domain;
	self.domain_count += 1;
	
	new_domain.id = id;
	new_domain:initialise();
	
	Shared.Remotes.CreateDomain:FireAllClients(new_domain:serialise());
	
	if new_domain:get_should_initially_explode() then
		-- 😭
		task.delay(0.4, function()
			new_domain:destroy();
		end);
	end;
	
	return new_domain;
end

table.freeze(DomainHandler);

return DomainHandler.new();