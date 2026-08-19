local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )

local Destruction = require( ServerScriptService.Scripts.Game.Modules.Destruction )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

local function FindAncestorHumanoidModel(Part : BasePart)
	if (Part.Parent == nil) then
		return
	end

	if not Part.Parent:FindFirstChildWhichIsA("Humanoid") then 
		return FindAncestorHumanoidModel(Part.Parent)
	else
		return Part, Part.Parent
	end
end

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not self:HasCertainCooldown("AntiStuck")
end

function Attack:Pretrigger(Extra, State : boolean)
	if (State == nil or State == true) then
		self.CancelEvent:Fire()
	end
end

function Attack:Activate()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(self.SpeedDecrease)
	
	self.Combat.Mouse:BeginRequesting(nil, "Default")
	
	local ReplicateLaser : RemoteEvent = self.Thread.Job:Task(Instance.new("UnreliableRemoteEvent"));
	ReplicateLaser.Name = "ReplicateLaser";
	ReplicateLaser.Parent = self.LuaCharacter.Model;
	
	self.Thread.OnClosed:Connect(function()
		self:AddCertainCooldown("AntiStuck", 0.2)
		self:AddCooldown(self.Cooldown)
		
		self.Animations.Loop:Stop()

		self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName, {
			FlashColor = Color3.fromRGB(255, 255, 255),
			Tip = ""
		})
		
		self.Combat.Mouse:EndRequesting()

		self.Combat:TimesSpeed(self.SpeedDecrease)
		self.Combat:StackState("Attacking", false)
	end)

	self:FireReliableVFX("Powers/Solar Vision", "Start", self.LuaCharacter.Model)
	
	self.Animations.Windup:GetMarkerReachedSignal("Start"):Wait()

	local RayParams = RaycastParams.new()
	RayParams.FilterDescendantsInstances = {workspace.Visuals, self.LuaCharacter.Model}
	RayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local Head : BasePart = self.LuaCharacter.Head
	local HavocElapsed = 0;
	
	self.Thread.Job:Task(RunService.PreSimulation:Connect(function(Delta: number)
		HavocElapsed += Delta;
		
		local MouseHit : CFrame = self.Combat.Mouse.Hit
		local Origin = Head.Position

		local Direction = (MouseHit.Position - Origin) * 1.1
		local RayResult = workspace:Raycast(Origin, Direction, RayParams)
		
		if RayResult and RayResult.Instance then
			if HavocElapsed > 0.1 then
				HavocElapsed -= 0.1;
				
				self.Combat.Hitbox:CreateHavocReplicated({
					parameters = {
						origin = CFrame.new(RayResult.Position),
						size = Vector3.one * 1.5,
						radius = 1.5;
						shape = "Sphere", 
						block_size = 3, 
						seperate_islands = true;
					},
					debris = { scale = 0.95 },
				})
			end;
			
			local _, Character = FindAncestorHumanoidModel(RayResult.Instance)
			
			if Character then
				local VictimLuaPlayer = LuaPlayerList.LuaPlayers[Character]

				if not VictimLuaPlayer then
					VictimLuaPlayer = LuaPlayerList.LuaPlayers[Players:GetPlayerFromCharacter(Character)]
				end

				if VictimLuaPlayer then
					self:Afflict(VictimLuaPlayer, {
						TriggerActiveCounterOverOrEqualLevel = -1,
						DontCheckBlock = true,
						Damage = 0.2,
						Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 5, 0.1},
						TrueStun = 0.3,
						PlayRandomHitReaction = true
					})
				end
			end

			for _, Player in Players:GetPlayers() do
				if (Player ~= self.LuaPlayer.Player) then
					ReplicateLaser:FireClient(Player, RayResult.Position)
				end
			end
		end
	end))

	self.Animations.Windup:Stop(0)
	self.Animations.Loop:Play(0)

	self.Thread.Job:Task(self.CancelEvent:Once(function()
		self:Close()
	end))

	self.Combat:ChangeAttackDisplay(self.Name, "Stop", {
		FlashColor = Color3.fromRGB(255, 31, 15),
		Tip = "[PRESS AGAIN]"
	})
	
	self.Thread.Job:Task(task.delay(self.MaxDuration, self.Close, self))
	
	self:FireReliableVFX("Powers/Solar Vision", "Loop", ReplicateLaser, self.LuaCharacter.Model, self.Combat.Mouse.Hit.Position)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.TryToCancelMoves = false
	self.CancelEvent = EventService.new()
	
	self.MaxDuration = 3
	self.Cooldown = 40
	self.SpeedDecrease = 2

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack