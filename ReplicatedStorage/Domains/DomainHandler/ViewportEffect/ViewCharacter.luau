local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Maid = require( ReplicatedStorage.Packages.Maid )
local Instances = require( ReplicatedStorage.Packages.Instances )

local ViewCharacter = {};
ViewCharacter.__index = ViewCharacter;

function ViewCharacter.new(base_viewport: any)
	local maid = Maid.new()
	
	local self = setmetatable(
		{
			maid = maid;
			viewport = base_viewport;
			framerate = 240;
			motors = {};
			
			latency = 0;
			latency_buffer = {};
			_latency_pointer = 0;
			_updated_pointer = 0;
			
			is_afterimage = false;
		}, 
		ViewCharacter);
	
	self:initialise();
	
	return self;
end;

function ViewCharacter:initialise()
	local frame_elapsed = math.random();
	
	--self.maid:add(RunService.PreAnimation:Connect(function(dt)
	--	frame_elapsed += dt;

	--	local frames = 1 / self.framerate;

	--	if frame_elapsed > frames then
	--		frame_elapsed = frame_elapsed - frames;
			
	--		if self.is_afterimage then
	--			self.viewport.ImageTransparency = 0.925;
	--			TweenService:Create(self.viewport, TweenInfo.new(1, Enum.EasingStyle.Cubic), {ImageTransparency = 1}):Play()
	--		end;
			
	--		self:step(dt);
	--	end;
	--end));
end

function ViewCharacter:step(dt: number)
	if self.latency > 0 then
		local max_transform = (self.framerate * self.latency);
		local pointer = self._updated_pointer;
		
		self._updated_pointer = math.floor(pointer % max_transform + 1);
		self._latency_pointer = math.floor((pointer - max_transform / 2) % max_transform + 1);
		
		local transforms = self.latency_buffer[self._updated_pointer];
		
		if not transforms then
			transforms = {};
			self.latency_buffer[self._updated_pointer] = transforms;
		end;
		
		for char_motor, view_motor in self.motors do
			transforms[view_motor] = char_motor.Transform;
		end;
		
		local delayed_transforms = self.latency_buffer[self._latency_pointer]
		
		if delayed_transforms then
			for view_motor, transform in delayed_transforms do
				view_motor.Transform = transform;
			end;
		end;
	else
		for char_motor, view_motor in self.motors do
			view_motor.Transform = char_motor.Transform;
		end;
	end;
end;

function ViewCharacter:load_animation(animation)
	local track = self.view_character.Humanoid.Animator:LoadAnimation(animation);
	
	return track;
end

function ViewCharacter:destroy()
	if self.destroyed then return end;
	
	self:remove_character();
	self.maid:destroy();
	
	table.clear(self);
	
	self.destroyed = true;
end

function ViewCharacter:remove_character()
	if self.view_character then
		self.view_character:Destroy();
		self.view_character = nil;
	end;
end;

function ViewCharacter:apply_description(description: HumanoidDescription)
	if self.view_character then
		self.view_character.Humanoid:ApplyDescription(description);
	end;
end

function ViewCharacter:create_character(character: Model)
	self:remove_character();
	
	local archivable = character.Archivable;
	character.Archivable = true;
	
	self.view_character = character:Clone();
	
	character.Archivable = archivable;
	
	local humanoid = self.view_character:FindFirstChildOfClass("Humanoid");	
	humanoid.EvaluateStateMachine = false;
	humanoid.RequiresNeck = false;

	for _, child in self.view_character:GetDescendants() do
		if child:IsA("IKControl") then
			child:Destroy();

		elseif child:IsA("Motor6D") then
			local other_joint = character:FindFirstChild(child.Name, true);

			if other_joint and other_joint:IsA("Motor6D") then
				self.motors[other_joint] = child;
			end;
			
		elseif child:IsA("LuaSourceContainer") then
			child:Destroy();

		elseif child:IsA("Animator") then
			child:Destroy();
		end;
	end;
	
	if not humanoid:FindFirstChildOfClass("Animator") then
		Instance.new("Animator", humanoid);
	end;
	
	self.view_character:PivotTo(CFrame.identity)
	self.view_character.Parent = self.viewport.WorldModel;
end

table.freeze(ViewCharacter);

return ViewCharacter;