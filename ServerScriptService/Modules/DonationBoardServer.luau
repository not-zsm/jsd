local FOURTY_DAYS_TO_SECONDS = 3456000
local REFRESH_TIME_IN_SECONDS = 300
local MAX_LIST_COUNT = 10
local MAX_RETRIES = 5

local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local AllTimeLeaderboard = DataStoreService:GetOrderedDataStore("AllTimeRobuxLeaderboard")
local MonthlyLeaderboard = MemoryStoreService:GetSortedMap("MonthlyRobuxLeaderboard")

local RemoteRateLimiter = require( ServerScriptService.Modules.Utility.RemoteRateLimiter )
local ProfileStore = require( ServerScriptService.Modules.Utility.ProfileStore )
local Products = require( ServerScriptService.Modules.ProductHandler.Products )

local AbbreviateTime = require("./LeaderboardHandler/LeaderboardModule/Abbreviate Time")
local AbbreviateNumber = require("./LeaderboardHandler/LeaderboardModule/Abbreviate Number")
local LuaPlayerList = require("./LuaPlayerList")

local CharactersData = ServerScriptService.Modules.Player.Character.Combat

local DonationRemote = ReplicatedStorage.Remotes.RequestDonation

local DonationBoard = workspace.Leaderboards.DonationLeaderboard.LeaderboardGui.Holder

local Donations = {
	[10] = 3285471316,
	[100] = 3285471390,
	[1_000] = 3285471446,
	[10_000] = 3285471569,
	[100_000] = 3285471650,
	[1_000_000] = 3285471729, 
} 

local Month = os.date("*t", os.time()).month
local Year = os.date("*t", os.time()).year
local CurrentStoredMonth = MonthlyLeaderboard:GetAsync("CurrentMonth")

local CurrentDonationAccessPlayers = {
	AllTime = -1,
	Monthly = -1,
}

if CurrentStoredMonth ~= `{Month}/{Year}` then
	MonthlyLeaderboard:SetAsync("CurrentMonth", `{Month}/{Year}`, FOURTY_DAYS_TO_SECONDS)
	MonthlyLeaderboard:SetAsync("Leaderboard", {}, FOURTY_DAYS_TO_SECONDS)
end

local function GetAllTimeData(UserId : number)
	local Success, AllTimeData = pcall(function()
		return AllTimeLeaderboard:GetAsync(`{UserId}`)
	end)
	
	return if Success then AllTimeData else 0
end

local function GetMonthlyData(UserId : number)
	local Leaderboard = MonthlyLeaderboard:GetAsync("Leaderboard")
	
	for Index, Data : {UserId : number, Amount : number} in Leaderboard do
		if Data.UserId == UserId then
			return Data.Amount
		end
	end
end

local function SortMonthly(A : {UserId : number, Amount : number}, B : {UserId : number, Amount : number})
	return A.Amount > B.Amount
end

local function AddToDonationBoard(UserId : number, Amount : number)
	local AllTimeData = GetAllTimeData(UserId) or 0
	local MonthlyData = GetMonthlyData(UserId) or 0

	local NewAllTimeData = AllTimeData + Amount
	local NewMonthlyData = MonthlyData + Amount
	
	local AllTimeSetSuccess, AllTimeSetError = pcall(function()
		return AllTimeLeaderboard:SetAsync(`{UserId}`, NewAllTimeData)
	end)
	
	if not AllTimeSetSuccess then
		local CurrentRetry = 1
		
		while AllTimeSetSuccess ~= true and (CurrentRetry <= MAX_RETRIES) do
			CurrentRetry += 1
			
			AllTimeSetSuccess, AllTimeSetError = pcall(function()
				return AllTimeLeaderboard:SetAsync(`{UserId}`, NewAllTimeData)
			end)
			
			task.wait(CurrentRetry/MAX_RETRIES)
		end
		
		if AllTimeSetSuccess ~= true then
			warn(`DBS: Set {AllTimeSetError}`)
			return false
		end
	end
	
	MonthlyLeaderboard:UpdateAsync("Leaderboard", function(value, key)
		if not value then
			value = {}
		end
		
		for Index, Data in value do
			if Data.UserId == UserId then
				table.remove(value, Index)
			end
		end
		
		table.insert(value, {
			UserId = UserId,
			Amount = NewMonthlyData
		})
		
		table.sort(value, SortMonthly)
		
		return value, key
	end, FOURTY_DAYS_TO_SECONDS)
	
	return true
end

local function SafeCall(ToTry : (...any) -> (...any), OnError : ((...any) -> ...any)?, ...)
	local Packed = {...}
	local ToReturn

	local Success, Error = xpcall(function()
		ToReturn = { ToTry(unpack(Packed)) }
	end, debug.traceback)

	if Error then
		if OnError ~= nil then
			SafeCall(OnError, nil, Error)
		end

		warn(debug.traceback(Error))
	end

	return unpack(ToReturn or {})
end

-- RunTime

for Amount, ProductId in Donations do
	Products[ProductId] = {
		Name = `{Amount} Robux Donation`,
		PurchaseText = "We appreciate your support! This means alot to our development team.",
		
		Function = function(ReceivingPlayer : Player)
			return SafeCall(AddToDonationBoard, nil, ReceivingPlayer.UserId, Amount)
		end,
	}
	
	local Clone = script.DonationAmount:Clone()
	Clone.Name = `{Amount}`
	Clone.Price.Text = `\u{E002} {AbbreviateNumber(Amount, "Comma")}`
	Clone.LayoutOrder = Amount
	Clone.Parent = DonationBoard.Donations
end

DonationRemote.OnServerEvent:Connect(function(Player, Amount : number)
	if (RemoteRateLimiter.Check(DonationRemote, Player, 10) == false) then
		return
	end
	
	Amount = tonumber(Amount or 0)
	
	local ProductId = Donations[Amount]
	
	if ProductId == nil then
		return
	end
	
	MarketplaceService:PromptProductPurchase(Player, ProductId)
end)

-- create gui for players and set up listners to auto update

script.DonationBoardClient:Clone().Parent = ReplicatedStorage

local function MakeGUI(UserId : number, Index : number, Amount : number)
	local PlayerDisplay = script.PlayerTemplate:Clone()
	
	local NameSuccess, Name = pcall(function()
		return Players:GetNameFromUserIdAsync(tonumber(UserId))
	end)
	
	local ThubnailSuccess, Image = pcall(function()
		return Players:GetUserThumbnailAsync(tonumber(UserId), Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	
	PlayerDisplay.PlayerName.Text = if NameSuccess then Name else "???"
	PlayerDisplay.Rank.Text = `#{tonumber(Index)}`
	PlayerDisplay.Value.Text = `\u{E002} {AbbreviateNumber(tonumber(Amount), "Comma")}`
	PlayerDisplay.Icon.Image = if ThubnailSuccess then Image else "rbxassetid://100395502772079"
	PlayerDisplay.LayoutOrder = tonumber(Index)
	
	return PlayerDisplay
end

local function SetCharacters(UserId : number, Type : "AllTime" | "Monthly")
	local TypeTag = `{Type}Donation`
	local OppositeTag = `{if Type == "AllTime" then "Monthly" else "AllTime"}Donation`
	
	for _, Player in ipairs(Players:GetPlayers()) do
		if Player:HasTag("DonationCharacterAccess") and Player:HasTag(TypeTag) and Player.UserId ~= UserId and not Player:HasTag(OppositeTag) then
			Player:RemoveTag(TypeTag)
			
			Player:RemoveTag("DonationCharacterAccess")
			
			local LuaPlayer = LuaPlayerList.Get(Player)
			
			if LuaPlayer then
				local DataHandler = LuaPlayer.Data
				
				if DataHandler and DataHandler.Profile and DataHandler.Profile:IsActive() then
					local CharacterName = DataHandler.Profile.Data.CurrentCharacter
					
					local CharacterInfo = if CharacterName then CharactersData:FindFirstChild(CharacterName) else nil
					
					if CharacterInfo then
						CharacterInfo = require(CharacterInfo)
					else
						CharacterInfo = {}
					end
					
					if CharacterInfo.DonatorAccess then
						LuaPlayer.Character.Combat:SetCharacter("Gojo")
					end
				end
			end
		end
		
		if Player.UserId == UserId then
			Player:AddTag("DonationCharacterAccess")
			
			Player:AddTag(TypeTag)
		end
	end
end

local function ClearCurrent(Leaderboard : ScrollingFrame)
	for _, Item in Leaderboard:GetChildren() do
		if not Item:IsA("Frame") then
			continue
		end
		
		Item:Destroy()
	end
end

local function UpdateMonthly()
	ClearCurrent(DonationBoard.Monthly)
	
	local Success, Leaderboard = pcall(function()
		return MonthlyLeaderboard:GetAsync("Leaderboard")
	end)
	
	if not Success then
		local CurrentRetry = 1

		while not Success and (CurrentRetry <= MAX_RETRIES) do
			CurrentRetry += 1

			Success, Leaderboard = pcall(function()
				return MonthlyLeaderboard:GetAsync("Leaderboard")
			end)

			task.wait(CurrentRetry/MAX_RETRIES)
		end

		if not Success then
			warn(`DBS: Getting memeroy store async {Leaderboard}`)
			return
		end
	end
	
	if not Leaderboard then
		return
	end

	for Index = 1, MAX_LIST_COUNT do
		local Data = Leaderboard[Index]
		
		if not Data then
			continue
		end
		
		task.spawn(function()
			MakeGUI(Data.UserId, Index, Data.Amount).Parent = DonationBoard.Monthly
		end)
	end
	
	local MonthlyMost = Leaderboard[1]
	
	if MonthlyMost then
		CurrentDonationAccessPlayers.Monthly = tonumber(MonthlyMost.UserId)
		SetCharacters(tonumber(MonthlyMost.UserId), "Monthly")
	end
end 

local function UpdateAllTime()
	ClearCurrent(DonationBoard.AllTime)
	
	local Success, StoredSync = pcall(function()
		return AllTimeLeaderboard:GetSortedAsync(false, MAX_LIST_COUNT)
	end)
	
	if not Success then
		local CurrentRetry = 1

		while not Success and (CurrentRetry <= MAX_RETRIES) do
			CurrentRetry += 1

			Success, StoredSync = pcall(function()
				return AllTimeLeaderboard:GetSortedAsync(false, MAX_LIST_COUNT)
			end)

			task.wait(CurrentRetry/MAX_RETRIES)
		end

		if not Success then
			warn(`DBS: Getting stored aync {StoredSync}`)
			return
		end
	end
	
	if not StoredSync then
		return
	end

	local PageSuccess, Leaderboard = pcall(function()
		return StoredSync:GetCurrentPage()
	end)
	
	if not PageSuccess then
		local CurrentRetry = 1

		while not PageSuccess and (CurrentRetry <= MAX_RETRIES) do
			CurrentRetry += 1

			PageSuccess, Leaderboard = pcall(function()
				return StoredSync:GetCurrentPage()
			end)

			task.wait(CurrentRetry/MAX_RETRIES)
		end

		if not PageSuccess then
			warn(`DBS: Getting page aync {PageSuccess}`)
			return
		end
	end
	
	if not Leaderboard then
		return
	end

	for Index = 1, MAX_LIST_COUNT do
		local Data = Leaderboard[Index]

		if not Data then
			continue
		end

		task.spawn(function()
			MakeGUI(Data.key, Index, Data.value).Parent = DonationBoard.AllTime
		end)
	end
	
	local AllTimeMost = Leaderboard[1]

	if AllTimeMost then
		CurrentDonationAccessPlayers.AllTime = tonumber(AllTimeMost.key)
		SetCharacters(tonumber(AllTimeMost.key), "AllTime")
	end
end

local function UpdateTimer(Time : number)
	DonationBoard.Parent.Timer.Text = `Top Monthly & All Time donators get an Admin Character, Refresh in: {AbbreviateTime(Time)}`
end

local function GetRemainingTime()
	return REFRESH_TIME_IN_SECONDS - (os.time() % REFRESH_TIME_IN_SECONDS)
end

local ResetDebounce = false

RunService.PostSimulation:Connect(function()
	local TimeLeft = GetRemainingTime()

	UpdateTimer(TimeLeft)
	
	if ResetDebounce or TimeLeft > 1 then
		return
	end
	
	ResetDebounce = true
	
	UpdateMonthly()
	UpdateAllTime()
	
	task.delay(1, function()
		ResetDebounce = false
	end)
end)

UpdateMonthly()
UpdateAllTime()

Players.PlayerAdded:Connect(function(NewPlayer : Player)
	if CurrentDonationAccessPlayers.AllTime == NewPlayer.UserId then
		NewPlayer:AddTag("DonationCharacterAccess")
		NewPlayer:AddTag("AllTimeDonation")
		
	elseif CurrentDonationAccessPlayers.Monthly == NewPlayer.UserId then
		NewPlayer:AddTag("DonationCharacterAccess")
		NewPlayer:AddTag("MonthlyDonation")
	end
end)

return nil