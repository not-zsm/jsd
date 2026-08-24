local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ServerStorage = game:GetService("ServerStorage")
----------------------------------------------------------------------------------

local Job = require( replicatedStorage.modules.shared.Utilities.Job )
local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:SpaceVariant()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.BarrageHit = false

	local Weapons = self.Combat.Attacks.Weapons

	if Weapons then
		Weapons:SetCurrent("Chained Blades")
	end
	
	self.Animations.SpaceVariant:Play()

	local BarrageHitbox = self:CreateHitbox(false);
	BarrageHitbox.Params.Offset = CFrame.new(0, 1.5, 0)
	BarrageHitbox.Params.Size = Vector3.new(12.5, 11, 22.5)
	BarrageHitbox.Params.DestroyOnEndCast = false

	BarrageHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self.BarrageHit = self:Afflict(VictimLuaPlayer, {
			DontRestartRespawnTimer = true,
			Damage = 0.5,
			TrueStun = 1.25
		})

		if self.BarrageHit then
			VictimCombat:PlayRandomHitReaction()
			self:FireReliableVFX("Kratos/Chaos Blades", "Hit", VictimLuaCharacter.RootPart)
		end

		task.delay(0.15, function()
			BarrageHitbox:RemoveHumanoid(VictimLuaCharacter.Humanoid)
		end)
	end)

	local SwingOffset = CFrame.new(0, 2.5, -7.25)
	local SwingSize = Vector3.new(12, 20, 12)

	self.Thread.OnClosed:Connect(function()
		Weapons:ToggleChainedBladeTrails(false)

		self:AddCooldown(self.Cooldown)

		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.CancelJob:Task(
		self:CreateMoveSFX("kratos", "Chaos Blades")
	)

	self.Thread.Job:Task(self.Animations.SpaceVariant:GetMarkerReachedSignal("start"):Once(function()
		if Weapons then
			Weapons:ToggleChainedBladeTrails(true)
		end
	
		self:FireReliableVFX("Kratos/Chaos Blades", "Start", self.LuaCharacter.RootPart)
		BarrageHitbox:BeginCast()
	end))

	self.Thread.Job:Task(self.Animations.SpaceVariant:GetMarkerReachedSignal("end"):Once(function()
		BarrageHitbox:EndCast()
	end))
	
	local Rnd = Random.new();

	self.Thread.Job:Task(self.Animations.SpaceVariant:GetMarkerReachedSignal("swingup2"):Once(function()
		if Weapons then
			task.delay(0.5, function()
				Weapons:ToggleChainedBladeTrails(false)
			end)
		end

		self:FireReliableVFX("Kratos/Chaos Blades", "SwingUp2", self.LuaCharacter.RootPart)
		
		local Hitbox = self:CreateHitbox(false);
		Hitbox.Params.Offset = SwingOffset
		Hitbox.Params.Size = SwingSize
		Hitbox.Params.DestroyOnEndCast = false

		self.Combat.Hitbox:CreateHavocReplicated({
			parameters = {
				origin = Hitbox:GetCFrame(),
				shape = "Sphere", 
				radius = 12,
				block_size = 6,
			},
			debris = {
				scale = 0.9,
				velocity = function(part)
					return self.LuaCharacter.RootPart.CFrame.LookVector * math.random(25, 40) + Rnd:NextUnitVector() * 15 + Vector3.yAxis * 25;
				end,
			},
		});
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				BreakBlock = true,
				Damage = 5,
				Ragdoll = 2, --  remove this if ur gonna make it extend again
				Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 55 + Vector3.yAxis * 45, 0.1},
			})

			if Validated then
				self:FireReliableVFX("Kratos/Chaos Blades", "Hit", VictimLuaCharacter.RootPart)
				
				--if VictimCombat:GetState("Ragdolled") then
				--	self.Combat:PushSkidVictim(VictimLuaPlayer, {
				--		TimeTilGroundDetection = 0.35,
				--		StartVelocityXZ = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 70,
				--		StartVelocityY = Vector3.yAxis * 75,
				--		StartDuration = 0.25,
				--		LandedRollVelocityZ = 75,
				--		LandedRollDuration = 0.8
				--	})
				--else
				--	VictimCombat.Ragdoll:Toggle(true, 2)
				--end
			end
		end)

		Hitbox:Detect()
	end))

	self.Animations.SpaceVariant:GetMarkerReachedSignal("swingup1"):Wait()

	self:FireReliableVFX("Kratos/Chaos Blades", "SwingUp1", self.LuaCharacter.RootPart)
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = SwingOffset
	Hitbox.Params.Size = SwingSize
	Hitbox.Params.DestroyOnEndCast = false

	self.Combat.Hitbox:CreateHavocReplicated({
		parameters = {
			origin = Hitbox:GetCFrame(),
			shape = "Sphere", 
			radius = 12,
			block_size = 6,
		},
		debris = {
			scale = 0.9,
			velocity = function(part)
				return self.LuaCharacter.RootPart.CFrame.LookVector * math.random(15, 25) + Rnd:NextUnitVector() * 12.5 + Vector3.yAxis * 15;
			end,
		},
	});
	
	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
			Damage = 5,
			Ragdoll = 2,
			Velocity = {Vector3.yAxis * 37.5, 0.2}
		})

		if Validated then
			VictimCombat:StackState("CannotDash", true)

			task.delay(0.5, function()
				VictimCombat:StackState("CannotDash", false)
			end)
			
			self:FireReliableVFX("Kratos/Chaos Blades", "Hit", VictimLuaCharacter.RootPart)
		end
	end)

	Hitbox:Detect()

	task.wait(self.BarrageHit and 0.7 or 1.15)

	self:Close()
end

function Attack:Activate()
	if (self.VariantsEnabled and self.HoldingJump) or self.ForceVariant then
		return self:SpaceVariant()
	end
	
	self.Animations.Normal:Play(0.1, 1, 1.5)

	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	local Weapons = self.Combat.Attacks.Weapons

	if Weapons then
		Weapons:SetCurrent("Chained Blades")
		Weapons:ToggleChainedBladeTrails(true)
	end

	self.Thread.CancelJob:Task(
		self:CreateMoveSFX("kratos", "Barrage")
	)

	local BarrageHitbox = self:CreateHitbox(false);
	BarrageHitbox.Params.Offset = CFrame.new(0, 1.5, 0)
	BarrageHitbox.Params.Size = Vector3.new(12.5, 8, 20)
	BarrageHitbox.Params.DestroyOnEndCast = false
	
	local SpinningPart = false
	local SpinJob = Job.new();
	
	BarrageHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self.BarrageHit = self:Afflict(VictimLuaPlayer, {
			Damage = 1,
			TrueStun = SpinningPart and 1.25 or nil,
			Stun = not SpinningPart and 1.25 or nil,
			Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 7.5 + Vector3.yAxis * 5, 0.1}
		})

		if self.BarrageHit then
			VictimCombat:PlayRandomHitReaction()
			self:FireReliableVFX("Kratos/Chaos Blades", "Hit", VictimLuaCharacter.RootPart)
		end

		task.delay(0.15, function()
			BarrageHitbox:RemoveHumanoid(VictimLuaCharacter.Humanoid)
		end)
	end)
	
	local VelocityObject

	self.Thread.OnClosed:Connect(function()
		SpinJob:Destroy();
		
		if VelocityObject then
			VelocityObject:Destroy()
		end

		if Weapons then
			Weapons:ToggleChainedBladeTrails(false)
		end
		
		self:AddCooldown(self.Cooldown)

		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Normal:GetMarkerReachedSignal("start"):Once(function()
		self.Animations.Normal:AdjustSpeed(1)
		BarrageHitbox:BeginCast()
	end))

	local Rnd = Random.new();
	
	self.Thread.Job:Task(self.Animations.Normal:GetMarkerReachedSignal("startrun"):Once(function()
		VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 2
		VelocityObject.Settings.RemoveTime = 1.4 
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 22.5
		VelocityObject:Fire();
		
		SpinJob:Task(task.spawn(function()
			while true do
				self.Combat.Hitbox:CreateHavocReplicated({
					parameters = {
						origin = BarrageHitbox:GetCFrame(),
						shape = "Sphere", 
						radius = 8,
						block_size = 6,
					},
					debris = {
						scale = 0.9,
						velocity = function(part)
							return self.LuaCharacter.RootPart.CFrame.LookVector * math.random(5, 15) + Rnd:NextUnitVector() * 30 + Vector3.yAxis * 25;
						end,
					},
				});
				
				task.wait(0.3);
			end
		end))
	end))

	self.Thread.Job:Task(self.Animations.Normal:GetMarkerReachedSignal("end"):Once(function()
		BarrageHitbox:EndCast()
		SpinJob:Destroy();
	end))

	self.Thread.Job:Task(self.Animations.Normal:GetMarkerReachedSignal("spin"):Connect(function()
		SpinningPart = true
		self:FireReliableVFX("Kratos/Barrage", "Spin", self.LuaCharacter.RootPart)
	end))

	self.Thread.Job:Task(self.Animations.Normal:GetMarkerReachedSignal("startspin"):Connect(function()
		self:FireReliableVFX("Kratos/Barrage", "StartSpin", self.LuaCharacter.RootPart)
	end))

	self.Thread.Job:Task(self.Animations.Normal:GetMarkerReachedSignal("finalhit"):Once(function()
		self:FireReliableVFX("Kratos/Barrage", "FinalHit", self.LuaCharacter.RootPart)
		
		local Hitbox = self:CreateHitbox(false);
		Hitbox.Params.Offset = CFrame.new(-0.5, 2.5, -7.25)
		Hitbox.Params.Size = Vector3.new(18, 12, 18)
		Hitbox.Params.DestroyOnEndCast = false
		
		self.Combat.Hitbox:CreateHavocReplicated({
			parameters = {
				origin = Hitbox:GetCFrame(),
				shape = "Sphere", 
				radius = 14,
				block_size = 6,
			},
			debris = {
				scale = 0.9,
				velocity = function(part)
					return self.LuaCharacter.RootPart.CFrame.LookVector * math.random(5, 15) + Rnd:NextUnitVector() * 30 + Vector3.yAxis * 25;
				end,
			},
		});

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			local Finisher = self:IsFinisherEnabled() and VictimLuaCharacter.Humanoid.Health <= 5
			
			local Validated = self:Afflict(VictimLuaPlayer, {
				BreakBlock = true,
				Damage = 5,
				FinisherKill = Finisher,
				Ragdoll = 2.15,
				Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 65 + Vector3.yAxis * 38, 0.1}
			})

			if Validated then
				self:FireReliableVFX("Kratos/Chaos Blades", "Hit", VictimLuaCharacter.RootPart)
				
				if Finisher then
					self:FireReliableVFX("Global/Elemental", "Burn", VictimLuaCharacter.Model)
				end
			end
		end)

		Hitbox:BeginCast(0.1)

		task.wait(0.5)

		self:Close()
	end))
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.Cooldown = 21
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack