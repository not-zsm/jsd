-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local rateLimiter = require( replicatedStorage.modules.shared.Utilities.rateLimiter )
local MessagingService = game:GetService("MessagingService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local ServerStorage = game:GetService("ServerStorage")
local Macros = replicatedStorage.modules.shared.Commands.Macros;

local Commands = require( replicatedStorage.modules.shared.Commands )
local UserRoles = require( replicatedStorage.modules.shared.Commands.UserRoles )
local BanList = require( replicatedStorage.modules.shared.Commands.PrivateServerBanList )

local AnnouncementHandler = require( ServerStorage.modules.AnnouncementHandler )

local LuaPlayerList = require( ServerStorage.modules.LuaPlayerList )

--local Whitelist = require( ServerStorage.modules.Whitelist )
local Whitelist = require( replicatedStorage.modules.shared.Game.Whitelist )

local CommandHandler = {}
CommandHandler.__index = CommandHandler

local MAX_PLAYER_LOGS = 1_000;

local DEFAULT_PERFORM_SETTINGS = { 
	ApplyRestrictions = true, 
	NotifyRestriction = true, 
	Logging = true 
};

local StrRestrictionDebounce = "RestrictedTargetDebounce";
local StrGlobalDebounce = "GlobalCommandDebounce";

type RunCommandResult = "Boss" | "No Target";
type RestrictionResult = "Global Blocked" | "Self Restriction" | "Higher Up";
type CommandTarget = Player | "Others" | "All" | "Me";
type UserRole = UserRoles.UserRole;

-- Command Names that aren't allowed to be used on "All" or "Others"
local GlobalBlocked = {"To", "Kick", "Server Ban"}

function SendNotification(Player : Player, NotificationTitle : string, NotificationText : string, NotificationIcon : number, Duration : number)
	Duration = Duration or 5

	if not NotificationIcon then
		NotificationIcon = 112856803225144
	end

	local IconString = `rbxassetid://{NotificationIcon}`

	network.notify.sendTo({
		Title = NotificationTitle, 
		Text = NotificationText, 
		Icon = IconString,
		Duration = Duration
	}, Player)
end

--local Warned = {}

--Players.PlayerRemoving:Connect(function(Player)
--	if Warned[Player] then
--		Warned[Player] = nil;
--	end;
--end);

function CommandHandler:PlayerUsedCommands(Player : Player)
	if Player:GetAttribute("UsedCommands") then
		return true
	end

	return false
end

function CommandHandler:PrepareToUseCommand(Player): boolean
	if Player:GetAttribute("CannotUseCommands") then 
		SendNotification(Player, "Error", "You cannot use commands at the moment.");

		return false;
	end

	local Role: UserRole = self:GetRole(Player)
	local Level = Role.Permission;

	if not Role.BypassBosses then
		workspace:SetAttribute("DisableBosses", true)
	end;

	return true;
end;

function CommandHandler:GetRole(PlayerOrPermission: Player | string): UserRole
	local Permission = "None";

	if typeof(PlayerOrPermission) == "string" then
		Permission = PlayerOrPermission;
	else
		Permission = self:GetPermission(PlayerOrPermission);
	end;

	local Role = UserRoles[Permission];

	if not Role then
		warn("No defined role exists for", Permission);
		return UserRoles.None;
	end;

	return Role;
end

-- Does more checks if you supply a direct Player Instance.
-- Its less restrictive if you give the method 'All' or 'Others', so this function must be called initially, then for every Player Instance affected from something like 'All' or 'Others'
function CommandHandler:IsTargetRestricted(Command, Player: Player, Target: CommandTarget): (boolean, RestrictionResult?)
	local PlayerRole: UserRole = self:GetRole(Player);
	local IsSelf = (Player == Target or Target == "Me");

	if not Command.IgnoreSelfRestriction and PlayerRole.RestrictToSelf and not IsSelf then
		return true, "Self Restriction";
	end;

	if typeof(Target) == "Instance" then
		local TargetRole: UserRole = self:GetRole(Target);

		if not Command.UnrestrictedTarget and (PlayerRole.Level < TargetRole.Level and not IsSelf) then
			return true, "Higher Up";
		end;

	elseif Target == "Others" or Target == "All" then
		-- Make sure player doesnt use extreme command on All/Others
		if table.find(GlobalBlocked, Command.Name) then
			return true, "Global Blocked";
		end;
	end;

	return false;
end;

function CommandHandler:TryNotifyRestriction(Command, Player: Player, Target: CommandTarget)
	if not Player:GetAttribute(StrRestrictionDebounce) then
		Player:SetAttribute(StrRestrictionDebounce, true);

		task.delay(1, function()
			Player:SetAttribute(StrRestrictionDebounce, false);
		end);

		if typeof(Target) == "Instance" then
			SendNotification(Player, "Warning", `You cannot use commands on other players.`, nil, 2.5);
			SendNotification(Target, "Info", `{Player.Name} with the rank {self:GetPermission(Player)} tried running {Command.Name} on you. 💔`, nil, 2.5);
		else
			SendNotification(Player, "Warning", `You cannot use commands on {Target}`, nil, 2.5);
		end
	end;
end

function CommandHandler:PerformCommand(Command, Player, TargetPlayer, Parameters, Settings): (boolean, string?, RestrictionResult?)
	local LuaPlayer = LuaPlayerList.Get(Player);
	local TargetLuaPlayer = LuaPlayerList.Get(TargetPlayer);

	if not (LuaPlayer and TargetLuaPlayer) then
		return false, "Invalid Player";
	end;

	local IsRestricted, RestrictionResult = false, nil;

	if Settings.ApplyRestrictions then
		IsRestricted, RestrictionResult = self:IsTargetRestricted(Command, Player, TargetPlayer)
	end

	if IsRestricted then

		if Settings.NotifyRestriction then
			self:TryNotifyRestriction(Command, Player, TargetPlayer);
		end;

		return false, "Restricted", RestrictionResult;
	else
		task.spawn(Command.Callback, LuaPlayer, TargetLuaPlayer, Parameters);

		return true;
	end;
end

-- Run a Command
-- Returns whether the command ran, and if it didn't run - the reason.
function CommandHandler:RunCommand(Command, Player: Player, Target: CommandTarget, Parameters, Settings): (boolean, RunCommandResult?)
	local CanContinue = self:PrepareToUseCommand(Player);

	if not CanContinue then
		return false, "Boss";
	end;

	local PlayerRole: UserRole = self:GetRole(Player);

	if PlayerRole.GlobalCooldown then
		if Player:GetAttribute(StrGlobalDebounce) then
			return;
		end;

		Player:SetAttribute(StrGlobalDebounce, true);

		task.delay(PlayerRole.GlobalCooldown, function()
			Player:SetAttribute(StrGlobalDebounce, false);
		end);
	end;

	local Settings = Settings or DEFAULT_PERFORM_SETTINGS;
	local IsSingleTarget = typeof(Target) == "Instance";
	local CommandLog = {};

	local function PerformCommand(CommandTarget: CommandTarget)
		local Success, FailReason, RestrictionReason = self:PerformCommand(Command, Player, CommandTarget, Parameters, Settings);

		if not Success and FailReason == "Restricted" then
			CommandLog.WasRestricted = true;
		end;
	end;

	if not IsSingleTarget and self:IsTargetRestricted(Command, Player, Target) then
		if Settings.NotifyRestriction then
			self:TryNotifyRestriction(Command, Player, Target);
		end;

		CommandLog.WasRestricted = true;

	elseif IsSingleTarget then
		CommandLog.TargetType = "Player";
		CommandLog.TargetUserId = Target.UserId;
		CommandLog.TargetUserName = Target.Name;
		CommandLog.TargetDisplayName = Target.DisplayName;

		PerformCommand(Target);

	elseif Target == "Others" then
		for _, TargetPlayer in Players:GetPlayers() do
			if TargetPlayer ~= Player then
				PerformCommand(TargetPlayer);
			end
		end;

	elseif Target == "All" then
		for _, TargetPlayer in Players:GetPlayers() do
			PerformCommand(TargetPlayer);
		end;

	elseif Target == "Me" then
		PerformCommand(Player);

	else
		return false, "No Target"
	end

	CommandLog.CommandName = Command.Name;
	CommandLog.Parameters = Parameters;
	CommandLog.TargetType = CommandLog.TargetType or Target;
	CommandLog.Permission = PlayerRole.Permission;

	if Settings.Logging then
		self:CreateCommandLog(Player, CommandLog);
	end;

	return true;
end

--local PsPeople = {
--	242509995, 119987926
--}

--119987926 -- rod
--242509995 -- binx

--local Developers = {
--	166263406
--}

--function CommandHandler:GetPermission(Player : Player) : number?
--	local LuaPlayer = LuaPlayerList.LuaPlayers[Player]

--	if (LuaPlayer == nil) then 
--		return 4
--	end

--	if LuaPlayer.Character.Combat:IsOwner() then
--		return 1
--	end

--	if table.find(PsPeople, Player.UserId) then
--		return 2
--	end

--	if game.PrivateServerOwnerId == Player.UserId then
--		if LuaPlayer.Data:HasGamepass("Private Server+") then
--			return 2
--		else
--			return 3
--		end
--	end

--	return 4
--end

function CommandHandler:GetPermission(Player : Player) : string
	if (Player.UserId == 2496412033) then
		return "GOB"
	end

	local LuaPlayer = LuaPlayerList.Get(Player);

	--if Player.Name == "swrerm" then
	--	return "Developer"
	--end

	--if Player.Name == "Aenoir" then
	--	return "Staff"
	--end

	if (LuaPlayer == nil) then 
		return "None"
	end

	if LuaPlayer.Character.Combat:IsOwner() then
		return "Owner"
	end

	if (game.PrivateServerOwnerId == Player.UserId) then
		if LuaPlayer.Data:HasGamepass("Private Server+") or shared.IsTestPlace then
			return "PS+"
		else
			return "PS"
		end
	end

	if Whitelist.is_permitted(Player.UserId, "Developer Panel") then
		return "Developer"
	end

	if Whitelist.is_permitted(Player.UserId, "Staff Panel") then
		return "Staff"
	end

	return "None"
end

local ServerLocked = false

-- Initialize
function CommandHandler._new()
	local self = setmetatable({}, CommandHandler);

	self.SlashCommands = require( script.SlashCommands ).new(self)
	self.ActiveMacros = {};
	self.PlayerLogs = {};
	self.PlayerLogsPointer = 0;
	self.CommandLogs = {};
	self.CommandLogsPointer = 0;

	self.DisableBosses = false;
	self.HasCommandsBeenUsed = false

	--[[
		CreateMacro and Send were two remotes reaching the same shape, so they
		share the runCommand packet and split on its macro flag. Wanting is the
		flag this wrapper answers to; the packet's own typing replaces the
		hand-written CommandName check.
	--]]
	local function CommandWrap(Limiter, Wanting, Callback)

		return function(data, Player: Player)
			if data.macro ~= Wanting then return end

			local CommandName, Target = data.command, data.target
			local Role: UserRole = self:GetRole(Player)

			if (Role.RateLimit ~= -1 and rateLimiter.check(Player, Limiter, Role.RateLimit or 10) == false) then
				return;
			end;

			if not (typeof(Target) == "string" or typeof(Target) == "Instance") then return end

			if (Role.Permission ~= "None") then
				local Command = Commands[CommandName];

				if not Command then 
					return;
				end;

				if not table.find(Command.PermissionsToTrigger, Role.Permission) then
					return network.notify.sendTo({
						Title = "Notification",
						Text = "You do not have permission to run this command",
						Duration = 2
					}, Player);
				end;

				return Callback(Player, CommandName, Command, Target, data.parameters);
			else
				network.notify.sendTo({
					Title = "Notification",
					Text = "You do not have permissions to run commands.",
					Duration = 2
				}, Player)
			end;
		end;
	end;

	network.runCommand.listen(CommandWrap("createMacro", true, function(Player, CommandName, Command, Target, Parameters)
		if table.find(GlobalBlocked, CommandName) then return end;
		if typeof(Parameters) ~= "table" then return end;

		if #Macros:GetChildren() >= 100 then
			return SendNotification(Player, "Error", "Limited to a maximum of 100 total macros.");
		end;

		if not Command.CanMacro then
			return SendNotification(Player, "Error", "Macros are disabled for this command 💔");
		end;

		local NormalTarget = Target;
		local TargetType = Target;

		if typeof(Target) == "Instance" and Target:IsA("Player") then
			TargetType = "Player";
			NormalTarget = Target.UserId;
		end;

		if self:IsTargetRestricted(Command, Player, Target) then
			return self:TryNotifyRestriction(Command, Player, Target);
		end

		if not self:PrepareToUseCommand(Player) then
			return;
		end;

		local CommandLog = {};
		CommandLog.IsMacro = true;
		CommandLog.TargetType = TargetType;
		CommandLog.CommandName = Command.Name;
		CommandLog.TargetType = CommandLog.TargetType or Target;
		CommandLog.Permission = Player:GetAttribute("PanelPermission") or self:GetPermission(Player);
		CommandLog.Parameters = Parameters;

		self:CreateCommandLog(Player, CommandLog);

		local Macro = Instance.new("Configuration");
		Macro.Name = CommandName;
		Macro:SetAttribute("Targets", NormalTarget);

		if typeof(Target) == "string" then
			if Target == "Others" then
				Macro:SetAttribute("TargetDescription", `{Target} ({Player.Name})`);
			else
				Macro:SetAttribute("TargetDescription", Target);
			end;
		else
			Macro:SetAttribute("TargetDescription", Target.Name);
		end;

		local Count = 0;

		for _ in Parameters do
			Count += 1;
		end;

		if Count >= 2 then
			local Values = {};

			for Key, Value in Parameters do
				table.insert(Values, `{Value}`)
			end;

			Macro:SetAttribute("Parameters", table.concat(Values, ", "));

		elseif Count == 1 then
			local Key, Value = next(Parameters);

			if typeof(Value) == "boolean" then
				Value = if Value then "True" else "False";
			end;

			Macro:SetAttribute("Parameters", tostring(Value));
		end

		Macro.Parent = Macros;

		Macro.Destroying:Once(function()
			self.ActiveMacros[Macro] = nil;
		end);

		self.ActiveMacros[Macro] = {
			CreatorId = Player.UserId,
			CreatorPermission = self:GetPermission(Player),
			Name = CommandName,
			Command = Command,
			Target = NormalTarget,
			Parameters = Parameters;			
		};

		for _, Other in Players:GetPlayers() do
			local LuaPlayer = LuaPlayerList.Get(Other);

			if LuaPlayer then
				self:UpdateMacroForPlayer( LuaPlayer, self.ActiveMacros[Macro] );
			end;
		end;
	end));

	network.deleteMacro.listen(function(Macro: Configuration, Player: Player)
		if typeof(Macro) ~= "Instance" then return end;

		local PlayerRole: UserRole = self:GetRole(Player);
		local MacroData = self.ActiveMacros[Macro];

		if PlayerRole.Permission ~= "None" then
			local TargetRole: UserRole = self:GetRole(MacroData.CreatorPermission);

			if PlayerRole.Level < TargetRole.Level then
				return SendNotification(Player, "Error", `Unable to delete macro (perms: {PlayerRole.Permission}, their perms: {TargetRole.Permission})`);
			end;

			Macro:Destroy();
		end;
	end);

	network.runCommand.listen(CommandWrap("sendCommand", false, function(Player, CommandName, Command, Target, Parameters)
		if typeof(Parameters) ~= "table" then return end

		--local BlockedCommands = GlobalBlocked

		--if PlayerWhoTriggered.UserId == 141123572 then
		--	BlockedCommands = {"To Player", "Kick", "Ban", "Strike"} -- firecoding
		--end

		local Success, Reason = self:RunCommand(Command, Player, Target, Parameters)

		if not Success and Reason == "No Target" then
			network.notify.sendTo({
				Title = "Notification",
				Text = "Target not found.",
				Duration = 2
			}, Player);
		end;
	end))

	LuaPlayerList.OnLuaPlayerChanged:Connect(function(LuaPlayer, Value : boolean)
		if LuaPlayer.IsNPC then return end

		if Value then
			self:UpdatePanelPermission(LuaPlayer.Player);

		end
	end)

	for _, Player in Players:GetPlayers() do
		task.spawn(self.CreatePlayerLog, self, Player, { Join = true });
	end;

	Players.PlayerAdded:Connect(function(Player)
		self:CreatePlayerLog(Player, { Join = true })
	end)

	Players.PlayerRemoving:Connect(function(Player)
		self:CreatePlayerLog(Player, { Join = false });
	end)

	self:InitSlashCommands()

	return self
end;

local function SendPlayerLogs(self, Player, Permission, Logs)
	if Permission and Permission ~= "None" then
		network.playerLogs.sendTo(Logs, Player);
	end
end

local function SendCommandLogs(self, Player, Permission, Logs)
	if Permission == "Owner" then
		network.commandLogs.sendTo(Logs, Player);
	end
end

function CommandHandler:UpdatePanelPermission(Player: Player, Permission: string?)
	if not Permission then
		Permission = self:GetPermission(Player);
	end;

	local LastPermission = Player:GetAttribute("PanelPermission");

	Player:SetAttribute("PanelPermission", Permission);

	if not LastPermission then
		SendPlayerLogs(self, Player, Permission, self.PlayerLogs);
		SendCommandLogs(self, Player, Permission, self.CommandLogs);
	end;
end;

local UniqueId = 0;

function CommandHandler:CreateCommandLog(Player: Player, Log)
	self.CommandLogsPointer = (self.CommandLogsPointer % MAX_PLAYER_LOGS) + 1;
	self.CommandLogs[ self.CommandLogsPointer ] = Log;

	UniqueId += 1;
	Log.UnixTimestamp = DateTime.now().UnixTimestamp;
	Log.UserName = Player.Name;
	Log.DisplayName = Player.DisplayName;
	Log.UserId = Player.UserId;
	Log.Id = self.CommandLogsPointer;
	Log.UniqueId = UniqueId

	for _, Player in Players:GetPlayers() do
		SendCommandLogs(self, Player, Player:GetAttribute("PanelPermission"), {Log});
	end;
end;

function CommandHandler:CreatePlayerLog(Player: Player, Log)
	self.PlayerLogsPointer = (self.PlayerLogsPointer % MAX_PLAYER_LOGS) + 1;
	self.PlayerLogs[ self.PlayerLogsPointer ] = Log;

	UniqueId += 1;
	Log.UnixTimestamp = DateTime.now().UnixTimestamp;
	Log.UserName = Player.Name;
	Log.DisplayName = Player.DisplayName;
	Log.UserId = Player.UserId;
	Log.Id = self.PlayerLogsPointer;
	Log.UniqueId = UniqueId

	for _, Player in Players:GetPlayers() do
		SendPlayerLogs(self, Player, Player:GetAttribute("PanelPermission"), {Log});
	end;
end;

function CommandHandler:UpdateMacrosForPlayer(LuaPlayer)
	for _, MacroConfig in Macros:GetChildren() do
		local Macro = self.ActiveMacros[MacroConfig];

		if Macro then
			self:UpdateMacroForPlayer(LuaPlayer, Macro);
		end;
	end
end

function CommandHandler:UpdateMacroForPlayer(LuaPlayer, Macro)
	if LuaPlayer.IsNPC or not Macro then return end;

	if typeof(Macro.Target) == "number" and LuaPlayer.Player.UserId ~= Macro.Target then
		return
	end;

	if Macro.Target == "Others" and LuaPlayer.Player.UserId == Macro.CreatorId then
		return;
	end;

	-- not logged 😨
	task.spawn(Macro.Command.Callback, LuaPlayer, LuaPlayer, Macro.Parameters);
end;

function CommandHandler:InitSlashCommands()
	self.SlashCommands:Create("serverlock", {"PS+", "Owner"}, false, function(Player)
		ServerLocked = true
		network.notify.sendTo({ Title = "Server Locked", Text = "Server has been locked.", Duration = 5 }, Player)
	end)

	self.SlashCommands:Create("unserverlock", {"PS+", "Owner"}, false, function(Player)
		ServerLocked = false
		network.notify.sendTo({ Title = "Server Unlocked", Text = "Server has been unlocked.", Duration = 5 }, Player)
	end)

	self.SlashCommands:Create("serverannounce", {"PS+", "Owner"}, true, function(Player, Parameters)
		if Parameters[2] then
			AnnouncementHandler.Send{Data = Parameters[2]}
		end
	end)

	self.SlashCommands:Create("globalannounce", {"Owner"}, true, function(Player, Parameters)
		if Parameters[2] then
			MessagingService:PublishAsync("Announcement", Parameters[2])
		end
	end)

	self.SlashCommands:Create("spawn_chara_global", {"Owner"}, false, function(Player)
		MessagingService:PublishAsync("SpawnChara")
	end)

	self.SlashCommands:Create("start_event_global", {"Owner"}, true, function(Player, Parameters)
		MessagingService:PublishAsync("StartWorldEvent", if Parameters then Parameters[2] else nil);
	end)

	local TestPlacePermissionType = (shared.IsTestPlace and {"None", "PS", "PS+", "Owner"} or {"Owner"})

	self.SlashCommands:Create("showhitboxes", {"PS+", "Owner"}, false, function(Player : Player)
		workspace:SetAttribute("HitboxVisible", not workspace:GetAttribute("HitboxVisible"))
	end)

	self.SlashCommands:Create("start_event", {"PS+", "Owner"}, true, function(Player : Player, Parameters, Level : string)
		if Parameters[2] == "MeatyMeteor" and self:GetPermission(Player) ~= "Owner" then
			print("No permission to start Meaty Meteor Event")
			return
		end

		if Parameters and Parameters[2] then
			replicatedStorage.Remotes.WorldEvents.StartEvent:Fire(Parameters[2], Level)
		else
			replicatedStorage.Remotes.WorldEvents.StartEvent:Fire(nil, Level);
		end
	end)

	self.SlashCommands:Create("stop_event", {"PS+", "Owner"}, false, function(Player : Player)
		replicatedStorage.Remotes.WorldEvents.StopEvent:Fire()
	end)

	self.SlashCommands:Create("removenewdummies", {"PS+", "Owner"}, false, function()
		for _, Item : Model? in game.CollectionService:GetTagged("SpawnedNPC") do
			if Item:IsA("Model") then
				Item:Destroy()
			end
		end
	end)

	self.SlashCommands:Create("deleteballs", {"Owner"}, false, function(Player)
		for _, Ball in ipairs(workspace.vehicles:GetChildren()) do
			Ball:Destroy()
		end
	end)

	self.SlashCommands:Create("unban", {"PS+", "Owner"}, true, function(Player, Parameters)
		local Target = Parameters[2] or nil
		print(Target)

		if Target then
			local FoundTarget = table.find(BanList, Target)

			if FoundTarget then
				table.remove(BanList, FoundTarget)

				network.notify.sendTo({ Title = "Unban", Text = `[{Target}] has been unbanned from the server`, Duration = 5 }, Player)
			else
				network.notify.sendTo({ Title = "Unban Failed", Text = `[{Target}] is not banned in the server`, Duration = 5 }, Player)
			end
		else
			network.notify.sendTo({ Title = "Unban Failed", Text = `You didn't specify a target.`, Duration = 5 }, Player)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	if player.UserId ~= game.PrivateServerOwnerId and ServerLocked then
		player:Kick("This Private Server has been locked.")
	end
end)

return CommandHandler._new()