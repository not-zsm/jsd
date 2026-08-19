local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-----------------------------------------------------------------------------------

local Player = Players.LocalPlayer;

-----------------------------------------------------------------------------------

local Observer = require( ReplicatedStorage.Packages.Observer )
local Flight = require( script.Flight )

-----------------------------------------------------------------------------------

-- If you put this attribute on a Player, they will automatically be granted with flight. So dont call :grant directly.
local FlightAttribute = "HasFlight";

-----------------------------------------------------------------------------------

export type ClassFlightHandler = {
	__index: ClassFlightHandler;

	new: () -> FlightHandler;
	has_flight: (self: FlightHandler) -> boolean;
	grant: (self: FlightHandler) -> ();
	revoke: (self: FlightHandler) -> ();
	initialise: (self: FlightHandler) -> ();
};

export type FlightHandler = typeof(setmetatable({} :: {
	flight: Flight.Flight;

}, {} :: ClassFlightHandler));

-----------------------------------------------------------------------------------

local FlightHandler = {};
FlightHandler.__index = FlightHandler;

function FlightHandler.new()
	local self = setmetatable(
		{
			flight = nil;
		}, 
		FlightHandler);

	self:initialise();

	return self;
end;

-----------------------------------------------------------------------------------

function FlightHandler:has_flight()
	return Player:GetAttribute(FlightAttribute);
end

function FlightHandler:grant()
	if self.flight then
		self:revoke();
	end;
	
	self.flight = Flight.new(Player.Character);

	pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
		Title = "Flight",
		Text = "Use double jump to activate",
		Icon = "rbxassetid://4592292717";
	});
end

function FlightHandler:revoke()
	if self.flight then
		self.flight:destroy();
		self.flight = nil;
	end
end

function FlightHandler:initialise()
	if Player.Character and self:has_flight() then
		self:grant();
	end;

	Player:GetAttributeChangedSignal(FlightAttribute):Connect(function()
		if self:has_flight() then
			self:grant();
		else
			self:revoke();
		end;
	end);

	Player.CharacterAdded:Connect(function(character)
		if self:has_flight() then
			self:grant();
		end;
	end);
	
	Player.CharacterRemoving:Connect(function(character)
		self:revoke();
	end);
end;

-----------------------------------------------------------------------------------

table.freeze(FlightHandler);

return FlightHandler.new();