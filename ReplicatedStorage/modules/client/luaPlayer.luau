local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--local Weather = require( ReplicatedStorage.modules.client.weather )

local Player = Players.LocalPlayer;
local Remotes = ReplicatedStorage.Remotes;

----------------------------------------------------------------------------------

local Animations = ReplicatedStorage.Animations

local Character = require( script.Parent.character )
local Replication = require( script.Parent.replication )

----------------------------------------------------------------------------------

local LuaPlayer = {}
LuaPlayer.__index = LuaPlayer

----------------------------------------------------------------------------------

function LuaPlayer:_Init()
	
	warn("LOADING CLIENT")
	
	local StartTime = os.clock()
	
	self:EditPlayerModule()
	
	self.Remotes = self.Player:WaitForChild("Remotes", 100)

	self.Replication = Replication.new(self)
	self.Character = Character.new(self)
	
	self.Replication:_Init();
	self.Character:_Init();
	
	task.delay(10, function()
		self:UpdateOnlineFriends();
		
		-- Updates the online friends every 25 minutes.
		while task.wait(1500) do
			self:UpdateOnlineFriends();
		end
	end);
	
	warn(`CLIENT LOADED, TOOK {os.clock() - StartTime} SECONDS`)
end

----------------------------------------------------------------------------------

function LuaPlayer:PromptGamepassPurchase(Gamepass : string)
	ReplicatedStorage.Remotes.PromptGamepassPurchase:FireServer(Gamepass)
end
	
function LuaPlayer:EditPlayerModule()
	local PlayerModule = self.PlayerScripts:WaitForChild("PlayerModule")

	local NewPopper = script.Parent.camera:WaitForChild("Popper");
	local NewCameraInput = script.Parent.camera:WaitForChild("CameraInput");
	
	local CameraInputSwapSuccess, CameraInputSwapResult = pcall(function()
		local OldCameraInput = PlayerModule
			:WaitForChild("CameraModule", 60)
			:WaitForChild("CameraInput", 60)

		NewCameraInput.Parent = OldCameraInput.Parent;
		OldCameraInput:Destroy();
	end)
		
	local PopperSwapSuccess, PopperSwapResult = pcall(function()
		local OldPopper = PlayerModule
			:WaitForChild("CameraModule", 60)
			:WaitForChild("ZoomController", 60)
			:WaitForChild("Popper", 60)

		NewPopper.Parent = OldPopper.Parent;
		OldPopper:Destroy();
	end)

	if not CameraInputSwapSuccess then
		warn("Camera Input module swap failed:", CameraInputSwapResult);
	end
	
	if not PopperSwapSuccess then
		warn("Popper module swap failed:", PopperSwapResult);
	end
	
	self.RobloxPlayerModuleObject = PlayerModule
	self.RobloxPlayerModule = require(PlayerModule)
end

function LuaPlayer:UpdateOnlineFriends()
	local Success, Friends = pcall(Player.GetFriendsOnline, Player, 20);
	
	if Success then
		local SimpleFriends: {string} = {};
		
		for _, Friend in Friends do
			table.insert(SimpleFriends, tostring(Friend.VisitorId));
		end;
		
		Remotes.UpdateFriendsList:FireServer(SimpleFriends);
	end;
end;

function LuaPlayer.new()
	local self = setmetatable({}, LuaPlayer)
	self.Player = Players.LocalPlayer

	if not self.Player then
		Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		
		self.Player = Players.LocalPlayer
	end
	
	self.Mouse = self.Player:GetMouse()
	self.PlayerGui = self.Player.PlayerGui
	self.PlayerScripts = self.Player.PlayerScripts

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	----------------------------------------
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(LuaPlayer)

return LuaPlayer