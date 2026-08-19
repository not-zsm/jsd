-- Ultra basic AI that walks forward and attacks.
-- You dont need some crazy behaviour trees because imma be frank, i cannot be arsed

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Unpacker = require( "./Unpacker" );
local Maid = require( Unpacker.Packages.Maid );
local Signal = require( Unpacker.Packages.Signal );
local Navigate = require( script.Navigate )
local Sensor = require( script.Sensor )

local BuildShared = ReplicatedStorage:WaitForChild("BuildTools");
local Remotes = BuildShared.Remotes;

local XZ_Plane = Vector3.new(1, 0, 1);

local AI = {};
AI.__index = AI;
AI.list = {};

function AI.new(humanoid: Humanoid)
	if AI.list[humanoid] then
		error(`An AI is already using humanoid '{humanoid:GetFullName()}'`);
	end
	
	local rig = humanoid.Parent;
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			humanoid = humanoid;
			root = rig:FindFirstChild("HumanoidRootPart");
			torso = rig:FindFirstChild("Torso");
			rig = rig;
			maid = maid;
			
			target = nil;
			range = 200;
			attack_range = 12;
			attack_speed = 1;
			standback_range = 3;
			death_cleanup = 2;
			modifier_affected = true;
			is_dead = false;
			animations = {};
			
			look_at_target = false;
			attack_debounce = false;
			gyro = Instance.new("AlignOrientation");
			
			on_attack = maid:add(Signal.new());
		}, 
		AI);
	
	self.sensor = Sensor.new(self);
	self.navigate = Navigate.new(self);
	
	task.defer(function()
		self:initialise();
	end);
	
	return self;
end;

function AI:initialise_animations()
	if self.rig:FindFirstChild("Animations") then
		for _, animation: Animation in self.rig.Animations:GetChildren() do
			self.animations[animation.Name] = self.humanoid.Animator:LoadAnimation(animation) :: AnimationTrack;
		end
	end
	
	if self.animations.Idle then
		self.animations.Idle:Play();
	end;
	
	if self.animations.Run then
		local track_speed = self.animations.Run.Animation:GetAttribute("Speed") or 1;
		local track_weight = self.animations.Run.Animation:GetAttribute("Weight") or 1;

		self.maid:add(self.humanoid.Running:Connect(function(speed)
			if not self.animations.Run then return end;
			
			if speed > 0.1 then
				if not self.animations.Run.IsPlaying then
					self.animations.Run:Play(0.25, track_weight, track_speed);
				end
			else
				if self.animations.Run.IsPlaying then
					self.animations.Run:Stop(0.25);
				end
			end
		end))
	end;
end

function AI:initialise()
	self.navigate:create_path({
		AgentRadius = 3,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = true,
	})
	self.root.Anchored = false;
	
	self.humanoid:AddTag("EntityAI");
	self.humanoid.AutoRotate = false;
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false);
	
	self.gyro.Name = "RotateFacingGyro"
	self.gyro.AlignType = Enum.AlignType.AllAxes ;
	self.gyro.Mode = Enum.OrientationAlignmentMode.OneAttachment;
	self.gyro.Attachment0 = self.root.RootAttachment;
	self.gyro.RigidityEnabled = false;
	self.gyro.Responsiveness = 25;
	self.gyro.Parent = self.root;
	
	if self.humanoid:IsDescendantOf(workspace) then
		self:initialise_animations();
	else
		local connection; connection = self.maid:add(self.rig.AncestryChanged:Connect(function(_, parent)
			if self.humanoid:IsDescendantOf(workspace) then
				self.maid:delete(connection);
				self:initialise_animations();
			end;
		end))
	end
	
	self.maid:add(self.root.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:destroy();
		end;
	end));
	
	self.gyro.MaxTorque = self:get_assembly_mass() * 1_000;
	
	self.maid:add(RunService.PreSimulation:Connect(function(dt: number)
		local gyro_enabled = self:get_gyro_enabled();
		local rigidity_enabled = false;
		local target_direction: Vector3?;
		
		if self.look_at_target and self.sensor.root and self.sensor.root.Position ~= self.root.Position then
			target_direction = (self.sensor.root.Position - self.root.Position) * XZ_Plane;
		else
			target_direction = self.root.AssemblyLinearVelocity * XZ_Plane
		end;
		
		if target_direction then
			local unit_direction = target_direction.Unit;
			
			if unit_direction == unit_direction and target_direction ~= Vector3.zero then
				self.gyro.CFrame = CFrame.lookAlong(Vector3.zero, unit_direction);
			end;
		end;
		
		if self.combat and self.combat:GetState("Grabbing") then
			self.gyro.Responsiveness = 1;
			rigidity_enabled = true;
			
		elseif self.attack_replacer and self.attack_replacer:ThreadAvailable() then
			self.gyro.Responsiveness = 50;
		else
			self.gyro.Responsiveness = 25;
		end;
		
		self.gyro.RigidityEnabled = rigidity_enabled;
		self.gyro.Enabled = gyro_enabled;
	end))
	
	self.maid:add(task.spawn(function()
		while task.wait(0.1) do
			task.spawn(self.update_loop, self);
		end
	end))
	
	task.defer(function()
		local function on_died()
			if self.is_dead then return end;

			self.is_dead = true;
			task.delay(self.death_cleanup, self.destroy, self);
		end;
		
		if self.lua_player then
			self.maid:add(self.lua_character.OnHumanoidDied:Connect(on_died))
		else
			self.maid:add(self.humanoid.Died:Connect(on_died))
		end
	end)
	
	AI.list[self.humanoid] = self;
end;

function AI:get_gyro_enabled(): boolean
	return not self.humanoid.PlatformStand;
end

function AI:get_assembly_mass(): number
	local assembly_mass = 0;

	for _, child in self.rig:GetDescendants() do
		if child:IsA("BasePart") then
			assembly_mass += child:GetMass();
		end
	end
	
	return assembly_mass;
end

function AI:update_loop()
	if self.is_dead then return end;
	
	if self.torso then
		self.torso.CanCollide = false;
	end;
	
	self.root.CanCollide = true;
	
	-- Stop it !!! stop it now !!!
	if self.root:CanSetNetworkOwnership() then
		self.root:SetNetworkOwner(nil);
	end;
	
	self.sensor:search();
	
	self:update_running();
	self:update_attacking();
end

function AI:destroy()
	self.maid:destroy();
	self.rig:Destroy();
	
	AI.list[self.humanoid] = nil;
end

function AI:get_position(): Vector3
	return self.root.Position;
end

function AI:attack()
	if self.attack_replacer then
		self.attack_replacer:Trigger(true);
		
		if self.attack_replacer.Name == "Tectonic Control" then
			task.delay(1.5, function()
				-- Force Blink Strike to happen 💔🌹
				if not self.attack_replacer:ThreadAvailable() and self.attack_replacer.Variant then
					self.attack_replacer:Trigger(true);
				end;
			end);
			
		elseif self.attack_replacer.Name == "Meaty Michael Slap" then
			task.delay(1.25, function()
				if self.attack_replacer.VariantPhase or self.attack_replacer.ForceVariant then
					self.attack_replacer:Tung()
				end;
			end);
		end
	end;
	
	self.attack_debounce = true;
	
	task.delay(self.attack_speed, function()
		self.attack_debounce = false;
	end);
end

function AI:update_attacking()
	if self.combat then
		if self.sensor.root then
			local target_coordinate = CFrame.lookAlong(self.sensor.root.Position, self.sensor.root.Position - self.root.Position);
			
			self.combat.Mouse:Update(target_coordinate, self.sensor.rig);
		end;
		
		if self.combat:IsStunned() then
			return;
		end;
	end;
	
	if self.attack_debounce or not self.sensor:get_seen() or self.is_dead then return end;
	
	if self.sensor.humanoid and (self.sensor.root.Position - self.root.Position).Magnitude < self.attack_range then
		self.on_attack:Fire();
		self:attack();
	end
end

function AI:update_running()
	if self.sensor.humanoid then
		
		if self.sensor:get_seen(true) then
			self.look_at_target = true;
			self.navigate:walk_to( self.sensor:get_position(Vector3.one * -self.standback_range) );
		else
			self.look_at_target = false;
			
			if self.navigate:get_time_since_last_path_to() > 2 then
				self.navigate:path_to( self.sensor:get_position(Vector3.zero) );
			end;
		end;
	else
		self.look_at_target = false;
		self.navigate:stop_walking();
	end
end

table.freeze(AI);

return AI;