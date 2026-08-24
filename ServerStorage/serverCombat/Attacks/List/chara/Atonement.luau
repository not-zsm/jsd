local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local Minigame = require( script.Minigame )
local NPCSupport = require( script.NPCSupport )
local Unstuck = require( script.Unstuck )

--if not RunService:IsStudio() then
--	workspace:SetAttribute("DisableAtonement", true) -- Jimpee told me to add this, remove when you want it in game.
--end

local Attack = {} -- need to add an npc that runs at you and uses the move to test the minigame
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not workspace:GetAttribute("DisableAtonement") -- Jimpee told me to add this.
end


function Attack:Activate()
	if workspace:GetAttribute("DisableAtonement") then return end
	
	self.Hit = false

	self.Combat:StackState("GrabIFrames", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Config.Cooldown)
		self.Combat:TimesSpeed(50)

		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("GrabIFrames", false)
	end)

	-->> Hitboxes <<--
	-->> Slashes
	local SlashHitbox1 = self:CreateHitbox(true);
	SlashHitbox1.Params.Offset = if self.LuaPlayer.IsNPC then CFrame.new(0, 0, -0.5) else CFrame.new(0, 0, -4.5)
	SlashHitbox1.Params.Size = 8.3

	SlashHitbox1.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
			TriggerActiveCounterOverOrEqualLevel = -1,
			Ragdoll = 2.5,
			Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 50 + Vector3.yAxis * 8, 0.1},
			Damage = self.Config.DamageTable.Slash1,
		})
	end)

	local SlashHitbox2 = self:CreateHitbox(false);
	SlashHitbox2.Params.Offset = CFrame.new(-0.27, 0, -5) * CFrame.Angles(0, 0, math.rad(-35))
	SlashHitbox2.Params.Size = Vector3.new(4, 8.5, 11)

	SlashHitbox2.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character

		local Validated = self:Afflict(VictimLuaPlayer, {
			--BreakBlock = true,
			TriggerActiveCounterOverOrEqualLevel = -1,
			Ragdoll = 2.5,
			Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 45 + Vector3.yAxis * 8, 0.1},
			Damage = self.Config.DamageTable.Slash2,
		})
	end)

	-->> Grab
	local GrabHitbox = self:CreateHitbox(false);
	GrabHitbox.Params.Offset = if self.LuaPlayer.IsNPC then CFrame.new(0, 0, -1) else CFrame.new(0, 0, -6)
	GrabHitbox.Params.Size = Vector3.new(8, 8.5, 12)
	GrabHitbox.Params.MaxTargets = 1
	GrabHitbox.Params.DestroyOnEndCast = false

	GrabHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
			TriggerActiveCounterOverOrEqualLevel = -1,
		})

		if Validated then
			self.Hit = true
			GrabHitbox:EndCast()
			GrabHitbox:Destroy()

			self:StartGrab(VictimLuaPlayer)
		end
	end)

	-->> Other <<--
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Connect(function(Parameter)
		if Parameter == "1" then
			--task.wait(0.267)
			SlashHitbox1:BeginCast(0.1)
		else
			SlashHitbox2:Detect()
		end
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("grab"):Connect(function(Parameter)
		if Parameter == "1" then
			GrabHitbox:BeginCast(0.33)
		else
			GrabHitbox:BeginCast(0.44)
		end
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("End"):Once(function()
		self.Thread.Job:Task(task.delay(self.Config.Endlag, self.Close, self)) 
	end))

	self:FireReliableVFX("chara/Atonement", "Start", self.LuaCharacter.Model)
	if self.LuaPlayer.IsNPC then
		NPCSupport(self.LuaCharacter, self.Animations.Windup)
	end
end

function Attack:StartGrab(VictimLuaPlayer)
	-->> Setup <<--
	local MinigameResult = nil

	local VictimLuaCharacter = VictimLuaPlayer.Character
	local VictimCombat = VictimLuaCharacter.Combat
	
	local VictimHitAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(replicatedStorage.animations.Attacks.chara["Atonement"].VictimHit)
	local VictimLoseAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(replicatedStorage.animations.Attacks.chara["Atonement"].VictimLose)
	
	local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0))

	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:HideUI(true)
	
	if VictimCombat then
		VictimCombat:StackState("HitboxImmunity", true)
		VictimCombat:HideUI(true)
	end

	local LuaCharacterStopRotate = self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
	--self.Thread.Job:Task(VictimLuaCharacter:StopAutoRotate()) -- Don't think u need this
	
	if VictimLuaCharacter then
		VictimLuaCharacter:StopRespawnTimer()
	end

	self.LuaCharacter:HideTitle(true)
	
	self.LuaCharacter:Anchor(true)
	VictimLuaCharacter:Anchor(true) -- keeps bugging if not anchored for some reason
	
	local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

	if Matched then
		Ultimate:SetBarPausing(true)

		self.Thread.OnClosed:Connect(function()
			Ultimate:SetBarPausing(false)
		end)
	end

	self:FireReliableVFX("chara/Atonement", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model)

	self.Thread.OnClosed:Connect(function()
		if not self.Ended then
			if VictimLuaCharacter then
				VictimLuaCharacter:Anchor(false)
			end
			
			if VictimHitAnimation then
				VictimHitAnimation:Stop()
			end
			
			if GrabObject then
				GrabObject.Destroy(0)
			end
			
			VictimCombat:Unstun()
		end

		self.Combat:StackState("HitboxImmunity", false)
		self.Combat:HideUI(false)
		
		if VictimCombat then
			VictimCombat:StackState("HitboxImmunity", false)
			VictimCombat:HideUI(false)
		end
		
		self.LuaCharacter:HideTitle(false)
		self.LuaCharacter:Anchor(false)
		
		if VictimLuaCharacter then
			VictimLuaCharacter:RestartRespawnTimer()
		end
	end)

	-->> Start <<--
	self.Animations.Windup:Stop(0)
	self.Animations.Hit:Play(0)
	
	if VictimHitAnimation then
		VictimHitAnimation:Play(0)
	end

	-->> Start Minigame
	if VictimLuaPlayer and not VictimLuaPlayer.IsNPC then
		if VictimLuaCharacter.Model then
			VictimLuaCharacter.Model:SetAttribute("InMinigame", true)
		end
		
		local MinigameSignal = Minigame.Start(VictimLuaPlayer.Player)
		self.Thread.Job:Task(MinigameSignal:Connect(function(Player : Player, Result : String)
			if Player == VictimLuaPlayer.Player then
				MinigameResult = Result
			end
			
			VictimLuaCharacter.Model:SetAttribute("InMinigame", nil)
		end))
	elseif VictimCombat and VictimCombat.IsChara then
		MinigameResult = "success"
	else
		if math.random(1, 3) == 1 then
			MinigameResult = "success"
		else
			MinigameResult = "lose"
			local DamageThread = coroutine.create(function()
				for i = 1, 10 do
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = {
							Amount = 10,
							DontKill = true
						}
					})

					task.wait(0.8)
				end
			end)
			
			self.Thread.Job:Task(DamageThread)
			coroutine.resume(DamageThread)
		end
	end
	
	-->> Minigame Result <<--
	self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("End"):Once(function()
		-- for boss players like invincible or meaty michael
		if VictimLuaCharacter and VictimLuaCharacter.Humanoid.Health > 99 then
			MinigameResult = "success"
		end
		
		if MinigameResult == "success" then -- Victim survives minigame
			self.Thread.Job:Task(self.Animations.Lose:GetMarkerReachedSignal("End"):Once(function()
				self:Close()
			end))
			
			self.Thread.Job:Task(self.Animations.Lose:GetMarkerReachedSignal("Hit"):Connect(function(Parameter)
				if Parameter == "Kick" then
					self.Ended = true
					
					if VictimLuaCharacter then
						VictimLuaCharacter:Anchor(false)
					end
					
					do -- Felt weird after the kick when you don't move
						if LuaCharacterStopRotate then
							LuaCharacterStopRotate:Destroy()
						end
					
						self.LuaCharacter:Anchor(false)

						local Velocity = self.Combat:Velocity()
						Velocity.Settings.FixScale = true
						Velocity.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
						Velocity.Settings.Controllable = true
						Velocity.Settings.Duration = 2.5
						Velocity.Settings.Z = 15
						Velocity:Fire()

						self.Thread.Job:Task(Velocity)
					end

					if VictimHitAnimation then
						VictimHitAnimation:Stop(0)
					end
				
					if VictimLoseAnimation then
						VictimLoseAnimation:Stop(0)
					end
				
					if GrabObject then
						GrabObject.Destroy(0)
					end
					
					if VictimCombat then
						VictimCombat:Unstun()
					end
	
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Ragdoll = 2.5,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 100 + Vector3.yAxis * 10, 0.1},
						Damage = {
							Amount = self.Config.DamageTable.Kick,
							DontKill = true
						}
					})
					
				elseif Parameter == "VictimStab" then
					self:Afflict(self.LuaPlayer, {
						ExcludeAttempts = true,
						Damage = {
							Amount = self.Config.DamageTable.VictimStab,
							DontKill = true
						}
					})
				end
			end))
			
			if VictimLuaCharacter then
				VictimLuaCharacter.Combat:CombatTag()
			end

			-- Begin
			self.Animations.Hit:Stop(0)
			self.Animations.Lose:Play(0)
			
			if VictimHitAnimation then
				VictimHitAnimation:Stop(0)
			end
			
			if VictimLoseAnimation then
				VictimLoseAnimation:Play(0)
			end
			
			self:FireReliableVFX("chara/Atonement", "Lose", self.LuaCharacter.Model, VictimLuaCharacter.Model)
		else
			local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(replicatedStorage.animations.Attacks.chara["Atonement"].WinEtc.Victim)
			
			self.Thread.OnClosed:Connect(function()
				if VictimAnimation then
					VictimAnimation:Stop()
				end

				if not GrabObject.Destroyed then
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)
			
			self.Thread.Job:Task(self.Animations.Win:GetMarkerReachedSignal("End"):Once(function()
				--local GotUnstuck = Unstuck:Unstuck(self.LuaCharacter.Model, self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -104))

				--if VictimLuaCharacter.RootPart then
				--	VictimLuaCharacter.RootPart.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -1)
				--end

				self.Animations.Win:Stop(0)
				self.Ended = true
				
				if VictimLuaCharacter then
					VictimLuaCharacter:Anchor(false)
				end
			
				if GrabObject then
					GrabObject.Destroy(0)
				end
				
				if VictimCombat then
					VictimCombat:Unstun()
				end

				if VictimAnimation then
					VictimAnimation:Stop(0)
				end

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					FinisherKill = true,
				})

				self:Close()
			end))
			
			if GrabObject then
				GrabObject.Destroy(0)
			end
			
			--self.LuaCharacter:Anchor(false)
			if VictimLuaCharacter then
				VictimLuaCharacter:Anchor(false)
			end

			-- New Grab Object
			GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -4.224) * CFrame.Angles(0, math.pi, 0))
			
			self.Animations.Hit:Stop(0)
			self.Animations.Win:Play(0)

			if VictimAnimation then
				VictimAnimation:Play(0) -- Looks weird on 0.1.
			end
			
			local TorsoCF
			self.Thread.Job:Task(self.Animations.Win:GetMarkerReachedSignal("Kill"):Once(function()
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {
						Amount = 100,
						DontKill = true
					}
				})
			end))

			self:FireReliableVFX("chara/Death Charge", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
		end		
	end))
end -- hi guys whats the meetup -- publishing uh could you gimme like 5 min

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.Config = {
		Cooldown = 30,
		DamageTable = {
			-- Windup
			Slash1 = 10,
			Slash2 = 15,
			
			-- Lose Variant
			VictimStab = 15,
			Kick = 20,
		}
	}

	self.TryToCancelMoves = true
	self.Hit = false
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack