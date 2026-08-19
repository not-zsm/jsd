local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local EventService = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	--self.Combat:StackState("HitboxImmunity", true)
	
	self.Thread.OnClosed:Connect(function()
		self.Animations.Windup:AdjustSpeed(1)
	end)
	
	local ResumeSignal = self.Thread.Job:Task(EventService.new())
	local Reference = self.Thread.Job:Task(Instance.new("Folder"))
	Reference.Name = "VelocityReferene"
	Reference.Parent = self.LuaCharacter.Model

	self.Thread.CancelJob:Task(self:CreateMoveSFX("Gebura Red Mist", "Great Split - Vertical", "Start"))
	self:FireReliableVFX("Gebura Red Mist/Great Split - Vertical", "Startup", self.LuaCharacter.Model)
	self.Combat:DivideSpeed(20)
	
	self.Hit = false
	self.Landed = false
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 3, -10)
	Hitbox.Params.Size = Vector3.new(30, 12, 36)

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		if self.Hit then
			return
		end
		
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			DontCheckBlock = true,
			DontBypassIFrames = {},
			TriggerActiveCounterOverOrEqualLevel = -1,
			Damage = {Amount = 30, DontKill = true}
		})

		if Validated then
			self.Hit = true

			self.Combat:StackState("HitboxImmunity", true)
			VictimCombat:StackState("HitboxImmunity", true)

			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
			
			self.LuaCharacter:Anchor(true)
			VictimLuaCharacter:Anchor(true)

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart)
			local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks["Gebura Red Mist"]["Great Split - Vertical"].BeatdownVictim)

			self.Combat:HideUI(true)
			VictimCombat:HideUI(true)
			
			self.Thread.Job:Task(task.delay(4.500, function()
				VictimAnimation:Destroy(0)
				
				GrabObject.Destroy(0)
				VictimLuaCharacter:Anchor(false)
				
				VictimCombat:HideUI(false)
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 70,
					Ragdoll = 5,
					Velocity = {Vector3.yAxis * 250, 0.15}
				})
				
				self.Combat:VictimImpactGround(VictimLuaPlayer)
				VictimCombat:Unstun()
			end))
			
			self.Thread.Job:Task(self.Animations["BeatdownUser"].Stopped:Connect(function()
				self:Close()
			end))

			self.Thread.OnClosed:Connect(function()
				VictimLuaCharacter:Anchor(false)
				self.LuaCharacter:Anchor(false)
				
				if VictimAnimation then
					VictimAnimation:Stop()
				end

				self.Combat:HideUI(false)
				VictimCombat:HideUI(false)
				
				self.Combat:StackState("HitboxImmunity", false)
				VictimCombat:StackState("HitboxImmunity", false)
			end)
			
			self.Animations["Windup"]:Stop(0)
			self.Animations["BeatdownUser"]:Play(0)
			
			if VictimAnimation then
				VictimAnimation:Play(0)
			end
		
			self:FireReliableVFX("Gebura Red Mist/Great Split - Vertical", "SlashHit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
			self.Thread.CancelJob:Task(self:CreateMoveSFX("Gebura Red Mist", "Great Split - Vertical", "cutscene"))
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:TimesSpeed(20)
		self:AddCooldown(15)
		
		self.Combat:StackState("Attacking", false)
		
		task.wait(0.35)
		
		--self.Combat:StackState("HitboxImmunity", false)
	end)
	
	self.Thread.Job:Task(task.delay(0.133, function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1.6
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 9
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)
	end))
	
	self.Thread.Job:Task(task.delay(1.533, function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 50
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)
	end))
	
	self.Thread.Job:Task(task.delay(2.200, function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = .95
		VelocityObject.Settings.RemoveTime = 1
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 85
		VelocityObject:Fire()
		
		self.Thread.Job:Task(VelocityObject)
		
		Hitbox:Detect()
		self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Hitbox.Params.Size, 8)
	end))
	
	self.Thread.Job:Task(task.delay(2.217, function()
		if self.Hit then
			return
		end
		
		self.Thread.CancelJob:Task(self:CreateMoveSFX("Gebura Red Mist", "Great Split - Vertical", "whiff"))
	end))
	
	self.Thread.Job:Task(task.delay(3.033, function()
		if self.Hit then
			return
		end
		
		self:FireReliableVFX("Gebura Red Mist/Great Split - Vertical", "Trail", self.LuaCharacter.Model, Reference)
		self:FireReliableVFXToSelf("Gebura Red Mist/Great Split - Vertical", "LeapVelocity", self.LuaCharacter.Model, Reference)
		
		self.Combat:AnticipateGround(3, nil, 0.1, function()
			self.Landed = true
		end)
	end))
	
	self.Thread.Job:Task(task.delay(3.5, function()
		if self.Hit then
			return
		end
		
		self.Animations.Windup:AdjustSpeed(0)
	end))
	
	self.Thread.Job:Task(task.spawn(function()
		local Start = os.clock()
		
		while not self.Landed and not self.Hit and (os.clock() - Start < 7) do
			task.wait()
		end
		
		if self.Hit then
			return
		end
		
		if Reference then
			Reference:Destroy()
		end

		self.Animations.Windup:AdjustSpeed(1)
		
		while self.Animations.Windup.TimePosition < 3.6 do
			self.Animations.Windup:AdjustSpeed(1)
			task.wait()
		end
		
		local SlamHitbox = self:CreateHitbox(false);
		SlamHitbox.Params.Offset = CFrame.new(0, 0, -25)
		SlamHitbox.Params.Size = vector.create(10, 20, 50)
		
		SlamHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			local Validated = self:Afflict(VictimLuaPlayer, {
				BreakBlock = true,
				Ragdoll = 2.5,
				Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 30 + Vector3.yAxis * 110, 0.1},
				Damage = 30
			})
		end)

		if SlamHitbox then
			SlamHitbox:Detect()
		end
		
		self:FireReliableVFX("Gebura Red Mist/Great Split - Vertical", "WhiffSlam", self.LuaCharacter.Model, self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -8))
		self.Combat.Hitbox:Destruction(CFrame.new(0, 0, -25), vector.create(10, 20, 50), 1)
		
		task.delay(1.28, function()
			ResumeSignal:Fire()
		end)
	end))
	
	ResumeSignal:Wait()
	
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.Uncancellable = true

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack