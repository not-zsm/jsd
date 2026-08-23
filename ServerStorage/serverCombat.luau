local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ServerStorage = game:GetService("ServerStorage")
local IsStudio = RunService:IsStudio()
print("is studio:", IsStudio)

local function StudioPrint(...)
	if IsStudio then
		print(...)
	end
end

----------------------------------------------------------------------------------

local Remotes = replicatedStorage.Remotes

local CombatRemotes = Remotes.Combat

local UIRemotes = CombatRemotes.UI

local Shared = replicatedStorage.modules.shared
local SharedUtilities = Shared.Utilities

----------------------------------------------------------------------------------

local BaseAttack = require( script.Attacks.BaseAttack ) 
local Passives = require( script.Passives )

----------------------------------------------------------------------------------

local Preloading = require( ServerStorage.modules.preloading )

local Job = require( SharedUtilities.Job )
local EventService = require( SharedUtilities.EventService )
local Utility = require( SharedUtilities.Utility )
local AenoirUtil = require( SharedUtilities.Utility.AenoirUtil )
local NumberStack = require( SharedUtilities.NumberStack )

local Gamepasses = require( Shared.Game.Gamepasses )
local Velocity = require( Shared.Game.Velocity )

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

local Whitelist = require( replicatedStorage.modules.shared.Game.Whitelist )
local info = require( replicatedStorage.info )
local AnimationProxy = require( script.AnimationProxy )

----------------------------------------------------------------------------------

local MovementReplicator = require( ServerStorage.modules.MovementReplicator )
local MovementReplicatorSettings = require( replicatedStorage.modules.shared.movementReplicator.Settings )

----------------------------------------------------------------------------------

local LuaPlayerList = require( ServerStorage.modules.LuaPlayerList )
local CommandHandler = require( ServerStorage.modules.CommandHandler )

local RemoteRateLimiter = require( ServerStorage.modules.Utility.RemoteRateLimiter )

----------------------------------------------------------------------------------

local Combat = {}
Combat.__index = Combat
Combat.Info = {};

----------------------------------------------------------------------------------

local AttackModuleCache = {};
local CharacterModuleCache = {};
local AttackFunctionModuleCache = {};

local AttackList = script.Attacks.List
local CharacterList = script.Parent.characterData;
local AttackFunctionList = script.AttackFunctions;

local XZAxis = Vector3.new(1, 0, 1);

local DefaultAccessibleCharacterSettings = {
	IncludeWorldEvents = false;
	RespectSkillBuilder = false;
};

local DefaultAccessibleAttackSettings = {
	RespectSkillBuilder = false;
	IncludeUsing = false;
	IncludeVaulted = false;
	ReturnHashmap = false;
};

----------------------------------------------------------------------------------

function Combat:Destroy()
	StudioPrint("removed combat", self.LuaPlayer.PlayerName)
	task.spawn(Preloading.Remove, self.LuaPlayer.Player, replicatedStorage.Animations.Global)

	if not self.LuaPlayer.IsNPC then
		task.spawn(self.AwardKillToHighestDamager, self, "Left")
	end

	self.Job:Destroy()

	self.Actions:Destroy()
	self.Mouse:Destroy()
	self.Projectiles:Destroy()

	for _, Attack in self.Attacks do
		Attack:Destroy()
	end;
end

----------------------------------------------------------------------------------

function Combat:_Init()

	self.Hitbox = require( script.Hitbox ).new(self)
	self.Ragdoll = require( script.Ragdoll ).new(self)
	self.Actions = require( script.Actions ).new(self)
	self.Mouse = require( script.Mouse ).new(self)
	self.Projectiles = require( script.Projectiles ).new(self)


	task.defer(self.ConnectHumanoidAvailability, self)

	self:CreateAttack("M1", Enum.UserInputType.MouseButton1)

	self:CreateAttack("Block", Enum.KeyCode.F)
	self:CreateAttack("Ultimate", Enum.KeyCode.G)

	self:CreateAttack("Dash", Enum.KeyCode.Q)
	self:CreateAttacks({"Vault", "WallJump"}, Enum.KeyCode.W)

	if self.LuaPlayer.IsNPC and self.LuaPlayer.Player:GetAttribute("Character") then
		self:SetCharacter(self.LuaPlayer.Player:GetAttribute("Character"))
	end

	if not self.LuaPlayer.IsNPC then
		self:SendCharacterInformation();

		self.Job:Task(Whitelist.on_data_changed:Connect(function()
			--local Was_Intruder = self:ResetCurrentCharacterIfNotAllowed()

			if not self:CanUseCharacter(self.CurrentCharacter.Name) and not self.IsInvincibleFromWorldEvent and not self.IsMeatyMichaelFromWorldEvent then

				if self.LuaPlayer.Data and self.LuaPlayer.Data.Profile then
					self.LuaPlayer.Data.Profile.Data.CurrentCharacter = "Invincible"
				end

				self:SetCharacter("Invincible")
			end;
		end))
	end
end

-----------------------------------------------------------------------------------

--function Combat:HasAccessToDonatorCharacter(Whitelist : {})
--	return self.LuaPlayer.Player:HasTag("DonationCharacterAccess") or (Whitelist and table.find(Whitelist, self.LuaPlayer.UserId))
--end

function Combat:SendCharacterInformation()
	--if true then return end;

	if not Combat.Info.Characters then
		Combat.Info.Characters = {};

		for _, Item in CharacterList:GetChildren() do
			local Character = require(Item);
			local Info = {
				DisplayName = Character.DisplayName or Item.Name,
				Icon = Character.Icon,
				StandName = Character.StandName,
				PrivateServerPlusOnly = Character.PrivateServerPlusOnly,
				DevOnly = Character.DevOnly,
				Attacks = Character.Attacks;
			};

			if Character.Ultimate then
				Info.Ultimate = {
					Name = Character.Ultimate.Name,
					Color = Character.Ultimate.Color,
					Attacks = Character.Ultimate.Attacks,
				};
			end;

			Combat.Info.Characters[Item.Name] = Info;
		end;
	end;

	local Available = {};

	for Name, Info in Combat.Info.Characters do
		if self:CanUseCharacter(Name) then
			Available[Name] = Info;
		end;
	end;

	network.characterInfo.sendTo(Available, self.LuaPlayer.Player);
end;

type FailToUseCharacterReason = "No Character" | "Early Access" | "Private Servers" | "Owner" | "Whitelist" | "Boss Drop" | "World Event";

--[[
	What the client reports about its own movement and input.

	These were six remote handlers wired per player in _Init, each opening with
	the same identity check. The networker resolves the sender to this object,
	so the checks went with the transport.
--]]
function Combat:OnClientLanded()
	self.ClientJumping = false
	self.ClientLanded:Fire()
end

function Combat:OnClientJumped()
	self.ClientJumping = true
	self.ClientJumped:Fire()
end

function Combat:SetSpaceHeld(Held : boolean)
	if not self.LuaCharacter.HumanoidAlive then return end

	self.SpaceHeld = Held
	self.OnSpaceStateChanged:Fire(Held)
end

function Combat:SetAirState(State : string)
	if not self.LuaCharacter.HumanoidAlive then return end

	self.AirState = State
	self.OnAirStateChanged:Fire(State)
end

function Combat:SetDevice(Device : string)
	if Device ~= "Touch" and Device ~= "Controller" and Device ~= "Keyboard" then return end

	self.CurrentDevicePlayingOn = Device
end

function Combat:OnDashProximity()
	if not self.LuaCharacter.HumanoidAlive then return end

	for _, Attack in self.Attacks do
		if (Attack.Available and Attack.OnDashProximityReceived ~= nil) then
			Attack.OnDashProximityReceived:Fire()
		end
	end
end

function Combat:SwitchCharacter(Character : string, IconId : string?)
	if self.SwitchCooldown then return end

	if shared.IsRankedPlace and IconId then
		self.LuaPlayer.PendingCharacterName = Character

		if IconId then
			Remotes.Ranked.UpdateSelectionDisplay:FireAllClients(self.LuaPlayer.Player, IconId)
		end

		return 
	end

	local CharacterModule = self:GetCharacterModule(Character);

	if not CharacterModule then
		-- Invalid character, do nothing.
		warn(`Unable to switch to character '{Character}' as it does not exist`)
		return;
	end;

	local CharacterInfo = require(CharacterModule :: any)
	local Switched = false

	local Profile = self.LuaPlayer.Data.Profile
	local CanUse: boolean, FailReason: FailToUseCharacterReason = self:CanUseCharacter(Character);

	if CanUse then
		if Switched or self.InCombat or self:IsStunned() then 
			return 
		end

		Switched = true

		if Profile then
			Profile.Data.CurrentCharacter = CharacterModule.Name
		end

		self.LuaCharacter:Respawn()
	else
		-- Can't use character :(
		if FailReason == "Early Access" then
			MarketplaceService:PromptGamePassPurchase(self.LuaPlayer.Player, Gamepasses["Early Access"].ID);
		end;
	end;

	--if CharacterInfo.EarlyAccess then
	--	local OwnsEarlyAccess = self.LuaPlayer.Data:HasGamepass("Early Access") or self:OwnsEarlyAccess()

	--	if OwnsEarlyAccess then
	--		Switch()
	--	else
	--		MarketplaceService:PromptGamePassPurchase(self.LuaPlayer.Player, Gamepasses["Early Access"].ID)
	--	end

	--elseif CharacterInfo.PrivateServerPlusOnly then
	--	--local Level = CommandHandler:GetPermission(self.LuaPlayer.Player)

	--	--if Level and Level < 3 then 

	--	local Level = CommandHandler:GetPermission(self.LuaPlayer.Player)

	--	if Level == "PS+" or Level == "Owner" then 
	--		Switch()
	--	end

	--elseif CharacterInfo.OwnerOnly then
	--	if self:IsOwner() then 
	--		Switch()
	--	end

	--elseif CharacterInfo.GitHubWhitelist or CharacterInfo.DonatorAccess then

	--	if (CharacterInfo.DonatorAccess and self.LuaPlayer.Player:HasTag("DonationCharacterAccess")) then
	--		Switch()
	--	else
	--		local Permitted = Whitelist.is_permitted(self.LuaPlayer.UserId, CharacterInfo.GitHubWhitelist)

	--		if Permitted then
	--			Switch()
	--		end
	--	end

	--	--elseif CharacterInfo.Whitelist or CharacterInfo.DonatorAccess then
	--	--	if self:HasAccessToDonatorCharacter(CharacterInfo.Whitelist) then 
	--	--		Switch()
	--	--	end 

	--elseif CharacterInfo.Whitelist then

	--	if table.find(CharacterInfo.Whitelist, self.LuaPlayer.UserId) then 
	--		Switch()
	--	end 

	--	--elseif CharacterInfo.DonatorAccess and not Switched then
	--	--	if self.LuaPlayer.Player:HasTag("DonationCharacterAccess") then
	--	--		print("switch cause of donator access")
	--	--		Switch()
	--	--	end

	--elseif CharacterInfo.BossDrop then
	--	if self:IsOwner() or self.LuaPlayer:HasAccessToBossDrop(CharacterInfo.BossDrop) then
	--		Switch()
	--	end
	--else
	--	Switch()
	--end

	if Switched then
		self.SwitchCooldown = true

		task.delay(1, function()
			self.SwitchCooldown = false
		end)
	end
end

function Combat:CanUseCharacter(Name: string, Settings): (boolean, FailToUseCharacterReason?)
	local Module = self:GetCharacterModule(Name);

	if not Module then
		return false, "No Character";
	end;

	local Settings = Settings or DefaultAccessibleCharacterSettings;
	local CharacterInfo = require(Module :: any);

	if Settings.RespectSkillBuilder and CharacterInfo.DisableInSkillBuilder then
		return false, "Skill Builder";
	end;

	local Level = CommandHandler:GetPermission(self.LuaPlayer.Player)

	if Level == "GOB" then
		print("GOB!")
		return true
	end

	if CharacterInfo.DevOnly then
		return (table.find(info.theBigFour, self.LuaPlayer.UserId) ~= nil), "Dev Only";
	end;

	if CharacterInfo.EarlyAccess then
		local OwnsEarlyAccess = self.LuaPlayer.Data:HasGamepass("Early Access") or self:OwnsEarlyAccess()

		if OwnsEarlyAccess then
			return true;
		else
			return false, "Early Access";
		end

	elseif CharacterInfo.PrivateServerPlusOnly then
		if (Level == "PS+" or Level == "Owner") then 
			return true;
		end;

		return false, "Private Servers";

	elseif CharacterInfo.OwnerOnly then
		if self:IsOwner() then 
			return true;
		end;

		return false, "Owner";

	elseif Settings.IncludeWorldEvents and CharacterInfo.InWorldEvent then
		return true, "World Event";

	elseif CharacterInfo.GitHubWhitelist or CharacterInfo.DonatorAccess then

		if (CharacterInfo.DonatorAccess and self.LuaPlayer.Player:HasTag("DonationCharacterAccess")) then
			return true;
		else
			local Permitted = Whitelist.is_permitted(self.LuaPlayer.UserId, CharacterInfo.GitHubWhitelist)

			if Permitted then
				return true;
			end;
		end;

		return false, "Whitelist";

	elseif CharacterInfo.Whitelist then

		if table.find(CharacterInfo.Whitelist, self.LuaPlayer.UserId) then 
			return true;
		end;

		return false, "Whitelist";

	else
		return true;
	end;
end;


-- Gives a list of every character that can be accessed by this combat.
function Combat:GetListOfAccessibleCharacters(Settings): {string}
	local Settings = Settings or DefaultAccessibleCharacterSettings;
	local AccessibleCharacters = {};

	for _, Module in CharacterList:GetChildren() do
		if self:CanUseCharacter(Module.Name, Settings) then
			table.insert(AccessibleCharacters, Module.Name);
		end;
	end;

	return AccessibleCharacters;
end


-- Gives a list of every attack that can be accessed by this combat.
function Combat:GetListOfAccessibleAttacks(Settings): {string}
	local Settings = Settings or DefaultAccessibleAttackSettings;
	local AttacksToAdd = {};

	for _, CharacterName in self:GetListOfAccessibleCharacters(Settings) do
		local CharacterInfo = require(self:GetCharacterModule(CharacterName) :: any);

		if Settings.RespectSkillBuilder and CharacterInfo.DisableInSkillBuilder then
			continue;
		end;

		if Settings.IncludeUsing and CharacterInfo.UsingAttacks then
			for _, Name in CharacterInfo.UsingAttacks do
				AttacksToAdd[Name] = true;
			end;
		end;

		if Settings.IncludeVaulted and CharacterInfo.VaultedAttacks then
			for _, Name in CharacterInfo.VaultedAttacks do
				AttacksToAdd[Name] = true;
			end;
		end

		for Name in CharacterInfo.Attacks do
			AttacksToAdd[Name] = true;
		end;

		if CharacterInfo.Ultimate and CharacterInfo.Ultimate.Attacks then
			for Name in CharacterInfo.Ultimate.Attacks do
				AttacksToAdd[Name] = true;
			end;
		end;
	end;

	for _, CharacterConfig in AttackList:GetChildren() do
		local AllowAll = CharacterConfig:GetAttribute("SkillBuilderAllowed");

		for _, AttackModule in CharacterConfig:GetChildren() do
			if not AttackModule:IsA("ModuleScript") or ( not AllowAll and not AttackModule:GetAttribute("SkillBuilderAllowed") ) then
				continue;
			end;

			AttacksToAdd[AttackModule.Name] = true;
		end
	end;

	if Settings.ReturnHashmap then
		return AttacksToAdd;
	end;

	local AccessibleAttacks = {};

	for Attack in AttacksToAdd do
		table.insert(AccessibleAttacks, Attack);
	end;

	return AccessibleAttacks;
end;

function Combat:CanUseNamedAttack(Name: string, Settings): boolean
	local Attack = self:GetAttackModule(Name);

	if not Attack then
		return false;
	end;

	local CharacterConfig = Attack.Parent;
	local CharacterName = CharacterConfig.Name;

	if CharacterConfig:GetAttribute("SkillBuilderAllowed") or Attack:GetAttribute("SkillBuilderAllowed") or self:CanUseCharacter(CharacterName, Settings) then
		return true;
	end;

	return false;
end;

function Combat:GetCharacterFromAttack(AttackName: string, IncludeNonCharacters: boolean?): string?
	local Attack = self:GetAttackModule(AttackName);

	if Attack then
		if IncludeNonCharacters then
			return Attack.Parent.Name;
		end;

		local CharacterModule = self:GetCharacterModule(Attack.Parent.Name);

		if CharacterModule then
			return CharacterModule.Name;
		end;
	end;

	return nil;
end

function Combat:HideUI(Value : boolean)
	if not self.LuaPlayer.IsNPC and self.LuaPlayer:PlayerExists() then
		UIRemotes.Hide:FireClient(self.LuaPlayer.Player, Value)
	end
end

function Combat:ToggleHeadMovement(Value : boolean?)
	if (not self.LuaPlayer.IsNPC and self.LuaPlayer:PlayerExists()) then
		network.headMovement.sendTo(Value, self.LuaPlayer.Player)
	end
end

function Combat:ChangeAttackDisplay(Name : string, NewName : string, Settings : {})
	if self.LuaPlayer.IsNPC then
		return
	end

	Settings = Settings or {}
	network.hotbarDisplay.sendTo({
		move = Name,
		text = NewName,
		tip = Settings.Tip,
		flash = Settings.FlashColor,
		important = true,
	}, self.LuaPlayer.Player)
end

--function Combat:ResetCurrentCharacterIfNotAllowed()
--	local DataHandler = self.LuaPlayer.Data

--	if not DataHandler.Profile or not DataHandler.Profile.Data then
--		return true
--	end

--	local Intruder = false

--	local function Was_Intruding()
--		DataHandler.Profile.Data.CurrentCharacter = "Chara"
--		Intruder = true
--	end

--	-- Should be able to replace most of this code using new Combat:CanUseCharacter() method
--	-- but i dont want to break anything so ill leave it

--	local CharacterData = self:GetCharacterModule(DataHandler.Profile.Data.CurrentCharacter)

--	if (CharacterData == nil) then
--		Was_Intruding()
--	else
--		local Info = require(CharacterData :: any)

--		if Info.OwnerOnly and not self:IsOwner() then
--			Was_Intruding()
--		end

--		local Not_Whitelisted = (Info.GitHubWhitelist and not Whitelist.is_permitted(self.LuaPlayer.UserId, Info.GitHubWhitelist))

--		if Info.DonatorAccess then

--			if not self.LuaPlayer.Player:HasTag("DonationCharacterAccess") and Not_Whitelisted then
--				Was_Intruding()
--			end

--		else
--			if Not_Whitelisted then
--				Was_Intruding()
--			end
--		end

--		task.spawn(function()
--			local Permission = CommandHandler:GetPermission(self.LuaPlayer.Player)

--			if (Info.PrivateServerPlusOnly and (game.PrivateServerId == "" or HostHandler.server.is_custom_server) and Permission ~= "Owner") then
--				Was_Intruding()
--			end
--		end)
--	end

--	return Intruder
--end

function Combat:ConnectHumanoidAvailability()
	local function Load(Value : boolean)
		if Value then

			if not shared.IsRankedPlace then
				self.Actions:SetEnabled(false)

				task.delay(0.5 + self.LuaPlayer:GetPing(), function()			
					self.Actions:SetEnabled(true)
				end)
			end

			table.clear(self.StunnedBy)
			table.clear(self.TotalBeenDamaged)

			self.HasFinisherKillIFrames = false

			if not self.LuaPlayer.IsNPC then
				for State : string in self.States do
					self:ResetState(State)
				end
			end

			self:LoadAnimations()
			self.Ragdoll:CreateFolder()

			task.spawn(function()
				if MovementReplicatorSettings.use_replicator and self.LuaPlayer.IsNPC then
					MovementReplicator:create_resimulated(self.LuaCharacter.Model, true).Parent = self.LuaCharacter.Model
				end
			end)

			self.LuaCharacter.HumanoidJob:Task(self.LuaCharacter.OnHumanoidDied:Connect(function()
				task.spawn(self.AwardKillToHighestDamager, self, "Attacked")

				if not self.LuaPlayer.IsNPC then
					task.spawn(function()
						while self.LuaCharacter.HumanoidExists do
							self.LuaCharacter:SetOwnership(self.LuaPlayer.Player)
							task.wait(0.1)
						end
					end)
				end

				self.Ragdoll:Toggle(true)
			end))

			if Passives.UserId[self.LuaPlayer.UserId] then
				for _, PassiveFunction in Passives.UserId[self.LuaPlayer.UserId] do
					task.spawn(PassiveFunction, self)
				end
			end

			if not self.LuaPlayer.IsNPC then
				self.AttributeStates:SetAttribute("Run", true)
			end

			local DataHandler = self.LuaPlayer.Data

			if DataHandler and DataHandler.Profile then

				if not self:CanUseCharacter(DataHandler.Profile.Data.CurrentCharacter) then
					DataHandler.Profile.Data.CurrentCharacter = "Invincible"
				end

				self:SetCharacter(DataHandler.Profile.Data.CurrentCharacter or "Invincible")
			else
				self:SetCharacter(self.LuaPlayer.Player:GetAttribute("Character") or "Invincible")
			end

			if not self.LuaPlayer.IsNPC then
				task.spawn(self.FireSpawnAnimation, self)
			end

			self:ResetCombatTag()
			self.AwardedToSomeoneAsKill = false
		else
			self.DamageMultiplier = 1
			self.DefenseMultiplier = 1

			for _, Attack in self.Attacks do
				Attack:CloseForRespawn();
			end;

			for StunThread in self.StunThreads do
				task.cancel(StunThread)
			end

			table.clear(self.StunThreads)

			self:DisableKillStreak()
			self.CurrentStreak = 0

		end
	end

	if self.LuaCharacter.HumanoidAlive then
		Load(true)
	end

	self.Job:Task(self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(Load))
end

function Combat:FireSpawnAnimation()
	self:StackState("HitboxImmunity", true)

	local Highlight = Instance.new("Highlight")

	if not self.LuaPlayer.IsNPC then
		Highlight.FillColor = Color3.new(1, 1, 1)
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.OutlineTransparency = 1
		Highlight.FillTransparency = 0.25
		Highlight.Parent = self.LuaCharacter.Model
	end

	local NewJob = Job.new()
	local Animation : AnimationTrack, Sound : Sound = nil, nil

	NewJob:Task(function()
		self:StackState("HitboxImmunity", false)

		if (Animation ~= nil and Animation.IsPlaying) then
			Animation:Stop()
		end

		if (Highlight.Parent ~= nil) then
			TweenService:Create(Highlight, TweenInfo.new(1), {
				FillTransparency = 1
			}):Play()
		end

		task.delay(1, Highlight.Destroy, Highlight)
	end)

	local ResetTimer = NewJob:Task(task.delay(7.5 + self.LuaPlayer:GetPing(), NewJob.Destroy, NewJob))

	if not self.LuaPlayer.IsNPC and not self.LuaCharacter.AppearanceLoaded then
		self.LuaCharacter.OnAppearanceLoaded:Wait() -- or else anims arent loaded and it dont play
	end

	if self.LuaPlayer.IsNPC or self:NotStunned() then
		local MovementJob = Job.Extend(NewJob)

		if self.LuaPlayer.IsNPC or self.LuaCharacter.Humanoid.MoveDirection == Vector3.zero then

			if self:HasACharacter() then
				if self.CurrentCharacter.Info.OnRespawn then
					Animation, Sound = self.CurrentCharacter.Info.OnRespawn(self.LuaPlayer, NewJob, 
						(self.CurrentCharacter.Info.SpawnAnimationRng and math.random(1, self.CurrentCharacter.Info.SpawnAnimationRng))
					)
				else
					pcall(function()
						Animation = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.Animations.CharacterSpawnAnimations[self.CurrentCharacter.Name].Spawn)
						Animation:Play()
					end)
				end
			end

			if Sound then
				NewJob:Task(Sound)
			end
		end

		local function ClearAnimation()
			MovementJob:Destroy()

			if Sound then
				Sound:Destroy()
			end

			if (Animation ~= nil) then
				Animation:Stop()
			end

			if ResetTimer then
				Utility.CloseThreadSafe(ResetTimer)
				Highlight.FillTransparency = 0.6
				NewJob:Task(task.delay(1, NewJob.Destroy, NewJob))
			end
		end

		if self.LuaCharacter.Humanoid.MoveDirection ~= Vector3.zero then
			ClearAnimation()
		end

		MovementJob:Task(self.LuaCharacter.Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
			if (self.LuaCharacter.Humanoid.MoveDirection ~= Vector3.zero) then
				ClearAnimation()
			end
		end))

		MovementJob:Task(self.OnStateChanged:Connect(function(State : string, Value : boolean)
			if (State == "Attacking" or State == "M1ing" or State == "Ragdolled" or State == "Stunned") and Value then
				ClearAnimation()
			end
		end))
	end

	return NewJob
end


function Combat:HasACharacter()
	return (self.CurrentCharacter.Name ~= "")
end

local OwnerIds = {
	141123572, -- jimpee
	7207821215, -- swrerm
	150522417, -- ery
	289049081, -- solid
	85042395, -- aenoir
}

function Combat:IsOwner()
	if IsStudio then
		return true
	end

	if self.LuaPlayer.IsNPC then
		return true
	end

	local Player : Player = self.LuaPlayer.Player

	return (table.find(OwnerIds, Player.UserId) ~= nil)
end

function Combat:OwnsEarlyAccess()
	local Player : Player = self.LuaPlayer.Player

	if shared.IsTestPlace then
		return true
	else
		return self:IsOwner() or Player.UserId == 465427335 -- mymy
	end
end

local WordsThatWontLoad = {
	["Camera"] = "Camera"
}

function Combat:IterateThroughAnimationFolder(AnimationTable : {}, StartFolder : Folder, CustomAnimator : Animator?)
	local Animator : Animator = CustomAnimator or self.LuaCharacter.Animator

	local function AddAnimation(CurrentTable, Item: Instance, Result : AnimationTrack)
		local Track = AnimationProxy.new(Result);
		local Priority = Result.Animation:GetAttribute("Priority")

		CurrentTable[Item.Name] = Track;

		if Priority then
			Track.Priority = Enum.AnimationPriority[Priority];
		end;
	end;

	local function Iterate(CurrentTable, CurrentFolder)
		for Index, Item : (Animation | Folder) in ipairs(CurrentFolder:GetChildren()) do
			if Item:IsA("Animation") then
				if Item:HasTag("DontLoadOnAnimator") then 
					continue;
				end;

				if WordsThatWontLoad[Item.Name] and string.find(Item.Name, WordsThatWontLoad[Item.Name]) then 
					continue;
				end;

				if Item.AnimationId == "" then
					warn(`Animation {Item:GetFullName()} has asset id empty`);
					continue;
				end;

				AddAnimation(CurrentTable, Item, Animator:LoadAnimation(Item))

			elseif Item:IsA("Folder") then
				CurrentTable[Item.Name] = {}
				Iterate(CurrentTable[Item.Name], Item)
			end
		end
	end

	Iterate(AnimationTable, StartFolder)
end;


function Combat:LoadAnimations()
	table.clear(self.Animations)

	Preloading.Add(self.LuaPlayer.Player, replicatedStorage.Animations.Global)
	self:IterateThroughAnimationFolder(self.Animations, replicatedStorage.Animations.Global)

	for _, Attack in self.Attacks do
		Attack:UpdateAnimations()
	end;
end;


function Combat:SetSpeedMultiplier(Speed: number)
	self.SpeedMultiplier = Speed;

	local Multiplier = self:GetSpeedMultiplier();

	local function ForeachAnimation(Animation)
		if typeof(Animation) ~= "table" then return end;

		if getmetatable(Animation) ~= AnimationProxy then
			for Key, Value in Animation do
				ForeachAnimation(Value);
			end;
		else
			Animation:SetSpeedMultiplier(Multiplier);
		end;
	end;

	ForeachAnimation(self.Animations);

	for _, Attack in self.Attacks do
		Attack:SetSpeedMultiplier(Attack.SpeedMultiplier);
	end;
end;


function Combat:GetSpeedMultiplier(): number
	return self.SpeedMultiplier * ( workspace:GetAttribute("AttackSpeedMultiplier") or 1 );
end;


function Combat:SetCharacter(Name : string, ...)
	local Character = self:GetCharacterModule(Name)

	if (Character == nil) then
		return false
	end

	local Info = require(Character :: any)	

	if not self.LuaPlayer.IsNPC and Info.RestrictSetCharacter and not IsStudio then
		local Level = CommandHandler:GetPermission(self.LuaPlayer.Player)

		if (Level ~= "GOB") then
			local ID : number = self.LuaPlayer.UserId

			if Info.GitHubWhitelist then
				if not Whitelist.is_permitted(ID, Info.GitHubWhitelist) then
					return false 
				end

			elseif Info.Whitelist then
				if (table.find(Info.Whitelist, self.LuaPlayer.UserId) == nil) then
					return false
				end
			end
		end
	end

	self.OnCharacterSwitching:Fire(Name)

	if (self.CurrentCharacter.Info ~= nil) then
		if (self.CurrentCharacter.Info.Ultimate ~= nil and self.CurrentCharacter.Info.Ultimate.Attacks ~= nil) then
			for AttackName : string in self.CurrentCharacter.Info.Ultimate.Attacks do
				if not self.CurrentCharacter.Info.Attacks[AttackName] then
					self:RemoveAttack(AttackName)
				end
			end
		end

		for AttackName : string in self.CurrentCharacter.Info.Attacks do
			self:RemoveAttack(AttackName)
		end;

		-- Mainly for custom skills
		for AttackName : string, Attack in self.Attacks do
			if Attack.RemoveOnSpawn then
				self:RemoveAttack(AttackName);
			end;
		end;

		self.SpawnJob:Clean()

		if (self.CurrentCharacter.Info.OnRemoved ~= nil) then
			self.CurrentCharacter.Info.OnRemoved(self.LuaPlayer)
		end
	end

	self.CurrentCharacter.Name = Name
	self.CurrentCharacter.Info = Info
	self.CurrentCharacter.Stats = self.CurrentCharacter.Info.Stats and Utility.DeepCopy(self.CurrentCharacter.Info.Stats) or {}

	if not self.LuaPlayer.IsNPC then
		network.setCharacter.sendTo(Name, self.LuaPlayer.Player)
	end

	self.LuaPlayer.Replication.Attributes:SetAttribute("CurrentCharacter", Name)

	for AttackName : string, AttackKey : (Enum.KeyCode | Enum.UserInputType) in self.CurrentCharacter.Info.Attacks do
		self:CreateAttack(AttackName, AttackKey)
	end;

	if (self.CurrentCharacter.Info.OnSpawn ~= nil and self.LuaCharacter.HumanoidAlive) then
		self.CurrentCharacter.Info.OnSpawn(self.LuaPlayer, ...)
	end

	if not self.LuaPlayer.IsNPC then
		local Ultimate = self.CurrentCharacter.Info.Ultimate

		self.AttributeValues:SetAttribute("UltimateBar", true)
		self.AttributeValues:SetAttribute("UltimateName", Ultimate and (Ultimate.Name or "") or "")

		if (Ultimate and Ultimate.Color ~= nil) then
			self.AttributeValues:SetAttribute("UltimateColor", Ultimate.Color)
		else
			self.AttributeValues:SetAttribute("UltimateColor", ColorSequence.new(Color3.new(1, 1, 1)))
		end
	end

	self.OnCharacterSwitched:Fire()

	return true
end


function Combat:CreateGhostAttack(Name: string)
	local Attack = self:GetAttackModule(Name);

	if (Attack ~= nil) then
		local NewAttack = require(Attack :: any).new(self, Attack, Enum.KeyCode.Unknown);

		NewAttack.OnTriggered:Connect(function()
			if (self.ActiveAttacks[NewAttack] == nil) then
				self.ActiveAttacks[NewAttack] = true
			end

			NewAttack.Thread.OnClosed:Connect(function()
				if self.ActiveAttacks[NewAttack] then
					self.ActiveAttacks[NewAttack] = nil
				end;
			end);
		end);

		NewAttack:UpdateAnimations()

		return NewAttack
	end;
end

function Combat:GetAttackFunctionModule(AttackDirectory: string): ModuleScript?
	local CacheHit = AttackFunctionModuleCache[AttackDirectory];

	if CacheHit then
		return CacheHit;
	end;

	local Instances = require( replicatedStorage.Packages.Instances )
	local Item = Instances.find_directory(AttackFunctionList, AttackDirectory, "/");

	if Item then
		AttackFunctionModuleCache[AttackDirectory] = Item;
	end;

	return Item;
end

function Combat:GetAttackModule(AttackName: string): ModuleScript?
	local CacheHit = AttackModuleCache[AttackName];

	if CacheHit then
		return CacheHit;
	end;

	for _, Item in AttackList:GetDescendants() do
		if Item:IsA("ModuleScript") and Item.Name == AttackName then
			AttackModuleCache[Item.Name] = Item;
			return Item;
		end;
	end;

	return nil;
end

function Combat:GetCharacterModule(CharacterName: string): ModuleScript?
	local CacheHit = CharacterModuleCache[CharacterName];

	if CacheHit then
		return CacheHit;
	end;

	for _, Item in CharacterList:GetChildren() do
		if Item:IsA("ModuleScript") and Item.Name == CharacterName then
			CharacterModuleCache[Item.Name] = Item;
			return Item;
		end;
	end;

	-- The module names are capitalised, info.movesets is keyed lowercase, and
	-- the pickers send one or the other. Match either.
	local Lowered = string.lower(CharacterName);

	for _, Item in CharacterList:GetChildren() do
		if Item:IsA("ModuleScript") and string.lower(Item.Name) == Lowered then
			CharacterModuleCache[CharacterName] = Item;
			return Item;
		end;
	end;

	return nil;
end

function Combat:_CreateAttack(Name : string, Key : (Enum.KeyCode | Enum.UserInputType), ModuleName: string?) -- DontUseSavedKeybind, Place it before properties
	if (self.Attacks[Name] ~= nil) then
		return self.Attacks[Name]
	end

	local Attack: any = self:GetAttackModule(ModuleName or Name)

	if (Attack ~= nil) then
		local NewAttack = require(Attack).new(self, Attack, Key);

		self.Attacks[Name] = NewAttack

		NewAttack.OnTriggered:Connect(function()
			if (self.ActiveAttacks[NewAttack] == nil) then
				self.ActiveAttacks[NewAttack] = true
			end

			NewAttack.Thread.OnClosed:Connect(function()
				if self.ActiveAttacks[NewAttack] then
					self.ActiveAttacks[NewAttack] = nil
				end
			end)
		end)

		if Key then
			local HotbarValue = (Key.Value - 48)

			if HotbarValue > 0 and HotbarValue < 10 then
				self.HotbarAttacks[Name] = true
			end
		end

		if Key and not self.LuaPlayer.IsNPC then
			network.createAttack.sendTo({
			move = Name,
			key = Key.Name,
			directory = NewAttack.DirectoryParent,
			properties = NewAttack.Properties,
		}, self.LuaPlayer.Player)
		end

		if typeof(NewAttack.Initialise) == "function" then
			NewAttack:Initialise();
		end;

		if (self.LuaCharacter.HumanoidAlive) then
			NewAttack:UpdateAnimations()
		end;

		self.OnAttackChanged:Fire(NewAttack, true);

		return NewAttack
	else
		if not self.LuaPlayer.IsNPC then
			network.notify.sendTo({
				Title = "Notification",
				Text = `The attack {Name} does not exist`,
				Duration = 2
			}, self.LuaPlayer.Player)
		end

		warn(`The attack {Name} does not exist`)

		return nil
	end
end


function Combat:ChangeKeyOfAttack(Name : string, AttackKey : (Enum.KeyCode | Enum.UserInputType), NewKey : (Enum.KeyCode | Enum.UserInputType))
	local Attack, Matched = self:MatchAttack(Name, AttackKey)

	if Matched then
		print("changed attack key")
		network.changeAttackKey.sendTo({ move = Name, key = NewKey.Name }, self.LuaPlayer.Player :: Player)
	end;
end;

function Combat:GetFirstAttackUsingKey(Key: Enum.KeyCode): boolean
	for Name, Attack in self.Attacks do
		if Attack.Key == Key then
			return Attack;
		end;
	end;

	return false;
end

function Combat:GetNextAttackKey(): Enum.KeyCode
	local NextNumber = 1;
	local UsedNumbers = {};

	for Name, Attack in self.Attacks do
		local Key = Attack.Key;

		if Key then
			UsedNumbers[Key.Value - 48] = true;
		end;
	end

	for Number = 1, 9 do
		if not UsedNumbers[Number] then
			return Enum.KeyCode:FromValue(Number + 48);
		end
	end

	return Enum.KeyCode.Unknown;
end


function Combat:CreateAttack(Name : string, Key : (Enum.KeyCode | Enum.UserInputType), ...)
	return self:_CreateAttack(Name, Key, ...)
end


function Combat:CreateAttacks(Names : (string | {}), Key : (Enum.KeyCode | Enum.UserInputType), ...)
	for _, Name in Names do
		self:_CreateAttack(Name, Key, ...)
	end
end


function Combat:RemoveAttack(Name : string, DontCallDestroy : boolean)
	local Attack = self.Attacks[Name]

	if (Attack ~= nil) then

		if DontCallDestroy and Attack:ThreadAvailable() then
			Attack.Thread.OnClosed:Connect(function()
				task.defer(Attack.Destroy, Attack)
			end)
		else
			Attack:Destroy()
		end

		self.Attacks[Name] = nil

		if self.HotbarAttacks[Name] then
			self.HotbarAttacks[Name] = nil
		end

		self.OnAttackChanged:Fire(Name, false)

		if not self.LuaPlayer.IsNPC then
			network.removeAttack.sendTo(Name, self.LuaPlayer.Player :: Player)
		end
	end
end

function Combat:GetStand()
	local StandName = self.CurrentCharacter.Info.StandName;

	if StandName then
		return self.Attacks[StandName];
	end;
end

function Combat:GetFirstAttack(Name : string)
	return self.Attacks[Name];
end

function Combat:MatchAttack(Name : string, Key : (Enum.KeyCode | Enum.UserInputType)) : (any, boolean)
	local Attack = self.Attacks[Name]

	if (Attack ~= nil and Attack.Key == Key) then
		return Attack, true
	end

	return nil, false
end

function Combat:CreateCounter(Level : number, Callback : () -> ())
	if (self.ActiveCounter == nil) then
		local ActiveCounter = {
			Level = Level,
			Event = EventService.new()
		}

		ActiveCounter.Event:Connect(function(VictimLuaPlayer)
			self:RemoveActiveCounter()
			task.spawn(Callback, VictimLuaPlayer)
		end)

		self.ActiveCounter = ActiveCounter
	end
end

function Combat:RemoveActiveCounter()
	if (self.ActiveCounter ~= nil) then
		self.ActiveCounter.Event:Destroy()
		table.clear(self.ActiveCounter)
		self.ActiveCounter = nil
	end
end

function Combat:Afflict(VictimLuaPlayer, Arguments : {}) : (boolean, string)
	local VictimLuaCharacter = VictimLuaPlayer.Character
	local VictimCombat = VictimLuaCharacter.Combat

	if (Arguments.DontHitDeadPeople and not VictimLuaCharacter.HumanoidAlive) then
		return false, "Dead"
	end

	if not Arguments.ExcludeAttempts then
		if (Arguments.TriggerActiveCounterOverOrEqualLevel == nil) then
			Arguments.TriggerActiveCounterOverOrEqualLevel = 1
		end

		if not Arguments.Inspection then
			if not Arguments.NoCounter and VictimCombat.ActiveCounter and Arguments.TriggerActiveCounterOverOrEqualLevel ~= -1 then

				local Distance = VictimCombat:CalculateMagnitude(self.LuaPlayer)

				if Arguments.Projectile  or Distance ~= Distance then
					Distance = 0
				end

				if Distance < 30 and VictimCombat.ActiveCounter.Level >= Arguments.TriggerActiveCounterOverOrEqualLevel then
					self:CancelAllAttacks()
					VictimCombat.ActiveCounter.Event:Fire(self.LuaPlayer)

					return false, "Countered"
				end
			end

			local MoveName: string; --debug.info(2, "s"):match("([^%.]+)$")

			if Arguments.SourceAttack then
				MoveName = Arguments.SourceAttack.Name;
			else
				MoveName = debug.info(2, "s"):match("([^%.]+)$");
			end
		end;

		if not Arguments.DontCheckForHitboxImmunity and VictimCombat:GetState("HitboxImmunity") then
			return false, "IFrames"
		end

		for _, IFrame in (Arguments.DontBypassIFrames or {"Grab"}) do
			if VictimCombat:GetState(IFrame .. "IFrames") then
				self.LuaPlayer.Replication:FireReliableVFX("Global/StateIndications", "IFrames", VictimLuaCharacter.RootPart)
				return false, "IFrames"
			end
		end

		if not Arguments.DontCheckBlock then
			local Validation = self:ValidateBlock(VictimLuaPlayer, Arguments)

			if (Validation == "Perfect Blocked") then
				return false, Validation
			end

			if (Validation == "Blocked") then
				return false, Validation
			end
		end

		if Arguments.DontHitRagdolled and VictimCombat:GetState("Ragdolled") then
			return false, "Ragdolled"
		end

		if (Arguments.YDifferenceValue ~= nil) then
			local YDifference = self:CalculateYDifference(VictimLuaPlayer)

			if (VictimCombat:GetState("Ragdolled") and YDifference < Arguments.YDifferenceValue) then
				return false, "Grounded"
			end
		end

		if not Arguments.DontRestartRespawnTimer then
			VictimLuaCharacter:RestartRespawnTimer()
		end

		if not VictimLuaPlayer.IsNPC then
			self:CombatTag()
		end

		VictimCombat:CombatTag()

		if not self.LuaPlayer.IsNPC then
			network.resetJumpFatigue.sendTo(nil, self.LuaPlayer.Player)
		end

		if (VictimLuaCharacter.Humanoid.Sit == true) then
			VictimLuaCharacter.Humanoid.Sit = false
		end
	end

	local WasTimestopped = VictimCombat:GetState("Timestopped")

	if WasTimestopped then
		VictimCombat:GetStateChanged("Timestopped"):Wait()
	end

	if Arguments.FinisherKill then

		if VictimLuaPlayer.IsNPC then
			if VictimLuaCharacter.HumanoidAlive then
				VictimLuaCharacter.Humanoid:TakeDamage(100)
			end

			task.defer(function()
				if not VictimLuaCharacter.HumanoidAlive then
					VictimCombat:SetFinisherKillIFrames()
				end
			end)
		else
			VictimLuaPlayer.Character:Die()
			VictimCombat:SetFinisherKillIFrames()

			self.OnFinisherKill:Fire(VictimLuaPlayer)
		end
	else
		if (Arguments.Damage ~= nil) then
			self:AfflictDamage(VictimLuaPlayer, Arguments.Damage)
		end
	end

	if Arguments.PlayRandomHitReaction then
		VictimCombat:PlayRandomHitReaction()
	end

	if (Arguments.Ragdoll ~= nil) then
		VictimCombat.Ragdoll:Toggle(true, Arguments.Ragdoll)
	end

	if (Arguments.Stun ~= nil) then
		VictimCombat:Stun(Arguments.Stun)

	elseif (Arguments.TrueStun ~= nil) then
		VictimCombat:TrueStun(Arguments.TrueStun)
	end

	if (Arguments.Velocity ~= nil) then
		local VelocityObject = if Arguments.SourceAttack then Arguments.SourceAttack:VelocityOn(VictimCombat) else VictimCombat:Velocity()

		if (VelocityObject ~= nil) then
			if typeof(Arguments.Velocity[1]) == "number" then
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = Arguments.Velocity[1]
			else
				VelocityObject.Settings.Velocity = Arguments.Velocity[1]
			end

			VelocityObject.Settings.RemoveTime = Arguments.Velocity[2]
			VelocityObject.Settings.MaxForce = Arguments.Velocity[3]
			VelocityObject:Fire()
		end
	end

	if WasTimestopped then
		task.wait(Utility.Seed:NextNumber(0.01, 0.02))
	end

	return true, "Damaged"
end

function Combat:SetFinisherKillIFrames()
	self:StackState("HitboxImmunity", true)
	self.HasFinisherKillIFrames = true
end

function Combat:ValidateBlock(VictimLuaPlayer, Arguments : {}) : string
	local VictimLuaCharacter = VictimLuaPlayer.Character
	local VictimCombat = VictimLuaCharacter.Combat

	local BlockAttack, BlockAttackMatched = VictimCombat:MatchAttack("Block", Enum.KeyCode.F)

	if not BlockAttackMatched then
		return "No attack"
	end

	if not VictimCombat:GetState("Blocking") then
		return "Bypassed"
	end

	local ShieldAttack = VictimCombat.Attacks["Guardian Shield"]
	local IsKratosShieldState = (ShieldAttack and ShieldAttack.InShield)

	local BlockAngle = IsKratosShieldState and math.rad(100) or (Arguments.BlockAngle or BlockAttack.BlockAngle)
	local Angle = self:CalculateHitAngle(VictimLuaPlayer, Arguments.HitAngleLookVector) 

	if Angle >= BlockAngle then
		return "Hit Behind"
	end

	local BlockAnimationDirectory = BlockAttack:GetAnimationDirectory()

	if Arguments.CanPerfectBlock and BlockAttack.PerfectBlockWindow then

		if VictimLuaPlayer.IsNPC then
			self.Animations.Parried:Play(0.1, 0.65, 0.7)
		else
			if IsKratosShieldState then
				--VictimCombat:StackState("Attacking", true)
				VictimCombat:StackState("CannotM1", true)
				VictimCombat:StackState("CannotBlock", true)
				VictimCombat:StackState("BackdashIFrames", true)

				VictimCombat:DivideSpeed(3)

				if BlockAnimationDirectory.ShieldHold and BlockAnimationDirectory.ShieldHold.IsPlaying then
					BlockAnimationDirectory.ShieldHold:Stop()
				end

				if BlockAnimationDirectory.ShieldParry then
					BlockAnimationDirectory.ShieldParry:Play()
				end

				self.LuaPlayer.Replication:FireReliableVFX("Kratos/Guardian Shield", "Parry", VictimLuaCharacter.Model, self.LuaCharacter.Model)

				task.spawn(function()
					local ReflectedDamage = 0
					local ReflectedStun = 0

					if typeof(Arguments.Damage) == "table" then
						ReflectedDamage = Arguments.Damage.Amount or 0

					elseif typeof(Arguments.Damage) == "number" then
						ReflectedDamage = Arguments.Damage
					end

					if (Arguments.Stun ~= nil) then
						ReflectedStun = Arguments.Stun

					elseif (Arguments.TrueStun ~= nil) then
						ReflectedStun = Arguments.TrueStun
					end

					if ReflectedDamage > 0 then
						VictimCombat:DealDamage(self.LuaPlayer, ReflectedDamage)
					else
						VictimCombat:DealDamage(self.LuaPlayer, 3)
					end

					if self.Animations.BlackFlashed then
						self.Animations.BlackFlashed:Play(0.04, 0.75, 1.25)
					end

					if ReflectedStun > 0 then
						self:TrueStun(ReflectedStun)
					else
						self:TrueStun(0.9)
					end
				end)

				task.delay(0.35, function()
					if BlockAnimationDirectory.ShieldParry then
						BlockAnimationDirectory.ShieldParry:Stop(0.4)
					end

					if BlockAnimationDirectory.ShieldHold and not BlockAnimationDirectory.ShieldHold.IsPlaying and VictimCombat:GetState("Blocking") then
						BlockAnimationDirectory.ShieldHold:Play(0.4)
					end

					VictimCombat:TimesSpeed(3)

					VictimCombat:StackState("CannotM1", false)
					VictimCombat:StackState("BackdashIFrames", false)
				end)

				task.delay(0.475, function()
					VictimCombat:StackState("CannotBlock", false)
				end)
			else
				BlockAttack.PerfectBlockTime = time()

				if VictimCombat.CurrentCharacter.Info.Parry and VictimCombat.CurrentCharacter.Info.Parry.CustomFunction then
					task.spawn(VictimCombat.CurrentCharacter.Info.Parry.CustomFunction, VictimCombat, self, BlockAttack, BlockAnimationDirectory)
				else
					--self:Stun(0.6)
					self:StackState("CannotDash", true, 0.4)
					self:StackState("CannotBlock", true, 0.4)
					self:StackState("CannotM1", true, 0.4)

					VictimLuaPlayer.Replication:FireReliableVFX("Global/Block", "Parry", VictimLuaCharacter.RootPart, VictimCombat.CurrentCharacter.Name, math.random(1, 450))

					if VictimCombat.CurrentCharacter.Name == "Chara" then
						VictimCombat:GiveOneTriggerMove("Check", Enum.KeyCode.R, 60)
					end

					if BlockAnimationDirectory.Parried then
						BlockAnimationDirectory.Parried:Play()
					end
				end
			end
		end

		return "Perfect Blocked"
	end

	if Arguments.BreakBlock then
		return "Bypassed"
	end

	if IsKratosShieldState then -- didn't want to do this but im too lazy
		BlockAnimationDirectory.ShieldHold:Stop()

		local Blocks = BlockAnimationDirectory.ShieldBlocks
		local Animation = Blocks[tostring(math.random(1, Utility.TableCount(Blocks)))]

		if Animation then
			Animation:Play()

			Animation.Stopped:Once(function()
				if BlockAnimationDirectory.ShieldHold and VictimCombat:GetState("Blocking") then
					BlockAnimationDirectory.ShieldHold:Play(0.3)
				end
			end)
		end
	else
		local Ultimate = VictimCombat:GetFirstAttack("Ultimate");
		local PlayUltimateBlock = (Ultimate and Ultimate.InUltimate and BlockAnimationDirectory.Ult)

		if PlayUltimateBlock then
			local Reactions = BlockAnimationDirectory.Ult.Reactions

			if Reactions then
				if BlockAnimationDirectory.Ult.Hold and BlockAnimationDirectory.Ult.Hold.IsPlaying then
					BlockAnimationDirectory.Ult.Hold:Stop(0.001)
				end

				local Animation = Reactions[tostring(math.random(1, Utility.TableCount(Reactions)))]
				Animation:Play(0)

				Animation.Stopped:Once(function()
					if BlockAnimationDirectory.Ult.Hold and VictimCombat:GetState("Blocking") then
						BlockAnimationDirectory.Ult.Hold:Play(0.001)
					end
				end)
			end
		else
			local Reactions = BlockAnimationDirectory.Reactions or BlockAttack.Animations.Default.Reactions
			local Hold = BlockAnimationDirectory.Hold or BlockAttack.Animations.Default.Hold
			local Windup = BlockAnimationDirectory.Windup or BlockAttack.Animations.Default.Windup

			if Reactions then
				if Windup then
					Windup:Stop(0.001)
				end

				if Hold then
					Hold:Stop(0.001)
				end

				local Animation = Reactions[tostring(math.random(1, Utility.TableCount(Reactions)))]
				Animation:Play(0)

				Animation.Stopped:Once(function()
					if Hold and VictimCombat:GetState("Blocking") then
						Hold:Play(0.001)
					end
				end)
			end
		end
	end

	self.LuaPlayer.Replication:FireVFX("Global/Block", "Hit", VictimLuaCharacter.RootPart)

	return "Blocked"
end

function Combat:AfflictDamage(VictimLuaPlayer, Value : (number | table))
	self.LastAfflictedDamage = tick(); -- For Hit Cancel in Custom Skills

	if typeof(Value) == "number" then
		self:DealDamage(VictimLuaPlayer, Value)

	elseif (typeof(Value) == "table" and Value.Amount ~= nil) then
		--if (Value.DontKill) then
		--local VictimLuaCharacter = VictimLuaPlayer.Character
		--local VictimCombat = VictimLuaCharacter.Combat

		--local Health : number = VictimLuaCharacter.Humanoid.Health

		--self:DealDamage(VictimLuaPlayer, Damage, Value.DontCountToUltimate)

		--if Health > Damage then
		--	self:DealDamage(VictimLuaPlayer, Damage, Value.DontCountToUltimate)
		--else
		--	local NewHealth = math.max(0.1, Health - Damage)

		--	self:DealDamage(VictimLuaPlayer, 
		--		--(Health - (Damage - (Damage - 0.1))), 
		--		NewHealth,
		--		Value.DontCountToUltimate, true
		--	)
		--end

		--local DontKillDamage = (Health > Damage and Damage or Health - (Damage - (Damage - 0.1)))

		--self:DealDamage(VictimLuaPlayer, DontKillDamage, Value.DontCountToUltimate)
		--else

		self:DealDamage(VictimLuaPlayer, Value.Amount, Value.DontCountToUltimate, Value.DontKill)

		--end
	end
end

function Combat:DealDamage(VictimLuaPlayer, Value : number, DontCountToUltimate : boolean, DontKill : boolean)
	local VictimLuaCharacter = VictimLuaPlayer.Character

	if VictimLuaCharacter.HumanoidAlive then
		Value = math.max(0, Value)

		local VictimCombat = VictimLuaCharacter.Combat

		if not DontCountToUltimate and self:IsntTheSamePerson(VictimLuaPlayer) then
			local Ultimate, HasUltimate = self:MatchAttack("Ultimate", Enum.KeyCode.G)

			if HasUltimate and not Ultimate.InUltimate and not self:GetState("CannotGainMeter") then
				local Amount = (IsStudio and (Value * 10) or (Value / 2))

				if VictimLuaPlayer.IsNPC then
					Amount /= 3
				end

				Ultimate:AddValue(Amount)
			end
		end

		local DamageMultiplier : number = math.max(0.01, self.DamageMultiplier)
		local DefenseMultiplier : number = math.max(0.01, VictimCombat.DefenseMultiplier)

		local Health : number = VictimLuaCharacter.Humanoid.Health;

		local ActualValue = math.max(0, (Value / DefenseMultiplier) * DamageMultiplier)
		local KeptAlive = false

		if DontKill then
			local MinimumHP = 0.1;

			ActualValue = math.min(Health - MinimumHP, ActualValue);
			KeptAlive = ActualValue <= MinimumHP;

			if (ActualValue > 0) then
				VictimLuaCharacter.Humanoid:TakeDamage(ActualValue)
			end;
		else
			VictimLuaCharacter.Humanoid:TakeDamage(ActualValue)
		end;

		--if self:HasACharacter() and self.CurrentCharacter.Name == "Chara" then
		self.LuaPlayer.Replication:FireReliableVFX("Chara/Damage Indicator", "Value", VictimLuaCharacter.RootPart, if KeptAlive then 9999 else ActualValue) --global effect now
		--end

		VictimCombat.LastHitBy = self.LuaPlayer.Player

		if not self.LuaPlayer.IsNPC and VictimCombat:CanAwardKills() and self:IsntTheSamePerson(VictimLuaPlayer) then
			local Max = VictimLuaCharacter.Humanoid and VictimLuaCharacter.Humanoid.MaxHealth or 100

			local PreviousBeenValue = VictimCombat.TotalBeenDamaged[self.LuaPlayer.Player]
			local PreviousDealtValue = self.TotalDealtDamage[VictimLuaPlayer.Player]

			VictimCombat.TotalBeenDamaged[self.LuaPlayer.Player] = math.clamp(
				(PreviousBeenValue or 0) + ActualValue, 
				0, Max
			)

			self.TotalDealtDamage[VictimLuaPlayer.Player] = math.clamp(
				(PreviousDealtValue or 0) + ActualValue, 
				0, Max
			)

			self.OnDamageDealt:Fire(ActualValue)
		end
	end
end

function Combat:CanAwardKills()
	if shared.IsTestPlace then
		return (self.AwardedToSomeoneAsKill == false)
	end

	return (self.AwardedToSomeoneAsKill == false and not self.LuaPlayer.IsNPC)
end

function Combat:CanDamageAI()
	local CurrentCharacter = self.CurrentCharacter.Name;

	if self:IsOwner() then
		return true;
	end;

	if (CurrentCharacter == "Invincible" or CurrentCharacter == "Meaty Michael" or CurrentCharacter == "Walter" or CurrentCharacter == "Gebura Red Mist") then
		return false;
	end;

	return true;
end

function Combat:CanGainKills()
	local CurrentCharacter : string = self.CurrentCharacter.Name;

	if self:IsOwner() then
		return true;
	end;

	if (not self.IsInvincibleFromWorldEvent and CurrentCharacter == "Invincible") then
		return false;
	end;

	if (not self.IsMeatyMichaelFromWorldEvent and CurrentCharacter == "Meaty Micheal") then
		return false;
	end;

	if (CurrentCharacter == "Walter" or CurrentCharacter == "Gebura Red Mist") then
		return false;
	end;

	return true;
end

function Combat:AwardKillToHighestDamager(Type : string)
	if not self:CanAwardKills() then return end

	local SortedDamagers = {}

	StudioPrint(self.LuaPlayer.PlayerName, "just killed sum1")

	for Player : Player, Damage : number in self.TotalBeenDamaged do
		if (Player and Player.Parent ~= nil) then
			StudioPrint(`player that dealt damage to {self.LuaPlayer.PlayerName} until death:`, `{Player},`, "value:", Damage)

			table.insert(SortedDamagers, {Player = Player, Damage = Damage})
		end
	end

	table.sort(SortedDamagers, function(A, B)
		return A.Damage > B.Damage
	end)

	--print(SortedDamagers)

	local function NormalAward(AwardedLuaPlayer)
		local AwardedLuaCharacter = AwardedLuaPlayer.Character
		local AwardedCombat = AwardedLuaCharacter.Combat

		if not AwardedLuaPlayer.IsNPC then
			if game.PrivateServerId == "" then
				AwardedLuaPlayer.Data:AddKill(self.LuaPlayer.Player, Type)
			end

			if AwardedCombat:HasACharacter() then
				if Passives.Kills[AwardedCombat.CurrentCharacter.Name] then
					task.spawn(Passives.Kills[AwardedCombat.CurrentCharacter.Name], AwardedCombat)
				end
			end

			if self.LuaPlayer:PlayerExists() and AwardedLuaPlayer:PlayerExists() then

				if Type == "Attacked" and self.LuaCharacter.HumanoidExists then
					task.spawn(AwardedCombat.PlayKillSound, AwardedCombat, self.LuaCharacter.Model)
				end

			end
		end

		AwardedCombat.OnKill:Fire(self)
		AwardedCombat.CurrentStreak += 1

		task.spawn(function()
			local AwardedKillStreak = nil

			for Player : Player, LuaPlayer in LuaPlayerList.LuaPlayers do
				if Player.Parent ~= Players then
					continue
				end

				if (LuaPlayer == nil or LuaPlayer.Character == nil or LuaPlayer.Character.Combat == nil) then
					print("idk why this is still erroring")
					continue
				end

				LuaPlayer.Character.Combat:DisableKillStreak()

				if not LuaPlayer.Character.Combat.HideKillStreak and (not AwardedKillStreak or LuaPlayer.Character.Combat.CurrentStreak > AwardedKillStreak.Character.Combat.CurrentStreak) then
					AwardedKillStreak = LuaPlayer
				end
			end

			if AwardedKillStreak and AwardedKillStreak.Character.Combat.CurrentStreak >= 10 then
				AwardedKillStreak.Character.Combat:EnableKillStreak()
			end
		end)
	end

	for _, Entry in ipairs(SortedDamagers) do
		local Player = Entry.Player
		local Damage = Entry.Damage

		if (Type == "Left" and Damage < 50) then
			StudioPrint("left", Player, Damage)
			continue
		end

		local AwardedLuaPlayer = LuaPlayerList.LuaPlayers[Player]

		if AwardedLuaPlayer then
			if not AwardedLuaPlayer.Character.Combat:CanGainKills() then
				continue
			end

			self.AwardedToSomeoneAsKill = true

			NormalAward(AwardedLuaPlayer)
			break
		end
	end

	table.clear(SortedDamagers)
	table.clear(self.TotalBeenDamaged)
end

--function Combat:GetHighestDamager()
--	local ReceiveKillData

--	for Player : Player, Damage : number in self.TotalBeenDamaged do
--		if (Player.Parent == nil) then
--			self.TotalBeenDamaged[Player] = nil
--			continue
--		end

--		if (ReceiveKillData == nil) then 
--			ReceiveKillData = {Player, Damage} 
--			continue 
--		end

--		if Damage > ReceiveKillData[2] then
--			ReceiveKillData = {Player, Damage}
--		end
--	end

--	if (ReceiveKillData ~= nil) then
--		local PlayerWhoKilled = ReceiveKillData[1]

--		if (PlayerWhoKilled ~= nil) then
--			return ReceiveKillData, LuaPlayerList.LuaPlayers[PlayerWhoKilled]
--		end
--	end

--	return ReceiveKillData
--end

--function Combat:AwardKillToHighestDamager(Type : string)
--	if not self:CanAwardKills() then return end

--	local ReceiveData, AwardedLuaPlayer = self:GetHighestDamager()

--	if ReceiveData and AwardedLuaPlayer then
--		if (Type == "Left" and ReceiveData[2] < 50) then
--			return
--		end

--		self.AwardedToSomeoneAsKill = true

--		local AwardedLuaCharacter = AwardedLuaPlayer.Character
--		local AwardedCombat = AwardedLuaCharacter.Combat

--		if not AwardedLuaPlayer.IsNPC then
--			if game.PrivateServerId == "" then
--				AwardedLuaPlayer.Data:AddKill(self.LuaPlayer.Player, Type)
--			end

--			if self.LuaPlayer:PlayerExists() and AwardedLuaPlayer:PlayerExists() then
--				if Type == "Attacked" and self.LuaCharacter.HumanoidExists then
--					task.spawn(AwardedCombat.PlayKillSound, AwardedCombat, self.LuaCharacter.Model)
--				end

--				if AwardedCombat:HasACharacter() then
--					if Passives.Kills[AwardedCombat.CurrentCharacter.Name] then
--						task.spawn(Passives.Kills[AwardedCombat.CurrentCharacter.Name], AwardedCombat)
--					end
--				end
--			end

--			--if game.PrivateServerId == "" and not self.LuaPlayer.IsNPC then
--			--	AwardedLuaPlayer.Data:AddKill(self.LuaPlayer.Player, Type)
--			--end

--			--if self.LuaPlayer:PlayerExists() and AwardedLuaPlayer:PlayerExists() then
--			--	if Type == "Attacked" and self.LuaCharacter.HumanoidExists then
--			--		task.spawn(AwardedCombat.PlayKillSound, AwardedCombat, self.LuaCharacter.Model)
--			--	end

--			--	if AwardedCombat:HasACharacter() and (not self.LuaPlayer.IsNPC or game.PrivateServerId ~= "") then
--			--		if Passives.Kills[AwardedCombat.CurrentCharacter.Name] then
--			--			task.spawn(Passives.Kills[AwardedCombat.CurrentCharacter.Name], AwardedCombat)
--			--		end
--			--	end
--			--end
--		end

--		AwardedCombat.CurrentStreak += 1

--		task.spawn(function()
--			local AwardedKillStreak = nil

--			for Player : Player, LuaPlayer in LuaPlayerList.LuaPlayers do
--				if Player.Parent ~= Players then
--					continue
--				end

--				if (LuaPlayer == nil or LuaPlayer.Character == nil or LuaPlayer.Character.Combat == nil) then
--					print("idk why this is still erroring")
--					continue
--				end

--				LuaPlayer.Character.Combat:DisableKillStreak()

--				if not LuaPlayer.Character.Combat.HideKillStreak and (not AwardedKillStreak or LuaPlayer.Character.Combat.CurrentStreak > AwardedKillStreak.Character.Combat.CurrentStreak) then
--					AwardedKillStreak = LuaPlayer
--				end
--			end

--			if AwardedKillStreak and AwardedKillStreak.Character.Combat.CurrentStreak >= 10 then
--				AwardedKillStreak.Character.Combat:EnableKillStreak()
--			end
--		end)
--	end
--end

function Combat:EnableKillStreak()
	if not self.LuaCharacter.HumanoidExists then return end

	if not self.LuaCharacter.Head:FindFirstChild("KillStreakGUI") then
		local Streak = script.Streak:Clone()
		Streak.Name = "KillStreakGUI"
		Streak.Adornee = self.LuaCharacter.Head
		Streak.Parent = self.LuaCharacter.Head
	end

	if not self.LuaCharacter.Model:FindFirstChild("KillStreakHighlight") then
		local Highlight = Instance.new("Highlight")
		Highlight.Name = "KillStreakHighlight"
		Highlight.FillTransparency = 1
		Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		Highlight.Parent = self.LuaCharacter.Model
	end

	self.LuaCharacter.Head.KillStreakGUI.Label.Text = `{self.CurrentStreak}`
	self.LuaCharacter.Head.KillStreakGUI.Enabled = true
	self.LuaCharacter.Model.KillStreakHighlight.Enabled = true
end

function Combat:DisableKillStreak()
	if not self.LuaCharacter.HumanoidExists then return end

	if self.LuaCharacter.Head:FindFirstChild("KillStreakGUI") then
		self.LuaCharacter.Head.KillStreakGUI.Enabled = false
	end

	if self.LuaCharacter.Model:FindFirstChild("KillStreakHighlight") then
		self.LuaCharacter.Model.KillStreakHighlight.Enabled = false
	end
end

--function Combat:CombatTag()
--	self:ResetCombatTagThread()
--	self.InCombat = true

--	if not self.LuaPlayer.IsNPC then
--		self.AttributeValues:SetAttribute("InCombat", true)
--	end

--	self.InCombatReset = task.delay(10, function()
--		self.InCombat = false

--		if not self.LuaPlayer.IsNPC then
--			self.AttributeValues:SetAttribute("InCombat", false)
--		end
--	end)
--end

function Combat:CombatTag()
	self:ResetCombatTagThread()
	self.InCombat = true

	if not self.LuaPlayer.IsNPC then
		self.AttributeValues:SetAttribute("InCombat", true)
	end

	local Time = 10

	if self.LuaCharacter.HumanoidExists then
		local Health : number = self.LuaCharacter.Humanoid.Health
		local MaxHealth : number = self.LuaCharacter.Humanoid.MaxHealth

		if (MaxHealth == math.huge or MaxHealth ~= MaxHealth) then
			MaxHealth = 100
		end

		Time = math.clamp(
			Time + ((1 - (Health / MaxHealth)) * 17.5), 
			Time, 30
		)
	end

	self.InCombatReset = task.delay(Time, function()
		self.InCombat = false

		if not self.LuaPlayer.IsNPC then
			self.AttributeValues:SetAttribute("InCombat", false)
		end
	end)
end

function Combat:ResetCombatTagThread()
	if (self.InCombatReset ~= nil and coroutine.status(self.InCombatReset) == "suspended") then
		task.cancel(self.InCombatReset)
		self.InCombatReset = nil
	end
end

function Combat:ResetCombatTag()
	self:ResetCombatTagThread()
	self.InCombat = false

	if not self.LuaPlayer.IsNPC then
		self.AttributeValues:SetAttribute("InCombat", false)
	end
end

function Combat:GiveOneTriggerMove(Name : string, Key : Enum.KeyCode, Duration : number)
	local Attack = self:CreateAttack(Name, Key)
	if (Attack == nil) then return end

	local NewJob = Job.new()

	NewJob:Task(function()
		self:RemoveAttack(Name, true)
	end)

	NewJob:Task(task.delay(Duration or 20, NewJob.Destroy, NewJob))

	NewJob:Task(self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(_, Exists)
		if not Exists then
			NewJob:Destroy()
		end
	end))

	NewJob:Task(self.OnCharacterSwitched:Connect(function()
		NewJob:Destroy()
	end))

	NewJob:Task(Attack.OnTriggered:Once(function()
		Attack.OnCooldown = true;
		NewJob:Destroy()
	end))

	Attack.CooldownEnabled = false;
end

--function Combat:AwardPassive()
--	if self.CurrentCharacter.Name == "Gojo" then
--		self:GiveOneTriggerMove("Reverse Cursed Technique", Enum.KeyCode.R) 

--	elseif self.CurrentCharacter.Name == "Reigen" then
--		self:GiveOneTriggerMove("Dimple", Enum.KeyCode.R)

--	elseif self.CurrentCharacter.Name == "Meaty Michael" then
--		local RandomMoves = {"Drake's Love", "Drake's Embrace"}
--		local Move = RandomMoves[math.random(1, #RandomMoves)]

--		if Move then
--			self:GiveOneTriggerMove(Move, Enum.KeyCode.R, 7.5)
--		end
--	end
--end

function Combat:PlayKillSound(KilledModel : Model)
	if (KilledModel == nil or KilledModel.Parent == nil) then return end

	if self.LuaPlayer.Player:GetAttribute("Kill_Sound") and self.LuaPlayer.Player:GetAttribute("Kill_Sound") ~= "0" then
		local Torso = KilledModel:FindFirstChild("Torso")

		if Torso then
			local KillSound : Sound = Instance.new("Sound")
			KillSound.SoundId = `rbxassetid://{self.LuaPlayer.Player:GetAttribute("Kill_Sound")}`
			KillSound.Volume = self.KillSoundSettings.Volume
			KillSound.PlaybackSpeed = self.KillSoundSettings.Pitch
			KillSound.SoundGroup = SoundService.KillSounds
			KillSound.Parent = Torso
			KillSound:Play()

			task.delay(10, KillSound.Destroy, KillSound)
		end
	end
end

function Combat:CalculateUnitDifference(VictimLuaPlayer) : Vector3
	local VictimRoot : BasePart = VictimLuaPlayer.Character.Combat:GetSimulatedRoot()
	local VictimRootCFrame : CFrame = VictimRoot and VictimRoot.CFrame

	if not VictimRootCFrame then
		return Vector3.zero
	end

	if not self.LuaCharacter.HumanoidExists then
		return -VictimRootCFrame.LookVector
	end

	local AttackerRoot : BasePart =  self:GetSimulatedRoot()
	local Difference =  (VictimRootCFrame.Position - AttackerRoot.Position).Unit

	if Difference ~= Difference then -- if its nan (victimluacharacter is selfluacharacter)
		return -VictimRootCFrame.LookVector
	end

	return Difference
end

function Combat:CalculateMagnitude(VictimLuaPlayer) : number
	local VictimRoot : BasePart = VictimLuaPlayer.Character.Combat:GetSimulatedRoot()
	local AttackerRoot : BasePart = self:GetSimulatedRoot()

	return (AttackerRoot.Position - VictimRoot.Position).Magnitude
end

function Combat:CalculateYDifference(VictimLuaPlayer) : number
	local AttackerRoot : BasePart =  self:GetSimulatedRoot()
	local VictimRoot : BasePart = VictimLuaPlayer.Character.Combat:GetSimulatedRoot()

	return (VictimRoot.Position - AttackerRoot.Position).Y
end

function Combat:GetSimulatedRoot()
	if MovementReplicatorSettings.use_replicator and not self.LuaPlayer.IsNPC then
		local simulated = MovementReplicator:get_root_part(self.LuaPlayer.Player)

		if simulated then
			return simulated
		end
	end

	return self.LuaCharacter.RootPart
end

function Combat:CalculateHitAngle(VictimLuaPlayer, CustomLookVector : Vector3?): number
	local LookVector : Vector3

	local VictimRoot : BasePart = VictimLuaPlayer.Character.Combat:GetSimulatedRoot()
	local RootCFrame = VictimRoot.CFrame * CFrame.new(0, 0, 0.25) -- tries to avoid bypassing blocks due to replicator cframing

	if CustomLookVector then
		LookVector = CustomLookVector
	else
		LookVector = (self:GetSimulatedRoot().Position - RootCFrame.Position)
	end

	return RootCFrame.LookVector:Angle(
		AenoirUtil.Unit(LookVector)
	)
end


function Combat:NotStunned()
	return not self:GetState("Attacking") and not self:GetState("M1ing") and not self:GetState("Stunned") and not self:GetState("Ragdolled") and not self:GetState("Blocking")
end

function Combat:IsStunned()
	return not self:NotStunned()
end


function Combat:Has_IFrames()
	return (self:GetState("HitboxImmunity") or self:GetState("GrabIFrames"))-- or self:GetState("BackdashIFrames"))
end

function Combat:_CreateState(State: any)
	if (self.States[State] == nil) then
		self.States[State] = NumberStack.new()

		local ConvertedName = Utility.ConvertStringAttributeFriendly(State)

		if not self.LuaPlayer.IsNPC then
			self.AttributeStates:SetAttribute(ConvertedName, false)
		end

		self.Job:Task(self.States[State].OnValueChanged:Connect(function(Value : boolean)
			self.OnStateUpdated:Fire(State, Value)
		end))

		self.Job:Task(self.States[State].OnChanged:Connect(function(Value : boolean)
			self.OnStateChanged:Fire(State, Value)

			if not self.LuaPlayer.IsNPC then
				self.AttributeStates:SetAttribute(ConvertedName, Value)
			end
		end))
	end
end


function Combat:ResetState(State: any)
	self:_CreateState(State)
	self.States[State]:Reset()
end


function Combat:GetRawState(State : any)
	self:_CreateState(State)

	return self.States[State]
end


function Combat:GetState(State: any)
	self:_CreateState(State)

	return self.States[State]:IsTrue()
end


function Combat:GetStateChanged(State: any)
	self:_CreateState(State)

	return self.States[State].OnChanged
end


function Combat:StackState(State : any, NewValue : any, DurationUntilPop : number?)
	self:_CreateState(State)

	if (NewValue == true) then
		self.States[State]:Add(DurationUntilPop)
	else
		self.States[State]:Subtract()
	end
end


function Combat:DivideSpeed(Amount : number)
	if self.LuaPlayer.IsNPC then
		self.LuaCharacter.Humanoid.WalkSpeed /= Amount
	else
		network.scaleSpeed.sendTo({ humanoid = self.LuaCharacter.Humanoid, amount = Amount, divide = true }, self.LuaPlayer.Player)
	end
end


function Combat:TimesSpeed(Amount : number)
	if self.LuaPlayer.IsNPC then
		self.LuaCharacter.Humanoid.WalkSpeed *= Amount
	else
		network.scaleSpeed.sendTo({ humanoid = self.LuaCharacter.Humanoid, amount = Amount, divide = false }, self.LuaPlayer.Player)
	end
end


function Combat:MinusDamage(Amount : number)
	self.DamageMultiplier -= Amount
end


function Combat:PlusDamage(Amount : number)
	self.DamageMultiplier += Amount
end


function Combat:MinusDefense(Amount : number)
	self.DefenseMultiplier -= Amount
end


function Combat:PlusDefense(Amount : number)
	self.DefenseMultiplier += Amount
end


function Combat:CancelAllAttacks()
	for Attack in self.ActiveAttacks do
		Attack:Cancel()
	end
end


function Combat:TriggerAntiTeam()
	if self:GetState("AntiTeam") then return end

	self:ResetStun()

	self:StackState("HitboxImmunity", true)
	self:StackState("Attacking", true)
	self:StackState("AntiTeam", true)
	self:DivideSpeed(50)

	local NewJob = Job.new()
	self.Animations.AntiTeam:Play(0.1, 1, 1.35)

	local Hitbox = self.Hitbox:Create()
	Hitbox.Params.Offset = CFrame.identity
	Hitbox.Params.Size = Vector3.one * 16

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontCheckBlock = true
		})

		if Validated then
			self:TSBPushVictim(VictimLuaPlayer, {
				DontBeginAoeHitbox = true,
				LookVectorInsteadOfDifference = true,
				LandedRollVelocityZ = 185,
				LandedRollDuration = 0.92
			})
		end
	end)

	local Pushed = false

	NewJob:Task(function()
		Hitbox:Destroy()

		task.delay(1, function()
			self:StackState("HitboxImmunity", false)
		end)

		if not Pushed then
			self.Animations.AntiTeam:Stop()
		else
			task.delay(0.5, self.Animations.AntiTeam.Stop, self.Animations.AntiTeam, 0.2)
		end

		self:TimesSpeed(50)

		self:StackState("AntiTeam", false)
		self:StackState("Attacking", false)
	end)

	NewJob:Task(self.Animations.AntiTeam:GetMarkerReachedSignal("push"):Connect(function()
		self.LuaPlayer.Replication:FireReliableVFX("Global/AntiTeam", "Push", self.LuaCharacter.RootPart)
		Hitbox:Detect()

		task.wait()

		Pushed = true
		NewJob:Destroy()
	end))
end

function Combat:Unstun()
	self:_CreateState("Stunned")

	local Thread = coroutine.running();

	if self.StunThreads[Thread] then
		self.StunThreads[Thread] = nil
	end

	if self.States.Stunned:IsTrue() then 
		self:StackState("Stunned", false) 

		if self.States.Stunned:IsFalse() then
			self:ResetAntiTeam()
			self:TimesSpeed(50)
		end
	end
end

function Combat:ResetAntiTeam()
	self.StunJob:Clean();
	self.Multistunned = nil;
	table.clear(self.StunnedBy)
end

function Combat:ResetStun()
	if self.States.Stunned:IsTrue() then
		self:TimesSpeed(50)
	end

	for StunThread in self.StunThreads do
		task.cancel(StunThread)
	end

	self:ResetAntiTeam()

	table.clear(self.StunThreads)

	self:ResetState("Stunned")
end

function Combat:_Stun(Duration : number?)
	self:_CreateState("Stunned")

	if self.States.Stunned:IsFalse() then
		self:DivideSpeed(50)
	end

	self:StackState("Stunned", true)
	self:CancelAllAttacks()

	self:_UnstunThread(Duration)
end

function Combat:_AntiTeamStun(AttackerPlayer, Duration : number?)
	self:_CreateState("Stunned")

	if self.States.Stunned:IsFalse() then
		self:DivideSpeed(50)
	end

	self:StackState("Stunned", true)
	self:CancelAllAttacks()

	local TimeNow = time()

	if not self.LuaPlayer.IsNPC then
		if not self.StunnedBy[AttackerPlayer] then
			self.StunnedBy[AttackerPlayer] = 0;
		end;

		self.StunnedBy[AttackerPlayer] += 1

		if Duration then
			task.delay(Duration, function()
				if (self.StunnedBy[AttackerPlayer] == nil) then return end

				if self.StunnedBy[AttackerPlayer] <= 0 then
					self.StunnedBy[AttackerPlayer] = nil;
				else
					self.StunnedBy[AttackerPlayer] -= 1;
				end;
			end)
		end;

		if Utility.TableCount(self.StunnedBy) > 1 and not self.Multistunned then
			self.Multistunned = TimeNow

			self.StunJob:Task(task.delay(0.5, function()
				while true do
					local StunCount = Utility.TableCount(self.StunnedBy);

					if StunCount <= 0 then
						self:ResetAntiTeam()
						break;
					end;

					if StunCount > 1 or time() - TimeNow > 1 then
						task.defer(self.TriggerAntiTeam, self)
						break;
					end

					task.wait(0.2)
				end;
			end))
		end;
	end;

	--if not self.LuaPlayer.IsNPC and Utility.TableCount(self.StunnedBy) > 1 and TimeNow - self.LastStunned > 0.15 then
	--	task.defer(self.TriggerAntiTeam, self)
	--end

	--self.LastStunned = TimeNow

	self:_UnstunThread(Duration)
end

function Combat:_UnstunThread(Duration : number)
	if (Duration ~= nil) then
		local Thread = task.delay( (Duration * self.StunMultiplier), self.Unstun, self );

		self.StunThreads[Thread] = true;
	end
end

function Combat:Stun(Duration : number)
	if not self:GetState("StunImmunity") then
		self:_Stun(Duration)
	end
end

function Combat:AntiTeamStun(AttackerLuaPlayer, Duration : number)
	if not self:GetState("StunImmunity") then
		self:_AntiTeamStun(AttackerLuaPlayer, Duration)
	end
end

Combat.TrueStun = Combat._Stun
Combat.TrueAntiTeamStun = Combat._AntiTeamStun

--function Combat:TrueStun(Duration : number)
--	self:_Stun()
--end

--function Combat:TrueAntiTeamStun(AttackerLuaPlayer, Duration : number)
--	self:_AntiTeamStun(AttackerLuaPlayer, Duration)
--end

function Combat:StartGrabAlign(VictimLuaPlayer, BoundTo : BasePart, Offset : CFrame, PresetName : string)
	Offset = Offset or CFrame.identity

	local VictimLuaCharacter = VictimLuaPlayer.Character
	local VictimCombat = VictimLuaCharacter.Combat

	local GrabAttachment = Instance.new("Attachment")
	GrabAttachment.Name = "GrabAttachment"
	GrabAttachment.CFrame = Offset

	local AlignPosition = Instance.new("AlignPosition")
	AlignPosition.Attachment0 = VictimLuaCharacter.RootAttachment
	AlignPosition.Attachment1 = GrabAttachment
	AlignPosition.RigidityEnabled = true

	local AlignOrientation = Instance.new("AlignOrientation")
	AlignOrientation.Attachment0 = VictimLuaCharacter.RootAttachment
	AlignOrientation.Attachment1 = GrabAttachment
	AlignOrientation.RigidityEnabled = true

	if self:IsntTheSamePerson(VictimLuaPlayer) then -- reflecition fix
		AlignPosition.Parent = GrabAttachment
		AlignOrientation.Parent = GrabAttachment

		network.grabSet.sendToAll({ part = VictimLuaCharacter.RootPart, boundTo = BoundTo, offset = Offset, preset = PresetName })

		GrabAttachment.Parent = self.LuaCharacter.RootPart --(BoundTo == self.LuaCharacter.RootPart and self:GetSimulatedRoot() or BoundTo)
	end

	return GrabAttachment, AlignPosition, AlignOrientation
end

function Combat:GrabVictim(VictimLuaPlayer, BoundTo : BasePart, Offset : CFrame, PresetName : string)
	local VictimLuaCharacter = VictimLuaPlayer.Character
	local VictimCombat = VictimLuaCharacter.Combat

	if VictimCombat:GetState("Grabbed") then 
		return 
	end

	local GrabObject = {}
	GrabObject.Job = Job.new()
	GrabObject.Destroyed = false

	if VictimLuaPlayer.IsNPC and VictimLuaCharacter.HumanoidAlive then
		VictimLuaCharacter.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
	end

	local GrabAttachment : Attachment, AlignPosition : AlignPosition, AlignOrientation : AlignOrientation = self:StartGrabAlign(VictimLuaPlayer, BoundTo, Offset, PresetName)

	if GrabAttachment then
		GrabObject.Job:Task(GrabAttachment)
	end

	if self:IsntTheSamePerson(VictimLuaPlayer) then
		self:StackState("GrabIFrames", true)
		VictimCombat:StackState("GrabIFrames", true)

		self:StackState("Grabbing", true)
		VictimCombat:StackState("Grabbed", true)

		VictimCombat:TrueStun()
		VictimCombat:ResetState("StunImmunity")
		VictimCombat.Ragdoll:ForceToggleOff()

		VictimCombat:CombatTag()

		GrabObject.Job:Task(Utility.StopAutoRotate(VictimLuaCharacter.Humanoid))

		self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
		VictimLuaCharacter:SetCollisionGroup("NoCollision")

		self.LuaCharacter:SetCameraOcclude(true)
		VictimLuaCharacter:SetCameraOcclude(true)

		GrabObject.Job:Task(self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value : boolean)
			if not Value then
				GrabObject.Destroy(0)
				VictimCombat:Unstun()
			end
		end))

		GrabObject.Job:Task(VictimLuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value : boolean)
			if not Value then
				GrabObject.Destroy(0)
			end
		end))
	end

	function GrabObject.SetOffset(NewOffset : CFrame)
		if not GrabObject.Destroyed and self:IsntTheSamePerson(VictimLuaPlayer) then
			network.grabSetOffset.sendToAll({ part = VictimLuaCharacter.RootPart, offset = NewOffset })
			GrabAttachment.CFrame = NewOffset
		end
	end

	function GrabObject.SetBound(NewBound : BasePart?)
		if not GrabObject.Destroyed and self:IsntTheSamePerson(VictimLuaPlayer) then
			network.grabSetBound.sendToAll({ part = VictimLuaCharacter.RootPart, boundTo = NewBound })

			if (NewBound == nil) then
				self.LuaCharacter:SetCollisionGroup("Player")
				VictimLuaCharacter:SetCollisionGroup("Player")
			else
				self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
				VictimLuaCharacter:SetCollisionGroup("NoCollision")
			end

			AlignPosition.Enabled = (NewBound ~= nil)
			AlignOrientation.Enabled = (NewBound ~= nil)

			GrabAttachment.Parent = NewBound
		end
	end

	function GrabObject.Destroy(OwnerIFrameDuration : number)
		if GrabObject.Destroyed then return end

		OwnerIFrameDuration = OwnerIFrameDuration or 0

		GrabObject.Destroyed = true
		GrabObject.Job:Destroy()

		if self:IsntTheSamePerson(VictimLuaPlayer) then
			network.grabDetach.sendToAll(VictimLuaCharacter.RootPart)

			self.LuaCharacter:SetCollisionGroup("Player")
			VictimLuaCharacter:SetCollisionGroup("Player")

			self.LuaCharacter:SetCameraOcclude(false)
			VictimLuaCharacter:SetCameraOcclude(false)

			VictimCombat:StackState("GrabIFrames", false)

			self:StackState("Grabbing", false)
			VictimCombat:StackState("Grabbed", false)

			if (OwnerIFrameDuration == 0) then
				self:StackState("GrabIFrames", false)
			else
				task.delay(OwnerIFrameDuration or 1, function()
					self:StackState("GrabIFrames", false)
				end)
			end
		end
	end

	return GrabObject
end

function Combat:IsntTheSamePerson(VictimLuaPlayer)
	return (self.LuaPlayer.Player ~= VictimLuaPlayer.Player)
end

function Combat:ClearBodyVelocities()
	Velocity.Utility.Clear(self.LuaCharacter.RootPart)
end

function Combat:CreateBodyVelocity(Name : string)
	return Velocity.Utility.Create(self.LuaCharacter.RootPart, Name)
end

function Combat:Velocity(Vector: Vector3?, Duration: number?) -- SERVER SIDE
	local NewVelocity = Velocity.new(self);

	if Vector then
		NewVelocity.Settings.Velocity = Vector;
	end;

	if Duration then
		NewVelocity.Settings.Duration = Duration;
	end;

	return NewVelocity;
