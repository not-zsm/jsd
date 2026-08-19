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
TagModifier.description = "Gives a set amount of points in the leaderboard.";
TagModifier.icon = 94805394043300;
TagModifier.color = Color3.fromRGB(255, 200, 34)
TagModifier.section = 9;
TagModifier.use_prompt = false;
TagModifier.properties = {
	ChangeValue = {
		Order = 2,
		Default = 10;
	};
	Name = {
		Order = 1,
		Default = "Cash";
	};
	Hidden = {
		Order = 3,
		Default = false,
	};
	GlobalVariable = {
		Order = 4,
		Default = false,
	};
};

local BannedNames = {
	["total kills"] = true;
	["kills"] = true;
	[SecretsName] = true;
};

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	
	return self;
end;

local function get_secrets_folder(leaderstats: Folder): Folder
	local secret = leaderstats:FindFirstChild(SecretsName);
	
	if not secret then
		secret = Instance.new("Folder");
		secret.Name = SecretsName;
		secret.Parent = leaderstats;
	end;
	
	return secret;
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

local function update_stat(leaderstats: Folder, data: any)
	local stat = get_stat(leaderstats, data.Name);

	if not stat then
		stat = Instance.new("NumberValue")
		assert(stat, "Stat was not created");

		stat:SetAttribute("PsuedoStat", true);
		stat.Name = data.Name;
		stat.Value = 0;
	end;

	assert(stat, "No Stat Value");

	if stat:GetAttribute("PsuedoStat") then
		if data.Hidden then
			stat.Parent = get_secrets_folder(leaderstats);
		else
			stat.Parent = leaderstats;
		end;

		stat.Value += data.ChangeValue;
	end;
end

function TagModifier:pulse(signal)
	local data = self.attributes:all();
	
	if BannedNames[ string.lower(data.Name) ] or time() < 5 then
		return signal:notify_builders("warning", `Unable to use name '{data.Name}' as it is reserved`, 5);
	end
	
	if data.GlobalVariable then
		update_stat(Unpacker.BuildTools.Variables, data);
	else
		for _, player: Player in signal:get_players() do
			local leaderstats = player:FindFirstChild("leaderstats");
			
			if leaderstats then
				update_stat(leaderstats, data);
			else
				warn(`No leaderstats folder exists in player {player.Name}, this folder must be created yourself.`);
			end;
		end;
	end;
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;