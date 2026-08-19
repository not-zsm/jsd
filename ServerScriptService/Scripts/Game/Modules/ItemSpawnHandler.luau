local ItemSpawn = {}
ItemSpawn.__index = ItemSpawn

-- Services
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local SpawnFolder = ServerStorage.ItemSpawns or ServerStorage.ItemSpawns:Wait()
local RandomLootTable = require( ReplicatedStorage.Modules.RandomLootTable )

-- Settings
if RunService:IsStudio() then
	ItemSpawn.Items = {
		["Temp V"] = 33,
		["Railgun"] = 33,
		["Daybreak"] = 34,
		["Death Note"] = 1,
	}
else
	ItemSpawn.Items = {
		["Temp V"] = 70,
		["Daybreak"] = 15,
		["Railgun"] = 15,
	}
end

ItemSpawn.SpawnDuration = 10 * 60 -- Every __ Minutes (Servertime)
ItemSpawn.SpawnChance = 75 --%
ItemSpawn.SpawnAmount = 1

-- Spawn Positions
local function GenerateSpawnCFrames()
	ItemSpawn.SpawnPoints = {}
	for _, SpawnPart in ipairs(SpawnFolder:GetChildren()) do
		table.insert(ItemSpawn.SpawnPoints, SpawnPart.CFrame)
	end
	
	--print(ItemSpawn.SpawnPoints)
	
	ItemSpawn.SpawnAvailable = {}
	for Index = 1, #ItemSpawn.SpawnPoints do
		ItemSpawn.SpawnAvailable[Index] = true
	end
end

local function GetAvailableSpawn()
	local AvailableIndexes = {}
	for Index, IsAvailable in ipairs(ItemSpawn.SpawnAvailable) do
		if IsAvailable then
			table.insert(AvailableIndexes, Index)
		end
	end

	if #AvailableIndexes == 0 then
		return nil
	end

	local RandomIndex = AvailableIndexes[math.random(1, #AvailableIndexes)]
	ItemSpawn.SpawnAvailable[RandomIndex] = false -- Mark as occupied
	return ItemSpawn.SpawnPoints[RandomIndex], RandomIndex
end

local function ReleaseSpawn(Index)
	if ItemSpawn.SpawnAvailable[Index] == false then
		ItemSpawn.SpawnAvailable[Index] = true
	end
end


-- Initialize
function ItemSpawn.new()
	local self = setmetatable({}, ItemSpawn)
	self.EventHandlers = {}
	
	self.LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
	self.LuaPlayers = self.LuaPlayerList.LuaPlayers
	
	GenerateSpawnCFrames()
	
	---- Auto event loop (you can modify or remove this)
	task.spawn(function()
		while RunService:IsRunning() do
			task.wait(ItemSpawn.SpawnDuration)
			
			if math.random(1, 100) <= self.SpawnChance then
				for i = 1, self.SpawnAmount do
					self:SpawnItem()
				end
			end
		end
	end)
	
	if workspace:GetAttribute("IsTestPlace") == true then
		task.spawn(self.SpawnTesterItems, self)
	end
	
	return self
end

-- Starts a random event
function ItemSpawn:SpawnItem(Config : Table)
	if not Config then
		Config = {}
	end
	
	local SpawnIndex
	local SpawnCFrame = Config.CFrame
	
	if not SpawnCFrame then
		local CFrame, Index = GetAvailableSpawn()
		SpawnCFrame = CFrame
		SpawnIndex = Index
		
		if not SpawnCFrame then
			warn("Items: No available Spawn CFrame found")
			return
		end
	end
	
	local ItemName = Config.ItemName
	if not ItemName then
		ItemName = RandomLootTable(ItemSpawn.Items)
	end
	
	local ItemList = ServerScriptService.Scripts.Game.Modules.Player.Character.Items.List
	local Item = ItemList[ItemName] and require( ItemList[ItemName] )
	
	if Item then
		if not Item.Template.PrimaryPart then
			local Handle = Item.Template:FindFirstChild("Handle")
			if Handle then
				Item.Template.PrimaryPart = Handle
			else
				warn(`Item: {ItemName} does not have a PrimaryPart`)
				return
			end
		end
		
		local DroppedTool = Item.Template:Clone()
		local Prompt : ProximityPrompt = DroppedTool.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
		
		if not Prompt then
			Prompt = Instance.new("ProximityPrompt")
			Prompt.ActionText = "Pick Up"
			Prompt.ObjectText = ItemName
			Prompt.Parent = DroppedTool.PrimaryPart
			Prompt.RequiresLineOfSight = false
		end
		
		Prompt.Enabled = true
		
		local Hitbox = DroppedTool:FindFirstChild("Hitbox")
		if not Hitbox then
			Hitbox = DroppedTool.PrimaryPart
		end
		
		DroppedTool.Parent = workspace.Visuals
		DroppedTool.PrimaryPart.CFrame = SpawnCFrame * (Item.SpawnOffset or CFrame.identity)
		Hitbox.CanCollide = true
		Hitbox.CollisionGroup = "NoPlayerCollision"
		
		if Item.OnSpawn then
			pcall(Item.OnSpawn, self, DroppedTool)
		end
		
		--print(`Spawned Item: {ItemName}`)
		
		local TriggerConnection
		TriggerConnection = Prompt.Triggered:Connect(function(Player)
			local LuaPlayer = self.LuaPlayers[Player]
			if #LuaPlayer.Character.Items.List >= 3 then
				return
			end
			
			TriggerConnection:Disconnect()
			TriggerConnection = nil

			DroppedTool:Destroy()
			LuaPlayer.Character.Items:Give(ItemName)
			
			if SpawnIndex then
				ReleaseSpawn(SpawnIndex)
			end
			
			if Config.ReplaceOnPickup then
				self:SpawnItem(Config)
			end
		end)
	else
		warn(`Items: Item /"{ItemName}/" not found.`)
	end
end

function ItemSpawn:SpawnTesterItems()
	local TesterPlate = workspace:FindFirstChild("TesterPlate")
	
	if TesterPlate then
		local SpawnPoints = TesterPlate.Items:GetChildren()

		for _, ItemSpawn in SpawnPoints do
			self:SpawnItem({
				ItemName = ItemSpawn.Name,
				CFrame = ItemSpawn.CFrame,
				ReplaceOnPickup = true
			})
		end
	end
end

return ItemSpawn.new()
