local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer;
local BuildPersistent = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildPersistent:WaitForChild("Shared");
local Remotes = BuildPersistent:WaitForChild("Remotes");
local BuildAssets = BuildShared:WaitForChild("Assets");

local Build = require( ReplicatedStorage.BuildTools.Build )
local Products = require( BuildShared.Data.Products );
local NotificationStatus = require( BuildShared.Data.NotificationStatus );
local Maid = require( ReplicatedStorage.Packages.Maid )
local Stylus = require( ReplicatedStorage.Packages.Stylus )
local Table = require( ReplicatedStorage.Packages.Table )
local Signal = require( ReplicatedStorage.Packages.Signal )

type SlotObject = {
	instance: GuiObject;
	slot: number;
	maid: Maid.Maid;
	update: () -> ();
}

local Marketplace = {};
Marketplace.__index = Marketplace;

function Marketplace.new(build_tools)
	local maid = build_tools.maid:limb();
	
	local self = setmetatable(
		{
			maid = maid;
			build_tools = build_tools;
			enabled = false;
			purchase_buy_enabled = true;
			
			purchase_maid = maid:limb();
			owned_changed = maid:add(Signal.new());
			
			tweens = {};
			
			main_ui = build_tools.elements.Main;
			shop = build_tools.elements.Shop;
			purchase_page = build_tools.elements.Shop.Body.Body.Items.BuyFrame;
			shop_page = build_tools.elements.Shop.Body.Body.Items.ItemsFrame;
			page_layout = build_tools.elements.Shop.Body.Body.Items.UIPageLayout;
		}, 
		Marketplace);
	
	self:initialise();
	
	return self;
end;

export type Marketplace = typeof(Marketplace.new(...))

function Marketplace:destroy()
	table.clear(self.tweens);
	self.purchase_maid:destroy();
	Table.dispose(self);
end


function Marketplace:initialise_tweens()
	local info = TweenInfo.new(0.15);
	local open_info = { GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5)};
	local close_info = { GroupTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.25)};

	self.tweens.open = TweenService:Create(self.shop.Body, info, open_info);
	self.tweens.close = TweenService:Create(self.shop.Body, info, close_info);

	self.tweens.close:Play();

	self.tweens.close.Completed:Connect(function(status)
		if (status == Enum.PlaybackState.Completed) then
			self.shop.Enabled = false;
			self.shop.Body.Position = UDim2.fromScale(0.5, 0.5);
		end;
	end)
end

function Marketplace:initialise_inspect_dragger()
	local icon = self.purchase_page.Body.Purchase.Icon;
	local dragger = icon.UIDragDetector;
	local initial_position = Vector2.zero;

	local function update_zoom(position)
		local mouse_position = position - GuiService:GetGuiInset();
		local offset = (mouse_position - icon.Display.AbsolutePosition)
		local size =  icon.Display.Icon.AbsoluteSize - icon.Display.AbsoluteSize;

		icon.Display.Icon.Position = UDim2.fromOffset(
			math.clamp(-offset.X, -size.X ,0),
			math.clamp(-offset.Y,-size.Y, 0));
	end

	icon.UIDragDetector.DragContinue:Connect(update_zoom)

	dragger.DragStart:Connect(function(input_position)
		initial_position = input_position;
		icon.Display.Icon.UIScale.Scale = 2;
		update_zoom(input_position);
	end)

	dragger.DragEnd:Connect(function(input_position)
		icon.Display.Icon.UIScale.Scale = 1;
		update_zoom(input_position)
	end)

	update_zoom(Vector2.zero);
end

function Marketplace:initialise()
	self:initialise_tweens();
	self:initialise_inspect_dragger();
	
	self.main_ui.BodyLeft.Links.Shop.MouseButton1Click:Connect(function()
		self:toggle();
	end)
	
	self.purchase_page.Body.Checkout.Back.MouseButton1Click:Connect(function()
		self:close_purchase_page();
	end)
	
	self.build_tools.maid:add(Remotes.Transactions.SaleGranted.OnClientEvent:Connect(function(sale_type, sale_id)
		if (sale_type == 1) then
			-- Product
			
		elseif (sale_type == 2) then
			-- Gamepass
		end
		
		self.build_tools:notify(NotificationStatus.success, "Thank you for your purchase.", 10);
	end))
	
	self.page_layout:JumpTo(self.shop_page);
	
	for name, products in Products.Shop do
		local frame = self.build_tools.assets.ShopItemsFrame:Clone();
		frame.Name = name;
		frame.Title.Text = `Available {name}!`;
		frame.LayoutOrder = products.LayoutOrder or 0;
		frame.Parent = self.shop_page;
		
		frame.UIPadding:AddTag("UI-AutoPadding")
		--frame.UIListLayout:AddTag("UI-AutoPadding")
		frame.Slide.UIListLayout:AddTag("UI-AutoPadding")
		
		for _, id in ipairs(products) do
			local info_type, product = Enum.InfoType.Product, Products.DeveloperProduct[id];
			
			if not product then
				info_type, product = Enum.InfoType.GamePass, Products.Gamepass[id];
			end;
			
			if not product then
				warn(`There is no DeveloperProduct or Gamepass assoicated with {id}!`);
				continue;
			end;
			
			product.type_title = name;
			
			local banner_frame = self:create_wide_banner_product(id, info_type, product)
			banner_frame.Parent = frame.Slide;
		end;
	end;
end

function Marketplace:bind_to_owned(product, gamepass, callback): Maid.Maid
	local maid = self.build_tools.maid:limb();
	
	if product then
		maid:add(Build.stream:observe({"Purchases", Products.get_product_string(product)}, function()
			maid:destroy();
			callback();
		end))
	end

	if gamepass then
		maid:add(Build.stream:observe({"Gamepass", Products.get_pass_string(gamepass)},function()
			maid:destroy();
			callback();
		end))
	end
	
	return maid;
end

function Marketplace:bind_to_instance_owned(instance: Instance, callback): Maid.Maid
	local needs_product = instance:GetAttribute("NeedsProduct");
	local needs_gamepass = instance:GetAttribute("NeedsGamepass");

	return self:bind_to_owned(needs_product, needs_gamepass, callback);
end

function Marketplace:has_owned(product, gamepass): boolean
	if product and not self:has_product(product) then
		return false;
	end

	if gamepass and not self:has_gamepass(gamepass) then
		return false;
	end;

	return true;
end

function Marketplace:has_instance_owned(instance: Instance): boolean
	local needs_product = instance:GetAttribute("NeedsProduct");
	local needs_gamepass = instance:GetAttribute("NeedsGamepass");
	
	return self:has_owned(needs_product, needs_gamepass);
end

function Marketplace:observe_product_owned(product_id: any, callback): RBXScriptSignal
	return Build.stream:observe({"Purchases", Products.get_product_string(product_id)}, callback);
end

function Marketplace:observe_gamepass_owned(pass_id: any, callback): RBXScriptSignal
	return Build.stream:observe({"Gamepass", Products.get_pass_string(pass_id)}, callback);
end

function Marketplace:observe_product(product_id: any, callback): RBXScriptConnection
	return Build.stream:observe({"Purchases", Products.get_product_string(product_id)}, callback);
end

function Marketplace:observe_gamepass(pass_id: any, callback): RBXScriptConnection
	return Build.stream:observe({"Gamepass", Products.get_pass_string(pass_id)}, callback);
end

function Marketplace:has_product(product_id: any): boolean
	local products = Build.stream:get({"Purchases", Products.get_product_string(product_id)});

	if products then
		return #products > 0;
	end;

	return false;
end

function Marketplace:has_gamepass(pass_id: any): boolean
	return Build.stream:get({"Gamepass", Products.get_pass_string(pass_id)}) or false;
end

function Marketplace:notify_purchase_code(message_code: (string | number)?): ()
	if typeof(message_code) == "number" then
		self.build_tools:notify(NotificationStatus.info, Products.PurchaseMessages[message_code]);

	elseif typeof(message_code) == "string" then
		self.build_tools:notify(NotificationStatus.info, message_code);
	else
		self.build_tools:notify(NotificationStatus.info, "You are unable to purchase this product.");
	end
end

function Marketplace:purchase_gamepass(pass_id: any): ()
	pass_id = Products.get_pass_id(pass_id);
	
	local success, message_code = Remotes.Transactions.CanPurchaseGamepass:InvokeServer(pass_id);

	if success then
		MarketplaceService:PromptGamePassPurchase(Player, pass_id);
	else
		self:notify_purchase_code(message_code);
	end;
end

function Marketplace:purchase_product(product_id: any): ()
	product_id = Products.get_product_id(product_id);
	
	local success, message_code = Remotes.Transactions.CanPurchaseProduct:InvokeServer(product_id);
	
	if success then
		MarketplaceService:PromptProductPurchase(Player, product_id);
	else
		self:notify_purchase_code(message_code);
	end
end

function Marketplace:set_purchase_buy_visible(value: boolean)
	if value then
		self.purchase_buy_enabled = true;
		
		self.purchase_page.Body.Checkout.Buy.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
		self.purchase_page.Body.Checkout.Buy.UIStroke.Color = Color3.fromRGB(196, 196, 196);
		self.purchase_page.Body.Checkout.Buy.Title.TextColor3 = Color3.fromRGB(255, 255, 255);
		self.purchase_page.Body.Checkout.Buy.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255);
		self.purchase_page.Body.Checkout.Buy.Title.UITextStroke.Color = Color3.fromRGB(81, 81, 81);
	else
		self.purchase_buy_enabled = false;

		self.purchase_page.Body.Checkout.Buy.BackgroundColor3 = Color3.fromRGB(32, 32, 32);
		self.purchase_page.Body.Checkout.Buy.UIStroke.Color = Color3.fromRGB(32, 32, 32);
		self.purchase_page.Body.Checkout.Buy.Title.TextColor3 = Color3.fromRGB(32, 32, 32);
		self.purchase_page.Body.Checkout.Buy.Icon.ImageColor3 = Color3.fromRGB(64, 64, 64);
		self.purchase_page.Body.Checkout.Buy.Title.UITextStroke.Color = Color3.fromRGB(16, 16, 16);
	end
end

function Marketplace:is_on_purchase_page(): boolean
	return self.page_layout.CurrentPage == self.purchase_page;
end

function Marketplace:close_purchase_page()
	if not self:is_on_purchase_page() then
		return;
	end;
	
	self.purchase_maid:clean();
	self.page_layout:JumpTo(self.shop_page);
end

function Marketplace:open_purchase_page(info)
	if self:is_on_purchase_page() then
		return;
	end;
	
	local product = info.product;
	if not product then return end;
	
	self.purchase_page.Body.Checkout.Title.Text = info.title;
	self.purchase_page.Body.Checkout.SubTitle.Text = `Loading ...`;
	self.purchase_page.Body.Checkout.Type.Title.Text = info.type_title or "Map";
	self.purchase_page.Body.Checkout.Buy.Title.Text = product.PriceInRobux;
	self.purchase_page.Body.Checkout.Description.Title.Text = info.description or product.Description or "No description is available for this item.";
	self.purchase_page.Body.Purchase.Icon.Image = info.image;
	self.purchase_page.Body.Purchase.Icon.Display.Icon.Image = info.image;
	
	self.purchase_maid:add(task.spawn(function()
		local success, name = pcall(Players.GetNameFromUserIdAsync, Players, info.creator_id);

		if success and name then
			self.purchase_page.Body.Checkout.SubTitle.Text = `By @{name}`;
			
		elseif info.creator_name then
			self.purchase_page.Body.Checkout.SubTitle.Text = `By @{info.creator_name}`;
			
		else
			self.purchase_page.Body.Checkout.SubTitle.Text = `Could not retrieve creator`;
		end;
	end))
	
	local function update_text_scale()
		self.purchase_page.Body.Checkout.Description.Title.TextSize = self.purchase_page.Body.Checkout.AbsoluteSize.Y * 0.065;
	end;
	
	update_text_scale();
	self.purchase_maid:add(self.purchase_page.Body.Checkout:GetPropertyChangedSignal("AbsoluteSize"):Connect(update_text_scale));
	
	self.purchase_maid:add(self.purchase_page.Body.Checkout.Buy.MouseButton1Click:Connect(function()
		if not self.purchase_buy_enabled then return end;
		
		self:set_purchase_buy_visible(false);
		
		task.delay(2, function()
			self:set_purchase_buy_visible(true);
		end)
		
		if info.info_type == Enum.InfoType.Product then
			self:purchase_product(info.id);
			
		elseif info.info_type == Enum.InfoType.GamePass then
			self:purchase_gamepass(info.id);
		end
	end))
	
	self.page_layout:JumpTo(self.purchase_page);
end

function Marketplace:create_wide_banner_product(id: number, info_type: Enum.InfoType, info)
	info.info_type = info_type;
	info.id = id;
	
	local map_frame = self.build_tools.assets.ShopMapItem:Clone();
	map_frame.Expand.Image = info.image;
	map_frame.Buy.Title.Text = "?";
	map_frame.Backdrop.UIStroke.UIGradient.Color = info.stroke_gradient;
	map_frame.Glow.Icon.UIGradient.Color = info.stroke_gradient;
	map_frame.Body.Title.Text = info.title or "Untitled Map";
	map_frame.Body.SubTitle.Text = info.subtitle or "Purchase once to use this map whenever!";
	map_frame.Size = info.preferred_size or map_frame.Size;
	map_frame.Body.SubTitle.Size = UDim2.fromScale(0.3 + map_frame.Size.Width.Scale / 2, 0.45);
	
	if info.backdrop_gradient then
		map_frame.Expand.UIGradient.Transparency = NumberSequence.new(0);
		map_frame.Expand.UIGradient.Color = info.backdrop_gradient;
	end;
	
	if info.displayed_items then
		for _, display in info.displayed_items do
			local frame = self.build_tools.assets.ShopItemDisplayItem:Clone();
			frame.Image = display.image;
			frame.Icon.Image = display.image;
			frame.Parent = map_frame.Items;
		end
	end;
	
	Stylus:bind_hover_highlight(map_frame.Expand, {Info = TweenInfo.new(0.4)})
	
	task.spawn(function()
		local success, product_info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, info_type);
		
		if not success and RunService:IsStudio() then
			success, product_info = true, {PriceInRobux = "?"};
		end;
		
		if success then
			info.product = product_info;
			map_frame.Buy.Title.Text = product_info.PriceInRobux;
		end
	end);
	
	map_frame.Expand.MouseButton1Click:Connect(function()
		self:open_purchase_page(info);
	end)
	
	map_frame.Buy.MouseButton1Click:Connect(function()
		self:open_purchase_page(info);
	end)
	
	return map_frame;
end

function Marketplace:toggle(value: boolean?)
	if value == nil then
		value = not self.enabled
	end;

	if self.enabled ~= value then
		self.build_tools:close_all(self);
		self.enabled = value;
		
		if value then
			self.shop.Enabled = true;
			self.tweens.open:Play();
			Stylus:tween_blur(15);
			SoundService:PlayLocalSound(self.build_tools.sounds.Flash);
		else
			self.tweens.close:Play();
			Stylus:tween_blur(0);
		end;
	end;
end;

table.freeze(Marketplace);

return Marketplace;