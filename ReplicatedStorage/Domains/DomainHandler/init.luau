local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Observer = require( ReplicatedStorage.Packages.Observer )

local BaseDomain = require(script.BaseDomain);
local ViewportEffect = require( script.ViewportEffect )
local Domains = script.Parent;
local DomainList = script.BaseDomain;
local Remotes = Domains.Remotes;

local DomainHandler = {};
DomainHandler.__index = DomainHandler;

function DomainHandler.new()
	local self = setmetatable(
		{
			active_domains = {};
			lighting_objects = {};
		}, 
		DomainHandler);
	
	self:initialise();
	
	return self;
end;

function DomainHandler:initialise()
	Remotes.PopUp.OnClientEvent:Connect(function(model)
		local domain = self:get_domain(model);

		if domain then
			domain:play_popup();
		end;
	end);
	
	Remotes.SpawnWave.OnClientEvent:Connect(function(model)
		local domain = self:get_domain(model);

		if domain then
			domain:spawn_wave();
		end;
	end);
	
	Remotes.EnterDomain.OnClientEvent:Connect(function(model)
		local domain = self:get_domain(model);
		
		if domain then
			domain:enter();
		end;
	end)
	
	Remotes.LeaveDomain.OnClientEvent:Connect(function(model, trap_info)
		local domain = self:get_domain(model);

		if domain then
			domain:leave();
		end;
	end)
	
	Remotes.SpawnDome.OnClientEvent:Connect(function(model)
		local domain = self:get_domain(model);
		
		if domain then
			domain:create_bubble(domain.origin);
		end;
	end)
	
	Remotes.BulkCreateDomain.OnClientEvent:Connect(function(data)
		for _, info in data do
			self:create_from_info(info);
		end;
	end);
	
	Remotes.CreateDomain.OnClientEvent:Connect(function(info)
		self:create_from_info(info);
	end);
	
	RunService.PreRender:Connect(function(dt)
		local camera = workspace.CurrentCamera;
		
		for model, domain in self.active_domains do
			if domain.owned then
				continue;
			end;
			
			if domain.world:inside_of(camera.CFrame) then
				domain:show_screen();
			else
				domain:hide_screen();
			end
		end
	end)
end

function DomainHandler:get_domain(model: Model?)
	assert(model, "No model");
	
	local domain = self.active_domains[model];
	assert(domain, `No domain associated with {model.Name}`);
	
	return domain;
end

function DomainHandler:hide_lighting()
	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") then
			child.Parent = nil;
			table.insert(self.lighting_objects, child);
		end;
	end;
end

function DomainHandler:show_lighting()
	Lighting.FogStart = 0;
	Lighting.FogEnd = 100_000;
	Lighting.FogColor = Color3.fromRGB(196, 196, 196);
	
	for _, child in self.lighting_objects do
		child.Parent = Lighting;
	end;

	table.clear(self.lighting_objects);
end

function DomainHandler:create_from_info(info: any): BaseDomain.BaseDomain
	assert(info.model, "No domain model :(");

	local domain = self:create(info.domain_type, info)

	if info.spawn_dome then
		domain:create_bubble(info.origin);
	end;
	
	return domain;
end

function DomainHandler:remove(domain)
	if self.active_domains[domain.model] then
		self.active_domains[domain.model] = nil;
	end
end

function DomainHandler:create(domain_type: string, info: any): BaseDomain.BaseDomain
	local domain = DomainList:FindFirstChild(domain_type);
	
	assert(domain, `No domain exists named {domain_type}`);
	
	local new_domain = require(domain).new(self, info);
	
	self.active_domains[new_domain.model] = new_domain;
	new_domain:initialise();
	
	return new_domain;
end

table.freeze(DomainHandler);

return DomainHandler.new();