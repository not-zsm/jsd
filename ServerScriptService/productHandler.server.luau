local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local PolicyService = game:GetService("PolicyService")
local Players = game:GetService("Players")

local Gift = require( script.Gift )
local Webhook = require( script.Webhook )

local LuaPlayerList = require( ServerStorage.modules.LuaPlayerList )
local Data = require( ServerStorage.modules.Player.Character.Emotes.Data )

local Gamepasses = require( ReplicatedStorage.Shared.Game.Gamepasses )
local HasGamepassOffline = require( ReplicatedStorage.Shared.Game.Gamepasses.HasGamepassOffline )
local RemoteAntiSpam = require( ServerStorage.modules.Utility.RemoteRateLimiter )

local Products = require( script.Products )

Products[Gamepasses["Early Access"].GiftID] = {
	Name = "Early Access Gift",

	Function = function(PlayerGifting : Player)
		return Gift(PlayerGifting, "Early Access")
	end
}

Products[Gamepasses["Extra Emote Slots"].GiftID] = {
	Name = "Extra Emote Slots Gift",

	Function = function(PlayerGifting : Player)
		return Gift(PlayerGifting, "Extra Emote Slots")
	end
}

Products[Gamepasses["Private Server+"].GiftID] = {
	Name = "Private Server+ Gift",

	Function = function(PlayerGifting : Player)
		return Gift(PlayerGifting, "Private Server+")
	end
}

Products[Gamepasses["Kill Sounds"].GiftID] = {
	Name = "Kill Sounds Gift",

	Function = function(PlayerGifting : Player)
		return Gift(PlayerGifting, "Kill Sounds")
	end
}

ReplicatedStorage.Remotes.GiftGamepass.OnServerEvent:Connect(function(PlayerGifting, ReceiverUserId : UserId, Name : string)
	if (typeof(Name) ~= "string" or Gamepasses[Name] == nil) or typeof(ReceiverUserId) ~= "number" then 
		return
	end

	if (RemoteAntiSpam.Check(ReplicatedStorage.Remotes.GiftGamepass, PlayerGifting, 20) == false) then
		return
	end

	local Data = Gamepasses[Name]
	local OwnsGamepass = false

	local ReceivingPlayer = Players:GetPlayerByUserId(ReceiverUserId)

	if ReceivingPlayer then
		local LuaPlayer = LuaPlayerList.WaitFor(ReceivingPlayer)

		if LuaPlayer then
			OwnsGamepass = LuaPlayer.Data:HasGamepass(Name, true)
		else
			warn("lua player does not exist")
		end
	else
		OwnsGamepass = HasGamepassOffline:Check(ReceiverUserId, Name)
	end

	if (OwnsGamepass == true) then
		ReplicatedStorage.Remotes.Notification:FireClient(PlayerGifting,  {
			Title = "Gifting Error",
			Text = `This user already owns {Name}`,
			Duration = 3
		})

	elseif (OwnsGamepass == false) then
		local OldGiftingToPlayer = PlayerGifting:FindFirstChild("GiftingToPlayer")

		if OldGiftingToPlayer then
			OldGiftingToPlayer:Destroy()
		end

		local GiftingToPlayer = Instance.new("NumberValue")
		GiftingToPlayer.Name = "GiftingToPlayer"
		GiftingToPlayer.Value = ReceiverUserId
		GiftingToPlayer.Parent = PlayerGifting

		if (PlayerGifting.Name == "swrerm" or PlayerGifting.Name == "SolidSounds" or PlayerGifting.Name == "Jimpeewastaken") then
			Gift(PlayerGifting, Name)
		else
			MarketplaceService:PromptProductPurchase(PlayerGifting, Data.GiftID)
		end
	end
end)

local function FunctionErrored(Player : Player, Handler)
	warn(`{Handler.Name} failed for`, Player.Name, "returned false in function")

	ReplicatedStorage.Remotes.Notification:FireClient(Player, {
		Title = "Product Error",
		Text = `Purchasing {Handler.Name} has unexpectedly errored. Rejoining will make it try again. Roblox will automatically refund you if this issue is recurring.`,
		Duration = 7
	})

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function(UserId, ProductId, Purchased)
	if ProductId == 3348046631 then
		local Player : Player = Players:GetPlayerByUserId(UserId)

		if (Player ~= nil and Player.Parent ~= nil) then 
			Player:SetAttribute("CannotUseCommands", false)
		end
	end
end)

MarketplaceService.ProcessReceipt = function(Info)
	if not Info.PlayerId then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local Player : Player = Players:GetPlayerByUserId(Info.PlayerId)

	if (Player == nil or Player.Parent == nil) then 
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local Handler = Products[Info.ProductId]

	if (Handler == nil) then
		local ProductInfo = MarketplaceService:GetProductInfo(Info.ProductId, Enum.InfoType.Product)
		local MessUpText = ProductInfo and ProductInfo.Name or Info.ProductId

		ReplicatedStorage.Remotes.Notification:FireClient(Player, {
			Title = "Uh oh",
			Text = `We have seemed to mess up the {MessUpText} product, Roblox will refund you if this reccurs. If you can, report this error to the Jump Showdown discord server.`,
			Duration = 7
		})

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local Success, Result = pcall(Handler.Function, Player)

	if not Success then
		warn("purchase failed for", Player.Name, Result)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if not Result then
		return FunctionErrored(Player, Handler)
	end

	ReplicatedStorage.Remotes.Notification:FireClient(Player, {
		Title = "Thank you!",
		Text = Handler.PurchaseText or `You have purchased {Handler.Name}`,
		Duration = 7
	})

	return Enum.ProductPurchaseDecision.PurchaseGranted
end