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
TagModifier.description = "Capture movement input";
TagModifier.icon = 10881676048;
TagModifier.color = Color3.fromRGB(175, 84, 255)
TagModifier.section = 3;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Right = {
		Order = 2,
		Default = nil;
		Type = Type.Instance();
	};
	Left = {
		Order = 4,
		Default = nil;
		Type = Type.Instance();
	};
	Front = {
		Order = 1,
		Default = nil;
		Type = Type.Instance();
	};
	Back = {
		Order = 3,
		Default = nil;
		Type = Type.Instance();
	};
	OnSeated = {
		Order = 5,
		Default = nil;
		Type = Type.Instance();
	};
	OnUnseated = {
		Order = 6,
		Default = nil;
		Type = Type.Instance();
	};
};

type Input = Enum.UserInputType | Enum.KeyCode;

local function get_seated_player(self): Player?
	if self.part.Occupant then
		return Players:GetPlayerFromCharacter(self.part.Occupant:FindFirstAncestorOfClass("Model"));
	end;
	
	return nil;
end

local function pulse_thingit(self, instance: Instance): ()
	local targets = InstanceModifier.get_pulse_targets_of(self, instance);
	local pulse = self:create_target_pulse();

	for _, modifier in targets do
		modifier:pulse(pulse);
	end;
end;

local function update_occupant(self): ()
	local new_player = get_seated_player(self);
	local new_occupant = self.part.Occupant;
	
	if self.current_occupant ~= new_occupant then
		if self.current_occupant then
			local instance = self.attributes:get("OnUnseated");

			if instance then
				pulse_thingit(self, instance);		
			end;
			
			self:remove_humanoid_from_signal(self.current_occupant);
		end

		if new_occupant then
			self:add_humanoid_to_signal(new_occupant);
			
			local instance = self.attributes:get("OnSeated");

			if instance then
				pulse_thingit(self, instance);		
			end;
		end;
	end;
	
	self.current_occupant = new_occupant;
	self.current_player = new_player;
	
	if new_player then
		self:set_powering(true);
	else
		self:set_powering(false);
	end
end;

local function bind_to_part(self)
	self.maid:add(Input.SeatMove.OnServerEvent:Connect(function(player: Player, move_vector: Vector3)
		if self.current_player ~= player then return end;

		local axis_output_front: string = "";
		local axis_output_right: string = "";

		if move_vector.Z < -0.25 then
			axis_output_front = "Front";

		elseif move_vector.Z > 0.25 then
			axis_output_front = "Back";
		end;

		if move_vector.X < -0.25 then
			axis_output_right = "Left";

		elseif move_vector.X > 0.25 then
			axis_output_right = "Right";
		end;

		if self.current_front_axis ~= axis_output_front or self.current_right_axis ~= axis_output_right then
			self.current_front_axis = axis_output_front;
			self.current_right_axis = axis_output_right;

			self:update_powering_source();
		end;
	end))

	if self.part and ( self.part:IsA("Seat") or self.part:IsA("VehicleSeat") ) then
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
	
	task.defer(bind_to_part, self)
	
	return self;
end;

local function merge(table1, table2)
	return table.move(table2, 1, #table2, #table1 + 1, table1);
end;

function TagModifier:get_pulse_targets(chain)
	local targets = {};
	local data = self.attributes:all();
	
	if data[self.current_front_axis] then
		merge(targets, self:get_pulse_targets_of(data[self.current_front_axis], chain));
	end;
	
	if data[self.current_right_axis] then
		merge(targets, self:get_pulse_targets_of(data[self.current_right_axis], chain));
	end;
	
	return targets;
end;

TagModifier:rebase();
table.freeze(TagModifier);

Input.SeatMove.OnServerEvent:Connect(function() end);

return TagModifier;