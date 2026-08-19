local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer;

local Assets = script.Assets;
local Rnd = Random.new();

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
--local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )
local Ragdoll = require( ReplicatedStorage.MovementReplicator.Lib.Ragdoll )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Velocities = require( ReplicatedStorage.BuildTools.Build.Velocities )
local AenoirEmit = EffectUtility.AenoirEmit

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Flashbang = require( ReplicatedStorage.Modules.Player.Replication.Global.Flashbang )
local ProjectileHandler = require( ReplicatedStorage.Projectiles.ProjectileHandler )
local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local Maid = require( ReplicatedStorage.Packages.Maid )

local Animations = ReplicatedStorage.Animations.Attacks.Walter[script.Name]

type Turret = typeof(Assets.Turret);

return {
	["Turret"] = function(Turret: Turret, Character)
		if not Character then return end;

		local Retrieved = AnimationRetriever.new(Character, Animations.Windup)
		if (Retrieved == nil) then return end

		local Job = Retrieved.Job;
		local Animation = Retrieved.Animation;
		local RootPart = Retrieved.RootPart;
		
		local ThisPlayer = Players:GetPlayerFromCharacter(Character);
		local RootPart = Character.HumanoidRootPart;
		
		local TurretMaid = Maid.new();
		local FiringMaid = TurretMaid:limb();
		local CurrentTarget: Humanoid? = nil;
		local CurrentRotation: CFrame = CFrame.identity;
		local IsFiring = false;
		local SpreadRnd = Random.new();
		local FireImpulse = 0;
		
		--Turret.Front.GunRotate.C0 = CFrame.identity;
		
		Turret.Destroying:Once(function()
			TurretMaid:destroy();
		end);
		
		TurretMaid:add(RunService.PreSimulation:Connect(function(dt)
			if CurrentTarget then
				CurrentRotation = CurrentRotation:Lerp(Turret.Mid.CFrame.Rotation:Inverse() * CFrame.lookAt(Vector3.zero, CurrentTarget.RootPart.Position - Turret.Mid.Position), 15 * dt);
				
				FireImpulse = math.max(0, FireImpulse - dt * 10);
				Turret.MidStern.GunRotate.Transform = CurrentRotation * CFrame.Angles(FireImpulse * 0.1, 0, 0) * CFrame.new(0, 0, FireImpulse * 0.5);
			end;
		end))
		
		Turret.SetTarget.OnClientEvent:Connect(function(Target: Humanoid)
			CurrentTarget = Target;
		end);
		
		local ProjectileParams = RaycastParams.new();
		ProjectileParams.FilterType = Enum.RaycastFilterType.Include;
		ProjectileParams:AddToFilter(workspace.Map);

		local function AddFolder(Folder)
			for _, Item in Folder:GetChildren() do
				if Item:IsA("Folder") then
					AddFolder(Item);

				elseif Item:IsA("Model") and Item ~= Character then
					ProjectileParams:AddToFilter(Item);
				end;
			end;
		end;

		AddFolder(workspace.Models);
	
		local function CreateProjectile(Origin: CFrame, Direction: Vector3)
			local Projectile = Assets.Bullet:Clone();
			Projectile.CFrame = Origin;
			Projectile.Trail.Transparency = NumberSequence.new(math.random() * 0.2);
			Projectile.Parent = workspace.Visuals;
			Debris:AddItem(Projectile, 5);
			
			AenoirEmit( Assets.Miss, Projectile.Attachment0 );
			
			local Result = workspace:Raycast(Origin.Position, Direction.Unit * 256, ProjectileParams);
			local Target = Origin.Position + Direction.Unit * 256;
			local Humanoid: Humanoid?;
			
			if Result then
				Target = Result.Position;
				
				local Model = Result.Instance:FindFirstAncestorOfClass("Model");
				
				if Model then
					Humanoid = Model:FindFirstChildOfClass("Humanoid");
				end;
			end;
			
			local Distance = (Origin.Position - Target).Magnitude;
			
			local Tween = TweenService:Create(Projectile, TweenInfo.new(Distance / math.random(1_000, 1_300), Enum.EasingStyle.Linear), {
				CFrame = Origin.Rotation + Target;
			});
			
			task.wait(0.02); -- Trail delay
			Tween:Play();
			
			Tween.Completed:Once(function()
				if Humanoid and Blood.CanShowBlood() then
					AenoirEmit( Assets.Slice, Target, nil, {Scale = 0.125, Volume = 0.25} );
				else
					AenoirEmit( Assets.HitNone, Target, nil, {Scale = 0.125, Volume = 0.5} );
				end;
				
				for _, Light in Projectile:GetDescendants() do
					if Light:IsA("Light") then
						Light.Enabled = false;
					end;
				end;
				
				task.wait(2);
				Projectile:Destroy();
			end);
		end
		
		local function FireProjectile(): ()
			if not CurrentTarget then
				return;
			end;
			
			local MaxDistance = 100;
			local Distance = Player:DistanceFromCharacter(Turret.Front.Position)
			local Taper = 1 - math.clamp(math.map(Distance, 25, MaxDistance, 0, 1), 0, 1);

			if Distance <= MaxDistance then
				CameraShake(4.5 * Taper, 5, 0.01, 0.2, Vector3.one * 0.1 * Taper, Vector3.one * 0.01 * Taper)
			end

			AenoirEmit( Assets.BarrelShot, Turret.Front.Barrel, nil, {Scale = 0.3} );
			CreateProjectile(Turret.Front.Barrel.WorldCFrame, (CurrentTarget.RootPart.Position - Turret.Mid.Position).Unit + SpreadRnd:NextUnitVector() * 0.03 );
			
			FireImpulse = 0.6;
		end;
		
		Turret.SetFiring.OnClientEvent:Connect(function(Value: boolean, Seed)
			FiringMaid:clean();
			SpreadRnd = Random.new(Seed);
			IsFiring = Value;
			
			if Value then
				FiringMaid:add(task.spawn(function()
					while task.wait(0.07) do
						FireProjectile();
					end;
				end));
			end;
		end)
		
		AenoirEmit( Assets.Placement, Turret.Mid );
		
		Job:Task(Animation:GetMarkerReachedSignal("TurretPlace"):Connect(function()
			Turret.MidStern.GunRotate.C0 = CFrame.fromEulerAnglesXYZ(0, math.rad(0), 0);
			Turret.MidStern.GunRotate.C1 = CFrame.new(0, -0.65, 0.4);
			
			--Turret.Parent = workspace.Visuals;
		end));
	end,
};