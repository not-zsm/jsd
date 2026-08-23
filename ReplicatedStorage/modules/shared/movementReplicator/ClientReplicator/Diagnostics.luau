local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

---------------------------------------------------------------------------------

local Player = Players.LocalPlayer;
local PlayerGui = Player:WaitForChild("PlayerGui");

---------------------------------------------------------------------------------

local MovementReplicatorFolder = ReplicatedStorage.modules.shared.movementReplicator
local Remotes = MovementReplicatorFolder:WaitForChild("Remotes");
local Assets = MovementReplicatorFolder:WaitForChild("Assets");

---------------------------------------------------------------------------------

local Packages = ReplicatedStorage.Packages

local Signal = require( Packages.Signal )
local Maid = require( Packages.Maid )

local Settings = require( ReplicatedStorage.modules.shared.movementReplicator.Settings )
local Metadata = require( ReplicatedStorage.modules.shared.movementReplicator.Metadata )
local Casting = require( ReplicatedStorage.modules.shared.movementReplicator.Lib.Casting )
local Util = require( ReplicatedStorage.modules.shared.movementReplicator.Util )

local Types = require( script.Parent.Types );

---------------------------------------------------------------------------------

local Diagnostics = {} :: Types.ClassDiagnostics;
Diagnostics.__index = Diagnostics;
Diagnostics.active_color = Color3.fromRGB(92, 255, 119);
Diagnostics.inactive_color = Color3.fromRGB(255, 106, 106);
Diagnostics.info_color = Color3.fromRGB(172, 223, 255);

---------------------------------------------------------------------------------

local FewDots = string.rep(" ˳", 15);

local function get_color_value(value: any): Color3
	if typeof(value) == "boolean" then
		return if value then Diagnostics.active_color else Diagnostics.inactive_color;
		
	elseif typeof(value) == "EnumItem" then
		return Diagnostics.info_color;
	end

	return Diagnostics.active_color;
end

local function get_input_value(value: string): string
	-- Simple divide expression support so you can write something like 1 / 30
	local numerator, denominator = string.match(value, "(%d+).-/.-(%d+)");
	
	if numerator and denominator then
		return tostring( numerator / denominator );
	end;
	
	return value;
end

local function format_value(value: any): string
	if typeof(value) == "EnumItem" then
		return value.Name;
		
	elseif typeof(value) == "NumberRange" then
		return `{value.Min} -> {value.Max}`;
	end

	return tostring(value);
end

local function update_setting(stat: typeof(Assets.UI.Stat), setting: string, value: any)
	if string.find(setting, "tick") then
		value = `{math.round(1 / value)}/s`;
	end

	stat.Value.Box.Text = format_value(value);
	stat.Value.Box.TextColor3 = get_color_value(value);
end

local function create_stat_frame(info)
	local stat = Assets.UI.Stat:Clone();
	stat.Title.Text = info.setting;
	stat.Visible = true;
	
	if info.value ~= nil then
		update_setting(stat, info.setting, info.value);
	end;
	
	if info.can_edit then
		stat.Value.BackgroundTransparency = 0.95;
		stat.Value.Edit.Visible = true;

		if info.edit_type == "boolean" then
			stat.Value.Button.Interactable = true;
			
			if info.callback then
				local enabled = false;
				
				stat.Value.Button.MouseButton1Click:Connect(function()
					enabled = not enabled;
					if not info.dont_update then
						update_setting(stat, info.setting, enabled);
					end;
					info.callback(enabled);
				end)	
			end;
		else
			stat.Value.Box.Interactable = true;
			
			if info.callback then
				stat.Value.Box.FocusLost:Connect(info.callback);
			end;
		end
	else
		stat.Value.Button:Destroy();
		stat.Value.Edit:Destroy();
	end
	
	return stat;
end

local function create_bool_stat(title: string, header: typeof(Assets.UI.Header), callback)
	local enabled = false;

	local stat = create_stat_frame({
		setting = title,
		value = false;
		can_edit = true,
		edit_type = "boolean",
		callback = callback;
	})
	stat.Title.Text = title .. FewDots;
	stat.Title.Name = title;

	stat.Parent = header.Body;
	return stat;
end

---------------------------------------------------------------------------------

function Diagnostics.new(ClientReplicator)
	local maid = Maid.light();
	local enable_maid = Maid.light();
	local proximities_maid = Maid.light();
	
	local self = setmetatable(
		{
			client_replicator = ClientReplicator;

			enabled = false;
			edit_enabled = false;
			is_proximity_expanded = false;
			proximities_enabled = false;
			
			stat_elements = {};
			header_elements = {};
			proximity_elements = {};
			
			maid = maid;
			enable_maid = enable_maid;
			proximities_maid = proximities_maid;
			
			on_enabled_changed = maid:add(Signal.new());
		}, 
		Diagnostics);
	
	self:hook();
	
	return self;
end;

function Diagnostics:destroy()
	self.maid:destroy();
	self.enable_maid:destroy();
end

function Diagnostics:update_setting(setting: string, value: any)
	local stat = self.stat_elements[setting];
	
	if stat then
		update_setting(stat, setting, value);
	end;
end

function Diagnostics:get_replicant_thumbnail(replicant)
	local user_id = replicant.player.UserId;

	-- test server errors
	if user_id < 0 then return end;

	local success, thumbnail = pcall(Players.GetUserThumbnailAsync, Players, user_id, 
		Enum.ThumbnailType.HeadShot, 
		Enum.ThumbnailSize.Size48x48
	);
	
	if success and thumbnail then
		return thumbnail;
	end;
	
	return nil;
end

function Diagnostics:add_replicant(replicant)
	local player_stat = Assets.UI.ProximityPlayer:Clone();
	local player_maid = self.enable_maid:add(Maid.light());
	
	task.spawn(function()
		local thumbnail = self:get_replicant_thumbnail(replicant);
		
		if thumbnail then
			player_stat.Body.Icon.Image = thumbnail;
		end;
	end)

	player_stat.Body.Title.Text = replicant.player.Name;
	player_stat.Items.Visible = false;
	player_stat.Parent = self.in_proximity_header.Body;

	player_stat.Body.Title.Button.MouseButton1Click:Connect(function()
		player_stat.Items.Visible = not player_stat.Items.Visible;
	end)

	player_maid:add(replicant.on_destroying:Once(function()
		player_stat:Destroy();
		player_maid:destroy();
		self.enable_maid:delete(player_maid);
	end))

	player_maid:add(self.in_proximity_header.Title.Button.MouseButton1Click:Connect(function()
		task.wait() -- Oh hell nawww
		player_stat.Items.Visible = self.is_proximity_expanded;
	end))

	local function add_stat(setting: string, event: any, can_edit: boolean)
		local stat_frame; stat_frame = create_stat_frame({
			setting = setting,
			can_edit = can_edit and self.edit_enabled,
			edit_type = "boolean",
			dont_update = true;
			callback = function(value)
				Remotes.UpdatePlayerSetting:FireServer(replicant.player, setting, not replicant[setting]);
			end,
		})
		stat_frame.Title.Text = setting;
		stat_frame.Parent = player_stat.Items;

		local function update_stat()
			update_setting(stat_frame, setting, replicant[setting])
		end

		update_stat();
		player_maid:add(event:Connect(update_stat));
		return stat_frame;
	end

	add_stat("is_ragdolled", replicant.on_ragdoll_changed, true);
	add_stat("in_proximity", replicant.on_proximity_changed, false);

	local stat_frame = Assets.UI.Stat:Clone();
	stat_frame.Title.Text = "Replication Frequency";
	stat_frame.Parent = player_stat.Items;
	
	local last = tick();
	local increment = 0;
	local steps = 0;
	local rate = 0.5;

	player_maid:add(stat_frame);

	player_maid:add(RunService.PostSimulation:Connect(function(dt)
		local now = tick();
		increment += (now - replicant.last);
		steps += 1;

		if now - last > rate then
			stat_frame.Value.Box.Text = math.round(steps / increment * 0.5);
			increment, steps = 0, 0;
			last = now;
		end
	end))
end

function Diagnostics:initialise_replica_stats()
	local headers = {};

	for setting, value in Settings do
		local metadata = Metadata[setting];
		local header, order = metadata.section.title, metadata.section.order;

		if header and not headers[header] then
			local stat_header = Assets.UI.Header:Clone();
			stat_header.Title.Text = header;
			stat_header.Visible = true;
			stat_header.Name = header;
			stat_header.LayoutOrder = order;
			stat_header.Parent = self.ui.Main.Body;

			headers[header] = stat_header;
		end;
		
		local stat: typeof(Assets.UI.Stat);
		
		stat = create_stat_frame({
			setting = setting,
			can_edit = self.edit_enabled and metadata.can_edit,
			edit_type = typeof(value),
			value = value,
			
			callback = function(was_enter_pressed)
				if typeof(value) == "boolean" then
					stat.Value.Box.Text = tostring(not Settings[setting]);
					Remotes.UpdateSetting:FireServer(setting, stat.Value.Box.Text);
				else
					if was_enter_pressed then
						Remotes.UpdateSetting:FireServer(setting, get_input_value(stat.Value.Box.Text));
					else
						update_setting(stat, setting, Settings[setting]);
					end
				end
			end,
		})
		
		stat.Title.Text = setting .. FewDots;
		stat.Name = tostring(metadata.order or "") .. setting;
		stat.Visible = true;

		update_setting(stat, setting, value);
		self.stat_elements[setting] = stat;

		stat.Parent = headers[header].Body;
	end
end

function Diagnostics:initialise_debugger_stats()
	local stat_header = Assets.UI.Header:Clone();
	stat_header.Title.Text = "> Debugging <";
	stat_header.Visible = true;
	stat_header.Name = "Debugger";
	stat_header.LayoutOrder = 1;
	stat_header.Parent = self.ui.Debug.Body;
	
	create_bool_stat("show_proximity", stat_header, function(enabled)
		self:set_proximities_enabled(enabled);
	end)
	
	local stat; stat = create_bool_stat("reset_to_defaults", stat_header, function()
		stat.Value.Box.Text = "Reset";
		stat.Value.Box.TextColor3 = Color3.fromRGB(255, 255, 255);
		
		Remotes.ResetToDefaults:FireServer();
	end)
	
	stat.Value.Box.Text = "Reset";
	stat.Value.Box.TextColor3 = Color3.fromRGB(255, 255, 255);
end

function Diagnostics:add_proximities_replicant(replicant)
	if (replicant.player == Player) then return end;

	local replicant_maid = Maid.light();
	local adornee = replicant.root;

	local billboard_gui = Assets.Debug.ProximityBillboard:Clone();
	billboard_gui.Adornee = adornee;
	billboard_gui.Name = "DebugProximityBillboard"
	billboard_gui.Parent = PlayerGui;

	local function update_proximity(in_proximity: boolean)
		billboard_gui.Title.Text = if in_proximity then "In Range" else "Out Of Range";
		billboard_gui.Title.TextColor3 = if in_proximity then Color3.fromRGB(0, 255, 0) else Color3.fromRGB(255, 0, 0);
		billboard_gui.Light.BackgroundColor3 = billboard_gui.Title.TextColor3;
	end

	local function update_distance()
		if not adornee then return end;
		local distance = Player:DistanceFromCharacter(adornee.Position);

		billboard_gui.SubTitle.Text = `[{math.round(distance)}] Studs`;
	end

	local function destroy()
		billboard_gui:Destroy();
		replicant_maid:destroy();
		self.proximities_maid:delete(replicant_maid);
	end

	task.spawn(update_distance);
	task.spawn(update_proximity, replicant.in_proximity);

	replicant_maid:add(Util.frequency_loop(0.2, update_distance))
	replicant_maid:add(replicant.on_proximity_changed:Connect(update_proximity))
	replicant_maid:add(replicant.on_destroying:Connect(destroy))
	replicant_maid:add(replicant.on_ready_changed:Connect(function(is_ready)
		if is_ready then
			adornee = replicant.root;
			billboard_gui.Adornee = adornee;
		end
	end))

	self.proximities_maid:add(destroy);
end

function Diagnostics:set_proximities_enabled(value: boolean)
	if (self.proximities_enabled ~= value) then
		self.proximities_enabled = value;

		if value then
			for _, replicant in self.client_replicator.replicators do
				task.defer(self.add_proximities_replicant, self, replicant);
			end;

			self.proximities_maid:add(self.client_replicator.on_replicant_added:Connect(function(replicant)
				if not replicant.is_ready then
					replicant.on_ready_changed:Wait();
				end
				self:add_proximities_replicant(replicant);
			end))
		else
			self.proximities_maid:clean();
		end
	end
end

function Diagnostics:initialise_ui()
	if self.ui then
		return warn("Diagnostics UI already exists");
	end;
	
	self.enable_maid:clean();
	
	self.ui = Assets.UI.Diagnostics:Clone();
	self.ui.Name = "ReplicatorDiagnostics";
	
	self.in_proximity_header = Assets.UI.ProximityHeader:Clone();
	self.in_proximity_header.Title.Text = "> Replicants <"
	self.in_proximity_header.Parent = self.ui.Proximity.Body;
	
	self.in_proximity_header.Title.Button.MouseButton1Click:Connect(function()
		self.is_proximity_expanded = not self.is_proximity_expanded;
	end)
	
	self:initialise_replica_stats();
	
	if not Settings.need_permissions_for_debugger_diagnostic or self.edit_enabled then
		self:initialise_debugger_stats();
	else
		self.ui.Debug.Visible = false;
	end;
	
	if not Settings.need_permissions_for_replicant_diagnostic or self.edit_enabled then
		for _, replicant in self.client_replicator.replicators do
			task.defer(self.add_replicant, self, replicant);
		end;

		self.enable_maid:add(self.client_replicator.on_replicant_added:Connect(function(replicant)
			self:add_replicant(replicant);
		end))
	else
		self.ui.Proximity.Visible = false;
	end;
	
	self.ui.Parent = PlayerGui;
end

function Diagnostics:destroy_ui()
	self.enable_maid:clean();
	
	table.clear(self.stat_elements);
	table.clear(self.header_elements);
	
	self.in_proximity_header = nil;
	
	if self.ui then
		self.ui:Destroy();
		self.ui = nil;
	end;
end

local function is_context_pressed(context): boolean
	for key in context do
		if not UserInputService:IsKeyDown(key) then
			return false;
		end;
	end;
	
	return true;
end

function Diagnostics:hook()
	local open_context = { [Enum.KeyCode.LeftShift] = true, [Enum.KeyCode.F8] = true };
	
	UserInputService.InputBegan:Connect(function(input, processed)
		
		if open_context[input.KeyCode] and is_context_pressed(open_context) then
			self:toggle()
		end
	end)
	
	Remotes.UpdateWhitelist.OnClientEvent:Connect(function()
		self.edit_enabled = true;
	end)
end

function Diagnostics:toggle()
	self:set_enabled(not self.enabled);
end

function Diagnostics:set_enabled(value: boolean)
	if self.enabled == value then return end;
	
	self.enabled = value;
	self.on_enabled_changed:Fire();
	
	self:destroy_ui();
	
	if value then
		self:initialise_ui();
	end
end

table.freeze(Diagnostics);

return Diagnostics;