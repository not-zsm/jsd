local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not self.Bashed
end

function Attack:RemoveShield()
	if not self.InShield then return end

	Utility.CloseThreadSafe(self.ShieldRemoveThread)
	
	if self.GoneConnection and self.GoneConnection.Connected then
		self.GoneConnection:Disconnect()
	end
	
	self.ShieldRemoveThread = nil
	self.GoneConnection = nil

	--self.Animations.Idle:Stop()
	self.Animations.Leash:Play()
	
	local NewJob = Job.new()
	
	NewJob:Task(self.Animations.Leash:GetMarkerReachedSignal("shrink"):Connect(function()
		self:FireReliableVFX("Kratos/Guardian Shield", "Unform", self.LuaCharacter.Model)
	end))
	
	NewJob:Task(self.Animations.Leash:GetMarkerReachedSignal("end"):Connect(function()
		local BlockAttack = self.Combat.Attacks.Block
		
		if BlockAttack then
			local Animations = BlockAttack:GetAnimationDirectory()

			if Animations.ShieldHold then
				Animations.ShieldHold:Stop()
			end
			
			if self.Combat:GetState("Blocking") then
				local Hold = Animations.Hold or BlockAttack.Animations.Default.Hold

				if Hold then
					Hold:Play()
				end
			end
		end
		
		if self.Shield then
			self.Shield:Destroy()
		end
		
		self.Shield = nil
	end))
	
	NewJob:Task(self.Animations.Leash.Stopped:Connect(function()
		NewJob:Destroy()
	end))

	self.InShield = false
	self.Combat:RemoveAttack("Guardian Shield")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	
	if self.InShield then
		self.Bashed = true;
		self.Uncancellable = false;
		self:HideDisplay();
		
		local Hitbox = self:CreateHitbox(false);
		Hitbox.Params.Offset = CFrame.new(0, 0, -2.5)
		Hitbox.Params.Size = Vector3.new(9, 7.5, 10.75)

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local KnockbackVelocity : Vector3 = self.Combat:CalculateUnitDifference(VictimLuaPlayer)

			local Validated = self:Afflict(VictimLuaPlayer, {
				BreakBlock = true,
				Damage = 7.5,
				Velocity = {KnockbackVelocity * 80 + Vector3.yAxis * 50, 0.04},
				Ragdoll = 2
			})

			if Validated then
				self:FireReliableVFX("Kratos/Guardian Bash", "Hit", VictimLuaCharacter.Model)
			end
		end)

		self.Thread.OnClosed:Connect(function()
			self.Animations.Rush:Stop()
			self.Combat:StackState("Attacking", false)
		end)
		
		self.Thread.Job:Task(self.Animations.Rush:GetMarkerReachedSignal("hit"):Connect(function()
			Hitbox:BeginCast(0.1)
		end))
			
		self.Thread.Job:Task(self.Animations.Rush:GetMarkerReachedSignal("end"):Connect(function()
			self:Close()
		end))
		
		self.Animations.Rush:Play()
		self:FireReliableVFX("Kratos/Guardian Bash", "Start", self.LuaCharacter.Model)
		
		if self.LuaPlayer.IsNPC then
			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 1.5
			VelocityObject.Settings.RemoveTime = 1.8
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 35
			VelocityObject:Fire();
		end;
	else
		self.InShield = true
		self.Combat:ChangeAttackDisplay(self.Name, "Guardian Bash")

		self.Shield = script.Shield:Clone()
		self.Shield.Weld.Part0 = self.LuaCharacter.LeftArm
		self.Shield.Parent = self.LuaCharacter.Model

		self.Animations.Unleash:Play()
		--self.Animations.Idle:Play(0.1, 1, 1)

		self:FireReliableVFX("Kratos/Guardian Shield", "Form", self.LuaCharacter.Model)
		self.ShieldRemoveThread = task.delay(30, self.RemoveShield, self)
		
		task.delay(0.5, function()
			self.Combat:StackState("Attacking", false)
		end)
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.DontBuffer = true
	self.Uncancellable = true
	self.InShield = false
	self.Bashed = false
	
	local MimirVoiceLine = task.delay(15, function()
		if self.Bashed == false and self.LuaCharacter.Mimir then
			if math.random(1, 3) == 1 then
				self.LuaCharacter.Mimir.RootPart["What Goods A Shield"]:Play()
			end
		end
	end)
	
	self.GoneConnection = self.Job:Task(self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value)
		if not Value then
			self.GoneConnection:Disconnect()
			Utility.CloseThreadSafe(self.ShieldRemoveThread)

			if self.Shield then
				self.Shield:Destroy()
			end

			self.Shield = nil
			self.ShieldRemoveThread = nil

			self.InShield = false
			self.Combat:RemoveAttack("Guardian Shield")
			task.cancel(MimirVoiceLine)
		end
	end))

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack