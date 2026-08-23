local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Gamepasses = require( script.Parent )
local GiftsProcessingStore = DataStoreService:GetDataStore("gifts-processing")

local HasGamepassOffline = {}

function HasGamepassOffline:Check(PlayerId : UserId, Name : String)
	local GamepassData = Gamepasses[Name]

	if (GamepassData == nil) then 
		return warn(Name, "is not a valid gamepass, did you name it incorrectly?")
	end
	
	local DataSuccess, DataResult = pcall(shared.PlayerStore.GetAsync, shared.PlayerStore, tostring(PlayerId))
	
	if DataSuccess and DataResult then
		if DataResult.Data.OwnedGamepasses[Name] then
			return true
		end
	end

	local Success, Result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, PlayerId, GamepassData.ID)

	if Success and Result then
		return true
	end
	
	-- Check to make sure gift isn't processing
	local Success, GiftData = pcall(function()
		return GiftsProcessingStore:GetAsync(tostring(PlayerId))
	end)

	if Success and GiftData then
		if table.find(GiftData, Name) then
			return true
		end
	end
	
	return false
end

return HasGamepassOffline
