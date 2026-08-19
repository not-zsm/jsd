local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

------------------------------------------------------------------------------------

local Unpacker = require( "./Unpacker" );
local Serialise = require( "./Serialise" );
local Remotes = Unpacker.BuildTools.Remotes;

------------------------------------------------------------------------------------

local StreamService = require( Unpacker.Packages.StreamService );
local BufferUtil = require( Unpacker.Packages.BufferUtil );
local NotificationStatus = require( Unpacker.Shared.Data.NotificationStatus );

local SequenceSkill = require( script.SequenceSkill )
local Branch = require( script.SequenceSkill.Branch )
local BaseBlock = require( script.BaseBlock )
local PlayerEditor = require( script.PlayerEditor )
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )

------------------------------------------------------------------------------------

local SkillBuilder = {};
SkillBuilder.__index = SkillBuilder;

function SkillBuilder.new(build_handler)
	local self = setmetatable(
		{
			build_handler = build_handler,
			properties_data = nil;
			
			players = {};
		}, 
		SkillBuilder);
	
	self:initialise();
	
	return self;
end;

function SkillBuilder:initialise()
	function Remotes.Skills.RequestProperties.OnServerInvoke(player: Player)
		return self:get_serialised_properties_data();
	end;
	
	local function wrap(callback)
		return function(player, ...)
			local editor = self.players[player];
			
			if editor and editor:is_enabled() then
				return callback(editor, ...);
			end
		end
	end
	
	Remotes.Skills.FilterString.OnServerInvoke = wrap(function(editor, text: string)
		if typeof(text) ~= "string" then return end;
		
		local success, filter_text = editor:filter_text_with_debounce(text, 0.75);
		
		if not success then
			return false, "Slow down 👍";
		else
			if filter_text ~= text then
				return false, "Text was filtered 🥀";
			end
			
			return true, filter_text;
		end;
	end)
	
	Remotes.Skills.ExportSkill.OnServerInvoke = wrap(function(editor, slot: number)
		
		local success, exported = pcall( editor.get_slot_compressed, editor, slot );
		
		if not success then
			editor:message({ Title = "Unable to Export Skill", SubTitle = "The skill may be too small to export 🥀", Duration = 6, CanClose = true });
			return;
		end;
		
		return exported;
	end);
	
	Remotes.Skills.ImportSkill.OnServerInvoke = wrap(function(editor, data)
		local slot = editor:get_free_slot();
		
		if slot then
			local success, imported = pcall( editor.import, editor, data );
			
			if not success then
				warn("Unable to Import Skill:", imported);
				
				editor:message({ Title = "Unable to Import Skill", SubTitle = "This data is not formatted correctly", Duration = 6, CanClose = true });
				return;
			end;
			
			editor:save_to_slot(slot, SequenceSkill.reformat(imported))
			
			return slot;
		end;
	end)
	
	Remotes.Skills.RequestTableAnimations.OnServerInvoke = wrap(function(editor)
		return editor:get_animation_table();
	end);
	
	Remotes.Skills.RequestTableSkills.OnServerInvoke = wrap(function(editor)
		return editor:get_skill_table();
	end);
	
	Remotes.Skills.RequestTableEffects.OnServerInvoke = wrap(function(editor)
		return editor:get_effects_table();
	end)
	
	Remotes.Skills.RequestSkillData.OnServerInvoke = wrap(function(editor, slot: number)
		return SequenceSkill.deserialise( editor:get_slot_data(slot), true );
	end)
	
	Remotes.Skills.SubmitSkill.OnServerEvent:Connect(wrap(function(editor, slot: number, data)
		local sequence = self:create_sequence(data)
		
		if sequence then
			sequence:sanitize(editor.player.UserId);
			editor:save_to_slot(slot, sequence:serialise());
		end;
	end))
	
	Remotes.Skills.CreateSkill.OnServerEvent:Connect(wrap(function(editor, slot: number, data)
		if editor:get_slot_info(slot) then
			return editor:message({ Title = "Unable not create slot", SubTitle = "An unknown error occured", Duration = 6, CanClose = true })
		end;
		
		editor:save_to_slot(slot, SequenceSkill.reformat{ 
			EditTime = data.EditTime,
			Properties = { SkillName = data.Properties.SkillName.Value },
			BranchBlocks = {
				{ Blocks = {}, Properties = {} }
			};
		});
	end))
	
	Remotes.Skills.DeleteSkill.OnServerEvent:Connect(wrap(function(editor, slot: number)
		editor:delete_slot(slot);
	end))
	
	Remotes.Skills.ObtainSkill.OnServerEvent:Connect(wrap(function(editor, slot: number)
		local sequence = self:create_sequence_from_serialised( editor:get_slot_data(slot) );

		if sequence then
			local lua_player = LuaPlayerList.Get(editor.player);
			
			if lua_player then
				sequence:create_attack_for( lua_player.Character.Combat );
			else
				warn(`No LuaPlayer found for {editor.Player.Name}`)
			end
		end;
	end))
	
	Players.PlayerRemoving:Connect(function(player)
		self:remove_player_editor(player);
	end)
	
	for _, module in script.BaseBlock:GetChildren() do
		task.defer(require, module);
	end;
	
	StreamService.get_channel("CustomSkillsProfile");
end;

local function get_attack_slot_data(self): any
	if not self.interest_id then return end;

	local player = Players:GetPlayerByUserId(self.interest_id);
	local editor = self.build_handler.skill_builder:get_editor(player);

	if editor then
		local slot, data = editor:get_slot_from_name( self.attributes:get("CustomAction") );

		if slot then
			return editor:get_slot_data(slot)
		end;
	end;
end;

local function create_sequence_skill(self)
	local data = get_attack_slot_data(self);
	local skill_builder = self.build_handler.skill_builder;

	if not data then
		local success, imported = pcall( skill_builder.import, skill_builder, self.attributes:get("_CustomActionSerialised") );

		assert(success, `Unable to create custom skill (failure to import serialised data)`);
		data = imported;
	end;

	local sequence = self.build_handler.skill_builder:create_sequence_from_serialised( data );

	return sequence;
end;

function SkillBuilder:get_skill_sequence(user_id: number, action: string)
	local data = self:get_sequence_data_for_action(user_id, action);
	
	if data then
		return self:create_sequence_from_serialised(data);
	end;
end

function SkillBuilder:get_sequence_data_for_action(user_id: number, action: string)
	local player = Players:GetPlayerByUserId(user_id);
	local editor = self:get_editor(player);

	if editor then
		local slot, data = editor:get_slot_from_name( action );

		if slot then
			return editor:get_slot_data(slot)
		end;
	end;
end;

function SkillBuilder:create_sequence_primitive(user_id: number, action: string, action_serialised_fallback: string?)
	local data = self:get_sequence_data_for_action(user_id, action);
	
	if not data then
		local success, imported = pcall( self.import, self, action_serialised_fallback );

		assert(success, `Unable to create custom skill, bad import: {imported}`);
		data = SequenceSkill.reformat(imported);
	end;
	
	local sequence = self:create_sequence_from_serialised( data );
	
	return sequence;
end

function SkillBuilder:export(data: any)
	local json = HttpService:JSONEncode(data);
	local export_data = Serialise.compress(json, { machine = "Zlib", level = 9 });

	return export_data;
end;

function SkillBuilder:import(data: string)
	local decompressed = Serialise.decompress(data, {});
	local import_data = HttpService:JSONDecode(decompressed);

	return import_data;
end

function SkillBuilder:get_skill_table(player: Player)
	assert(player, "No Player");
	
	local attacks = {};
	local lua_player = LuaPlayerList.WaitFor(player);
	
	if lua_player then
		local attack_settings = { IncludeUsing = true, IncludeWorldEvents = true, RespectSkillBuilder = true };
		
		for _, attack_name in lua_player.Character.Combat:GetListOfAccessibleAttacks(attack_settings) do
			local character = lua_player.Character.Combat:GetCharacterFromAttack(attack_name, true);
			
			if not character then
				warn("No character assigned to attack", attack_name);
				continue;
			end;
			
			if not attacks[character] then
				attacks[character] = {};
			end;
			
			table.insert(attacks[character], attack_name);
		end;
	end;
	
	return attacks;
end;

function SkillBuilder:get_effects_table(player: Player)
	assert(player, "No Player");
	
	local visual_effects = {};
	
	local VFX = ReplicatedStorage.Modules.Player.Replication.VFX;
	local AllowedTypes = { "Sound", "Light", "ParticleEmitter", "Attachment" };
	
	local function recommended(item: Instance): boolean
		for _, allowed_type in AllowedTypes do
			if item:IsA(allowed_type) then
				return true;
			end;
		end;
		
		return false;
	end
	
	local function verify_purity(item: Instance): boolean
		if not ( item:IsA("Folder") or item:IsA("Attachment") or item:IsA("BasePart") ) then
			return false;
		end;
		
		-- Only want top-level Attachment
		if item:IsA("Attachment") and ( item:FindFirstAncestorOfClass("Attachment") ) then
			return false;
		end;
		
		local children = item:GetChildren();
		
		if #children == 0 then
			return false;
		end;
		
		local actionable = false;
		
		for _, child in children do
			if not recommended(child) then
				return false;
				
			elseif child:IsA("Sound") then
				actionable = true;
				
			elseif child:IsA("ParticleEmitter") and ( child:GetAttribute("EmitCount") or child:GetAttribute("EmitUptime") or child:GetAttribute("EmitDuration") ) then
				actionable = true;
			end;
		end;
		
		if not actionable then
			return false;
		end;
		
		return true;
	end;
	
	local function add_effects(item: Instance)
		table.insert(visual_effects, item);
	end;
	
	for _, item in ReplicatedStorage.BuildTools.Effects:GetChildren() do
		add_effects(item);
	end;
	
	local lua_player = LuaPlayerList.WaitFor(player);
	
	if lua_player then
		local attack_settings = { IncludeWorldEvents = true, RespectSkillBuilder = true };
		local characters = lua_player.Character.Combat:GetListOfAccessibleCharacters(attack_settings);
		local characters_include = { Items = true, Powers = true, Global = true };
		
		for _, character in characters do
			characters_include[character] = true;
		end;
		
		for _, character_folder in VFX:GetChildren() do
			if not characters_include[character_folder.Name] then
				continue;
			end;
			
			for _, attack_folder in character_folder:GetChildren() do
				-- Based on exclusions and not moves you can access, if you do not exclude VFX modules for inaccessible moves, players can access these VFX.
				if attack_folder:GetAttribute("ExcludeFromBuilder") then
					continue;
				end;
				
				for _, item in attack_folder:GetDescendants() do
					if verify_purity(item) then
						add_effects(item);
					end;
				end;
			end;
		end;
	end;
	
	return visual_effects;
end;

function SkillBuilder:get_animation_table(player: Player)
	assert(player, "No Player");
	
	local animations = {};
	local folder = ReplicatedStorage.Animations;
	
	local function add_animation(animation: Instance): ()
		if not animation:IsA("Animation") or (string.match(animation.Name, "Cam$") or string.match(animation.Name, "Camera$")) then
			return;
		end;
		
		table.insert( animations, animation );
	end
	
	local function recursive_add(folder: Instance)
		for _, item in folder:GetChildren() do
			if item:GetAttribute("ExcludeFromBuilder") then
				continue;
			end;

			add_animation(item);
			recursive_add(item);
		end;
	end;
	
	local function add_animations(directory: Instance): ()
		add_animation(directory);
		recursive_add(directory);
	end;
	
	local lua_player = LuaPlayerList.WaitFor(player);

	if lua_player then
		local characters = lua_player.Character.Combat:GetListOfAccessibleCharacters{ IncludeWorldEvents = true, RespectSkillBuilder = true };
		local attacks = lua_player.Character.Combat:GetListOfAccessibleAttacks{ IncludeWorldEvents = true, IncludeUsing = true, ReturnHashmap = true, RespectSkillBuilder = true };
		local characters_include = { Items = true, Powers = true, Global = true };
		
		for _, character in characters do
			characters_include[character] = true;
		end;
		
		for _, character_folder in folder.Attacks:GetChildren() do
			if not characters_include[character_folder.Name] then
				continue;
			end;
			
			for _, attack in character_folder:GetChildren() do
				if not attacks[attack.Name] or attack:GetAttribute("ExcludeFromBuilder") then
					continue;
				end;
				
				add_animations(attack);
			end;
		end;
		
		for _, item_folder in { folder.Movement, folder.CharacterSpawnAnimations, folder.Attacks.Global.Dash, folder.Attacks.Global.Block, folder.Attacks.Global.M1 } do
			for _, item in item_folder:GetChildren() do
				if item:IsA("Animation") or characters_include[item.Name] then
					add_animations(item);
				end;
			end;
		end
		
		for _, animation_folder in { folder.ClientActions, folder.Emotes, folder.Global, folder.Items, folder.Miscellaneous, folder.WorldEvents } do
			add_animations(animation_folder);
		end;
		
		for _, item in folder.Parries:GetChildren() do
			if characters_include[item.Name] then
				add_animation(item);
			end;
		end;
	end;
	
	return animations;
end

function SkillBuilder:get_editor(player: Player)
	return self.players[player];
end

function SkillBuilder:add_player_editor(player: Player, profile)
	assert( not self.players[player], "Player editor already exists" );
	
	local player_editor = PlayerEditor.new(self, player, profile);
	
	self.players[player] = player_editor;
	
	return player_editor;
end

function SkillBuilder:remove_player_editor(player: Player)
	if self.players[player] then
		self.players[player]:destroy();
		self.players[player] = nil;
	end
end

function SkillBuilder:get_serialised_properties_data()
	if self.properties_data then
		return self.properties_data;
	end;
	
	local properties_data = {
		properties = {};
		blocks = {};
		branches = {};
	};
	
	for name, property in Branch.properties do
		properties_data.branches[name] = {
			Order = property.Order,
			AssetType = property.AssetType,
			DisplayName = property.DisplayName,
			Default = property.Default,
			Format = property.Format;
			Grayboxed = property.Grayboxed,
		}
	end;
	
	for name, property in SequenceSkill.properties do
		properties_data.properties[name] = {
			Order = property.Order,
			AssetType = property.AssetType,
			DisplayName = property.DisplayName,
			Format = property.Format;
			Default = property.Default,
			Grayboxed = property.Grayboxed,
		}
	end;
	
	for _, module in script.BaseBlock:GetChildren() do
		local success, result = pcall(require, module);
		
		if not success then
			warn(`Failed to load skill block module '{module.Name}', {result}`);
			continue;
		end;
		
		local block_data = { 
			Color = result.color,
			Icon = result.icon,
			Order = result.order or 1,
			Description = result.description,
			HelpDescription = result.help_description,
			Deprecated = result.deprecated,
			Properties = {} 
		};
		properties_data.blocks[module.Name] = block_data;
		
		for name, property in result.properties do
			block_data.Properties[name] = {
				DisplayName = property.DisplayName,
				Order = property.Order,
				AssetType = property.AssetType,
				Default = property.Default,
				Hidden = property.Hidden,
				Described = property.Described,
				ViewingHelper = property.ViewingHelper,
				Format = property.Format;
				Type = property.Type,
				Grayboxed = property.Grayboxed;
				Filtered = property.Filtered;
				ValueList = property.ValueList;
				TitleColor = property.TitleColor;
			}
		end;
	end;
	
	self.properties_data = properties_data;
	
	return properties_data;
end

function SkillBuilder:create_sequence_from_serialised( serialised_data )
	local data = SequenceSkill.deserialise(serialised_data);
	
	if data then
		return self:create_sequence( data );
	end
end

function SkillBuilder:create_sequence( data )
	local sequence = SequenceSkill.new(self);
	
	sequence:generate(data);
	
	return sequence;
end

------------------------------------------------------------------------------------

table.freeze(SkillBuilder);

return SkillBuilder;