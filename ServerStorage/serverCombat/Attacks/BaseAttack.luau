local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local RunService = game:GetService("RunService")

local ServerStorage = game:GetService("ServerStorage")
----------------------------------------------------------------------------------

local Remotes = replicatedStorage.Remotes

local CombatRemotes = Remotes.Combat
local UIRemotes = CombatRemotes.UI

local AttackAnimations = replicatedStorage.Animations.Attacks

local Shared = replicatedStorage.modules.shared
local SharedUtilities = Shared.Utilities

local Preloading = require( ServerStorage.modules.preloading )
local AnimationProxy = require( "../AnimationProxy" );

local EventService = require( SharedUtilities.EventService )
local Utility = require( SharedUtilities.Utility )
local Job = require( SharedUtilities.Job )

----------------------------------------------------------------------------------

local BaseAttack = {}
BaseAttack.__index = BaseAttack

----------------------------------------------------------------------------------

function BaseAttack:Destroy()
	table.clear(self.TrackedCharacters);
	
	self:Close(); -- Was :Cancel, but if its uncancellable then the move will never close on respawn.
	self.Job:Destroy()
	
	if self.AttackFolder then
		Preloading.Remove(self.LuaPlayer.Player, self.AttackFolder)
	end
end

function BaseAttack:_Init() --stub
	
end

function BaseAttack:Initialise() --stub
	
end

function BaseAttack:UpdateAirVariantChecking(Extra : {})
	self.HoldingJump = ((Extra and Extra.HoldingJump) == true) or self.Combat.SpaceHeld --(Extra and (Extra.HoldingJump or false) or false)
	self.FreeFalling = (Extra and Extra.FreeFalling) == true --Extra and (Extra.FreeFalling or false) or false
	
	self.ClientSentExtra = Extra
end

function BaseAttack:Trigger()
	self:Close()
	self:TryToCancelAttacks()
	
	table.clear(self.TrackedCharacters);
	
	self.Thread = {
		Closed = false,
		Cancelled = false,
		Errored = false,

		OnClosed = EventService.new(),
		OnCancelled = EventService.new(),

		Job = Job.new(),
		CancelJob = Job.new(),

		Object = coroutine.create(function(...)
			local Success, Result = pcall(self.Activate, ...)

			if not Success then
				self:Close()
				self.Thread.Errored = true

				warn(Result)
			end
			
			--if RunService:IsStudio() then
			--	task.spawn(self.Activate, self, ...)
			--	-- shows a better error
			--else
			--	local Success, Result = pcall(self.Activate, ...)

			--	if not Success then
			--		self:Close()
			--		self.Thread.Errored = true

			--		warn(Result)
			--	end
			--end
		end)
	}

	task.spawn(self.Thread.Object, self);
	
	--self.Thread.Job:Task(self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value : boolean)
	--	if not Value then
	--		self:Cancel()
	--	end
	--end))
	
	if not self.Thread.Errored then
		if (self.Animations.Windup ~= nil) then
			if self.Animations.Windup.IsPlaying then
				self.Animations.Windup:Stop()
			end

			self.Animations.Windup:Play(self.AnimationSettings.FadeTime, self.AnimationSettings.Weight, self.AnimationSettings.Speed)
		end
		
		self.OnTriggered:Fire()
		self:AntiDashMovestack()
	end
end

function BaseAttack:ThreadAvailable()
	return (self.Thread ~= nil and not self.Thread.Closed)
end;

function BaseAttack:CloseForRespawn(...)
	self:Close(...);
end;

function BaseAttack:Close(...)
	if not self:ThreadAvailable() then return end
	
	self.Thread.Closed = true

	self.Thread.OnClosed:Fire(...)
	self.Thread.OnClosed:DisconnectAll()

	self.Thread.Job:Destroy()
	
	table.clear(self.VictimAnimations);
	
	if coroutine.status(self.Thread.Object) == "suspended" then
		task.cancel(self.Thread.Object);
	end
end

function BaseAttack:Cancel()
	if not self:ThreadAvailable() or self.Uncancellable then return end

	self.Thread.Cancelled = true

	self.Thread.OnCancelled:Fire()
	self.Thread.OnCancelled:DisconnectAll()
	
	self.Thread.CancelJob:Destroy()
	
	self:StopAllAnimations()
	self:Close()
end;

function BaseAttack:SetUncancellable(Value : boolean): ()
	self.Uncancellable = Value;
end;

function BaseAttack:StopAllAnimations()
	local Directory = self:GetAnimationDirectory()
	
	if Directory then
		for Index, Animation : AnimationTrack in Directory do
			if (Animation.Animation ~= nil and Animation.IsPlaying) then
				Animation:Stop()
			end
		end
	end
end

function BaseAttack:GetAnimationDirectory()
	self:UpdateAnimationDirectory()
	
	local MoveTable = (self.Combat:HasACharacter() and self.Combat.CurrentCharacter.Info[self.Directory.Name])

	if MoveTable then
		local CustomM1Directory = MoveTable.AnimationDirectory

		if CustomM1Directory then
			return CustomM1Directory(self) 
		end
	end
	
	return self.AnimationDirectory
end

function BaseAttack:UpdateAnimationDirectory()
	self.AnimationDirectory = (self.Animations[self.Combat.CurrentCharacter.Name] or self.Animations.Default or self.Animations)
end

--function BaseAttack:AddCooldown(Duration : number?, ClientActionLikeIndicator : boolean)
--	if self.OnCooldown or not self.Combat.CooldownsEnabled or not self.CooldownEnabled then return end

--	self.OnCooldown = true
--	self.OnCooldownChanged:Fire(true, Duration)

--	if not self.LuaPlayer.IsNPC then
--		HotbarRemotes.AddCooldown:FireClient(self.LuaPlayer.Player, self.Directory.Name, Duration)
		
--		if ClientActionLikeIndicator then
--			self.LuaPlayer.Remotes.ClientCooldownWithIndicator:FireClient(self.LuaPlayer.Player, self.Directory.Name, Duration)
--		end
--	end

--	self.CooldownThread = task.delay(Duration, self.RemoveCooldown, self)
--end

--function BaseAttack:RemoveCooldown()
--	if not self.OnCooldown then return end

--	self.OnCooldown = false
--	self.OnCooldownChanged:Fire(false)
	
--	if not self.LuaPlayer.IsNPC then
--		HotbarRemotes.RemoveCooldown:FireClient(self.LuaPlayer.Player, self.Directory.Name)
--	end

--	if (coroutine.status(self.CooldownThread) == "suspended") then
--		task.cancel(self.CooldownThread)
--	end

--	self.CooldownThread = nil
--end

function BaseAttack:AddCooldown(Duration : number, ClientActionLikeIndicator : boolean?)
	if self.OnCooldown or not self.CooldownEnabled then return end
	
	if (self.NameNoSpaces ~= "M1" and not self.Combat.CooldownsEnabled) then
		return
	end

	self.OnCooldown = true
	self.CooldownDuration = Duration
	self.CooldownStart = tick() -- Store the start time
	self.RemainingCooldown = Duration -- Default to full duration

	self.OnCooldownChanged:Fire(true, Duration)

	-- 🔹 Notify UI
	if not self.LuaPlayer.IsNPC then
		network.hotbarCooldown.sendTo({ move = self.Name, duration = Duration }, self.LuaPlayer.Player)
		
		if ClientActionLikeIndicator then
			network.moveCooldown.sendTo({ move = self.Name, duration = Duration }, self.LuaPlayer.Player)
		end
	end

	-- Start the cooldown thread
	self.CooldownThread = task.delay(Duration, function()
		self:RemoveCooldown()
	end)
end

function BaseAttack:RemoveCooldown()
	if not self.OnCooldown then return end

	self.OnCooldown = false
	self.OnCooldownChanged:Fire(false)

	-- 🔹 Notify UI
	if not self.LuaPlayer.IsNPC then
		network.hotbarRemoveCooldown.sendTo(self.Name, self.LuaPlayer.Player)
	end

	self:ResetCooldownThread()
	self.RemainingCooldown = nil
	self.CooldownStart = nil
end


function BaseAttack:ResetCooldownThread()
	if self.CooldownThread and coroutine.status(self.CooldownThread) == "suspended" then
		task.cancel(self.CooldownThread)
	end

	self.CooldownThread = nil
end

function BaseAttack:PauseCooldown()
	if not self.OnCooldown then return end

	local elapsedTime = tick() - self.CooldownStart
	self.RemainingCooldown = math.max(self.CooldownDuration - elapsedTime, 0) -- Calculate remaining time

	self:ResetCooldownThread()
	self.OnCooldownChanged:Fire(true, self.RemainingCooldown, "paused")

	-- 🔹 Notify UI about the pause
	if not self.LuaPlayer.IsNPC then
		network.hotbarRemoveCooldown.sendTo(self.Name, self.LuaPlayer.Player)
	end
end

function BaseAttack:ResumeCooldown()
	if not self.OnCooldown or not self.RemainingCooldown or self.RemainingCooldown <= 0 then return end

	self.CooldownStart = tick() -- Restart from now
	self.OnCooldownChanged:Fire(true, self.RemainingCooldown, "resumed")

	self:ResetCooldownThread()
	
	-- 🔹 Notify UI about the resume
	if not self.LuaPlayer.IsNPC then
		network.hotbarCooldown.sendTo({ move = self.Name, duration = self.RemainingCooldown }, self.LuaPlayer.Player)
	end

	self.CooldownThread = task.delay(self.RemainingCooldown, function()
		self:RemoveCooldown()
	end)
end


function BaseAttack:AddCertainCooldown(Name : string, Duration : number?, Ended : () -> (), ClientActionLikeIndicator : boolean)
	self:RemoveCertainCooldown(Name)

	if not self.LuaPlayer.IsNPC and ClientActionLikeIndicator then
		network.moveCooldown.sendTo({ move = Name, duration = Duration }, self.LuaPlayer.Player)
	end
	
	self.CertainCooldowns[Name] = task.delay(Duration, function()
		if (Ended ~= nil) then
			Ended()
		end
		
		self:RemoveCertainCooldown(Name)
	end)
end

function BaseAttack:RemoveCertainCooldown(Name : string)
	if (self.CertainCooldowns[Name] == nil) then return end

	if (coroutine.status(self.CertainCooldowns[Name]) == "suspended") then
		task.cancel(self.CertainCooldowns[Name])
	end

	self.CertainCooldowns[Name] = nil
end

function BaseAttack:HasCertainCooldown(Name : string)
	return (self.CertainCooldowns[Name] ~= nil)
end

BaseAttack.CertainCooldownExists = BaseAttack.HasCertainCooldown

function BaseAttack:UpdateAnimations()
	table.clear(self.Animations)
	
	for _, AttackFolder in ipairs(AttackAnimations:GetDescendants()) do
		if AttackFolder:IsA("Folder") and AttackFolder.Name == self.Directory.Name then
			self.AttackFolder = AttackFolder

			Preloading.Add(self.LuaPlayer.Player, AttackFolder)
			self.Combat:IterateThroughAnimationFolder(self.Animations, AttackFolder)

			break
		end;
	end;
	
	self:SetSpeedMultiplier(self.SpeedMultiplier);
end;

function BaseAttack:SetSpeedMultiplier(Speed: number)
	self.SpeedMultiplier = Speed;

	local Multiplier = self.Combat:GetSpeedMultiplier();
	
	local function ForeachAnimation(Animation)
		if typeof(Animation) ~= "table" then return end;

		if getmetatable(Animation) ~= AnimationProxy then
			for Key, Value in Animation do
				ForeachAnimation(Value);
			end;
		else
			Animation:SetSpeedMultiplier(Speed * Multiplier);
		end;
	end;
	
	ForeachAnimation(self.Animations);
end;

function BaseAttack:SetEnabled(Value: boolean)
	if self.Enabled ~= Value then
		self.Enabled = Value;
		
		if Value then
			self:ShowDisplay();
		else
			self:HideDisplay();
		end;
	end;
end;

function BaseAttack:ChangeDisplay(DisplayName, Settings)
	self.Combat:ChangeAttackDisplay(self.Name, DisplayName or self.DisplayName, Settings);
end;

function BaseAttack:HideDisplay()
	if self.LuaPlayer.IsNPC then return end;
	
	network.hotbarHide.sendTo(self.Name, self.LuaPlayer.Player)
end;

function BaseAttack:ShowDisplay()
	if self.LuaPlayer.IsNPC then return end;
	
	network.hotbarShow.sendTo(self.Name, self.LuaPlayer.Player);
end;

-- Wrapper that can decide whether to fire VFX
function BaseAttack:FireReliableVFXToSelf(Directory, Function, ...)
	if not self.VisualEffectsEnabled then
		return;
	end;

	self.LuaPlayer.Replication:FireReliableVFXToSelf(Directory, Function, ...);
end

-- Wrapper that can decide whether to fire VFX
function BaseAttack:FireReliableVFX(Directory, Function, ...)
	if not self.VisualEffectsEnabled then
		return;
	end;
	
	self.LuaPlayer.Replication:FireReliableVFX(Directory, Function, ...);
end

-- Wrapper that can decide whether to fire VFX
function BaseAttack:FireVFXToSelf(Directory, Function, ...)
	if not self.VisualEffectsEnabled then
		return;
	end;

	self.LuaPlayer.Replication:FireVFXToSelf(Directory, Function, ...);
end

-- Wrapper that can decide whether to fire VFX
function BaseAttack:FireVFX(Directory, Function, ...)
	if not self.VisualEffectsEnabled then
		return;
	end;

	self.LuaPlayer.Replication:FireVFX(Directory, Function, ...);
end

-- Wrapper that can apply multipliers
function BaseAttack:VelocityOn(VictimCombat)
	local Velocity = VictimCombat:Velocity();
	local VelocityFire = Velocity.Fire;
	
	function Velocity.Fire(_, ...)
		if Velocity.Settings.Velocity then
			local KnockbackMultiplier = self:GetKnockbackMultiplier();
			
			Velocity.Settings.Velocity *= KnockbackMultiplier;
		end;
		
		return VelocityFire(Velocity, ...);
	end;
	
	return Velocity;
end;

-- Wrapper that can apply multipliers, and fixes afflicting to a respawned character
function BaseAttack:Afflict(VictimLuaPlayer, Properties)
	if self.TrackedCharacters[VictimLuaPlayer] and self.TrackedCharacters[VictimLuaPlayer] ~= VictimLuaPlayer.Character.Model then
		return;
	end;
	
	-- Apply per attack damage multiplier
	if Properties.Damage then
		local DamageMultiplier = self:GetDamageMultiplier();
		
		if typeof(Properties.Damage) == "number" then
			Properties.Damage *= DamageMultiplier;
		else
			Properties.Damage.Amount *= DamageMultiplier;
		end;
	end;
	
	if Properties.Ragdoll then
		local RagdollMultiplier = self:GetRagdollMultiplier();

		Properties.Ragdoll *= RagdollMultiplier;
	end;
	
	if Properties.Stun then
		local StunMultiplier = self:GetStunMultiplier();
		
		Properties.Stun *= StunMultiplier;
	end;
	
	if Properties.TrueStun then
		local StunMultiplier = self:GetStunMultiplier();
		
		Properties.TrueStun *= StunMultiplier;
	end;
	
	Properties.SourceAttack = self;
	
	local Validated, Result = self.Combat:Afflict(VictimLuaPlayer, Properties);
	
	self.TrackedCharacters[VictimLuaPlayer] = VictimLuaPlayer.Character.Model;
	self.OnAfflict:Fire(VictimLuaPlayer, Properties, Validated, Result);
	
	return Validated, Result;
end;

function BaseAttack:CreateMoveSFX(Character : string, MoveName : string, Name : string?)
	if not self.SoundEffectsEnabled then
		return Instance.new("Sound");
	end;
	
	return self.Combat:CreateMoveSFX(Character, MoveName, Name);
end;

function BaseAttack:GetRagdollMultiplier(): number
	return self.RagdollMultiplier or 1;
end

function BaseAttack:GetDamageMultiplier(): number
	return self.DamageMultiplier or 1;
end

function BaseAttack:GetKnockbackMultiplier(): number
	return self.KnockbackMultiplier or 1;
end;

function BaseAttack:GetStunMultiplier(): number
	return self.StunMultiplier or 1;
end

function BaseAttack:IsFinisherEnabled(): boolean
	return self.FinisherEnabled;
end

function BaseAttack:BasicConditions() : boolean
	local Conditions = not self.Combat:GetState("Stunned") 
		and not self.Combat:GetState("Attacking") 
		and not self.Combat:GetState("Ragdolled") 
		and not self.Combat:GetState("Backdashing") 
		and not self.OnCooldown
		and self.Enabled
	
	return Conditions and not self.Combat:GetState(`Cannot{self.NameNoSpaces}`)
end

function BaseAttack:ConditionToActivate() : boolean
	return self:BasicConditions() 
		and not self.Combat:GetState("Dashing") 
		and not self.Combat:GetState("Blocking") 
		and not self.Combat:GetState("M1ing") 
end

local CancelAttacks = {
	["M1"] = Enum.UserInputType.MouseButton1, 
	["Block"] = Enum.KeyCode.F
} 

function BaseAttack:TryToCancelAttacks()
	if (self.Directory.Name == "Dash") then
		local FrontOrBack = (self.Direction == "Front" or self.Direction == "Back")
		
		if FrontOrBack then
			for Name, Key in CancelAttacks do
				local Attack, Matched = self.Combat:MatchAttack(Name, Key)

				if Matched then
					Attack:Cancel()
				end
			end
		end
	else
		if self.TryToCancelMoves then
			self.Combat:CancelAllAttacks()
		end
	end
end

function BaseAttack:AntiDashMovestack()
	if (self.Directory.Name == "Dash" and self.Direction ~= "Front" and self.Combat:GetState("Attacking")) then
		local Dash, Matched = self.Combat:MatchAttack("Dash", Enum.KeyCode.Q)

		if Matched then
			Dash:Cancel()
		end
	end
end

function BaseAttack:ActivateCustomFunction(Item: any, ...): ("Default")?
	
	if typeof(Item) == "function" then
		return Item(self, ...);
		
	elseif typeof(Item) == "string" then
		local Module = self.Combat:GetAttackFunctionModule(Item);

		if Module then
			local Custom = require(Module :: any);
			
			return Custom.Activate(self, ...);
		else
			warn(`Bad Custom Function: Unable to find attack function {Item}`);
		end;
	end;
	
	return "Default";
end

function BaseAttack:CreateHitbox(Sphere: boolean?, DontClose: boolean?)
	local Hitbox = self.Combat.Hitbox:Create(Sphere)
	
	if not DontClose and self:ThreadAvailable() then
		self.Thread.OnClosed:Connect(function()
			Hitbox:EndCast()
			Hitbox:Destroy()
		end);
	end;
	
	if self.HitboxMultiplier ~= Vector3.one or self.HitboxOffset ~= Vector3.zero then
		local BaseBeginCast = Hitbox.BeginCast;
		local BaseDetect = Hitbox.Detect;
		
		local AppliedValues = false;
		
		local function ApplyValues()
			if AppliedValues then return end;
			
			AppliedValues = true;
			
			local Offset = self.HitboxOffset;
			local Size = self.HitboxMultiplier;

			Hitbox.Params.Offset *= CFrame.new(Offset);

			if typeof(Hitbox.Params.Size) == "number" then
				Hitbox.Params.Size *= math.min(Size.X, Size.Y, Size.Z);
			else
				Hitbox.Params.Size *= Size;
			end;
		end;
		
		-- Intercept the begin cast function and apply the additional multipliers and offsets
		function Hitbox.BeginCast(_, ...)
			ApplyValues();
			BaseBeginCast(Hitbox, ...);
		end;
		
		-- Intercept the detect function and apply the additional multipliers and offsets
		function Hitbox.Detect(_, ...)
			ApplyValues();
			BaseDetect(Hitbox, ...);
		end;
	end;
	
	return Hitbox
end

function BaseAttack.new(Combat, Directory : Instance, Key : (Enum.KeyCode | Enum.UserInputType))
	local self = setmetatable({}, BaseAttack)
	self.Job = Job.new()

	self.Directory, self.Key = Directory, Key
	self.DirectoryParent = Directory.Parent.Name

	self.NameNoSpaces = string.gsub(self.Directory.Name, "%s+", "")
	
	self.Name = self.Directory.Name;
	self.DisplayName = self.Directory.Name; -- Used for Custom Skills only
	
	self.Combat = Combat
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaPlayer
	
	self.VictimAnimations = {}; -- Used for Custom Skills
	self.Animations = {};
	self.AnimationDirectory = {}
	
	self.AnimationSettings = {
		FadeTime = 0.1,
		Weight = 1,
		Speed = 1
	}

	self.HeldState = false
	self.Available = true
	self.DontBuffer = false
	
	self.HoldingJump = false
	self.FreeFalling = false

	self.Thread = nil
	
	self.Enabled = true;
	self.CooldownEnabled = true
	self.FinisherEnabled = true;
	self.SoundEffectsEnabled = true;
	self.VisualEffectsEnabled = true;
	self.VariantsEnabled = true;
	
	self.ForceVariant = false;
	self.ForceSpecialVariant = false;
	
	self.SpeedMultiplier = 1;
	self.DamageMultiplier = 1;
	self.RagdollMultiplier = 1;
	self.KnockbackMultiplier = 1;
	self.StunMultiplier = 1;
	self.HitboxMultiplier = Vector3.one;
	self.HitboxOffset = Vector3.zero;
	
	self.OnCooldown = false
	self.CooldownThread = nil
	self.OnCooldownChanged = self.Job:Task(EventService.new())
	self.OnTriggered = self.Job:Task(EventService.new())
	self.OnAfflict = self.Job:Task(EventService.new())
	
	self.CertainCooldowns = {}
	self.TrackedCharacters = {}
	
	self.BypassHumanoidAlive = false
	self.TryToCancelMoves = false
	self.Uncancellable = false
	self.BeginRequestingMouseOnBuffer = false
	
	--local function Connect()
	--	self.Job:Task(self.LuaCharacter.Animator.AnimationPlayed:Connect(function(Track)
	--		for _, Animation in self.Animations do
	--			if Animation == Track then
	--				Animation:AdjustSpeed(Animation.Speed * self.SpeedMultiplier);
	--			end;
	--		end;
	--	end));
	--end

	--if self.LuaCharacter.HumanoidAlive then
	--	task.spawn(Connect)
	--else
	--	self.Job:Task(self.LuaCharacter.OnHumanoidAvailabilityChanged:Once(Connect))
	--end
	
	return self
end

----------------------------------------------------------------------------------

table.freeze(BaseAttack)

return BaseAttack