end;

function Combat:TSBPushVictim(VictimLuaPlayer, Settings : {})
	local VictimLuaCharacter = VictimLuaPlayer.Character
	local VictimCombat = VictimLuaCharacter.Combat

	if VictimCombat.RemoveCurrentPush then
		if VictimCombat.Animations.Push.IsPlaying then
			VictimCombat.Animations.Push:Stop(0)
		end

		VictimCombat.RemoveCurrentPush()
	end

	--if Settings.OverridePrevious and VictimCombat.RemoveCurrentPush then
	--	if VictimCombat.Animations.Push.IsPlaying then
	--		VictimCombat.Animations.Push:Stop(0)
	--	end

	--	VictimCombat.RemoveCurrentPush()
	--else
	--	if VictimCombat:GetState("Pushed") then 
	--		return
	--	end
	--end

	if not VictimLuaCharacter.HumanoidAlive then 
		VictimCombat.Ragdoll:Toggle(true)
		VictimCombat:Velocity(self.LuaCharacter.RootPart.CFrame.LookVector * 50 + Vector3.yAxis * 35, 0.1)

		return 
	end

	VictimCombat:StackState("Pushed", true)

	VictimCombat:ResetState("StunImmunity")
	VictimCombat:TrueStun()

	VictimCombat.Ragdoll:ForceToggleOff()
	VictimCombat:CombatTag()

	VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")

	local NewJob = Job.new()

	local VictimStopAutoRotate = Utility.StopAutoRotate(VictimLuaCharacter.Humanoid)

	if VictimLuaPlayer.IsNPC then
		VictimLuaCharacter:SetOwnership(nil)
		VictimLuaCharacter.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
	end

	local Start = os.clock()
	local Difference

	if Settings.LookVectorInsteadOfDifference then
		Difference = self:GetSimulatedRoot().CFrame.LookVector
	else
		Difference = Settings.Difference or self:CalculateUnitDifference(VictimLuaPlayer)
	end

	local CF = CFrame.lookAt(Vector3.zero, -Difference * XZAxis) + VictimLuaCharacter.RootPart.Position
	VictimLuaCharacter.Model:PivotTo(CF)

	local Gyro = Instance.new("BodyGyro")
	Gyro.CFrame = CF
	Gyro.MaxTorque = Vector3.one * 80000
	Gyro.P = 5000
	Gyro.Parent = VictimLuaCharacter.RootPart
	NewJob:Task(Gyro)

	local VerticalLeak = Settings.VerticalLeak or 0.5---0.3

	local DirectionNoY = (Difference * XZAxis)

	local OriginalDirection = Difference.Unit
	local FlattenedDirection = AenoirUtil.Unit(DirectionNoY.Unit, (self:GetSimulatedRoot().CFrame.LookVector * XZAxis).Unit)

	--if DirectionNoY.Magnitude < 0.01 then
	--	FlattenedDirection = (self:GetSimulatedRoot().CFrame.LookVector * XZAxis).Unit
	--else
	--	FlattenedDirection = DirectionNoY.Unit
	--end

	local FinalPushDirection = FlattenedDirection:Lerp(OriginalDirection, VerticalLeak)

	--local PushDirection = AenoirUtil.Unit(
	--	(Difference * Vector3.new(1, 0.1, 1)).Unit, 
	--	(self:GetSimulatedRoot().CFrame.LookVector * XZAxis)
	--)

	local VelocityObject = VictimCombat:Velocity()
	VelocityObject.Settings.MaxForce =  XZAxis * 80000
	VelocityObject.Settings.Duration = Settings.LandedRollDuration
	VelocityObject.Settings.Velocity = FinalPushDirection * Settings.LandedRollVelocityZ
	VelocityObject:Fire()

	VictimLuaPlayer.Replication.Attributes:SetAttribute("Landed", true)
	self.LuaPlayer.Replication:FireVFX("Global/Push", "Land", VictimLuaCharacter.RootPart, Settings.LandedRollDuration)

	if not VictimLuaPlayer.IsNPC then
		VictimLuaPlayer.Replication.Attributes:SetAttribute("DestructibleDestroyLoop", true)
		network.destructibleLoop.sendTo({ offset = CFrame.new(0, 0, -4), size = Vector3.one * 6 }, VictimLuaPlayer.Player)

		NewJob:Task(function()
			VictimLuaPlayer.Replication.Attributes:SetAttribute("DestructibleDestroyLoop", nil)
		end)
	else
		NewJob:Task(RunService.PostSimulation:Connect(function()
			VictimCombat.Hitbox:Destruction(CFrame.new(0, -1, -4), Vector3.one * 6, 1)
		end))
	end

	local SimulatedRoot : BasePart = VictimCombat:GetSimulatedRoot()
	local AOEHitbox = VictimCombat.Hitbox:AoeHitboxForGrabs(self.LuaPlayer, CFrame.identity, Vector3.one * 8)
	AOEHitbox.Params.DestroyOnEndCast = false

	NewJob:Task(task.spawn(function()
		while task.wait(0.1) do
			if (SimulatedRoot == nil) then break end

			local CF : CFrame = SimulatedRoot.CFrame * CFrame.new(0, 1, -4.5)

			VictimCombat.Hitbox:CreateHavocReplicated({
				parameters = {
					origin = CF,
					size = Vector3.new(6.5, 4, 12), 
					shape = "Box", 
					block_size = 4, 
				},
				crater = {},
				debris = {
					scale = 0.9,
					velocity = function(cube)
						return (CF.UpVector * (15 + cube:GetMass() / 2)) + Random.new():NextUnitVector() * 10;
					end 
				},
			})
		end
	end))

	if not Settings.DontBeginAoeHitbox then
		AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
			VictimCombat:Afflict(NewVictimLuaPlayer, {
				TriggerActiveCounterOverOrEqualLevel = -1,
				DontBypassIFrames = {"Grab", "Backdash"},
				BreakBlock = true,
				Damage = 3,
				Ragdoll = 1.5,
				Velocity = {  VictimLuaPlayer.Character.Combat:CalculateUnitDifference(NewVictimLuaPlayer) * 35 + Vector3.yAxis * 25, 0.1}
			})
		end)

		AOEHitbox:BeginCast()
	end

	local function Remove()
		VictimCombat.RemoveCurrentPush = nil
		NewJob:Destroy()

		VelocityObject:Destroy()

		AOEHitbox:EndCast()
		AOEHitbox:Destroy()

		VictimCombat:StackState("Pushed", false)
		VictimLuaPlayer.Replication.Attributes:SetAttribute("Landed", nil)

		VictimStopAutoRotate:Destroy()

		if not VictimCombat:GetState("Grabbed") then
			VictimLuaCharacter:SetCollisionGroup("Player")
		end

		if VictimCombat.Animations.Push.IsPlaying then
			VictimCombat.Animations.Push:Stop(0.25)
		end

		task.delay(0.25, function()
			VictimCombat:Unstun()
		end)
	end

	VictimCombat.RemoveCurrentPush = Remove

	NewJob:Task(task.delay(Settings.LandedRollDuration * (Settings.DurationMultiplier or 1), Remove))

	NewJob:Task(VictimCombat.OnStateUpdated:Connect(function(StateChanged : any, Value : any)
		if ( (StateChanged == "Stunned" or StateChanged == "Ragdolled") and Value) then
			Remove()
			VictimCombat.Animations.Push:Stop()
		end
	end))

	VictimCombat.Animations.Push:Play(0)

	if Settings.AntiWallCombo then
		local NearWall = workspace:Raycast(VictimLuaCharacter.RootPart.Position, Difference * 7.5, Utility.VisualParams)

		if NearWall then
			VictimLuaPlayer.Replication:FireReliableVFX("Global/Dashing/Forward Dash", "WallSlam", VictimLuaCharacter.RootPart, Difference)

			VictimCombat:StackState("CannotDash", true, 1.5)
			VictimCombat.Ragdoll:Toggle(true, 1.5)

			local VelocityObject = VictimCombat:Velocity()
			VelocityObject.Settings.MaxForce = Vector3.one * 80000
			VelocityObject.Settings.RemoveTime = 0.1
			VelocityObject.Settings.Velocity = -Difference * 70 + Vector3.yAxis * 35
			VelocityObject:Fire()
		end
	end
end


function Combat:PushSkidVictim(VictimLuaPlayer, Settings : {})
	local VictimLuaCharacter = VictimLuaPlayer.Character

	if not VictimLuaCharacter.HumanoidExists or not self.LuaCharacter.HumanoidExists then return end

	local VictimCombat = VictimLuaCharacter.Combat

	if not VictimLuaCharacter.HumanoidAlive then 
		VictimCombat.Ragdoll:Toggle(true)
		VictimCombat:Velocity(self.LuaCharacter.RootPart.CFrame.LookVector * 50 + Vector3.yAxis * 35, 0.1)

		return 
	end

	local Push : BodyVelocity = VictimCombat:CreateBodyVelocity()

	if (Push == nil) then
		VictimCombat.Ragdoll:Toggle(true, 2)
		VictimCombat:Velocity(self:CalculateUnitDifference(VictimLuaPlayer) * 50 + Vector3.yAxis * 25, 0.1)

		return
	end

	--VictimCombat:ResetState("StunImmunity")
	VictimCombat:StackState("StunImmunity", true, Settings.LandedRollDuration / 2)
	VictimCombat:TrueStun()

	VictimCombat:StackState("Pushed", true)

	VictimLuaPlayer.Replication.Attributes:SetAttribute("CraterImpact", true)
	VictimLuaPlayer.Replication.Attributes:SetAttribute("Pushed", true)

	VictimCombat.Ragdoll:ForceToggleOff()
	VictimCombat:CombatTag()

	local NewJob = Job.new()
	local VictimStopAutoRotate = Utility.StopAutoRotate(VictimLuaCharacter.Humanoid)

	if VictimLuaPlayer.IsNPC then
		VictimLuaCharacter:SetOwnership(nil)
	end

	local Difference = (Settings.StartVelocity or Settings.StartVelocityXZ)

	if Difference ~= Difference then -- difference is nan so its killing them
		Difference = self.LuaCharacter.RootPart.CFrame.LookVector
	end

	local CF = CFrame.lookAt(Vector3.zero, -Difference * XZAxis) + VictimLuaCharacter.RootPart.Position

	Push.MaxForce = Vector3.one * 80000
	Push:AddTag("RemoveOnEvasive")
	Push.Parent = VictimLuaCharacter.RootPart

	VictimLuaCharacter.RootPart.CFrame = CF

	local Gyro = Instance.new("BodyGyro")
	Gyro.CFrame = CF
	Gyro.MaxTorque = Vector3.one * 80000
	Gyro.P = 5000
	Gyro.Parent = VictimLuaCharacter.RootPart
	Gyro:AddTag("RemoveOnEvasive")
	NewJob:Task(Gyro)

	local PushConnection

	local DetectedGround = EventService.new()

	local Removed = false
	local HitGround = false

	self.LuaCharacter:SetCollisionGroup("NoPlayerCollision") 
	VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")

	local function Remove()
		if Removed then return end

		Removed = true
		VictimCombat.RemoveCurrentPush = nil

		if not Settings.CannotEvasive then
			VictimCombat:StackState("EvasiveState", false)
		end

		NewJob:Destroy()

		self.LuaCharacter:SetCollisionGroup("Player") VictimLuaCharacter:SetCollisionGroup("Player")

		Push:Destroy()
		VictimCombat:StackState("Pushed", false)

		VictimStopAutoRotate:Destroy()

		VictimLuaPlayer.Replication.Attributes:SetAttribute("CraterImpact", nil)
		VictimLuaPlayer.Replication.Attributes:SetAttribute("Pushed", nil)
		VictimLuaPlayer.Replication.Attributes:SetAttribute("Landed", nil)

		if VictimCombat.Animations.Push.IsPlaying then
			VictimCombat.Animations.Push:Stop(0.25)
		end

		task.delay(0.25, function()
			VictimCombat:Unstun()
		end)

		if not Settings.CannotEvasive then 
			VictimCombat:StackState("CannotDash", false)
		end
	end

	Push.Destroying:Once(Remove)
	VictimCombat.RemoveCurrentPush = Remove

	NewJob:Task(VictimLuaCharacter.Combat.Animations.Push:GetMarkerReachedSignal("freeze"):Once(function()
		if HitGround then return end

		VictimLuaCharacter.Combat.Animations.Push:AdjustSpeed(0)
	end))

	NewJob:Task(VictimCombat.OnStateUpdated:Connect(function(StateChanged : any, Value : any)
		if ( (StateChanged == "Stunned" or StateChanged == "Ragdolled") and Value) then
			Remove()
			VictimCombat.Animations.Push:Stop()
		end
	end))

	local AirTime = 0

	coroutine.wrap(function()
		if VictimLuaPlayer.Player:GetAttribute("FakePing") then
			task.wait(VictimLuaPlayer.Player:GetAttribute("FakePing") / 1000)
		end

		local UppercutLike = (Settings.StartVelocity == nil)

		if UppercutLike then
			local Start = os.clock()

			PushConnection = NewJob:Task(RunService.PostSimulation:Connect(function()
				local TimeFromStart = (os.clock() - Start)

				local YVelocity = Settings.StartVelocityY * (Settings.StartDuration - TimeFromStart / Settings.StartDuration)
				Push.Velocity = (Settings.StartVelocityXZ + YVelocity)
			end))
		else
			Push.Velocity = Settings.StartVelocity
		end
	end)()

	DetectedGround:Once(function(AntiStuckTrigger : boolean?)
		HitGround = true

		if (PushConnection ~= nil) then
			PushConnection:Disconnect()
		end

		if AntiStuckTrigger then
			return Push:Destroy()
		end

		if not Settings.CannotEvasive then 
			VictimCombat:StackState("CannotDash", true)
		end

		VictimLuaPlayer.Replication.Attributes:SetAttribute("Pushed", nil)
		VictimLuaPlayer.Replication.Attributes:SetAttribute("Landed", true)
		self.LuaPlayer.Replication:FireVFX("Global/Push", "Land", VictimLuaCharacter.RootPart, Settings.LandedRollDuration)

		NewJob:Task(task.delay(Settings.LandedRollDuration * (Settings.LandedRollDurationMultiplier or 1), Remove))

		Push.MaxForce = XZAxis * 80000
		Push.Velocity = Vector3.zero

		self.LuaCharacter:SetCollisionGroup("Player") VictimLuaCharacter:SetCollisionGroup("Player")
		VictimLuaCharacter.Combat.Animations.Push:AdjustSpeed(1)

		local BehindVector = -VictimLuaCharacter.RootPart.CFrame.LookVector
		local Velocity = BehindVector * Settings.LandedRollVelocityZ

		local Start = os.clock()

		NewJob:Task(RunService.PostSimulation:Connect(function()
			if Settings.ScaleLandedRollVelocityWithAirTime then
				local ScaledWithAirTime = (Vector3.new(1, 0, 1) / math.max(1, AirTime / (Settings.AirTimeScaleToRoll or 12.5)))
				Push.Velocity = (Velocity * ScaledWithAirTime)
			else
				Push.Velocity = Velocity
			end

			Push.Velocity *= math.max(0, Settings.LandedRollDuration - (os.clock() - Start) / Settings.LandedRollDuration)
		end))
	end)

	NewJob:Task(VictimCombat:AnticipateGround(Settings.GroundDetectionPrecisionValue or 5, Settings.GroundDetectionPrecisionTime, Settings.TimeTilGroundDetection, function(AntiStuckTrigger : boolean)
		DetectedGround:Fire(AntiStuckTrigger)
	end))

	VictimCombat.Animations.Push:Play()

	self.LuaPlayer.Replication:FireVFX("Global/Push", "Up", VictimLuaCharacter.RootPart)

	if not Settings.CannotEvasive then -- ummmm idk
		VictimCombat:StackState("EvasiveState", true)
	end
end


function Combat:AnticipateGround(Precision : number, PrecisionTime : number, DelayTime : number, Fn : () -> ())
	local DetectGroundThread : thread = nil

	local function Clean()
		if (DetectGroundThread ~= nil and coroutine.status(DetectGroundThread) == "suspended") then
			task.cancel(DetectGroundThread)
		end

		DetectGroundThread = nil
	end

	local AttackerRoot : BasePart = self:GetSimulatedRoot()
	local WorkspaceSetting = workspace:GetAttribute("DebugGroundDetect")

	DetectGroundThread = coroutine.create(function()
		while self.LuaCharacter.HumanoidExists do

			local AssemblyVelocity : Vector3 = AttackerRoot.AssemblyLinearVelocity;
			local UnitAssemblyVelocity : Vector3 = AenoirUtil.Unit(AssemblyVelocity, -Vector3.yAxis * Precision)
			local Velocity = UnitAssemblyVelocity * (math.max(1.5, AssemblyVelocity.Magnitude / Precision))

			local Raycast

			if WorkspaceSetting then
				Raycast = Utility.RaycastWithDebug(AttackerRoot.Position, Velocity, Utility.VisualParams)
			else
				Raycast = workspace:Raycast(AttackerRoot.Position + Vector3.yAxis, Velocity, Utility.VisualParams)
			end

			local AntiStuckTrigger = (AssemblyVelocity.Magnitude <= 2)

			if (AntiStuckTrigger or Raycast ~= nil) then
				task.spawn(Fn, AntiStuckTrigger)
				Clean()

				break
			end

			if (PrecisionTime ~= nil) then
				task.wait(PrecisionTime)
			else
				RunService.PreSimulation:Wait()
			end

		end
	end)

	if (DelayTime ~= nil) then
		task.delay(DelayTime, function()
			if (DetectGroundThread ~= nil) then
				coroutine.resume(DetectGroundThread)
			end
		end)
	else
		coroutine.resume(DetectGroundThread)
	end

	self.LuaCharacter.HumanoidJob:Task(Clean)
	return DetectGroundThread
end

function Combat:VictimImpactGround(VictimLuaPlayer)--, OnImpact : () -> ())
	local VictimLuaCharacter = VictimLuaPlayer.Character
	VictimLuaPlayer.Replication:FireReliableVFX("Global/Impact", "CraterImpact", self.LuaCharacter.Model, VictimLuaCharacter.RootPart)

	--local RagdollConnection : RBXScriptConnection = nil

	--local Thread = VictimCombat:AnticipateGround(true, nil, 0.1, function()
	--	if (RagdollConnection ~= nil and RagdollConnection.Connected) then
	--		RagdollConnection:Disconnect()
	--	end

	--	if (OnImpact ~= nil) then
	--		coroutine.wrap(OnImpact)()
	--	else
	--		VictimCombat:Velocity((VictimLuaCharacter.RootPart.Position - self.LuaCharacter.RootPart.Position).Unit * 20 + Vector3.yAxis * 35, 0.1)

	--		if not VictimLuaCharacter.HumanoidAlive then
	--			VictimCombat.Ragdoll:Toggle(true)
	--		else
	--			VictimCombat.Ragdoll:Toggle(true, 1)
	--		end

	--		VictimLuaCharacter.Humanoid:TakeDamage(5)
	--	end

	--	self:Afflict(VictimLuaPlayer, {
	--		ExcludeAttempts = true,
	--		Damage = 5,
	--	})

	--	local Hitbox = VictimCombat.Hitbox:Create()
	--	Hitbox.Params.Offset = CFrame.new(0, 3, 0)
	--	Hitbox.Params.Size = Vector3.one * 13

	--	Hitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
	--		VictimCombat:Afflict(NewVictimLuaPlayer, {
	--			BreakBlock = true,
	--			Damage = 3,
	--			Ragdoll = 2,
	--			Velocity = {(NewVictimLuaPlayer.Character.RootPart.Position - VictimLuaCharacter.RootPart.Position).Unit * 20 + Vector3.yAxis * 35, 0.1}
	--		})
	--	end)

	--	Hitbox:BeginCast(0.05)
	--end)

	--RagdollConnection = VictimLuaCharacter.HumanoidJob:Task(VictimCombat:GetStateChanged("Ragdolled"):Connect(function()
	--	if not VictimCombat:GetState("Ragdolled") then
	--		RagdollConnection:Disconnect()

	--		if (Thread ~= nil and coroutine.status(Thread) == "suspended") then
	--			task.cancel(Thread)

	--		end; Thread = nil

	--		VictimLuaPlayer.Replication.Attributes:SetAttribute("CraterImpact", false)
	--	end
	--end))
end

function Combat:ImpactOnGroundHit()
	self.LuaPlayer.Replication:FireReliableVFX("Global/Impact", "CraterImpact", self.LuaCharacter.Model, self.LuaCharacter.RootPart)
end

local Reactions = {"Left", "Right", "Front", "Back"}

function Combat:TranslateHitReaction(Value : number)
	return Reactions[Value];
end

function Combat:PlayRandomHitReaction(Max : number)
	local Animation = Utility.PickRandom(Reactions, function(Choice)
		return Choice ~= self.LastHitReaction
	end)

	self.LastHitReaction = Animation

	for _, AnimationPlaying : AnimationTrack in self.Animations.HitReactions do
		if AnimationPlaying.IsPlaying then
			AnimationPlaying:Stop(0)
		end
	end

	if (self.Animations.HitReactions[Animation] ~= nil) then
		self.Animations.HitReactions[Animation]:Play(0, 0.85, 1)
	end
end


function Combat:PlayCertainHitReaction(Value : number)
	local Animation = self:TranslateHitReaction(Value)

	for _, Animation : AnimationTrack in self.Animations.HitReactions do
		if Animation.IsPlaying then
			Animation:Stop(0)
		end
	end

	if (self.Animations.HitReactions[Animation] ~= nil) then
		self.Animations.HitReactions[Animation]:Play(0, 0.85, 1)
	end
end

function Combat:TeleportForward(DistanceToCover : number,  Callback : () -> ())
	local Map = workspace.Map
	local MapModel = Map.Model

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Include
	Params.FilterDescendantsInstances = {}

	local Terrain = MapModel:FindFirstChild("Terrain")
	local Props = MapModel:FindFirstChild("Props")

	for _, Item in {Terrain, Locations, Props} do
		if Item then
			Params:AddToFilter(Item)
		end
	end

	local Root : BasePart = self:GetSimulatedRoot()
	local StartCF : CFrame = Root.CFrame
	local StartingY : number = StartCF.Position.Y

	local function FireRaycast(CF : CFrame, DistanceCovered: number)
		local Origin = CF.Position
		local Direction = StartCF.LookVector * DistanceToCover

		local Raycast = workspace:Raycast(Origin, Direction, Params) 

		if (Raycast ~= nil) then
			DistanceCovered += Raycast.Distance

			if Raycast.Normal:Dot(Vector3.yAxis) > 0.25 then
				DistanceToCover -= Raycast.Distance
				return FireRaycast(CFrame.lookAlong(Raycast.Position + Raycast.Normal, Direction), DistanceCovered)
			end

			local RayCF = CFrame.lookAlong(Raycast.Position, StartCF.LookVector)

			if Raycast.Instance:GetAttribute("Destructed") then
				Params:AddToFilter(Raycast.Instance)
				DistanceToCover -= Raycast.Distance

				return FireRaycast(RayCF, DistanceCovered)
			else

				local Raycast = workspace:Raycast(RayCF.Position, Vector3.yAxis * -8, Params)
				local FinalCF = RayCF

				if (Raycast ~= nil) then
					FinalCF = RayCF + Vector3.new(0, -Raycast.Distance + 3, 0)
				end

				local HitboxSizeAdjustY = math.abs(FinalCF.Y - StartingY)
				Callback(DistanceCovered, FinalCF, HitboxSizeAdjustY)

			end
		else
			local CF = CFrame.lookAlong(Origin + Direction, Direction)
			local HitboxSizeAdjustY = math.abs(CF.Y - StartingY)

			Callback(DistanceCovered + DistanceToCover, CF, HitboxSizeAdjustY)
		end
	end

	FireRaycast(StartCF, 0)
end

function Combat:GetRandomFriend(UseCache: boolean?) -- yields btw so task.spawn it - use the table inside self.LuaPlayer now - or use the parameter... - it dont matter no more
	return self.LuaPlayer:GetRandomFriend(UseCache);
end

function Combat:CreateMoveSFX(Character : string, MoveName : string, Name : string?)
	local Module = replicatedStorage.modules.client.replication.VFX:FindFirstChild(Character)

	if Module then
		local Move = Module:FindFirstChild(MoveName)
		if (Move == nil) then return end

		local SFX : Sound? = Move:FindFirstChild(Name or "SFX")
		if (SFX == nil) then return end

		if SFX:IsA("Folder") then
			local _, Attachment = EffectUtility.EmitEffects(SFX, self.LuaCharacter.Torso)

			return Attachment
		else
			local NewSFX = SFX:Clone()
			NewSFX.Parent = self.LuaCharacter.Torso

			local function Play()
				NewSFX:Play()

				if NewSFX.Looped then
					NewSFX:GetPropertyChangedSignal("Looped"):Once(function()
						if not NewSFX.Looped then
							task.delay(NewSFX.TimeLength, NewSFX.Destroy, NewSFX)
						end
					end)
				else
					task.delay(NewSFX.TimeLength, NewSFX.Destroy, NewSFX)
				end
			end

			local function WhenLoaded()
				local EmitDelay : number = NewSFX:GetAttribute("Delay") or 0

				if (EmitDelay > 0) then
					task.delay(EmitDelay, Play)
				else
					Play()
				end
			end

			if not NewSFX.IsLoaded then
				NewSFX.Loaded:Once(WhenLoaded)
			else
				WhenLoaded()
			end

			return NewSFX
		end
	end
end

function Combat.new(LuaCharacter)
	local self = setmetatable({}, Combat)

	self.Job = Job.new()

	self.LuaCharacter = LuaCharacter
	self.LuaPlayer = LuaCharacter.LuaPlayer

	self.Attacks = {}
	self.ActiveAttacks = {}
	self.HotbarAttacks = {}
	self.Animations = {}

	self.States = {}

	self.Values = {
		Jump = NumberStack.new(),
		Run = NumberStack.new()
	}

	self.CooldownsEnabled = true
	self.SpaceHeld = false
	self.Timestopped = false

	self.AirState = ""
	self.CurrentDevicePlayingOn = "Keyboard"

	self.OnStateUpdated = self.Job:Task(EventService.new());
	self.OnStateChanged = self.Job:Task(EventService.new());
	self.OnAttackChanged = self.Job:Task(EventService.new());
	self.OnAirStateChanged = self.Job:Task(EventService.new());
	self.OnSpaceStateChanged = self.Job:Task(EventService.new());
	self.OnDamageDealt = self.Job:Task(EventService.new());
	self.OnKill = self.Job:Task(EventService.new());
	self.OnFinisherKill = self.Job:Task(EventService.new());

	self.ClientJumping = false

	self.ClientLanded = self.Job:Task(EventService.new());
	self.ClientJumped = self.Job:Task(EventService.new());

	self.OnCharacterSwitching = self.Job:Task(EventService.new());
	self.OnCharacterSwitched = self.Job:Task(EventService.new());

	self.CurrentCharacter = {
		Name = "",
		Info = nil
	}

	self.SpawnJob = self.Job:Task(Job.new())
	self.StunJob = self.Job:Task(Job.new())

	self.StunnedBy = {}
	self.LastStunned = -1
	self.LastAfflictedDamage = -1;

	self.TotalBeenDamaged = {}
	self.TotalDealtDamage = {}
	self.StunThreads = {}

	self.SpeedMultiplier = 1;
	self.DamageMultiplier = 1;
	self.DefenseMultiplier = 1;
	self.StunMultiplier = 1

	self.AwardedToSomeoneAsKill  = false
	self.CurrentStreak = 0

	if not self.LuaPlayer.IsNPC and self.LuaPlayer:PlayerExists() then
		local Gui = Instance.new("ScreenGui")
		Gui.ResetOnSpawn = false
		Gui.Name = "StatesHolder"
		Gui.Parent = self.LuaPlayer.Player.PlayerGui

		self.AttributeStates = Instance.new("Configuration")
		self.AttributeStates.Name = "States"
		self.AttributeStates.Parent = Gui

		self.AttributeValues = Instance.new("Configuration")
		self.AttributeValues.Name = "Values"
		self.AttributeValues.Parent = Gui
	end

	self.KillSoundSettings = {
		Volume = 1.5,
		Pitch = 1,
	}

	self.CombatTagTime = 10

	----------------------------------------

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

if MovementReplicator and MovementReplicator.on_player_setting_changed then
	MovementReplicator.on_player_setting_changed:Connect(function(player, setting, value)
		if setting == "is_ragdolled" then
			local lua_player = LuaPlayerList.LuaPlayers[player]

			if lua_player then
				lua_player.Character.Combat.Ragdoll:Toggle(value)
			end
		end
	end)
end

----------------------------------------------------------------------------------

table.freeze(Combat)

return Combat