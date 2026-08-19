local BaseEvent = require( script.Parent );

local DeadDrop = setmetatable({}, BaseEvent);
DeadDrop.__index = DeadDrop

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
local Maid = require( ReplicatedStorage.Packages.Maid )

local CaseFunctions = require("../Modules/CaseFunctions");

function DeadDrop.new(...)
	local self = setmetatable(BaseEvent.new(...), DeadDrop)

	-- Settings
	self.Settings = {
		TimeUntilTracking = 15, -- Seconds
		EventDuration = 300 -- Seconds
	}

	-- Configuration
	self.SpawnsFolder = ServerStorage.EventAssets.CrateSpawns
	self.CrateTemplate = ServerStorage.EventAssets.Crate
	self.DealerNPC = workspace["NPC's"]["Black Market Dealer"]

	self.CaseHolderMaid = nil

	return self
end

function DeadDrop:Start()
	if self.Active then return end;
	
	BaseEvent.Start(self);
	
	-- Announce Dead Drop
	self.System.EventUtility:Announce("World Event - Dead Drop", "A Random Project has spawned somewhere on the map! Deliver it for a reward.")

	self:Spawn()

	self.Maid:add(self.Case.ProximityPrompt.Triggered:Connect(function(Player)
		local LuaPlayer, LuaCharacter = self.System.EventUtility:GetLuaPlayer(Player)

		if LuaCharacter.Combat:NotStunned() and Player.Character:FindFirstChild("Humanoid").Health > 0 then
			self:HandleCasePickup(Player)
		end
	end))

	local ProximityPrompt = self.DealerNPC.HumanoidRootPart.ProximityPrompt

	local ProximityConnection
	ProximityConnection = ProximityPrompt.Triggered:Connect(function(Player)
		if Player == self.CaseHolder then
			self.Maid:delete(ProximityConnection)
			-- ProximityConnection:Disconnect()
			self:End(self.CaseHolder)
		end
	end)

	self.Maid:add(ProximityConnection)

	local TimeUntilMarked = task.delay(self.Settings.TimeUntilTracking, function()
		if self.Case then
			self.System.EventUtility:FireReliableVFX("WorldEvents/DeadDrop", "MarkCrate", true, self.Case.Attachment, self.CaseHolder)
		end
	end)
	self.Maid:add(TimeUntilMarked)

	local TimerThread = task.delay(self.Settings.EventDuration, function()
		print("Ran out of time")
		self:End()
	end)
	self.Maid:add(TimerThread)
end

-- Handles the crate pickupy thingy
function DeadDrop:HandleCasePickup(Player : Player)
	CaseFunctions.HandleCasePickup(self, "DeadDrop", Player)
end

-- Drop the case
function DeadDrop:DropCase(Ended)
	CaseFunctions.DropCase(self, "DeadDrop", Ended)
end

-- Spawn Animation
function DeadDrop:Spawn()
	-- Spawn at random location
	local SpawnLocations = self.SpawnsFolder:GetChildren()

	local RandomSpawn = SpawnLocations[math.random(1, #SpawnLocations)]
	local SpawnCFrame = RandomSpawn.CFrame * CFrame.new(0, 1, 0)
	local TweenDuration = 5.5

	self.Case = self.CrateTemplate:Clone()
	self.Case.CFrame = SpawnCFrame
	self.Case.Parent = workspace.Visuals
	local CasePrompt = self.Case.ProximityPrompt

	task.wait(3)

	self.System.EventUtility:FireReliableVFX("WorldEvents/DeadDrop", "SpawnCrate", self.Case, SpawnCFrame, TweenDuration)

	-- Spawn Case
	task.wait(TweenDuration)
	CasePrompt.Enabled = true

	self.Maid:add(task.delay(5, function()
		self.Case.Transparency = 0
	end))
end

function DeadDrop:End(Winner : Player)
	if not self.Active then return end;
	
	task.spawn(function()
		-- Reward Winner
		if (Winner and Winner.Parent ~= nil) then
			self.System.EventUtility:Announce("World Event - Dead Drop", `{Winner.Name} has delivered the weapons crate and won!`)
		else
			self.System.EventUtility:Announce("World Event - Dead Drop", `The Dead Drop has expired — no one made the delivery in time.`)
		end

		self.System.EventUtility:FireReliableVFX("WorldEvents/DeadDrop", "End", Winner)
	end)

	task.spawn(function()
		if Winner then
			self.System.EventUtility:RewardRandomEmote(Winner)
		end
	end)

	-- Cleanup
	if self.CaseHolder then
		self:DropCase(true)
	end

	if self.Case then
		self.Case:Destroy()
		self.Case = nil
	end

	BaseEvent.End(self, Winner);
end

return DeadDrop