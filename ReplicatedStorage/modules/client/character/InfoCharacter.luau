local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatRemotes = ReplicatedStorage.Remotes.Combat;
local Signal = require( ReplicatedStorage.Packages.Signal )

local Characters = {};
Characters.List = {};
Characters.InfoReady = false;
Characters.OnReady = Signal.new();

CombatRemotes.SendCharacterInfo.OnClientEvent:Connect(function(CharacterInfo)
	table.clear(Characters.List);
	
	for Key, Value in CharacterInfo do
		Characters.List[Key] = Value;
	end;
	
	Characters.InfoReady = true;
	Characters.OnReady:Fire(Characters.List);
end);

---------------------------------------------------------------

local Main = {};

function Main.GetCharacters()
	return Characters.List;
end;

function Main.IsReady(): boolean
	return Characters.InfoReady;
end;

function Main.GetCharacterInfo(Character: string)
	if not Character then
		return {};
	end;

	return Characters.List[Character];
end;

function Main.WaitForCharacters(Timeout: number?)
	if not Characters.InfoReady then
		Characters.OnReady:Wait(Timeout);
	end;
	
	return Characters.List;
end;

function Main.OnCharactersReady(Callback)
	if Characters.InfoReady then
		task.spawn(Callback, Characters.List);
	else
		Characters.OnReady:Once(Callback);
	end;
end;

function Main.OnCharacterReady(Character: string, Callback)
	Main.OnCharactersReady(function()
		return Callback( Main.GetCharacterInfo(Character) );
	end);
end;

table.freeze(Main);

return Main;