local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

shared.TesterPlaceId = 95576587700882
shared.Group = 14636287

shared.PlaceIds = {
	Main = 18519254033,
	MainVC = 131330652857284,
	Test = 95576587700882,
	TestVC = 82685679507656,
}

shared.IsTestPlace = (game.PlaceId == shared.PlaceIds.Test or game.PlaceId == shared.PlaceIds.TestVC)
shared.IsVCPlace = (game.PlaceId == shared.PlaceIds.TestVC or game.PlaceId == shared.PlaceIds.MainVC)

-- Ranked was removed along with matchmaking. These stay defined because combat
-- and movement code still guards on them; both now read false everywhere.
shared.IsRankedPlace = false
shared.IsRankedLobby = false

task.spawn(function()
	workspace:SetAttribute("IsTestPlace", shared.IsTestPlace)
	workspace:SetAttribute("IsVCPlace", shared.IsVCPlace)
	workspace:SetAttribute("IsRankedLobby", shared.IsRankedLobby)
	workspace:SetAttribute("IsRankedPlace", shared.IsRankedPlace)
end)

----------------------------------------------------------------------------------

local LuaPlayerList = require( ServerScriptService.Modules.LuaPlayerList )

task.spawn(require, ReplicatedStorage.Shared.Game.Appearances)
task.spawn(require, ServerScriptService.Modules.HavocHandler )
task.spawn(require, ServerScriptService.Modules.CommandHandler)
task.spawn(require, ServerScriptService.Modules.AnnouncementHandler)
task.spawn(require, ServerScriptService.Modules.Npcs)
task.spawn(require, ServerScriptService.Modules.DonationBoardServer)

task.spawn(function()
	local function Update(Sound : Sound)
		local SoundGroup = Sound:GetAttribute("SoundGroup")

		if SoundGroup then
			local Group = SoundService:WaitForChild(SoundGroup, 2)

			if Group then
				Sound.SoundGroup = Group
			end
		end
	end

	CollectionService:GetInstanceAddedSignal("UpdateSoundGroup"):Connect(Update)

	for _, Item in CollectionService:GetTagged("UpdateSoundGroup") do
		Update(Item)
	end
end)

task.spawn(function()
	local function Update(Model : Model)
		for _, Item in ipairs(Model:GetDescendants()) do
			if Item:IsA("BasePart") then
				Item:AddTag("DestructibleDescendant")
			end
		end
	end

	CollectionService:GetInstanceAddedSignal("DestructibleModel"):Connect(Update)

	for _, Item in CollectionService:GetTagged("DestructibleModel") do
		Update(Item)
	end
end)

----------------------------------------------------------------------------------

local AllowContentCreators = false

local function CheckForTester(Player : Player)
	local Success, Result = pcall(function()
		return Player:GetRankInGroup(shared.Group)
	end)

	if Success then
		local RequiredRank = AllowContentCreators and 59 or 60

		if Result < RequiredRank then
			Player:Kick("You are not a tester")
		end
	else
		warn(Result)
		Player:Kick(`Error fetching your group rank, try again later. Error: {Result}`)
	end

	return Success
end

local function AddLuaPlayer(Player : Player)
	if Player.UserId == 263484818 then
		task.wait(Random.new():NextNumber(1.5, 5))

		Player:Kick("There was an error trying to load your data, please try again later.")

		return 
	end

	if not RunService:IsStudio() then
		if shared.IsTestPlace then
			local Success = CheckForTester(Player)

			if not Success then 
				return 
			end
		end

		if Player.AccountAge < 7 then
			Player:Kick("Account not old enough!")
		end
	end

	local LuaPlayer = require(ServerScriptService.Modules.Player).new(Player)
	LuaPlayerList.Add(LuaPlayer)

	task.wait()

	if LuaPlayer:PlayerExists() then
		Player:LoadCharacter()
	end
end

for _, Player in ipairs(Players:GetPlayers()) do
	task.defer(AddLuaPlayer, Player)
end

Players.PlayerAdded:Connect(AddLuaPlayer)

Players.PlayerRemoving:Connect(function(Player : Player)
	local LuaPlayer = LuaPlayerList.LuaPlayers[Player]

	if (LuaPlayer ~= nil) then
		LuaPlayerList.Remove(LuaPlayer)
		LuaPlayer:Destroy()
	end

	task.delay(3, Player.Destroy, Player)
end)

task.spawn(function()
	workspace:SetAttribute("ServerTimeStart", workspace:GetServerTimeNow())

	if RunService:IsStudio() then
		return warn("didn't show region due to doxxing")
	end

	local URL = "http://ip-api.com/json/?fields=16394"--"http://ip-api.com/json/"
	local Success, Result = pcall(HttpService.GetAsync, HttpService, URL, false)

	if Success then
		if (Result == nil) then
			return warn("error getting result from http")
		end

		local Json = HttpService:JSONDecode(Result)
		print(Json.status)

		if Json.status == "success" then
			print(Json)

			workspace:SetAttribute("Region", HttpService:JSONEncode({ 
				Country = Json.countryCode,
				City = Json.city,
				Region = Json.regionName,
			}))
		end
	else
		warn("region failed to load:", Result)
	end
end)