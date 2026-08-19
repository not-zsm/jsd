local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local Input = Unpacker.Remotes.Input;

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Capture input";
TagModifier.icon = 438219158;
TagModifier.color = Color3.fromRGB(230, 131, 255)
TagModifier.section = 3;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Input = {
		Default = Enum.KeyCode.E,
	};
	Output = {
		Default = nil;
		Type = Type.Instance();
	};
	Sticky = {
		Default = false;
	};
};

type Input = Enum.UserInputType | Enum.KeyCode;

local function get_seated_player(self): Player?
	if self.part.Occupant then
		return Players:GetPlayerFromCharacter(self.part.Occupant:FindFirstAncestorOfClass("Model"));
	end;
	
	return nil;
end

local function input_began(self, player: Player, input: Input)
	self.input_down[input] = true;
	self:set_powering(true);
end

local function input_ended(self, player: Player, input: Input)
	self.input_down[input] = nil;
	self:set_powering(false);
end

local function update_occupant(self)
	local new_player = get_seated_player(self);
	local new_occupant = self.part.Occupant;
	
	if not new_occupant and self.current_player then
		for input in self.input_down do
			input_ended(self, self.current_player, input);
		end;
	end
	
	if self.current_occupant ~= new_occupant then
		if self.current_occupant then
			self:remove_humanoid_from_signal(self.current_occupant);
		end
		
		if new_occupant then
			self:add_humanoid_to_signal(new_occupant)
		end;
	end;
	
	self.current_occupant = new_occupant;
	self.current_player = new_player;
end;

local function update_seated(self)
	if not self.part then
		return warn("No part to bind seat keybinds to.");
	end;
	
	self.maid:add(Input.SeatKeyDown.OnServerEvent:Connect(function(player: Player, input: Input)
		if self.current_player == player and input == self.attributes:get("Input") then

			if self.attributes:get("Sticky") and self.input_down[input] then
				input_ended(self, player, input);
			else
				input_began(self, player, input);
			end;
		end
	end))

	self.maid:add(Input.SeatKeyUp.OnServerEvent:Connect(function(player: Player, input: Input)
		if self.current_player == player and input == self.attributes:get("Input") and not self.attributes:get("Sticky") then
			input_ended(self, player, input);
		end
	end))

	if self.part:IsA("Seat") or self.part:IsA("VehicleSeat") then
		update_occupant(self);

		self.maid:add(self.part:GetPropertyChangedSignal("Occupant"):Connect(function()
			update_occupant(self);
		end))
	end;
end

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	self.current_player = nil;
	self.input_down = {};
	
	task.defer(update_seated, self);
	
	return self;
end

TagModifier:rebase();
table.freeze(TagModifier);

Input.SeatKeyDown.OnServerEvent:Connect(function() end);
Input.SeatKeyUp.OnServerEvent:Connect(function() end);

return TagModifier;