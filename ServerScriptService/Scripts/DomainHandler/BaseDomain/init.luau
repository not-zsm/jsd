local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Domains;
local SharedBaseDomain = require( Shared.DomainHandler.BaseDomain );
local DomainWorld = require( Shared.DomainWorld );
local Maid = require( ReplicatedStorage.Packages.Maid )
local Signal = require( ReplicatedStorage.Packages.Signal )
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )

local BaseDomain = {};
BaseDomain.__index = BaseDomain;
BaseDomain.name = script.Name;
BaseDomain.shared = SharedBaseDomain;
BaseDomain.enter_time = 4;
BaseDomain.leave_time = 0;

function BaseDomain.new(DomainHandler, info: any)
	local model = Shared.Assets.Domain:Clone();
	model.CollisionSphere.CanCollide = false;
	
	local world = Shared.Assets.World:Clone();
	world.Parent = model;
	
	if info.origin then
		model:PivotTo(info.origin);
	end;
	
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			maid = maid;
			domain_handler = DomainHandler;
			model = model;
			origin = info.origin;
			owner = info.owner;
			is_npc = not info.owner:IsA("Player"),
			trapped = {};
			excluded = {};
			world = DomainWorld.new(model, model.CollisionSphere.Position);
			
			destroying = maid:add(Signal.new())
		},
		BaseDomain);
	
	return self;
end;

function BaseDomain:initialise()
	self.world:set_world_size(self.shared.world_size);
	self.world.position = self.model.CollisionSphere.Position;
	
	self.model.CollisionSphere.Size = Vector3.one * (self.shared.size + 20);
	self.model.World:PivotTo( self:get_world_coordinate() );
	
	self.other_world = Shared.Assets.World:Clone();

	local world_sphere = Shared.Assets.WorldSphere:Clone();
	world_sphere.Size = self.other_world.CollisionSphere.Size;
	world_sphere.Color = Color3.fromRGB(0, 0, 0);
	world_sphere.Parent = self.other_world;

	self.other_world:PivotTo( CFrame.new(self.world.plane.Position + Vector3.new( 0, 2048, 0 )) );
	self.other_world.Name = "TransitionWorld";
	self.other_world.Parent = self.model;
	
	--self.model.CollisionSphere.Touched:Connect(function(part: BasePart)
	--	local character = part:FindFirstAncestorOfClass("Model");
		
	--	if character then
	--		local humanoid = character:FindFirstChildOfClass("Humanoid");
			
	--		if humanoid then
	--			local player = Players:GetPlayerFromCharacter(character);
				
	--			if (player and self.owner == player) or self.owner == character then
	--				return;
	--			end;
				
	--			self:engulf(character);
	--		end
	--	end
	--end)
end;

function BaseDomain:spawn_dome()
	if self.maid.destroyed then return end;
	
	assert(not self.dome_active, "Dome is already spawned");
	
	self.model.CollisionSphere.CanCollide = true;
	self.dome_active = true;
	
	Shared.Remotes.SpawnDome:FireAllClients(self.model);
end

function BaseDomain:serialise()
	return {
		model = self.model;
		owner = self.owner;
		origin = self.origin;
		domain_type = self.name;
		spawn_dome = self.dome_active
	};
end;

local function get_humanoids_in_folder(folder: Folder, list: {Humanoid}): ()
	for _, child in folder:GetChildren() do
		if child:IsA("Folder") then
			get_humanoids_in_folder(child, list);
			continue;
		end;
		
		local humanoid = child:FindFirstChildOfClass("Humanoid");

		if humanoid then
			table.insert(list, humanoid);
		end;
	end;
end;

function BaseDomain:get_humanoids_in_dome(tolerance: number?): {Humanoid}
	local humanoids: {Humanoid} = {};
	get_humanoids_in_folder(workspace.Models, humanoids);
	
	local valid_humanoids = {};
	
	for _, humanoid in humanoids do
		if humanoid.Health > 0 and humanoid.RootPart and (humanoid.RootPart.Position - self.origin.Position).Magnitude < self.shared.size * 0.5 + (tolerance or 0) then
			table.insert(valid_humanoids, humanoid);
		end;
	end;
	
	return valid_humanoids;
end;

function BaseDomain:get_character()
	return if self.is_npc then self.owner else self.owner.Character;
end

function BaseDomain:get_should_initially_explode(): boolean
	if self.owner and self.domain_handler:get_domain_engulfed_in(self:get_character()) then
		return true;
	end

	for _, other_domain in self.domain_handler:get_domains_in_space(self.origin, 60) do
		if other_domain ~= self then
			return true;
		end;
	end;
	
	return false;
end;

function BaseDomain:play_popup()
	for _, humanoid in self:get_humanoids_in_dome(25) do
		local player = Players:GetPlayerFromCharacter(humanoid.Parent);
		
		if player then
			Shared.Remotes.PopUp:FireClient(player, self.model);
		end;
	end;
end;

function BaseDomain:spawn_wave()
	Shared.Remotes.SpawnWave:FireAllClients(self.model);
end;

function BaseDomain:engulf_in_dome()
	local humanoids = self:get_humanoids_in_dome();
	
	for _, humanoid in humanoids do
		--if humanoid.Parent == self:get_character() then
		--	continue;
		--end;
		
		self:engulf(humanoid.Parent);
	end;
end;

function BaseDomain:clean_trap(character: Model)
	local trapped = self.trapped[character];
	
	if trapped then
		Maid.cleanup(trapped.leave_thread);
		Maid.cleanup(trapped.enter_thread);
	end
end

function BaseDomain:engulf(character: Model)
	if not character or self.excluded[character] then
		return;
	end;
	
	-- Cannot be engulfed in two or more domains at once
	if self.domain_handler:get_domain_engulfed_in(character) then
		return;
	end;
	
	local trapped = self.trapped[character];
	
	if trapped and trapped.inside then
		return;
	end;
	
	if not trapped then
		trapped = { origin = character:GetPivot() };
		self.trapped[character] = trapped;
	end;
	
	self:clean_trap(character);
	trapped.inside = true;
	
	local player = Players:GetPlayerFromCharacter(character);
	
	if player then
		Shared.Remotes.EnterDomain:FireClient(player, self.model);
	else
		trapped.enter_thread = task.spawn(self.enter_character, self, character, trapped);
	end;
end;

function BaseDomain:enter_character(character: Model, trapped): ()
	task.wait(self.shared.plane_transition.pretime);
	
	self.world:teleport_world(
		character, 
		self.world:get_position(false), 
		self.world:get_position(self.other_world),
		"In"
	);
	
	task.wait(self.shared.plane_transition.duration + 0.5);
	
	self.world:teleport_world(
		character, 
		self.world:get_position(self.other_world), 
		self.world:get_position(true),
		"None"
	);
end;

function BaseDomain:spit(character: Model)
	local trapped = self.trapped[character];
	
	if not (trapped and trapped.inside) then
		return;
	end;
	
	local player = Players:GetPlayerFromCharacter(character);

	self:clean_trap(character);
	trapped.inside = false;
	
	if player then
		Shared.Remotes.LeaveDomain:FireClient(player, self.model, trapped);
	else
		trapped.leave_thread = task.spawn(self.leave_character, self, character, trapped);
	end;
end;

function BaseDomain:leave_character(character: Model, trapped)
	task.wait(self.leave_time);
	
	self.world:teleport_world(
		character, 
		self.world:get_position(true), 
		self.world:get_position(false), -- lol
		"Out"
	);
end

function BaseDomain:exclude(character: Model)
	self.excluded[character] = true;
end

function BaseDomain:get_world_coordinate(): CFrame
	assert(self.id, "No id");
	
	return CFrame.new(10_000 + 1_500 * self.id, 10_000, 0);
end

function BaseDomain:destroy()
	self.destroying:Fire();
	self.domain_handler:remove(self);
	
	for character in self.trapped do
		self:spit(character)
	end
	
	table.clear(self.trapped);
	table.clear(self.excluded);
	
	self.model:Destroy();
	self.maid:destroy();
end

table.freeze(BaseDomain);

export type BaseDomain = typeof(BaseDomain.new(...))

return BaseDomain;