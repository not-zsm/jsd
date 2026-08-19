local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	self.StandHandler = self.Combat.Attacks["Star Platinum"]
	
	return self.StandHandler and self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.StandHandler:MoveStandByAction("Attack", 1.25)
	
	local Barrage : AnimationTrack = self.StandHandler.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks["Stardust Crusader"]["Heavy Barrage"].Stand)
	
	local BarrageHitbox = self:CreateHitbox()
	BarrageHitbox.Params.Offset = CFrame.new(0, 0, -6.5)
	BarrageHitbox.Params.Size = Vector3.new(7, 6, 8)
	BarrageHitbox.Params.DestroyOnEndCast = false

	BarrageHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		task.delay(0.06, function()
			BarrageHitbox:RemoveHumanoid(VictimLuaCharacter.Humanoid)
		end)

		local Validated = self:Afflict(VictimLuaPlayer, {
			DontCheckBlock = true,
			Damage = {Amount = 0.75, DontKill = true},
			TrueStun = 2,
			PlayRandomHitReaction = true,
		})

		if Validated then
			self:FireReliableVFX("Stardust Crusader/Heavy Barrage", "BarrageHit", VictimLuaCharacter.Torso)
		end
	end)
	
	local HitHitbox = self:CreateHitbox()
	HitHitbox.Params.Offset = CFrame.new(0, 0, -6.5)
	HitHitbox.Params.Size = Vector3.new(10, 10, 8)
	HitHitbox.Params.DestroyOnEndCast = false

	HitHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Finisher = self:IsFinisherEnabled() and VictimLuaCharacter.Humanoid.Health <= 30
		
		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontCheckBlock = true,
			Damage = 30,
			Ragdoll = 3,
			Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * (Finisher and 500 or 100) + Vector3.yAxis * (Finisher and 50 or 75), 0.1},
		})

		if Validated then
			
			if Finisher then
				self:FireReliableVFX("Stardust Crusader/Heavy Barrage", "HeavyHitFinisher", VictimLuaCharacter.Torso)
				self.Combat:VictimImpactGround(VictimLuaPlayer)
				
				if VictimLuaPlayer:PlayerExists() then
					local Offset = CFrame.identity
					local Size = 10

					local ThrowJob = Job.new()

					if not VictimLuaPlayer.IsNPC then
						ThrowJob:Task(VictimCombat.Hitbox:ClientSidedDestructionLoop(Offset, Size))
					end

					local Root : BasePart = VictimCombat:GetSimulatedRoot()

					ThrowJob:Task(RunService.PostSimulation:Connect(function()
						if (Root == nil) then 
							return ThrowJob:Destroy() 
						end

						VictimCombat.Hitbox:SphereDestruction(Root.Position, Size, 5)
					end))

					task.delay(2, ThrowJob.Destroy, ThrowJob)

					local AOEHitbox = VictimCombat.Hitbox:AoeHitboxForGrabs(self.LuaPlayer, Offset, Vector3.one * Size)

					if AOEHitbox then
						AOEHitbox.Params.DestroyOnEndCast = false

						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							VictimCombat:Afflict(NewVictimLuaPlayer, {
								TriggerActiveCounterOverOrEqualLevel = -1,
								DontCheckBlock = true,
								Damage = 50,
								Ragdoll = 4,
								Velocity = { (NewVictimLuaPlayer.Character.RootPart.Position - VictimLuaPlayer.Character.RootPart.Position).Unit * 150 + Vector3.yAxis * 45, 0.1}
							})
						end)

						AOEHitbox:BeginCast()

						ThrowJob:Task(function()
							AOEHitbox:EndCast()
							AOEHitbox:Destroy()
						end)
					end

					ThrowJob:Task(VictimCombat:GetStateChanged("Evasived"):Connect(function()
						ThrowJob:Destroy()
					end))
				end

			else
				self:FireReliableVFX("Stardust Crusader/Heavy Barrage", "HeavyHit", VictimLuaCharacter.Torso)
			end
			
			self.Combat:VictimImpactGround(VictimLuaPlayer)
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(14)
		
		if Barrage.IsPlaying then
			Barrage:Stop()
		end
		
		Barrage:Destroy()
		
		self.StandHandler:MoveStandByAction("Idle", 0.5)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(Barrage:GetMarkerReachedSignal("barrage"):Connect(function(Parameter : string)
		if (Parameter == "true") then
			self.Combat:StackState("GrabIFrames", true)
			self.Combat:DivideSpeed(50)

			self.Thread.OnClosed:Connect(function()
				self.Combat:TimesSpeed(50)
				
				task.wait(0.5)
				
				self.Combat:StackState("GrabIFrames", false)
			end)
			
			BarrageHitbox:BeginCast()
		else
			BarrageHitbox:EndCast()
			self.Combat:TimesSpeed(50)
		end
	end))
	
	self.Thread.Job:Task(Barrage:GetMarkerReachedSignal("punch"):Connect(function(Parameter : string)
		self.Combat:DivideSpeed(50)
		HitHitbox:Detect()
	end))
	
	self.Thread.Job:Task(Barrage:GetMarkerReachedSignal("end"):Connect(function()
		self:Close()
	end))
	
	Barrage:Play()
	self:FireReliableVFX("Stardust Crusader/Heavy Barrage", "Start", self.StandHandler.Model)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack