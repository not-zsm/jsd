local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );

local InterfaceRemote = Unpacker.Remotes.Effects.ScreenInterface;

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Used to display an on-screen message or images.";
TagModifier.icon = 77840188181333;
TagModifier.color = Color3.fromRGB(206, 247, 255)
TagModifier.section = 3;
TagModifier.attribute_updates = {};
--TagModifier.signal_generator = true;
TagModifier.properties = {
	Text = {
		Order = 5,
		Default = "Hello World";
	};
	Image = {
		Order = 6,
		Default = "";
		AssetType = Enum.AssetType.Decal;
	};
	ScreenPosition = {
		Order = 7,
		Default = UDim2.new(0.5, 0, 0.35, 0);
	};
	ScreenSize = {
		Order = 8,
		Default = UDim2.new(0.4, 0, 0.025, 6);
	};
	AspectRatio = {
		Order = 4,
		Default = 0;
	};
	Style = {
		Order = 16,
		Default = "Black Backdrop";
		ValueList = { "Black Backdrop", "Plain", "Widget" };
	};
	OnClick = {
		Order = 17,
		Default = nil;
		Type = Type.Instance();
	};
	Transparency = {
		Order = 3,
		Default = 0;
	};
	Interactable = {
		Order = 10,
		Default = true;
	};
	Global = {
		Order = 9,
		Default = false;
	};
	ZIndex = {
		Order = 2,
		Default = 0
	};
	Identifier = {
		Order = 1,
		Default = "abc";
	};
	Tween = {
		Order = 12,
		Default = false;
		Shows = {"EasingTime", "EasingStyle", "EasingDirection"};
	};
	EasingStyle = {
		Order = 13,
		Default = Enum.EasingStyle.Linear;
		Hidden = true;
	};
	EasingDirection = {
		Order = 14,
		Default = Enum.EasingDirection.Out;
		Hidden = true;
	};
	EasingTime = {
		Order = 15,
		Default = 1;
		Hidden = true;
	};
	Remove = {
		Order = 11,
		Default = false;
		Hides = {};
	};
};

local function on_click_button(self, player: Player)
	local output = self.attributes:get("OnClick");
	
	if output then
		local list = InstanceModifier.get_modifiers(output);
		local signal = self:create_pulse{ self:get_combat(player) };
		
		for _, modifier in list do
			if modifier == self then
				continue;
			end;
			
			modifier:pulse(signal);
		end
	end
end

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.click_remote = Instance.new("RemoteEvent");
	self.click_remote.Archivable = false;
	self.click_remote.Name = "Click";
	self.click_remote.Parent = self.modifier;
	
	self.click_remote.OnServerEvent:Connect(function(player)
		if self.active_players[player] then
			on_click_button(self, player);
		end;
	end)
	
	self.active_players = {};
	
	self.maid:add(Players.PlayerRemoving:Connect(function(player)
		self.active_players[player] = nil;
	end))
	
	self.short_powered = true;
	
	return self;
end;

function TagModifier:pulse(signal)
	local players: {Player};
	
	if self.attributes:get("Global") then
		players = Players:GetPlayers();
	else
		players = signal:get_players();
	end
	
	local is_valid = true;
	
	if not self.part or not self.part.Parent then
		is_valid = false;
	end;
	
	for _, player in players do
		self.active_players[player] = true;
		
		if not is_valid then
			local builder = self.build_handler:get(player);
			
			if builder then
				builder:push_notification("warning", "Screen Interface modifier is not parented in a valid location and will not work", 3);
			end
		else
			InterfaceRemote:FireClient(player, self.modifier);
		end
	end;
end;

function TagModifier:destroy()
	table.clear(self.active_players);
	self.click_remote:Destroy();
	InstanceModifier.destroy(self);
end

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;