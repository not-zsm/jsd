local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local StreamService = require( ReplicatedStorage.Packages.StreamService )
local SequenceSkill = require( "./SequenceSkill" );
local BufferUtil = require( ReplicatedStorage.Packages.BufferUtil )

local PlayerEditor = {};
PlayerEditor.__index = PlayerEditor;

function PlayerEditor.new(skill_builder, player: Player, profile)
	local self = setmetatable(
		{
			skill_builder = skill_builder,
			player = player,
			profile = profile,
			
			filter_string_debounce = false;
		}, 
		PlayerEditor);
	
	self:initialise();
	
	return self;
end;

function PlayerEditor:validate_profile_format()
	local custom_info = self.profile.Data.CustomSkills.Info;

	for slot, data in custom_info.Slots do
		--local bad_data = true;

		--for name, property in data.Properties do
		--	if typeof(property) ~= "table" then
		--		bad_data = true;
		--		break;
		--	end;
		--end;
		
		-- Reformats the info incase of outdated format.
		custom_info.Slots[slot] = SequenceSkill.reformat(data);
	end;
end;

--function PlayerEditor:force_rollback(user_id: number, hours_ago: number)
--	local hours = hours_ago;
--	local profile_key = `{user_id}`;
--	local time_now = DateTime.now().UnixTimestampMillis
--	local store = DataStoreService:GetDataStore("PlayerStore")

--	local rollback_success = false;
	
--	local listSuccess, pages = pcall(function()
--		return store:ListVersionsAsync(profile_key, Enum.SortDirection.Ascending, time_now - hours * 60 * 60 * 1000, time_now, 1)
--	end)
	
--	if listSuccess then
--		local items = pages:GetCurrentPage()

--		local item = items[1];
		
--		if item then
--			local data = store:GetVersionAsync(profile_key, item.Version).Data;
			
--			for index, value in data do
--				self.profile.Data[index] = value;
--			end;
			
--			rollback_success = true;
--		end;
--	end;
	
--	if not rollback_success then
--		warn(`Unable to rollback user {user_id}'s data`);
--	else
--		print(`Successfully rolled user {user_id}'s data to {hours_ago} hour(s) ago`);
--	end;
--end

function PlayerEditor:initialise()
	--self:force_rollback(self.player.UserId, 1);
	local custom_info = self.profile.Data.CustomSkills.Info;
	
	self:validate_profile_format();
	
	self.stream = StreamService.new("CustomSkillsProfile", custom_info);
	self.stream:connect_listeners({ self.player });
end;

function PlayerEditor:get_builder()
	return self.skill_builder.build_handler:get(self.player)
end;

function PlayerEditor:notify(status, description, duration)
	local builder = self:get_builder();

	if builder then
		builder:push_notification(status, description, duration)
	end;
end;

function PlayerEditor:filter_text_with_debounce(text: string, debounce: number): (boolean, string)
	if self.filter_string_debounce then
		return false;
	end;
	
	self.filter_string_debounce = true;
	
	task.delay(debounce, function()
		self.filter_string_debounce = false;
	end);
	
	return true, self.skill_builder.build_handler:filter_text(text, self.player.UserId);
end

function PlayerEditor:is_enabled(): boolean
	local builder = self:get_builder()
	
	if builder and builder.enabled then
		return true;
	end;
	
	return false;
end

function PlayerEditor:destroy()
	self.stream:destroy();
	
	self.cached_effects_table = nil;
	self.cached_skill_table = nil;
	self.cached_animation_table = nil;
end;

function PlayerEditor:get_effects_table()
	if self.cached_effects_table then
		return self.cached_effects_table;
	end;
	
	self.cached_effects_table = self.skill_builder:get_effects_table(self.player);
	
	return self.cached_effects_table;
end;

function PlayerEditor:get_skill_table()
	if self.cached_skill_table then
		return self.cached_skill_table;
	end;

	self.cached_skill_table = self.skill_builder:get_skill_table(self.player);
	
	return self.cached_skill_table;
end;

function PlayerEditor:get_animation_table()
	if self.cached_animation_table then
		return self.cached_animation_table;
	end;

	self.cached_animation_table = self.skill_builder:get_animation_table(self.player);
	
	return self.cached_animation_table;
end;

function PlayerEditor:get_slot_from_name(name: string)
	for slot, data in self.profile.Data.CustomSkills.Info.Slots do
		if data.Properties.SkillName.Value == name then
			return slot, data;
		end;
	end;
	
	return nil, nil;
end;

function PlayerEditor:get_slot_info(slot: number)
	return self.profile.Data.CustomSkills.Info.Slots[tostring(slot)];
end;

function PlayerEditor:get_slot_data(slot: number)
	local data = self.profile.Data.CustomSkills.DataSlots[tostring(slot)];
	
	if typeof(data) == "string" then
		data = self:import(data);
	end;
	
	return SequenceSkill.reformat( data );
end;

function PlayerEditor:get_slot_compressed(slot: number)
	local data = self.profile.Data.CustomSkills.DataSlots[ tostring(slot) ];

	-- Is already compressed.
	if typeof(data) == "string" then
		return data;
	end;
	
	-- Compress it as it is an uncompressed table.
	return self:export(data);
end

function PlayerEditor:get_free_slot(): number?
	for slot = 1, self.stream:get{"SlotAmount"} or 128 do
		-- Slot is free
		if not self.profile.Data.CustomSkills.Info.Slots[tostring(slot)] then
			return slot;
		end;
	end;
	
	return nil;
end;

function PlayerEditor:export(data: any)
	return self.skill_builder:export(data);
end;

function PlayerEditor:import(data: string)
	return self.skill_builder:import(data);
end

function PlayerEditor:message(data)
	data.VisibleTo = self.player;
	data.DisplayOrder = 194;
	
	local message = self.skill_builder.build_handler:create_message(data);
	
	return message;
end;

function PlayerEditor:delete_slot(slot: number)
	local str_slot = tostring(slot);
	
	self.stream:set({"Slots", str_slot}, nil);
	self.profile.Data.CustomSkills.DataSlots[str_slot] = nil;
end

function PlayerEditor:save_to_slot(slot: number, data)
	local str_slot = tostring(slot);
	local max_slots = self.stream:get({"SlotAmount"});
	
	if not (slot >= 1 and slot <= max_slots) then
		self:message({
			Title = "Too many skills", 
			SubTitle = "You can only create 255 skills",
			CanClose = true;
			Duration = 5
		});
		return;
	end;
	
	local compress_string = self:export(data);
	local max_string_size = 25 * 1_000 -- 25 KB
	
	if string.len(compress_string) > max_string_size then
		self:message({
			Title = "Exceeded the maximum data limit of 30KB", 
			SubTitle = "Please reduce the amount of blocks your skill uses, sorry!",
			CanClose = true;
			Duration = 5;
		});
		return;
	end
	
	local slot_index = {"Slots", str_slot};
	local slot_data = self.stream:get(slot_index)
	local now = DateTime.now().UnixTimestamp;
	
	if not slot_data then
		slot_data = { 
			CreateTime = now,
			Properties = {};
			InfoProperty = {};
		};
		self.stream:set(slot_index, slot_data);
	end;
	
	self.stream:set({"Slots", str_slot, "EditTime"}, now);
	
	for name, properties in SequenceSkill.properties do
		self.stream:set({"Slots", str_slot, "Properties", name}, data.Properties[name]);
	end;
	
	self.profile.Data.CustomSkills.DataSlots[str_slot] = compress_string;
end;

table.freeze(PlayerEditor);

return PlayerEditor;