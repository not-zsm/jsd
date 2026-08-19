-- Ultra basic AI that walks forward and attacks.
-- You dont need some crazy behaviour trees because imma be frank, i cannot be arsed

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Unpacker = require( "../../Unpacker" );
local Table = require( Unpacker.Packages.Table );
local Maid = require( Unpacker.Packages.Maid );
local Type = require( Unpacker.Packages.Type );
local Instances = require( Unpacker.Packages.Instances );
local Observer = require( Unpacker.Packages.Observer );
local Signal = require( Unpacker.Packages.Signal );
local Attributes = require( Unpacker.Packages.Attributes )

local Effects = Unpacker.Effects;
local Remotes = Unpacker.Remotes;

local BaseAI = require(script.Parent.Parent);

local AI = setmetatable({}, BaseAI);
AI.__index = AI;

function AI.new(humanoid: Humanoid)
	local self = setmetatable(BaseAI.new(humanoid), AI);
	
	self.attack_range = 35;
	self.standback_range = 15;
	
	return self;
end;

function AI:initialise()
	BaseAI.initialise(self);
	self.animations.Attack.Looped = false;
end

function AI:attack()
	self.attack_debounce = true;
	
	task.delay(2.50, function()
		self.attack_debounce = false;
	end);
	
	self.animations.Attack:Play(0.2, 1, 1.5);
	
	Remotes.Effects.SpawnEffects:FireAllClients(Effects.PineappleJump, self.root);
	
	self.animations.Attack:GetMarkerReachedSignal("Attack"):Once(function()
		Remotes.Effects.SpawnEffects:FireAllClients(Effects.PineappleSlam, CFrame.new((self.root.CFrame * CFrame.new(0, -2.5, -18)).Position) * CFrame.Angles(math.rad(90), 0, 0));
		
		if self.sensor.combat then
			self.sensor.combat:damage_by_builder(15);
		end
	end);
end

table.freeze(AI);

return AI;