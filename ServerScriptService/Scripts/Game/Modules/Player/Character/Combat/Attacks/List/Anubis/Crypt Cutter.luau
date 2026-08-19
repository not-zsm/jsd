local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Anubis_Utility = require("./Anubis Utility")

local EventService = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)

local Remotes = ReplicatedStorage.Remotes

local CombatRemotes = Remotes.Combat
local GrabRemotes = Remotes.Grab

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Finisher(VictimLuaPlayer)
	local VictimLuaCharacter = VictimLuaPlayer.Character
	local VictimCombat = VictimLuaCharacter.Combat

	local VictimAnimation = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Anubis["Crypt Cutter"].FinisherVictim)
	local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -10) * CFrame.Angles(0, math.pi, 0))

	VictimLuaCharacter:StopRespawnTimer()
	
	self.Combat:DivideSpeed(100)
	
	self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
	self.Thread.Job:Task(VictimLuaCharacter:StopAutoRotate())

	self.Combat:StackState("HitboxImmunity", true)
	VictimCombat:StackState("HitboxImmunity", true)

	self.Combat:HideUI(true)
	VictimCombat:HideUI(true)

	self.Thread.OnClosed:Connect(function()
		self.Combat:TimesSpeed(100)
		
		VictimLuaCharacter:RestartRespawnTimer()
		
		self.Combat:HideUI(false)
		VictimCombat:HideUI(false)

		VictimCombat:StackState("HitboxImmunity", false)
		self.Combat:StackState("HitboxImmunity", false)
	end)
	
	----------------------------------------------

	self.Animations.Windup:Stop(0)
	self.Animations.FinisherUser:Play(0)
	VictimAnimation:Play(0)
	
	self:FireReliableVFX("Anubis/Crypt Cutter Finisher", "Start", self.LuaCharacter.Model, VictimLuaCharacter.Model, self.Combat.Sheathe.Model)
	
	self.Thread.Job:Task(self.Animations.FinisherUser:GetMarkerReachedSignal("KillVictim"):Connect(function()
		self.Combat:HideUI(false)
		VictimCombat:HideUI(false)
		
		if VictimAnimation then
			VictimAnimation:Stop(0)
		end
	
		GrabObject.Destroy(0)

		self:Afflict(VictimLuaPlayer, {
			ExcludeAttempts = true,
			FinisherKill = true,
		})
		
		VictimCombat:Unstun()
	end))

	self.Thread.OnClosed:Connect(function()
		GrabObject.Destroy(0)
		VictimCombat:Unstun()

		self.Animations.FinisherUser:Stop()
		
		if VictimAnimation then
			VictimAnimation:Stop()
		end
	end)
	
	self.Thread.Job:Task(self.Animations.FinisherUser.Stopped:Connect(function()
		self:Close()
	end))
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(self.SpeedReduction)
	
	local Finisher =  nil
	
	self.Hit = false
	self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Cooldown)
		
		if not self.Combat:GetState("Grabbed") then
			self.LuaCharacter:SetCollisionGroup("Player")
		end
		
		self.Combat:TimesSpeed(self.SpeedReduction)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(task.delay(self.TimeUntilMoveTimesOut, function()
		if not Finisher then
			self:Close()
		end
	end)) 

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("End"):Once(function()
		if not Finisher then
			self:Close()
		end
	end))
	
	local Swing = 0
	
	if self.LuaPlayer.IsNPC then
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 2
		VelocityObject.Settings.RemoveTime = 1.9
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 90000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 10;
		VelocityObject:Fire();
	end;
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Hitbox"):Connect(function(Data)
		Swing += 1
		
		if (Swing == 1) then
			self.Animations.Windup:AdjustSpeed(1.25);
			
			if self.LuaPlayer.IsNPC then
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 2
				VelocityObject.Settings.RemoveTime = 1.9
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 90000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 10;
				VelocityObject:Fire();
			end;
		end
		
		local IsFinal = (Data == "Final")

		local Root : BasePart = self.Combat:GetSimulatedRoot()
		
		local Hitbox = self:CreateHitbox(not IsFinal)
		Hitbox.Params.Offset = if IsFinal then CFrame.new(0, 0, -2.5) else CFrame.new(0, 0, -1.25)
		Hitbox.Params.Size = if IsFinal then vector.create(8, 7, 12) else 8
		
		if IsFinal then
			local Rnd = Random.new();

			self.Combat.Hitbox:CreateHavocReplicated({
				parameters = {
					origin = Hitbox:GetCFrame() * CFrame.new(0, 1.5, 0),
					shape = "Sphere", 
					radius = 4,
				},
				debris = {
					scale = 0.9,
					radius = 6,
					velocity = function(part)
						return self.LuaCharacter.RootPart.CFrame.LookVector * 25 + Rnd:NextUnitVector() * 10 + Vector3.yAxis * 15;
					end,
				},
			});
		end;
		
		local FoundUserToFinish = false
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			if FoundUserToFinish then return end
			
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			--if IsFinal then -- Why did bro check it here 😭
			--	Finisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= self.FinisherHealth)
				
			--	if Finisher then
			--		self:Finisher(VictimLuaPlayer)
			--		FoundUserToFinish = true
					
			--		return
			--	end
			--end
			
			Finisher = IsFinal and (self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= self.FinisherHealth))

			local Victim_Ragdolled = VictimCombat:GetState("Ragdolled")
			local Victim_Blocking = VictimCombat:GetState("Blocking")
		
			local ForwardVelocity = {Root.CFrame.LookVector * (Victim_Ragdolled and 35 or 55), 0.15} 
			
			self.Hit = self:Afflict(VictimLuaPlayer, {
				Damage = not Finisher and if IsFinal then 5 else 3 or nil,
				TrueStun = (Swing == 2 and 0.75 or nil),
				Stun = (Swing == 1 and 0.75 or nil),
				Ragdoll = if IsFinal then 1.5 else nil,
				BreakBlock = IsFinal,
				BlockAngle = math.rad(180),
				
				Velocity = if IsFinal then 
					{(Root.CFrame.LookVector * 40) + vector.create(0, Victim_Ragdolled and 35 or 25, 0), 0.25} 
					else 
					ForwardVelocity
				,
				
				DontRestartRespawnTimer = true,
				PlayRandomHitReaction = true
			})
			
			if self.Hit then
				self:FireReliableVFX("Anubis/Possession Flurry", "Emit", VictimLuaCharacter.RootPart, "HitEffect")
				
				if Finisher then
					self:Finisher(VictimLuaPlayer)
					FoundUserToFinish = true
				end
			else
				if Victim_Blocking then
					local VelocityObject = self:VelocityOn(VictimCombat)
					VelocityObject.Settings.Velocity = ForwardVelocity[1]
					VelocityObject.Settings.RemoveTime = ForwardVelocity[2]
					VelocityObject:Fire()
				end
			end
		end)
		
		Hitbox:BeginCast(0.1) 
		
		if IsFinal then
			self.Thread.Job:Task(task.delay(0.1, function()
				if not self.Hit then
					self.Animations.Windup:AdjustSpeed(0.4)
				end
			end))
		end
	end))
	
	self:FireReliableVFX(self.InternalEffectPath, "Start", self.LuaCharacter.Model)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	
	self.Cooldown = 16
	
	self.TimeUntilMoveTimesOut = 5
	self.SpeedReduction = 4
	self.FinisherHealth = 10
	
	self.InternalEffectPath = `Anubis/{script.Name}`
	
	--self.AnimationSettings.Speed = 1.25
	self:_Init()
	
	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack