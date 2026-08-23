local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")
----------------------------------------------------------------------------------

local Remotes = ReplicatedStorage.Remotes

local UIRemotes = Remotes.Combat.UI

local Job = require( ReplicatedStorage.modules.shared.Utilities.Job )
local EventService = require( ReplicatedStorage.modules.shared.Utilities.EventService )
local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )

local EmoteData = require( ServerStorage.modules.Player.Character.Emotes.Data )
local LeaderboardHandler = require( ServerStorage.modules.LeaderboardHandler )

local Settings = require(script.Settings)

local Gamepasses = require( ReplicatedStorage.modules.shared.Game.Gamepasses )
local GroupRankGamepasses = require( ReplicatedStorage.modules.shared.Game.Gamepasses.GroupRankGamepasses )

local GiftsProcessingStore = DataStoreService:GetDataStore("gifts-processing")

----------------------------------------------------------------------------------

local ProfileStore = require( ServerStorage.modules.Utility.ProfileStore )

local Data = {}
Data.__index = Data

local Template = {
	TimesJoined = 0,
	PromptedBloodWarning = false,

	PlayTime = 0,
	ConvertedPlayTime = "",

	GotFreeEmoteForJoining = false,

	CurrentTitle = "",

	Emotes = {},
	BoughtEmotes = {},

	CurrentEmoteSlots = {},
	ClaimedEmotes = 0,
	ExtraEmoteClaims = 0,

	OwnedGamepasses = {},

	Settings = {},

	CustomSkills = {
		Info = {
			SlotAmount = 128,
			Slots = {}; -- Holds information on custom skills
		};
		DataSlots = {}; -- Holds custom skill data
	};

	Builds = {
		Preferences = {};
		Purchases = {};
		Gamepass = {};
		Permissions = {
			ImportExport = false
		};
		SlotAmount = 5;
		Slots = {};
	};

	Hosting = {
		Banned = false;
		MyServers = {
			Validated = {
				Time = -1;
				Pending = false;
			};
			List = {};
		};
	};

	Bosses = {
		Chara = {
			Awarded = false,
			AwardPityCount = 0,
			Killed = 0,
			PreviousPlace = 0,
		}
	},

	CurrentDisguise = nil,

	--DeviceKeybinds = {
	--	Controller = {},
	--	Keyboard = {}
	--},

	MobileButtonPositions = nil,

	Credits = 0,
	Kills = 0,
	Elo = 0,

	CurrentCharacter = "Gojo"
}

local PlayerStore = ProfileStore.New("PlayerStore", Template)
shared.PlayerStore = PlayerStore

local function ConvertTimePlayed(Minutes : string)
	local Days = math.floor(Minutes / 1440)
	Minutes = Minutes % 1440

	local Hours = math.floor(Minutes / 60)
	Minutes = Minutes % 60

	return string.format("%d:%d:%d", Days, Hours, Minutes)
end

----------------------------------------------------------------------------------

function Data:Destroy()
	self.Job:Destroy()

	if (self.Profile ~= nil) then

		local PlayTimeInServer = (time() - self.JoinTime)

		self.Profile.Data.PlayTime += PlayTimeInServer
		self.Profile.Data.ConvertedPlayTime = ConvertTimePlayed( math.floor(self.Profile.Data.PlayTime / 60) )

		self.Profile:EndSession()
		self.Profile = nil
	end
end

function Data:_Init()
	local Player = self.LuaPlayer.Player

	local Profile = PlayerStore:StartSessionAsync(`{Player.UserId}`, {
		Cancel = function()
			return Player.Parent ~= Players
		end,
	})

	if (Profile ~= nil) then

		Profile:AddUserId(Player.UserId)
		Profile:Reconcile()

		Profile.OnSessionEnd:Connect(function()
			self.Profile = nil
			Player:Kick("Profile session end - Please rejoin")
		end)

		if (Player.Parent == Players) then
			self.Profile = Profile
			self:DataLoaded()
		else
			Profile:EndSession()
		end

	else
		Player:Kick("Profile load fail - Please rejoin")
	end
end

function Data:DataLoaded()
	--if self.LuaPlayer.Player.Name == "swrerm" then
	--	table.clear(self.Profile.Data.Emotes)
	--	table.clear(self.Profile.Data.BoughtEmotes)
	--	table.clear(self.Profile.Data.CurrentEmoteSlots)
	--	self.Profile.Data.ClaimedEmotes = 0
	--	self.Profile.Data.Kills = 500

	--	self.Profile.Data.Bosses.Chara = {
	--		Awarded = false,
	--		AwardPityCount = 0,
	--		Killed = 0,
	--		PreviousPlace = 0,
	--	}
	--end

	self.Profile:MessageHandler(function(Message : {}, Processed : () -> ())
		print("Received Message")

		if Message.Type then
			if Message.Type == "GamepassGift" and Message.GamepassName then
				self.Profile.Data.OwnedGamepasses[Message.GamepassName] = true

				ReplicatedStorage.Remotes.Announcement:FireClient(self.LuaPlayer.Player, 
					`You have been gifted {Message.GamepassName} by another user.`
				)

				task.spawn(function()
					local Success, Result = pcall(function()
						return GiftsProcessingStore:GetAsync(tostring(self.LuaPlayer.Player.UserId))
					end)

					if Success and Result then
						local Index = table.find(Result, Message.GamepassName)

						if Index then
							table.remove(Result, Index)
						end

						local SetAsyncSuccess, SetAsyncError

						if #Result == 0 then
							SetAsyncSuccess, SetAsyncError = pcall(function()
								GiftsProcessingStore:RemoveAsync(tostring(self.LuaPlayer.Player.UserId))
							end)
						else
							SetAsyncSuccess, SetAsyncError = pcall(function()
								GiftsProcessingStore:SetAsync(tostring(self.LuaPlayer.Player.UserId), Result)
							end)
						end

						if not SetAsyncSuccess then
							warn(`Error removing {self.LuaPlayer.Player.Name}'s gamepass data, Error: {SetAsyncError}`)
						end
					else
						warn(`Error getting {self.LuaPlayer.Player.Name}'s gamepass data, Error: {Result}`)
					end
				end)

				Processed()
			end

		else
			Processed()
		end
	end)

	--elseif Message.Type == "EmotesGift" and Message.AmountOfEmotes then -- emote gifting (idk if it works)
	--	local function IsSafeToGiveEmote()
	--		return (Message.AmountOfEmotes < Utility.TableCount(self.Profile.Data.Emotes))
	--	end

	--	if IsSafeToGiveEmote() then -- if they can actually claim
	--		local WasSafe = false

	--		for Index = 1, Message.AmountOfEmotes do
	--			WasSafe = IsSafeToGiveEmote()

	--			if not WasSafe then
	--				break
	--			end

	--			self.LuaCharacter.Emotes:GetRandom("Purchase")
	--		end

	--		if WasSafe then
	--			Processed()
	--		end
	--	end

	if self.Profile:IsActive() then
		for Slot, Name in self.Profile.Data.CurrentEmoteSlots do
			if typeof(Slot) == "number" then
				self.Profile.Data.CurrentEmoteSlots[Slot] = nil
				self.Profile.Data.CurrentEmoteSlots[tostring(Slot)] = Name
			end
		end

		for Emote in self.Profile.Data.Emotes do
			if not EmoteData[Emote] then -- if i delete an emote from the game
				self.Profile.Data.Emotes[Emote] = nil

				if self.Profile.Data.BoughtEmotes[Emote] then
					self.Profile.Data.BoughtEmotes[Emote] = nil
				else
					self.Profile.Data.ClaimedEmotes -= 1
				end
			end
		end
	end

	self.Profile.Data.ExtraEmoteClaims = math.clamp(self.Profile.Data.ExtraEmoteClaims, 0, 5)

	if self.Profile:IsActive() then
		self.Profile.Data.TimesJoined += 1

		if not self.Profile.Data.PromptedBloodWarning and not self.Profile.Data.Settings.Blood then
			self.Profile.Data.PromptedBloodWarning = true
			ReplicatedStorage.PlayerRemotes.PromptBloodWarning:FireClient(self.LuaPlayer.Player)
		end
	end

	self.LeaderStats = Instance.new("Folder")
	self.LeaderStats.Name = "leaderstats"
	self.LeaderStats.Parent = self.LuaPlayer.Player

	self.KillStat = Instance.new("NumberValue")
	self.KillStat.Name = "Total Kills"
	self.KillStat.Value = self.Profile.Data.Kills
	self.KillStat.Parent = self.LeaderStats

	self.ELOStat = Instance.new('NumberValue')
	self.ELOStat.Name = "ELO"
	self.ELOStat.Value = self.Profile.Data.Elo

	if shared.IsRankedLobby or shared.IsRankedPlace then
		self.ELOStat.Parent = self.LeaderStats
	else
		self.ELOStat.Parent = self.LuaPlayer.Player
	end 

	self.JoinTime = time()

	task.spawn(self.InitSettings, self)
	task.spawn(self.InitMobileUI, self)

	self.OnDataLoaded:Fire()
