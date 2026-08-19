local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer;

local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )
local AenoirEmit = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.AenoirEmit )

local ViewportEffect = require("../ViewportEffect");
local Animations = ReplicatedStorage.Animations.Attacks.Walter["Candy Lab"]

local BaseDomain = require(script.Parent);

local CandyLab = setmetatable({}, BaseDomain);
CandyLab.__index = CandyLab;
CandyLab.resources = script;
CandyLab.size = 100;
CandyLab.music = script.Sounds.Music;

function CandyLab.new(...)
	local self = setmetatable(BaseDomain.new(...), CandyLab);
	
	return self;
end;

function CandyLab:transition()
	BaseDomain.transition(self);
	
end

function CandyLab:play_popup()
	local effect = ViewportEffect.new({
		viewport_animation = Animations.Windup,
		background_image = "rbxassetid://12871997361",
		character = self:get_character(),
	});
	effect:play();

	self.assets.Sounds.Danger:Play()
	task.wait(0.5);
	self.assets.Sounds.Cough:Play()
	
	task.wait(1.25);
	effect:stop();
end;

function CandyLab:create_world()
	local plane = self.model.World.Plane;
	local world = self.assets.Domain:Clone();
	world:PivotTo(plane:GetPivot() * CFrame.new(0, 7, 0));
	world.Parent = self.model.World;
	
	local elapsed = 0;
	local seed = math.random();
	
	self.maid:add(RunService.PreSimulation:Connect(function(dt)
		local origin = plane:GetPivot();
		
		elapsed += dt * 1;
		world.Hat:PivotTo( origin * 
			CFrame.Angles(math.rad(270) * math.noise(seed, elapsed * 0.01), math.rad(30) * elapsed + seed * 10, math.rad(42) * elapsed) * 
			CFrame.new(200, -100, 300) *
			CFrame.Angles(math.rad(43) * elapsed * 2, seed, -math.rad(17) * elapsed * seed) )
	end))
	
	for count = 1, 7 do
		local seed = math.random();
		local origin = plane:GetPivot();
		local wisp = self.assets.Attachments.Wisp:Clone();
		local elapsed = 0;
		
		local function update(dt: number)
			elapsed += dt * (1 + seed * 0.5);
			wisp.CFrame = ( origin * 
				CFrame.Angles(-math.rad(120) * elapsed * 1.5, math.rad(4) * elapsed + seed * 10, math.rad(5) * elapsed) * 
				CFrame.new(250, -150, 450) )
		end
		
		update(0);
		
		self.maid:add(RunService.PreSimulation:Connect(update));
		self.maid:add(wisp);
		
		wisp.Parent = workspace.Terrain;
	end
end;

function CandyLab:create_bubble(origin)
	BaseDomain.create_bubble(self, origin);
end;

table.freeze(CandyLab);

return CandyLab;