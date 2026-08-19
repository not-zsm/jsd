local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(self.SpeedReduction)
	
	self.Countered = false
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:RemoveActiveCounter()
		
		self.Animations.Windup:Stop(0.65)
		
		if not self.Countered then
			task.wait(0.65)
		end
		
		self:AddCooldown(if self.Countered then self.Cooldown else self.WhiffCooldown)
		
		self.Combat:TimesSpeed(self.SpeedReduction)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(task.delay(self.TimeUntilMoveTimesOut, function()
		self:Close()
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("End"):Once(function()
		self:Close()
	end))
	
	self.Countered = false

	--self.Thread.Job:Task(task.delay(4 / 60, function()
		self.Combat:CreateCounter(1, function(VictimLuaPlayer)
			self.Countered = true

			self.Combat:StackState("GrabIFrames", true)
			self.Combat:DivideSpeed(1000)
			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
			self.LuaCharacter:Anchor(true)

			self.Thread.OnClosed:Connect(function()
				self.LuaCharacter:Anchor(false)

				self.Combat:StackState("GrabIFrames", false)
				self.Combat:TimesSpeed(1000)

				task.defer(function()
					self.LuaCharacter:FixCenter()
				end)
			end)

			local VictimLuaCharacter = VictimLuaPlayer.Character 
			local VictimCombat = VictimLuaCharacter.Combat 

			self.Animations.Windup:Stop(0);
			self.Animations.Counter:Play(0);
			VictimCombat.Animations.GrabVictims.EvilSpiritVictim:Play(0)

			VictimLuaCharacter:SetCollisionGroup("NoCollision")

			local RootCFrame = self.Combat:GetSimulatedRoot().CFrame

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart)

			self.Thread.Job:Task(function()
				GrabObject.Destroy()
			end)

			VictimCombat:StackState("HitboxImmunity", true)
			VictimCombat:DivideSpeed(1000)
			VictimLuaCharacter:Anchor(true)

			local VictimAutoRotate = VictimCombat.Job:Task(VictimLuaCharacter:StopAutoRotate())
			local RestoredVictim = false

			local function RestoreVictim()
				if RestoredVictim then
					return
				end

				RestoredVictim = true

				VictimLuaCharacter:Anchor(false)

				VictimCombat:StackState("HitboxImmunity", false)

				VictimCombat:TimesSpeed(1000)

				VictimCombat:Unstun()

				if VictimAutoRotate then
					VictimAutoRotate:Destroy()
				end
			end

			VictimCombat.Job:Task(VictimCombat.Animations.GrabVictims.EvilSpiritVictim.Stopped:Once(function()
				RestoreVictim()

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 8,
					Ragdoll = 1.5,
					Velocity = {(RootCFrame.LookVector * 25) + vector.create(0, 15, 0), 0.1},
				})
			end))

			self.Thread.Job:Task(self.Animations.Counter.Stopped:Once(function()
				self:Close()
			end))

			self:FireReliableVFX(self.InternalEffectPath, "OnCounter", self.LuaCharacter.Model)
			self:FireReliableVFX(self.InternalEffectPath, "OnVictimCountered", VictimLuaCharacter.Model)
		end)
	--end))
	
	self:FireReliableVFX(self.InternalEffectPath, "OnStart", self.LuaCharacter.Model)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.Countered = false
	self.AnimationSettings = {FadeTime = 0}
	
	self.Cooldown = 12
	self.WhiffCooldown = 18
	
	self.TimeUntilMoveTimesOut = 4
	self.SpeedReduction = 10
	
	self.InternalEffectPath = `Anubis/{script.Name}`
	
	self:_Init()
	
	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack