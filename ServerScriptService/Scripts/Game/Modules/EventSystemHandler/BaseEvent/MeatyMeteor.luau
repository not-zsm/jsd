local BaseEvent = require( script.Parent );

local MeatyMeteor = setmetatable({}, BaseEvent);
MeatyMeteor.__index = MeatyMeteor

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)
local Maid = require( ReplicatedStorage.Packages.Maid )
local Havoc = require( ServerScriptService.Scripts.HavocHandler.Havoc )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Destruction = require( ServerScriptService.Scripts.Game.Modules.Destruction )
local BuildHandler = require( ServerScriptService.Scripts.BuildHandler )
local SphereHitbox = require( ReplicatedStorage.Modules.Shared.Game.Hitbox.Type.Sphere )
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
local PartCache = require( ReplicatedStorage.Havoc.PartCache )
local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )

local Modules = ReplicatedStorage.Modules
local Remotes = ReplicatedStorage.Remotes

local ReplicationRemotes = Remotes.Replication

local Animations = ReplicatedStorage.Animations.WorldEvents.MeatyMeteor;
local HeedMyCall = ReplicatedStorage.Modules.Player.Replication.VFX["Meaty Michael"]["Heed My Call"];
local CharacterEffects = ReplicatedStorage.Effects.Characters["Meaty Michael"];

local Assets = ServerStorage.EventAssets;

function MeatyMeteor.new(...)
	local self = setmetatable(BaseEvent.new(...), MeatyMeteor)
	
	-- Settings
	self.Settings = {
		Display = "World Event - Meaty Meteor",
		TimeUntilTracking = 5, -- Seconds
		DespawnTime = 550,
		EventDuration = 500,--900, -- Seconds (15 minutes = 900 seconds)
		BossHealth = 175;
		
		ImpactRadius = 215,
		ImpactY = 192.5,
		ImpactBlockSize = 3.5;
	}
	
	self.SteakTemplate = Assets.Meteor.Steak
	self.SpawnsFolder = Assets.MeteorSpawns
	self.SpawnCFrame = CFrame.identity;
	
	self.SteakMaid = self.Maid:limb();
	
	self.TerrainRayParams  = RaycastParams.new();
	self.TerrainRayParams.FilterDescendantsInstances = { workspace.Map.Model.Terrain };
	self.TerrainRayParams.FilterType = Enum.RaycastFilterType.Include;
	
	self.TerrainOverlap = OverlapParams.new();
	self.TerrainOverlap.FilterDescendantsInstances = { workspace.Map.Model.Terrain };
	self.TerrainOverlap.FilterType = Enum.RaycastFilterType.Include;
	
	return self
end

function MeatyMeteor:Start()
	if self.Active then return end;
	
	BaseEvent.Start(self);
	
	self:Spawn()
	
	self.Maid:add(self.SteakRoot.RootAttachment.ProximityPrompt.Triggered:Connect(function(Player)
		local LuaPlayer, LuaCharacter = self.System.EventUtility:GetLuaPlayer(Player)
		
		if LuaCharacter.Combat:NotStunned() and LuaCharacter.HumanoidAlive and not LuaCharacter.Combat:IsWorldBoss() then
			self.SteakRoot.RootAttachment.ProximityPrompt:Destroy()
			self:StartBoss(Player)
		end
	end))
	
	self.TimerThread = task.delay(self.Settings.DespawnTime, function()
		if self.Boss then return end;
		
		self:End("NoBoss");
	end);
	
	self.Maid:add(self.TimerThread)
end

function MeatyMeteor:StartBoss(Player : Player)
	local LuaPlayer, LuaCharacter = self.System.EventUtility:GetLuaPlayer(Player)
	
	self.BossMaid = self.Maid:limb()
	self.Boss = Player
	
	----------- BOSS CONNECTIONS -----------
	
	-- If Player Dies
	self.BossMaid:add(LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value : boolean)
		if not Value then
			self:End("Died")
		end
	end))

	-- If Player Leaves
	self.BossMaid:add(LuaPlayer.OnDestroyed:Connect(function()
		self:End("Left")
	end))

	-- If Player Switches Characters
	self.CharacterSwitchingConnection = LuaCharacter.Combat.OnCharacterSwitching:Connect(function(CharacterName : string)
		if CharacterName ~= "Meaty Michael" then
			self:End("Died")
		end
	end)
	
	self.Maid:delete(self.TimerThread);
	self.BossMaid:add(self.CharacterSwitchingConnection)
	
	self:ToggleSteak(false);
	
	do
		self.PreviousCharacter = LuaPlayer.Replication.Attributes:GetAttribute("CurrentCharacter") or "Default"
		
		LuaCharacter.Combat:SetCharacter("Meaty Michael")
		LuaCharacter.Combat.IsMeatyMichaelFromWorldEvent = true
		
		local Humanoid : Humanoid = LuaCharacter.Humanoid;
		Humanoid.MaxHealth = self.Settings.BossHealth;
		
		LuaCharacter:HealFull()
	end
	
	LuaCharacter:StopRegen()
	
	self.Maid:add(function()
		if self.CharacterSwitchingConnection then
			self.BossMaid:delete(self.CharacterSwitchingConnection)
		end

		local NewLuaPlayer, NewLuaCharacter = self.System.EventUtility:GetLuaPlayer(self.Boss)

		if NewLuaPlayer and NewLuaCharacter then
			NewLuaCharacter.Humanoid.MaxHealth = 100
			NewLuaCharacter:HealFull()
			NewLuaCharacter:StartRegen()

			if self.PreviousCharacter then
				NewLuaCharacter.Combat:SetCharacter(self.PreviousCharacter)
			else
				NewLuaCharacter.Combat:SetCharacter("Gojo")
			end

			LuaCharacter.Combat.IsMeatyMichaelFromWorldEvent = nil
		end;
	end);
	
	self.Maid:add(task.delay(self.Settings.EventDuration, function()
		self:End("OutOfTime")
	end))

	-- Set BossBar
	self.BossConfig = self.BossMaid:add(Instance.new("Configuration"))
	self.BossConfig:SetAttribute("Title", `{LuaCharacter.Humanoid.DisplayName}`)
	self.BossConfig:SetAttribute("BarType", "Meaty Michael");
	self.BossConfig:AddTag("BossBar");
	self.BossConfig.Archivable = false;
	self.BossConfig.Parent = LuaCharacter.Humanoid;

	self.System.EventUtility:Announce(self.Settings.Display, `{self.Boss:GetAttribute("Name")} has tasted the steak, and now they're going to steak it soo good. Defeat them if you wish not to see such a sight.`)
end

function MeatyMeteor:ToggleSteak(Value: boolean)
	self.SteakMaid:clean();
	
	local Transparency = if Value then 0 else 1;
	
	self.Steak.Torso.Transparency = Transparency;
	self.SteakPrompt.Enabled = Value;
	self.Steak.Torso.CanCollide = Value;
	self.SteakRoot.CanCollide = false;
	
	if Value then
		self.SteakMaid:add(task.spawn(function()
			while task.wait( math.random(10, 20) ) do
				BuildHandler:spawn_effects(HeedMyCall.Assets.SteakLaugh, self.Steak.Torso, {Volume = 0.25});
			end;
		end));
	end;
end;


-- Spawn Animation
function MeatyMeteor:Spawn()
	local SpawnLocations = self.SpawnsFolder:GetChildren()

	local RandomSpawn = SpawnLocations[math.random(1, #SpawnLocations)]
	local SpawnCFrame = RandomSpawn.CFrame;
	
	local Coordinate = SpawnCFrame + Vector3.yAxis * self.Settings.ImpactY;
	local Radius = self.Settings.ImpactRadius;
	
	self.SpawnCFrame = SpawnCFrame;
	
	self.Steak = self.Maid:add(self.SteakTemplate:Clone())
	self.SteakRoot = self.Steak.HumanoidRootPart;
	self.SteakPrompt = self.SteakRoot.RootAttachment.ProximityPrompt;
	self.SteakRoot.Anchored = true;
	self.Steak:PivotTo(SpawnCFrame);
	
	self:ToggleSteak(false);
	self.Steak.Parent = workspace.Visuals;
	
	self.SteakRoot.Falling:Play();
	self.Steak.Torso.ExplosionFalling.Enabled = true;
	
	local FallAnimation = self.Steak.AnimationController.Animator:LoadAnimation(Animations.Fall);
	self.Maid:add(FallAnimation);
	FallAnimation:Play(0);

	FallAnimation.Stopped:Connect(function()
		self.SteakRoot.Falling:Stop();
		self.Steak.Torso.ExplosionFalling.Enabled = false;

		self:ToggleSteak(true);
		self:CreateInitialBlast(Coordinate, Radius);
		
		task.wait(3.0);
		
		--self.System.EventUtility:Announce(self.Settings.Display, '"Im steaking it so good" (dont let him get away with it)')
		self.System.EventUtility:Announce("World Event - ???", `"I'm steaking it so good.." Wuh!? Did you guys hear that? (Go check out the small blast)`)
	end);
end;

function MeatyMeteor:CreateInitialBlast(Coordinate: CFrame, Radius: number)
	local SpawnCFrame = self.SpawnCFrame;
	
	self.SteakZone = self.Maid:add(Assets.Meteor.SteakZone:Clone());
	self.SteakZone:PivotTo(SpawnCFrame);
	self.SteakZone.Music:Play();
	self.SteakZone.Parent = workspace.Visuals;

	self.DeadZone = self.Maid:add(Assets.Meteor.DeadZone:Clone());
	self.DeadZone:PivotTo(Coordinate - Vector3.new(0, 2.5, 0));
	self.DeadZone.Size = Vector3.one * Radius * 2;
	self.DeadZone.FireSound:Play();
	self.DeadZone.Parent = workspace.Visuals;
	
	self:CreateDestructionImpact( Coordinate, Radius );
	self:CreateHitbox( Coordinate, Radius + 20 );

	BuildHandler:spawn_effects(CharacterEffects.WorldEventBlast, SpawnCFrame - Vector3.new(0, 25, 0), {Scale = 6.5, Density = 3})

	local ChosenEvent = math.random(1, ReplicationRemotes:GetAttribute("EventAmount"))
	local Event = ReplicationRemotes.Reliable:WaitForChild(ChosenEvent)
	Event:FireAllClients("Meaty Michael/World Event", "Blast", SpawnCFrame);
	
	local raycast = workspace:Raycast(SpawnCFrame.Position, -Vector3.yAxis * 256, self.TerrainRayParams);

	if raycast then
		local rnd = Random.new();

		self.Steak:PivotTo( CFrame.lookAlong(raycast.Position + Vector3.new(0, 1, 0), (rnd:NextUnitVector() * Vector3.new(1, 0, 1) + rnd:NextUnitVector() * Vector3.yAxis * 0.35).Unit) * CFrame.Angles(0, 0, math.rad(10)) );
	end;
end;

function MeatyMeteor:CreateDestructionImpact(Coordinate: CFrame, Radius: number)
	local HavocObject = Havoc.create({
		shape = "Sphere",
		origin = Coordinate,
		radius = Radius,
		block_size = 3.5,
		auto_overlap = false;
		overlap = self.TerrainOverlap;
		greedy_batch_size = 500;
		greedy_meshing = true;
	});

	local HavocDestructed = HavocObject:destruct({
		indefinite = true,
		crater = { parent = workspace.Map.Model.Terrain };
	});

	local ModelsDestructed = {};

	for _, Destructable in workspace:GetPartBoundsInRadius(Coordinate.Position, Radius + 30, Utility.DestructiblesParams) do
		table.insert(ModelsDestructed, Destruction.Destruct(Destructable, 10, nil, true));
	end;
	
	for Index = 1, math.random(12, 16) do
		local Rock = self:SpawnFlyingRock();
	end;
	
	return self.Maid:add(function()
		for _, Destructable in ModelsDestructed do
			Destruction.RestoreObject(Destructable);
		end;
		
		for _, Part in HavocDestructed do
			Havoc.restore_destructed(Part);
		end;
	end);
end;

function MeatyMeteor:SpawnFlyingRock()
	local Rnd = Random.new();
	local Scale = 3 * Rnd:NextNumber(0.25, 1);

	local Rock = Assets.Meteor.Rock:Clone();
	Rock.Size *= Scale;
	Rock.VectorForce.Force *= Scale;
	Rock.AssemblyLinearVelocity = (Rnd:NextUnitVector() + Vector3.yAxis * 1.25).Unit * Rnd:NextNumber(100, 175);
	Rock.AssemblyAngularVelocity = Rnd:NextUnitVector() * 20;

	Rock:PivotTo(self.SpawnCFrame);

	Rock.Parent = workspace.Visuals;
	Rock:SetNetworkOwner(nil);
	
	task.delay(0.25, function()
		local Touched : RBXScriptConnection;
		
		Touched = Rock.Touched:Connect(function(Part)
			if not Part:IsDescendantOf(workspace.Map.Model.Terrain) then
				return;
			end;
			
			Touched:Disconnect();

			task.delay(0.25, function()
				Rock.Anchored = true;
				Rock.AssemblyLinearVelocity = Vector3.zero;
				Rock.AssemblyAngularVelocity = Vector3.zero;
			end);
			
			local raycast = workspace:Raycast(Rock.Position, -Vector3.yAxis * 128, self.TerrainRayParams);

			if raycast then
				local TargetCFrame = Rock.CFrame.Rotation + raycast.Position - Vector3.yAxis * Scale;
				
				if (TargetCFrame.Position - self.SteakRoot.Position).Magnitude < 17.50 then
					return Rock:Destroy();
				end;
				
				task.delay(0.25, function()
					Rock:PivotTo(TargetCFrame);
				end);
				
				local HavocObject = Havoc.create({
					shape = "Sphere",
					origin = CFrame.new(raycast.Position) + Vector3.yAxis * (Scale * 4),
					radius = 4.75 * Scale,
					block_size = 3,
					auto_overlap = false;
					overlap = self.TerrainOverlap;
					greedy_batch_size = 500;
					greedy_meshing = true;
				});

				local HavocDestructed = HavocObject:destruct({
					indefinite = true,
					crater = { parent = workspace.Map.Model.Terrain };
				});

				self.Maid:add(function()
					for _, Part in HavocDestructed do
						Havoc.restore_destructed(Part);
					end;
				end);
			end;
		end);
		
		task.delay(6, function()
			if Touched.Connected then
				Rock:Destroy();
			end;
		end);
	end);
	
	self.Maid:add(Rock);
	
	return Rock;
end

function MeatyMeteor:CreateHitbox(Coordinate: CFrame, Radius: number)
	-- Larger but less deadly hitbox
	local Params = SphereHitbox.NewParams();
	Params.Size = Radius + 50;

	local Hitbox = SphereHitbox.new(Coordinate, Params)

	Hitbox.Events.HumanoidHit:Connect(function(Humanoid : Humanoid)
		local VictimLuaPlayer = LuaPlayerList.Get(Humanoid);

		if VictimLuaPlayer then 
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			VictimLuaCharacter.Humanoid:TakeDamage(17)

			local VelocityObject = VictimCombat:Velocity()
			VelocityObject.Settings.FixScale = true;
			VelocityObject.Settings.RemoveTime = 0.15
			VelocityObject.Settings.Velocity = ((VictimLuaCharacter.RootPart.Position - Coordinate.Position) * Vector3.new(1, 0, 1)).Unit * 70 + Vector3.yAxis * 50;
			VelocityObject:Fire();
			
			VictimCombat.Ragdoll:Toggle(true, 2);
			VictimCombat:ImpactOnGroundHit();
		end;
	end);

	Hitbox:Detect()
	task.defer(Hitbox.Destroy, Hitbox);
	
	local Params = SphereHitbox.NewParams();
	Params.Size = Radius;

	local Hitbox = SphereHitbox.new(Coordinate, Params)

	Hitbox.Events.HumanoidHit:Connect(function(Humanoid : Humanoid)
		local VictimLuaPlayer = LuaPlayerList.Get(Humanoid);

		if VictimLuaPlayer then 
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			VictimLuaCharacter.Humanoid:TakeDamage(29)

			local VelocityObject = VictimCombat:Velocity()
			VelocityObject.Settings.FixScale = true;
			VelocityObject.Settings.RemoveTime = 0.3
			VelocityObject.Settings.Velocity = ((VictimLuaCharacter.RootPart.Position - Coordinate.Position) * Vector3.new(1, 0, 1)).Unit * 125 + Vector3.yAxis * 160;
			VelocityObject:Fire();

			VictimCombat.Ragdoll:Toggle(true, 4);
		end;
	end);

	Hitbox:Detect()
	task.defer(Hitbox.Destroy, Hitbox);
end;

function MeatyMeteor:End(Result)
	if not self.Active then return end;
	
	if Result == "NoBoss" then
		self.System.EventUtility:Announce(self.Settings.Display, `Mysteriously, no one seemed to stumbled upon the meteor site ...`)
		
	elseif Result == "OutOfTime" then
		self.System.EventUtility:Announce(self.Settings.Display, `No one defeated {self.Boss:GetAttribute("Name")} in time, and have fallen victim to the steak.`)
		
	elseif Result == "EventEnded" then
		self.System.EventUtility:Announce(self.Settings.Display, `The event was ended.`);
		
	elseif self.Boss then
		self.System.EventUtility:Announce(self.Settings.Display, `The Earth has defeated {self.Boss:GetAttribute("Name")}, and everyone's eyes were saved.`)
	end
	
	BaseEvent.End(self, Result);
end

return MeatyMeteor