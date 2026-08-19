-- This ensures all connections are disconnected (I.E UserInputService connections)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Build = require( ReplicatedStorage.BuildTools.Build );

local BuildTools = ReplicatedStorage:WaitForChild("BuildTools");
local BuildShared = BuildTools:WaitForChild("Shared");

local BuildModule = require(BuildShared.Client.BuildTools);

local GUI = script:WaitForChild("GUI");

local function Initialise()
	local Object = BuildModule.new(GUI.Value);

	local function DestroyObject()
		Object:destroy();
		Object = nil;

		task.defer(script.Destroy, script);
	end

	GUI.Changed:Connect(DestroyObject);

	Build.Bindables.Toggle.Event:Connect(function(value: boolean)
		Object:toggle_ui(value);
	end)
end

local Success, Err = pcall(Initialise);

if not Success then
	warn("Error while initialising Build Tools:", Err);
	
	if GUI.Value then
		GUI.Value:Destroy();
		GUI.Value = nil;
	end;
	
	script:Destroy();
else
	print("[Build Tools]: Loaded successfully.");
end;