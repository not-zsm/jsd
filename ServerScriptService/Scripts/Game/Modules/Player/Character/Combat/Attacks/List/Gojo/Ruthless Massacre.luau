local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local UIRemotes = Remotes.Combat.UI

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

----------------------------------------------------------------------------------

local Attack = {}
Attack.__index = Attack

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(20)

	self.Hit = false
	
	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 0, -5.5)
	Hitbox.Params.Size = Vector3.new(7.5, 8, 10)
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 1

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = 2,
			DontHitDeadPeople = true,
			BreakBlock = true,
		})

		if Validated then
			self.Hit = true
			
			VictimCombat:StackState("HitboxImmunity", true)
		
			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
	
			self.LuaCharacter:Anchor(true)
			VictimLuaCharacter:Anchor(true)
			
			local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

			if Matched then
				Ultimate:SetBarPausing(true)
				
				self.Thread.OnClosed:Connect(function()
					Ultimate:SetBarPausing(false)
				end)
			end
			
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -2.5) * CFrame.Angles(0, math.pi, 0))
			
			local AttackerParameterToVFXName = {
				["teleport"] = "Teleport",
				["l1"] = "LeftArm1",
				["l2"] = "LeftArm2",
				["r1"] = "RightArm1",
				["r2"] = "RightArm2",
				["redenable"] = "RedEnable",
				["reddisable"] = "RedDisable",
				["blueenable"] = "BlueEnable",
				["bluedisable"] = "BlueDisable",
				["h1"] = "AttackerRootPart1",
				["h2"] = "AttackerRootPart2",
				["h3"] = "AttackerRootPart3",
				["redshoot"] = "ShootRed",
				["h25"] = "AttackerRootPart25",
				["h33"] = "AttackerRootPart33",
				["h36"] = "AttackerRootPart36",
				["h44"] = "AttackerRootPart44",
			}
			
			local VictimParameterToVFXName = {
				["1"] = "Victim1",
				["2"] = "Victim2",
				["3"] = "Victim3",
				["BF"] = "BlackFlash",
				["BFenable"] = "BlackFlashEnable",
				["BFdisable"] = "BlackFlashDisable",
			}
			
			local Ended = false
			local RightArmCountForCamera = 0
			
			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("EventName"):Connect(function(Parameter : string)
				local VFXName : string = AttackerParameterToVFXName[Parameter]

				if VFXName == "Teleport" then -- idk why
					self:FireReliableVFX("Gojo/Ruthless Massacre", VFXName, self.LuaCharacter.Torso)
				end
				
				if VFXName:find("LeftArm") or VFXName:find("Red") or VFXName:find("Blue") then
					self:FireReliableVFX("Gojo/Ruthless Massacre", VFXName, self.LuaCharacter.LeftArm)
					
				elseif VFXName:find("RightArm") then
					RightArmCountForCamera += 1

					if RightArmCountForCamera == 2 then
						self.Combat:HideUI(true)
						VictimCombat:HideUI(true)
						
						self.LuaPlayer.Replication.Attributes:SetAttribute("RuthlessMassacreCamera", true)
						self:FireReliableVFXToSelf("Gojo/Ruthless Massacre", "Camera", self.LuaCharacter.RootPart)
						
						if (not VictimLuaPlayer.IsNPC and VictimLuaPlayer.Player.Parent ~= nil) then
							VictimLuaPlayer.Replication.Attributes:SetAttribute("RuthlessMassacreCamera", true)
							VictimLuaPlayer.Replication:FireReliableVFXToSelf("Gojo/Ruthless Massacre", "Camera", self.LuaCharacter.RootPart)
						end
						
						self.Thread.OnClosed:Connect(function()
							if (not self.LuaPlayer.IsNPC and self.LuaPlayer.Player.Parent ~= nil) then
								self.LuaPlayer.Replication.Attributes:SetAttribute("RuthlessMassacreCamera", nil)
							end
							
							self.Combat:HideUI(false)
							VictimCombat:HideUI(false)
	
							if (not VictimLuaPlayer.IsNPC and VictimLuaPlayer.Player.Parent ~= nil) then
								VictimLuaPlayer.Replication.Attributes:SetAttribute("RuthlessMassacreCamera", nil)
							end
						end)
					end
					
					self:FireReliableVFX("Gojo/Ruthless Massacre", VFXName, self.LuaCharacter.RightArm)
					
				elseif VFXName:find("AttackerRootPart") then
					self:FireReliableVFX("Gojo/Ruthless Massacre", VFXName, self.LuaCharacter.RootPart)
				end
			end))
			
			self.Thread.Job:Task(VictimCombat.Animations.GrabVictims["Ruthless Massacre"]:GetMarkerReachedSignal("EventName"):Connect(function(Parameter : string)
				local VFXName : string = VictimParameterToVFXName[Parameter]

				if VFXName == "BlackFlashEnable" then
					self:FireReliableVFXToSelf("Gojo/Ruthless Massacre", "ImpactFrames")

					if not VictimLuaPlayer.IsNPC then
						VictimLuaPlayer.Replication:FireReliableVFXToSelf("Gojo/Ruthless Massacre", "ImpactFrames")
					end
	
				elseif VFXName == "BlackFlashDisable" then
					Ended = true
					GrabObject.Destroy(0)
					
					VictimCombat.Animations.GrabVictims["Ruthless Massacre"]:Stop(0)
					VictimLuaCharacter:Anchor(false)

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						FinisherKill = true,
						Ragdoll = 5;
						Velocity = {self.LuaCharacter.RootPart.CFrame.RightVector * 75 + self.LuaCharacter.RootPart.CFrame.LookVector * 100 + Vector3.yAxis * 50, 0.1}
					})
					
					--VictimCombat.Ragdoll:Toggle(true, 5)
					self.Combat:VictimImpactGround(VictimLuaPlayer)
					
					VictimCombat:Unstun()
					VictimCombat:StackState("HitboxImmunity", false)
				end

				self:FireReliableVFX("Gojo/Ruthless Massacre", VFXName, VictimLuaCharacter.Torso)
			end))
			
			self.Animations.Windup:Stop(0) 
			self.Animations.Hit:Play(0)
			VictimCombat.Animations.GrabVictims["Ruthless Massacre"]:Play(0)
			
			self:FireReliableVFX("Gojo/Ruthless Massacre", "Hit", self.LuaCharacter.RootPart, VictimLuaCharacter.RootPart)

			self.Thread.OnClosed:Connect(function()
				if not Ended then
					VictimCombat.Animations.GrabVictims["Ruthless Massacre"]:Stop(0)
					VictimCombat:StackState("HitboxImmunity", false)
					VictimLuaCharacter:Anchor(false)
				end
				
				self.LuaCharacter:Anchor(false)
				
				GrabObject.Destroy(0)
				VictimCombat:Unstun()
			end)

			self.Thread.Job:Task(self.Animations.Hit.Stopped:Once(function()
				self:Close()
			end))
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(100)
		
		if not self.Combat:GetState("Grabbed") then
			self.LuaCharacter:SetCollisionGroup("Player")
		end

		self.Combat:TimesSpeed(20)

		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("HitboxImmunity", false)
	end)
	
	self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")

	local VelocityObject = self.Combat:Velocity()
	VelocityObject.Settings.Duration = 1.75
	VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
	VelocityObject.Settings.Controllable = true
	VelocityObject.Settings.Z = 5
	VelocityObject:Fire()

	self.Thread.Job:Task(VelocityObject)

	self:FireReliableVFX("Gojo/Ruthless Massacre", "Start", self.LuaCharacter.RootPart)
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Gojo", "Ruthless Massacre"))

	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("step"):Connect(function(Parameter : string)
		self:FireReliableVFX("Gojo/Ruthless Massacre", "Footstep", (Parameter == "Left" and self.LuaCharacter.LeftLeg.LeftFootAttachment or Parameter == "Right" and self.LuaCharacter.RightLeg.RightFootAttachment))
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("run"):Once(function()
		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1.2
		VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration + 0.3
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 80
		VelocityObject:Fire()
		
		self.Thread.Job:Task(VelocityObject)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Once(function()
		self:FireReliableVFX("Gojo/Ruthless Massacre", "Swing", self.LuaCharacter.RootPart)
		Hitbox:BeginCast(0.15)
	end))

	self.Animations.Windup.Ended:Wait()

	if not self.Hit then
		self:FireReliableVFX("Gojo/Ruthless Massacre", "Miss", self.LuaCharacter.RootPart)
		self:Close()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true
	self.AnimationSettings = {Speed = 1.25}
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack