local BaseEvent = require( script.Parent );

local HotProperty = setmetatable({}, BaseEvent);
HotProperty.__index = HotProperty

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Signal = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)
local Maid = require(ReplicatedStorage.Packages.Maid)

local CaseFunctions = require("../Modules/CaseFunctions");

function HotProperty.new(...)
	local self = setmetatable(BaseEvent.new(...), HotProperty)
	
	-- Settings
	self.Settings = {
		EventDuration = 240, -- Seconds
		TimeUntilTracking = 5,
	}

	-- Configuration
	self.SpawnsFolder = ServerStorage.EventAssets.CrateSpawns
	self.CrateTemplate = ServerStorage.EventAssets.Crate

	self.CaseHolderMaid = nil
	self.PlayerHoldTimes = {}
	self.PlayersTrackingProject = {}
	self.EndTime = nil

	return self
end

function HotProperty:Start()
	if self.Active then return end;
	
	BaseEvent.Start(self);
	
	self.System.EventUtility:Announce("World Event - Hot Property", "A Random Project has spawned somewhere on the map! Hold onto it the longest to win.")

	self.PlayerHoldTimes = {}
	self.PlayersTrackingProject = {}

	self.Leaderboard = Instance.new("Configuration")
	self.Leaderboard.Name = "HotProperty Leaderboard"
	self.Leaderboard.Parent = ReplicatedStorage

	self.Maid:add(self.Leaderboard)

	self:Spawn()

	self.Maid:add(self.Case.ProximityPrompt.Triggered:Connect(function(Player)
		local LuaPlayer, LuaCharacter = self.System.EventUtility:GetLuaPlayer(Player)

		if LuaCharacter.Combat:NotStunned() and Player.Character:FindFirstChild("Humanoid").Health > 0 then
			self:HandleCasePickup(Player)
		end
	end))

	self.EndTime = time() + self.Settings.EventDuration

	local TimerThread = task.delay(self.Settings.EventDuration, function()
		if self.CaseHolder then
			self:DropCase()
		end

		local Winner, LongestTime = nil, 0
		for Player, TimeHeld in pairs(self.PlayerHoldTimes) do
			if TimeHeld > LongestTime then
				Winner = Player
				LongestTime = TimeHeld
			end
		end

		self:End(Winner)
	end)

	self.Maid:add(TimerThread)

	local TimeUntilMarked = task.delay(self.Settings.TimeUntilTracking, function()
		if self.Case then
			self.System.EventUtility:FireReliableVFX("WorldEvents/HotProperty", "MarkCrate", true, self.Case.Attachment, (self.EndTime))

			self.Maid:add(ReplicatedStorage.Remotes.WorldEvents.TrackProject.OnServerEvent:Connect(function(Player)
				table.insert(self.PlayersTrackingProject, Player)
			end))
		end
	end)
	self.Maid:add(TimeUntilMarked)

	-- Update Leaderboard Loop
	self.UpdateHolderScore = coroutine.create(function()
		while true do
			if self.CaseHolder then
				self.PlayerHoldTimes[self.CaseHolder] = (self.PlayerHoldTimes[self.CaseHolder] or 0) + 1
				self.Leaderboard:SetAttribute(self.CaseHolder.Name, self.PlayerHoldTimes[self.CaseHolder])
			end

			task.wait(1)
		end
	end)

	coroutine.resume(self.UpdateHolderScore)
	self.Maid:add(self.UpdateHolderScore)

end


--function HotProperty:UpdateLeaderboard()
--	if self.UpdateHolderScore then
--		print("Removed")
--		self.Maid:delete(self.UpdateHolderScore)
--	end

--	--for Player, Score in pairs(self.PlayerHoldTimes) do
--	--	self.Leaderboard:SetAttribute(Player.Name, Score)
--	--end
--	if self.CaseHolder then
--		print("yes")
--		self.UpdateHolderScore = coroutine.create(function()
--			while true do
--				print("loop")
--				self.PlayerHoldTimes[self.CaseHolder] += 1
--				self.Leaderboard:SetAttribute(self.CaseHolder.Name, self.PlayerHoldTimes[self.CaseHolder])
--				task.wait(1)
--			end
--		end)

--		coroutine.resume(self.UpdateHolderScore)
--		-- self.Maid:add(self.UpdateHolderScore)
--	end
--end

function HotProperty:HandleCasePickup(Player)
	CaseFunctions.HandleCasePickup(self, "HotProperty", Player)
end

function HotProperty:DropCase(Ended)
	CaseFunctions.DropCase(self, "HotProperty", Ended)
end

function HotProperty:Spawn()
	local SpawnLocations = self.SpawnsFolder:GetChildren()
	local RandomSpawn = SpawnLocations[math.random(1, #SpawnLocations)]
	local SpawnCFrame = RandomSpawn.CFrame * CFrame.new(0, 1, 0)
	local TweenDuration = 5.5

	self.Case = self.CrateTemplate:Clone()
	self.Case.CFrame = SpawnCFrame
	self.Case.Parent = workspace.Visuals

	local CasePrompt = self.Case.ProximityPrompt

	task.wait(3)

	self.System.EventUtility:FireReliableVFX("WorldEvents/HotProperty", "SpawnCrate", self.Case, SpawnCFrame, TweenDuration)

	task.wait(TweenDuration)
	CasePrompt.Enabled = true

	self.Maid:add(task.delay(5, function()
		self.Case.Transparency = 0
	end))
end

function HotProperty:End(Winner)
	if not self.Active then return end;
	
	task.spawn(function()
		if Winner then
			self.System.EventUtility:Announce("World Event - Hot Property", `{Winner.Name} held the project the longest and won!`)
		else
			self.System.EventUtility:Announce("World Event - Hot Property", "No one held the project long enough to win.")
		end

		self.System.EventUtility:FireReliableVFX("WorldEvents/HotProperty", "End", Winner)
	end)

	task.spawn(function()
		if Winner then
			self.System.EventUtility:RewardRandomEmote(Winner)
		end
	end)

	if self.CaseHolder then
		self:DropCase(true)
	end

	if self.Case then
		self.Case:Destroy()
		self.Case = nil
	end;
	
	BaseEvent.End(self, Winner);
end

return HotProperty
