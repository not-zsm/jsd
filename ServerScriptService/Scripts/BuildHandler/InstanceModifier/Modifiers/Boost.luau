local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local CombatRemotes = ReplicatedStorage.Remotes.Combat;

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Change a player's speed and jump";
TagModifier.icon = 16181398272;
TagModifier.color = Color3.fromRGB(19, 255, 255)
TagModifier.section = 3;
TagModifier.properties = {
	WalkSpeed = {
		Order = 1,
		Default = 16;
	};
	JumpPower = {
		Order = 2,
		Default = -1;
	};
	Multiply = {
		Order = 3,
		Default = false;
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end

function TagModifier:pulse(signal)
	local data = self.attributes:all();
	
	for _, combat in signal:get_combats() do
		local humanoid = combat:get_humanoid();
		local player = combat:get_player();
		
		if humanoid and humanoid.RootPart then
			if not player then
				if data.WalkSpeed >= 0 then
					if data.Multiply then
						humanoid.WalkSpeed *= data.WalkSpeed;
					else
						humanoid.WalkSpeed = data.WalkSpeed;
					end
				end;
			else
				if data.WalkSpeed >= 0 then
					if data.Multiply then
						CombatRemotes.TimesSpeed:FireClient(player, humanoid, data.WalkSpeed);
					else
						CombatRemotes.SetSpeed:FireClient(player, humanoid, data.WalkSpeed);
					end
				end;
			end;
			
			if data.JumpPower >= 0 then
				if data.Multiply then
					humanoid.JumpPower *= data.JumpPower;
				else
					humanoid.JumpPower = data.JumpPower;
				end
			end;
		end;
	end;
end;

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;