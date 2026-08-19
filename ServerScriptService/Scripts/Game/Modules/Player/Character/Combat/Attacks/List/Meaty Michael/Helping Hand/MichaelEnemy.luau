local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )
local AenoirEmit = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.AenoirEmit )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Assets = script.Assets;

local MichaelEnemy = {};
MichaelEnemy.__index = MichaelEnemy;

function MichaelEnemy.new(attack: any, coordinate: CFrame, properties)
	if not properties then properties = {}; end;
	
	local job = Job.new();
	local steak = Assets[properties.Steak or "Steak"]:Clone();
	
	local self = setmetatable(
		{
			job = job;
			steak = steak;
			humanoid = steak.Humanoid;
			root = steak.HumanoidRootPart;
			linear_velocity = steak.HumanoidRootPart.LinearVelocity;
			linear_gyro = steak.HumanoidRootPart.AlignOrientation;
			
			can_shoot = true;
			is_shooting = false;
			
			attack_debounce = false;
			target = nil;
			origin = coordinate;
			attack = attack;
			
			speed = 90;
			laser_chance = 0.25;
			laser_block_angle = math.rad(90);
			laser_effect_properties = properties.LaserEffectProperties;
			
			attack_range = 8;
			attack_tick = 0.5;
			attack_pushback_power = 250;
			attack_block_angle = math.rad(180),
			attack_effect_properties = properties.AttackEffectProperties;
			
			damage_multiplier = 1;
			search_tick = 0.5;
			y_power = 50;
		}, 
		MichaelEnemy);
	
	self:initialise();
	
	return self;
end;

function MichaelEnemy:update_step(dt: number)
	local direction = if self.target then (self.target.Character.RootPart.Position - self.root.Position) else Vector3.zero -- michael enemy 😭😭😭😭 all scripted by aenoir fire
	local unit_direction = if direction.Magnitude < 0.001 then Vector3.zero else direction.Unit;
	
	self.linear_gyro.CFrame = CFrame.lookAlong(Vector3.zero, direction);
	self.linear_velocity.VectorVelocity = unit_direction * self.speed + Vector3.yAxis * self.y_power * (if not self.target then 0 else 1);

	if self.target and not self.attack_debounce and direction.Magnitude < self.attack_range then
		self.attack_debounce = true;

		task.delay(self.attack_tick, function()
			self.attack_debounce = false;
		end);

		self.attack.LuaPlayer.Replication:FireReliableVFX("Meaty Michael/Heed My Call", "SteakEat", self.target.Character.RootPart.RootAttachment, self.attack_effect_properties);
		self.root.AssemblyLinearVelocity += -direction.Unit * self.attack_pushback_power;
		
		self.attack.Combat:Afflict(self.target, {
			BlockAngle = self.attack_block_angle,
			Damage = 2 * self.damage_multiplier,
			Ragdoll = 1,
			Velocity = {direction.Unit * 100 + Vector3.yAxis * 50, 0.4}
		})
	end
end

function MichaelEnemy:initialise_search()
	self.searcher = self.attack.Combat.Hitbox:Create(true)
	self.searcher.Adornee = self.root;
	self.searcher.Params.Sorting = "Nearest"
	self.searcher.Params.MaxTargets = 5
	self.searcher.Params.Size = 300

	local last_detection = -1;
	
	self.searcher.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local time_now = tick();
		
		if time_now - last_detection < 0.1 then return end;
		
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		if not VictimCombat:Has_IFrames() then
			last_detection = time_now;
			
			self.target = VictimLuaPlayer;
			self.target_attachment = VictimLuaCharacter.RootPart.RootAttachment;
			self.linear_gyro.Attachment1 = self.target_attachment;
		end;
	end)
	
	self:search();

	while task.wait(self.search_tick) do
		self:search();
		
		if self.can_shoot and not self.is_shooting and math.random() < self.laser_chance then
			self:shoot()
		end

		if math.random(0, 8) == 0 then
			self.attack.LuaPlayer.Replication:FireReliableVFX("Meaty Michael/Heed My Call", "SteakLaugh", self.root);
		end
	end
end

function MichaelEnemy:shoot()
	if not self.target then return end;

	local speed = 600;

	local target = self.target;
	local target_attachment = self.target_attachment;
	local torso = self.steak.Torso;
	local right_eye, left_eye = torso.RightEye, torso.LeftEye;

	self.attack.LuaPlayer.Replication:FireReliableVFX("Meaty Michael/Heed My Call", "LaserShoot", self.steak, target_attachment, self.laser_effect_properties);
	self.shoot_animation:Play(0.6, 1, 1);

	task.delay(0.75, function()
		self.is_shooting = false;

		local direction = (target_attachment.WorldPosition - torso.Position);
		local origin = right_eye.WorldPosition:Lerp(left_eye.WorldPosition, 0.5);
		local result = workspace:Raycast(origin, direction.Unit * 1000, Utility.VisualParams);
		local cframe_hit = CFrame.lookAlong(target_attachment.WorldPosition, Vector3.yAxis);

		if result then
			cframe_hit = CFrame.lookAlong(result.Position, result.Normal);
		end;

		self.attack.LuaPlayer.Replication:FireReliableVFX("Meaty Michael/Heed My Call", "LaserFire", self.steak, cframe_hit, self.laser_effect_properties);
		
		local direction_hit = (origin - cframe_hit.Position);
		task.wait(direction_hit.Magnitude / speed);
		
		local hitbox = self.attack.Combat.Hitbox:Create(true)
		hitbox.Adornee = cframe_hit.Position;
		hitbox.Params.Offset = CFrame.identity
		hitbox.Params.Size = 12
		hitbox.Params.TrySorting = false

		hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			self.attack.Combat:Afflict(VictimLuaPlayer, {
				Damage = 4 * self.damage_multiplier,
				BlockAngle = self.laser_block_angle,
			})
		end)
		
		hitbox:Detect();
		
		task.defer(function()
			hitbox:Destroy();
		end)
	end)

	self.is_shooting = true;
end

function MichaelEnemy:initialise()
	self.job:Task(RunService.PreSimulation:Connect(function(dt)
		self:update_step(dt);
	end))
	
	self.linear_gyro.Attachment1 = self.linear_gyro.Attachment0;
	self.steak:PivotTo(self.origin);
	self.root.Massless = true;
	self.steak.Name = "SteakWhip";
	self.steak.Parent = workspace.Terrain;
	
	if self.attack.LuaPlayer.Player:IsA("Player") then
		self.root:SetNetworkOwner(self.attack.LuaPlayer.Player);
	else
		self.root:SetNetworkOwner(nil);
	end;
	
	self.shoot_animation = self.humanoid.Animator:LoadAnimation(Assets.Shoot);
	self.idle_animation = self.humanoid.Animator:LoadAnimation(Assets.Idle);
	self.idle_animation:Play(0, 1, 0.85 + math.random() * 0.25);

	self.job:Task(task.defer(self.initialise_search, self))
end

function MichaelEnemy:leave()
	task.delay(2.5, function()
		self:destroy();
	end)
	
	self.can_shoot = false;
	self.y_power = 1000;
	self.linear_gyro.Enabled = false;
	self.idle_animation:Stop();
end

function MichaelEnemy:destroy()
	self.target = nil;
	
	self.steak:Destroy();
	self.job:Destroy()
	
	self.searcher:Destroy();
end

function MichaelEnemy:search()
	self.searcher:Reset()
	
	self.target = nil;
	self.target_attachment = nil;
	self.linear_gyro.Attachment1 = nil;
	self.linear_velocity.VectorVelocity = Vector3.zero;

	self.searcher:Detect();
end

table.freeze(MichaelEnemy);

return MichaelEnemy;