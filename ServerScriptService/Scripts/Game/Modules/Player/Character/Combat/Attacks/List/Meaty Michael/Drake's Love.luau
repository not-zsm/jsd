local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

local function GetTriangle(Value: number): number
	local Triangle = 1;
	local N = 0;
	
	while Triangle <= Value do
		Triangle = N * (N + 1) / 2;
		N += 1;
	end
	
	return N - 1;
end

local function GetOffset(Value: number): CFrame
	local Scale = GetTriangle(Value);
	
	return CFrame.new((Value % Scale - (Scale - 1) / 2) * 12, Scale * 7.5, math.random(-15, 15))
end

local function GetTimeDistance(Origin: CFrame, Target: CFrame): number
	return (Target.Position - Origin.Position).Magnitude / 500;
end

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end;

function Attack:Initialise()
	BaseAttack.Initialise(self);
	
	if self.Combat.IsMeatyMichaelFromWorldEvent then
		self:ChangeDisplay("Meaty's Love");
	end;
end;

function Attack:Activate()
	self.Combat:StackState("GrabIFrames", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(20)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(20)
		
		self.Combat:TimesSpeed(20)
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("GrabIFrames", false)
	end)
	
	local function CupidBowHit(Target: CFrame)
		local BowHitbox = self:CreateHitbox(true, true);
		BowHitbox.Adornee = Target.Position
		BowHitbox.Params.Size = 24

		BowHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character

			self:Afflict(VictimLuaPlayer, {
				Damage = 2,
				Ragdoll = 0.75,
				Velocity = {(VictimLuaCharacter.RootPart.Position - Target.Position).Unit * 15 + Vector3.yAxis * 10, 0.1}
			})
		end)
		
		BowHitbox:Detect()

		task.defer(function()
			BowHitbox:Destroy()
		end)
	end
	
	local function CupidShoot(Origin: CFrame, Target: CFrame, CupidNum: number): ()
		Origin = Origin * GetOffset(CupidNum);
		Target = Target * CFrame.new(math.random(-5, 5), 0, math.random(-5, 5));
		
		self:FireReliableVFX("Meaty Michael/Drake's Love", "CupidShoot", self.LuaCharacter.Model, Origin, Target)
		
		task.delay(0.8 + GetTimeDistance(Origin, Target), function()
			local HitRay = workspace:Raycast(Origin.Position, (Target.Position - Origin.Position).Unit * 1000);
			local TargetHit = Target;

			if HitRay then
				TargetHit = TargetHit.Rotation + HitRay.Position
			end
			
			CupidBowHit(TargetHit);
		end)
	end
	
	self:FireReliableVFX("Meaty Michael/Drake's Love", "Charge", self.LuaCharacter.RootPart)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Swing"):Once(function()
		self:FireReliableVFX("Meaty Michael/Drake's Love", "Swing", self.LuaCharacter.RootPart)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Attack"):Once(function()
		local Origin = self.Combat:GetSimulatedRoot().CFrame
		
		self:FireReliableVFX("Meaty Michael/Drake's Love", "Attack", Origin * CFrame.new(0, 0, -3))
		self.Animations.Windup:Stop(0.75);
		
		local KissHitbox = self:CreateHitbox(false);
		KissHitbox.Params.Offset = CFrame.new(0, 0, -15)
		KissHitbox.Params.Size = vector.create(32, 20, 32)

		KissHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local RootPart = VictimLuaCharacter.RootPart;
			
			self:Afflict(VictimLuaPlayer, {
				Damage = 10,
				BreakBlock = true,
				Ragdoll = 2,
				Velocity = {Origin.LookVector * 25 + Vector3.yAxis * 40, 0.2}
			})
			
			-- Still get charmed even if you block it
			task.delay(0.5 + math.random() / 2, function()
				for Value = 1, 8 do
					local Coordinate = CFrame.new(RootPart.Position);

					CupidShoot(Coordinate + Vector3.new(0, 15, 0), Coordinate, Value)
					task.wait(0.1 + math.random() / 2)
				end;
			end)
			
			self:FireReliableVFX("Meaty Michael/Drake's Love", "Charmed", RootPart)
		end)
		
		KissHitbox:Detect()

		for Value = 1, 3 do
			CupidShoot(CFrame.new(Origin.Position), Origin * CFrame.new(math.random(-30, 30), 0, -30 + math.random(-30, 30)), Value)
			task.wait(0.1 + math.random() / 3)
		end;
	end));

	self.Animations.Windup.Stopped:Wait()
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	
	self.TryToCancelMoves = true
	self.AnimationSettings = {
		FadeTime = 0.2,
		Speed = 0.9
	}

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack