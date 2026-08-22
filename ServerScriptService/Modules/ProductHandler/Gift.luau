local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Gamepasses = require( ReplicatedStorage.Shared.Game.Gamepasses )
local LuaPlayerList = require( ServerScriptService.Modules.LuaPlayerList )

local GiftsProcessingStore = DataStoreService:GetDataStore("gifts-processing")
local Webhook = require( script.Parent.Webhook )

local GiftProducts = {}

local function LoadGiftsProcessing(UserId : booooooolean)
	local Success, Data = pcall(function()
		return GiftsProcessingStore:GetAsync(tostring(UserId))
	end)
	
	if Success and Data then
		return Data
	end
	
	return {}
end

return function(PlayerGifting : Player, GamepassName : String)
	local GiftingToPlayer : ObjectValue = PlayerGifting:FindFirstChild("GiftingToPlayer")

	if (GiftingToPlayer == nil) then
		warn("Player does not have a GiftingTo value.")
		return false
	end

	local ReceiverUserId = GiftingToPlayer.Value
	GiftingToPlayer:Destroy()

	-- Check if Player is in server and attempt to gift without MessageAsync, if the player isn't in the server or something goes wrong, resort to MessageAsync
	local ReceivingPlayer = Players:GetPlayerByUserId(ReceiverUserId)
	
	if ReceivingPlayer then
		local LuaPlayer = LuaPlayerList.WaitFor(ReceivingPlayer)

		if LuaPlayer then
			local ReceiverProfile = LuaPlayer.Data.Profile
			
			if (ReceiverProfile and ReceiverProfile:IsActive()) then
				ReceiverProfile.Data.OwnedGamepasses[GamepassName] = true
				
				ReplicatedStorage.Remotes.Announcement:FireClient(ReceivingPlayer, 
					`You have been gifted {GamepassName} by {PlayerGifting.Name}. Make sure to say thank you!`
				)
				
				ReplicatedStorage.Remotes.Announcement:FireClient(PlayerGifting, 
					`You have gifted {GamepassName} to {ReceivingPlayer.Name}.`, "How nice of you!"
				)

				task.spawn(function()
					Webhook:Send(
						"Gamepass Gift Receipt",
						`**User Gifting: [{PlayerGifting.UserId}](https://www.roblox.com/users/{PlayerGifting.UserId}/profile)**\n**Receiver: [{ReceiverUserId}](https://www.roblox.com/users/{ReceiverUserId}/profile)**\n**Gamepass Bought:** {GamepassName}\n**Processed:** True\n**Server Gift:** True`
					)
				end)
				
				return true
			end
		else
			return false
		end
	end

	-- If Player is not in game, or data profile doesn't exist for some reason:

	local MessageSuccess = shared.PlayerStore:MessageAsync(
		tostring(ReceiverUserId),
		{Type = "GamepassGift", GamepassName = GamepassName}
	)

	if not MessageSuccess then
		return false
	end

	local GiftData = LoadGiftsProcessing(ReceiverUserId)
	table.insert(GiftData, GamepassName)

	local ProcessSuccess, ProcessError = pcall(function()
		GiftsProcessingStore:SetAsync(tostring(ReceiverUserId), GiftData)
	end)

	if not ProcessSuccess then
		warn(`Error Saving GiftData for {ReceiverUserId}, Error: {ProcessError}`)

		return false
	end
	
	task.spawn(function()
		local Name = Players:GetNameFromUserIdAsync(ReceiverUserId)
		
		if Name then
			ReplicatedStorage.Remotes.Announcement:FireClient(PlayerGifting, 
				`You have gifted {GamepassName} to {Name}.`, "How nice of you! They will receive your gift when they join the game."
			)
		end
	end)

	return true
end