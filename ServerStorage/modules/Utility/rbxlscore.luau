--[=[
    @class rbxlscore.luau
    A module that evaluates a user's avatar based on their accessories.
    It retrieves the user's current wearing accessories and evaluates them using a point-based system
    to determine if the avatar has inappropriate content.
]=]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Marketplace = game:GetService("MarketplaceService")
local AvatarEditorService = game:GetService("AvatarEditorService")

local module = {}

-- Store the fetched patterns so that they are only fetched once.
module.fetchedPatterns = nil

--[=[
    Retrieves all the accessories of a user, including shirts, pants, and any other assets that are currently worn.
    @param userId: number - The user ID of the player whose accessories are being retrieved.
    @returns wordedAccessories: table - A table containing the names of the user's accessories.
]=]
module.getUserAccessories = function(userId: number)
	local accessories = {}
	local humanoidDescription = Players:GetHumanoidDescriptionFromUserId(userId)

	if humanoidDescription.GraphicTShirt ~= 0 then
		table.insert(accessories, humanoidDescription.GraphicTShirt)
	end

	if humanoidDescription.Shirt ~= 0 then
		table.insert(accessories, humanoidDescription.Shirt)
	end

	if humanoidDescription.Pants ~= 0 then
		table.insert(accessories, humanoidDescription.Pants)
	end

	for _, data in humanoidDescription:GetAccessories(true) do
		table.insert(accessories, data.AssetId)
	end

	local success, result = pcall(function()
		return AvatarEditorService:GetBatchItemDetails(accessories, Enum.AvatarItemType.Asset)
	end)

	local wordedAccessories = {}

	if not success then
		warn("RBXLSCORE_Error: " .. result)
	else
		for _, data in result do
			table.insert(wordedAccessories, data.Name)
		end
	end

	--for _, id in accessories do
	--	local success, message = pcall(function()
	--		local data = Marketplace:GetProductInfo(id)
	--		table.insert(wordedAccessories, data.Name)
	--	end)

	--	if not success then
	--		warn("RBXLSCORE_Error: " .. message, id)
	--	end
	--end

	return wordedAccessories
end

--[=[
    Fetch the patterns from the remote JSON file on GitHub.
    This JSON contains patterns used for matching accessories and checking for inappropriate content.
    It will only fetch the data once and cache it.
]=]
local function fetchPatternsFromGit()
	-- Check if the patterns have already been fetched
	if module.fetchedPatterns then
		return module.fetchedPatterns
	end

	local url = "https://raw.githubusercontent.com/DevKrazes/RBXLSCORE/refs/heads/main/patterns.json"
	local response
	local success, errorMessage = pcall(function()
		response = HttpService:GetAsync(url)
	end)

	if success then
		local data = HttpService:JSONDecode(response)
		module.fetchedPatterns = data  -- Cache the fetched patterns
		return data
	else
		warn("Error fetching patterns: " .. errorMessage)
		return nil
	end
end

--[=[
    Check the accessories of multiple users for flagged patterns, determining the appropriateness of each avatar.
    The server evaluates the avatars based on a point-based system, returning the results for each user in a table format.

    @param userIds: table - A list of user IDs to be evaluated.
    @returns result: table - Contains the evaluation results of the avatars.
]=]
module.CheckUserIds = function(userIds)
	-- Fetch patterns from GitHub
	local patterns = fetchPatternsFromGit()
	if not patterns then
		return { success = false, message = "Failed to fetch patterns from Git" }
	end

	-- Create result data for response
	local result = {
		success = true,
		score = {},
		flaggedItems = {},
		totalScore = 0,
	}

	for i, userId in userIds do
		local accessories = module.getUserAccessories(userId)
		if accessories == nil then
			continue
		end

		-- Check for matches against blackList patterns (with points)
		local flaggedItems = {}
		local scores = 0
		for _, item in patterns.blackList do
			for _, accessory in accessories do
				if string.match(accessory:lower(), item.pattern:lower()) then
					local isWhitelisted = false

					for _, pattern in patterns.whiteList do
						if string.match(accessory:lower(), pattern:lower()) then
							isWhitelisted = true
							break
						end
					end

					if isWhitelisted then
						continue
					end

					table.insert(flaggedItems, { item = accessory, pattern = string.match(accessory, item.pattern), score = item.points })
					result.totalScore += item.points
					scores += item.points
				end
			end
		end

		result.score[i] = scores
		result.flaggedItems[i] = flaggedItems
	end

	return result
end

--[=[
    Check the user's accessories for flagged patterns, determining the appropriateness of the avatar.
    The server evaluates the avatar based on a point-based system and returns the result in table format.
    
    @param userId: number - The user ID of the player being evaluated.
    @returns result: table - Contains the evaluation results of the avatars.
]=]
module.CheckUserId = function(userId: number)
	local accessories = module.getUserAccessories(userId)
	if accessories == nil then
		return
	end

	-- Fetch patterns from GitHub
	local patterns = fetchPatternsFromGit()
	if not patterns then
		return { success = false, message = "Failed to fetch patterns from Git" }
	end

	-- Check for matches against blackList patterns (with points)
	local flaggedItems = { [1] = {} }
	local totalScore = 0
	local scores = { [1] = 0 }
	for _, item in patterns.blackList do
		for _, accessory in accessories do
			if string.match(accessory:lower(), item.pattern:lower()) then
				local isWhitelisted = false

				for _, pattern in patterns.whiteList do
					if string.match(accessory:lower(), pattern:lower()) then
						isWhitelisted = true
						break
					end
				end

				if isWhitelisted then
					continue
				end

				table.insert(flaggedItems[1], { item = accessory, pattern = string.match(accessory, item.pattern), score = item.points })
				totalScore += item.points
				scores[1] += item.points
			end
		end
	end

	-- Create result data for response
	local result = {
		success = true,
		score = scores,
		flaggedItems = flaggedItems,
		totalScore = totalScore
	}

	return result
end

--[=[
    Adds new patterns in the whiteList or blackList.
    This allows you to dynamically modify the patterns used for evaluation.
    @param listType: string - The list type, either "whiteList" or "blackList".
    @param pattern: string - The new pattern to add or replace in the list.
    @param points: number? - Used for blackList pattern to evaluate total score. 
]=]
module.modifyPattern = function(listType: string, pattern: string, points: number?)
	local patterns = fetchPatternsFromGit()

	if not patterns then
		return { success = false, message = "Unable to fetch patterns." }
	end

	if listType == "whiteList" then
		table.insert(patterns.whiteList, pattern)
	elseif listType == "blackList" then
		table.insert(patterns.blackList, { pattern = pattern, points = points })
	else
		return { success = false, message = "Invalid list type. Must be either 'whiteList' or 'blackList'." }
	end

	-- Cache the modified patterns
	module.fetchedPatterns = patterns
	return { success = true }
end

return module
