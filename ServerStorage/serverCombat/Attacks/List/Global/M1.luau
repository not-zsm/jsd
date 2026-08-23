local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local Shared = ReplicatedStorage.Shared

local Utility = require( Shared.Utilities.Utility )
local EventService = require( Shared.Utilities.EventService )

local MovementReplicatorSettings = require( ReplicatedStorage.MovementReplicator.Settings )

local HavocHandler = require( ServerStorage.modules.HavocHandler )
local Table = require( ReplicatedStorage.Packages.Table )

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

--function Attack:GetAnimationDirectory()
--	self:UpdateAnimationDirectory()

--	local CustomM1Directory = (self.Combat:HasACharacter() and self.Combat.CurrentCharacter.Info.M1) and self.Combat.CurrentCharacter.Info.M1.AnimationDirectory

--	if CustomM1Directory then
--		return CustomM1Directory(self) 
--	end

--	return self.AnimationDirectory
--end

function Attack:StopCurrentAnimation(Directory : {})
	if (self.Count == 0) then return end
	
	Directory = Directory or self:GetAnimationDirectory()
	
	if Directory then
		local Animation : AnimationTrack = Directory[tostring(self.Count)]

		if (Animation ~= nil and Animation.IsPlaying) then
			Animation:Stop()
		end
	end
end

function Attack:ConditionToActivate() : boolean
	local CharacterInfo : {}? = self.Combat:HasACharacter() and self.Combat.CurrentCharacter.Info or nil

	if CharacterInfo and CharacterInfo.M1 and CharacterInfo.M1.CustomConditionToActivate then
		return (CharacterInfo.M1.CustomConditionToActivate() == false) and not self.LuaCharacter.Items:IsSinked()
	else
		return self:BasicConditions() and not self.Combat:GetState("Blocking") and not self.Combat:GetState("M1ing") and not self.LuaCharacter.Items:IsSinked()
	end;
end;

function Attack:AntiM1ResetTech()
	if time() - self.ResetTime >= self.ResetTimer then
		self.Count = 0
		return
	end
	
	--self.Count = 3

	if self.Count == 4 then
		self.Count = 3
	end
end

function Attack:AirAttack()
	self.Combat:StackState("Attacking", true)
	self.Animations.AirAttack:Play(0.1, 1, 1.275)
	self.Animations.AirAttack.TimePosition = 0.15

	self.Thread.OnClosed:Connect(function()
		self:AddCertainCooldown("AirAttack", 4, nil, true)

		self.Animations.AirAttack:Stop(0.15)
		self.Combat:StackState("Attacking", false)
	end)

	self:FireReliableVFX("Global/AirAttack", "Spin", self.LuaCharacter.LeftLeg)

	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 1
	VelocityObject.Settings.RemoveTime = 0.3
	VelocityObject.Settings.MaxForce = Vector3.one * 80000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = 65
	VelocityObject.Settings.Y = -18.5
	VelocityObject:Fire()

	task.wait(0.28)

	local Hitbox = self:CreateHitbox()
	Hitbox.Params.Offset = CFrame.new(0, -3.5, -3.5)
	Hitbox.Params.Size = Vector3.new(8, 12, 8.5)

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local KnockbackVelocity : Vector3 = self.Combat:CalculateUnitDifference(VictimLuaPlayer)

		local Validated = self:Afflict(VictimLuaPlayer, {
			DontBypassIFrames = {"Grab", "Backdash"},
			BreakBlock = true,
			Damage = 5,
			Velocity = {KnockbackVelocity * 30 - Vector3.yAxis * 7.5, 0.1},
			DontRestartRespawnTimer = true
		})

		if Validated then
			if not VictimLuaCharacter.Combat:GetState("Ragdolled") then
				VictimLuaCharacter.Combat.Ragdoll:Toggle(true, 1.5)
			end
			
			self:FireReliableVFX("Global/Dashing/Forward Dash", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
		end
	end)
	
	local CF : CFrame = Hitbox:GetCFrame() * CFrame.new(0, 1, 0)

	self.Combat.Hitbox:CreateHavocReplicated({
		parameters = {
			origin = CF,
			size = Hitbox.Params.Size, 
			shape = "Box", 
			block_size = 4, 
		},
		crater = {},
		debris = {
			scale = 0.9,
			velocity = function(part)
				return (CF.UpVector * (20 + part:GetMass() / 2)) + Random.new():NextUnitVector() * 10;
			end,
		},
	})
	
	Hitbox:BeginCast(0.2)

	task.wait(0.25)
	
	self:Close()
end

function Attack:M1()
	if (self.Count > 3 or time() - self.ResetTime >= self.ResetTimer) then
		self.Count = 0
	end

	self.Combat:StackState("M1ing", true);
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:StackState("M1ing", false)

		if self.Count > 3 then
			self:AddCooldown(0.75, true)
		end
	end)
	
	self:StopCurrentAnimation();

	self.Count += 1

	self.ResetTime = time()

	self.Hit = false
	self.Downslammed = false
	self.InWindup = true
	self.Condition = (self.Count > 3 and (if self.Combat.AirState == "" then nil else self.Combat.AirState) or nil)

	self.WallComboVictim = nil

	local Is_Normal_M1 = self.Count < 4

	local CharacterName : string = self.Combat:HasACharacter() and self.Combat.CurrentCharacter.Name or nil
	local CharacterInfo : {} = self.Combat:HasACharacter() and self.Combat.CurrentCharacter.Info or nil
	local CharacterStats : {} = self.Combat:HasACharacter() and self.Combat.CurrentCharacter.Stats or nil

	local AnimationDirectory = self:GetAnimationDirectory()
	local Animation : AnimationTrack = (self.Condition ~= nil and AnimationDirectory[self.Condition] or AnimationDirectory[tostring(self.Count)])

	local AttackingWith = nil
	
	if CharacterInfo and CharacterInfo.M1 and CharacterInfo.M1.EndFunction then
		self.Thread.OnClosed:Once(function()
			task.spawn(CharacterInfo.M1.EndFunction, self)
		end)
	end

	self.Thread.Job:Task(Animation:GetMarkerReachedSignal("attackingwith"):Once(function(Parameter : string)
		AttackingWith = self.LuaCharacter[Parameter]
	end))

	local DefaultSpeed = 0.83
	local ExtraAnimSpeed = (Animation.Animation:GetAttribute("Speed") or 1)
	
	if CharacterStats then
		local M1Speed = (CharacterStats.M1 and (CharacterStats.M1.Speed or DefaultSpeed) or DefaultSpeed)
		Animation:Play(0.1, 1, (self.Condition == nil and M1Speed or 1) * ExtraAnimSpeed)
	else
		Animation:Play(0.1, 1, DefaultSpeed * ExtraAnimSpeed)
	end

	if CharacterInfo and CharacterInfo.M1 and CharacterInfo.M1.StartFunction then
		task.spawn(CharacterInfo.M1.StartFunction, self)
	end

	local Hitbox = self:CreateHitbox()
	Hitbox.Params.DestroyOnEndCast = false

	if self.Condition == "Up" then
		Hitbox.Params.Offset = CFrame.new(0, 0, -2.65)
		Hitbox.Params.Size = Vector3.new(6, 10, 6.8)

	elseif self.Condition == "Down" then
		Hitbox.Params.Offset = CFrame.new(0, -3.5, -2.65)
		Hitbox.Params.Size = Vector3.new(5.35, 25, 6.8)
	else
		if (CharacterStats and CharacterStats.M1 and CharacterStats.M1.LastHitbox) and not Is_Normal_M1 then
			Hitbox.Params.Offset = CharacterStats.M1.LastHitbox.Offset
			Hitbox.Params.Size = CharacterStats.M1.LastHitbox.Size
			
		elseif CharacterStats and CharacterStats.M1 and CharacterStats.M1.Hitbox then
			Hitbox.Params.Offset = CharacterStats.M1.Hitbox.Offset
			Hitbox.Params.Size = CharacterStats.M1.Hitbox.Size
		else
			Hitbox.Params.Offset = CFrame.new(0, 0, -2.65) 
			Hitbox.Params.Size = Vector3.new(6, 6, 6.8)
		end
	end

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local BlockAttack, BlockAttackMatched = self.Combat:MatchAttack("Block", Enum.KeyCode.F)
		local Parried = BlockAttackMatched and (time() - BlockAttack.PerfectBlockTime < 2)

		--local Is_Normal_M1 = self.Count < 4--(self.Condition == nil)

		local Validated, Type : string = self:Afflict(VictimLuaPlayer, {
			DontBypassIFrames = (self.Condition ~= "Down" and {"Grab", "Backdash"}),
			BreakBlock = (self.Condition == "Down" or Parried),
			--Damage = Parried and 6 or (self.Count > 2 and 4 or 3),
			Damage = Parried and 6 or (self.Damage[self.Count]),
			CanPerfectBlock = (self.Condition == nil),
			DontHitRagdolled = Is_Normal_M1,
			YDifferenceValue = not Is_Normal_M1 and VictimLuaCharacter.HumanoidAlive and 0 or nil,
			DontHitDeadPeople = Is_Normal_M1,
			DontRestartRespawnTimer = true,
			CannotBeAdapted = true
		})

		if Type == "Blocked" then
			self.Combat:StackState("CannotM1", true, self.TimeUntilCanBlock)
			self.Combat.Values.Jump:Change(true, self.TimeUntilCanBlock)
		end
		
		if Validated then
			self.Hit = true
			self.HitTime = time()
			self.OnHit:Fire(VictimLuaPlayer)

			if (self.Count == 4) then
				self.WallComboVictim = VictimLuaPlayer
				
				task.delay(0.4, function()
					self.WallComboVictim = nil
				end)
			end

			local KnockbackVelocity : Vector3 = self.Combat:CalculateUnitDifference(VictimLuaPlayer)

			if Parried then
				BlockAttack.PerfectBlockTime = -1
				BlockAttack:AddCertainCooldown("PerfectBlockCooldown", 1, nil, true)
				self:FireReliableVFX("Global/M1", "Black Flash", VictimLuaCharacter.RootPart, self.Condition)
			end

			if self.Condition == "Up" then
				self:FireReliableVFX("Global/M1", "Uppercut", VictimLuaCharacter.RootPart, CharacterName)

				local VictimVelocityObject = self:VelocityOn(VictimCombat)
				VictimVelocityObject.Settings.RemoveTime = 0.1
				VictimVelocityObject.Settings.Velocity = Vector3.yAxis * 57.5
				VictimVelocityObject:Fire()

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true;
					Ragdoll = 2;
				})
				--VictimCombat.Ragdoll:Toggle(true, 2)
				VictimLuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(30, -30), 0, Utility.Seed:NextNumber(30, -30))

			elseif self.Condition == "Down" then
				self.Downslammed = true

				self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Vector3.new(4, 15, 4), 1)
				self:FireReliableVFX("Global/M1", "Down Slam", VictimLuaCharacter.RootPart, CharacterName)
				VictimLuaCharacter.RootPart.CFrame *= CFrame.new(0, -0.5, 1) * CFrame.Angles(math.rad(-45), 0, 0)

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true;
					Ragdoll = 2;
				})
				--VictimCombat.Ragdoll:Toggle(true, 2)

				local VictimVelocityObject = self:VelocityOn(VictimCombat)
				VictimVelocityObject.Settings.RemoveTime = 0.1
				VictimVelocityObject.Settings.Velocity = Vector3.yAxis * -60
				VictimVelocityObject:Fire()
			else
				if Parried then
					VictimCombat.Animations.BlackFlashed:Play()
					VictimCombat:AntiTeamStun(self.LuaPlayer.Player, 1.25)
				else
					if self.Combat.Attacks.Weapons then
						self:FireReliableVFX("Global/M1", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, self.Count, CharacterName, self.Combat.Attacks.Weapons.CurrentlyUsing) 
					else
						self:FireReliableVFX("Global/M1", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart, self.Count, CharacterName) 
					end

					if (self.Count == 4) then
						if CharacterStats and CharacterStats.M1 and CharacterStats.M1.LastM1KnocksUp then
							local VictimVelocityObject = self:VelocityOn(VictimCombat)
							VictimVelocityObject.Settings.RemoveTime = 0.1
							VictimVelocityObject.Settings.Velocity = KnockbackVelocity * 40 + Vector3.yAxis * 40
							VictimVelocityObject:Fire()
						else
							local VictimVelocityObject = self:VelocityOn(VictimCombat)
							VictimVelocityObject.Settings.RemoveTime = 0.1
							VictimVelocityObject.Settings.Velocity = KnockbackVelocity * 40 + Vector3.yAxis * 8.5
							VictimVelocityObject:Fire()
						end

						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true;
							Ragdoll = 2;
						})
						--VictimCombat.Ragdoll:Toggle(true, 2)
					else
						VictimCombat:PlayRandomHitReaction()
						VictimCombat:AntiTeamStun(self.LuaPlayer.Player, 0.85)
						VictimCombat:StackState("ForceDashPush", true, 1)
						
						if not VictimCombat:GetState("StunImmunity") then
							local MaxForce = Vector3.new(1, 0, 1) * 10000

							local VictimVelocityObject = self:VelocityOn(VictimCombat)
							VictimVelocityObject.Settings.RemoveTime = 0.2
							VictimVelocityObject.Settings.MaxForce = MaxForce
							VictimVelocityObject.Settings.Velocity = KnockbackVelocity * 5
							VictimVelocityObject:Fire()

							local AttackerVelocityObject = self.Combat:Velocity()
							AttackerVelocityObject.Settings.Name = "M1PullIn"
							AttackerVelocityObject.Settings.Z = 5
							AttackerVelocityObject.Settings.RemoveTime = 0.2
							AttackerVelocityObject.Settings.MaxForce = MaxForce
							AttackerVelocityObject.Settings.Controllable = true
							AttackerVelocityObject:Fire()
						end
					end
				end
			end

			if (self.Count == 4) then
				task.defer(self.Close, self)
			end
			
			-- Hornet
			if not Parried and self.LuaCharacter.Silk then
				self.LuaCharacter.Silk:PlusCount(1)
			end
		end
	end)

	if (not MovementReplicatorSettings.use_replicator and not self.LuaPlayer.IsNPC and self.LuaPlayer.Data.Profile.Data.Settings.M1_Hitbox_Compensate == true) then
		self.Thread.Job:Task(
			self.Combat.Hitbox:OffsetHitboxOnVelocity(Hitbox, 17.5)
		)
	end

	if (self.Condition ~= nil) then
		self:FireReliableVFX("Global/M1", "SpecialSwing", self.LuaCharacter.RootPart, self.Condition, CharacterName)
	else
		self.Thread.Job:Task(Animation:GetMarkerReachedSignal("swing"):Once(function()
			if self.Combat.Attacks.Weapons then
				self:FireReliableVFX("Global/M1", "Swing", self.LuaCharacter.RootPart, self.Count, CharacterName, AttackingWith, self.Combat.Attacks.Weapons.CurrentlyUsing)
			else
				self:FireReliableVFX("Global/M1", "Swing", self.LuaCharacter.RootPart, self.Count, CharacterName, AttackingWith)
			end
		end))
	end
	
	local StopAnimConnection : RBXScriptConnection; StopAnimConnection = self.Combat.OnStateUpdated:Connect(function(State : string, Value : boolean)
		if (State == "Attacking" or State == "M1ing" or State == "Blocking") and Value then
			StopAnimConnection:Disconnect()
			Animation:Stop()
		end
	end)

	Animation.Stopped:Once(function()
		StopAnimConnection:Disconnect()
	end)
	
	self.Thread.Job:Task(Animation:GetMarkerReachedSignal("hit"):Connect(function(Parameter : string?)
		self.InWindup = false
		Hitbox:BeginCast(0.1)
		
		if self.Count > 3 then
			task.spawn(function()
				local Condition : string? = self.Condition
				local CF : CFrame = Hitbox:GetCFrame() * CFrame.new(0, 1, 0)
				local Seed = Random.new()
				local VelocityFn;
				
				local Power = 30
				local MassDivide = 2
				
				if Condition == "Up" then
					function VelocityFn(cube)
						return (CF.UpVector * (Power + cube:GetMass() / MassDivide)) + Seed:NextUnitVector() * 5;
					end
					
				elseif Condition == "Down" then
					function VelocityFn(cube)
						return (CF.UpVector * (Power + cube:GetMass() / MassDivide)) + Seed:NextUnitVector() * 5;
					end
				else
					function VelocityFn(cube)
						return (CF.LookVector * (Power + cube:GetMass() / MassDivide)) + Seed:NextUnitVector() * 5;
					end
				end
				
				local havoc, destructed, crater, debris = self.Combat.Hitbox:CreateHavocReplicated({
					parameters = {
						origin = CF,
						size = Hitbox.Params.Size, 
						shape = "Box", 
						block_size = 4, 
						seperate_islands = true,
					},
					crater = {},
					debris = {
						scale = 0.9,
						velocity = VelocityFn
					},
				})
			
				--local havoc = HavocHandler:create_replicated({
				--	origin = CF,
				--	size = Hitbox.Params.Size, 
				--	shape = "Box", 
				--	block_size = 4, 
				--	greedy_meshing = true,
				--})

				--havoc:destruct({
				--	crater = {},
				--	debris = {
				--		scale = 0.9,
				--		create_part_callback = CreatePartFn
				--	},
				--});

				--HavocHandler:create_effects_from(havoc);
			end)
			
			if not self.Hit then
				if self.Combat:HasACharacter() then
					self.Combat:StackState("CannotUse" .. self.Combat.CurrentCharacter.Name, true)
				end

				self.Combat:StackState("CannotDash", true)
				self.Combat:DivideSpeed(20)

				self.Thread.OnClosed:Connect(function()
					self.Combat:StackState("CannotDash", false)
					self.Combat:TimesSpeed(20)

					if self.Combat:HasACharacter() then
						self.Combat:StackState("CannotUse" .. self.Combat.CurrentCharacter.Name, false)
					end
				end)
			end
		end
		
		--if (self.Condition ~= nil) then
		--	local StopAnimConnection : RBXScriptConnection; StopAnimConnection = self.Combat:GetStateChanged("Attacking"):Connect(function(Value : boolean)
		--		if Value then
		--			StopAnimConnection:Disconnect()
		--			Animation:Stop()
		--		end
		--	end)

		--	Animation.Stopped:Once(function()
		--		StopAnimConnection:Disconnect()
		--	end)
		--end
		
		self.Combat.Values.Jump:Add(0.05)

		if (self.Condition == nil) then
			if CharacterStats and CharacterStats.M1 and CharacterStats.M1.EndlagAfterSwing then
				task.wait(CharacterStats.M1.EndlagAfterSwing)
			else
				task.wait(0.2)
			end
		else
			task.wait(0.15)
		end
		
		if not (table.find({"", " ", "0", "last", "final", "end"}, Parameter)) then
			return
		end
		
		if self.Count > 3 and not self.Hit then
			task.wait(0.7)
			self:Close()
		else
			self.Combat:StackState("CannotBlock", true)
			self.Combat:StackState("CannotRun", true)
			self:Close()

			task.delay(self.TimeUntilCanBlock, function()
				self.Combat:StackState("CannotRun", false)
				self.Combat:StackState("CannotBlock", false)
			end)
		end
	end))
end

function Attack:Activate()
	--if self.LuaCharacter.Items.EquippedItem then
	--	return
	--end
	
	local Vault, VaultMatched = self.Combat:MatchAttack("Vault", Enum.KeyCode.W)
	local WallJump, WallJumpMatched = self.Combat:MatchAttack("WallJump", Enum.KeyCode.W)
	
	if self.Combat.CurrentCharacter.Name == "Hornet" then
		local Raycast = workspace:Raycast(self.LuaCharacter.RootPart.Position, Vector3.new(0, -10, 0), Utility.VisualParams)
		
		if not Raycast then
			local Attack = self.Combat.Attacks["Dive Nail"]
			if Attack:CanActivate() then
				Attack:Trigger()
				return
			end
		end
	end
	
	if ( (VaultMatched and Vault.Active) or (WallJumpMatched and WallJump.Active) ) and not self:HasCertainCooldown("AirAttack") then
		return self:AirAttack()
	end
	
	local CharacterInfo : {}? = self.Combat:HasACharacter() and self.Combat.CurrentCharacter.Info or nil
	local UseDefault = true;
	
	if CharacterInfo and CharacterInfo.M1 and CharacterInfo.M1.CustomFunction then
		local Result = self:ActivateCustomFunction(CharacterInfo.M1.CustomFunction);
		
		if Result ~= "Default" then
			UseDefault = false;
		end;
	end;
	
	if UseDefault then
		local Stand = self.Combat:GetStand();

		if Stand and Stand.Summoned then
			self:ActivateCustomFunction("Stands/Stand M1");
		else
			self:M1();
		end;
	end
end;

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.Count = 0

	self.ResetTime = -1
	self.HitTime = -1

	self.ResetTimer = 1.25

	self.Hit = false
	self.Downslammed = false

	self.WallComboVictim = nil

	self.OnHit = self.Job:Task(EventService.new())
	self.TimeUntilCanBlock = 0.325
	
	self.Damage = {
		[1] = 2,
		[2] = 2,
		[3] = 2,
		[4] = 4,
	}

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack