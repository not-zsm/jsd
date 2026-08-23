local Title = {}
Title.__index = Title

local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")
local AllTimeLeaderboard = DataStoreService:GetOrderedDataStore("AllTimeRobuxLeaderboard")

local DataModule = require(replicatedStorage.modules.shared.Game.TitleData)

local function GetAllTimeData(UserId : number)
	local Success, AllTimeData = pcall(function()
		return AllTimeLeaderboard:GetAsync(`{UserId}`)
	end)
	
	return AllTimeData or 0
end

function Title:_Init()
	if not self.LuaPlayer:PlayerExists() then return end
	
	if (self.LuaPlayer.GroupRank == nil) then
		self.LuaPlayer.OnGroupRankFetched:Wait()
	end

	network.loadTitles.sendTo({
		kills = self.LuaPlayer.Data.Profile.Data.Kills,
		groupRank = self.LuaPlayer.GroupRank,
	}, self.LuaPlayer.Player)
end

local function Find(NameIWANT : string)
	local DATA = nil
	local TYPE = nil
	
	for r, tbl in {DataModule.KillTitles, DataModule.GroupTitles, DataModule.CustomTitles, DataModule.DonatorTitles} do
		for name, data in pairs(tbl) do
			if name == NameIWANT then
				DATA = data
				TYPE = r == 1 and "KillTitles" or r == 2 and "GroupTitles" or r == 3 and "CustomTitles" or r == 4 and "DonatorTitles"
				
				break
			end
		end
	end
	
	return DATA, TYPE
end

function Title:Equip(name : string)
	local player : Player = self.LuaPlayer.Player
	local foundTable, titleType = Find(name)

	if not foundTable then
		return warn(`{player.Name} attempted to equip title that does not exist: {name}`)
	end

	-- Check Title Type
	if titleType == "KillTitles" then
		if (self.LuaPlayer.Data.Profile.Data.Kills < foundTable.requirement) then
			return warn("Player: "..player.Name.." attempted to equip a kills title without permissions") -- Player's kills did not match the requirement
		end
	elseif titleType == "DonatorTitles" then
		if (GetAllTimeData(self.LuaPlayer.UserId) < foundTable.requirement) then
			return warn("Player: "..player.Name.." attempted to equip a donator title without permissions") -- Player's donation amount did not match the requirement
		end
	elseif titleType == "GroupTitles" then
		
		if typeof(foundTable.requirement) == "table" then
			local rankInTable = table.find(foundTable.requirement, self.LuaPlayer.GroupRank)
			
			if not rankInTable then
				return warn("Player: "..player.Name.." attempted to equip a group title without permissions") -- Player's rank did not match the requirement
			end
		else
			if self.LuaPlayer.GroupRank ~= foundTable.requirement then
				return warn("Player: "..player.Name.." attempted to equip a group title without permissions") -- Player's rank did not match the requirement
			end
		end
	
	elseif titleType == "CustomTitles" then
		if (foundTable  == nil) then
			return warn("Custom Title: ".. name .." unknown") -- Couldn't find Title
		end
		
		local accessIds = foundTable.accessIds
		local access = foundTable.access

		if (accessIds and not table.find(accessIds, player.UserId)) or (access and not table.find(access, player.Name)) then
			return warn("Player: "..player.Name.." attempted to equip a custom title without permissions") -- Player was not found in title's access table
		end
	end

	-- Set Title
	self:Set(name, foundTable)
end

function Title:Unequip()
	local titleGui =  self.LuaCharacter.Head:FindFirstChild("Title") 

	if (titleGui ~= nil) then
		titleGui:Destroy()
	end

	self.LuaPlayer.Data.Profile.Data.CurrentTitle = ""
end

function Title:Set(Name : string, Data : {})
	local titleGui : typeof(script.Gui) = self.LuaCharacter.Head:FindFirstChild("Title") or self:AddGui()
	local titleLabel = titleGui:FindFirstChild("Title")
	local titleStroke = titleGui:FindFirstChild("Stroke")
	
	local DefaultFont = DataModule.DefaultSettings.font
	local FontData = Data.font or {}
	
	if titleGui then
		titleLabel.Text = Name
		titleStroke.Text = Name
		
		if (typeof(Data.color) == "ColorSequence") then
			titleLabel.UIGradient.Color = Data.color
			titleGui:SetAttribute("Color", Data.color.Keypoints[1].Value)
			
		elseif (typeof(Data.color) == "Color3") then
			titleLabel.UIGradient.Color = ColorSequence.new(Data.color)
			titleGui:SetAttribute("Color", Data.color)
		end
		
		if FontData.FontFace and tonumber(FontData.FontFace) then
			titleLabel.FontFace = Font.fromId(FontData.FontFace)
			titleStroke.FontFace = Font.fromId(FontData.FontFace)
		else
			titleLabel.Font = FontData.FontFace or DefaultFont.FontFace
			titleStroke.Font = FontData.FontFace or DefaultFont.FontFace
		end
		
		titleLabel.FontFace.Weight = FontData.FontWeight or DefaultFont.FontWeight
		titleStroke.FontFace.Weight = FontData.FontWeight or DefaultFont.FontWeight

		titleStroke.UIStroke.Color = FontData.StrokeColor or DefaultFont.StrokeColor
		titleStroke.UIStroke.Thickness = FontData.StrokeSize or DefaultFont.StrokeSize

		titleGui:SetAttribute("ChatPrefix", Data.chatPrefix)
		
		if Data.gradient and typeof(Data.gradient) == "table" then
			titleGui:SetAttribute("GradientOffsetTime", Data.gradient.offsetTime or 3)
		end
		
		titleGui.Gradient.Enabled = (Data.gradient ~= nil)
		titleGui.Enabled = true

		self.LuaPlayer.Data.Profile.Data.CurrentTitle = Name
	end
end

function Title:AddGui()
	if not self.LuaCharacter.Head:FindFirstChild("Title") then
		local Gui = script.Gui:Clone()
		Gui.Name = "Title"
		Gui.Parent = self.LuaCharacter.Head

		return Gui
	end
end

function Title.new(LuaCharacter)
	local self = setmetatable({}, Title)
	
	self.LuaCharacter = LuaCharacter
	self.LuaPlayer = LuaCharacter.LuaPlayer
	
	----------------------------------------

	task.spawn(self._Init, self)

	return self
end

table.freeze(Title)

return Title
