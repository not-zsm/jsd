local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Unpacker = require( "../../Unpacker" );

local Type = require( Unpacker.Packages.Type );
local CommandHandler = require( ServerScriptService.Scripts.Game.Modules.CommandHandler )
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Gain another move";
TagModifier.icon = 2252732140;
TagModifier.color = Color3.fromRGB(175, 84, 255)
TagModifier.section = 3;
TagModifier.use_prompt = true;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Action = {
		Order = 1;
		Default = "Limitless Strikes";
		ValueList = "Skills",
		
		Shows = {
			["CustomAction"] = {"Custom"};
		};
	};
	CustomAction = {
		Order = 2;
		Default = "",
		ValueList = "CustomSkill";
		Hidden = true;
	};
	_CustomActionSerialised = {
		Default = "";
		
		Hidden = true;
	};
	_CustomActionUserId = {
		Default = "",
		Hidden = true;
	};
	DisplayName = {
		Order = 3;
		Default = "";
	};
	Prompt = {
		Order = 4;
		Default = true;
	};
	Add = {
		Order = 5;
		Default = true;
		Hidden = false;
		Hides = { "Keybind", "Override", "AllowKeybindDuplicates" };
	};
	Keybind = {
		Order = 6,
		Hidden = false;
		Default = Enum.KeyCode.One;
	};
	Override = {
		Order = 7,
		Hidden = false;
		Default = true;
	};
	AllowKeybindDuplicates = {
		Order = 8,
		Hidden = false;
		Default = true;
	};
	Remove = {
		Order = 9;
		Default = false;
		Shows = { "ClearHotbar", "OnlyRemoveCustom" };
		Hides = { "Add", "Keybind", "Override", "AllowKeybindDuplicates" };
	};
	ClearHotbar = {
		Order = 10;
		Default = false;
		Hidden = true;
	};
	OnlyRemoveCustom = {
		Order = 11;
		Default = false;
		Hidden = true;
	};
};

-------------------------------------------------------------------------------------------

local function get_user_id(self): number?
	return self.interest_id or self.attributes:get("_CustomActionUserId");
end;

local function get_sequence_data(self)
	return self.build_handler.skill_builder:get_sequence_data_for_action(get_user_id(self), self.attributes:get("CustomAction"));
end

local function create_sequence(self)
	return self.build_handler.skill_builder:create_sequence_primitive(get_user_id(self), self.attributes:get("CustomAction"), self.attributes:get("_CustomActionSerialised"));
end

-------------------------------------------------------------------------------------------

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end

function TagModifier:prompt_set()
	local data = self.attributes:all();
	local object_text = if data.Action ~= "Custom" then data.Action else data.CustomAction;
	local action_text = "";
	
	if data.Remove then
		if data.ClearHotbar then
			object_text = "";
			
			if data.OnlyRemoveCustom then
				action_text = "Remove Custom Moves";
			else
				action_text = "Remove All Moves"
			end
		else
			action_text = "Remove"
		end;
	else
		action_text = if data.Action ~= "Random" then "Move" else "Random Move";
	end;
	
	self.prompt.ActionText = action_text;
	self.prompt.ObjectText = object_text;
	self.prompt.Enabled = data.Prompt;
end;

function TagModifier.attribute_updates:CustomAction(value, was_init)
	if was_init then return end;
	
	-- We need to serialise the data incase the player who set the custom action is no longer in-game, it it can still give players the custom skill.
	local data = get_sequence_data(self);
	
	if data then
		local skill_builder = self.build_handler.skill_builder;
		local success, exported = pcall( skill_builder.export, skill_builder, data );
		
		if success then
			self.attributes:set("_CustomActionSerialised", exported);
			self.attributes:set("_CustomActionUserId", self.interest_id);
		end;
	end;
end;

function TagModifier:pulse(signal)
	local sampled;
	local data = self.attributes:all();
	
	local skill_builder = self.build_handler.skill_builder;
	
	local use_random_action = data.Action == "Random";
	local use_display_name = data.DisplayName ~= "";
	local is_custom_action = data.Action == "Custom";
	
	local actual_action = if is_custom_action then data.CustomAction else data.Action;
	local attack_settings = { IncludeWorldEvents = true, RespectSkillBuilder = true };
	
	for _, combat in signal:get_combats() do
		local player = combat:get_player();
		
		if data.Remove and data.ClearHotbar then
			for name, attack in combat.Attacks do
				if data.OnlyRemoveCustom and not attack.CustomAttack then
					continue;
				end;
				
				-- So it won't remove M1, Block, or Dash 🥀
				-- And won't remove vital attacks (I.E kratot's Weapons)
				if attack.DirectoryParent == "Global" or attack.CoreCharacter then
					continue;
				end;
				
				combat:RemoveAttack(name);
			end;
			
		elseif data.Remove then
			combat:RemoveAttack(actual_action);
			
		elseif data.Action ~= "None" and ( use_random_action or is_custom_action or combat:CanUseNamedAttack(data.Action, attack_settings) ) then
			local next_key;
			
			if data.Add then
				next_key = combat:GetNextAttackKey();
			else
				next_key = data.Keybind;
			end;
			
			if (next_key ~= nil and next_key ~= Enum.KeyCode.Unknown and typeof(next_key) == "EnumItem") then
				local override_attack = combat:GetFirstAttackUsingKey(next_key);
				
				if data.Override and override_attack then
					combat:RemoveAttack(override_attack.Name);
				end;
				
				if data.AllowKeybindDuplicates or data.Override or not override_attack then
					local attack;
				
					if use_random_action then
						local attack_list = combat:GetListOfAccessibleAttacks(attack_settings);
						local random = attack_list[math.random(1, #attack_list)];
						
						if not combat:GetFirstAttack(random) then
							attack = combat:CreateAttack(random, next_key);
						end;
						
					elseif is_custom_action then
						
						if not combat:GetFirstAttack(actual_action) then
							local sequence = create_sequence(self);
							
							attack = sequence:create_attack_for(combat, next_key);
						end;
						
					elseif not combat:GetFirstAttack(actual_action) then
						attack = combat:CreateAttack(actual_action, next_key);
					end;
					
					if attack then
						attack.RemoveOnSpawn = true;
						
						if use_display_name then
							attack.DisplayName = data.DisplayName;
						end;
						
						if attack.Name ~= attack.DisplayName then
							combat:ChangeAttackDisplay(attack.Name, attack.DisplayName, {})
						end;
					end;
				end;
			end;
		end;
	end;
end;

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;