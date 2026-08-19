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
	Ranked = 0, -- CHANGE THIS!!!
	RankedLobby = 0, -- THIS TOO
	TestRanked = 120735443646303,
	TestRankedLobby = 122394296123463,
}

shared.IsTestPlace = (game.PlaceId == shared.PlaceIds.Test or game.PlaceId == shared.PlaceIds.TestVC)
shared.IsVCPlace = (game.PlaceId == shared.PlaceIds.TestVC or game.PlaceId == shared.PlaceIds.MainVC)
shared.IsRankedPlace = (game.PlaceId == shared.PlaceIds.Ranked or game.PlaceId == shared.PlaceIds.TestRanked)
shared.IsRankedLobby = (game.PlaceId == shared.PlaceIds.RankedLobby or game.PlaceId == shared.PlaceIds.TestRankedLobby)

task.spawn(function()
	workspace:SetAttribute("IsTestPlace", shared.IsTestPlace)
	workspace:SetAttribute("IsVCPlace", shared.IsVCPlace)
	workspace:SetAttribute("IsRankedLobby", shared.IsRankedLobby)
	workspace:SetAttribute("IsRankedPlace", shared.IsRankedPlace)
end)

task.spawn(function()
	if not shared.IsTestPlace then
		local TesterPlate = workspace:FindFirstChild("TesterPlate")
		
		if TesterPlate then
			TesterPlate:Destroy()
		end
	end
	
	if shared.IsRankedLobby then
		local Map = workspace:FindFirstChild("Map")
		
		if Map then
			Map.Model:ClearAllChildren();
		end;
		
		local NewMap = ServerStorage.RankedAssets.Lobby.Map:Clone()

		if not Map then
			NewMap.Parent = workspace;
		else
			local LoadInto = {Model = true};

			for _, Folder in NewMap:GetChildren() do
				if not LoadInto[Folder.Name] then
					Folder.Parent = Map;
				end;
			end;

			for Name, ShouldLoad in pairs(LoadInto) do
				if ShouldLoad then
					local Source = NewMap:FindFirstChild(Name)
					local Descendant = Map:FindFirstChild(Name)
					
					if Source and Descendant then
						for _, Item in ipairs(Source:GetChildren()) do
							Item.Parent = Descendant 
						end
					end
				end
			end
		end
		
		print(NewMap)
		
		workspace.DefaultAmbience:Destroy()
		workspace.RankedMusic.Lobby.Music:Play()
		
		script.GlobalQueueHandler.Enabled = true
	end
	
	if shared.IsRankedPlace then
		local Map = workspace:FindFirstChild("Map")

		if Map then
			Map.Model:ClearAllChildren();
		end;
		
		workspace.DefaultAmbience:Destroy()

		script.MatchManager.Enabled = true
		
	elseif not shared.IsRankedPlace then
		workspace.RankedPlate:Destroy()
	end
end)

----------------------------------------------------------------------------------

local LuaPlayerList = require( script.Modules.LuaPlayerList )

task.spawn(require, ReplicatedStorage.Modules.Shared.Game.Appearances)
task.spawn(require, ServerScriptService.Scripts.HavocHandler )
task.spawn(require, script.Modules.CharaSpawner)
task.spawn(require, script.Modules.CommandHandler)
task.spawn(require, script.Modules.AnnouncementHandler)
task.spawn(require, script.Modules.Npcs)
task.spawn(require, script.Modules.DonationBoardServer)
task.spawn(require, script.Modules.VCServerTeleporter)
task.spawn(require, script.Modules.RankedTeleporter)
task.spawn(require, script.Modules.MainTeleporter)
task.spawn(require, script.Modules.EventSystemHandler)
task.spawn(require, script.Modules.ItemSpawnHandler)
task.spawn(require, script.Modules.Arcade)

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
	
	local LuaPlayer = require(script.Modules.Player).new(Player)
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
