local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local MichaelEnemy = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.List["Meaty Michael"]["Helping Hand"].MichaelEnemy )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end;

function Attack:Initialise()
	BaseAttack.Initialise(self);

	if self.Combat.IsMeatyMichaelFromWorldEvent then
		self:ChangeDisplay("Meaty's Embrace");
	end;
end;

function Attack:Activate()
	self.Combat:StackState("GrabIFrames", true)
	self.Combat:StackState("Attacking", true)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(20)
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("GrabIFrames", false)
	end)
	
	local Character = self.LuaCharacter.Model;
	local Humanoid = self.LuaCharacter.Humanoid;
	local RootPart = self.LuaCharacter.RootPart;
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Step"):Connect(function(Foot: string)
		local Limb = Character:FindFirstChild(`{Foot} Leg`);
		local Attachment = if Limb then Limb:FindFirstChild(`{Foot}FootAttachment`) else nil;
			
		if Attachment then
			self:FireReliableVFX("Meaty Michael/Drake's Embrace", "Footstep", Attachment);
		end
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("StepBack"):Once(function()
		self.Animations.Windup:AdjustSpeed(2);
		self:FireReliableVFX("Meaty Michael/Drake's Embrace", "StepBack", Character);
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Land"):Once(function()
		self:FireReliableVFX("Meaty Michael/Drake's Embrace", "Land", RootPart);
		self.Animations.Windup:AdjustSpeed(1.75);
		
		local Origin = RootPart.CFrame;
		
		local Hitbox = self:CreateHitbox(true, true);
		Hitbox.Adornee = Origin.Position;
		Hitbox.Params.Size = 40

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			self:Afflict(VictimLuaPlayer, {
				Damage = 15,
				BreakBlock = true,
				Ragdoll = 5,
				Velocity = {(VictimLuaCharacter.RootPart.Position - Origin.Position).Unit  * 100 + Vector3.yAxis * 35, 0.25}
			})
			
			self:FireReliableVFX("Meaty Michael/Drake's Embrace", "Charmed", VictimLuaCharacter.RootPart);
			
			if math.random(0, 6) == 0 then
				local whip = MichaelEnemy.new(self, Origin * CFrame.new(0, math.random(35, 40), 0));

				task.delay(30, function()
					whip:leave();
				end)
			end
			-- Make it spawn one meaty michael enemy for every person hit 😈 -- i gotchu
		end)

		Hitbox:Detect()

		task.defer(function()
			Hitbox:Destroy()
		end)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Jump"):Once(function()
		self:FireReliableVFX("Meaty Michael/Drake's Embrace", "Jump", RootPart, self.Combat.IsMeatyMichaelFromWorldEvent);
		self.Animations.Windup:AdjustSpeed(0.2);

		local Connection; Connection = self.Combat.ClientLanded:Connect(function()
			Connection:Disconnect();
			self.Animations.Windup:AdjustSpeed(5);
		end)
		
		self.Thread.Job:Task(Connection);
		
		self.Thread.Job:Task(task.delay(0.5, function()
			if Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
				Connection:Disconnect();
				self.Animations.Windup:AdjustSpeed(5);
			end
		end))
	end))

	self.Animations.Windup.Stopped:Wait()
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {
		FadeTime = 0.2,
		Speed = 1.5
	}

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack