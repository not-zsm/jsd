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
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )
local Maid = require( ReplicatedStorage.Packages.Maid )

local ProjectileHandler = require( ServerScriptService.Scripts.ProjectileHandler )

local Assets = ReplicatedStorage.Modules.Player.Replication.VFX.Walter[script.Name].Assets

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true);
	self.Combat:DivideSpeed(10);

	self.Animations.Windup.Looped = false;
	
	local Wheelchair = Assets.WheelChair:Clone();
	local WheelRoot = Wheelchair.HumanoidRootPart;
	local Pushed = false;
	
	local Replicator = Wheelchair.Replicator;
	local RootPart = self.Combat:GetSimulatedRoot();
	local RootAttachment = RootPart.RootAttachment;
	
	local OffsetAttachment = Instance.new("Attachment");
	OffsetAttachment.CFrame = CFrame.new(0, 0, 0);
	OffsetAttachment.Parent = RootAttachment;
	
	WheelRoot.Anchored = false;
	WheelRoot.CFrame = self.LuaCharacter.RootPart.CFrame;
	WheelRoot.AlignPosition.Attachment1 = OffsetAttachment;
	WheelRoot.AlignPosition.Enabled = true;
	WheelRoot.AlignOrientation.Enabled = true;
	WheelRoot.AlignOrientation.Mode = Enum.OrientationAlignmentMode.TwoAttachment;
	WheelRoot.AlignOrientation.Attachment1 = RootAttachment;
	WheelRoot.RootAttachment.WorldPosition = WheelRoot.AssemblyCenterOfMass;
	Wheelchair.Parent = workspace.Visuals;
	
	if WheelRoot:CanSetNetworkOwnership() then
		WheelRoot:SetNetworkOwner(nil);
	end;
	
	local ChairTarget = nil;
	
	local ReplicateConnection = AenoirUtil.EventFrequency(RunService.PostSimulation, 1 / 20, function(dt)
		if WheelRoot.Anchored then
			WheelRoot.CFrame = RootPart.CFrame * CFrame.new(0, 0, -8);
		end;
		
		if ChairTarget then
			local Direction = ( WheelRoot.Position - ChairTarget:GetSimulatedRoot().Position );
			
			if Direction == Direction and Direction ~= Vector3.zero then
				WheelRoot.AlignOrientation.Responsiveness = 2;
				WheelRoot.AlignOrientation.CFrame = CFrame.lookAlong(Vector3.zero, -Direction);
			end;
		end;
		
		Replicator:FireAllClients(WheelRoot.CFrame, WheelRoot.AssemblyLinearVelocity);
	end);
	
	local function Cleanup()
		ChairTarget = nil;
		ReplicateConnection:Disconnect();
		Replicator:Destroy();
		Wheelchair:Destroy();
		OffsetAttachment:Destroy();
	end;
	 
	local function DismantleWheelchair()
		ChairTarget = nil;
		ReplicateConnection:Disconnect();
		Replicator:Destroy();
		
		self:FireReliableVFX("Walter/Last Chance To Look", "Dismantle", Wheelchair, self.LuaCharacter.Model);
	end
	
	Wheelchair.Destroying:Once(Cleanup);
	
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(12);
		
		self.Combat:StackState("Attacking", false);
		self.Combat:TimesSpeed(10);
		
		if not Pushed then
			Cleanup()
		else
			task.delay(15, Cleanup);
		end;
	end);
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Push"):Once(function()
		Pushed = true;
		
		WheelRoot.Anchored = false;
		WheelRoot.AlignPosition.Enabled = false;
		WheelRoot.AlignOrientation.Enabled = true;
		WheelRoot.PushVelocity.Enabled = true;
		
		WheelRoot.AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment;
		WheelRoot.AlignOrientation.CFrame = CFrame.lookAlong(Vector3.zero, RootPart.CFrame.LookVector);

		local bumper_hitbox = self:CreateHitbox(true, true);
		bumper_hitbox.Adornee = Wheelchair.Hitbox;
		bumper_hitbox.Params.Offset = CFrame.new(0, 0, -3);
		bumper_hitbox.Params.Size = 5;
		bumper_hitbox.Params.Sorting = "Nearest";
		bumper_hitbox.Params.MaxTargets = 1;
		
		local first_hit = false;
		local Rnd = Random.new();
		
		bumper_hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				Damage = 3,
				Ragdoll = 1.5;
				Velocity = {WheelRoot.CFrame.LookVector * 30 + Vector3.yAxis * 12.5 + (Rnd:NextUnitVector() * Vector3.new(1, 0, 1)).Unit * 20, 0.15},
				TriggerActiveCounterOverOrEqualLevel = -1,
			})

			if Validated then
				WheelRoot.PushVelocity.VectorVelocity *= 0.8;
				
				if not first_hit then
					first_hit = true;
					
					self:FireReliableVFX("Walter/Last Chance To Look", "Bump", Wheelchair, math.random() < 0.9);
				else
					self:FireReliableVFX("Walter/Last Chance To Look", "Bump", Wheelchair, false);
				end;
			end;
			
			task.delay(1, function()
				bumper_hitbox:RemoveHumanoid(VictimLuaCharacter.Humanoid);
			end);
		end);
		
		bumper_hitbox:BeginCast();
		
		task.delay(2.6, function()
			bumper_hitbox:EndCast();
			bumper_hitbox:Destroy();
			
			WheelRoot.PushVelocity.Enabled = false;
			WheelRoot.AlignOrientation.Enabled = false;
			
			local size = 20
			local rnd = Random.new()
			
			self.Combat.Hitbox:CreateHavocReplicated({
				parameters = {
					origin = WheelRoot.CFrame,
					shape = "Sphere", 
					radius = size,
					block_size = 6,
				},

				debris = {
					scale = 0.9,
					radius = size,
					velocity = function(part)
						return (rnd:NextUnitVector() * Vector3.new(1, 0, 1)).Unit * 30 + Vector3.yAxis * 40;
					end,
				},
			});
			
			local explode_hitbox = self:CreateHitbox(true, true);
			explode_hitbox.Adornee = WheelRoot;
			explode_hitbox.Params.Size = 25
			explode_hitbox.Params.Sorting = "Nearest";
			explode_hitbox.Params.MaxTargets = 5;

			explode_hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local Validated = self:Afflict(VictimLuaPlayer, {
					Damage = 17,
					BreakBlock = true,
					TrueStun = 1,
					Ragdoll = 2.75;
					Velocity = {(VictimLuaCharacter.RootPart.Position - explode_hitbox:GetPosition()).Unit * 55 + Vector3.yAxis * 35, 0.2},
					TriggerActiveCounterOverOrEqualLevel = -1,
				})

				if Validated then
					
				end
			end);

			explode_hitbox:Detect();
			
			task.defer(function()
				explode_hitbox:Destroy();
			end);
			
			DismantleWheelchair();
		end);
		
		local hitbox = self:CreateHitbox(true, true);
		hitbox.Adornee = WheelRoot;
		hitbox.Params.Size = 75;
		hitbox.Params.Sorting = "Nearest";
		hitbox.Params.MaxTargets = 1;
		
		hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			ChairTarget = VictimCombat;
		end);
		
		hitbox:Detect();
		
		task.defer(function()
			hitbox:Destroy();
		end);
		
		task.wait(0.25);
		self:Close();
	end));
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("StartPush"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1.3
		VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 110000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 20
		VelocityObject:Fire()
	end));
	
	local Friend = self.LuaPlayer:GetRandomFriend(true);
	
	self:FireReliableVFX("Walter/Last Chance To Look", "Wheelchair", Wheelchair, self.LuaCharacter.Model, Friend);
end;

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack