local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseBlockModule = script.Parent.BaseBlock;

local BaseBlock = require( BaseBlockModule );
local Branch = require( script.Branch );
local Thread = require( script.Thread );
local Sequencer = require( script.Sequencer )

local Serialise = require( "../Serialise" );
local Utility = require( "./Utility" );
local Table = require( ReplicatedStorage.Packages.Table )
local Type = require( ReplicatedStorage.Packages.Type )

local SequenceSkill = {};
SequenceSkill.__index = SequenceSkill;
SequenceSkill.properties = {
	SkillName = {
		Order = 0;
		Default = "Unnamed Skill";
	};
	DisplayName = {
		Order = 10,
		Default = "{SkillName}"
	};
	ToolTip = {
		Order = 20;
		Default = "";
	};
	Cooldown = {
		Order = 30,
		Default = 5
	};
	SpeedMultiplier = {
		Order = 40,
		Default = 1,
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 3);
			Increment = 1 / 60,
		},
	};
	DamageMultiplier = {
		Order = 50,
		Default = 1,
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 3);
			Increment = 1 / 60,
		},
	};
	RagdollMultiplier = {
		Order = 60,
		Default = 1,
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 3);
			Increment = 1 / 60,
		},
	};
	KnockbackMultiplier = {
		Order = 70,
		Default = 1,
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 3);
			Increment = 1 / 60,
		},
	};
	WalkspeedDivider = {
		Order = 80,
		Default = 3,
	};
	MaximumUses = {
		Order = 90,
		Default = 0
	};
	ResetUIState = {
		DisplayName = "Reset UI State";
		Order = 100,
		Default = true;
	};
	AllowedInAwakening = {
		Order = 110,
		Default = true
	};
	AllowedInBase = {
		Order = 120,
		Default = true
	};
	AllowedForItemsOnly = {
		Order = 130,
		Default = "",
		Grayboxed = true;
	};
	RemoveOnMovesetSwitch = {
		Order = 140,
		Default = false;
	};
	PreventOverride = {
		Order = 150,
		Default = false
	};
};

function SequenceSkill.new(skill_builder)
	local self = setmetatable(
		{
			skill_builder = skill_builder,
			branches = {};
			data = {};
		}, 
		SequenceSkill);
	
	self.values = Utility.block_getter(self.data);
	self.main_sequencer = Sequencer.new(self);
	
	return self;
end;

function SequenceSkill:destroy()
	self.cache_config:Destroy();
	
	for _, branch in self.branches do
		branch:destroy();
	end;
	
	table.clear(self.branches);
	
	if self.main_sequencer then
		self.main_sequencer:destroy();
	end;
	
	self.combat = nil;
	self.attack = nil;
end;

function SequenceSkill:create_cache()
	self.cache_config = Instance.new("Configuration");
	self.cache_config.Name = `Skill [{self:get_value("SkillName")}]`;
end

function SequenceSkill.get_block(name: string)
	local block = BaseBlockModule:FindFirstChild(name);
	
	if block then
		local module = require(block)
		
		return module;
	end;
end

function SequenceSkill.serialise_property(blocket, info)
	if not blocket then
		blocket = { Value = info.Default, Gray = info.Grayboxed };
		
	elseif typeof(blocket) ~= "table" then
		blocket = { Value = blocket, Gray = info.Grayboxed };
	else
		blocket = table.clone(blocket);
	end;

	-- SaveTo should only be used for serialising instance types 👍
	local value_type = info.SaveType or info.Type or typeof(info.Default);
	local type_caster = Type[value_type];

	if not type_caster or value_type == "table" then
		return ;
	end;
	
	if (value_type == "Instance" and typeof(blocket.Value) == "Instance") then
		local descendants = blocket.Value:GetDescendants();

		if #descendants > (info.SaveInstanceLimit or 128) then
			warn(`Instance {blocket.Value.Name} contains more than 128 instances ({#descendants})`);
			return;
		end;

		local data, size = Serialise.serialise(blocket.Value);

		-- Under 5Kb, otherwise reject it to make sure you can't overload the profile.
		if size < (info.SaveKBLimit or 5_000) then
			blocket.Value = data;
			return blocket;
		end;
	else
		local new_value, success, err = type_caster:cast(blocket.Value);
		
		if success then
			blocket.Value = Serialise.serialise_value( value_type, new_value )
			return blocket;
		end;
	end;
end

-- I messed up and had to change and refactor the saved format several times, meaning this function is thrice as long as it needs to be as it corrects the old formats.
-- spent way too much time fixing this 🥀💔
function SequenceSkill.reformat(data_live)
	-- Old format 1: convert to new
	if data_live.Blocks and not data_live.BranchBlocks then
		data_live.BranchBlocks = { { Blocks = data_live.Blocks } };
		data_live.Blocks = nil;
	end;
	
	-- Mainly required because I used completely different table structures initially, this is so the older formats still work.
	local function format_blocket(blocket, info)
		if typeof(blocket) == "table" then
			if blocket.value ~= nil and blocket.Value == nil then
				blocket.Value, blocket.value = blocket.value, nil;
			end;

			if blocket.gray ~= nil and blocket.Gray == nil then
				blocket.Gray, blocket.gray = blocket.gray, nil;
			end;

			if blocket.Value ~= nil then
				return blocket;
			end;
		end;
		
		if typeof(blocket) == "table" then
			return { 
				Value = blocket;
				Gray = info.Grayboxed;
			};
		else
			return SequenceSkill.serialise_property(blocket, info);
		end;
	end

	if data_live.Properties then
		-- Skill Name is now used instead of DisplayName for atomicity.
		local no_skill_name = data_live.Properties.SkillName == nil;
		
		for name, info in SequenceSkill.properties do
			data_live.Properties[name] = format_blocket(data_live.Properties[name], info);
		end;
		
		if no_skill_name and data_live.Properties.SkillName then
			data_live.Properties.SkillName.Value = data_live.Properties.DisplayName.Value;
			data_live.Properties.DisplayName.Value = "{SkillName}";
		end;
	end;

	if data_live.BranchBlocks then

		for branch_index, branch in data_live.BranchBlocks do
			if not branch.Properties then
				branch.Properties = { };
			end;

			-- Convert from old format
			if branch.Name then
				branch.Properties.BranchName = { Value = branch.Name };
				branch.Name = nil;
			end

			for branch_property, branch_info in Branch.properties do
				local blocket = branch.Properties[branch_property];

				-- Old Format 2: convert loose properties
				if blocket == nil then
					blocket = branch[branch_property];
				end;
				
				branch.Properties[branch_property] = format_blocket(blocket, branch_info);
			end
			
			for index, block_data in branch.Blocks do

				-- Old Format 3: convert to universal data structure for values
				if block_data.InfoProperty then
					for name, data_block in block_data.InfoProperty do
						local block = SequenceSkill.get_block(block_data.Name);
						local info = block.properties[name];
						
						if not info then continue; end;
						
						local value = block_data.Properties[name];
						local blocket = format_blocket(value, info);
						
						if blocket then
							blocket.Gray = data_block.Grayed;
							blocket.Value = value;
							
							block_data.Properties[name] = blocket;
						end;
					end;

					block_data.InfoProperty = nil;
				end;

				for name, data_block in block_data.Properties do
					local block = SequenceSkill.get_block(block_data.Name);
					local info = block.properties[name];

					if not info then
						warn(`Property with name {name} doesn't exist within {block_data.Name} block`);
						block_data.Properties[name] = nil; -- Wipe it to prevent any recurring issues.
						continue;
					end;
					
					block_data.Properties[name] = format_blocket(data_block, info);
				end;
			end;
		end;
	end;
	
	return data_live;
end

-- Make sure the data is in the correct format (call .reformat)
function SequenceSkill.deserialise(data, instance_mode: boolean?)
	assert(not Branch.properties.Blocks, "Cannot use 'Blocks' as a branch property, it is reserved.");
	
	local data_live = Table.clone(data);
	
	local function deserialise_blocket(blocket, info): any
		if not blocket then return end;
		
		local value_type = info.Type or typeof(info.Default);

		if (value_type == "Instance") and not instance_mode then
			local success, instances = pcall(Serialise.deserialise, blocket.Value);

			if success then
				blocket.Value = instances[1];
			end;
		else
			local success, new_value = pcall(Serialise.deserialise_value, value_type, blocket.Value, info.Default)

			if success then
				blocket.Value = new_value;
			end;
		end;
		
		return blocket;
	end;
	
	if data_live.Properties then
		for name, info in SequenceSkill.properties do
			data_live.Properties[name] = deserialise_blocket(data_live.Properties[name], info);
		end;
	end;
	
	if data_live.BranchBlocks then
		for branch_index, branch in data_live.BranchBlocks do
			for branch_property, branch_info in Branch.properties do
				branch.Properties[branch_property] = deserialise_blocket( branch.Properties[branch_property], branch_info );
			end
			
			for index, block_data in branch.Blocks do
				for name, data_block in block_data.Properties do
					local block = SequenceSkill.get_block(block_data.Name);
					local info = block.properties[name];

					if not info then
						continue;
					end;
					
					block_data.Properties[name] = deserialise_blocket(data_block, info);
				end;
			end;
		end;
	end;
	
	return data_live;
end;

function SequenceSkill:serialise()
	local serialised = {};
	serialised.Properties = {};
	serialised.BranchBlocks = {};
	
	for property, info in SequenceSkill.properties do
		serialised.Properties[property] = self.data[property];
	end;
	
	for index, branch in self.branches do
		serialised.BranchBlocks[index] = branch:serialise();
	end;
	
	return serialised;
end;


-- Filters all strings ✅
-- Make sure to call this after a user submits their own skill.
function SequenceSkill:sanitize(user_id: number): ()
	local start_time = os.clock();
	
	local function filter_chunk(property, info, data)
		if not data[property] then
			warn(`Chunk does not have property {property} (value: {data[property]})`)
			return;
		end;
		
		local value = data[property].Value;
		local new_value = self.skill_builder.build_handler:sanitize_block(user_id, value, info);

		-- Was filtered
		if new_value ~= value then
			data[property].Value = new_value;
		end;
	end;
	
	for property, info in SequenceSkill.properties do
		filter_chunk(property, info, self.data);
	end;
	
	for _, branch in self.branches do
		for property, info in branch.properties do
			filter_chunk(property, info, branch.data);
		end;
		
		for index, block in branch.blocks do
			for property, info in block.properties do
				filter_chunk(property, info, block.data);
			end;
		end;
	end;
	
	-- print( `Sanitized SequenceSkill in time: {os.clock() - start_time}` );
end

function SequenceSkill:generate(data)
	for property, value in data.Properties do
		self.data[property] = value;
	end;
	
	for branch_index, branch_data in data.BranchBlocks do
		local branch = Branch.new(self, branch_data.Properties);
		branch.index = branch_index;
		
		self.branches[branch_index] = branch;
		
		for _, block_data in branch_data.Blocks do
			local position = #branch.blocks + 1;
			local block = self:create_block(block_data.Name, block_data);
			
			block:set_branch(branch, position);
		end;
	end;
end;

function SequenceSkill:get_speed_multiplier(): number
	return self.data.SpeedMultiplier.Value * self.combat:GetSpeedMultiplier();
end;

function SequenceSkill:get_blocks(name: string?)
	local blocks = {};
	
	if name then
		for _, branch in self.branches do
			for _, block in branch.blocks do
				if block.name == name then
					table.insert(blocks, block);
				end;
			end;
		end;
	else
		for _, branch in self.branches do
			table.move(branch.blocks, 1, #branch.blocks, #blocks + 1, blocks);
		end;
	end;
	
	return blocks;
end;

function SequenceSkill:cancel_all()
	for index, block in self:get_blocks() do
		block:cancel();
	end;
end;

function SequenceSkill:close_all()
	for index, block in self:get_blocks() do
		block:close();
	end;
end;

function SequenceSkill:get_active_branch_value(name: string)
	if self.current_branch then
		local data = self.current_branch.data[name];
		
		if data and not data.Gray then
			return data.Value;
		end;
	end;
	
	return self:get_value(name);
end

function SequenceSkill:get_branch(name: string)
	for _, branch in self.branches do
		if branch:get_value("BranchName") == name then
			return branch;
		end;
	end;
	
	return nil;
end;

function SequenceSkill:start_hit_branch(branch, combat)
	local sequencer;
	
	local function block_iterate(index, block)
		local targeting = block.properties.Targeting
		local block_combat = combat;
		
		if targeting and targeting.IsBranchTargeting then
			local target = block.data.Targeting.Value;
			
			if target == "User" then
				block_combat = self.combat;
			end;
		end;
		
		return block:trigger( sequencer, block_combat );
	end;
	
	sequencer = Sequencer.new(self);
	sequencer:start(block_iterate, branch);
	
	return sequencer;
end

function SequenceSkill:branch_to(branch_name: string, index: number?)
	return self.main_sequencer:branch_to(branch_name, index);
end;

function SequenceSkill:get_previous_blocks(from_block)
	return self.main_sequencer:get_previous_blocks(from_block);
end;

function SequenceSkill:start(callback, branch)
	local origin_branch = branch or self.branches[1];
	
	if not self.loaded_cache then
		self.loaded_cache = true;
		
		for _, block in self:get_blocks() do
			block:initialise_cache( self.cache_config );
		end;
	end;
	
	self.main_sequencer:start(callback, origin_branch);
end;

function SequenceSkill:wait()
	if self.main_sequencer.thread then
		self.main_sequencer.thread.closed:Wait();
	end;
end;

function SequenceSkill:stop()
	self.main_sequencer:stop();
end;

function SequenceSkill:get_current_cooldown(): number
	--local final_branch = self.main_sequencer.current_branch;
	local cooldown: number?;
	
	--if final_branch and not final_branch.data.Cooldown.Gray then
	--	cooldown = final_branch:get_value("Cooldown");
	--else
		cooldown = self:get_value("Cooldown");
	--end
	
	return tonumber(cooldown) or 5;
end

function SequenceSkill:get_builder()
	if not self.combat then return end;
	
	return self.skill_builder.build_handler:get(self.combat.LuaPlayer.Player);
end

function SequenceSkill:set_variant_interest(block)
	local current_interest = self.variant_interest;
	
	self.variant_interest = nil;
	
	if current_interest then
		current_interest:remove_interest();
	end;
	
	self.variant_interest = block;
	self.attack:UpdateBranchState();
end

function SequenceSkill:create_attack_for(combat: any, key: EnumItem?)
	assert(not self.combat, "Already given to another combat :(");
	
	local attack_name = self:get_value("SkillName");
	
	self:create_cache();
	
	if combat.Attacks[attack_name] then
		combat:RemoveAttack(attack_name);
	end;
	
	if not key then
		key = combat:GetNextAttackKey();
	end;
	
	local attack = combat:CreateAttack( attack_name, key, "Custom" );
	
	self.combat = combat;
	self.attack = attack;
	
	attack:SetCustomSequence(self);
	
	for _, block in self:get_blocks() do
		block:initialise_attack(attack);
	end
	
	self.cache_config.Parent = combat.LuaPlayer.Player;
	
	return attack;
end;

function SequenceSkill:get_value(name: string)
	if self.data[name] then
		return self.data[name].Value;
	end
end

function SequenceSkill:create_block(name: string, ...)
	local module = SequenceSkill.get_block(name);
	assert(module, `Could not create a skill block of type '{name}'`);

	local block = module.new(self, ...);
	
	block:initialise();
	
	return block;
end;

table.freeze(SequenceSkill);

return SequenceSkill;