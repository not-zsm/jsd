--[[
	Adding products: GUIDE
	
	Want to add a product?
	- Create a unique name for your product and set in the Enums table -> DeveloperProduct table, to the ID of the product
	- Create a Developer Product (in table DeveloperProduct), copy one of the ones in there already and set the key to the unique name before. Set all the values to desired.
	- To have it appear in the shop, find the Products table -> Shop table, and put the product id in one of the sections for it to appear.
	- Now for implementation: locate 'Shared.Assets.Build'
	
	- For maps, make a model in the 'Maps' folder, with the attributes:
		* Thumbnail - AssetId of the thumbnail to be displayed in the inventory. (string)
		* InsertAsset - (Optional) An optimisation to allow the model to instead be loaded from the Toolbox (better network efficiency) (string/number)
		* NeedsProduct - (Optional) The unique name (in Enums table) of the product that needs to be owned for this map to be usable. (string)
		* NeedsGamepass - (Optional) The unique name (in Enums table) of the gamepass that needs to be owned for this model to be usable. (string)
		
	- For models, make a folder in the 'Inventory' folder, and place it into any sub-folder (the folders will auto-categorise), with the attributes:
		* LayoutOrder - The order at which the section will appear at in-inventory. (number)
		* NeedsProduct (Optional) - The unique name (in Enums table) of the product that needs to be owned for this model to be usable. (string)
		* NeedsGamepass (Optional) - The unique name (in Enums table) of the gamepass that needs to be owned for this model to be usable. (string)
		
	- For modifiers, locate the modifier module in 'InstanceModifier.BaseTagModifier', and change the class table fields:
		* needs_product (Optional) - The unique name (in Enums table) of the product that needs to be owned for this model to be usable. (string)
		* needs_gamepass (Optional) - The unique name (in Enums table) of the gamepass that needs to be owned for this model to be usable. (string)
		
	That should be it, it now should work when you own the product.
	The process is the exact same with Gamepass, but you use NeedsGamepass instead.
	
	Dw, It should error if you have setup something incorrectly.
]]

export type ReceiptInfo = {
	CurrencySpent: number;
	CurrencyType: Enum.CurrencyType;
	PlaceIdWherePurchased: number;
	PlayerId: number;
	ProductId: number;
	ProductPurchaseChannel: Enum.ProductPurchaseChannel;
	PurchaseId: string;
};

local Enums = {
	Gamepass = {
		PrivateServerPlus = 1040382354;
		PineappleBoss = 1206891972;
		TrapsPack1 = 1205346307
	};
	DeveloperProduct = {
		-- TrapsPack1 = 3280505916;
		-- PineappleBoss = 3278090691;
		AddBuildSaveSlot = 3306828245;
		PlainsMap = -1;
		RuralMap = -2;
	};
};

local Gamepass = {
	[Enums.Gamepass.PrivateServerPlus] = {
		title = "Oh yeahhhhh ps+";
	};

	[Enums.Gamepass.TrapsPack1] = {
		one_time = true;
		title = "Traps Vol. 1";
		subtitle = "Gain 3 new trap modifiers.";
		-- description = [[Gives you access to 3 new trap modifiers. If you owned PS+, you will also gain access to preset trap models.]];
		creator_id = 85042395;
		creator_name = "Aenoir";
		stroke_gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.new(0.403922, 0.403922, 0.403922)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
		};
		backdrop_gradient = ColorSequence.new(Color3.new(0.580392, 0.580392, 0.580392));
		image = "rbxassetid://17567867550";
		preferred_size = UDim2.fromScale(0.4, 0.25);
	};

	[Enums.Gamepass.PineappleBoss] = {
		one_time = true;
		title = "Pineapple Summon";
		subtitle = "";
		-- description = [[Gives you access to a pineapple modifier that summons the one and only pineapple. Use a trigger on the modifier to summon. If you own PS+, you will gain access to additional models that use this new modifier.]];
		creator_id = 85042395;
		creator_name = "Aenoir";
		stroke_gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.new(1, 0.905882, 0.203922)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 0.435294, 0.172549)),
		};
		backdrop_gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.new(1, 0.937255, 0.580392)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
		};
		image = "rbxassetid://3400877924";
		preferred_size = UDim2.fromScale(0.5, 0.25);
		displayed_items = {
			{ image = "rbxassetid://103366738339014" },
			{ image = "rbxassetid://103366738339014" },
		};
	};
};

local DeveloperProduct = {
	--	[Enums.DeveloperProduct.TrapsPack1] = {
	--		one_time = true;

	--		title = "Traps Vol. 1";
	--		subtitle = "Gain 3 new trap modifiers.";
	--		description = [[Gives you access to 3 new trap modifiers. If you owned PS+, you will also gain access to preset trap models.]];
	--		creator_id = 85042395;
	--		creator_name = "Aenoir";
	--		stroke_gradient = ColorSequence.new{
	--			ColorSequenceKeypoint.new(0, Color3.new(1, 0.905882, 0.203922)),
	--			ColorSequenceKeypoint.new(1, Color3.new(1, 0.435294, 0.172549)),
	--		};
	--		image = "rbxassetid://16992645010";
	--		preferred_size = UDim2.fromScale(0.4, 0.3);
	--		--displayed_items = {};
	--	};

	--	[Enums.DeveloperProduct.PineappleBoss] = {
	--		one_time = true;

	--		title = "SUMMON PINEAPPLE RAHH";
	--		subtitle = "scary boss summon ahhh";
	--		description = [[Gives you access to a pineapple modifier that summons the one and only pineapple. Use a trigger on the modifier to summon.
	--If you own PS+, you will gain access to additional models that use this new modifier.]];
	--		creator_id = 85042395;
	--		creator_name = "Aenoir";
	--		stroke_gradient = ColorSequence.new{
	--			ColorSequenceKeypoint.new(0, Color3.new(1, 0.905882, 0.203922)),
	--			ColorSequenceKeypoint.new(1, Color3.new(1, 0.435294, 0.172549)),
	--		};
	--		image = "rbxassetid://6855964012";
	--		preferred_size = UDim2.fromScale(0.5, 0.3);
	--		displayed_items = {};
	--	};
	--[0] = {
	--	one_time = true;

	--	title = "Town (Free)",
	--	description = [[This cute little map is old-style, contains various different buildings, perfect for a zombie apocolypse roleplay. This map is <b>small</b>.]];
	--	stroke_gradient = ColorSequence.new{
	--		ColorSequenceKeypoint.new(0, Color3.new(0.505882, 0.352941, 0.0862745)),
	--		ColorSequenceKeypoint.new(1, Color3.new(0.745098, 0.67451, 0.270588)),
	--	};
	--	image = "http://www.roblox.com/asset/?id=107758788058915";
	--};
	--[1] = {
	--	one_time = true;

	--	title = "Ancient (Default)",
	--	creator_id = 462646322;
	--	creator_name = "TheZipTune";
	--	description = [[This is the current JSD map. This map is bright, and features landmarks such as a tile area, a large exterior only castle, a water area, and various mini-ruins. This map is <b>extra large</b>.]];
	--	stroke_gradient = ColorSequence.new{
	--		ColorSequenceKeypoint.new(0, Color3.new(0.239, 1.000, 0.580)),
	--		ColorSequenceKeypoint.new(1, Color3.new(1, 0.909804, 0.239216)),
	--	};
	--	image = "http://www.roblox.com/asset/?id=81492384391100";
	--};

	[Enums.DeveloperProduct.PlainsMap] = {
		one_time = true;
		title = "Plains",
		creator_id = 462646322;
		creator_name = "TheZipTune";
		description = [[The map previously present before <b>Ancient</b> in JSD. This map has a yellow tint, featuring landmarks such as a gas station, a cafe, and tile area. This map is <b>large</b>.]];
		stroke_gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.new(1, 0.905882, 0.203922)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 0.435294, 0.172549)),
		};
		image = "http://www.roblox.com/asset/?id=70894490097877";
		preferred_size = UDim2.fromScale(1, 0.2);
	};

	[Enums.DeveloperProduct.RuralMap] = {
		one_time = true;
		title = "Rural",
		creator_id = 462646322;
		creator_name = "TheZipTune";
		description = [[The map previously present before <b>Plains</b> in JSD. This map has a blue tint perfect for rainy days, it features landmarks such as a gas station, a tile area, a boss arena, and an ancient ruin. This map is <b>large</b>.]];
		stroke_gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.new(0.505882, 0.384314, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(0.12549, 0.768627, 1)),
		};
		image = "http://www.roblox.com/asset/?id=82830922744575";
		preferred_size = UDim2.fromScale(1, 0.2);
	};

	[Enums.DeveloperProduct.AddBuildSaveSlot] = {
		one_time = false;
		title = "Add Build Save Slot",
		creator_name = "Jimpee's Cabin";
		description = [[I might've farted on this gui so its a little stinky my apologies]];
		stroke_gradient = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.new(0.152941, 1, 0.67451)),
			ColorSequenceKeypoint.new(1, Color3.new(0, 0.6, 1)),
		};
		image = "http://www.roblox.com/asset/?id=743367508";
		preferred_size = UDim2.fromScale(1, 0.2);
		purchase_callback = function(profile, builder)
			if builder then
				builder.stream:increment({"SlotAmount"}, 1);
				builder:initialise_slots();
			else
				profile.Data.Builds.SlotAmount += 1
			end;

			return true
		end,
	};
};

local Products = {
	DeveloperProduct = DeveloperProduct;
	Gamepass = Gamepass;
	PurchaseMessages = {
		[1] = "You already own this product.";
		[2] = "This product does not exist.";
	};
	Enum = Enums;

	Shop = {
		More = {
			LayoutOrder = 0,
			Enums.DeveloperProduct.AddBuildSaveSlot
		};
		Modifiers = {
			LayoutOrder = 2,
			Enums.Gamepass.PineappleBoss;
			Enums.Gamepass.TrapsPack1;
		};
		--Maps = {
		--	LayoutOrder = 1,
		--};
	};
};

function Products.get_product_id(value: string | number): number
	local product_id: number;

	if typeof(value) == "string" then
		product_id = Enums.DeveloperProduct[value];
		assert(product_id, `Product with name '{value}' does not exist`);
	else
		product_id = value;
	end

	return product_id;
end

function Products.get_product_string(value: string | number): string
	return tostring( Products.get_product_id(value) )
end

function Products.get_pass_id(value: string | number): number
	local product_id: number;

	if typeof(value) == "string" then
		product_id = Enums.Gamepass[value];
		assert(product_id, `Gamepass with name '{value}' does not exist`);
	else
		product_id = value;
	end

	return product_id;
end

function Products.get_pass_string(value: string | number): string
	return tostring( Products.get_pass_id(value) )
end

return Products;