end

function Data:InitMobileUI()
	Remotes.SaveMobileUIPosition:FireClient(self.LuaPlayer.Player, self.Profile.Data.MobileButtonPositions)

	self.Job:Task(Remotes.SaveMobileUIPosition.OnServerEvent:Connect(function(Player, Positions : {[string]: {x : number, y : number}})
		if Player ~= self.LuaPlayer.Player or typeof(Positions) ~= "table" then 
			return 
		end

		local Success = true

		for Name, Table in Positions do
			if typeof(Name) ~= "string" or Table.x == nil or Table.y == nil or typeof(Table.x) ~= "number" or typeof(Table.y) ~= "number" then
				Success = false
				break
			end
		end

		if Success then
			self.Profile.Data.MobileButtonPositions = Positions
		end
	end))
end

function Data:InitSettings()
	for Setting : string, StartingValue : boolean in Settings do
		Setting = Setting:gsub(" ", "_")

		if (self.Profile.Data.Settings[Setting] == nil) then
			self.Profile.Data.Settings[Setting] = StartingValue
		end

		self.LuaPlayer.Player:SetAttribute(Setting, self.Profile.Data.Settings[Setting])
	end

	Remotes.LoadSettings:FireClient(self.LuaPlayer.Player, self.Profile.Data.Settings)--, self.Profile.Data.DeviceKeybinds)

	self.Job:Task(Remotes.Settings.Toggle.OnServerEvent:Connect(function(Player, Setting : string)
		if Player ~= self.LuaPlayer.Player or typeof(Setting) ~= "string" then 
			return 
		end

		Setting = Setting:gsub(" ", "_")

		if (Settings[Setting] ~= nil) then
			local Value = not Player:GetAttribute(Setting)
			Player:SetAttribute(Setting, Value)
			self.Profile.Data.Settings[Setting] = Value
		end
	end))

	self.Job:Task(Remotes.Settings.Percentage.OnServerEvent:Connect(function(Player, Setting : string, Percentage : any)
		if Player ~= self.LuaPlayer.Player or typeof(Setting) ~= "string" or typeof(Percentage) ~= "number" then 
			return 
		end

		Setting = Setting:gsub(" ", "_")

		if (Settings[Setting] ~= nil) then
			local Value = math.clamp(Percentage or 0, 0, 200)
			Player:SetAttribute(Setting, Value)
			self.Profile.Data.Settings[Setting] = Value
		end
	end))

	--self.Job:Task(Remotes.Settings.Keybind.OnServerEvent:Connect(function(Player, Move : string, Key : (Enum.KeyCode | Enum.UserInputType), Device : string)
	--	if Player ~= self.LuaPlayer.Player or typeof(Move) ~= "string" or typeof(Device) ~= "string" or typeof(Key) ~= "EnumItem" then 
	--		return
	--	end

	--	if self.Profile.Data.DeviceKeybinds[Device] then
	--		self.Profile.Data.DeviceKeybinds[Device][Move] = Key.Name
	--		print("updated device Keybinds:", self.Profile.Data.DeviceKeybinds)
	--	end

	--	if  self.LuaPlayer.Character.Combat.Attacks[Move] then
	--		Remotes.Combat.ChangeAttackKey:FireClient(self.LuaPlayer.Player, Move, Key)
	--	end
	--end))

	self.Job:Task(Remotes.Settings.String.OnServerEvent:Connect(function(Player, Setting : string, String : any)
		if Player ~= self.LuaPlayer.Player or typeof(Setting) ~= "string" or typeof(String) ~= "string"  then
			return 
		end

		task.spawn(function()
			if Setting == "Kill Sound" then
				if not self:HasGamepass("Kill Sounds") then
					MarketplaceService:PromptGamePassPurchase(self.LuaPlayer.Player, 1039898973)

					return
				end

				if not tonumber(String) then
					return
				end
			end

			Setting = Setting:gsub(" ", "_")

			if (Settings[Setting] ~= nil) then
				Player:SetAttribute(Setting, String)
				self.Profile.Data.Settings[Setting] = String
			end
		end)
	end))
