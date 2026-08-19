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
	
	self.Thread.OnClosed:Connect(function()
		self.Combat:StackState("Attacking", false);
		self.Combat:TimesSpeed(10);
		
		self:AddCooldown(30);
	end);
	
	local Paused = false;
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Pause"):Once(function()
		Paused = true;
		self.Animations.Windup:AdjustSpeed(0);
	end))
	
	task.wait(0.1);
	
	if not Paused then
		self.Animations.Windup:AdjustSpeed(1);
	end;
	
	local domain = DomainHandler:create("CandyLab", {
		owner = self.LuaPlayer.Player,
		origin = self.Combat:GetSimulatedRoot().CFrame - Vector3.yAxis * 3
	})
	
	self.Thread.OnClosed:Connect(function()
		if not domain.dome_active then
			domain:destroy();
		end;
	end);
	
	domain:play_popup();
	domain:spawn_wave();
	
	task.wait(0.95);
	domain:spawn_dome();
	
	for _, humanoid in domain:get_humanoids_in_dome() do
		local lua_player = LuaPlayerList.Get(humanoid);
		
		if lua_player and self.LuaPlayer ~= lua_player then
			lua_player.Character.Combat:TrueStun();
			
			domain.destroying:Once(function()
				lua_player.Character.Combat:Unstun();
			end)
		end;
	end;
	
	task.delay(1.25, function()
		if domain.maid.destroyed then return end;
		
		domain:engulf(self.LuaCharacter.Model)
		domain:engulf_in_dome()
	end)
	
	task.delay(12, function()
		domain:destroy()
	end);
	
	task.wait(1.25);
	self.Animations.Windup:Stop(0.25);
	task.wait(1.00);
	self:Close();
end;

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {
		FadeTime = 0.1,
		Speed = 0.6;
	};
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack