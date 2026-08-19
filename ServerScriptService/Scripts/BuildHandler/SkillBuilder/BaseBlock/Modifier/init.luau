local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);
local Table = require( ReplicatedStorage.Packages.Table )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Serialise = require( "../../Serialise" );
local InstanceModifier = require( "../../InstanceModifier" );

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(255, 238, 238)
DerivedBlock.icon = "126827005623644"
DerivedBlock.description = "Pulse a custom modifier"
DerivedBlock.help_description = require(script.Description);
DerivedBlock.order = 25;
DerivedBlock.properties = {
	SavePart = {
		Order = 0;
		Default = nil;
		Type = "Instance";
		ViewingHelper = {
			Type = "Modifier";
		};
		
		SaveTo = "SerialisedInstance",
		SaveInstanceLimit = 256; -- Maximum 256 instances total.
		SaveKBLimit = 4_000; -- Maximum 4kb saves.
	};
	SerialisedInstance = {
		Default = "";
		Hidden = true;
		Type = "Instance";
		SaveType = "string";
		SaveManaged = true;
		Filtered = false;
	};
	UseCache = {
		Order = 20;
		Default = true;
	};
	AlwaysUpdatePosition = {
		Order = 30;
		Default = false;
	};
	Cancellable = {
		Order = 40;
		Default = true;
	};
	PowerDuration = {
		Order = 50;
		Default = 0;
		Described = true;
	};
	Lifetime = {
		Order = 55,
		Default = 60,
	};
	Position = {
		Default = Vector3.zero;
		Order = 60;
	};
	Orientation = {
		Default = Vector3.zero;
		Order = 70;
	};
	Parent = {
		Order = 80;
		Default = "None";
		ValueList = { "None", "Storage", "Workspace" };
	};
	Targeting = {
		Order = 120,
		Default = "Default",
		IsBranchTargeting = true;
		ValueList = { "Default", "User", "Target" };
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);

	self.threads = {};
	self.threads_maid = Maid.new();
	
	return self;
end;

local function update_output_position(self, combat, output: Instance)
	if output:IsA("PVInstance") then
		local rot = self.values.Orientation;
		local offset = CFrame.new( self.values.Position ) * CFrame.Angles( math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z) );

		output:PivotTo( combat:get_root_attachment().WorldCFrame * offset );
	end;
end

local function deactivate_modifiers(self, output: Instance, maid: Maid.Maid)
	local combat = self:get_combat();
	local powered_modifiers = InstanceModifier.get_modifiers(output);
	
	for _, modifier in powered_modifiers do
		modifier.active_signal:remove_combat( combat );
		modifier:unpower_from_source( self.modifier );
	end;
end

local function activate_modifiers(self, output: Instance, maid: Maid.Maid)
	local combat = self:get_combat();
	
	if self.values.PowerDuration > 0 then
		local powered_modifiers = InstanceModifier.get_modifiers(output);
		
		for _, modifier in powered_modifiers do
			modifier.active_signal:add_combat( combat);
			modifier:power_from_source( self.modifier );
			modifier:update_powered();
		end;
		
		if self.values.AlwaysUpdatePosition then
			maid:add(RunService.PreSimulation:Connect(function(dt)
				update_output_position(self, combat, output);
			end));
		end;
	else
		local list = InstanceModifier.get_modifiers(output);
		local signal = self.modifier:create_pulse{ combat };

		for _, modifier in list do
			if modifier == self.modifier then
				continue;
			end;

			modifier:pulse(signal);
		end;
	end;
end;

local function get_hidden_modifiers_folder(): Folder
	local folder = ReplicatedStorage.BuildTools:FindFirstChild("Modifiers");
	
	if not folder then
		folder = Instance.new("Folder");
		folder.Name = "Modifiers";
		folder.Parent = ReplicatedStorage.BuildTools;
	end;
	
	return folder;
end;

-------------------------------------------------------------------------

function DerivedBlock:cancel()
	if self.data.Cancellable then
		self.threads_maid:clean();
		
		for thread, output in self.threads do
			if coroutine.status(thread) == "suspended" then
				task.cancel(thread);
				task.delay(0, deactivate_modifiers, self, output);
			end;
		end;
		
		table.clear(self.threads);
	end;
end;

local function remove_modifier(self, output)
	local index = table.find(self.temp_instances, output);
	
	if index then
		table.remove(self.temp_instances, index);
	end;
	
	output:Destroy();
end;

function DerivedBlock:activate(sequencer, combat)
	self:cancel();
	
	if typeof(self.values.SerialisedInstance) ~= "Instance" then
		return warn("Serialised instance is not an Instance, got:", string.sub(tostring(self.values.SerialisedInstance), 1, 20), "...");
	end;
	
	local output_instance = self.values.SerialisedInstance;
	
	if not self.values.UseCache then
		output_instance = output_instance:Clone();
		
		task.delay(self.values.Lifetime, remove_modifier, self, output_instance);
		table.insert(self.temp_instances, output_instance);
	end;
	
	update_output_position(self, combat, output_instance);
	
	local placement_type = self.values.Parent;
	local output_maid = self.threads_maid:limb();
	
	if placement_type == "Storage" then
		output_instance.Parent = get_hidden_modifiers_folder();
		
	elseif placement_type == "Workspace" then
		output_instance.Parent = workspace.Visuals;
	end;
	
	self.sequence_skill.skill_builder.build_handler:load_modifiers(output_instance);
	
	local function start_thread()
		local success, result = pcall(function()
			activate_modifiers(self, output_instance, output_maid);
			task.wait( self.values.PowerDuration / self.sequence_skill:get_speed_multiplier() );
			deactivate_modifiers(self, output_instance, output_maid);
		end);
		
		if not success then
			warn("[Skill Builder]: modifier block exception:", result);
		end;
		
		output_maid:destroy();
	end;
	
	local new_thread = task.defer(start_thread);
	
	output_maid:add(function()
		self.threads[new_thread] = nil;
	end);
	
	self.threads[new_thread] = output_instance;
end;

function DerivedBlock:destroy()
	self.threads_maid:destroy();
	self.proxy_part:Destroy();
	self.proxy_modifier:Destroy();
	
	self.modifier = nil;
	
	BaseBlock.destroy(self);
end

function DerivedBlock:initialise()
	BaseBlock.initialise(self);
	
	self.temp_instances = {};
	
	self.proxy_part = Instance.new("Part");
	self.proxy_modifier = Instance.new("Configuration", self.proxy_part);
	self.proxy_modifier:SetAttribute("Modifier", "Repeater");
	self.proxy_modifier:AddTag("InstanceModifier");
	
	self.modifier = self.sequence_skill.skill_builder.build_handler:load_modifier(self.proxy_modifier);
	self.modifier.phantom_powering = true;
end

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;