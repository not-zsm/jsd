local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--local Weather = require( ReplicatedStorage.Modules.Weather )

local Player = Players.LocalPlayer;
local Remotes = ReplicatedStorage.Remotes;

----------------------------------------------------------------------------------

local Animations = ReplicatedStorage.Animations
local Modules = ReplicatedStorage.Modules

local Character = require( script.Character )
local Replication = require( script.Replication )

----------------------------------------------------------------------------------

local LuaPlayer = {}
LuaPlayer.__index = LuaPlayer

----------------------------------------------------------------------------------

function LuaPlayer:_Init()

	--warn([[
	
	
	--"Jump Showdown"
	
	--Most recent update log:

	--- NEW MOVE FOR UNWANTED GOD'S ULTIMATE 
	--  - Rock Throw

	--- FINISHED UNHINGED ESPER'S ULTIMATE
	--  - Carnal Revolution

	--- NEW LIMITED EMOTE 
	--  - Love Train

	--- sweep changes
	--  - damage: 7 - 5
	--  - red (air variant) damage: 10 - 7
	--  - patched extending it from normal variant (not ragdolled one)

	--- you can now evasive out of blink strike (tectonic control variant) push back

	--- accelerator cd changes
	--  - tectonic control: 19 - 21
	--  - accelerated punishment: 20 - 18
	--  - soundwave punch: 12: 15

	--- improved welding with effects like arm trails, accelerator's wings, etc (was very jittery before)
	--- improved universal crater smoke
	--- added tile destruction setting (since it can lag a little)
	--- fixed tile's not destructing, having tile split geometry setting off will just do a simple split
	--- fixed not being able to change emotes on mobile or console
	--- fixed other glitches

	--(next update will be massive, will include kratos being free and some other character..... 🔪 )
	
	--]])
	
	--warn([[


	--how to report glitches properly

	--step 1:  
	
	--]])
	
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

	local NewPopper = script.Camera:WaitForChild("Popper");
	local NewCameraInput = script.Camera:WaitForChild("CameraInput");
	
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