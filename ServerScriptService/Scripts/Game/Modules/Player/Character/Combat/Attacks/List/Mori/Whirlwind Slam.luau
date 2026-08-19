--[[
    © 2025 swrerm. All Rights Reserved.
    Author: swrerm
    Created: July 16, 2024
    Developed under the group: Jimpee's Cabin

    Licensed for use by Jimpee's Cabin only.
    Redistribution, resale, or unauthorized use of this code, 
    in whole or in part, without express permission from the author
    is strictly prohibited.

    This script is the original work of the author listed above.

    Contacts:
      wboyd4029@gmail.com
      jimpeeisbusiness@gmail.com
--]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Pretrigger(Extra : {}, State : boolean)
	if (State == nil) then
		State = true
	end
	
	if State and self.Launched then
		self.OnVariant:Fire()
	end
end

function Attack:Activate()
	self.Hit = false
	
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)

	local LaunchHitbox = self:CreateHitbox(true)
	LaunchHitbox.Params.Offset = CFrame.identity
	LaunchHitbox.Params.Size = self.AirDragon and 10 or 7
	LaunchHitbox.Params.DestroyOnEndCast = false
	
	local SlamHitbox = self:CreateHitbox(true)
	SlamHitbox.Params.Offset = CFrame.new(0, 0, -1.9)
	SlamHitbox.Params.Size = 7
	SlamHitbox.Params.DestroyOnEndCast = false

	local ImpactLand : RemoteEvent = self.Thread.Job:Task(Instance.new("RemoteEvent"))
	ImpactLand.Name = "ImpactLand"
	ImpactLand.Parent = self.LuaCharacter.Model
	
	local Landed = false
	
	local function DoImpact()
		self:Launch(false)
		SlamHitbox:Detect()
		
		task.wait(self.Hit and 0.2 or 1)

		if not self.TwinDragons then -- fixes the movestacking
			self:Close()
		end
	end

	LaunchHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat
		
		self:Afflict(VictimLuaPlayer, {
			BreakBlock = self.TwinDragons,
			Ragdoll = self.TwinDragons and 2.5 or 1.25,
			Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * (self.TwinDragons and 85 or 65) + Vector3.yAxis * (self.TwinDragons and 40 or 20), 0.05},
			Damage = 2.5
		})
	end)
	
	local function FireLaunchHitbox()
		local Root : BasePart = self.Combat:GetSimulatedRoot()

		local Raycast = workspace:Raycast(Root.Position, Vector3.yAxis * -50, Utility.VisualParams)
		local Distance = Raycast and Raycast.Distance or 0

		LaunchHitbox.Params.Offset = CFrame.new(0, -(Distance / 2), 0)
		LaunchHitbox:Detect()
	end
	
	SlamHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local ComboExtend = (VictimCombat:GetState("Ragdolled") and not LaunchHitbox:HumanoidBeenHit(VictimLuaCharacter.Humanoid))
		
		self.Hit = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
			Ragdoll = (not ComboExtend and 2 or nil),
			Velocity = (not ComboExtend and {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 10 + Vector3.yAxis * 75, 0.1} or nil),
			Damage = ComboExtend and 6.5 or 10
		})

		if self.Hit and ComboExtend then
			self.Combat:PushSkidVictim(VictimLuaPlayer, {
				TimeTilGroundDetection = 0.5,
				StartVelocityXZ = self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 25,
				StartVelocityY = Vector3.yAxis * 125,
				StartDuration = 0.8,
				LandedRollVelocityZ = 125,
				LandedRollDuration = 0.7875
			})
		end
	end)

	self.Thread.Job:Task(task.delay(0.57, function()
		self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")

		self.Thread.OnClosed:Connect(function()
			if not self.Combat:GetState("Grabbed") then
				self.LuaCharacter:SetCollisionGroup("Player")
			end
		end)

		FireLaunchHitbox()
		
		if self.LuaPlayer.IsNPC then
			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 0.3;
			VelocityObject.Settings.RemoveTime = 0.3;
			VelocityObject.Settings.MaxForce = Vector3.new(1, 1, 1) * 95000
			VelocityObject.Settings.Controllable = false
			VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.LookVector * 65 + Vector3.yAxis * 40;
			VelocityObject.Settings.DontScale = true;
			VelocityObject:Fire();
			
			self.Thread.Job:Task(self.LuaCharacter.Humanoid.StateChanged:Connect(function(old, new)
				if new == Enum.HumanoidStateType.Landed and not Landed then
					Landed = true;
					
					task.wait(0.25);
					DoImpact();
				end;
			end));
			
			self.Thread.Job:Task(task.delay(1.75, function()
				if Landed then return end;
				
				Landed = true;
				DoImpact();
			end))
		else
			ImpactLand.OnServerEvent:Connect(function(Player2)
				if (Player2 ~= self.LuaPlayer.Player or Landed) then return end

				Landed = true
				DoImpact()
			end)
		end;
	
		self.Thread.Job:Task(self.OnVariant:Connect(function()
			ImpactLand:Destroy()

			self.Launched = false
			self.TwinDragons = true

			--local AirLanded = false

			local Root : BasePart = self.Combat:GetSimulatedRoot()

			local AirSlamHitbox = self:CreateHitbox(true)
			AirSlamHitbox.Params.Size = 11
			AirSlamHitbox.Params.DestroyOnEndCast = false

			AirSlamHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local Validated self:Afflict(VictimLuaPlayer, {
					BreakBlock = true,
					Ragdoll = 2.75,
					Velocity = {Root.CFrame.LookVector * 75 + Vector3.yAxis * 35, 0.1},
					Damage = 14,--17.5,
				})
			end)

			local SlideHitbox = self:CreateHitbox()
			SlideHitbox.Params.Offset = CFrame.new(0, 0, -1)
			SlideHitbox.Params.Size = Vector3.new(5.5, 7, 10)
			SlideHitbox.Params.DestroyOnEndCast = false
			
			local PeopleWhoBlocked = {}
			
			self.Thread.OnClosed:Connect(function()
				table.clear(PeopleWhoBlocked)
			end)

			SlideHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local Validated, Type = self:Afflict(VictimLuaPlayer, {
					BlockAngle = math.rad(180),
					Velocity = {Root.CFrame.LookVector * 45 - Vector3.yAxis * 2.5, 0.06},
					Damage = 1,
				})
				
				if Type == "Blocked" then
					PeopleWhoBlocked[VictimLuaPlayer] = true
				end
				
				if Validated and not PeopleWhoBlocked[VictimLuaPlayer] and not VictimCombat:GetState("Ragdolled") then
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true;
						Ragdoll = 1;
					})
					
					VictimCombat:StackState("CannotDash", true, 1)
				end
				
				task.delay(0.1, SlideHitbox.RemoveHumanoid, SlideHitbox, VictimLuaCharacter.Humanoid)
			end)
			
			--local AirImpactLand : RemoteEvent = self.Thread.Job:Task(Instance.new("RemoteEvent"))
			--AirImpactLand.Name = "AirImpactLand"
			--AirImpactLand.Parent = self.LuaCharacter.Model
			
			--local function AirDoImpact()
			--	AirSlamHitbox:Detect()
			--end
			
			--LaunchHitbox:Reset()
			
			self.Animations.Air:Play()
			
			self.Thread.Job:Task(self.Animations.Air:GetMarkerReachedSignal("slide"):Once(function()
				SlideHitbox:BeginCast(1)
			end))

			self.Thread.Job:Task(self.Animations.Air:GetMarkerReachedSignal("shoot"):Once(function()
				local Raycast = workspace:Raycast(Root.Position + Vector3.yAxis * 1.25, Vector3.yAxis * -17.5, Utility.VisualParams)
				local Distance = Raycast and Raycast.Distance or 0

				AirSlamHitbox.Params.Offset = CFrame.new(0, -(Distance / 2), -2.279)
				AirSlamHitbox:Detect()
			end))

			--self.Thread.Job:Task(self.Animations.Air:GetMarkerReachedSignal("drop"):Connect(function(Parameter : string)
				--if (Parameter == "true") then
				--	AirImpactLand.OnServerEvent:Connect(function(Player2)
				--		if (Player2 ~= self.LuaPlayer.Player or AirLanded) then return end

				--		AirLanded = true
				--		AirDoImpact()
				--	end)
				--end
			--end))

			self.Thread.Job:Task(self.Animations.Air:GetMarkerReachedSignal("end"):Connect(function()
				self:Close()
			end))
			
			self.Thread.OnClosed:Connect(function()
				self.TwinDragons = false
			end)
			
			FireLaunchHitbox()
			self:FireReliableVFX("Mori/Whirlwind Slam Air", "Start", self.LuaCharacter.Model)
		end))
		
		self:Launch(true)
		
		self.Thread.OnClosed:Connect(function()
			self:Launch(false)
		end);
		
		if self.ForceVariant then
			self.OnVariant:Fire();
		end;
	end))

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(19)
		
		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
	end)
	
	self:FireReliableVFX("Mori/Whirlwind Slam", "Start", self.LuaCharacter.Model)
end

function Attack:Launch(Value : boolean)
	self.Launched = Value
	
	if Value then
		self.Combat:ChangeAttackDisplay(self.Name, "Mori Jin Original : Twin Dragons")
	else
		self.Combat:ChangeAttackDisplay(self.Name, self.DisplayName)
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.OnVariant = EventService.new()
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack