local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )

local DomainHandler = require( ServerScriptService.Scripts.DomainHandler )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit
local Maid = require( ReplicatedStorage.Packages.Maid )

local ProjectileHandler = require( ServerScriptService.Scripts.ProjectileHandler )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not self.FlickPhase
end

function Attack:Pretrigger()
	if self.FlickPhase and not self.Flicked then
		self.Flicked = true;
		
		self:ChangeDisplay(self.DisplayName, {
			Tip = "",
			FlashColor = Color3.fromRGB(255, 255, 255)
		})
	end
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true);
	self.Combat:DivideSpeed(5);

	local AnimationMaid = Maid.new();
	
	self.Thread.OnClosed:Connect(function()
		AnimationMaid:destroy();
		
		self:AddCooldown(17);
		
		self.Combat:StackState("Attacking", false);
		self.Combat:TimesSpeed(5);
	end);
	
	local ToSwing = false;
	local Thrown = false;

	local function ThrowProjectile()
		if Thrown then return end;
		Thrown = true;
		
		local projectile = ProjectileHandler:create("Boomerang");
		
		task.delay(10, function()
			projectile:destroy();
		end)

		local hitbox = self:CreateHitbox(true, true);
		hitbox.Adornee = projectile.saucer.model;
		hitbox.Params.Size = 6

		hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Difference = VictimLuaCharacter.RootPart.Position - hitbox:GetPosition();
			
			local Validated = self:Afflict(VictimLuaPlayer, {
				Damage = 17.5,
				BreakBlock = true,
				TrueStun = 1,
				Ragdoll = 2.25,
				Velocity = {Difference.Unit * (if Difference.Magnitude < 20 then 55 else 100), 0.15},
				TriggerActiveCounterOverOrEqualLevel = -1,
			})
			
			if Validated then
				self:FireReliableVFX("Walter/Pizza Throw", "Slice", VictimLuaCharacter.Humanoid);
			end;
		end);

		projectile:fire(self.LuaCharacter.RootPart.CFrame * CFrame.new(1, 1, -1), self.LuaCharacter.RootPart);
		hitbox:BeginCast();

		task.wait(0.5);
		local DisplayChanged = false;
		
		projectile:bind_to_update(1 / 60, function(elapsed, dt)
			if ToSwing then return end;
			
			local distance = ( self.LuaCharacter.RootPart.Position - projectile:get_position() ).Magnitude;

			if not DisplayChanged and distance < 35 then
				self.FlickPhase = true;
				DisplayChanged = true;
				
				self:ChangeDisplay("Hrahh!", {
					Tip = "[PRESS AGAIN]",
					FlashColor = Color3.fromRGB(255, 100, 53)
				})
			end;
			
			if distance < 5 then
				ToSwing = true;
				
				if self.Flicked then
					self.Animations.SwingBack:GetMarkerReachedSignal("Swing"):Once(function()
						self.Combat:StackState("Attacking", true);

						task.delay(0.25, function()
							self.Combat:StackState("Attacking", false);
						end)

						local projectile = ProjectileHandler:create("PizzaBlast");

						projectile.hitbox = self:CreateHitbox(true, true);
						projectile.hitbox.Adornee = projectile.saucer.model;
						projectile.hitbox.Params.Size = 6

						projectile.hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
							local VictimLuaCharacter = VictimLuaPlayer.Character
							local VictimCombat = VictimLuaCharacter.Combat

							local Validated = self:Afflict(VictimLuaPlayer, {
								Damage = 15,
								BreakBlock = true,
								TrueStun = 1,
								Ragdoll = 2,
								Velocity = {(VictimLuaCharacter.RootPart.Position - projectile.hitbox:GetPosition()).Unit * 75, 0.1},
								TriggerActiveCounterOverOrEqualLevel = -1,
							})

							if Validated then
								self:FireReliableVFX("Walter/Pizza Throw", "Slice", VictimLuaCharacter.Humanoid);
							end;
						end);

						local collide_connection;
						
						collide_connection = projectile.saucer.on_collide:Connect(function(result: RaycastResult)
							local humanoid = result.Instance.Parent:FindFirstChildOfClass("Humanoid");
							
							if not humanoid then
								collide_connection:Disconnect();
								projectile:stop(result);
							end;
						end);

						projectile:fire(self.LuaCharacter.RootPart.CFrame * CFrame.new(1, 1, -1), self.LuaCharacter.RootPart);
						projectile.hitbox:BeginCast();

						task.delay(10, function()
							projectile:destroy();
						end);
					end);
					
					self.Animations.SwingBack:Play(0, 1, 1.5);
					self:FireReliableVFX("Walter/Pizza Throw", "Swing", self.LuaCharacter.Model);
				else
					self:Afflict(self.LuaPlayer, {
						Damage = 4,
						BreakBlock = true,
						Ragdoll = 1.5,
						Velocity = {(self.LuaCharacter.RootPart.Position - hitbox:GetPosition()).Unit * 35, 0.1},
						TriggerActiveCounterOverOrEqualLevel = -1,
					})
					
					self:FireReliableVFX("Walter/Pizza Throw", "Slice", self.LuaCharacter.Humanoid);
					self:ChangeDisplay(self.DisplayName, {Tip = ""});
				end;
				
				self.Flicked = false;
				self.FlickPhase = false;
				
				hitbox:EndCast();
				hitbox:Destroy();
				
				projectile:destroy();
			end
		end);
	end

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Throw"):Once(function()
		ThrowProjectile();
		
		self:Close();
	end))

	self:FireReliableVFX("Walter/Pizza Throw", "Pizza", self.LuaCharacter.Model, AenoirUtil.GetAnimationId(self.Animations.Windup.Animation.AnimationId));
	task.wait(0.5);
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