local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildTools = ReplicatedStorage.BuildTools;
local Packages = ReplicatedStorage.Packages;
--Packages.Parent = ReplicatedStorage;

local Shared = script.Shared;

local Unpacker = {};
Unpacker.Shared = Shared;
Unpacker.Packages = Packages;
Unpacker.Remotes = BuildTools.Remotes;
Unpacker.BuildTools = BuildTools;
Unpacker.Effects = BuildTools.Effects;
Unpacker.DefaultMap = workspace.Map.Model;

function Unpacker.get_character_from_font(font: string, character: string)
	return script.Fonts[font]:FindFirstChild(character);
end

function Unpacker.load()
	if Packages.Parent ~= ReplicatedStorage then
		Packages.Parent = ReplicatedStorage;
	end;
	
	if Shared.Parent ~= BuildTools then
		Shared.Parent = BuildTools;
	end;
end

function Unpacker.unload()
	--if Packages.Parent ~= script then
	--	Packages.Parent = script;
	--end;
	
	if Shared.Parent ~= script then
		Shared.Parent = script;
	end;
end

return Unpacker;