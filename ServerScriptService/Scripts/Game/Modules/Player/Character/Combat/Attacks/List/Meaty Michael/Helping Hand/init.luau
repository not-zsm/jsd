local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )
local SteakOrder = require( ReplicatedStorage.Modules.Player.Replication.VFX["Meaty Michael"]["Steak Order"] )

local MichaelEnemy = require( script.MichaelEnemy )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not self.Riding and not self.RideCooldown
end

function Attack:Pretrigger()
	if self.Riding then
		self.OnWantToUnride:Fire()
	end
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	if (self.VariantsEnabled and (self.HoldingJump or self.Freefalling)) or self.ForceVariant then
		local Steak = script.HeedMyCallKey:Clone();
		Steak.Name = "Steak"
		Steak.SteakJoint.Part0 = self.LuaCharacter.LeftArm;
		Steak.Transparency = 1;
		Steak.Parent = self.LuaCharacter.Model;

		self.Thread.OnClosed:Connect(function()
			Steak.Transparency = 1;
			
			task.delay(3, function()
				Steak:Destroy();
			end);
			
			self:AddCooldown(35)
			
			self.Combat:TimesSpeed(10)
			self.Combat:StackState("Attacking", false)
		end)

		self.Thread.Job:Task(self.Animations.HeedMyCall:GetMarkerReachedSignal("Land"):Once(function()
			self.Animations.HeedMyCall:AdjustSpeed(1.1);
		end))

		self.Thread.Job:Task(self.Animations.HeedMyCall:GetMarkerReachedSignal("Jump"):Once(function()
			Steak.Transparency = 0;
			task.wait(0.05);
			self.Animations.HeedMyCall:AdjustSpeed(0.75);
			self:FireReliableVFX("Meaty Michael/Heed My Call", "Jump", self.LuaCharacter.RootPart);
		end));

		self.Thread.Job:Task(self.Animations.HeedMyCall:GetMarkerReachedSignal("Spin"):Once(function()
			self:FireReliableVFX("Meaty Michael/Heed My Call", "Beep", Steak);
		end))

		self.Thread.Job:Task(self.Animations.HeedMyCall:GetMarkerReachedSignal("Catch"):Once(function()
			self:FireReliableVFX("Meaty Michael/Heed My Call", "Catch", self.LuaCharacter.RootPart.RootAttachment);
			self.Animations.HeedMyCall:AdjustSpeed(0.75);
		end))

		self.Thread.Job:Task(self.Animations.HeedMyCall:GetMarkerReachedSignal("Pose"):Once(function()
			local Origin = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 22.5, 15)

			self:FireReliableVFX("Meaty Michael/Heed My Call", "Summoning", Origin, Steak);
			self.Animations.HeedMyCall:AdjustSpeed(0.75);
			
			local ZoneHitbox = self:CreateHitbox(true, true);
			ZoneHitbox.Params.Offset = CFrame.identity
			ZoneHitbox.Params.Size = 55;
			ZoneHitbox.Adornee = Steak;
			ZoneHitbox.Params.DestroyOnEndCast = true;
			
			ZoneHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character;

				task.delay(0.5, function()
					ZoneHitbox:RemoveHumanoid(VictimLuaCharacter.Humanoid);
				end);
				
				local Validated = self:Afflict(VictimLuaPlayer, {
					Damage = 1,
					BreakBlock = true,
					Ragdoll = 1.25,
					Velocity = {((VictimLuaCharacter.RootPart.Position - Origin.Position) * Vector3.new(1, 0, 1)).Unit * 65 + Vector3.yAxis * 25, 0.15}
				});
			end);
			
			ZoneHitbox:BeginCast();
			
			task.delay(2, function()
				ZoneHitbox:EndCast();
				ZoneHitbox:Destroy();
			end);
			
			for count = 1, math.random(4, 6) do
				local whip = MichaelEnemy.new(self, Origin * CFrame.new(math.random(-60, 60), math.random(-10, 25), math.random(-60, 60)));
				
				task.delay(5 / 60, function()
					self:FireReliableVFX("Meaty Michael/Heed My Call", "SummoningLink", Origin, whip.steak);
				end)
				
				task.delay(11.5, function()
					whip:leave();
				end)
			end;
		end))

		self.Animations.HeedMyCall:Play(0.1, 1, 1.25)
		self.Animations.HeedMyCall.Stopped:Wait()
		self:Close()
	else
		local GotSpeed = false

		local Steak = script.Steak:Clone()
		Steak.SteakJoint.Part0 = self.LuaCharacter.Torso;
		Steak.Parent = self.LuaCharacter.Model;

		local SteakKey = script.SteakKey:Clone();

		self.Thread.OnClosed:Connect(function()
			Steak:Destroy();
			SteakKey:Destroy();

			self.Animations.SteakOrder:Stop()

			if not GotSpeed then
				self.Combat:TimesSpeed(10)
			end

			self.RideCooldown = true

			task.delay(0.5, function()
				self.RideCooldown = false
			end)

			self.Riding = false

			self:AddCooldown(20)
			self.Combat:StackState("Attacking", false)
		end);
		
		local BumperHitbox = self:CreateHitbox(true);
		BumperHitbox.Params.Offset = CFrame.new(0, 17.5, 0)
		BumperHitbox.Params.Size = 15;
		BumperHitbox.Adornee = Steak;
		BumperHitbox.Params.DestroyOnEndCast = true;
		
		local AccumulatedDamage = 0;
		local AccumulateMax = 16;
		local Debounce = false;
		
		BumperHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character;
			
			task.delay(0.5, function()
				BumperHitbox:RemoveHumanoid(VictimLuaCharacter.Humanoid);
			end);
			
			self:FireReliableVFX("Meaty Michael/Steak Order", "BumperHit", VictimLuaCharacter.RootAttachment, Steak);
			
			local Damage = 3;
			local FinalHit = AccumulatedDamage + Damage >= AccumulateMax;
			
			local Validated = self:Afflict(VictimLuaPlayer, {
				Damage = Damage,
				BreakBlock = true,
				Ragdoll = if FinalHit then 2.5 else 1.75,
				Velocity = {(VictimLuaCharacter.RootPart.Position - Steak.Position).Unit * (if FinalHit then 30 else 120) + Vector3.yAxis * 50, 0.15}
			});
			
			if Validated then
				AccumulatedDamage = math.clamp(AccumulatedDamage + Damage, 0, AccumulateMax);
				
				if FinalHit then
					self:Cancel();
				end;
			end;
		end);

		self:FireReliableVFX("Meaty Michael/Steak Order", "Start", self.LuaCharacter.RootPart)

		self.Thread.Job:Task(self.Animations.SteakOrder:GetMarkerReachedSignal("KeyGrab"):Once(function()
			SteakKey.SteakKeyJoint.Part0 = self.LuaCharacter.RightArm
			SteakKey.Parent = self.LuaCharacter.Model;
		end))

		self.Thread.Job:Task(self.Animations.SteakOrder:GetMarkerReachedSignal("CarKey"):Once(function()
			self:FireReliableVFX("Meaty Michael/Steak Order", "CarKey", self.LuaCharacter.Model)
			self:FireReliableVFXToSelf("Meaty Michael/Meaty Scare", "new")
		end))

		self.Thread.Job:Task(self.Animations.SteakOrder:GetMarkerReachedSignal("CarEngine"):Once(function()
			self:FireReliableVFX("Meaty Michael/Steak Order", "CarEngine", Steak)
		end))

		self.Thread.Job:Task(self.Animations.SteakOrder:GetMarkerReachedSignal("Jump"):Once(function()
			GotSpeed = true;
			
			self.Combat:TimesSpeed(10);
			
			BumperHitbox:BeginCast();
			SteakKey:Destroy();
			
			self:FireReliableVFXToSelf("Meaty Michael/Steak Order", "Jump", self.LuaCharacter.RootPart, Steak);
			
			if self.LuaPlayer.IsNPC then
				local LinearVelocity, Align = SteakOrder.Jump(self.LuaCharacter.RootPart, Steak);
				Align:Destroy();
				
				self.Thread.OnClosed:Connect(function()
					LinearVelocity:Destroy();
				end);
			end
		end))

		self.Thread.Job:Task(self.Animations.SteakOrder:GetMarkerReachedSignal("Pause"):Once(function()
			self.Riding = true
			self.Animations.SteakOrder:AdjustSpeed(0)
		end))

		self.Animations.SteakOrder:Play(0.2)
		self.OnWantToUnride:Wait();
		
		self:Close()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	
	self.TryToCancelMoves = true
	self.RideCooldown = false
	self.Riding = false
	self.OnWantToUnride = self.Job:Task(EventService.new())

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack