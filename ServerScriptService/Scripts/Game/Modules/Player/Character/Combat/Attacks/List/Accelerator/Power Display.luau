local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local UIRemotes = Remotes.Combat.UI

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

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
	
	local SFX : Sound = self.Thread.CancelJob:Task(self:CreateMoveSFX("Accelerator", "Power Display"))

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.MaxTargets = 1
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat
		
		local Validated = self:Afflict(VictimLuaPlayer, {
			DontHitDeadPeople = true,
			BreakBlock = true
		})

		if Validated then
			self.Hit = true
			
			if SFX then
				SFX:Destroy()
			end
			
			VictimCombat:StackState("HitboxImmunity", true)
			
			self:FireReliableVFX("Accelerator/Power Display", "Unvanish", self.LuaCharacter.Torso)
			self:FireReliableVFX("Accelerator/Power Display", "Hit", self.LuaCharacter.Torso, VictimLuaCharacter.Torso)
			
			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

			local Magnitude = (VictimLuaCharacter.RootPart.Position - self.LuaCharacter.RootPart.Position).Magnitude
			self.LuaCharacter.RootPart.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -(Magnitude / 1.05))

			self.LuaCharacter:Anchor(true)
			VictimLuaCharacter:Anchor(true)

			local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

			if Matched then
				Ultimate:SetBarPausing(true)

				self.Thread.OnClosed:Connect(function()
					Ultimate:SetBarPausing(false)
				end)
			end

			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0.6, 0, -7.8) * CFrame.Angles(0, math.pi, 0))
			
			self.Thread.OnClosed:Connect(function()
				self.LuaCharacter:Anchor(false)
				VictimLuaCharacter:Anchor(false)

				GrabObject.Destroy(0)
				VictimCombat:Unstun()
			end)
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("barrier"):Connect(function()
				self:FireReliableVFX("Accelerator/Power Display", "Barrier", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("pushaway"):Connect(function()
				self:FireReliableVFX("Accelerator/Power Display", "Pushaway", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("teleporting"):Connect(function()
				self:FireReliableVFX("Accelerator/Power Display", "Teleport", self.LuaCharacter.Torso)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("grab"):Connect(function()
				self:FireReliableVFX("Accelerator/Power Display", "Grab", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("slam"):Connect(function()
				self:FireReliableVFX("Accelerator/Power Display", "GrabSlam", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("kick1"):Connect(function()
				self:FireReliableVFX("Accelerator/Power Display", "Kick1", self.LuaCharacter.RootPart)
				
				self:FireReliableVFXToSelf("Accelerator/Power Display", "ImpactFrames")
				VictimLuaPlayer.Replication:FireReliableVFXToSelf("Accelerator/Power Display", "ImpactFrames")
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("kick2"):Connect(function()
				self:FireReliableVFX("Accelerator/Power Display", "Kick2", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("kickhead"):Connect(function()
				self:FireReliableVFX("Accelerator/Power Display", "KickHead", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("kickheadresume"):Connect(function()
				self:FireReliableVFX("Accelerator/Power Display", "KickHeadResume", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("crack"):Connect(function(Type : string)
				self:FireReliableVFX("Accelerator/Power Display", "Crack", self.LuaCharacter.RootPart, tonumber(Type))
			end))

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("splat"):Connect(function()
				self:FireReliableVFX("Accelerator/Power Display", "Splat", self.LuaCharacter.RootPart)
				
				task.wait(0.05) -- emit dealy until splat
				
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 60,
					Ragdoll = 3.5,
					Velocity = {self.LuaCharacter.RootPart.CFrame.RightVector * 25 + self.LuaCharacter.RootPart.CFrame.LookVector * 25, 0.1}
				})
				
				self:Close()
			end))
			
			self.Animations.Windup:Stop(0) 
			self.Animations.Hit:Play(0)
			VictimCombat.Animations.GrabVictims.PowerDisplay:Play(0)

			self.Combat:HideUI(true)
			VictimCombat:HideUI(true)

			self.LuaPlayer.Replication.Attributes:SetAttribute("PowerDisplayCamera", true)
			self:FireReliableVFXToSelf("Accelerator/Power Display", "Camera", self.LuaCharacter.RootPart)

			VictimLuaPlayer.Replication.Attributes:SetAttribute("PowerDisplayCamera", true)
			VictimLuaPlayer.Replication:FireReliableVFXToSelf("Accelerator/Power Display", "Camera", self.LuaCharacter.RootPart)

			self.Thread.OnClosed:Connect(function()
				VictimCombat.Animations.GrabVictims.PowerDisplay:Stop(0)
				VictimCombat:StackState("HitboxImmunity", false)
				
				self.Combat:HideUI(false)
				VictimCombat:HideUI(false)
				
				self.LuaPlayer.Replication.Attributes:SetAttribute("PowerDisplayCamera", nil)
				VictimLuaPlayer.Replication.Attributes:SetAttribute("PowerDisplayCamera", nil)
			end)
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Hit and 40 or 17.5)
		
		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Animations.Windup:GetMarkerReachedSignal("vanishing"):Wait()

	self.Combat:StackState("HitboxImmunity", true)
	self:FireReliableVFX("Accelerator/Power Display", "Vanishing", self.LuaCharacter.Torso)
	
	self.Thread.OnClosed:Connect(function()
		self:FireReliableVFX("Accelerator/Power Display", "Unvanish", self.LuaCharacter.Torso)
		self.Combat:StackState("HitboxImmunity", false)
	end)

	self.Animations.Windup:GetMarkerReachedSignal("teleport"):Wait()

	self:FireReliableVFX("Accelerator/Power Display", "Dash", self.LuaCharacter.RootPart, self.LuaCharacter.RootPart.CFrame)
	
	local StartingY = self.LuaCharacter.RootPart.Position.Y
	
	self.Combat:TeleportForward(75, function(DistanceCovered : number, CF : CFrame, HitboxAdjust : number)
		local ExtraDistance = 2.5
		DistanceCovered += ExtraDistance

		Hitbox.Params.Offset = CFrame.new(0, HitboxAdjust / 2, -(DistanceCovered / 2))
		Hitbox.Params.Size = Vector3.new(8, HitboxAdjust + 8.5, DistanceCovered)
		Hitbox:Detect()

		if not self.Hit then
			self.Combat.Hitbox:Destruction(Hitbox.Params.Offset, Hitbox.Params.Size, 4)
			self.LuaCharacter.Model:PivotTo(CF)
		end
	end)
	
	if not self.Hit then
		self.Animations.Windup:GetMarkerReachedSignal("unvanish"):Wait()

		self:FireReliableVFX("Accelerator/Power Display", "Unvanishing", self.LuaCharacter.Torso)

		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 0.865
		VelocityObject.Settings.RemoveTime = 0.865
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 87.5
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)

		self.Animations.Windup:GetMarkerReachedSignal("slam"):Wait()

		self:FireReliableVFX("Accelerator/Power Display", "Slam", self.LuaCharacter.RootPart)

		local Hitbox = self:CreateHitbox(false);
		Hitbox.Params.Offset = CFrame.new(0, 0, -2)
		Hitbox.Params.Size = Vector3.new(30, 12, 30)
		Hitbox.Params.DestroyOnEndCast = false

		local Rnd = Random.new();
		
		self.Combat.Hitbox:CreateHavocReplicated({
			parameters = {
				origin = Hitbox:GetCFrame(),
				shape = "Sphere", 
				radius = 14,
				block_size = 7,
			},
			debris = {
				scale = 0.9,
				radius = 18,
				velocity = function(part)
					return Rnd:NextUnitVector() * 35 + Vector3.yAxis * 60;
				end,
			},
		});
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				BreakBlock = true,
				Damage = 12.5,
				Ragdoll = 1.5,
				Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 9 + Vector3.yAxis * 45, 0.1}
			})

			if Validated then
				VictimLuaCharacter.RootPart:ApplyAngularImpulse(Vector3.new(Utility.Seed:NextNumber(-100, 100), Utility.Seed:NextNumber(-100, 100), Utility.Seed:NextNumber(-100, 100)))
			end
		end)

		Hitbox:Detect()
		
		task.wait(0.85)

		if not self.Hit then
			self.Animations.Windup:Stop(0.3)
			self:Close()
		end
	end
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