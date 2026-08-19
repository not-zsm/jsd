local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local Serialise = require("../../Serialise") --require( ServerScriptService.BuildHandler.Serialise )
local BossAI = require("../.././Npc/Bots/PineappleBoss")
local MinionAI = require("../.././Npc/Bots/PineappleMinion")
--local BossAI = require( ServerScriptService.BuildHandler.Npc.Bots.PineappleBoss )
--local MinionAI = require( ServerScriptService.BuildHandler.Npc.Bots.PineappleMinion )

local InstanceModifier = require( script.Parent.Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.needs_product = nil;
TagModifier.needs_gamepass = "PineappleBoss";
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Summons the pineapple boss.";
TagModifier.icon = 903000961;
TagModifier.color = Color3.fromRGB(255, 119, 0)
TagModifier.section = 5;
TagModifier.use_prompt = false;
TagModifier.properties = {
	Debounce = {
		Default = 60
	};
	Goon = {
		Default = false
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	self.entities = {};
	
	return self;
end

function TagModifier:pulse(signal)
	if not self.entities then return end;
	
	local clone_enemy, entity;
	
	if self.attributes:get("Goon") then
		clone_enemy = script.PineappleMan:Clone()
		entity = MinionAI.new(clone_enemy.Humanoid);
	else
		clone_enemy = script.PineappleBoss:Clone()
		entity = BossAI.new(clone_enemy.Humanoid);
	end;
	
	clone_enemy:PivotTo(self:get_cframe());
	clone_enemy.Parent = workspace.Models;
	
	self.entities[clone_enemy] = true;

	entity.maid:add(function()
		self.entities[clone_enemy] = nil;
	end)
end

function TagModifier:destroy()
	for enemy in self.entities do
		enemy:Destroy();
	end;

	table.clear(self.entities);

	InstanceModifier.destroy(self);
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;