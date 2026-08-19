local ServerScriptService = game:GetService("ServerScriptService")

----------------------------------------------------------------------------------

local Attack = {}
Attack.__index = Attack

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate() : boolean
	if not self.LuaCharacter.HumanoidAlive then
		return self:CanReawaken()
	end

	return self:BasicConditions() and not self.Combat:GetState("Blocking") 
end

function Attack:CanReawaken() : boolean
	local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

	if not self.Combat:GetState("Attacking") and not self.UsedPurple and (Matched and Ultimate.Value == 100) then
		return true
	end
	
	return false
end

function Attack:Reawakening()
	self.UsedPurple = true

	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)

	local StopAutoRotate = self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

	self.Combat.Ragdoll:ForceToggleOff()
	self.LuaCharacter:StopRespawnTimer()

	self.LuaCharacter:Anchor(true)
	self.LuaCharacter:StandUprightServer()

	self.Combat:HideUI(true)

	self.LuaPlayer.Replication.Attributes:SetAttribute("GojoReawakening", true)
	self:FireReliableVFXToSelf("Gojo/Reawakening", "Camera", self.LuaCharacter.RootPart)
	self:FireReliableVFX("Gojo/Reawakening", "Start", self.LuaCharacter.RootPart, true)
	self:FireReliableVFX("Gojo/Reverse Cursed Technique", "AddAura", self.LuaCharacter.Model)

	self.Thread.OnClosed:Once(function()
		self.LuaPlayer.Replication.Attributes:SetAttribute("GojoReawakening", nil)
		self:FireReliableVFX("Gojo/Reawakening", "Start", self.LuaCharacter.RootPart, false)
		self:FireReliableVFX("Gojo/Reawakening", "ScreenFXEnd", self.LuaCharacter.RootPart)
		self:FireReliableVFX("Gojo/Reverse Cursed Technique", "RemoveAura", self.LuaCharacter.Model)

		self.Combat:TimesSpeed(50)

		self.Combat:HideUI(false)

		self.LuaCharacter:Anchor(false)

		self.Combat.Ragdoll:Toggle(true)
		self.LuaCharacter:StartRespawnTimer()

		self.Combat:StackState("HitboxImmunity", false)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Reawaken:GetMarkerReachedSignal("getup"):Connect(function()
		self:FireReliableVFX("Gojo/Reawakening", "GetUp", self.LuaCharacter.RootPart)
		self:FireReliableVFX("Gojo/Reverse Cursed Technique", "RemoveAura", self.LuaCharacter.Model)
	end))

	self.Thread.Job:Task(self.Animations.Reawaken:GetMarkerReachedSignal("step"):Connect(function(Parameter : string)
		self:FireReliableVFX("Gojo/Reawakening", "Step", self.LuaCharacter.RootPart, Parameter)
	end))

	self.Thread.Job:Task(self.Animations.Reawaken:GetMarkerReachedSignal("hollow"):Connect(function()
		self.LuaPlayer.Replication.Attributes:SetAttribute("GojoReawakening", nil)
		self:FireReliableVFX("Gojo/Reawakening", "Hollow", self.LuaCharacter.RootPart)

		self.LuaCharacter:Anchor(false)

		if StopAutoRotate then
			StopAutoRotate:Destroy()
		end
	end))

	self.Thread.Job:Task(self.Animations.Reawaken:GetMarkerReachedSignal("purple"):Connect(function()
		self:FireReliableVFX("Gojo/Reawakening", "Purple", self.LuaCharacter.RootPart)

		local Projectile = self.Combat.Projectiles:Create("Purple", self.LuaCharacter.RootPart.Position, self.LuaCharacter.RootPart.CFrame.LookVector * 375, {
			HeightenWithGround = true,
			Height = 10,
			MaxDistance = 2000,
			DetectionSize = 15
		})

		Projectile.OnMapHit:Connect(function(Raycast : RaycastResult)
			self:FireReliableVFX("Gojo/Reawakening", "WallHit", Raycast.Position, Raycast.Normal)
			
			self.Combat.Hitbox:CreateHavocReplicated({
				parameters = {
					origin = CFrame.new(Raycast.Position),
					shape = "Sphere", 
					radius = 20,
					block_size = 5, 
				},
			})
			
			local AoeHitbox = self:CreateHitbox(true, true);
			AoeHitbox.Params.Size = 20
			AoeHitbox.Adornee = Raycast.Position
			AoeHitbox.Params.DestroyOnEndCast = false

			AoeHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local Difference : Vector3 = (VictimLuaCharacter.RootPart.Position - self.LuaCharacter.RootPart.Position)

				self:Afflict(VictimLuaPlayer, {
					DontBypassIFrames = {},
					BreakBlock = true,

					Damage = {
						Amount = 15,
						DontCountToUltimate = true
					},

					TriggerActiveCounterOverOrEqualLevel = -1,

					Ragdoll = 2,
					Velocity = {Difference.Unit * 15 + Vector3.yAxis * 25, 0.1}
				})
			end)
			
			AoeHitbox:BeginCast(0.05)
			
			Projectile:Destroy()
		end)

		Projectile.Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			self:Afflict(VictimLuaPlayer, {
				TriggerActiveCounterOverOrEqualLevel = -1,
				DontBypassIFrames = {},
				BreakBlock = true,
				Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 100 + Vector3.yAxis * 35, 0.1},
				Damage = {
					Amount = 100,
					DontCountToUltimate = true
				}
			})
		end)

		Projectile:Start()
	end))

	self.Animations.Reawaken:Play(0)
	self.Animations.Reawaken.Stopped:Wait()

	local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)
	
	if Matched then
		Ultimate:ForceSetValue(0)
	end
	
	local VelocityObject = self.Combat:Velocity()

	if (VelocityObject ~= nil) then
		VelocityObject.Settings.Velocity = -self.LuaCharacter.RootPart.CFrame.LookVector * 10
		VelocityObject.Settings.RemoveTime = 0.1
		VelocityObject:Fire()
	end
	
	self:Close()
end

function Attack:Activate()
	if not self.LuaCharacter.HumanoidAlive then
		return self:Reawakening()
	end

	self:FireReliableVFX("Gojo/Reverse Cursed Technique", "AddAura", self.LuaCharacter.Model)

	self.LuaCharacter.RegenRate = 6/100
	self.LuaCharacter:SetRegenStep(0.2)

	task.delay(7.5, function()
		self:FireReliableVFX("Gojo/Reverse Cursed Technique", "RemoveAura", self.LuaCharacter.Model)

		self.LuaCharacter.RegenRate = self.LuaCharacter.DefaultRegenRate
		self.LuaCharacter:SetRegenStep(self.LuaCharacter.DefaultRegenStep)
	end)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.DontBuffer = true
	self.BypassHumanoidAlive = true
	
	self.Job:Task(self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function()
		if not self.LuaCharacter.HumanoidAlive then
			self.UsedPurple = false
			
			self.Combat:ChangeAttackDisplay(self.Name, "One Final Move", {
				FlashColor = Color3.fromRGB(140, 0, 255),
				Tip = "[NEEDS MAX ULT]"
			})
		else
			self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, {
				Tip = ""
			})
		end
	end))

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack