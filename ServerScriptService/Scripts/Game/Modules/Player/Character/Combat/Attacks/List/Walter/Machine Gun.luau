local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )

local DomainHandler = require( ServerScriptService.Scripts.DomainHandler )
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AenoirEmit = EffectUtility.AenoirEmit
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
	self.Combat:DivideSpeed(35);
	
	local RootPart = self.Combat:GetSimulatedRoot();
	local TurretMaid = Maid.new();
	local HasPlaced = false;
	
	local Turret = Assets.Turret:Clone();
	Turret.Mid.CFrame = RootPart.CFrame;
	Turret.Mid.Joint.Part0 = self.LuaCharacter.RootPart;
	Turret.Parent = self.LuaCharacter.Model;

	Turret.Destroying:Once(function()
		TurretMaid:destroy();
	end)
	
	self.Thread.OnClosed:Connect(function()
		if not HasPlaced then
			TurretMaid:destroy();
			Turret:Destroy();
		end;
		
		self:AddCooldown(29);
		
		self.Combat:StackState("Attacking", false);
		self.Combat:TimesSpeed(35);
	end);
	
	local CurrentTarget;
	local IsFiring = false;
	
	local SpreadSeed;
	local SpreadRnd;
	
	local function GenerateNewSpread()
		SpreadSeed = math.random() + 1.942;
		SpreadRnd = Random.new(SpreadSeed);
	end;
	
	GenerateNewSpread();
	
	local function SetTarget(Target)
		if CurrentTarget ~= Target then
			Turret.SetTarget:FireAllClients(if Target then Target.LuaCharacter.Humanoid else nil);
			CurrentTarget = Target;
		end;
	end;
	
	local Hitbox = self:CreateHitbox(true, true);
	Hitbox.Adornee = Turret.Mid;
	Hitbox.Params.Size = 65;
	Hitbox.Params.Sorting = "Nearest";
	Hitbox.Params.MaxTargets = 4;
	
	self.Thread.OnClosed:Once(function()
		if not HasPlaced then
			Hitbox:EndCast();
			Hitbox:Destroy();
		end;
	end);
	
	local DetectHit = false;
	
	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat
		
		if not DetectHit and VictimLuaCharacter.HumanoidAlive then
			DetectHit = true;
			SetTarget(VictimCombat);
		end;
	end);
	
	local function RangeDetect()
		SetTarget(nil);
		DetectHit = false;
		
		Hitbox:Reset();
		Hitbox:Detect();
	end
	
	local ProjectileParams = RaycastParams.new();
	ProjectileParams.FilterType = Enum.RaycastFilterType.Include;
	ProjectileParams:AddToFilter(workspace.Map);
	
	local function AddFolder(Folder)
		for _, Item in Folder:GetChildren() do
			if Item:IsA("Folder") then
				AddFolder(Item);
				
			elseif Item:IsA("Model") and Item ~= self.LuaCharacter.Model then
				ProjectileParams:AddToFilter(Item);
			end;
		end;
	end;
	
	AddFolder(workspace.Models);
	
	local function FireProjectile(Origin, Direction)
		local Result = workspace:Raycast(Origin.Position, Direction.Unit * 256, ProjectileParams);
		local Target = Origin.Position + Direction.Unit * 256;
		local VictimLuaPlayer;
		
		if Result then
			Target = Result.Position;
			
			local Model = Result.Instance:FindFirstAncestorOfClass("Model");
			
			if Model then
				VictimLuaPlayer = LuaPlayerList.Get(Model)
			end;
		end;
		
		local Distance = (Origin.Position - Target).Magnitude;
		
		if VictimLuaPlayer and VictimLuaPlayer ~= self.LuaPlayer and not VictimLuaPlayer.Character.Combat.IsChara then
			local Direction = CurrentTarget.LuaCharacter.RootPart.Position - Turret.Mid.Position;

			local Validated = self:Afflict(VictimLuaPlayer, {
				Damage = 0.5,
				BreakBlock = Direction.Magnitude < 20,
				TriggerActiveCounterOverOrEqualLevel = -1,
				HitAngleLookVector = -Direction.Unit,
				DontRestartRespawnTimer = true,
			});
		end;
	end;
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("TurretLand"):Once(function()
		self.Combat:StackState("GrabIFrames", true);
		
		self.Thread.OnClosed:Once(function()
			self.Combat:StackState("GrabIFrames", false);
		end)
	end));
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("TurretPlace"):Once(function()
		HasPlaced = true;
		
		Turret.Mid.Joint.Enabled = false;
		Turret.Mid.Anchored = true;
		
		TurretMaid:add(task.spawn(function()
			
			while task.wait(0.07) do
				RangeDetect();
				task.wait() -- bruh
				
				if CurrentTarget then
					if not IsFiring then
						GenerateNewSpread();
						
						IsFiring = true;
						Turret.SetFiring:FireAllClients(true, SpreadSeed);
					end;
					
					local Origin = Turret.Mid.CFrame
					local Direction = (CurrentTarget.LuaCharacter.RootPart.Position - Origin.Position).Unit + SpreadRnd:NextUnitVector() * 0.03;
					
					FireProjectile(Origin, Direction);
					
				elseif IsFiring then
					IsFiring = false;
					Turret.SetFiring:FireAllClients(false, SpreadSeed);
				end;
			end;
		end));
		
		RangeDetect();
		
		task.delay(10, function()
			Hitbox:EndCast();
			Hitbox:Destroy();
			
			TurretMaid:destroy();
			
			if IsFiring then
				IsFiring = false;
				Turret.SetFiring:FireAllClients(false, SpreadSeed);
			end
			
			task.wait(3);
			Turret:Destroy();
		end);
		
		-- Has flashing problems
		Turret.Parent = workspace.Visuals;
		self:Close();
	end))

	self:FireReliableVFX("Walter/Machine Gun", "Turret", Turret, self.LuaCharacter.Model);
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