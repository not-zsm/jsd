local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local info = require(ReplicatedStorage.info)

-- shared.* is still read in about twenty places. It mirrors info rather than
-- holding its own values, so there is one source and the call sites can migrate
-- to require(info) whenever they are next touched.
shared.info = info

-- was an Init Script parented under the module; a Script does not run in
-- ServerStorage, so it starts from here now
require( ServerStorage.modules.Weather )

shared.TesterPlaceId = info.placeIds.test
shared.Group = info.groupID
shared.PlaceIds = {
	Main = info.placeIds.main,
	MainVC = info.placeIds.mainVC,
	Test = info.placeIds.test,
	TestVC = info.placeIds.testVC,
}

shared.IsTestPlace = info.isTestPlace
shared.IsVCPlace = info.isVCPlace

-- Ranked went with matchmaking; combat and movement still guard on these.
shared.IsRankedPlace = false
shared.IsRankedLobby = false

task.spawn(function()
	workspace:SetAttribute("IsTestPlace", shared.IsTestPlace)
	workspace:SetAttribute("IsVCPlace", shared.IsVCPlace)
	workspace:SetAttribute("IsRankedLobby", shared.IsRankedLobby)
	workspace:SetAttribute("IsRankedPlace", shared.IsRankedPlace)
end)

----------------------------------------------------------------------------------

local LuaPlayerList = require( ServerStorage.modules.LuaPlayerList )

task.spawn(require, ReplicatedStorage.modules.shared.Game.Appearances)
task.spawn(require, ServerStorage.modules.HavocHandler )
task.spawn(require, ServerStorage.modules.CommandHandler)
task.spawn(require, ServerStorage.modules.AnnouncementHandler)
task.spawn(require, ServerStorage.modules.Npcs)
task.spawn(require, ServerStorage.modules.DonationBoardServer)

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
		return Player:GetRankInGroupAsync(shared.Group)
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

	local LuaPlayer = require(ServerStorage.modules.Player).new(Player)
	LuaPlayerList.Add(LuaPlayer)

	task.wait()

	if LuaPlayer:PlayerExists() then
		Player:LoadCharacterAsync()
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
		--return warn("didn't show region due to doxxing")
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