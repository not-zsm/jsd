

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Modules.Player.Character.Combat.Attacks.BaseAttack )
local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Pretrigger()
	
end

--function Attack:Activate()
--	self.Combat:StackState("Attacking", true)
--	self.Combat:DivideSpeed(100)

--	self.Success = false

--	self.Thread.OnClosed:Connect(function()
--		self:AddCooldown(45)

--		self.Combat:RemoveActiveCounter()

--		self.Combat:TimesSpeed(100)
--		self.Combat:StackState("Attacking", false)
--	end)
	
--	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("counter"):Connect(function(Parameter : string)
--		if (Parameter == "true") then 
--			self.Animations.Windup:AdjustSpeed(1)
			
--			self.Combat:CreateCounter(2, function(VictimLuaPlayer)
--				self.Success = true

--				local VictimLuaCharacter = VictimLuaPlayer.Character
--				local VictimCombat = VictimLuaCharacter.Combat

--				self.Combat:StackState("HitboxImmunity", true)
--				VictimCombat:StackState("HitboxImmunity", true)
--				VictimCombat:TrueStun()

--				self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

--				local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

--				if Matched then
--					self.LuaPlayer.Replication.Attributes:SetAttribute("Ultimate_Mute", true)
--					Ultimate:SetBarPausing(true)

--					self.Thread.OnClosed:Connect(function()
--						self.LuaPlayer.Replication.Attributes:SetAttribute("Ultimate_Mute", nil)
--						Ultimate:SetBarPausing(false)
--					end)
--				end
				
--				self.Combat:HideUI(true)
--				VictimCombat:HideUI(true)

--				self:FireReliableVFXToSelf("Chara/Reset", "Counter", self.LuaCharacter.Model)
--				VictimLuaPlayer.Replication:FireReliableVFXToSelf("Chara/Reset", "Counter", self.LuaCharacter.Model)

--				self.Thread.OnClosed:Connect(function()
--					self.Combat:HideUI(false)
--					VictimCombat:HideUI(false)
					
--					self.Combat:StackState("HitboxImmunity", false)
--					VictimCombat:StackState("HitboxImmunity", false)
					
--					VictimCombat:Unstun()
--				end)

--				local Position : Vector3 = self.Combat:GetSimulatedRoot().Position
--				local Velocity : Vector3 = (VictimLuaCharacter.RootPart.Position - Position).Unit * 50 + Vector3.yAxis * 175

--				local Hitbox = self:CreateHitbox(true, true);
--				Hitbox.Adornee = Position
--				Hitbox.Params.MaxTargets = -1
--				Hitbox.Params.Ignore = {self.LuaCharacter.Model, VictimLuaPlayer.Character.Model}
--				Hitbox.Params.Offset = CFrame.identity
--				Hitbox.Params.Size = 100
				
--				Hitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
--					self:Afflict(NewVictimLuaPlayer, {
--						TriggerActiveCounterOverOrEqualLevel = -1,
--						Damage = 50,
--						Ragdoll = 3,
--						DontCheckBlock = true,
--						DontBypassIFrames = {},
--						Velocity = {Velocity, 0.25}
--					})
--				end)

--				--self.Thread.Job:Task(task.delay(710, function()
--				--	self:FireReliableVFX("Chara/Reset", "MiniExplosion", Position)
--				--end))

--				task.wait(780 / 60)

--				Hitbox:Detect()
--				task.defer(Hitbox.Destroy, Hitbox)
				
--				self:FireReliableVFX("Chara/Reset", "Explosion", Position)
	
--				self.Combat.Hitbox:CreateHavocReplicated({
--					parameters = {
--						origin = CFrame.new(Position),
--						shape = "Sphere", 
--						radius = Hitbox.Params.Size,
--						block_size = Hitbox.Params.Size / 3, 
--					},
--				})
				
--				local Self_Damage = 50
--				local No_Death = 10
				
--				local NewHealth = (self.LuaCharacter.Humanoid.Health - Self_Damage)
				
--				if (NewHealth < No_Death) then
--					self.LuaCharacter.Humanoid.Health = No_Death
--				else
--					self.LuaCharacter.Humanoid:TakeDamage(Self_Damage)
--				end
				
--				VictimLuaCharacter.Humanoid:TakeDamage(100)
				
--				self.Combat.Ragdoll:Toggle(true, 3)
--				VictimCombat.Ragdoll:Toggle(true, 3)
				
--				local VelocityObject = self.Combat:Velocity()
--				VelocityObject.Settings.Velocity = Velocity
--				VelocityObject.Settings.RemoveTime = 0.25
--				VelocityObject:Fire()

--				self:Close()
--			end)
--		else
--			self.Combat:RemoveActiveCounter()
--		end
--	end))
	
--	self.Thread.Job:Task(self.Animations.Windup.Stopped:Once(function()
--		if not self.Success then
--			self:Close()
--		end
--	end))
	
--	self:FireReliableVFX("Chara/Reset", "Start", self.LuaCharacter.Model)
--end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(100)

	self.Success = false

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(45)

		self.Combat:RemoveActiveCounter()

		self.Combat:TimesSpeed(100)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Combat:CreateCounter(2, function(VictimLuaPlayer)
		self.Success = true

		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self.Combat:StackState("HitboxImmunity", true)
		VictimCombat:StackState("HitboxImmunity", true)
		VictimCombat:TrueStun()

		self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

		local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

		if Matched then
			self.LuaPlayer.Replication.Attributes:SetAttribute("Ultimate_Mute", true)
			Ultimate:SetBarPausing(true)

			self.Thread.OnClosed:Connect(function()
				self.LuaPlayer.Replication.Attributes:SetAttribute("Ultimate_Mute", nil)
				Ultimate:SetBarPausing(false)
			end)
		end

		self.Combat:HideUI(true)
		VictimCombat:HideUI(true)

		self:FireReliableVFXToSelf("Chara/Reset", "Counter", self.LuaCharacter.Model)
		VictimLuaPlayer.Replication:FireReliableVFXToSelf("Chara/Reset", "Counter", self.LuaCharacter.Model)

		self.Thread.OnClosed:Connect(function()
			self.Combat:HideUI(false)
			VictimCombat:HideUI(false)

			self.Combat:StackState("HitboxImmunity", false)
			VictimCombat:StackState("HitboxImmunity", false)

			VictimCombat:Unstun()
		end)

		local Position : Vector3 = self.Combat:GetSimulatedRoot().Position
		local Velocity : Vector3 = (VictimLuaCharacter.RootPart.Position - Position).Unit * 50 + Vector3.yAxis * 175

		local Hitbox = self:CreateHitbox(true, true);
		Hitbox.Adornee = Position
		Hitbox.Params.MaxTargets = -1
		Hitbox.Params.Ignore = {self.LuaCharacter.Model, VictimLuaPlayer.Character.Model}
		Hitbox.Params.Offset = CFrame.identity
		Hitbox.Params.Size = 100

		Hitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
			self:Afflict(NewVictimLuaPlayer, {
				TriggerActiveCounterOverOrEqualLevel = -1,
				Damage = 50,
				Ragdoll = 3,
				DontCheckBlock = true,
				DontBypassIFrames = {},
				Velocity = {Velocity, 0.25}
			})
		end)

		--self.Thread.Job:Task(task.delay(710, function()
		--	self:FireReliableVFX("Chara/Reset", "MiniExplosion", Position)
		--end))

		task.wait(780 / 60)

		Hitbox:Detect()
		task.defer(Hitbox.Destroy, Hitbox)

		self:FireReliableVFX("Chara/Reset", "Explosion", Position)

		self.Combat.Hitbox:CreateHavocReplicated({
			parameters = {
				origin = CFrame.new(Position),
				shape = "Sphere", 
				radius = Hitbox.Params.Size,
				block_size = Hitbox.Params.Size / 3, 
			},
		})

		local Self_Damage = 20
		local No_Death = 10

		local NewHealth = (self.LuaCharacter.Humanoid.Health - Self_Damage)

		if (NewHealth < No_Death) then
			self.LuaCharacter.Humanoid.Health = No_Death
		else
			self.LuaCharacter.Humanoid:TakeDamage(Self_Damage)
		end

		VictimLuaCharacter.Humanoid:TakeDamage(55)

		self.Combat.Ragdoll:Toggle(true, 3)
		VictimCombat.Ragdoll:Toggle(true, 3)

		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Velocity = Velocity
		VelocityObject.Settings.RemoveTime = 0.25
		VelocityObject:Fire()
		
		local VictimVelocityObject = VictimCombat:Velocity()
		VictimVelocityObject.Settings.Velocity = Utility.Seed:NextUnitVector() * 50 + Vector3.yAxis * 175
		VictimVelocityObject.Settings.RemoveTime = 0.25
		VictimVelocityObject:Fire()

		self:Close()
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("counter"):Connect(function(Parameter : string)
		if (Parameter == "false") then 
			self.Combat:RemoveActiveCounter()
		end
	end))

	self.Thread.Job:Task(self.Animations.Windup.Stopped:Once(function()
		if not self.Success then
			self:Close()
		end
	end))

	self:FireReliableVFX("Chara/Reset", "Start", self.LuaCharacter.Model)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	--self.AnimationSettings = {Speed = 3}
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack