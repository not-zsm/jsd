local EventSystem = {}
EventSystem.__index = EventSystem

-- Services
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Whitelist = require( ReplicatedStorage.Modules.Shared.Game.Whitelist )

---- Events with probabilities
--if RunService:IsStudio() then
--	EventSystem.Events = {
--		["InvincibleBoss"] = 100,
--	}
--else
--	EventSystem.Events = {
--		["DeadDrop"] = 25,
--		["HotProperty"] = 25,
--		["NewWorld"] = 50,
--	}
--end

local Date
Date = os.date("*t")

local IsHalloween = (Date.day == 31 and Date.month == 10)

EventSystem.Events = {
	["DeadDrop"] = 25,
	["HotProperty"] = 25,
	--["NewWorld"] = 25, still WIP
	["InvincibleBoss"] = 25,
}

-- Utility
local function Format(Int)
	return string.format("%02i", Int)
end

local function ConvertToHMS(Seconds)
	local Minutes = (Seconds - Seconds % 60) / 60
	Seconds = Seconds - Minutes * 60
	local Hours = (Minutes - Minutes % 60) / 60
	Minutes = Minutes - Hours * 60
	return Format(Hours) .. ":" .. Format(Minutes) .. ":" .. Format(Seconds)
end;


-- Initialize the Event System
function EventSystem.new()
	local self = setmetatable({}, EventSystem)
	
	self.EventHandlers = {};
	self.ActiveEvents = {};
	
	self.LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
	self.LuaPlayers = self.LuaPlayerList.LuaPlayers
	
	self.EventUtility = require( script.EventUtility ).new(self)

	-- Check handlers for each event
	for EventName, _ in pairs(EventSystem.Events) do
		local HandlerModule = script.BaseEvent:FindFirstChild(EventName);
		
		if not HandlerModule then
			warn(`{EventName} Event Handler not found.`);
		end;
	end;
	
	-- Load handlers for each event
	for _, HandlerModule in script.BaseEvent:GetChildren() do
		self.EventHandlers[HandlerModule.Name] = require(HandlerModule)
	end;

	local function StartRandomEvent()
		if self:IsEventActive() then
			warn("Did not start random event, an event is already active.");
		else
			self:StartRandomEvent();
		end;
	end;
	
	-- Auto event loop (you can modify or remove this)
	task.spawn(function()
		if RunService:IsStudio() then
			task.wait(15);
			self:StartRandomEvent();
		end;
		
		local EventInterval = (25 * 60) -- Every 25 minutes
		
		while true do
			local Time = os.time();
			local Date = os.date("!*t", Time);
			local SecondsOfDay = Date.hour * 3600 + Date.min * 60 + Date.sec;
			local Seconds = EventInterval - (SecondsOfDay % EventInterval)
			
			print(`Next event in: {ConvertToHMS(Seconds)} ({Seconds} Seconds)`)
			
			task.wait(Seconds)
			task.spawn(StartRandomEvent);
		end;
	end);
	
	task.spawn(function()
		MessagingService:SubscribeAsync("StartWorldEvent", function(Message)
			self:StartEvent( Message.Data or self:GetRandomEvent() );
		end)
	end)
	
	task.spawn(function()
		self:UpdateControlledEvents();
	end);
	
	Whitelist.on_data_changed:Connect(function()
		self:UpdateControlledEvents();
	end)
	
	-- Listen For Events
	ReplicatedStorage.Remotes.WorldEvents.StartEvent.Event:Connect(function(EventName, Level: string?)
		if Level and ( Level ~= "Owner" and EventName == "MeatyMeteor" ) then
			return
		end;
		
		if Level and ( Level ~= "Owner" and self:IsEventActive() ) then
			return warn("Did not start random event, an event is already active.");
		end;
		
		if EventName then
			self:StartEvent(EventName)
		else
			self:StartRandomEvent();
		end;
	end);
	
	ReplicatedStorage.Remotes.WorldEvents.StopEvent.Event:Connect(function()
		self:EndEvent()
	end);

	return self;
end;

function EventSystem:UpdateControlledEvents()
	local world_events = Whitelist.get("World Events Enabled") or {};

	if RunService:IsStudio() then
		print("Updated Controlled Events:", world_events);
	end;
	
	if world_events.MeatyMeteor  == true then
		EventSystem.Events.MeatyMeteor = if IsHalloween then 15 else 1;
	else
		EventSystem.Events.MeatyMeteor = nil;
	end;
end;

function EventSystem:GetRandomEvent(IgnoreActive: boolean?)
	local EventPool = EventSystem.Events;
	
	if not IgnoreActive then
		EventPool = table.clone(EventSystem.Events);
		
		for Event in self.ActiveEvents do
			EventPool[Event.Name] = nil;
		end;
	end;
	
	local TotalWeight = 0;

	for _, Probability in EventPool do
		TotalWeight += Probability
	end

	local RandomWeight = Random.new():NextNumber() * TotalWeight
	local CurrentWeight = 0

	for Event, Probability in EventPool do
		CurrentWeight += Probability;
		
		if RandomWeight <= CurrentWeight then
			return Event;
		end;
	end;
end

-- Starts a random event
function EventSystem:StartRandomEvent()
	local EventName = self:GetRandomEvent();
	
	if not EventName then
		return warn("Unable to start any event.");
	end;

	self:StartEvent(EventName);
end;

function EventSystem:GetActiveEvent(EventName: string)
	for Event in self.ActiveEvents do
		if Event.Name == EventName then
			return Event;
		end;
	end;
	
	return nil;
end

function EventSystem:IsEventActive(EventName: string?): boolean
	if not EventName then
		return next( self.ActiveEvents ) ~= nil;
	end;
	
	return self:GetActiveEvent(EventName) ~= nil;
end;

-- Starts a specified event
function EventSystem:StartEvent(EventName: string, Forced: boolean?)
	if not Forced and self:IsEventActive(EventName) then
		return warn(`Event {EventName} is already active.`);
	end;

	local Handler = self.EventHandlers[EventName];
	
	if Handler then
		local NewEvent = Handler.new(self);
		
		self.ActiveEvents[NewEvent] = true;
		
		NewEvent.Ended:Once(function()
			self.ActiveEvents[NewEvent] = nil;
			NewEvent:Destroy();
		end)
		
		NewEvent.Name = EventName;
		NewEvent:Initialise();
		NewEvent:Start();
		
		return NewEvent;
	else
		warn(`No handler found for event: {EventName}`)
	end
end

-- Ends the current event
function EventSystem:EndEvent(EventName: string?, ...)
	local Event = next( self.ActiveEvents );
	
	if EventName then
		Event = self:GetActiveEvent(EventName);
	end;
	
	if Event then
		return Event:End(...);
	end;
end

return EventSystem.new()
