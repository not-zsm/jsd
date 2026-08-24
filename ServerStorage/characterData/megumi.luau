local replicatedStorage = game:GetService("ReplicatedStorage")

local colour = Color3.fromRGB(35, 34, 34)

return {
	DisplayName = "Potential Man",
	
	Attacks = {
		Toad = Enum.KeyCode.One,
		['Rabbit Escape'] = Enum.KeyCode.Two,
		['Dark Shadow'] = Enum.KeyCode.Three,
		Nue = Enum.KeyCode.Four,
	},
	
	Stats = {
		M1 = {
			Speed = 0.85,
			EndlagAfterSwing = 0.08,
			
			Hitbox = {
				Offset = CFrame.new(0, 0, -2.65),
					Size = Vector3.new(6, 6, 6.8),
			},

			ArmFlashes = {
				[1] = { Limb = "Right Arm", Colour = colour, Duration = 0.35 },
				[2] = { Limb = "Left Arm", Colour = colour, Duration = 0.35 },
				[3] = { Limb = "Right Arm", Colour = colour, Duration = 0.35 },
				[4] = { Limb = "Left Arm", Colour = colour, Duration = 0.4 },

				Up = { Limb = "Right Arm", Colour = colour, Duration = 0.4 },
				Down = { Limb = "Right Arm", Colour = colour, Duration = 0.4 },
			},
		}
	},
	
	Ultimate = {
	Name = "True Potential",
		
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 27, 28)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(32, 32, 32)),
		}),
		
		Attacks = {
			--none
		},
		
		--CanRotate = true,
		
		Function = function(self)
			local Weapons = self.Combat.Attacks.Weapons

			if Weapons then
				Weapons:HideAll()
			end
			
			local Animation : AnimationTrack = self.Animations[self.Combat.CurrentCharacter.Name].Start
			local Rotation = self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
			
			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("forward"):Connect(function()
				if Rotation then
					Rotation:Destroy()
				end
				
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 0.7
				VelocityObject.Settings.RemoveTime = 0.7
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 30
				VelocityObject:Fire()
			end))
			
			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("run"):Connect(function()
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.Duration = 1.5
				VelocityObject.Settings.RemoveTime = VelocityObject.Settings.Duration
				VelocityObject.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Z = 60
				VelocityObject:Fire()
			end))
			
			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("jump"):Connect(function()
				local VelocityObject = self.Combat:Velocity()
				VelocityObject.Settings.RemoveTime = 0.23
				VelocityObject.Settings.MaxForce = Vector3.one * 80000
				VelocityObject.Settings.Controllable = true
				VelocityObject.Settings.Y = 25
				VelocityObject.Settings.Z = 80
				VelocityObject:Fire()
			end))
			
			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("slam"):Connect(function()
				self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
				
				local Hitbox = self:CreateHitbox(false);
				Hitbox.Params.Size = Vector3.new(19.16, 10, 23.723)
				Hitbox.Params.Offset = CFrame.new(0.164, -2.341, -0.712)

				Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
					self:Afflict(VictimLuaPlayer, {
						TriggerActiveCounterOverOrEqualLevel = -1,
						Damage = 10,
						Ragdoll = 1.5,
						Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 50 + Vector3.yAxis * 50, 0.1}
					})
				end)

				Hitbox:Detect()
			end))
			
			local StartRageHitbox = self:CreateHitbox(false);
			StartRageHitbox.Params.Size = Vector3.new(27.706, 10, 28.463)
			StartRageHitbox.Params.Offset = CFrame.identity

			StartRageHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local Validated = self:Afflict(VictimLuaPlayer, {
					TriggerActiveCounterOverOrEqualLevel = -1,
					Damage = 10,
					BreakBlock = true,
				})

				if Validated then
					self.Combat:TSBPushVictim(VictimLuaPlayer, {
						LookVectorInsteadOfDifference = true,
						LandedRollVelocityZ = 170,
						LandedRollDuration = 0.7
					})
				end
				
				task.delay(0.5, StartRageHitbox.RemoveHumanoid, StartRageHitbox, VictimLuaPlayer.Character.Humanoid)
			end)
			
			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("startrage"):Connect(function(Parameter : string)
				local Raging = (Parameter == "true")
				
				if Raging then
					StartRageHitbox:BeginCast()
				else
					StartRageHitbox:EndCast()
				end
			end))
			
			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("endrage"):Connect(function(Parameter : string)
				if (Parameter == "false") then
					task.wait(0.6)
					
					if self.LuaCharacter.Mimir then
						task.delay(1, function()
							if math.random(1, 4) == 1 then
								self.LuaCharacter.Mimir.RootPart["On Fire Kratos"]:Play()
							end
						end)
					end
					
					self:Close()
				end
			end))
			
			Animation:Play()
			self:FireReliableVFX("kratos/Ultimate", "Start", self.LuaCharacter.Model)
			
			
			self.Thread.OnClosed:Connect(function()
				Animation:Stop(0.2)
			end)
		end,
	},
}