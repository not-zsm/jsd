local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Data = require(script.Data)

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	-- self.Combat:CreateMoveSFX("Kratos", "Daybreak Throw", "Throw")
	local Item = self.LuaCharacter.Items.EquippedItem
	if Item.Name ~= "Daybreak" then self:Close() end
	
	self.LuaCharacter.Model:SetAttribute("FreezeHotbar", true)
	
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.Thread.OnClosed:Connect(function()
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
		
		self.LuaCharacter.Model:SetAttribute("FreezeHotbar", false)
	end)
	
	local ThrowCF = self.LuaCharacter.RootPart.CFrame
	
	local function SetExplosionHitbox(RootPart : BasePart, CF)
		if RootPart then
			CF = RootPart.CFrame
		end
		
		local Hitbox = self:CreateHitbox(true, true);
		Hitbox.Adornee = CF
		Hitbox.Offset = CFrame.identity
		Hitbox.Params.Size = 5
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Difference : Vector3 = (VictimLuaCharacter.RootPart.Position - CF.Position)
			
			local Velocity = if RootPart then {(VictimLuaCharacter.RootPart.Position - ThrowCF.Position).Unit * 25, 0.1} else {Difference.Unit * 30 + Vector3.yAxis * 3, 0.1}
			
			local Validated = self:Afflict(VictimLuaPlayer, {
				Damage = self.Damage,
				BreakBlock = true,
				Ragdoll = 1,
				Velocity = Velocity,
				TriggerActiveCounterOverOrEqualLevel = -1,
			})
		end)
		
		task.delay(3, function()
			Hitbox:Detect()
			Hitbox:Destroy()
		end)
	end
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("step"):Connect(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.75
		VelocityObject.Settings.RemoveTime = 8
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true 
		VelocityObject.Settings.Z = 9
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("swing"):Connect(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.75
		VelocityObject.Settings.RemoveTime = 8
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 14
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("throw"):Connect(function()
		Item.UsesLeft = Item.UsesLeft - 1
		if Item.UsesLeft < 1 then
			self.LuaCharacter.Items:Remove(Item)
		end
		
		local MaxDistance = Data.MaxDistance
		local StartFallingAt =  Data.StartFallingAt
		local Gravity = Data.Gravity 

		local Root : BasePart = self.Combat:GetSimulatedRoot()
		local CF = Root.CFrame
		
		local StartCF = CF * CFrame.new(0.5, 1.25, -2) * CFrame.Angles(0, math.pi, 0)
		local Velocity : Vector3 = CF.LookVector * 225

		local Projectile = {
			DaybreakCF = StartCF,
			Hitbox = self:CreateHitbox(false, true);
			Connection = nil,
			Torso = nil
		}

		Projectile.Hitbox.Adornee = Projectile.DaybreakCF
		Projectile.Hitbox.Params.Offset = CFrame.identity
		Projectile.Hitbox.Params.Size = Vector3.new(0.8, 4, 3)

		Projectile.Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated, Type = self:Afflict(VictimLuaPlayer, {
				TriggerActiveCounterOverOrEqualLevel = 0.1,
				YDifferenceValue = -2,
				BreakBlock = true,
				Projectile = true,
			})

			local Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 7.5)

			if Type == "Countered" then
				if VictimLuaPlayer.Replication.Attributes:GetAttribute("Vector Reflection") then
					self:StopProjectileRunner(Projectile)
				else
					Projectile.DaybreakCF *= CFrame.Angles(0, math.pi, 0)
					Projectile.Hitbox.Params.Ignore = {}
				end
			else
				SetExplosionHitbox(VictimLuaPlayer.Character.RootPart)
				
				if Validated then
					local Distance = (self.LuaCharacter.RootPart.Position - VictimLuaCharacter.RootPart.Position).Magnitude

					self.Combat:DealDamage(VictimLuaPlayer, self.OnHitDamage)
					self.DaybreakVictim = VictimLuaPlayer

					Projectile.Torso = VictimLuaCharacter.Torso

					task.spawn(function()
						for i = 1, 15 do
							self.Combat:DealDamage(VictimLuaPlayer, self.BurnTickDamage)
							task.wait(0.2)
						end
					end)
				end
			end
		end)

		@native local function RunKratosDaybreakProjectile()
			Projectile.Connection = self.Job:Task(RunService.PreSimulation:Connect(function(Delta : number)
				local DaybreakCF : CFrame = Projectile.DaybreakCF
				local DaybreakPosition : Vector3 = DaybreakCF.Position

				local DistanceFromStart : number = (StartCF.Position - DaybreakPosition).Magnitude

				if DistanceFromStart > MaxDistance then
					return self:StopProjectileRunner(Projectile, "Distance")
				end

				local NewDaybreakPosition = DaybreakPosition + Velocity.Unit * (Velocity.Magnitude * Delta)

				if Projectile.Hitbox then
					Projectile.Hitbox.Adornee = CFrame.lookAlong(NewDaybreakPosition, DaybreakCF.LookVector)
					Projectile.Hitbox:Detect()
				end

				if (Projectile.Torso ~= nil) then
					self:StopProjectileRunner(Projectile, "Stick")
					self:FireReliableVFX("Items/Daybreak Throw", "StickToVictim", self.LuaCharacter.Model, Projectile.Torso)
					return
				end

				local Raycast = workspace:Raycast(DaybreakPosition, NewDaybreakPosition - DaybreakPosition, Utility.VisualParams)

				if Raycast and Raycast.Instance.CanCollide then
					SetExplosionHitbox(nil, DaybreakCF)
					return self:StopProjectileRunner(Projectile, "Hit")
				end

				if (DistanceFromStart > StartFallingAt) then
					Velocity += Gravity * Delta
				end

				Projectile.DaybreakCF = DaybreakCF + Velocity * Delta
			end))

			self:FireReliableVFX("Items/Daybreak Throw", "Create", self.LuaCharacter.Model, StartCF, Velocity)
		end

		RunKratosDaybreakProjectile()
	end))

	task.wait(1)

	self.Animations.Windup:Stop(0.3)

	self:Close()
end

function Attack:StopProjectileRunner(Projectile, Type : string)
	if Projectile.Connection then
		Projectile.Connection:Disconnect()
		Projectile.Connection = nil
	end

	if Projectile.Hitbox then
		Projectile.Hitbox:Destroy()
		Projectile.Hitbox = nil
	end

	--self:FireReliableVFX("Kratos/Daybreak Throw", "Obstruct", self.LuaCharacter.Model, Type)
end

function Attack.new(...) 
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.Cooldown = 0
	
	self.Damage = 15
	self.BurnTickDamage = 0.25
	self.OnHitDamage = 5
	
	self:_Init()
	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack
