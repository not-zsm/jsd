

local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )
local VelocityUtil = require( replicatedStorage.modules.shared.Game.Velocity.VelocityUtil )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Hit = false
	
	self.Combat:StackState("GrabIFrames", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)
	
	--local CurrentDash = ""

	--local DashHitbox = self:CreateHitbox()
	--DashHitbox.Params.Offset = CFrame.new(0, 0, -6)
	--DashHitbox.Params.Size = Vector3.new(15, 10, 15)
	--DashHitbox.Params.DestroyOnEndCast = false
	
	--DashHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
	--	local Validated = self:Afflict(VictimLuaPlayer, {
	--		BreakBlock = true,
	--		Damage = 7.5,
	--	})

	--	if Validated then
	--		local Root : BasePart = self.Combat:GetSimulatedRoot()
	--		local Difference = Vector3.zero

	--		if CurrentDash == "1" then
	--			Difference = Root.CFrame.RightVector + Root.CFrame.LookVector

	--		elseif CurrentDash == "2" then
	--			Difference = -Root.CFrame.RightVector + Root.CFrame.LookVector

	--		elseif CurrentDash == "3" then
	--			Difference = Root.CFrame.LookVector
	--		end

	--		self.Combat:TSBPushVictim(VictimLuaPlayer, {
	--			--LookVectorInsteadOfDifference = true,
	--			DontBeginAoeHitbox = true,
	--			Difference = Difference,
	--			LandedRollVelocityZ = 270,
	--			LandedRollDuration = 0.55,
	--			OverridePrevious = true
	--		})
	--	end
	--end)

	local HitHitbox = self:CreateHitbox()
	HitHitbox.Params.Offset = CFrame.new(0, 0, -5)
	HitHitbox.Params.Size = Vector3.new(15, 10, 15)
	HitHitbox.Params.DestroyOnEndCast = false
	HitHitbox.Params.MaxTargets = 1
	
	HitHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
		})

		if Validated then
			self.Hit = true
			self.Animations.Windup:Stop(0)
			
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			self.Combat:StackState("HitboxImmunity", true)
			VictimCombat:StackState("HitboxImmunity", true)
			
			VictimLuaCharacter:StopRespawnTimer()

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))

			local FinishersEnabled = self:IsFinisherEnabled();
			local Activate_Finisher = FinishersEnabled and (VictimLuaCharacter.Humanoid.Health <= 40)
			local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(replicatedStorage.animations.Attacks.chara["Cursed Remedy"][Activate_Finisher and "FinisherVictim" or "Victim"])

			self.Thread.OnClosed:Connect(function()
				self.Combat:StackState("HitboxImmunity", false)
				VictimCombat:StackState("HitboxImmunity", false)
				
				VictimLuaCharacter:RestartRespawnTimer()

				if VictimAnimation then
					VictimAnimation:Stop()
				end

				if not GrabObject.Destroyed then
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)

			if self.LuaPlayer.IsNPC then
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 7
				VelocityObject.Settings.RemoveTime = 5.5
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.FixScale = true;
				VelocityObject.Settings.Z = 45
				VelocityObject:Fire();
			end;

			if Activate_Finisher then
				
				local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

				if Matched then
					Ultimate:SetBarPausing(true)

					self.Thread.OnClosed:Connect(function()
						Ultimate:SetBarPausing(false)
					end)
				end
				
				self.Thread.OnClosed:Connect(function()
					local SpecialHell = self.Combat:GetFirstAttack("Special Hell")
					
					if SpecialHell then
						SpecialHell:CompleteStep()
					end
				end)
				
				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("finisher"):Once(function()
					self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
					
					self.Combat:HideUI(true)
					VictimCombat:HideUI(true)
					
					self.LuaPlayer.Replication.Attributes:SetAttribute("Ultimate_Mute", true)

					self.Thread.OnClosed:Connect(function()
						self.LuaPlayer.Replication.Attributes:SetAttribute("Ultimate_Mute", nil)
					end)

					GrabObject.SetOffset(CFrame.new(0, 0, -10.01) * CFrame.Angles(0, math.pi, 0))

					self.Thread.OnClosed:Connect(function()
						self.Combat:HideUI(false)
						VictimCombat:HideUI(false)
					end)
				end))
				
				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("cut"):Once(function()
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						FinisherKill = true,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 25, 0.1}
					})

					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end))

				self.Thread.Job:Task(self.Animations.Finisher.Stopped:Once(function()
					self:Close()
				end))

				self.Animations.Finisher:Play(0)
				
				if VictimAnimation then
					VictimAnimation:Play(0)
				end
				
				self:FireReliableVFX("Chara/Cursed Remedy", "Finisher", self.LuaCharacter.Model, VictimLuaCharacter.Model)
			else
				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("end"):Once(function()
					self:Close()
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("hit"):Once(function()
					GrabObject.Destroy(0.5)
					VictimAnimation:Stop(0)

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = 40,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 100 + Vector3.yAxis * 35, 0.1},
						Ragdoll = 2,
					})

					VictimCombat:Unstun()
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
					if (Parameter == "13") then
						self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
						GrabObject.SetBound(nil)

					elseif (Parameter == "14") then
						GrabObject.SetBound(self.LuaCharacter.RootPart)
					end
				end))

				self.Animations.Hit:Play(0)

				if VictimAnimation then
					VictimAnimation:Play(0) -- Looks weird on 0.1.
				end

				self:FireReliableVFX("Chara/Cursed Remedy", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
			end

			--local function Finisher()
			--	self.Combat:StackState("HitboxImmunity", true)
			--	VictimCombat:StackState("HitboxImmunity", true)

			--	VictimLuaCharacter:StopRespawnTimer()

			--	self.Combat:HideUI(true)
			--	VictimCombat:HideUI(true)
				
			--	GrabObject.SetOffset(CFrame.new(0, 0, -10.01) * CFrame.Angles(0, math.pi, 0))
			--	GrabObject.SetBound(self.LuaCharacter.RootPart)

			--	self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

			--	self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("cut"):Once(function()
			--		self:Afflict(VictimLuaPlayer, {
			--			ExcludeAttempts = true,
			--			FinisherKill = true,
			--			Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 25, 0.1}
			--		})

			--		GrabObject.Destroy(0)
			--		VictimCombat:Unstun()
			--	end))

			--	self.Thread.Job:Task(self.Animations.Finisher.Stopped:Once(function()
			--		self:Close()
			--	end))
				
			--	local FinisherVictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(replicatedStorage.animations.Attacks.chara["Cursed Remedy"].FinisherVictim)

			--	self.Thread.OnClosed:Connect(function()
			--		VictimLuaCharacter:RestartRespawnTimer()

			--		self.Combat:HideUI(false)
			--		VictimCombat:HideUI(false)

			--		if FinisherVictimAnimation then
			--			FinisherVictimAnimation:Stop()
			--		end
					
			--		self.Combat:StackState("HitboxImmunity", false)
			--		VictimCombat:StackState("HitboxImmunity", false)
			--	end)

			--	self.Animations.Hit:Stop(0)
			--	VictimAnimation:Stop(0)

			--	self.Animations.Finisher:Play(0)
			--	FinisherVictimAnimation:Play(0)

			--	self:FireReliableVFX("Chara/Cursed Remedy Finisher", "Start", self.LuaCharacter.Model, VictimLuaCharacter.Model)
			--end
			
			--local Activate_Finisher = false

			--self.Thread.Job:Task(task.delay(391 / 60, function()
			--	if Activate_Finisher then
			--		Finisher()
			--	end
			--end))
			
			--self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
			--	if (Parameter == "13") then
			--		Activate_Finisher = (VictimLuaCharacter.Humanoid.Health <= 15)
					
			--		if not Activate_Finisher then
			--			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
			--			GrabObject.SetBound(nil)
			--		end
				
			--	elseif (Parameter == "14") then
			--		GrabObject.SetBound(self.LuaCharacter.RootPart)
			--	end
			--end))
				
			--self.Thread.OnClosed:Connect(function()
			--	VictimLuaCharacter:RestartRespawnTimer()

			--	if VictimAnimation then
			--		VictimAnimation:Stop()
			--	end

			--	if not GrabObject.Destroyed then
			--		GrabObject.Destroy(0)
			--		VictimCombat:Unstun()
			--	end
				
			--	self.Combat:StackState("HitboxImmunity", false)
			--	VictimCombat:StackState("HitboxImmunity", false)
			--end)
			
			--self.Animations.Windup:Stop(0)
			--self.Animations.Hit:Play(0)

			--if VictimAnimation then
			--	VictimAnimation:Play(0) -- Looks weird on 0.1.
			--end

			--self:FireReliableVFX("Chara/Cursed Remedy", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(16)
		
		self.Combat:TimesSpeed(50)
		
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("GrabIFrames", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Once(function()
		self:Close()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("vfx"):Connect(function(CurrentDash : string)
		local DashHitbox = self:CreateHitbox()
		DashHitbox.Params.Offset = CFrame.new(0, 0, -6)
		DashHitbox.Params.Size = Vector3.new(15, 10, 15)
		DashHitbox.Params.DestroyOnEndCast = false
		
		local Root : BasePart = self.Combat:GetSimulatedRoot()
		local Difference = Vector3.zero

		if CurrentDash == "1" then
			Difference = Root.CFrame.RightVector + Root.CFrame.LookVector

		elseif CurrentDash == "2" then
			Difference = -Root.CFrame.RightVector + Root.CFrame.LookVector

		elseif CurrentDash == "3" then
			Difference = Root.CFrame.LookVector
		end;
		
		if self.LuaPlayer.IsNPC then
			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 0.4
			VelocityObject.Settings.RemoveTime = 0.25
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 320000
			VelocityObject.Settings.Controllable = false
			VelocityObject.Settings.FixScale = true;
			VelocityObject.Settings.Velocity = Difference.Unit * 125;
			VelocityObject:Fire();
		end;
		
		local Rnd = Random.new();

		self.Combat.Hitbox:CreateHavocReplicated({
			parameters = {
				origin = CFrame.lookAlong(Root.Position, Difference) + Difference.Unit * 8,
				shape = "Box", 
				size = Vector3.new(7, 12, 22),
				block_size = 5,
			},
			debris = {
				scale = 0.9,
				size = Vector3.new(12, 18, 26),
				velocity = function(part)
					return Difference * Rnd:NextNumber(15, 40) + Rnd:NextUnitVector() * 15 + Vector3.yAxis * Rnd:NextNumber(5, 25);
				end,
			},
		});
		
		DashHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local Validated = self:Afflict(VictimLuaPlayer, {
				BreakBlock = true,
				Damage = 4,
			})

			if Validated then
				self.Combat:TSBPushVictim(VictimLuaPlayer, {
					DontBeginAoeHitbox = true,
					Difference = Difference,
					LandedRollVelocityZ = 270,
					LandedRollDuration = 0.55,
					OverridePrevious = true
				})
			end
		end)
		
		DashHitbox:Detect()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		HitHitbox:BeginCast(0.15)
	end))
	
	self:FireReliableVFX("Chara/Cursed Remedy", "Start", self.LuaCharacter.Model)
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