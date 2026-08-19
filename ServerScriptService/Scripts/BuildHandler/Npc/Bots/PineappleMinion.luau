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

local Remotes = Unpacker.Remotes;

local BaseAI = require(script.Parent.Parent);

local AI = setmetatable({}, BaseAI);
AI.__index = AI;

function AI.new(humanoid: Humanoid)
	local self = setmetatable(BaseAI.new(humanoid), AI);
	
	self.standback_range = -5;
	self.humanoid.WalkSpeed *= 1 + math.random() * 0.2
	
	return self;
end;

function AI:attack()
	if self.sensor.combat then
		self.sensor.combat:damage_by_builder(4);
	end
	
	self.attack_debounce = true;
	
	task.delay(1.50, function()
		self.attack_debounce = false;
	end);
end

table.freeze(AI);

return AI;