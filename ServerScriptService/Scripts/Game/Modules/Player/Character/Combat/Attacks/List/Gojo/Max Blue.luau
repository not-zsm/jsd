local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage.Remotes
local UIRemotes = Remotes.Combat.UI

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
	self.Combat:DivideSpeed(7)
	
	self.Hit = false

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -4)
	Hitbox.Params.Size = Vector3.new(7, 7, 7)
	Hitbox.Params.MaxTargets = 1
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
		})

		if Validated then
			self.Hit = true
			
			VictimCombat:StackState("HitboxImmunity", true)
			self.Combat:StackState("HitboxImmunity", true)
			
			self.Animations.Windup:Stop(); self.Animations.Windup:Destroy()
			self.Animations.Hit:Play()
			VictimCombat.Animations.GrabVictims.MaxBlue:Play()
			
			local StopAutoRotate = Utility.StopAutoRotate(self.LuaCharacter.Humanoid)
			
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -8) * CFrame.Angles(0, math.pi, 0))
			local Ended = false
			
			self.Thread.CancelJob:Task(self:CreateMoveSFX("Gojo", "Max Blue", "HitSFX"))
			self:FireReliableVFX("Gojo/Max Blue", "HitStart", self.LuaCharacter.RootPart, VictimLuaCharacter.Torso)

			self.Thread.OnClosed:Connect(function()
				VictimCombat:StackState("HitboxImmunity", false)
				self.Combat:StackState("HitboxImmunity", false)
				
				local Purple, Matched = self.Combat:MatchAttack("Maximum Output - Purple", Enum.KeyCode.Five)

				if Matched then
					if Purple.CompletedStep1 and Purple.HitRed then
						Purple:CompleteStep2()
					else
						Purple.HitBlue = true
						Purple:CompleteStep1()
					end
				end
				
				if not Ended then
					self.Animations.Hit:Stop()
					StopAutoRotate:Destroy()
					
					VictimCombat.Animations.GrabVictims.MaxBlue:Stop()
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				else
					self.Animations.Hit:Stop(0.3)
				end
			end)
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("spin"):Once(function()
				self:FireReliableVFX("Gojo/Max Blue", "HitSpin", self.LuaCharacter.Torso)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("slam"):Once(function()
				self:FireReliableVFX("Gojo/Max Blue", "HitSlam", VictimLuaCharacter.Torso)
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {
						DontKill = true,
						Amount = 5
					}
				})
				
				local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, 3), Vector3.one * 9)

				AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					local NewVictimLuaCharacter = NewVictimLuaPlayer.Character

					local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
						Damage = 1.5,
						Ragdoll = 3,
						Velocity = {Vector3.yAxis * 40, 0.1}
					})
				end)

				AOEHitbox:BeginCast(0.05)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("leg"):Once(function()
				self:FireReliableVFX("Gojo/Max Blue", "HitLeg", self.LuaCharacter.LeftLeg)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("kick"):Once(function()
				self:FireReliableVFX("Gojo/Max Blue", "HitKick", VictimLuaCharacter.Torso)
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {
						DontKill = true,
						Amount = 15
					}
				})
				
				local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.new(0, 0, 3), Vector3.one * 14)

				AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
					local NewVictimLuaCharacter = NewVictimLuaPlayer.Character

					local Validated = self.Combat:Afflict(NewVictimLuaPlayer, {
						Damage = 5,
						Ragdoll = 2,
						Velocity = {Vector3.yAxis * 55, 0.1}
					})
				end)

				AOEHitbox:BeginCast(0.05)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("pull"):Once(function()
				Ended = true
				
				GrabObject.Destroy(1)
				
				VictimCombat.Animations.GrabVictims.MaxBlue:Stop(0)
				VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, 10))
				VictimCombat:StackState("HitboxImmunity", false)

				local Hitbox = self:BlueOrb(true)
				Hitbox:HitHumanoid(VictimLuaCharacter.Humanoid)
				
				task.delay(0.3, function()
					VictimCombat:Unstun()
				end)
				
				task.wait(2.5)
			
				self:Close()
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("throw"):Once(function()
				StopAutoRotate:Destroy()
			end))
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(17)
		
		self.Combat:TimesSpeed(7)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.CancelJob:Task(self:CreateMoveSFX("Gojo", "Max Blue", "StartSFX"))
	
	self.Animations.Windup:GetMarkerReachedSignal("charge"):Wait()
	
	self:FireReliableVFX("Gojo/Max Blue", "WindupCharge", self.LuaCharacter.RootPart)
	
	self.Animations.Windup:GetMarkerReachedSignal("swing"):Wait()

	self:FireReliableVFX("Gojo/Max Blue", "WindupSwing", self.LuaCharacter.RootPart)
	
	self.Animations.Windup:GetMarkerReachedSignal("hit"):Wait()

	self.Animations.Windup:AdjustSpeed(1)
	
	self.Thread.Job:Task(task.delay(0.4, function()
		self.Thread.CancelJob:Task(self:CreateMoveSFX("Gojo", "Max Blue", "SpinSFX"))
	end))
	
	self:FireReliableVFX("Gojo/Max Blue", "WindupHit", self.LuaCharacter.RootPart)

	Hitbox:BeginCast()
	
	task.wait(0.15)
	
	Hitbox:EndCast()
	
	if not self.Hit then
		self.Combat:StackState("HitboxImmunity", true)

		self.Thread.OnClosed:Connect(function()
			self.Combat:StackState("HitboxImmunity", false)
		end)

		self.Animations.Windup:GetMarkerReachedSignal("spin1"):Wait()

		self:FireReliableVFX("Gojo/Max Blue", "WindupSpin", self.LuaCharacter.RootPart)

		self.Animations.Windup:GetMarkerReachedSignal("spin2"):Wait()

		self:BlueOrb()
		self.Animations.Windup:AdjustSpeed(0.6)

		task.wait(1.5)
		
		self.Combat:StackState("GrabIFrames", true)

		task.delay(0.35, function()
			self.Combat:StackState("GrabIFrames", false)
		end)
		
		self:Close()
	end
end

function Attack:BlueOrb(Grabbed : boolean)
	local ArmChosenCFrame = CFrame.new(5, -30, 0)
	local CF = (self.LuaCharacter.RightArm.CFrame * ArmChosenCFrame)
	
	local Hitbox = self:CreateHitbox(true);
	Hitbox.Adornee = (CF * ArmChosenCFrame).Position
	Hitbox.Params.Size = 27.5
	Hitbox.Params.DestroyOnEndCast = false

	local Hit = {}
	
	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontBypassIFrames = {},
			BreakBlock = true,
		})

		if Validated and not Hit[VictimLuaPlayer] then
			VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")
			VictimCombat.Ragdoll:SetCollisionGroupOfColliders("NoPlayerCollision")

			VictimCombat:StackState("CannotDash", true)
			
			self:Afflict(VictimLuaPlayer, {
				ExcludeAttempts = true;
				Ragdoll = 3;
			})
			--VictimCombat.Ragdoll:Toggle(true, 3)
			
			self:FireReliableVFX("Gojo/Max Blue", "Pulled", VictimLuaCharacter.Torso)
			
			local HitsThread = coroutine.create(function()
				while VictimLuaCharacter.HumanoidAlive do
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = 0.75,
					})
					
					task.wait(0.1)
				end
			end)
			
			coroutine.resume(HitsThread)
			
			self.Thread.OnClosed:Connect(function()
				if coroutine.status(HitsThread) == "suspended" then
					task.cancel(HitsThread)
				end; HitsThread = nil
			end)
			
			Hit[VictimLuaPlayer] = true
		end
	end)

	self.Thread.OnClosed:Connect(function()
		for _, Attachment in self.MaxBlueAttachments do
			Attachment:Destroy()
		end
		
		table.clear(self.MaxBlueAttachments)
		
		for Victim in Hit do
			Victim.Character.Combat:StackState("CannotDash", false)
			
			if Victim.Character.HumanoidExists then
				Victim.Character.Combat.Ragdoll:Toggle(true, 2)
		
				if not Victim.Character.Combat:GetState("Grabbed") then
					Victim.Character:SetCollisionGroup("Player")
				end

				Victim.Character.Combat.Ragdoll:SetCollisionGroupOfColliders("Default")
			end
		end
		
		table.clear(Hit)
	end)
	
	local Last = os.clock()

	self.Thread.Job:Task(RunService.PostSimulation:Connect(function()
		local CF = (self.LuaCharacter.RightArm.CFrame * ArmChosenCFrame)
		local Raycast = workspace:Raycast(Hitbox.Adornee + (Vector3.yAxis * 4), Vector3.yAxis * -25, Utility.VisualParams)
		
		if Raycast then
			Hitbox.Adornee = CFrame.new(CF.X, Raycast.Position.Y + 10, CF.Z).Position
		else
			Hitbox.Adornee = (CF * ArmChosenCFrame).Position
		end
		
		local AdorneeCF = CFrame.new(Hitbox.Adornee)
		
		for Victim in Hit do
			local Model = Victim.Character.Model
			
			if (not Victim.Character.HumanoidExists or Model == nil) then
				self.MaxBlueAttachments[Model] = nil
			else
				if self.MaxBlueAttachments[Model] then
					self.MaxBlueAttachments[Model].CFrame = AdorneeCF
				else
					local Attachment = Instance.new("Attachment")
					Attachment.WorldCFrame = AdorneeCF
					Attachment.Parent = workspace.Terrain

					local AlignPosition = Instance.new("AlignPosition")
					AlignPosition.Responsiveness = 144
					AlignPosition.MaxForce = 10000
					AlignPosition.MaxVelocity = 150
					AlignPosition.Attachment0 = Victim.Character.RootPart.RootAttachment
					AlignPosition.Attachment1 = Attachment
					AlignPosition.Parent = Attachment

					self.MaxBlueAttachments[Model] = Attachment
				end
			end
		end
		
		if os.clock() - Last > 0.1 then	
			Last = os.clock()
			
			self.Combat.Hitbox:CreateHavocReplicated({
				parameters = {
					origin = AdorneeCF,
					shape = "Sphere", 
					radius = 15,
					block_size = 5, 
				},
			})
			
			task.spawn(self.Combat.Hitbox.SphereDestruction, self.Combat.Hitbox, Hitbox.Adornee, Hitbox.Params.Size, 15, nil, "None")
		end
	end))

	local Time = (Grabbed and 2.5 or 1.5)
	
	self:FireReliableVFX("Gojo/Max Blue", "Ball", self.LuaCharacter.Torso, self.LuaCharacter.RightArm, Time)
	Hitbox:BeginCast()
	
	return Hitbox
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	
	self.AnimationSettings = {
		Speed = 1.35
	}
	
	self.MaxBlueAttachments = {}
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack