local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	self.Animations.Spin:Play(0, 0.001, 0)
	self.Animations.Impact:Play(0, 0.001, 0)

	self.Combat:StackState("Attacking", true)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(32)
		self.Combat:StackState("Attacking", false)
	end)
	
	-- Timeout incase you get perma-stuck.
	self.Thread.Job:Task(task.delay(30, function()
		self:Close();
	end))
	
	local DiveEndVelocity = Vector3.new(0, -300, -15);
	
	local ImpactLand = self.Thread.Job:Task(Instance.new("RemoteEvent"));
	ImpactLand.Name = "ImpactLand";
	ImpactLand.Parent = self.LuaCharacter.Model;

	local function DoImpact(Coordinate: CFrame)
		self:FireReliableVFX("Accelerator/Carnal Revolution", "Impact", self.LuaCharacter.Model, Coordinate)

		self.Combat:DivideSpeed(100)
		
		self.Thread.OnClosed:Connect(function()
			self.Combat:TimesSpeed(100)
		end)

		task.delay(2.25, function()
			self:Close();
		end);
		
		local Hitbox = self:CreateHitbox(true)
		Hitbox.Adornee = Coordinate.Position
		Hitbox.Params.Size = 40

		local Rnd = Random.new();
		
		self.Combat.Hitbox:CreateHavocReplicated({
			parameters = {
				origin = Hitbox:GetCFrame(),
				shape = "Sphere", 
				radius = 15,
				block_size = 9,
			},
			debris = {
				scale = 0.9,
				radius = 40,
				velocity = function(part)
					return Rnd:NextUnitVector() * 45 + Vector3.yAxis * 90;
				end,
			},
		});
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			self:Afflict(VictimLuaPlayer, {
				Damage = 31,
				BreakBlock = true,
				Ragdoll = 3,
				Velocity = {(VictimLuaCharacter.RootPart.Position - Coordinate.Position).Unit * 100 + Vector3.yAxis * 90, 0.1}
			})
		end)

		Hitbox:Detect()
		self.Combat.Hitbox:SphereDestruction(Hitbox.Adornee, Hitbox.Params.Size, 5)
	end

	self:FireReliableVFX("Accelerator/Carnal Revolution", "Start", self.LuaCharacter.Model, ImpactLand)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("fly"):Once(function()
		if self.LuaPlayer.IsNPC then
			local VelocityObject = self.Combat:Velocity();
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.Z = 175;
			VelocityObject.Settings.RemoveTime = 0.75
			VelocityObject.Settings.MaxForce = Vector3.one * 150_000;
			VelocityObject:Fire()
		end;
		
		self.Combat:StackState("HitboxImmunity", true)
		
		self.Thread.OnClosed:Connect(function()
			self.Combat:StackState("HitboxImmunity", false)
		end)
	end))
		
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("up"):Once(function()
		if self.LuaPlayer.IsNPC then
			local VelocityObject = self.Combat:Velocity();
			VelocityObject.Settings.Controllable = false
			VelocityObject.Settings.Velocity = Vector3.new(0, 125, 0);
			VelocityObject.Settings.RemoveTime = 1.4
			VelocityObject.Settings.MaxForce = Vector3.one * 250_000;
			VelocityObject:Fire();
		end;
		
		local Hitbox = self:CreateHitbox(true);
		Hitbox.Adornee = self.LuaCharacter.RootPart.Position
		Hitbox.Params.Size = 30
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			self:Afflict(VictimLuaPlayer, {
				Damage = 12,
				BreakBlock = true,
				Ragdoll = 2.5,
				Velocity = {(VictimLuaCharacter.RootPart.Position - self.LuaCharacter.RootPart.Position).Unit * 50 + Vector3.yAxis * 40, 0.25}
			})
		end)

		Hitbox:Detect()

		task.defer(function()
			Hitbox:Destroy()
		end)
	end))
	
	local Landed = false;
	
	local function ImpactEvent(Coordinate: CFrame?)
		if not Landed then 
			Landed = true;

			if not Coordinate then
				local Result = workspace:Raycast(self.LuaCharacter.RootPart.Position - DiveEndVelocity.Unit * 10, DiveEndVelocity.Unit * 100, Utility.VisualParams);
				
				if Result then
					Coordinate = self.LuaCharacter.RootPart.CFrame.Rotation + Result.Position;
				else
					Coordinate = self.LuaCharacter.RootPart.CFrame;
				end;
			end;
			
			DoImpact(Coordinate);
		end;
	end
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("dive"):Once(function()
		local Connection: RBXScriptConnection;
		
		if self.LuaPlayer.IsNPC then
			
			Connection = self.Thread.Job:Task(RunService.PreSimulation:Connect(function(dt)
				local Result = workspace:Raycast(self.LuaCharacter.RootPart.Position, DiveEndVelocity.Unit * 50, Utility.VisualParams);
				
				if Result then
					Connection:Disconnect();
					
					ImpactEvent(self.LuaCharacter.RootPart.CFrame.Rotation + Result.Position);
				end;
			end));
		else
			-- Dont connect elsewhere because remote buffering could be nice here.
			Connection = ImpactLand.OnServerEvent:Connect(function(Player2)
				if (Player2 ~= self.LuaPlayer.Player) then return end;

				Connection:Disconnect();
				ImpactEvent();
			end);
		end;
	end));
end;

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {
		FadeTime = 0.2,
		Speed = 1
	}

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack