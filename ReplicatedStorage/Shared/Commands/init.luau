-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Modules
local Moves = {};

local Assets = script.Assets;
local DummyHandlers = script.DummyHandlers;

local BanList = require( script.PrivateServerBanList )

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Shared.Utilities.Job )

local Weather
local LuaPlayerList

if RunService:IsServer() then
	local ServerScriptService = game:GetService("ServerScriptService")

	Weather = require(ServerScriptService.Modules.Weather)
	LuaPlayerList = require(ServerScriptService.Modules.LuaPlayerList)

	-- On Click Strike
	ReplicatedStorage.Remotes.Commands.ClickStrike.OnServerEvent:Connect(function(Player, MousePosition)
		if Player:GetAttribute("ClickStrike") == true then
			if Weather then
				Weather.Smite(MousePosition)
			end
		end
	end)

	-- Fetch Moves
	local CharacterList = ServerScriptService.Modules.Player.Character.Combat.Attacks.List

	for _, Character in pairs(CharacterList:GetChildren()) do
		if Character:IsA("Configuration") then
			for _, Move in pairs(Character:GetChildren()) do
				if Move:IsA("ModuleScript") then
					table.insert(Moves, Move.Name)
				end
			end
		end
	end

	-- On Player Join
	Players.PlayerAdded:Connect(function(Player)
		-- Check if banned
		if table.find(BanList, Player.Name) then
			Player:Kick("Banned from this server")
		end
	end)
end

-- Local Functions
function SendNotification(Player : Player, NotificationTitle : string, NotificationText : string, NotificationIcon : number)
	if not NotificationIcon then
		NotificationIcon = 112856803225144
	end

	local IconString = `rbxassetid://{NotificationIcon}`

	ReplicatedStorage.Remotes.Notification:FireClient(Player, {
		Title = NotificationTitle, 
		Text = NotificationText, 
		Icon = IconString
	})
end

function ParametersValid(ReceivedParameters : any, Player : Player)
	-- Check if all required parameters are received
	for Parameter, Value in pairs(ReceivedParameters) do
		if not Value or Value == "" then
			SendNotification(Player, "Missing Parameter", `You did not specify: {Parameter}`, nil)
			return false
		end
	end
	return true
end

function GetValueFromPartialString(PartialString : string, Array : any, UseStringFind : boolean)
	for _, Value in pairs(Array) do
		local CheckingValue = Value
		if Value["Name"] then
			CheckingValue = Value["Name"]
		end

		if UseStringFind then
			if string.find(string.lower(CheckingValue), string.lower(PartialString)) then
				return Value
			end
		else
			if string.lower(CheckingValue):sub(1, #PartialString) == string.lower(PartialString) then
				return Value
			end
		end
	end
end

local DummyDisplays = {}

local Commands = {
	["Give Ultimate"] = {
		Index = -4,

		Parameters = {"Player"},
		--TriggerLevel = 3,

		Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			local Ultimate = TargetLuaPlayer.Character.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

			if Ultimate then
				Ultimate:SetValue(100)
			end
		end
	},

	["Set Cooldowns"] = {
		Parameters = {"Player", "Value"}, 
		--TriggerLevel = 3,
		Index = -3, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			TargetLuaPlayer.Character.Combat.CooldownsEnabled = (ReceivedParameters.Value)

			for _, Attack in TargetLuaPlayer.Character.Combat.Attacks do
				Attack:RemoveCooldown()
			end
		end},

	["Set Client Cooldowns"] = {
		Parameters = {"Player", "Value"}, 
		Index = -2.9, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			TargetLuaPlayer.Replication.Attributes:SetAttribute("DisabledClientCooldowns", not ReceivedParameters.Value)
		end},

	["Toggle Combat"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Owner"},
		Parameters = {"Player", "Value"},
		Index = -2, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			TargetLuaPlayer.Character.Combat.Actions:SetEnabled(ReceivedParameters.Value or false)
		end},

	["Toggle Respawning"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Owner"},
		Parameters = {"Player", "Value"}, Index = -1, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			TargetLuaPlayer.Character.RespawningEnabled = ReceivedParameters.Value or false
		end},

	["Moveset"] = {
		Parameters = {"Player", "Move"},
		PermissionsToTrigger = {"Owner"};

		Callback = function(LuaPlayer, TargetLuaPlayer, Parameters)
			if not ParametersValid(Parameters, LuaPlayer.Player) then return end

			for name, attack in TargetLuaPlayer.Character.Combat.Attacks do
				if attack.DirectoryParent == "Global" then
					continue;
				end;

				TargetLuaPlayer.Character.Combat:RemoveAttack(name);
			end;

			for _, name in string.split(Parameters.Move, ",") do
				local skill_name = string.gsub(string.gsub(name, "^%s*", ""), "%s*$", "");

				local success, result = pcall(function()
					local keybind = TargetLuaPlayer.Character.Combat:GetNextAttackKey();
					local found_move = GetValueFromPartialString(Parameters.Move, Moves);

					if found_move then
						TargetLuaPlayer.Character.Combat:CreateAttack(found_move, keybind)
					end;
				end);

				if not success then
					warn(`Unable to give move: {result}`);
				end;
			end;
		end,
	};

	["Give Attack"] = {
		Index = 0,

		Parameters = {"Player", "Move", "Keybind"}, 
		--TriggerLevel = 1,
		PermissionsToTrigger = {"Owner", "GOB"},

		Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			if not ParametersValid(ReceivedParameters, LuaPlayer.Player) then return end

			local AllowedKeys = {1, 2, 3, 4, 5, 6, 7, 8, 9}
			local Keybind = ReceivedParameters.Keybind

			if Keybind == "" then
				Keybind = TargetLuaPlayer.Character.Combat:GetNextAttackKey().Name;
			end;

			if string.len(Keybind) > 1 then
				return SendNotification(LuaPlayer.Player, "Invalid Keybind", `Keybind {Keybind} can't be more than one character.`);
			end;

			local IsNumber = table.find(AllowedKeys, tonumber(Keybind))

			if Keybind:match("[^a-zA-Z]+") and not (IsNumber or Enum.KeyCode:FromName(Keybind)) then
				return SendNotification(LuaPlayer.Player, "Invalid Keybind", `{Keybind} is not a valid keybind.`);
			end

			local FoundMove = GetValueFromPartialString(ReceivedParameters.Move, Moves)

			if FoundMove then
				if IsNumber then
					Keybind = Enum.KeyCode:FromValue(48 + tonumber(Keybind))
				else
					Keybind = Enum.KeyCode:FromName(Keybind);
				end;

				TargetLuaPlayer.Character.Combat:CreateAttack(FoundMove, Keybind)
			else
				print("Error, move not found")
			end;
		end;
	},

	["Give Item"] = {
		Index = 0,

		Parameters = {"Player", "Item"}, 
		--TriggerLevel = 1,
		PermissionsToTrigger = {"Owner", "GOB", "PS+"},

		Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			if not ParametersValid(ReceivedParameters, LuaPlayer.Player) then return end

			TargetLuaPlayer.Character.Items:Give(ReceivedParameters.Item)
		end
	},

	["Give Random Emote"] = {
		Index = 1,

		Parameters = {"Player"},
		--TriggerLevel = 1,
		PermissionsToTrigger = {"Owner"},
		CanMacro = false;
		Callback = function(LuaPlayer, TargetLuaPlayer)
			TargetLuaPlayer.Character.Emotes:GetRandom("Give")
		end
	},

	["Give Emote"] = {
		Index = 1,

		Parameters = {"Player", "EmoteName"}, 
		--TriggerLevel = 1,
		PermissionsToTrigger = {"Owner"},
		CanMacro = false;

		Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			TargetLuaPlayer.Character.Emotes:Give(ReceivedParameters.EmoteName)
		end
	},

	["Infinite Ultimate"] = {
		Index = 4,
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Developer", "GOB", "Owner"},

		Parameters = {"Player", "Value"},

		Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			local Ultimate = TargetLuaPlayer.Character.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

			if Ultimate then
				Ultimate:SetBarPausing(ReceivedParameters.Value)

				if ReceivedParameters.Value then
					Ultimate:SetValue(100)
				end
			end
		end
	},

	["Instant Ultimate"] = {
		Index = 4,
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Developer", "GOB", "Owner"},

		Parameters = {"Player", "Value"},

		Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			local Ultimate = TargetLuaPlayer.Character.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

			if Ultimate then
				Ultimate.SkipIntro = ReceivedParameters.Value
			end
		end
	},

	["Set Character"] = {
		Index = 5,

		Parameters = {"Player", "CharacterName"}, 
		--TriggerLevel = 1,
		PermissionsToTrigger = {"GOB", "Owner"},

		Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			local Success = TargetLuaPlayer.Character.Combat:SetCharacter(ReceivedParameters.CharacterName)

			if not Success then
				SendNotification(TargetLuaPlayer.Player, "Invalid Character", `{ReceivedParameters.CharacterName} is not a valid character.`)
			end
		end
	},

	["Disguise"] = {
		--TriggerLevel = 1,
		PermissionsToTrigger = {"Owner"},
		Parameters = {"Player", "String"}, 
		CanMacro = false;

		Index = 7, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			if ReceivedParameters.String == nil or ReceivedParameters.String == "" then
				if (TargetLuaPlayer.Data and TargetLuaPlayer.Data.Profile) then
					TargetLuaPlayer.Data.Profile.Data.CurrentDisguise = nil
				else
					warn("disguise couldn't save for some reason, using luacharacter disguise id")
					TargetLuaPlayer.Character.DisguiseId = nil
				end

				TargetLuaPlayer.Character:ApplyDescriptionToSelf()
			else
				if not tonumber(ReceivedParameters.String) then
					local Success, Result = pcall(function()
						return Players:GetUserIdFromNameAsync(ReceivedParameters.String)
					end)

					if Success and Result then
						if (TargetLuaPlayer.Data and TargetLuaPlayer.Data.Profile) then
							TargetLuaPlayer.Data.Profile.Data.CurrentDisguise = Result
						else
							warn("disguise couldn't save for some reason, using luacharacter disguise id")
							TargetLuaPlayer.Character.DisguiseId = Result
						end
					else
						warn(Result)
					end

					TargetLuaPlayer.Character:ApplyDescriptionToSelf()
				end
			end
		end},

	["Damage Multiplier"] = {
		--TriggerLevel = 1,
		PermissionsToTrigger = {"PS+", "GOB", "Owner"},
		Parameters = {"Player", "String"}, 
		Index = 7.01, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			local Number = tonumber(ReceivedParameters.String)

			if (Number ~= nil) then
				TargetLuaPlayer.Character.Combat.DamageMultiplier = math.max(0, Number)
			end
		end},

	["Attack Speed Multiplier"] = {
		--TriggerLevel = 1,
		PermissionsToTrigger = {"PS+", "GOB", "Owner"},
		Parameters = {"Player", "String"}, 
		Index = 7.02, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			local Number = tonumber(ReceivedParameters.String)

			if (Number ~= nil) then
				TargetLuaPlayer.Character.Combat:SetSpeedMultiplier( math.max(0, Number) );
			end
		end},

	["Heal"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Developer", "GOB", "Owner"},
		Parameters = {"Player"}, 
		Index = 7.1, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			TargetLuaPlayer.Character:HealFull()
		end},

	["Set Health"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Developer", "GOB", "Owner"},
		Parameters = {"Player", "String"}, 
		Index = 7.2, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			local NewValue = 100
			local Number = tonumber(ReceivedParameters.String)

			if (Number ~= nil) then
				NewValue = Number
			else
				if ReceivedParameters.String == "inf" then
					NewValue = math.huge
				end
			end

			TargetLuaPlayer.Character.Humanoid.MaxHealth = NewValue
			TargetLuaPlayer.Character:HealFull()
		end},

	["God"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Developer", "GOB", "Owner"},
		Parameters = {"Player"}, 
		Index = 8, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			TargetLuaPlayer.Character.Combat:StackState("HitboxImmunity", true)
		end},

	["Ungod"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Developer", "GOB", "Owner"},
		Parameters = {"Player"}, 
		Index = 9, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			TargetLuaPlayer.Character.Combat:StackState("HitboxImmunity", false)
		end},

	["Strike"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Owner", "GOB"},
		Parameters = {"Player"},
		Index = 12, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			if Weather then
				Weather.Smite(TargetLuaPlayer.Character.RootPart.Position)
			end
		end},

	["Dummy Display"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Developer", "GOB", "Owner"},
		Parameters = {"Player", "Value"},
		Index = 13, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			local TargetLuaCharacter = TargetLuaPlayer.Character

			if (ReceivedParameters.Value == true) then
				local Health = Assets.Health:Clone()
				Health.Parent = TargetLuaCharacter.Head

				local NewJob = Job.new()

				Health.Destroying:Once(function()
					NewJob:Destroy()
				end)

				local function UpdateHealth(NewHealth : number)
					if (Health ~= nil and Health.Parent ~= nil) then
						Health.Label.Text = Utility.DecimalRound(NewHealth <= 0.01 and 0 or NewHealth, 3) .. "%"
					end
				end

				UpdateHealth(TargetLuaCharacter.Humanoid.Health)

				NewJob:Task(TargetLuaCharacter.Combat:GetStateChanged("Stunned"):Connect(function(Value : boolean)
					if (Health ~= nil and Health.Parent ~= nil) then
						Health.Label.TextColor3 = Value and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
					end
				end))

				NewJob:Task(TargetLuaCharacter.Humanoid.HealthChanged:Connect(UpdateHealth))

				DummyDisplays[TargetLuaCharacter.Head] = Health
			else
				if DummyDisplays[TargetLuaCharacter.Head] then
					DummyDisplays[TargetLuaCharacter.Head]:Destroy()
					DummyDisplays[TargetLuaCharacter.Head] = nil
				end
			end

		end},

	["Flight"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Developer", "GOB", "Owner"},
		Parameters = {"Player", "Value"},
		Index = 13.1, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			TargetLuaPlayer.Player:SetAttribute("HasFlight", ReceivedParameters.Value)
		end},


	["Bring"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Developer", "GOB", "Owner", "Staff"},
		Parameters = {"Player"},
		Index = 13.2, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			TargetLuaPlayer.Character.Model:PivotTo(LuaPlayer.Character.RootPart.CFrame * CFrame.new(0, 0, -3))
		end},

	["To"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Developer", "GOB", "Owner", "Staff"},
		Parameters = {"Player"},
		IgnoreSelfRestriction = true,
		--UnrestrictedTarget = true,

		Index = 14, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			LuaPlayer.Character.Model:PivotTo(TargetLuaPlayer.Character.RootPart.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))
		end},

	["Respawn"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Developer", "GOB", "Owner", "Staff"},
		Parameters = {"Player"},
		CanMacro = false;
		Index = 15, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			TargetLuaPlayer.Character:Respawn()
			ReplicatedStorage.Remotes.Commands.Respawn:FireClient(TargetLuaPlayer.Player)
		end},

	["Spawn Dummy"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Owner"},
		Parameters = {"Player", "Dummy Type"},
		CanMacro = false;

		Index = 16, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			local Dummy = Assets.Dummy:Clone()
			Dummy:PivotTo(TargetLuaPlayer.Character.RootPart.CFrame * CFrame.new(0, 1, -5))
			Dummy.Parent = workspace

			local Type = ReceivedParameters["Dummy Type"]

			if Type == "Low HP Dummy" then
				Dummy.Humanoid.Health = 10
			else
				local Handlr = DummyHandlers:FindFirstChild(Type)

				if Handlr then
					local Handler = Handlr:Clone()
					Handler.Name = "NpcHandler"
					Handler.Parent = Dummy
				end
			end

			task.wait(1 / 60)

			Dummy:AddTag("Random_Developer_Outfit")
			Dummy:AddTag("NPC")
			Dummy:AddTag("SpawnedNPC")
		end},

	["Spawn Ball"] = {
		--TriggerLevel = 1,
		PermissionsToTrigger = {"Owner"},
		Parameters = {"Player"},
		CanMacro = false;

		Index = 18, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			local ball = Assets.Ball:Clone()
			ball:PivotTo(TargetLuaPlayer.Character.RootPart.CFrame * CFrame.new(0, 10, -10))
			ball.Parent = workspace.vehicles

			task.wait(2 / 60)

			ball.Scripts.Client.ClientController.Enabled = true
			ball.Scripts.Server.Occupant.Enabled = true
		end},

	["Click Strike"] = {
		--TriggerLevel = 1,
		PermissionsToTrigger = {"Owner", "GOB"},
		Parameters = {"Player", "Value"},
		Index = 19, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			TargetLuaPlayer.Player:SetAttribute("ClickStrike", ReceivedParameters.Value)
		end},

	["Kick"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Developer", "GOB", "Owner", "Staff"},
		Parameters = {"Player", "Confirm"},
		CanMacro = false;

		Index = 20, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			if (ReceivedParameters.Confirm == true) then
				if LuaPlayer.Player == TargetLuaPlayer.Player then return end

				TargetLuaPlayer.Player:Kick(`You have been kicked by {LuaPlayer.Player:GetAttribute("Name")}`)
			end
		end},

	["Server Ban"] = {
		--TriggerLevel = 2,
		PermissionsToTrigger = {"PS+", "Developer", "GOB", "Owner", "Staff"},
		Parameters = {"Player"},
		CanMacro = false;

		Index = 21, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			if LuaPlayer.Player == TargetLuaPlayer.Player then return end

			table.insert(BanList, TargetLuaPlayer.Player.Name)
			TargetLuaPlayer.Player:Kick(`You have been banned from this server by {LuaPlayer.Player:GetAttribute("Name")}`)
		end},

	["Jimper"] = {
		--TriggerLevel = 1,
		PermissionsToTrigger = {"Owner", "GOB"},
		Parameters = {"Player"},

		Index = 22, Callback = function(LuaPlayer, TargetLuaPlayer, ReceivedParameters)
			local ui = Assets.Jimper.ui:Clone()
			ui.Parent = TargetLuaPlayer.Player.PlayerGui

			for _, item in ipairs(ui:GetChildren()) do
				if item:IsA("Sound") then
					item:Play()
				end
			end

			task.wait(3)

			ui:Destroy()
		end},
}

for Name, Command in Commands do
	Command.Name = Name; -- For Convienence

	if Command.PermissionsToTrigger == nil then
		Command.PermissionsToTrigger = {"PS", "PS+", "Developer", "GOB", "Owner"};
	end;

	if Command.CanMacro == nil then
		Command.CanMacro = true;
	end;
end;

return Commands