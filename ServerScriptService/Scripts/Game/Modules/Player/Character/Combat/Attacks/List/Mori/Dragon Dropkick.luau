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
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Hit = false
	
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(100)
	
	self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")

	self.Thread.OnClosed:Connect(function()
		if not self.Combat:GetState("Grabbed") then
			self.LuaCharacter:SetCollisionGroup("Player")
		end
		
		self:AddCooldown(18)
		
		self.Combat:TimesSpeed(100)
		self.Combat:StackState("Attacking", false)
	end)
	
	local Root : BasePart = self.Combat:GetSimulatedRoot()
	
	if self.LuaPlayer.IsNPC then
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 2.8
		VelocityObject.Settings.RemoveTime = 3.5
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 7;
		VelocityObject:Fire();
	end;
	
	local function Hit_Effect(VictimLuaPlayer, Type : string)
		VictimLuaPlayer.Replication:FireReliableVFX("Mori/Dragon Dropkick", "Hit_Effect", VictimLuaPlayer.Character.Model, Type)
	end
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		local Hitbox = self:CreateHitbox()
		Hitbox.Params.Offset = CFrame.new(0, 0, -4)
		Hitbox.Params.Size = Vector3.new(6, 5.5, 6.75)
		Hitbox.Params.DestroyOnEndCast = false

		local Hit = false
		
		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			Hit = self:Afflict(VictimLuaPlayer, {
				YDifferenceValue = -2,
				Damage = {Amount = 2, DontKill = true}
			})

			if Hit then
				local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Mori[script.Name].VictimPush)
				local FlingJob = Job.new()

				VictimCombat.Ragdoll:Toggle(false)
				VictimLuaCharacter.Model:PivotTo(self.Combat:GetSimulatedRoot().CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(0, math.pi, 0))

				VictimCombat:TrueStun()
				FlingJob:Task(VictimLuaCharacter:StopAutoRotate())

				local VelocityObject = self:VelocityOn(VictimCombat)
				VelocityObject.Settings.Duration = 0.975
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = -45
				VelocityObject:Fire()

				FlingJob:Task(VelocityObject)

				FlingJob:Task(VictimAnimation.Stopped:Once(function()
					FlingJob:Destroy()
					VictimCombat:Unstun()
				end))

				FlingJob:Task(VictimCombat.OnStateUpdated:Connect(function(StateChanged : any, Value : any)
					if (StateChanged == "Stunned" or StateChanged == "Ragdolled") and Value then
						VictimAnimation:Stop(0.3)
					end
				end))

				VictimAnimation:Play(0, 1, 1.35)
				VictimLuaPlayer.Replication:FireReliableVFX("Mori/Dragon Dropkick", "VictimPush", VictimLuaCharacter.Model)
				Hit_Effect(VictimLuaPlayer, "1")
			end
		end)
		
		Hitbox:Detect()
		
		task.defer(function()
			if Hit then
				self:SetUncancellable(true)
			end
			
			self.Thread.OnClosed:Connect(function()
				self:SetUncancellable(false)
			end)
			
			if self.Combat:GetState("Ragdolled") or self.Combat:GetState("Grabbed") then
				self:Cancel()
			else
				self.Thread.Job:Task(self.Combat:GetStateChanged("Ragdolled"):Connect(function(Value)
					if Value then
						self:Cancel()
					end
				end))

				self.Thread.Job:Task(self.Combat:GetStateChanged("Grabbed"):Connect(function(Value)
					if Value then
						self:Cancel()
					end
				end))
			end
		end)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("kick_down"):Once(function()
		local Hitbox = self:CreateHitbox()
		Hitbox.Params.Offset = CFrame.new(0, 0, -3.5)
		Hitbox.Params.Size = Vector3.new(6, 10, 8.5)
		Hitbox.Params.DestroyOnEndCast = false

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				Ragdoll = 2,
				Damage = {Amount = 1, DontKill = true},
				Velocity = {Root.CFrame.LookVector * 22.5 + Vector3.yAxis * -60, 0.1}
			})

			if Validated then
				self:FireReliableVFX("Global/M1", "Down Slam", VictimLuaCharacter.RootPart, "Mori")
				VictimLuaCharacter.Model:PivotTo(VictimLuaCharacter.RootPart.CFrame * CFrame.new(0, -0.5, 1) * CFrame.Angles(math.rad(-45), 0, 0))

				Hit_Effect(VictimLuaPlayer,  "2")
			end
		end)

		Hitbox:BeginCast(0.2)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("smack"):Once(function()
		local Hitbox = self:CreateHitbox()
		Hitbox.Params.Offset = CFrame.new(0, 0, -3.5)
		Hitbox.Params.Size = Vector3.new(6, 10, 8.5)
		Hitbox.Params.DestroyOnEndCast = false

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				Ragdoll = 1,
				Damage = {Amount = 1, DontKill = true},
				Velocity = {Root.CFrame.LookVector * 20, 0.1}
			})

			if Validated then
				Hit_Effect(VictimLuaPlayer, "3")
			end
		end)

		Hitbox:BeginCast(0.05)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("kick_up"):Once(function()
		local Hitbox = self:CreateHitbox()
		Hitbox.Params.Offset = CFrame.new(0, 0, -3.5)
		Hitbox.Params.Size = Vector3.new(6, 10, 8.5)
		Hitbox.Params.DestroyOnEndCast = false

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local Validated = self:Afflict(VictimLuaPlayer, {
				Ragdoll = 1.5,
				Damage = {Amount = 1, DontKill = true},
				Velocity = {Root.CFrame.LookVector * 25 + Vector3.yAxis * 51, 0.1} --15 --50
			})

			if Validated then
				Hit_Effect(VictimLuaPlayer, "4")
			end
		end)

		Hitbox:BeginCast(0.05)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("kick"):Once(function()
		self:FireReliableVFX("Mori/Dragon Dropkick", "Dropkick", self.LuaCharacter.Model)
		
		self.LuaCharacter.Head.CanCollide = false
		self.LuaCharacter.Torso.CanCollide = false
		
		self.LuaCharacter.RootPart.CanCollide = true

		self.Thread.OnClosed:Connect(function()
			self.LuaCharacter.Head.CanCollide = true
			self.LuaCharacter.Torso.CanCollide = true
			
			self.LuaCharacter.RootPart.CanCollide = false
		end)

		if self.LuaPlayer.IsNPC then
			local VelocityObject = self.Combat:Velocity()
			VelocityObject.Settings.Duration = 0.7
			VelocityObject.Settings.RemoveTime = 1.1
			VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 120000
			VelocityObject.Settings.Controllable = true
			VelocityObject.Settings.FixScale = true;
			VelocityObject.Settings.Z = 50
			VelocityObject:Fire();
		end;
		
		local Hitbox = self:CreateHitbox()
		Hitbox.Params.MaxTargets = 1
		Hitbox.Params.Offset = CFrame.new(0, 0, -4)---1.5)
		Hitbox.Params.Size = Vector3.new(7, 10, 10)
		Hitbox.Params.DestroyOnEndCast = false

		Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			self.Hit = self:Afflict(VictimLuaPlayer, {
				Damage = {Amount = 1, DontKill = true},
				BreakBlock = true
			})

			if self.Hit then
				self:SetUncancellable(false)
				
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -4) * CFrame.Angles(0, math.pi, 0))
				local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Mori[script.Name].Victim)

				self.Animations.Windup:Stop()
				self.Animations.Hit:Play()

				if VictimAnimation then
					VictimAnimation:Play(0) -- Looks weird on 0.1.
				end

				self.Thread.OnClosed:Connect(function()
					if VictimAnimation then
						VictimAnimation:Stop()
					end

					if not GrabObject.Destroyed then
						GrabObject.Destroy(0)
						VictimCombat:Unstun()
					end
				end)
				
				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("kick_up_init"):Once(function()
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = {Amount = 2.5, DontKill = true},
					})
				end))
				
				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("kick_up"):Once(function()
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = {Amount = 2.5, DontKill = true},
					})
					
					if self.LuaPlayer.IsNPC then
						local VelocityObject = self.Combat:Velocity()
						VelocityObject.Settings.Duration = 1.5
						VelocityObject.Settings.RemoveTime = 1.75
						VelocityObject.Settings.MaxForce = Vector3.new(1, 1, 1) * 145000
						VelocityObject.Settings.Controllable = false
						VelocityObject.Settings.FixScale = true;
						VelocityObject.Settings.Velocity = Vector3.new(0, 55, -10)
						VelocityObject:Fire();
					end;
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("throw"):Once(function()
					GrabObject.Destroy(1)
					VictimAnimation:Stop(0)
					
					local Root : BasePart = self.Combat:GetSimulatedRoot()
					local Raycast = workspace:Raycast(Root.Position, Vector3.yAxis * -125, Utility.VisualParams)

					local CF = Root.CFrame - (Vector3.yAxis * Raycast.Distance) + (Vector3.yAxis * 3)
					
					if (Raycast == nil) then
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Damage = 5,
							Velocity = {Vector3.yAxis * -200, 0.05},
							Ragdoll = 2,
						})
						
						VictimCombat:Unstun()
						
						return
					end
					
					local Size = 13.5
					
					local Hitbox = self.Thread.Job:Task(self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, CFrame.identity, Size, true))
					Hitbox.Adornee = CF.Position

					local Rnd = Random.new();

					self.Combat.Hitbox:CreateHavocReplicated({
						parameters = {
							origin = CF,
							shape = "Sphere", 
							radius = Size,
							block_size = (Size / 2.5),
						},
						
						debris = {
							scale = 0.9,
							radius = Size,
							velocity = function(part)
								return Rnd:NextUnitVector() * 30 + Vector3.yAxis * 25;
							end,
						},
					});
				
					Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
						local VictimLuaCharacter = VictimLuaPlayer.Character
						local VictimCombat = VictimLuaCharacter.Combat

						self:Afflict(VictimLuaPlayer, {
							TriggerActiveCounterOverOrEqualLevel = -1,
							CannotBeAdapted = true,
							Damage = 10,
							DontCheckBlock = true,
							Ragdoll = 2,
							Velocity = {(VictimLuaCharacter.RootPart.Position - CF.Position).Unit * 35 + Vector3.yAxis * 35, 0.1}
						})
					end)

					Hitbox:Detect()
					self.Combat.Hitbox:SphereDestruction(Hitbox.Adornee, Hitbox.Params.Size, 5)
					
					task.spawn(function()
						local GotGrabbed = false
						
						for Index = 1, 6 do
							GotGrabbed = VictimCombat:GetState("Grabbed")
							
							if GotGrabbed then
								break
							end
							
							if VictimLuaCharacter.HumanoidExists then
								VictimLuaCharacter.Model:PivotTo(CF)
								VictimLuaCharacter.RootPart.AssemblyLinearVelocity = Vector3.zero
								VictimLuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.zero
							end
							
							RunService.Heartbeat:Wait()
						end
						
						if not GotGrabbed then
							self:Afflict(VictimLuaPlayer, {
								ExcludeAttempts = true,
								Damage = 5,
								Velocity = {(Rnd:NextUnitVector() * Vector3.new(1, 0, 1)).Unit * 50 + Vector3.yAxis * 50, 0.1},
								Ragdoll = 2,
							})
						end
						
						VictimCombat:Unstun()
					end)
					
					
					--task.delay(3 / 60, function()
					--	self:Afflict(VictimLuaPlayer, {
					--		ExcludeAttempts = true,
					--		Velocity = {(Rnd:NextUnitVector() * Vector3.new(1, 0, 1)).Unit * 50 + Vector3.yAxis * 50, 0.1},
					--	})
					--end)

					--self:Afflict(VictimLuaPlayer, {
					--	ExcludeAttempts = true,
					--	Damage = 5,
					--	Velocity = {Vector3.yAxis * -25, 0.05},
					--	Ragdoll = 2,
					--})
					
					--VictimCombat:Unstun()
				end))

				self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("end"):Connect(function()
					self:Close()
				end))

				self:FireReliableVFX("Mori/Dragon Dropkick", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
			end
		end)

		Hitbox:BeginCast(0.225)
		
		Hitbox.Events.OnCastEnded:Once(function()
			if not self.Hit then
				self:SetUncancellable(false)
			end
		end)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Once(function()
		self:Close()
	end))
	
	self:FireReliableVFX("Mori/Dragon Dropkick", "Start", self.LuaCharacter.Model)
end

function Attack:SetUncancellable(Value : boolean)
	BaseAttack.SetUncancellable(self, Value);

	if self.Uncancellable and not self.Uncancellable_Highlight then
		self.Uncancellable_Highlight = ReplicatedStorage.Modules.Player.Replication.VFX.Mori["Dragon Dropkick"].resources.highlight:Clone()
		self.Uncancellable_Highlight.OutlineColor = Color3.fromRGB(84, 144, 255)
		self.Uncancellable_Highlight.FillTransparency = 1
		self.Uncancellable_Highlight.OutlineTransparency = 0.6
		self.Uncancellable_Highlight.Parent = self.LuaCharacter.Model

	elseif not self.Uncancellable and self.Uncancellable_Highlight then
		self.Uncancellable_Highlight:Destroy()
		self.Uncancellable_Highlight = nil
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	--self.AnimationSettings = {Speed = 1.15}
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack