local replicatedStorage = game:GetService("ReplicatedStorage")

local flashSet = require(script.armFlash)

return {
	DisplayName = "kratos",
	DevOnly = true,

	UsingAttacks = {
		--"Chaos Run",
		"Guardian Shield"
	};
	
	Stats = {
		M1 = {
			Speed = 1.55,
			EndlagAfterSwing = 0.08,
			
			Hitbox = {
				Offset = CFrame.new(0, 0, -2.65),
				Size = Vector3.new(6, 6, 6.8),
			},
		}
	},
	
	Dash = {
		AnimationDirectory = function(self)
			local Weapons = self.Combat.Attacks.Weapons
			local Directory = self.AnimationDirectory

			if Weapons and Weapons.CurrentlyUsing ~= "" then
				if Directory[Weapons.CurrentlyUsing] then
					return Directory[Weapons.CurrentlyUsing]
				else
					return Directory.Default
				end
			end

			return Directory
		end,
	},
	
	M1 = {
		AnimationDirectory = function(self)
			local Weapons = self.Combat.Attacks.Weapons
			local Directory = self.AnimationDirectory

			if Weapons and Weapons.CurrentlyUsing ~= "" then
				return Directory[Weapons.CurrentlyUsing]
			end

			return Directory
		end,

		StartFunction = function(self)
			local Weapons = self.Combat.Attacks.Weapons

			if (Weapons and self.Count == 4 and self.Condition == nil)  then
				if Weapons.CurrentlyUsing == "Chained Blades" then
					Weapons:ToggleChainedBladeTrails(true)
					
					self.Combat.CurrentCharacter.Stats.M1.Hitbox.Offset = CFrame.new(0, 0, -4)
					self.Combat.CurrentCharacter.Stats.M1.Hitbox.Size = Vector3.new(9, 6, 8.8)

					task.wait(1)
					
					self.Combat.CurrentCharacter.Stats.M1.Hitbox.Offset = CFrame.new(0, 0, -2.65)
					self.Combat.CurrentCharacter.Stats.M1.Hitbox.Size = Vector3.new(6, 6, 6.8)

					Weapons:ToggleChainedBladeTrails(false)
					
				elseif Weapons.CurrentlyUsing == "Axe" then 
					Weapons:ToggleIceAxe(true)

					task.wait(1)

					Weapons:ToggleIceAxe(false)
				end
			end
		end,
		
		ArmFlashes = function(self)
			local Weapons = self.Combat.Attacks.Weapons

			return flashSet[Weapons and Weapons.CurrentlyUsing] or flashSet.Fists
		end,
	},

	Attacks = {
		["Chaos Barrage"] = Enum.KeyCode.One,
		["Leviathan Rush"] = Enum.KeyCode.Two,
		["Leviathan Throw"] = Enum.KeyCode.Three,
		["Draupnir Spin"] = Enum.KeyCode.Four,
	},

	OnRespawn = function(LuaPlayer, Job)
		local Animation = LuaPlayer.Character.Animator:LoadAnimation(replicatedStorage.animations.CharacterSpawnAnimations.kratos.Spawn)

		local Sound : Sound = script.SFX:Clone()
		Sound.Parent = LuaPlayer.Character.RootPart

		local Log = script.LogRig:Clone()
		Log["Log Mesh"].CFrame = LuaPlayer.Character.RootPart.CFrame * CFrame.new(0, -2, 0.5)
		Log.Parent = workspace.Visuals
		
		local LogAnimation =Log.AnimationController.Animator:LoadAnimation(replicatedStorage.animations.CharacterSpawnAnimations.kratos.Log)
	
		LogAnimation.Stopped:Once(function()
			Log:Destroy()
		end)
		
		local function PlaySound()
			Sound:Play()
			task.delay(Sound.TimeLength, Sound.Destroy, Sound)
		end

		if not Sound.IsLoaded then
			Sound.Loaded:Once(PlaySound)
		else
			PlaySound()
		end
		
		Animation:Play()
		LogAnimation:Play()

		Job:Task(function()
			LogAnimation:Stop()
		end)
		
		return Animation, Sound
	end,

	OnSpawn = function(LuaPlayer)
		local Weapons = LuaPlayer.Character.Combat:CreateAttack("Weapons")
		Weapons:SetCurrent("Axe")
		
		if (LuaPlayer.Player:GetAttribute("Accessories") and LuaPlayer.Character.Mimir == nil) then
			local Mimir = script.Mimir:Clone()
			Mimir.Weld.Part0 = LuaPlayer.Character.Model.Torso
			Mimir.Parent = LuaPlayer.Character.Model

			LuaPlayer.Character.Mimir = Mimir
		end
	end,

	OnRemoved = function(LuaPlayer)
		if LuaPlayer.Character.Mimir then
			LuaPlayer.Character.Mimir:Destroy()
			LuaPlayer.Character.Mimir = nil
		end
		
		local Weapons = LuaPlayer.Character.Combat.Attacks.Weapons

		if Weapons then
			Weapons:DestroyAll()
		end

		LuaPlayer.Character.Combat:RemoveAttack("Weapons")
	end,

	WallComboFinisher = {
		DistanceFromWall = 5.5,
		VictimOffset = CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0),

		Condition = function(VictimLuaPlayer)
			return VictimLuaPlayer.Character.Humanoid.Health <= 10
		end,

		DontPutIFrames = true,
		
		Function = function(self, VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local VictimModel = VictimLuaCharacter.Model

			local AttackerAnimation = self.Animations.WallCombo.kratos.Finisher
			local VictimAnimation = VictimLuaCharacter.Humanoid:LoadAnimation(replicatedStorage.animations.Attacks.Global.Dash.WallCombo.kratos.VictimFinisher)

			local Ended = false
			
			self.Combat:StackState("HitboxImmunity", true)
			VictimCombat:StackState("HitboxImmunity", true)

			do
				local Weapons = self.Combat.Attacks.Weapons

				if Weapons then
					Weapons:HideAll()
				end
			end
			
			self.Thread.CancelJob:Task(
				self:CreateMoveSFX("kratos", "Wall Combo Finisher")
			)

			self.Thread.OnClosed:Connect(function()
				self.LuaCharacter:Anchor(false)
				VictimLuaCharacter:Anchor(false)

				do
					local Weapons = self.Combat.Attacks.Weapons

					if Weapons then
						Weapons:BringBackPreviouslyUsing()
					end
				end

				VictimCombat:StackState("HitboxImmunity", false)
				
				if not Ended then
					self.Combat:StackState("HitboxImmunity", false)
					VictimCombat:Unstun()
				else
					task.delay(0.5, function()
						self.Combat:StackState("HitboxImmunity", false)
					end)
				end

				AttackerAnimation:Stop()
				VictimAnimation:Stop()
				VictimAnimation = nil
			end)

			AttackerAnimation:Play()
			VictimAnimation:Play()

			self.LuaPlayer.Replication.Attributes:SetAttribute("KratosWallComboCamera", true)
			VictimLuaPlayer.Replication.Attributes:SetAttribute("KratosWallComboCamera", true)

			self:FireReliableVFXToSelf("kratos/Wall Combo", "Camera", self.LuaCharacter.RootPart)
			VictimLuaPlayer.Replication:FireReliableVFXToSelf("kratos/Wall Combo", "Camera", self.LuaCharacter.RootPart)

			self.Combat:HideUI(true)
			VictimCombat:HideUI(true)

			self.Thread.OnClosed:Connect(function()
				self.LuaPlayer.Replication.Attributes:SetAttribute("KratosWallComboCamera", nil)
				VictimLuaPlayer.Replication.Attributes:SetAttribute("KratosWallComboCamera", nil)
				
				self.Combat:HideUI(false)
				VictimCombat:HideUI(false)
			end)
			
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("hit"):Connect(function(Count : string)
				self:FireReliableVFX("kratos/Wall Combo Finisher", "Hit", VictimLuaCharacter.Torso)
			end))
			
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("hit2"):Connect(function(Count : string)
				self:FireReliableVFX("kratos/Wall Combo Finisher", "HeadHit", VictimLuaCharacter.Torso)
			end))
			
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("slam"):Connect(function()
				self:FireReliableVFX("kratos/Wall Combo", "Smash", self.LuaCharacter.RootPart)
			end))

			AttackerAnimation:GetMarkerReachedSignal("finalhit"):Wait()
			
			self.LuaPlayer.Replication.Attributes:SetAttribute("KratosWallComboCamera", nil)
			VictimLuaPlayer.Replication.Attributes:SetAttribute("KratosWallComboCamera", nil)

			if VictimModel == VictimLuaCharacter.Model then
				Ended = true

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					FinisherKill = true,
					Ragdoll = 2.1;
				})

				VictimAnimation:Stop(0)

				VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")
				VictimCombat.Ragdoll:SetCollisionGroupOfColliders("NoPlayerCollision")

				VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))
				VictimLuaCharacter:Anchor(false)
				
				self.Combat.Hitbox:Destruction(CFrame.new(0, 0, -3), Vector3.new(5, 5, 7), 2)
				
				--VictimCombat.Ragdoll:Toggle(true, 2.1)
				VictimCombat:Unstun()

				task.delay(0.5 + (not VictimLuaPlayer.IsNPC and VictimLuaPlayer.Player:GetNetworkPing() or 0), function()
					if not VictimCombat:GetState("Grabbed") then
						VictimLuaCharacter:SetCollisionGroup("Player")
					end

					VictimCombat.Ragdoll:SetCollisionGroupOfColliders("Default")
				end)
			end

			task.wait(0.35)

			self:Close()
		end,
	},

	WallCombo = {
		DistanceFromWall = 4,

		Function = function(self, VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local VictimModel = VictimLuaCharacter.Model

			local AttackerAnimation = self.Animations.WallCombo.kratos.Normal
			local VictimAnimation = VictimLuaCharacter:LoadAnimation(replicatedStorage.animations.Attacks.Global.Dash.WallCombo.kratos.Victim)

			local Ended = false

			local Weapons = self.Combat.Attacks.Weapons

			if Weapons then
				Weapons:HideAll()
			end
			
			self.Thread.CancelJob:Task(
				self:CreateMoveSFX("kratos", "Wall Combo")
			)

			self.Thread.OnClosed:Connect(function()
				if not Ended then
					self.Combat:StackState("GrabIFrames", false)
					VictimCombat:StackState("GrabIFrames", false)
					VictimCombat:Unstun()
				else
					task.delay(0.5, function()
						self.Combat:StackState("GrabIFrames", false)
					end)
				end
				
				self.LuaCharacter:Anchor(false)
				VictimLuaCharacter:Anchor(false)

				AttackerAnimation:Stop()
				
				if VictimAnimation then
					VictimAnimation:Stop()
					VictimAnimation = nil
				end
				
				if self.Combat.Attacks and self.Combat.Attacks.Weapons then
					self.Combat.Attacks.Weapons:BringBackPreviouslyUsing()
				end
			end)

			AttackerAnimation:Play()
			
			if VictimAnimation then
				VictimAnimation:Play()
			end
	
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("smash"):Once(function()
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 2
				})

				self:FireReliableVFX("kratos/Wall Combo", "Smash", self.LuaCharacter.RootPart)
			end))

			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("hit"):Connect(function(Count : string)
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 0.5
				})

				self:FireReliableVFX("kratos/Wall Combo", "Hit", VictimLuaCharacter.Torso, Count)
			end))
			
			AttackerAnimation:GetMarkerReachedSignal("final"):Wait()
			
			if VictimModel == VictimLuaCharacter.Model then
				Ended = true

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 2.5,
					Ragdoll = 2.1;
				})

				self:FireReliableVFX("kratos/Wall Combo", "Uppercut", self.LuaCharacter.RootPart)

				if VictimAnimation then
					VictimAnimation:Stop(0)
				end
			
				VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")
				VictimCombat.Ragdoll:SetCollisionGroupOfColliders("NoPlayerCollision")

				VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -2)) --* CFrame.Angles(0, math.pi, 0))
				VictimLuaCharacter:Anchor(false)

				local VelocityObject = self:VelocityOn(VictimCombat)
				VelocityObject.Settings.RemoveTime = 0.1
				VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.RightVector * -45 + Vector3.yAxis * 85
				VelocityObject:Fire()

				--VictimCombat.Ragdoll:Toggle(true, 2.1)
				VictimCombat:Unstun()

				task.delay(0.5 + (not VictimLuaPlayer.IsNPC and VictimLuaPlayer.Player:GetNetworkPing() or 0), function()
					if not VictimCombat:GetState("Grabbed") then
						VictimLuaCharacter:SetCollisionGroup("Player")
					end

					VictimCombat.Ragdoll:SetCollisionGroupOfColliders("Default")
				end)

				VictimCombat:StackState("GrabIFrames", false)
			end
			
			task.wait(0.35)

			self:Close()
		end,
	},
	
	Ultimate = {
		Name = "The Rage of War", --"RAAAHHHH I AM KRETOS !!!"
		
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 115, 15)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 124, 64)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 115, 15)),
		}),
		
		CanRotate = true,
		
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

		Attacks = {
			["Spartan Rage"] = Enum.KeyCode.One,
			["Nature's Arsenal"] = Enum.KeyCode.Two,
			["Rageful Tackle"] = Enum.KeyCode.Three,
			["Father Son Bonding"] = Enum.KeyCode.Four,
		}
	},
}