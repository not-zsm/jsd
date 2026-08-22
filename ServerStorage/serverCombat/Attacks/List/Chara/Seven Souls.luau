

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )
local VelocityUtil = require( ReplicatedStorage.Shared.Game.Velocity.VelocityUtil )
local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:Activate()
	self.Hit = false
	
	self.Combat:StackState("GrabIFrames", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)
	
	local HitHitbox = self:CreateHitbox()
	HitHitbox.Params.Offset = CFrame.new(0, 0, -3)
	HitHitbox.Params.Size = Vector3.new(15, 12, 8.5)
	HitHitbox.Params.DestroyOnEndCast = false
	HitHitbox.Params.MaxTargets = 1
	
	HitHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local Validated = self:Afflict(VictimLuaPlayer, {
			Damage = {Amount = 5, DontKill = true},
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontBypassIFrames = self.LuaPlayer.IsFounderAndLeadScripter and {} or nil,
			BreakBlock = true,
		})

		if Validated then
			self.Hit = true
			self.Animations.Windup:Stop(0)
			
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			self.Combat:StackState("HitboxImmunity", true)
			VictimCombat:StackState("HitboxImmunity", true)
			
			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

			self.Combat:HideUI(true)
			VictimCombat:HideUI(true)
			
			VictimLuaCharacter:StopRespawnTimer()

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -7) * CFrame.Angles(0, math.pi, 0))
			local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Chara["Seven Souls"].Victim)

			--local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

			--if Matched then
			--	--self.LuaPlayer.Replication.Attributes:SetAttribute("Ultimate_Mute", true)
			--	Ultimate:SetBarPausing(true)

			--	self.Thread.OnClosed:Connect(function()
			--		--self.LuaPlayer.Replication.Attributes:SetAttribute("Ultimate_Mute", nil)
			--		Ultimate:SetBarPausing(false)
			--	end)
			--end
			
			local FirstSuccess, SecondSuccess = false, false
			local FirstFought, SecondFought = false, false

			if not self.LuaPlayer.IsNPC then
				local FightRemote = Instance.new("RemoteEvent")
				FightRemote.Name = "CharaSevenSoulsRemote"
				FightRemote.Parent = self.LuaCharacter.Model

				self.Thread.Job:Task(FightRemote)

				self.Thread.Job:Task(FightRemote.OnServerEvent:Connect(function(Player, InRange : boolean, Stage : number)
					if typeof(Stage) ~= "number" then return end
					if (Player ~= self.LuaPlayer.Player) or (typeof(InRange) ~= "boolean") then return end

					if (Stage == 1 and not FirstFought) then
						FirstFought = true
						FirstSuccess = InRange
		
					elseif (Stage == 2 and not SecondFought) then
						SecondFought = true
						SecondSuccess = InRange
					end
				end))

				self.Thread.Job:Task(self.Animations.Full:GetMarkerReachedSignal("on_qte"):Connect(function(Parameter : string)
					if (Parameter == "1" and not FirstSuccess) then
						self.Animations.Full:Stop(0)
						self.Animations.FirstQTEMiss:Play(0)

						VictimAnimation:Stop(0)
						GrabObject.Destroy(0)
						VictimCombat:Unstun()

						self.Combat:TSBPushVictim(VictimLuaPlayer, {
							LookVectorInsteadOfDifference = true,
							DontBeginAoeHitbox = true,
							LandedRollVelocityZ = 225,
							LandedRollDuration = 0.85,
						})

						task.wait(2)

						self:Close()
						
					elseif (Parameter == "2" and not SecondSuccess) then
						task.wait(0.3)
						
						GrabObject.Destroy(0)
						VictimAnimation:Stop(0)

						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Damage = 20,
							Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 75 + Vector3.yAxis * 50, 0.05},
							Ragdoll = 3,
						})

						VictimCombat:Unstun()
						
						task.wait(0.3)
						
						self.Animations.Full:Stop(0.5)
						
						task.wait(0.5)
			
						self:Close()
					end
				end))
			else
				FirstSuccess = (math.random(1, 7) ~= 1)
				SecondSuccess = (math.random(1, 7) ~= 1)
			end
			
			self.Thread.OnClosed:Connect(function()
				local SpecialHell = self.Combat:GetFirstAttack("Special Hell")

				if SpecialHell and FirstSuccess and SecondSuccess then
					SpecialHell:CompleteStep()
				end

				VictimLuaCharacter:RestartRespawnTimer()
				
				self.Combat:HideUI(false)
				VictimCombat:HideUI(false)

				if VictimAnimation then
					VictimAnimation:Stop()
				end

				if not GrabObject.Destroyed then
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end

				self.Combat:StackState("HitboxImmunity", false)
				VictimCombat:StackState("HitboxImmunity", false)
			end)

			self.Thread.Job:Task(self.Animations.Full:GetMarkerReachedSignal("end"):Once(function()
				self:Close()
			end))
			
			self.Thread.Job:Task(self.Animations.Full:GetMarkerReachedSignal("big_slash"):Once(function()
				if not SecondSuccess then return end
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {Amount = 15, DontKill = true}, --15
				})
			end))
			
			self.Thread.Job:Task(self.Animations.Full:GetMarkerReachedSignal("boom"):Once(function()
				if not SecondSuccess then return end
				
				self.Animations.Full:AdjustSpeed(0.8)
				
				GrabObject.Destroy(0.5)
				VictimAnimation:Stop(0)

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 30,--if (VictimLuaCharacter.Humanoid.Health <= 50) then 999 else 50,
					Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 100 + Vector3.yAxis * 125, 0.05},
					Ragdoll = 3,
				})
				
				self.Combat:VictimImpactGround(VictimLuaPlayer)

				VictimCombat:Unstun()
			end))
			
			local function Slash()
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {Amount = 1, DontKill = true}
				})
			end
			
			local Clone_Slashes = {19, 68, 107, 143, 174, 210, 233, 295}

			for Index, Time in Clone_Slashes do
				self.Thread.Job:Task(task.delay(Time / 60, Slash))
			end
			
			self.Thread.Job:Task(self.Animations.Full:GetMarkerReachedSignal("slash"):Connect(Slash))
			
			self.Animations.Full:Play(0)

			if VictimAnimation then
				VictimAnimation:Play(0) -- Looks weird on 0.1.
			end

			self:FireReliableVFX("Chara/Seven Souls", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(25)
		
		self.Combat:TimesSpeed(50)
		
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("GrabIFrames", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Once(function()
		self:Close()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("dash"):Connect(function()
		local DashHitbox = self:CreateHitbox()
		DashHitbox.Params.Offset = CFrame.new(0, 0, -4)
		DashHitbox.Params.Size = Vector3.new(15, 8, 15)
		DashHitbox.Params.DestroyOnEndCast = false

		DashHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local Validated = self:Afflict(VictimLuaPlayer, {
				Damage = {Amount = 2.5, DontKill = true},
				TriggerActiveCounterOverOrEqualLevel = -1,
				DontCheckBlock = true,
			})
			
			if Validated then
				self.Combat:TSBPushVictim(VictimLuaPlayer, {
					LandedRollVelocityZ = 150,
					LandedRollDuration = 0.83,
					DurationMultiplier = 1.5
				})
			end
		end)
		
		DashHitbox:BeginCast(0.25)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		self:FireReliableVFX("Chara/Seven Souls", "Slash", self.LuaCharacter.RootPart)
		HitHitbox:BeginCast(0.1)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("boost"):Once(function()
		self.LuaCharacter.Torso.CanCollide = false
		self.LuaCharacter.RootPart.CanCollide = true

		self.Thread.OnClosed:Connect(function()
			self.LuaCharacter.Torso.CanCollide = true
			self.LuaCharacter.RootPart.CanCollide = false
		end)
		
		local Velocity = self.Combat:Velocity()
		Velocity.Settings.FixScale = true
		Velocity.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		Velocity.Settings.Controllable = true
		Velocity.Settings.Duration = 8.5
		Velocity.Settings.Z = 100
		Velocity:Fire()
		
		self.Thread.Job:Task(Velocity)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("jump"):Once(function()
		local Velocity = self.Combat:Velocity()
		Velocity.Settings.FixScale = true
		Velocity.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		Velocity.Settings.Controllable = true
		Velocity.Settings.Duration = 0.925
		Velocity.Settings.RemoveTime = Velocity.Settings.Duration
		Velocity.Settings.Z = 90
		Velocity:Fire()

		self.Thread.Job:Task(Velocity)
	end))
	
	self:FireReliableVFX("Chara/Seven Souls", "Start", self.LuaCharacter.Model)
end

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.Hit = false
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack