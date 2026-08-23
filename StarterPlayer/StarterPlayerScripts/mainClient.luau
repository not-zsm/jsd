--!strict
--[[
	mainClient

	One owner for everything the client starts, and for the UI.

	Before this there were fifteen LocalScripts under StarterPlayerScripts, most
	of them four lines of require-and-go, each deciding for itself when to run
	and none of them able to see the others. Startup order was whatever Roblox
	picked, nothing could be restarted, and there was no type to hold on to.

	A system is a table with a name and a Start. mainClient owns the list, starts
	them in order, isolates their failures, and hands back a typed object.

		local mainClient = require(script.Parent.mainClient)
		mainClient.Default():Start()

	The UI lives here too, as script.UI. clientCombat asks for one through
	UIFactory rather than reaching for a child of its own, so the menus sit with
	the rest of the client and combat holds a reference it was handed.

	Everything is typed and exported, so `Client:` autocompletes and a misspelled
	system is a type error rather than a silent no-op.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Job = require(ReplicatedStorage.modules.shared.Utilities.Job)
local clientCombat = require(ReplicatedStorage.clientCombat)

--------------------------------------------------------------------------------

--[[
	One startable piece of the client.

	`Start` receives the MainClient so a system can reach its siblings without a
	global. Anything it returns that needs cleaning up should go on the Job it is
	given -- MainClient destroys those on Stop.
--]]
export type System = {
	Name: string,

	--- Lower starts first. Systems without one run at 100, after the essentials.
	Priority: number?,

	--[[
		Start on its own thread rather than in line.

		Set it on anything that yields -- a WaitForChild, a Loaded wait, a loop
		that never returns. These were LocalScripts, which each got a thread for
		free; starting them in line would let one of them hold up every system
		behind it.
	--]]
	Async: boolean?,

	Start: (self: System, Client: MainClient, Cleanup: any) -> (),

	--- Optional. Called before the system's Job is destroyed.
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

--[[
	Starts every registered system, lowest priority first.

	A system that throws is reported and skipped rather than taking the rest of
	the client down with it -- which is the one thing the old LocalScripts got
	right by accident, since a script that errors does not stop its siblings.
--]]
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
				warn(`[MainClient] system "{System.Name}" failed to start: {Problem}`)
			end
		end

		if System.Async then
			Cleanup:Task(task.spawn(Run))
		else
			Run()
		end
	end
end

--[[
	Builds the player object, which builds the character, which builds combat --
	and combat asks UIFactory for the UI on the way. Was a second entry
	LocalScript sitting beside this one deciding its own startup order.
--]]
function MainClient:StartPlayer()
	local Replicator = ReplicatedStorage.modules.shared.movementReplicator
	require(Replicator:WaitForChild("ClientReplicator", 100))

	require(ReplicatedStorage.modules.client.luaPlayer).new()

	local DonationBoard = ReplicatedStorage:WaitForChild("DonationBoardClient", 100)

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

--[[
	Every system shipped with the framework, in one place.

	A game adds its own with `Client:Add(require(...))` before calling Start.
--]]
function MainClient.Default(): MainClient
	local Client = MainClient.new()

	clientCombat.UIFactory = function(Combat)
		return require(script.UI).new(Combat)
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
