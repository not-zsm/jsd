

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Modules.Player.Character.Combat.Attacks.BaseAttack )
local VelocityUtil = require( ReplicatedStorage.Shared.Game.Velocity.VelocityUtil )
local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

Attack.BasicConditions = nil

--function Attack:BasicConditions() : boolean
--	local Conditions = 
--		not self.Combat:GetState("Attacking") 
--		and not self.Combat:GetState("Backdashing") 
--		and not self.OnCooldown

--	return Conditions and not self.Combat:GetState(`Cannot{self.NameNoSpaces}`)
--end

function Attack:ConditionToActivate()
	local Conditions = not self.Combat:GetState(`Cannot{self.NameNoSpaces}`)
		and not self.Combat:GetState("Attacking") 
		and not self.Combat:GetState("WallComboed")
		and not self.Combat:GetState("Grabbed")
		and not self.Combat:GetState("Blocking")
		and not self.Combat:GetState("Backdashing") 
		and not self.OnCooldown
		
	return Conditions
end

function Attack:Activate()
	self.Hit = false
	
	local ResetGrabIFrames = false
	local ResetBackdashIFrames = true
	
	if self.Combat:GetState("Ragdolled") then
		self.Combat.Ragdoll:Toggle(false)
	end

	self.Combat:StackState("BackdashIFrames", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)
	
	local Hitbox = self:CreateHitbox(true)
	Hitbox.Params.Offset = CFrame.new(0, 0, -2)
	Hitbox.Params.Size = 20
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontCheckBlock = true,
			Damage = 0.6,
			TrueStun = 0.6,
			DontRestartRespawnTimer = true,
			PlayRandomHitReaction = true,
			Velocity = {self.Combat:GetSimulatedRoot().CFrame.LookVector * 15, 0.015}
		})
		
		task.delay(0.05, function()
			Hitbox:RemoveHumanoid(VictimLuaCharacter.Humanoid)
		end)
	end)
	
	local EndHitbox = self:CreateHitbox(true)
	EndHitbox.Params.Offset = CFrame.new(0, 0, -2)
	EndHitbox.Params.Size = 22.5
	EndHitbox.Params.DestroyOnEndCast = false

	EndHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontCheckBlock = true,
			Damage = 9,
			Ragdoll = 2,
			Velocity = {self.Combat:GetSimulatedRoot().CFrame.LookVector * 100 + Vector3.yAxis * 35, 0.025}
		})

		task.delay(0.05, function()
			Hitbox:RemoveHumanoid(VictimLuaCharacter.Humanoid)
		end)
	end)
	
	local Velocity
	
	if self.LuaPlayer.IsNPC then
		task.spawn(function()
			local Multiply = 0
			local Max = 30

			Velocity = VelocityUtil.Create(self.LuaCharacter.RootPart, "Shatter Slashes")
			Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
			Velocity.Parent = self.LuaCharacter.RootPart

			Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
				Multiply = math.min(Multiply + (Delta * 60) * 0.25, Max)
				Velocity.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * Multiply
			end)

			self.Thread.Job:Task(Velocity)
		end)
	end
	
	local DestructionLoop : RBXScriptConnection
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(15)
		
		self.Combat:TimesSpeed(50)
	
		if ResetBackdashIFrames then
			self.Combat:StackState("BackdashIFrames", false)
		end
		
		if ResetGrabIFrames then
			self.Combat:StackState("GrabIFrames", false)
		end

		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("slashes"):Connect(function(Type : string)
		if (Type == "true") then
			
			ResetBackdashIFrames = false
			self.Combat:StackState("BackdashIFrames", false)
			self.Combat:StackState("GrabIFrames", true)
			ResetGrabIFrames = true
			
			Hitbox:BeginCast()
			
			local Clock = os.clock()
			
			DestructionLoop = self.Thread.Job:Task(RunService.PostSimulation:Connect(function()
				if (os.clock() - Clock > 0.05) then
					local Position : Vector3 = Hitbox:GetPosition()
					
					self.Combat.Hitbox:SphereDestruction(Position, Hitbox.Params.Size, 3)
					
					self.Combat.Hitbox:CreateHavocReplicated({
						parameters = {
							origin = CFrame.new(Position),
							shape = "Sphere", 
							radius = Hitbox.Params.Size,
							block_size = math.max(3, Hitbox.Params.Size / 3), 
						},
						
						debris = {
							scale = 0.9,
							velocity_power = 150,
						},
					})
					
					Clock = os.clock()
				end
			end))
		else
			if DestructionLoop and DestructionLoop.Connected then
				DestructionLoop:Disconnect()
				DestructionLoop = nil
			end
			
			Hitbox:EndCast()
			ResetGrabIFrames = false
			self.Combat:StackState("GrabIFrames", false)
		end
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("burst"):Connect(function(Type : string)
		if Velocity then
			Velocity:Destroy()
		end
		
		EndHitbox:BeginCast(0.1)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Once(function()
		self:Close()
	end))
	
	self:FireReliableVFX("Chara/Shatter Slashes", "Start", self.LuaCharacter.Model)
end


function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.Hit = false
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack