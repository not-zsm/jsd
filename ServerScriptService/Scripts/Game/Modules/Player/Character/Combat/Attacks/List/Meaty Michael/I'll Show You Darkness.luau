local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local MichaelEnemy = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.List["Meaty Michael"]["Helping Hand"].MichaelEnemy )
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

	local TargetAttachment = Instance.new("Attachment");
	TargetAttachment.Name = "TargetAttachment";

	local ArmAttachment = Instance.new("Attachment");
	ArmAttachment.Name = "ArmAttachment";
	ArmAttachment.CFrame = CFrame.new(-0.75, -1.25, 0.5);
	ArmAttachment.Parent =  self.LuaCharacter.RightArm

	self.Thread.OnClosed:Connect(function()
		task.delay(5, function()
			TargetAttachment:Destroy()
			ArmAttachment:Destroy()
		end)

		self:AddCooldown(14)
		self.Combat:StackState("Attacking", false)
	end)

	local PullHitbox = self:CreateHitbox(true);
	PullHitbox.Params.Offset = CFrame.identity
	PullHitbox.Params.Size = 18
	PullHitbox.Params.DestroyOnEndCast = true
	
	local PullConnection : RBXScriptConnection = nil
	local Hit = {}
	
	local function CleanStuff()
		if PullConnection and PullConnection.Connected then
			PullConnection:Disconnect()
		end
		
		for _, Attachment in self.PullAttachments do
			Attachment:Destroy()
		end

		table.clear(self.PullAttachments)
		
		for Victim in Hit do
			Victim.Character.Combat:StackState("CannotDash", false)

			if Victim.Character.HumanoidExists then
				if not Victim.Character.Combat:GetState("Grabbed") then
					Victim.Character:SetCollisionGroup("Player")
				end

				Victim.Character.Combat.Ragdoll:SetCollisionGroupOfColliders("Default")
			end
		end

		table.clear(Hit)
	end
	
	local ActivateFinisher = false;
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("ChargeStart"):Once(function()
		TargetAttachment.CFrame = self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 5, -25);
		TargetAttachment.Parent = workspace.Terrain;
		PullHitbox.Adornee = TargetAttachment.Position

		self:FireReliableVFX("Meaty Michael/NEED CAPITIVES", "ChargeStart", self.LuaCharacter.Model, ArmAttachment, TargetAttachment)

		PullHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			local Blocked = VictimCombat:GetState("Blocking")
			local Finisher = self:IsFinisherEnabled() and VictimLuaCharacter.Humanoid.Health <= 25;
			
			local Validated = self:Afflict(VictimLuaPlayer, {
				TriggerActiveCounterOverOrEqualLevel = -1,
				DontCheckBlock = true,
			})

			if Validated and not Hit[VictimLuaPlayer] then
				if Finisher then
					ActivateFinisher = true;
				end;
				
				if not Blocked then
					VictimCombat:StackState("CannotDash", true)
					
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true;
						Ragdoll = 5;
					})
					--VictimCombat.Ragdoll:Toggle(true, 5)
				end
				
				VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")
				VictimCombat.Ragdoll:SetCollisionGroupOfColliders("NoPlayerCollision")

				local HitsThread = coroutine.create(function()
					while VictimLuaCharacter.HumanoidAlive do
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Damage = Blocked and 0.1 or 0.5,
						})

						task.wait(0.3)
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

		PullConnection = RunService.PostSimulation:Connect(function()
			local AdorneeCF = CFrame.new(PullHitbox.Adornee)

			for Victim in Hit do
				local Model = Victim.Character.Model

				if (not Victim.Character.HumanoidExists or Model == nil) then
					self.PullAttachments[Model] = nil
				else
					if self.PullAttachments[Model] then
						self.PullAttachments[Model].CFrame = AdorneeCF
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

						self.PullAttachments[Model] = Attachment
					end
				end
			end
		end)
		
		task.delay(0.1, function()
			PullHitbox:BeginCast()
		end)
		
		self.Thread.OnClosed:Connect(CleanStuff)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Prison"):Once(function()
		local function EndPulling()
			PullHitbox:EndCast()
			PullHitbox:Destroy()
			CleanStuff()
		end;
		
		if ActivateFinisher then
			self:FireReliableVFX("Meaty Michael/NEED CAPITIVES", "PrisonFinisher", TargetAttachment)
			task.wait(0.20);
			self.Animations.Windup:AdjustSpeed(-0.25);
			task.wait(0.45);
			self.Animations.Windup:AdjustSpeed(0.5);
			
			EndPulling();
			
			local astral_meaty = MichaelEnemy.new(self, TargetAttachment.WorldCFrame, {
				Steak = "AstralSteak";
			});
			astral_meaty.attack_range = 15;
			astral_meaty.damage_multiplier = 2;
			astral_meaty.speed = 40;
			astral_meaty.attack_pushback_power = 35;
			astral_meaty.attack_tick = 1.25;
			astral_meaty.y_power = 12.5;
			astral_meaty.laser_chance = 0.5;
			astral_meaty.laser_block_angle = math.rad(75);
			astral_meaty.attack_block_angle = 0;
			astral_meaty.laser_effect_properties = { Tint = Color3.fromRGB(155, 105, 255), Scale = 1.5, Volume = 0.75 };
			astral_meaty.attack_effect_properties = { Tint = Color3.fromRGB(155, 105, 255), Scale = 1.5, Volume = 0.75 };
			
			task.delay(15, function()
				astral_meaty:leave();
			end);
			
			local Hitbox = self:CreateHitbox(true, true);
			Hitbox.Adornee = TargetAttachment.Position
			Hitbox.Params.Size = 55

			Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character

				self:Afflict(VictimLuaPlayer, {
					Damage = 22,
					BreakBlock = true,
					Ragdoll = 3,
					Velocity = {(VictimLuaCharacter.RootPart.Position - TargetAttachment.Position).Unit * 80 + Vector3.yAxis * 150, 0.2}
					--Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * -70 + Vector3.yAxis * 50, 0.1}
				})
			end)

			Hitbox:Detect()

			task.defer(function()
				Hitbox:Destroy()
			end)
		else
			EndPulling();
			
			self:FireReliableVFX("Meaty Michael/NEED CAPITIVES", "Prison", TargetAttachment);
			
			local Hitbox = self:CreateHitbox(true, true);
			Hitbox.Adornee = TargetAttachment.Position
			Hitbox.Params.Size = 35

			Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character

				self:Afflict(VictimLuaPlayer, {
					Damage = 10,
					BreakBlock = true,
					Ragdoll = 2.25,
					Velocity = {(VictimLuaCharacter.RootPart.Position - TargetAttachment.Position).Unit * 60 + Vector3.yAxis * 40, 0.1}
					--Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * -70 + Vector3.yAxis * 50, 0.1}
				})
			end)
			
			Hitbox:Detect()

			task.defer(function()
				Hitbox:Destroy()
			end)
		end;
		
		self.Combat.Hitbox:CreateHavocReplicated({
			parameters = {
				origin = CFrame.new(TargetAttachment.Position),
				shape = "Sphere", 
				radius = 22,
				block_size = 6, 
			},
		})
	end))

	self.Animations.Windup.Stopped:Wait()
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {
		FadeTime = 0.2,
		Speed = 0.45
	}

	self.PullAttachments = {}

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack