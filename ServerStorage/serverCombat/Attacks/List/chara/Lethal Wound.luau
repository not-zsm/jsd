local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")


----------------------------------------------------------------------------------

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:LethalWound()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)

	self.Hit = false

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, -1, self.LuaPlayer.IsNPC and 2 or -4) --self.LuaPlayer.IsNPC and 2 or -4 - self.LuaPlayer:GetPing())
	Hitbox.Params.Size = Vector3.new(7, 4, 10)
	Hitbox.Params.MaxTargets = 1
	Hitbox.Params.DestroyOnEndCast = false
	
	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			DontBypassIFrames = {"Grab", "BackDash"},
			BreakBlock = true,
		})

		if Validated then
			self.Hit = true
			
			Hitbox:EndCast()
			--self.LuaPlayer.Replication.Attributes:SetAttribute("LethalWoundSlide", nil)
			
			self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
			
			local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.Angles(0, math.pi, 0))
			local VictimAnimation : AnimationTrack = VictimLuaCharacter:LoadAnimation(replicatedStorage.animations.Attacks.chara["Lethal Wound"].Victim)
			
			local Ended = false
	
			local SFX : Sound = self.Thread.CancelJob:Task(self:CreateMoveSFX("chara", "Lethal Wound"))
			
			--self.LuaPlayer.Replication.Attributes:SetAttribute("LethalWoundHit", true)
			--self:FireReliableVFX("chara/Lethal Wound", "Tackle", self.LuaCharacter.RootPart)
			
			--self.Thread.OnClosed:Connect(function()
			--	self.LuaPlayer.Replication.Attributes:SetAttribute("LethalWoundHit", nil)
			--end)
			
			local function Finisher()
				SFX:Destroy()

				self.Thread.CancelJob:Task(self:CreateMoveSFX("chara", "Lethal Wound Finisher"))

				local FinisherVictimAnimation : AnimationTrack = VictimLuaCharacter.Animator:LoadAnimation(replicatedStorage.animations.Attacks.chara["Lethal Wound"].FinisherVictim)
				VictimLuaCharacter:StopRespawnTimer()

				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("stab"):Connect(function()
					self:FireReliableVFX("chara/Lethal Wound Finisher", "Stab", VictimLuaCharacter.RootPart)

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,

						Damage = {
							DontKill = true,
							Amount = 2.5,
						}
					})
				end))

				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("stabtoleft"):Connect(function()
					self:FireReliableVFX("chara/Lethal Wound Finisher", "StabToLeft", VictimLuaCharacter.RootPart)
				end))

				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("throwleft"):Connect(function()
					self:FireReliableVFX("chara/Lethal Wound Finisher", "ThrowLeft", VictimLuaCharacter.RootPart)
				end))

				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("throwback"):Connect(function()
					self:FireReliableVFX("chara/Lethal Wound Finisher", "ThrowBack", VictimLuaCharacter.RootPart)
				end))

				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("sliceemit"):Connect(function()
					self:FireReliableVFX("chara/Lethal Wound Finisher", "Slice", VictimLuaCharacter.RootPart)
				end))

				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("slicing"):Connect(function(Enable : string)
					local Enabled = (Enable == "Enable")

					self:FireReliableVFX("chara/Lethal Wound Finisher", "Slicing", VictimLuaCharacter.RootPart, Enabled)

					if Enabled then
						task.spawn(function()
							while not self.Thread.Closed do
								self:Afflict(VictimLuaPlayer, {
									ExcludeAttempts = true,

									Damage = {
										DontKill = true,
										Amount = 0.5,
									}
								})

								task.wait(0.035)
							end
						end)

						self.Thread.OnClosed:Connect(function()
							self:FireReliableVFX("chara/Lethal Wound Finisher", "StopSlicing", VictimLuaCharacter.RootPart)
						end)
					end
				end))

				self.Thread.Job:Task(self.Animations.Finisher:GetMarkerReachedSignal("sliced"):Connect(function()
					self:FireReliableVFX("chara/Lethal Wound Finisher", "Sliced", VictimLuaCharacter.RootPart)

					Ended = true

					FinisherVictimAnimation:Stop(0)
					self.Animations.Finisher:Stop(0)

					self.LuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -3.102) * CFrame.Angles(0, math.pi, 0))

					self.Animations.FinisherEnd:Play(0)
					GrabObject.Destroy(0)

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						FinisherKill = true,
						Velocity = {Vector3.yAxis * -25, 0.1}
					})

					local EndAnimation : RBXScriptConnection; EndAnimation = self.Combat.OnStateChanged:Connect(function(State : any, Value : boolean)
						if Value and (State == "Attacking" or State == "M1ing") then
							self.Animations.FinisherEnd:Stop()
						end
					end)

					self.Animations.FinisherEnd.Stopped:Once(function()
						if EndAnimation.Connected then
							EndAnimation:Disconnect()
						end
					end)

					VictimCombat:Unstun()
					self:Close()
				end))

				self.Animations.Hit:Stop()

				if VictimAnimation then
					VictimAnimation:Stop()
				end

				self.Animations.Finisher:Play()
				FinisherVictimAnimation:Play()

				self.Thread.OnClosed:Connect(function()
					VictimLuaCharacter:RestartRespawnTimer()
					
					if not Ended then
						self.Animations.Finisher:Stop()
						FinisherVictimAnimation:Stop()
					end
				end)
			end

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("stab"):Connect(function(Type : string)
				local IsFinisher = self:IsFinisherEnabled() and (VictimLuaCharacter.Humanoid.Health <= 7.5)
				
				if IsFinisher then
					Finisher()
				else
					--self:FireReliableVFX("chara/Lethal Wound", "Stab", self.LuaCharacter.RootPart, VictimLuaCharacter.Head, tonumber(Type))
					
					if Type == "3" then
						Ended = true
						
						self:FireReliableVFX("chara/Lethal Wound", "Stab", self.LuaCharacter.RootPart, VictimLuaCharacter.Head, Type)

						if VictimAnimation then
							VictimAnimation:Stop(0)
						end
						
						self.Animations.Hit:Stop(0)
						self.LuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -3.102) * CFrame.Angles(0, math.pi, 0))

						self.Animations.End:Play(0)
						GrabObject.Destroy(0.4)

						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							Damage = 3,
							Ragdoll = 1.5,
							Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 50, 0.1}
						})

						local EndAnimation : RBXScriptConnection; EndAnimation = self.Combat.OnStateChanged:Connect(function(State : any, Value : boolean)
							if Value and (State == "Attacking" or State == "M1ing") then
								self.Animations.End:Stop()
							end
						end)

						self.Animations.End.Stopped:Once(function()
							if EndAnimation.Connected then
								EndAnimation:Disconnect()
							end
						end)

						task.wait(0.35)
						
						self:Close()
					else
						self:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,

							Damage = {
								DontKill = true,
								Amount = 3,
							}
						})
					end
				end
			end))
			
			self.Animations.Windup:Stop(); self.Animations.Hit:Play()
			VictimAnimation:Play(0)
			
			self:FireReliableVFX("chara/Lethal Wound", "Hit", self.LuaCharacter.Model, VictimLuaCharacter.Model)
			
			self.Thread.OnClosed:Connect(function()
				if not Ended then
					self.Animations.Hit:Stop()
					VictimAnimation:Stop()
				end
			
				GrabObject.Destroy(0)
				VictimCombat:Unstun()
			end)
		end 
	end)
	
	local VelocityObject
	local NoRotation
	
	self.Thread.OnClosed:Connect(function()
		if VelocityObject then
			VelocityObject:Destroy()
		end
		
		--self:AddCooldown(16) -- when bloody mary extended
		self:AddCooldown(18.5)
		
		self.Combat:TimesSpeed(50)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("run"):Once(function()
		self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
		
		self.Thread.OnClosed:Connect(function()
			self.LuaCharacter:SetCollisionGroup("Player")
		end)

		VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1.1
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 50
		VelocityObject:Fire()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("slide"):Once(function()
		NoRotation = self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

		self.Animations.Windup:AdjustSpeed(1)
		
		self.LuaCharacter.Torso.CanCollide = false
		self.LuaCharacter.RootPart.CanCollide = true
		
		self.Thread.OnClosed:Connect(function()
			self.LuaCharacter.Torso.CanCollide = true
			self.LuaCharacter.RootPart.CanCollide = false
		end)
		
		VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 105
		VelocityObject:Fire()

		--self.LuaPlayer.Replication.Attributes:SetAttribute("LethalWoundSlide", true)
		--self:FireReliableVFX("chara/Lethal Wound", "Slide", self.LuaCharacter.RootPart)
		
		--self.Thread.OnClosed:Connect(function()
		--	self.LuaPlayer.Replication.Attributes:SetAttribute("LethalWoundSlide", nil)
		--end)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("begincast"):Once(function()
		Hitbox:BeginCast()
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("endcast"):Once(function()
		--self.LuaPlayer.Replication.Attributes:SetAttribute("LethalWoundSlide", nil)
		Hitbox:EndCast()
		
		if NoRotation then
			NoRotation:Destroy()
			NoRotation = nil
		end
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("end"):Once(function()
		--if NoRotation then
		--	NoRotation:Destroy()
		--	NoRotation = nil
		--end
		
		self.Animations.Windup:AdjustSpeed(0.9)
		
		self.LuaCharacter.Torso.CanCollide = true
		self.LuaCharacter.RootPart.CanCollide = false
	end))
	
	self:FireReliableVFX("chara/Lethal Wound", "Windup", self.LuaCharacter.Model)
	
	task.wait(1.85)

	if not self.Hit then
		self:Close()
	end
end

function Attack:SpiralingCascade()
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(15)

	self.GroundHit = false

	local Hitbox = self:CreateHitbox(false, true);
	Hitbox.Params.Offset = CFrame.new(0, -1, self.LuaPlayer.IsNPC and 2 or -4 - self.LuaPlayer:GetPing())
	Hitbox.Params.Size = Vector3.new(7, 3, 10)
	Hitbox.Params.MaxTargets = 1
	Hitbox.Params.DestroyOnEndCast = false

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
		})

		if Validated then
			self.GroundHit = true
			Hitbox:EndCast()
		end
	end)

	self.Thread.Job:Task(self.Animations.GroundWindup:GetMarkerReachedSignal("jump"):Once(function()
		self.Animations.GroundWindup:AdjustSpeed(1)

		self.LuaCharacter.Torso.CanCollide = false
		self.LuaCharacter.RootPart.CanCollide = true

		self.Thread.OnClosed:Connect(function()
			self.LuaCharacter.Torso.CanCollide = true
			self.LuaCharacter.RootPart.CanCollide = false
		end)

		local VelocityObject = self.Combat:Velocity()
		VelocityObject.Settings.Duration = 1
		VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
		VelocityObject.Settings.Controllable = true
		VelocityObject.Settings.Z = 105
		VelocityObject:Fire()

		self.Thread.Job:Task(VelocityObject)
	end))

	self.Thread.Job:Task(self.Animations.GroundWindup:GetMarkerReachedSignal("hit"):Once(function()
		Hitbox:BeginCast()
	end))

	self.Animations.GroundWindup:Play(0.1, 1, 1.4)
end

function Attack:Activate()
	if (self.VariantsEnabled and self.HoldingJump) or self.ForceVariant then
		self:SpiralingCascade()
	else
		self:LethalWound()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.Properties = {
		Variant = {
			Name = "Spiralling Cascade",
			Colour = Color3.fromRGB(191, 0, 0),
			When = "HoldingSpace",
		},
	}
	self.TryToCancelMoves = true
	self.AnimationSettings  = {Speed = 0.7}
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack