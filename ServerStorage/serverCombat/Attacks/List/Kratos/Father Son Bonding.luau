local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ServerStorage = game:GetService("ServerStorage")

----------------------------------------------------------------------------------

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )
local Quicktime =  require( ServerStorage.serverCombat.Quicktime )
	
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

	self.Hit = false
	
	local Weapons = self.Combat.Attacks.Weapons

	if Weapons then
		Weapons:SetCurrent("Fists")
	end
	
	local SlideVelocity

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 1, -3.5)
	Hitbox.Params.Size = Vector3.new(8.5, 8, 8.5)
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 1

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self.Hit = self:Afflict(VictimLuaPlayer, {
			DontCheckBlock = true,
		})

		if self.Hit then
			if SlideVelocity then
				SlideVelocity:Destroy()
			end
			
			self.Combat:StackState("HitboxImmunity", true)
			VictimCombat:StackState("HitboxImmunity", true)
			
			VictimLuaCharacter:StopRespawnTimer()
			
			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
			local Ended = false

			self.Combat:HideUI(true)
			VictimCombat:HideUI(true)
			
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -6) * CFrame.Angles(0, math.pi, 0))
			local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(replicatedStorage.Animations.Attacks.Kratos["Father Son Bonding"].Victim)
			
			self.Thread.OnClosed:Connect(function()
				if VictimAnimation then
					VictimAnimation:Stop()
				end
				
				VictimLuaCharacter:RestartRespawnTimer()
				
				GrabObject.Destroy(0)
				VictimCombat:Unstun()
				
				self.Combat:HideUI(false)
				VictimCombat:HideUI(false)

				self.Combat:StackState("HitboxImmunity", false)
				VictimCombat:StackState("HitboxImmunity", false)
			end)
			
			local QTETime = 0.485
			local QTEPrecision = 0.1
			local QTEAmount = 3
			
			local QTESeed = Random.new()
			local QTEKeys = {Enum.KeyCode.E, Enum.KeyCode.R}--, Enum.KeyCode.Z, Enum.KeyCode.X}
			local ControllerQTEKeys = {Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonX}--, Enum.KeyCode.Z, Enum.KeyCode.X}
			
			local MaxDamage = 85
			local MinDamage = 40
			
			local FinalDamage = MinDamage
			
			local function IncrementDamage(Up : boolean)
				if Up then
					FinalDamage = math.clamp(FinalDamage + ((MaxDamage - MinDamage) / QTEAmount), MinDamage, MaxDamage)
				else
					FinalDamage = math.clamp(FinalDamage - ((MaxDamage - MinDamage) / QTEAmount), MinDamage, MaxDamage)
				end
			end

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("qte"):Connect(function()
				if self.LuaPlayer:PlayerExists() and not self.LuaPlayer.IsNPC then
					local Key = QTEKeys[QTESeed:NextInteger(1, #QTEKeys)]
					local ControllerKey = ControllerQTEKeys[QTESeed:NextInteger(1, #ControllerQTEKeys)]
					
					local AttackerQTE = Quicktime.new(self.LuaPlayer.Player, Key, ControllerKey, NumberRange.new(QTETime, QTETime + QTEPrecision))

					AttackerQTE.OnUpdate:Connect(function(Value : boolean)
						if Value then
							IncrementDamage(true)
							print("attacker qte", FinalDamage)
						end
					end)
				end
				
				if VictimLuaPlayer:PlayerExists() and not VictimLuaPlayer.IsNPC then
					local Key = QTEKeys[QTESeed:NextInteger(1, #QTEKeys)]
					local ControllerKey = ControllerQTEKeys[QTESeed:NextInteger(1, #ControllerQTEKeys)]
					
					local VictimQTE = Quicktime.new(VictimLuaPlayer.Player, Key, ControllerKey, NumberRange.new(QTETime, QTETime + QTEPrecision))

					VictimQTE.OnUpdate:Connect(function(Value : boolean)
						if Value then
							IncrementDamage(false)
							print("victim qte", FinalDamage)
						end
					end)
				end
				
				-- changes damage depending on if victim or attacker successfully do qte or not
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("final"):Connect(function()
				GrabObject.Destroy(0)
				
				if VictimAnimation then
					VictimAnimation:Stop(0)
				end
				
				--do
				--	local VictimEndOffset = -28.012
					
				--	local Root : BasePart = self.LuaCharacter.RootPart
				--	local Raycast = workspace:Raycast(Root.Position, Root.CFrame.LookVector * -VictimEndOffset, Utility.VisualParams)

				--	if (Raycast ~= nil) then
				--		VictimLuaCharacter.Model:PivotTo(Root.CFrame * CFrame.Angles(math.rad(90), math.pi, 0) * CFrame.new(0, 0, Raycast.Distance)) 
				--	else
				--		VictimLuaCharacter.Model:PivotTo(Root.CFrame * CFrame.Angles(math.rad(90), math.pi, 0) * CFrame.new(0, 0, -VictimEndOffset))
				--	end
				--end
				
				if VictimLuaCharacter.RootPart then
					VictimLuaCharacter.RootPart.CFrame *= CFrame.new(0, 0, 6)
				end

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = FinalDamage,
					Ragdoll = 3;
				})

				--VictimCombat.Ragdoll:Toggle(true, 3)
				VictimCombat:Unstun()

				--VictimLuaCharacter.RootPart.AssemblyLinearVelocity = Vector3.zero
				--VictimLuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.zero

				--task.spawn(function()
				--	for Index = 1, 40 do
				--		if VictimAnimation then
				--			VictimAnimation:Stop(0)
				--		end
						
				--		VictimLuaCharacter.RootPart.AssemblyLinearVelocity = Vector3.zero
				--		VictimLuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.zero

				--		task.wait(0.02)
				--	end
				--end)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("end"):Once(function()
				self.Animations.HitEndPose:Play(0)
				self:Close()
			end))
			
			self.Animations.Windup:Stop(0)
			self.Animations.Hit:Play(0)
			
			if VictimAnimation then
				VictimAnimation:Play(0)
			end

			local Friend = self.LuaPlayer:GetRandomFriend(true);
			
			self:FireReliableVFX("Kratos/Father Son Bonding", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model, Friend)
		end
	end)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(20)

		self.Combat:TimesSpeed(100)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("forward"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1.5
		VelocityObject.Settings.RemoveTime = 1.4
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 12
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		SlideVelocity = self.Combat:Velocity()
		SlideVelocity.Settings.Duration = 1.3
		SlideVelocity.Settings.RemoveTime = SlideVelocity.Settings.Duration
		SlideVelocity.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		SlideVelocity.Settings.Controllable = true
		SlideVelocity.Settings.Z = 14
		SlideVelocity:Fire()

		self.Thread.Job:Task(SlideVelocity)
		
		Hitbox:BeginCast(0.1)
		
		task.wait(0.95)
		
		if not self.Hit then
			self.Animations.Windup:Stop(0.4)
			
			task.wait(0.25)
			
			self:Close()
		end
	end))
	
	--self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Once(function()
	--	if not self.Hit then
	--		self:Close()
	--	end
	--end))
	
	self:FireReliableVFX("Kratos/Father Son Bonding", "Startup", self.LuaCharacter.Model)
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