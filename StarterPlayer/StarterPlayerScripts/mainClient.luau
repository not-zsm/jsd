--!strict
local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Job = require(replicatedStorage.modules.shared.Utilities.Job)
local clientCombat = require(replicatedStorage.clientCombat)
local info = require(replicatedStorage.info)
local network = require(replicatedStorage.modules.network)
local soundUtil = require(replicatedStorage.modules.shared.soundUtil)

local uiConfig = require(script.UI.config)
local shopHelper = require(script.UI.helpers.shopHelper)
local createBGBlur = require(script.UI.helpers.blur)

local nirs = { "zsm", "dih", "niki", "pook" }

export type System = {
	Name: string,

	Priority: number?,
	Async: boolean?,

	Start: (self: System, Client: MainClient, Cleanup: any) -> (),
	Stop: ((self: System) -> ())?,
}

export type MainClient = {
	Player: Player,
	PlayerGui: PlayerGui,

	Systems: { [string]: System },
	Started: boolean,

	Add: (self: MainClient, System) -> MainClient,
	Get: (self: MainClient, name: string) -> System?,
	Start: (self: MainClient) -> (),
	Stop: (self: MainClient) -> (),
}

--------------------------------------------------------------------------------

local MainClient = {}
MainClient.__index = MainClient

--- Registers a system. Chainable, so a boot script reads as a list.
function MainClient:Add(System: System): MainClient
	assert(typeof(System) == "table", "MainClient:Add expects a system table")
	assert(typeof(System.Name) == "string" and System.Name ~= "", "a system needs a Name")
	assert(typeof(System.Start) == "function", `system "{System.Name}" needs a Start`)
	assert(self.Systems[System.Name] == nil, `system "{System.Name}" is already registered`)
	assert(not self.Started, `cannot add "{System.Name}" after Start`)

	self.Systems[System.Name] = System

	return self
end

function MainClient:Get(Name: string): System?
	return self.Systems[Name]
end

function MainClient:Start()
	if self.Started then
		return
	end

	self.Started = true

	local Ordered = {}

	for _, System in self.Systems do
		table.insert(Ordered, System)
	end

	table.sort(Ordered, function(A, B)
		local APriority, BPriority = A.Priority or 100, B.Priority or 100

		if APriority == BPriority then
			return A.Name < B.Name
		end

		return APriority < BPriority
	end)

	-- on its own thread: building the player yields on a good many
	-- WaitForChilds, and the systems used to run alongside it rather than
	-- queued up behind it
	task.spawn(function()
		local Success, Problem = pcall(self.StartPlayer, self)

		if not Success then
			warn(`[mainClient] the player failed to start: {Problem}`)
		end
	end)


	for _, System in Ordered do
		local Cleanup = self.Job:Task(Job.new())
		self.Cleanups[System.Name] = Cleanup

		local function Run()
			local Success, Problem = pcall(System.Start, System, self, Cleanup)

			if not Success then
				warn(`[mainClient] system "{System.Name}" failed to start: {Problem}`)
			end
		end

		if System.Async then
			Cleanup:Task(task.spawn(Run))
		else
			Run()
		end
	end
end

function MainClient:StartPlayer()
	local Replicator = replicatedStorage.modules.shared.movementReplicator
	require(Replicator:WaitForChild("ClientReplicator", 100))

	require(replicatedStorage.modules.client.luaPlayer).new()

	local DonationBoard = replicatedStorage:WaitForChild("DonationBoardClient", 100)

	if DonationBoard then
		require(DonationBoard)
	end
end

--- Stops every system and drops what they registered.
function MainClient:Stop()
	if not self.Started then
		return
	end

	for _, System in self.Systems do
		if System.Stop then
			local Success, Problem = pcall(System.Stop, System)

			if not Success then
				warn(`[MainClient] system "{System.Name}" failed to stop: {Problem}`)
			end
		end
	end

	self.Job:Clean()
	table.clear(self.Cleanups)

	self.Started = false
end

--------------------------------------------------------------------------------

function MainClient:SetHotbarVisible(Visible: boolean)
	local UI = self.Combat and self.Combat.UI

	if UI and UI.Hotbar then
		UI.Hotbar:SetHidden(not Visible)
	end
end

--- The key the menus and info.movesets share, which is the character lowercased.
function MainClient:CurrentMoveset(): string?
	local Name = self.Combat and self.Combat.CurrentCharacter

	return Name and string.lower(Name) or nil
end

local function applyOutfit(container, char: Model)
	local pick = math.random(1, #info.theBigFour)

	char:SetAttribute("nir", nirs[pick])
	
	local got, desc = pcall(Players.GetHumanoidDescriptionFromUserIdAsync, Players, info.theBigFour[pick])
	if not got then
		warn(`shop: could not fetch the keeper's outfit: {desc}`)
		return
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	container:Task(task.spawn(function()
		humanoid:ApplyDescriptionResetAsync(desc)
	end))
end

function MainClient:destroyContainer()
	if self.Container then self.Container:Destroy() self.Container = nil end
end

function MainClient:CloseMenus()
	self.PreviousMenu = nil
	self:destroyContainer()
end

function MainClient:createContainer(menu)
	if self.Container then self:destroyContainer() end
	if self.PreviousMenu == menu then self.PreviousMenu = nil return end

	self.Container = Job.new()
	self.PreviousMenu = menu

	return self.Container
end

function MainClient:Shop(currentShop)
	local container = self:createContainer('shop')
	if not container then return end

	local shopkeeperTypes = uiConfig.shop.keeper.shopkeeperTypes
	local shopYap = uiConfig.shop.keeper.yap

	local shop = script.UI:WaitForChild('shop'):Clone()
	shop.Parent = self.PlayerGui
	container:Task(shop)

	local shopitemFolder = shop.container.menu.shops[currentShop]

	local finalPos = shop.container.menu.Position
	shop.container.menu.Position = UDim2.new(0.5, 0, 2, 0)

	local shopKeeperModel = shop.container.keepa.shopKeeper.worldModel.shopKeeper	
	local shopKeeper = shopHelper.new(shopkeeperTypes[math.random(1, #shopkeeperTypes)], shopKeeperModel, shop, container)
	container:Task(shopKeeper)

	local menuTween = TweenService:Create(shop.container.menu, TweenInfo.new(0.7, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {Position = finalPos})
	container:Task(menuTween)
	menuTween:Play()

	local modernLife: Sound = soundUtil:playSound(script.UI.helpers.shopHelper.assets.modernLife, SoundService)

	createBGBlur(container, 0.7, 24)
	self:SetHotbarVisible(false)

	applyOutfit(container, shopKeeperModel)

	container:Task(task.spawn(function()
		local toYapShopThing = shopYap[math.random(1, #shopYap)]

		shopKeeper:shopkeeperYap(toYapShopThing)

		if toYapShopThing == shopYap[2] then
			shopKeeper:shopkeeperYap(shopYap[math.random(1, #shopYap)])
		end
		--shopKeeper:shopkeeperYap(shopYap[1])
	end))

	container:Task(function()
		shopKeeper.forceStop = true
		self:SetHotbarVisible(true)
		modernLife:Destroy()
	end)

	shopKeeper:timeoutResponses()

	--// BUTTONS
	if not shop then return end
	local pokeButton = shop:WaitForChild('container', 5):WaitForChild('keepa', 5):WaitForChild('shopKeeper', 5):WaitForChild('button', 5)
	pokeButton.MouseButton1Up:Connect(function()
		shopKeeper:pressKeeper()
	end)

	local buttonsByName = {}
	local amountButtons, purchaseButtons = {}, {}

	for _, button in shopitemFolder:GetDescendants() do
		if not (button:IsA("ImageButton") or button:IsA("TextButton")) then continue end

		buttonsByName[button.Name] = button

		if button:HasTag("amountButton") then
			table.insert(amountButtons, button)
		else
			table.insert(purchaseButtons, button)
		end
	end

	local AMOUNT_CYCLE = {1, 5, 10}

	local function nextAmount(current)
		for i, v in AMOUNT_CYCLE do
			if v == current then
				return AMOUNT_CYCLE[(i % #AMOUNT_CYCLE) + 1]
			end
		end
		return AMOUNT_CYCLE[1]
	end

	for _, button in amountButtons do
		container:Task(button.MouseButton1Up:Connect(function()
			local target = buttonsByName[button:GetAttribute("connection")]
			if not target then return end

			local newAmount = nextAmount(target:GetAttribute("amount") or 1)
			target:SetAttribute("amount", newAmount)
			button.Text = `x{newAmount}`
		end))
	end

	for _, button in purchaseButtons do
		container:Task(button.MouseButton1Up:Connect(function()
			network.purchase.send({ item = button.Name, count = button:GetAttribute("amount") or 1 })
		end))
	end

	--// TEXT STUFF
	if currentShop == 'main shop' then
		local emotePriceText = shopitemFolder.emotes.price
		local titlePriceText = shopitemFolder.titles.price
		local itemPriceText = shopitemFolder.item.price
		local sodaPriceText = shopitemFolder.soda.price

		emotePriceText.Text = `JP¥{info.shopPrices.main.emotes}`
		titlePriceText.Text = `JP¥{info.shopPrices.main.titles}`
		itemPriceText.Text = `JP¥{info.shopPrices.main.item}`
		sodaPriceText.Text = `JP¥{info.shopPrices.main.soda}`
	end
end	

--------------------------------------------------------------------------------

function MainClient.new(): MainClient
	local self = setmetatable({}, MainClient)

	self.Player = Players.LocalPlayer
	self.PlayerGui = self.Player:WaitForChild("PlayerGui") :: PlayerGui

	self.Systems = {}
	self.Cleanups = {}
	self.Started = false

	self.Job = Job.new()

	return (self :: any) :: MainClient
end

function MainClient.Default(): MainClient
	local Client = MainClient.new()

	clientCombat.UIFactory = function(Combat)
		Client.Combat = Combat

		-- The topbar icons live with the combat UI but open menus that live here,
		-- so the UI carries a way back.
		local UI = require(script.UI).new(Combat)
		UI.MainClient = Client

		return UI
	end

	for _, Module in script.Systems:GetChildren() do
		if Module:IsA("ModuleScript") then
			Client:Add(require(Module) :: any)
		end
	end

	return Client
end

--------------------------------------------------------------------------------

return MainClient
