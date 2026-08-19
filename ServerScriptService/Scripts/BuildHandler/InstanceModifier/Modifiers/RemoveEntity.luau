local Models = workspace.Models;

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Serialise = require( "../../Serialise" );
local AI = require("../../Npc");
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent.Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.needs_product = nil;
TagModifier.needs_gamepass = nil;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Removes spawned entities or interfaces.";
TagModifier.icon = 11768918600;
TagModifier.color = Color3.fromRGB(255, 161, 161)
TagModifier.section = 3;
TagModifier.use_prompt = false;
TagModifier.properties = {
	Global = {
		Default = false;
	};
	Interface = {
		Default = false;
	};
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end

function TagModifier:pulse(signal)
	local data = self.attributes:all();
	
	for _, modifier in self:get_pulse_targets{} do
		if modifier.entities then
			modifier:clear_entities()
		end;
		
		if data.Interface then
			Unpacker.Remotes.Effects.RemoveInterfaces:FireAllClients(true, modifier.modifier);
		end
	end;
	
	if data.Global then
		for _, entity in AI.list do
			if entity.modifier_affected then
				entity:destroy();
			end;
		end;
		
		if data.Interface then
			Unpacker.Remotes.Effects.RemoveInterfaces:FireAllClients(false);
		end;
		
	elseif self:get_output_value() == self.object 
		and self.part 
		and self.part.Parent 
		and self.part.Parent ~= Models
		and self.part.Parent:IsA("Model") 
		and self.part:IsDescendantOf(Models) 
	then
		self.part.Parent:Destroy();
	end;
end;

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;