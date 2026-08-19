local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Serialise = require( "../Serialise" );
local Utility = require( "./Utility" );

local Type = require( ReplicatedStorage.Packages.Type )
local Maid = require( ReplicatedStorage.Packages.Maid )

local BaseBlock = {};
BaseBlock.__index = BaseBlock;
BaseBlock.name = script.Name;
BaseBlock.order = 1;
BaseBlock.description = "No Description";
BaseBlock.properties = {};

function BaseBlock.new(sequence_skill, block_data)
	local data = block_data.Properties;
	
	local self = setmetatable(
		{
			maid = Maid.new(),
			sequence_skill = sequence_skill,
			data = data or {};
			position = 1;
		}, 
		BaseBlock);
	
	self.values = Utility.block_getter(self.data);
	
	return self;
end;

function BaseBlock:destroy()
	self.maid:destroy();
end;

function BaseBlock:get_internal_name(): string
	return `{string.lower(string.sub(string.gsub(self.name, "%u", "_%0"), 2))}`
end

function BaseBlock:serialise()
	local serialised = {
		Name = self.name;
		Properties = {};
	};
	
	for name, info in self.properties do
		local value_data = self.data[name];
		local new_value_data = self.sequence_skill.serialise_property(value_data, info);
		
		if new_value_data then
			if info.SaveManaged and serialised.Properties[name] then
				continue;
			end;
			
			serialised.Properties[info.SaveTo or name] = new_value_data;
		end
	end;
	
	return serialised;
end;

function BaseBlock:get_values()
	local values = {};
	
	for property, data in self.data do
		values[property] = data.Value;
	end;
	
	return values;
end

function BaseBlock:get_value(property: string): any
	if self.data[property].Gray then
		return nil;
	end;
	
	return self.data[property].Value;
end;

function BaseBlock:set_branch(branch, position: number?)
	self.branch = branch;
	
	if position then
		self.position = position;
	end;
	
	if branch.blocks[position] ~= nil then
		warn(`Block is overwriting another block in position {position}`);
	end;
	
	branch.blocks[position] = self;
end

function BaseBlock:get_cooldown(): number
	if not self.branch.data.Cooldown.Gray then
		return tonumber(self.branch.values.Cooldown);
	end;
	
	return tonumber(self.sequence_skill.values.Cooldown);
end;

function BaseBlock:get_combat()
	return self.sequence_skill.combat;
end;

function BaseBlock:get_attack()
	return self.sequence_skill.attack;
end

function BaseBlock:get_previous_block()
	return self.branch.blocks[ self.position - 1 ];
end

function BaseBlock:get_next_block()
	return self.branch.blocks[ self.position + 1 ];
end;

function BaseBlock:get_previous_blocks()
	return self.sequence_skill:get_previous_blocks();
end

function BaseBlock:get_previous_blocks_of_type(name: string)
	local previous_blocks = {};
	
	for _, block in self.sequence_skill:get_previous_blocks() do
		if block.name == name then
			table.insert(previous_blocks, block);
		end;
	end;
	
	return previous_blocks;
end

function BaseBlock:get_previous_block_of_type(name: string)
	for _, block in self.sequence_skill:get_previous_blocks() do
		if block.name == name then
			return block;
		end;
	end;
	
	return nil;
end;

function BaseBlock:initialise_attack(attack: any)
	
end

function BaseBlock:initialise_cache(cache: Configuration)

end

function BaseBlock:initialise()
	for name, info in self.properties do
		if not self.data[name] then
			self.data[name] = { Value = info.Default, Gray = info.Grayboxed };
		end;
	end;
end;

--function BaseBlock:trigger(...)
--	if not self.loaded_cache then
--		self.loaded_cache = true;
--		self:initialise_cache(self.sequence_skill.cache_config);
--	end;
	
--	return self:activate(...);
--end;

function BaseBlock:activate(...)
	warn("block was activated");
end;

function BaseBlock:trigger(...)
	return self:activate(...);
end;

function BaseBlock:cancel()
	-- warn("tried to cancel but method was not overridden ...");
end;

function BaseBlock:close()
	self:cancel();
end

---------------------------------------------------------------

table.freeze(BaseBlock);

return BaseBlock;