end

function Data:AddKill(KilledPlayer : Player, Type : string, ...) -- Attacked, Left
	if (self.Profile == nil or not self.Profile:IsActive()) then return end

	self.Profile.Data.Kills += 1
	self.KillStat.Value = self.Profile.Data.Kills

	task.spawn(LeaderboardHandler.UpdateLeaderboard, self.LuaPlayer.Player, "Kills", self.Profile.Data.Kills)

	self.LuaPlayer.Character.Emotes:UpdateEmoteKillClaim()

	if KilledPlayer and Type then
		Remotes.Combat.PlayerKilled:FireClient(self.LuaPlayer.Player, KilledPlayer, self.Profile.Data.Kills, Type, ...)
	end
end

function Data:SetKills(Value : number)
	if (self.Profile == nil or not self.Profile:IsActive()) then return end

	self.Profile.Data.Kills = Value
	self.KillStat.Value = self.Profile.Data.Kills

	task.spawn(LeaderboardHandler.UpdateLeaderboard, self.LuaPlayer.Player, "Kills", self.Profile.Data.Kills)

	self.LuaPlayer.Character.Emotes:UpdateEmoteKillClaim()
end

function Data:CalculateEloChange(WinnerRating, LoserRating)
	local KFactor = 32

	local ExpectedWinnerScore = 1 / (1 + 10 ^ ((LoserRating - WinnerRating) / 400))
	local EloChange = KFactor * (1 - ExpectedWinnerScore)

	return math.round(EloChange)
end

function Data:SetElo(Value)
	if not self.Profile or not self.Profile:IsActive() then return end
	local NewElo = math.max(Value, 0)

	self.Profile.Data.Elo = NewElo

	if self.ELOStat then
		self.ELOStat.Value = NewElo
	end
end

function Data:AddElo(Increment)
	if not self.Profile or not self.Profile:IsActive() then return end

	local CurrentElo = self.Profile.Data.Elo or 0
	local NewElo = math.max(CurrentElo + Increment, 0)

	self.Profile.Data.Elo = NewElo

	if self.ELOStat then
		self.ELOStat.Value = NewElo
	end
end

function Data:Wipe()
	if (self.Profile == nil or not self.Profile:IsActive()) then return end

	self.Profile:EndSession()
	PlayerStore:RemoveAsync(`{self.LuaPlayer.Player.UserId}`)
	self.LuaPlayer.Player:Kick("Data wiped")
end

function Data:HasGamepass(Name : string, Gifting : bolean?)
	local GamepassData = Gamepasses[Name]

	if (GamepassData == nil) then 
		return warn(Name, "is not a valid gamepass, did you name it incorrectly?")
	end

	local GroupRank = self.LuaPlayer.GroupRank

	if (not Gifting and GroupRank ~= nil) then
		local RankGamepasses = GroupRankGamepasses[GroupRank]

		if RankGamepasses then
			if table.find(RankGamepasses, Name) then
				return true
			end
		end
	end

	if (self.Profile == nil or not self.Profile:IsActive()) then
		warn("data for", self.LuaPlayer.Player.Name, "didn't exist, so just returned true for safety")
		return true
	end

	if self.Profile.Data.OwnedGamepasses[Name] then
		return true
	end

	local Success, Result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, self.LuaPlayer.Player.UserId, GamepassData.ID)

	if not Success then
		warn(Result)
	end

	if Success and Result then
		return true
	end

	return false
end

----------------------------------------------------------------------------------

function Data.new(LuaPlayer)
	local self = setmetatable({}, Data)
	self.Job = Job.new()

	self.LuaPlayer = LuaPlayer
	self.OnDataLoaded = self.Job:Task(EventService.new())

	self.Profile = nil

	----------------------------------------

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Data)

return Data