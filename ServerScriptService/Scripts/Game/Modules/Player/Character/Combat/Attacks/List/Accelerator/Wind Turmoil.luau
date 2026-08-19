local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(100)

	local WindHitbox = self:CreateHitbox(true);
	WindHitbox.Params.Size = 40
	WindHitbox.DestroyOnEndCast = false

	local Hit = {}

	WindHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontBypassIFrames = {},
			BreakBlock = true,
		})

		if Validated  then
			VictimCombat:StackState("CannotDash", true)
			VictimCombat.Ragdoll:Toggle(true)
			Hit[VictimLuaPlayer] = true

			local HitsThread = coroutine.create(function()
				while VictimLuaCharacter.HumanoidAlive do
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = 1,
					})

					if not VictimLuaCharacter.HumanoidAlive then
						Hit[VictimLuaPlayer] = nil
					end

					task.wait(0.3)
				end
			end)

			coroutine.resume(HitsThread)

			self.Thread.OnClosed:Connect(function()
				if coroutine.status(HitsThread) == "suspended" then
					task.cancel(HitsThread)
				end; 

				HitsThread = nil
			end)
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(14)

		for _, Item in self.TornadoAligns do
			Item:Destroy()
		end

		table.clear(self.TornadoAligns)

		for Victim in Hit do
			local VictimCombat = Victim.Character.Combat
			VictimCombat:StackState("CannotDash", false);
			
			self:Afflict(Victim, {
				ExcludeAttempts = true;
				Ragdoll = 0.5;
			})
			--VictimCombat.Ragdoll:Toggle(true, 0.5)
		end

		self.Combat:TimesSpeed(100)
		self.Combat:StackState("HitboxImmunity", false)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Start"):Once(function()
		self.Animations.Windup:AdjustSpeed(1)
		self:FireReliableVFX("Accelerator/Wind Turmoil", "Start", self.LuaCharacter.RootPart)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Explode"):Once(function()
		self:FireReliableVFX("Accelerator/Wind Turmoil", "Explode", self.LuaCharacter.RootPart)

		self.Combat:StackState("HitboxImmunity", true)

		WindHitbox:BeginCast()

		local Radius = 30
		local Height = 5
		local Speed = 10

		local StartTime = os.clock()

		self.SpinConnection = self.Thread.Job:Task(RunService.PostSimulation:Connect(function()
			local Elapsed = (os.clock() - StartTime)
			local Angle = Elapsed * Speed

			self.Combat.Hitbox:SphereDestruction(self.LuaCharacter.RootPart.Position, 30)

			for Victim in Hit do
				local Model = Victim.Character.Model
				local Offset = CFrame.new(math.sin(Angle) * Radius, Height, math.cos(Angle) * Radius)

				if (not Victim.Character.HumanoidExists or Model == nil) then
					self.TornadoAligns[Model] = nil
				else
					local Position = (self.LuaCharacter.RootPart.CFrame * Offset).Position

					if self.TornadoAligns[Model] then
						self.TornadoAligns[Model].Position = Position
					else
						local AlignPosition = Instance.new("AlignPosition")
						AlignPosition.MaxForce = 50000
						AlignPosition.Responsiveness = 100
						AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
						AlignPosition.Attachment0 = Victim.Character.RootPart.RootAttachment
						AlignPosition.Parent = Victim.Character.RootPart.RootAttachment
						AlignPosition.Position = Position

						self.TornadoAligns[Model] = AlignPosition
					end
				end
			end
		end))
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Charge"):Once(function()
		WindHitbox:EndCast()
		self:FireReliableVFX("Accelerator/Wind Turmoil", "Charge", self.LuaCharacter.RootPart, self.LuaCharacter.LeftArm)

		if self.SpinConnection then
			self.SpinConnection:Disconnect()
		end

		for _, Item in self.TornadoAligns do
			Item:Destroy()
		end

		for Victim in Hit do
			Victim.Character.Combat:StackState("CannotDash", false)
			Victim.Character.Combat.Ragdoll:Toggle(true, 3)

			if Victim.Character.HumanoidExists then
				Victim.Character.RootPart.AssemblyLinearVelocity = Vector3.zero
			end

			local VelocityObject = Victim.Character.Combat:Velocity()
			VelocityObject.Settings.RemoveTime = 0.3
			VelocityObject.Settings.Velocity = self.Combat:CalculateUnitDifference(Victim) * -45
			VelocityObject:Fire()
		end

		table.clear(self.TornadoAligns)
		table.clear(Hit)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Main Explosion"):Once(function()
		self:FireReliableVFX("Accelerator/Wind Turmoil", "MainExplosion", self.LuaCharacter.RootPart, self.LuaCharacter.LeftArm)

		local Hitbox = self:CreateHitbox(false);
		Hitbox.Params.Offset = CFrame.new(0, 7, 0)
		Hitbox.Params.Size = Vector3.one * 25

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			self:Afflict(VictimLuaPlayer, {
				Damage = 12.5,
				BreakBlock = true,
				Ragdoll = 2,
				Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 65 + Vector3.yAxis * 25, 0.03}
			})
		end)

		Hitbox:Detect()

		task.wait(0.6)

		self:Close()
	end))
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true

	self.AnimationSettings = {
		FadeTime = 0.05,
		Weight = 1,
		Speed = 1
	}

	self.TornadoAligns = {}

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack