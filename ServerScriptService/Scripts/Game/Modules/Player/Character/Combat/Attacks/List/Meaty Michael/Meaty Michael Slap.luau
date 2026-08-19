local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not self.VariantPhase
end

function Attack:Pretrigger()
	if self.VariantPhase or self.ForceVariant then
		self:Tung()
	end
end

function Attack:ResetTung()
	if self.VariantPhase then
		if self.TungResetter and coroutine.status(self.TungResetter) == "suspended" then
			task.cancel(self.TungResetter)
			self.TungResetter = nil
		end
		
		self:AddCooldown(17)

		self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, {
			Tip = ""
		})
		
		self.TungVictim = nil
		self.VariantPhase = false
	end
end

function Attack:Tung()
	local IsRestricted = self.Combat.IsMeatyMichaelFromWorldEvent;
	
	if not self.TungVictim then 
		local Hitbox = self:CreateHitbox(true);
		Hitbox.Adornee = self.LuaCharacter.RootPart.Position
		Hitbox.Params.Size = 100
		
		local HasHit = false;
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			if HasHit then return end;
			HasHit = true;
			
			self.TungVictim = VictimLuaPlayer;
			self:Tung();
		end);
		
		Hitbox:Detect();
	else
		self.Combat:StackState("Attacking", true)

		local TargetLuaCharacter = self.TungVictim.Character
		local Humanoid = TargetLuaCharacter.Humanoid :: Humanoid;
		local Animator = TargetLuaCharacter.Animator :: Animator;
		local RootPart = TargetLuaCharacter.RootPart :: BasePart;

		local Direction : Vector3 = (self.LuaCharacter.RootPart.Position - RootPart.Position);
		local LookVector : Vector3 = self.LuaCharacter.RootPart.CFrame.LookVector; -- Behind me if direction is zero.

		if (Direction.Magnitude > 1e-7) then
			LookVector = Direction.Unit; -- This is the direction Tung Tung Tung will be facing, towards you, you can use this for block checks if you want
		end;

		LookVector = (LookVector * Vector3.new(1, 0, 1)).Unit

		self:FireReliableVFX("Meaty Michael/TungTung", "Summon", TargetLuaCharacter.Model, LookVector, IsRestricted)

		-- Dont task this, its meant to be uncancellable. 
		task.delay(0.8, function()
			local BlastCFrame = RootPart.CFrame + LookVector * 5;

			local Hitbox = self:CreateHitbox(true, true);
			Hitbox.Adornee = BlastCFrame.Position
			Hitbox.Params.Size = 14

			Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				self:Afflict(VictimLuaPlayer, {
					Damage = 7,
					HitAngleLookVector = LookVector
				})

				VictimLuaPlayer.Replication:FireReliableVFXToSelf("Meaty Michael/TungTung", "Jumpscare", IsRestricted)
				self:FireReliableVFX("Meaty Michael/TungTung", "Attack", RootPart.RootAttachment, LookVector, IsRestricted)

				self.Combat:PushSkidVictim(VictimLuaPlayer, {
					TimeTilGroundDetection = 0.35,
					StartVelocityXZ = LookVector * 75,
					StartVelocityY = Vector3.yAxis * 150,
					StartDuration = 0.45,
					LandedRollVelocityZ = 165,
					LandedRollDuration = 0.75
				})
			end)

			Hitbox:Detect()

			task.defer(function()
				Hitbox:Destroy()
			end)

			self.Combat:StackState("Attacking", false)
		end)

		self:ResetTung()
	end
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.Hit = false
	
	local Steak = script.steak:Clone()
	Steak.Transparency = 1
	Steak.Parent = workspace.Visuals
	Steak.Weld.Part0 = self.LuaCharacter.RightArm

	self.Thread.OnClosed:Connect(function()
		if self.Hit then
			task.delay(0.75, Steak.Destroy, Steak)
		else
			Steak:Destroy()
		end
		
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -3)
	Hitbox.Params.Size = Vector3.new(10, 6, 10)

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			Damage = 7
		})

		if Validated then
			if not self.VariantPhase then
				self.VariantPhase = true
				self.TungVictim = VictimLuaPlayer
				
				self.Combat:ChangeAttackDisplay(self.Name, "Tongue Tongue", {
					Tip = "[SAHOO]",
					FlashColor = Color3.fromRGB(255, 90, 61)
				})
				
				self.TungResetter = task.delay(2, self.ResetTung, self)
			end
			
			self.Hit = true
			self:FireReliableVFX("Global/Dashing/Forward Dash", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)
			
			self.Combat:PushSkidVictim(VictimLuaPlayer, {
				TimeTilGroundDetection = 0.35,
				StartVelocityXZ = -self.LuaCharacter.RootPart.CFrame.RightVector * 50,
				StartVelocityY = Vector3.yAxis * 120,
				StartDuration = 0.53,
				LandedRollVelocityZ = 125,
				LandedRollDuration = 0.8,
			})

			self.Combat:VictimImpactGround(VictimLuaPlayer)
			self:Close()
		end
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("equip"):Once(function()
		Steak.Transparency = 0
	end))
	
	self.Animations.Windup:GetMarkerReachedSignal("slap"):Wait()
	Hitbox:BeginCast(0.05)

	task.wait(0.6)

	if not self.Hit then
		self:AddCooldown(17)
		self:Close()
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