local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

local function FloatForDummies(self)
	local RootPart = self.LuaCharacter.RootPart;
	local Raycast = workspace:Raycast(RootPart.Position, Vector3.yAxis * 45, Utility.VisualParams)
	local FloatPosition = nil

	if (Raycast ~= nil and Raycast.Instance.CanCollide) then
		FloatPosition = (RootPart.CFrame * CFrame.new(0, Raycast.Distance - 4, 0)).Position
	else
		FloatPosition = (RootPart.CFrame * CFrame.new(0, 45, 0)).Position
	end

	local BodyPosition = Instance.new("BodyPosition")
	BodyPosition.MaxForce = Vector3.one * 4e4
	BodyPosition.Position = FloatPosition
	BodyPosition.P = 4e4
	BodyPosition.Parent = RootPart
	
	task.delay(3, BodyPosition.Destroy, BodyPosition)
end;

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(10)

	self.Hit = false

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(11)
		
		self.Combat:TimesSpeed(10)
		self.Combat:StackState("Attacking", false)
	end)

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("float"):Once(function()
		self.Animations.Windup:AdjustSpeed(1);
		
		if self.LuaPlayer.IsNPC then
			FloatForDummies(self);
		else
			self:FireReliableVFX("Accelerator/Plasmic Degree", "Float", self.LuaCharacter.RootPart)
		end;
		
		local Hitbox = self:CreateHitbox(false);
		Hitbox.Adornee = self.LuaCharacter.RootPart.CFrame
		Hitbox.Params.Size = Vector3.new(30, 15, 30)
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			local Validated = self:Afflict(VictimLuaPlayer, {
				TriggerActiveCounterOverOrEqualLevel = 3,
				BreakBlock = true,
				Damage = 5,
				Ragdoll = 5,
				Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 47.5 + Vector3.yAxis * 75, 0.03}
			})
			
			if Validated then
				self.Combat:VictimImpactGround(VictimLuaPlayer);
				--VictimCombat:ImpactGroundOnHit()
			end
		end)
		
		Hitbox:BeginCast(0.05)
	end))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("handcharge"):Once(function()
		self:FireReliableVFX("Accelerator/Plasmic Degree", "Hand", self.LuaCharacter.RightArm)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("ball"):Once(function()
		self:FireReliableVFX("Accelerator/Plasmic Degree", "Ball", self.LuaCharacter.RootPart)
		
		self.Thread.OnClosed:Connect(function()
			self:FireReliableVFX("Accelerator/Plasmic Degree", "ThrowFail", self.LuaCharacter.RootPart)
		end)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("throw"):Once(function()
		local RootPart : BasePart =  self.LuaCharacter.RootPart
		local Raycast = workspace:Raycast(RootPart.Position, (RootPart.CFrame.LookVector + -RootPart.CFrame.UpVector) * 200, Utility.VisualParams)

		if (Raycast ~= nil) then
			self:FireReliableVFX("Accelerator/Plasmic Degree", "Throw", self.LuaCharacter.RootPart, Raycast.Position, Raycast.Instance.Color)

			task.delay(0.6, function()
				local Hitbox = self:CreateHitbox(false);
				Hitbox.Adornee = CFrame.new(Raycast.Position)
				Hitbox.Params.Size = Vector3.new(85, 30, 85)
				
				self.Combat.Hitbox:DestructionAt(Hitbox.Adornee, Hitbox.Params.Size)

				Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
					local VictimLuaCharacter = VictimLuaPlayer.Character
					local VictimCombat = VictimLuaCharacter.Combat

					local Validated = self:Afflict(VictimLuaPlayer, {
						TriggerActiveCounterOverOrEqualLevel = 3,
						DontBypassIFrames = {},
						BreakBlock = true,
						Damage = 17.5,
						Ragdoll = 3,
						Velocity = {Vector3.new(Utility.Seed:NextNumber(-35, 35), 100, Utility.Seed:NextNumber(-35, 35)), 0.03}
					})
					
					if Validated then
						self.Combat:VictimImpactGround(VictimLuaPlayer);
						--VictimCombat:ImpactGroundOnHit()
					end
				end)

				Hitbox:BeginCast(0.05)
			end)
		else
			self:FireReliableVFX("Accelerator/Plasmic Degree", "ThrowFail", self.LuaCharacter.RootPart)
		end
	end))
	
	self.Animations.Windup:GetMarkerReachedSignal("throw"):Wait()
	
	task.wait(0.6)
	
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	
	self.AnimationSettings = {
		FadeTime = 0.05,
		Weight = 1,
		Speed = 0.5
	}
	
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack