

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
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
	self.Combat:DivideSpeed(50)

	self.Hit = false

	local DashVelocity = self.Combat:Velocity()
	DashVelocity.Settings.Duration = 1
	DashVelocity.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
	DashVelocity.Settings.Controllable = true
	DashVelocity.Settings.Z = 75

	self.Thread.Job:Task(DashVelocity)

	local DashHitbox = self:CreateHitbox()
	DashHitbox.Params.Size = Vector3.new(5.5, 4, 7)
	DashHitbox.Params.Offset = CFrame.new(0, 0, -3)
	DashHitbox.Params.DestroyOnEndCast = false
	DashHitbox.Params.MaxTargets = 1

	local WasBlocked = false

	DashHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local Validated, Type = self:Afflict(VictimLuaPlayer, {
			YDifferenceValue = -2,
			Damage = {Amount = 2, DontKill = true},
			--BreakBlock = true
		})

		WasBlocked = (Type == "Blocked")

		if WasBlocked then
			self.Animations.Windup:AdjustSpeed(0.585)
			DashVelocity:Destroy()
		end

		if Validated then
			DashHitbox:EndCast()
			DashVelocity:Destroy()

			self.Hit = true
		
			local StopRotation = self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -5) * CFrame.Angles(0, math.pi, 0))

			--local Is_Finisher = self:IsFinisherEnabled() and VictimLuaCharacter.Humanoid.Health <= 15

			local AttackerAnimation : AnimationTrack = self.Animations.Hit--[Is_Finisher and "Finisher" or "Hit"]
			local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Chara["Fight"].Victim)--[Is_Finisher and "FinisherVictim" or "Victim"])

			self.Animations.Windup:Stop(0)
			AttackerAnimation:Play(0)

			if VictimAnimation then
				VictimAnimation:Play(0) -- Looks weird on 0.1.
			end

			self.Thread.OnClosed:Connect(function()
				if VictimAnimation then
					VictimAnimation:Stop()
				end

				if not GrabObject.Destroyed then
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)

			--if Is_Finisher then
			--	self.LuaPlayer.Replication.Attributes:SetAttribute("GrowABlueGarden", true)
				
			--	self.Thread.OnClosed:Connect(function()
			--		self.LuaPlayer.Replication.Attributes:SetAttribute("GrowABlueGarden", nil)
			--		self.Combat:ToggleHeadMovement(true)
			--	end)
				
			--	self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("hit"):Connect(function()
			--		self.Combat:ToggleHeadMovement(false)
			--	end))
				
			--	self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("cut"):Connect(function()
			--		GrabObject.Destroy(0)
					
			--		VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 3, -82.648))
			--		VictimAnimation:Stop(0)
					
			--		self:Afflict(VictimLuaPlayer, {
			--			ExcludeAttempts = true,
			--			FinisherKill = true,
			--			Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 15 + Vector3.yAxis * 100, 0.1},
			--		})

			--		VictimCombat:Unstun()
					
			--		AttackerAnimation:Stop(0)
			--		self.LuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -82.648))
			--		self.Animations.FinisherEnd:Play(0)
			--		self.Combat:ToggleHeadMovement(true)
					
			--		local Velocity = self.Combat:Velocity()
			--		Velocity.Settings.Duration = 1
			--		Velocity.Settings.RemoveTime = 1
			--		Velocity.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
			--		Velocity.Settings.Controllable = true
			--		Velocity.Settings.Z = 30
			--		Velocity:Fire()
					
			--		StopRotation:Destroy()
			--	end))
				
			--	self.Thread.Job:Task(self.Animations.FinisherEnd.Stopped:Once(function()
			--		self:Close()
			--	end))
			--else
				local Success = false
				local Fought = false

				if not self.LuaPlayer.IsNPC then
					local FightRemote = Instance.new("RemoteEvent")
					FightRemote.Name = "CharaFightRemote"
					FightRemote.Parent = self.LuaCharacter.Model

					self.Thread.Job:Task(FightRemote)

					self.Thread.Job:Task(FightRemote.OnServerEvent:Connect(function(Player, InRange : boolean)
						if Fought or (Player ~= self.LuaPlayer.Player) or (typeof(InRange) ~= "boolean") then return end

						Fought = true
						Success = InRange
					end))

					self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("attack"):Once(function()
						self.Combat:HideUI(true)

						self.Thread.OnClosed:Connect(function()
							self.Combat:HideUI(false)
						end)
					end))
				else
					Success = (math.random(1, 7) ~= 1)
				end
				
				self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("end"):Connect(function()
					self:Close()
				end))
				
				self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("hit"):Connect(function()
					self:FireReliableVFX("Chara/Fight", "Slash", self.LuaCharacter.Model, Success)

					GrabObject.Destroy(2)
					VictimAnimation:Stop(0)
					
					VictimCombat:StackState("CannotDash", true, 1)

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = Success and 10 or 2,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 75 + Vector3.yAxis * 15, 0.1},
						Ragdoll = 1.75,
					})

					VictimCombat:Unstun()
				end))
			--end

			--if Is_Finisher then
				--self:FireReliableVFX("Chara/Fight", "Finisher", self.LuaCharacter.Model)
			--else
				self:FireReliableVFX("Chara/Fight", "Hit", self.LuaCharacter.Model)
			--end
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(21)

		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("dash"):Once(function()
		DashVelocity:Fire()
		DashHitbox:BeginCast(0.5)

		DashHitbox.Events.OnCastEnded:Once(function()
			if not WasBlocked and not self.Hit and self.Animations.Windup.IsPlaying then
				self.Animations.Windup:AdjustSpeed(0.8)
			end
		end)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Once(function()
		if not self.Hit then
			self:Close()
		end
	end))

	self:FireReliableVFX("Chara/Fight", "Start", self.LuaCharacter.Model)
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