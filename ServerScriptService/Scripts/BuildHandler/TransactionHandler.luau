local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Unpacker = require( "./Unpacker" );
local Products = require( Unpacker.Shared.Data.Products );
local Remotes = Unpacker.Remotes;

local TransactionHandler = {};
TransactionHandler.__index = TransactionHandler;

function TransactionHandler.new(BuildHandler)
	local self = setmetatable(
		{
			build_handler = BuildHandler;
		}, 
		TransactionHandler);
	
	self:initialise();
	
	return self;
end;

function TransactionHandler:is_shop_product(product_id: number)
	return Products.DeveloperProduct[product_id] ~= nil;
end

function TransactionHandler:get_shop_product(product_id: number)
	return Products.DeveloperProduct[product_id];
end

function TransactionHandler:initialise()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, pass_id, was_purchased)
		if Products.Gamepass[pass_id] and was_purchased then
			local builder = self.build_handler:get(player)
			
			if builder then
				builder:give_gamepass(pass_id);
			end
		end
	end)
	
	function Remotes.Transactions.CanPurchaseProduct.OnServerInvoke(player: Player, product_id: number)
		local builder = self.build_handler:get(player)

		if builder then
			return builder:can_purchase_product(product_id);
		else
			return false;
		end
	end
	
	function Remotes.Transactions.CanPurchaseGamepass.OnServerInvoke(player: Player, pass_id: number)
		local builder = self.build_handler:get(player)

		if builder then
			return builder:can_purchase_gamepass(pass_id);
		else
			return false;
		end
	end
end

table.freeze(TransactionHandler);

return TransactionHandler;