local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InstanceModifier = require( script.Parent.Parent );
local TagModifier = setmetatable({}, InstanceModifier);

local SecretsName = "__secret";

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Checks and carries pulses if amount of points in the leaderboard is met.";
TagModifier.icon = 94805394043300;
TagModifier.color = Color3.fromRGB(232, 255, 21)
TagModifier.section = 9;
TagModifier.use_prompt = false;
TagModifier.properties = {
	ReachValue = {
		Default = 20;
		Order = 2,
	};
	InvertReach = {
		Default = false;
		Order = 3;
	};
	Name = {
		Default = "Cash";
		Order = 1,
	};
	GlobalVariable = {
		Order = 4,
		Default = false,
	};
	Output = {
		Default = nil;
		Type = Type.Instance();
		Order = 5;
	};
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	self.pulse_on_powered = true;
	
	return self;
end

local function foreach_pulse(self, signal, chain)
	if not chain then chain = {}; end;
	
	for _, modifier in self:get_pulse_targets(chain) do
		modifier:pulse(signal, chain);
	end;
end;

local function get_stat(leaderstats: Folder, stat: string): ValueBase?
	local value_base = leaderstats:FindFirstChild(stat);

	if value_base then
		return value_base;
	end;
	
	local secrets_folder = leaderstats:FindFirstChild(SecretsName);

	if secrets_folder then
		return secrets_folder:FindFirstChild(stat);
	end;
	
	return nil;
end;

function TagModifier:pulse(signal, chain)
	local data = self.attributes:all();
	
	local reach_value: number = data.ReachValue;
	local invert_reach: boolean = data.InvertReach;
	
	local function check_stat(leaderstats: Folder, combats: {any})
		local stat = get_stat(leaderstats, data.Name);

		if stat and ( stat:IsA("NumberValue") or stat:IsA("IntValue") ) then
			if invert_reach and (stat.Value <= reach_value) then
				foreach_pulse(self, self:create_pulse(combats), chain)

			elseif not invert_reach and (stat.Value >= reach_value) then
				foreach_pulse(self, self:create_pulse(combats), chain)
			end
		end;
	end;
	
	if data.GlobalVariable then
		check_stat(Unpacker.BuildTools.Variables, signal:get_combats());
	else
		for _, combat in signal:get_combats() do
			local player: Player? = combat:get_player();
			
			if not player then
				continue;
			end;
			
			local leaderstats = player:FindFirstChild("leaderstats");
			
			if leaderstats then
				check_stat(leaderstats, {combat});
			else
				warn("No leaderstats folder exists in player", player.Name);
			end
		end;
	end;
end;

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;