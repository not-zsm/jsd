

local MarketplaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local rateLimiter = require( replicatedStorage.modules.shared.Utilities.rateLimiter )
local connect = require( replicatedStorage.modules.network.connect )
local PhysicsService = game:GetService("PhysicsService")
local PolicyService = game:GetService("PolicyService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")
----------------------------------------------------------------------------------

local Remotes = replicatedStorage.remotes


local EventService = require( replicatedStorage.modules.shared.Utilities.EventService )
local Gamepasses = require( replicatedStorage.modules.shared.Game.Gamepasses )
local Job = require( replicatedStorage.modules.shared.Utilities.Job )
local Table = require( replicatedStorage.Packages.Table )


---------------------------------------------------------------------------------- 

local DefaultFriends = { 
	[1] = { Id = 141123572 }, 
	[2] = { Id = 7207821215 }, 
	[3] = { Id = 85042395 } 
}; -- Jimpee as a friend incase you have no friends 🌹 -- Now it's all of us! 🌹

local FriendRnd = Random.new();

---------------------------------------------------------------------------------- 

local LuaPlayer = {}
LuaPlayer.__index = LuaPlayer

local Character = require( script.Character )
local Replication = require( script.Replication )
local Data = require( script.Data )

----------------------------------------------------------------------------------

function LuaPlayer:Destroy()
	self.OnDestroyed:Fire()
	
	self.Job:Destroy()
	
	self.Replication:Destroy()
	self.Character:Destroy()
	
	if not self.IsNPC then
		self.Data:Destroy()
	end
end

function LuaPlayer:PlayerExists()
	return (self.Player.Parent ~= nil)
end
	
function LuaPlayer:_Init()
	if not self.IsNPC then
		self.Data = Data.new(self)
	end
	
	self.Replication = Replication.new(self)
	self.Character = Character.new(self)
	
	self.OnlineFriendTable = {};
	self.FriendTable = Table.clone(DefaultFriends);

	self.FriendTableReady = false;
	self.FriendTableLoading = false;
	
	if not self.IsNPC then
		self:BindRemotes();
	end;
	
	task.spawn(self.GetFriends, self, false);
end;

function LuaPlayer:GetRandomFriend(UseCache: boolean?)
	-- Prioritize online friends over non-online friends
	if math.random() < 0.5 then
		local OnlineFriends = self.OnlineFriendTable;
		
		if #OnlineFriends ~= 0 then
			return OnlineFriends[FriendRnd:NextInteger(1, #OnlineFriends)]
		end;
	end;
	
	local Friends = self:GetFriends(UseCache);
	
	if #Friends ~= 0 then
		return Friends[FriendRnd:NextInteger(1, #Friends)];
	end;
end;

function LuaPlayer:IsFriendsWith(UserId: number, Fast: boolean?): boolean
	if self.FriendTableReady then
		for _, Friend in self.FriendTable do
			if Friend.Id == UserId then
				return true;
			end;
		end;
	end;
	
	if not Fast then
		return self.Player:IsFriendsWith(UserId);
	end;
	
	return false;
end;

function LuaPlayer:GetFriendsQuota(Quota: number, UseCache: boolean?)
	local Friends = self:GetFriends(UseCache);
	
	local FriendQuota = {};
	local CurrentDefaultIndex = 0;
	
	for Index = 1, Quota do
		if Friends[Index] then
			table.insert(FriendQuota, Friends[Index]);
			
		elseif CurrentDefaultIndex < #DefaultFriends then
			CurrentDefaultIndex += 1;
			table.insert(FriendQuota, table.clone(DefaultFriends[CurrentDefaultIndex]));
			
		elseif #Friends > 0 then
			-- Recycle at the start of the friends table
			table.insert(FriendQuota, Friends[(Index - CurrentDefaultIndex) % #Friends + 1]);
			
		else
			-- Keep adding default friends if you have no friends 🌹
			CurrentDefaultIndex = 1;
			table.insert(FriendQuota, table.clone(DefaultFriends[1]));
		end;
	end;
	
	FriendRnd:Shuffle(FriendQuota);
	
	return FriendQuota;
end

function LuaPlayer:GetFriends(UseCache: boolean?)
	if self.IsNPC then
		return self.FriendTable;
	end;
	
	if UseCache then
		local Elapsed = 0;
		
		while self.FriendTableLoading and Elapsed < 5 do
			Elapsed += task.wait();
		end;
		
		if self.FriendTableReady then
			return self.FriendTable;
		end;
	end;
	
	self.FriendTableLoading = true;
	
	local Success, Page = pcall(Players.GetFriendsAsync, Players, self.UserId);

	if Success then
		self.FriendTableReady = false;
		table.clear(self.FriendTable);
		
		repeat
			local Info = Page:GetCurrentPage()

			for _, Friend in Info do
				table.insert(self.FriendTable, Friend)
			end

			if not Page.IsFinished then
				local AdvanceSuccess = pcall(Page.AdvanceToNextPageAsync, Page);
				
				if not AdvanceSuccess then
					break;
				end;
			end;

		until Page.IsFinished;
		
		-- No friends
		if #self.FriendTable == 0 then
			for _, Friend in DefaultFriends do
				table.insert(self.FriendTable, table.clone(Friend));
			end;
		end;
		
		self.FriendTableReady = true;
	end;
	
	self.FriendTableLoading = false;
	
	return self.FriendTable;
end

function LuaPlayer:HasAccessToBossDrop(Boss : string)
	local BossData = self.Data.Profile.Data.Bosses[Boss]

	if (BossData == nil) then
		return warn(Boss, "has no boss data")
	end

	return (BossData.Awarded or self.Is_Tester or self.Is_Contributor or self.Is_Adminstrator or self.Is_Developer or self.Is_Manager)
end

function LuaPlayer:BindRemotes()
	self.Job:Task(connect(network.friendsList, function(FriendIds: {string}, Player: Player)
		if self.Player ~= Player then return end;
		
		table.clear(self.OnlineFriendTable);
		
		for Index = 1, 20 do
			local UserId = tonumber( FriendIds[Index] );
			
			if UserId then -- and self:IsFriendsWith(UserId, true) then
				table.insert(self.OnlineFriendTable, { Id = UserId });
			end;
		end;
	end))
	
	self.Job:Task(connect(network.promptGamepass, function(Gamepass, Player)
		if self.Player ~= Player then return end;
		if typeof(Gamepass) ~= "string" then return end

		local GamepassTable : typeof(Gamepasses["Early Access"]) = Gamepasses[Gamepass]
		if (GamepassTable == nil) then return end

		if (rateLimiter.check(Player, "promptGamepass", 5) and not self.Data:HasGamepass(Gamepass)) then
			MarketplaceService:PromptGamePassPurchase(Player, GamepassTable.ID)
		end
	end))
end

function LuaPlayer:GetPing()
	if self.IsNPC then
		return 0
	end
	
	return (self.Player:GetNetworkPing() * 2)
end

----------------------------------------------------------------------------------

function LuaPlayer.new(ActualPlayer: Player)
	local self = setmetatable({}, LuaPlayer)
	
	self.Job = Job.new()

	self.Player = ActualPlayer
	self.PlayerName = ActualPlayer.Name
	self.Player:SetAttribute("Name", self.PlayerName)
	
	self.PendingCharacterName = nil
	
	self.IsNPC = not ActualPlayer:IsA("Player")
	
	self.UserId = self.IsNPC and -1 or ActualPlayer.UserId
	
	self.OnGroupRankFetched = self.Job:Task(EventService.new())
	self.OnPolicyInfoFetched = self.Job:Task(EventService.new())
	self.OnDestroyed = self.Job:Task(EventService.new())
	
	if not self.IsNPC and self:PlayerExists() then
		self.IsFounderAndLeadScripter = (ActualPlayer.UserId == 7207821215)

		task.spawn(function()
			local Success, Result = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, self.Player)

			if not Success then
				return warn("error while trying to get policy info on join:", Result)
			end
			
			self.PolicyInfo = Result
			self.OnPolicyInfoFetched:Fire()
		end)
		
		task.spawn(function()
			local Success, Result = pcall(self.Player.GetRankInGroup, self.Player, shared.Group)

			if not Success then
				warn("error while trying to get rank on join:", Result)
			end

			self.GroupRank = (Success and Result or 0)
			
			self.Is_Tester = (self.GroupRank == 61)
			self.Is_Contributor = (self.GroupRank == 62)
			self.Is_Adminstrator = (self.GroupRank == 64 or self.GroupRank == 190)
			self.Is_Manager = (self.GroupRank == 199 or self.GroupRank == 201)
			self.Is_Developer = (self.GroupRank == 71)
			
			self.OnGroupRankFetched:Fire()
		end)
		
		local ChatCooldown = false
		
		ActualPlayer.Chatted:Connect(function(Message)
			if not ChatCooldown then
				ChatCooldown = true
				
				if (#Message > 190) then
					ActualPlayer:Kick()
				end
				
				task.delay(0.5, function()
					ChatCooldown = false
				end)
			end
		end)
	end
	
	----------------------------------------

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(LuaPlayer)

return LuaPlayer