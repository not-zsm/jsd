local replicatedStorage = game:GetService("ReplicatedStorage")
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

return {
	DevOnly = true,

	DisplayName = "Invincible",
	Icon = "101089066666765",
	
	Attacks = {
		["Fraction of Power"] = Enum.KeyCode.One,
		["Holding Back"] = Enum.KeyCode.Two,
		["Visceral Drive"] = Enum.KeyCode.Three,
		["Death Leap"] = Enum.KeyCode.Four
	},
	
	Stats = {
		M1 = {
			Speed = 1.3,
			EndlagAfterSwing = 0.125,

			-- see Chara for what false means here
			ArmFlashes = {
				[1] = { Limb = "Right Arm", Colour = Color3.fromRGB(70, 130, 255), Duration = 0.35 },
				[2] = { Limb = "Left Arm", Colour = Color3.fromRGB(70, 130, 255), Duration = 0.35 },
				[3] = { Limb = "Right Arm", Colour = Color3.fromRGB(70, 130, 255), Duration = 0.35 },
				[4] = { Limb = "Left Arm", Colour = Color3.fromRGB(70, 130, 255), Duration = 0.4 },

				Up = { Limb = "Right Leg", Colour = Color3.fromRGB(70, 130, 255), Duration = 0.4 },
				Down = { Limb = "Right Arm", Colour = Color3.fromRGB(70, 130, 255), Duration = 0.4 },
			},
		},
	},
	
	Ultimate = {
		OneTimePop = true,

		Name = "This is Over! (UNFINISHED)",

		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 229, 86)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(0, 188, 240)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(0, 188, 240)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 229, 86)),
		}),

		Function = function(self, StartAnimation : AnimationTrack)
			self.Combat:StackState("Attacking", true)
			self.Combat:DivideSpeed(50)
			
			self.Combat:StackState("HitboxImmunity", true) 
			
			--self.Combat:CreateMoveSFX("Invincible", "Ultimate")
			
			self.LuaPlayer.Player:SetAttribute("AntiFling_Immunity", true)
			
			self.Thread.OnClosed:Connect(function()
				self:AddCooldown(0.5)

				self.Combat:TimesSpeed(50)
				self.Combat:StackState("Attacking", false)
				self.Combat:StackState("HitboxImmunity", false)
				
				self.LuaPlayer.Player:SetAttribute("AntiFling_Immunity", false)
				
				self.Combat:StackState("CannotGainMeter", true)
			end)
			
			-- Launch Hitbox
			local LaunchHitbox = self:CreateHitbox(true)
			LaunchHitbox.Params.Offset = CFrame.new(0, 0, 0)
			LaunchHitbox.Params.Size = 10
			LaunchHitbox.Params.DestroyOnEndCast = false

			LaunchHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local Validated = self:Afflict(VictimLuaPlayer, {
					TriggerActiveCounterOverOrEqualLevel = -1,
					DontCheckBlock = true,
					Ragdoll = 2,
					Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 75 + Vector3.yAxis * 50, 0.1},
					Damage = 5
				})
			end)
			
			self.Thread.Job:Task(StartAnimation:GetMarkerReachedSignal("launch"):Connect(function()
				
				LaunchHitbox:Detect()
			end))
			
			
			self.Thread.Job:Task(StartAnimation:GetMarkerReachedSignal("end"):Connect(function()
				-- End Windup and start the vertical flight
				StartAnimation:Stop(0)
				
				local FlightStart : AnimationTrack = self.LuaCharacter:LoadAnimation(replicatedStorage.Animations.Attacks.Global.Ultimate.Invincible.FlightStart)
				FlightStart:Play(0)
				
				-- Load SlamAnimation
				local SlamAnimation : AnimationTrack = self.LuaCharacter:LoadAnimation(replicatedStorage.Animations.Attacks.Global.Ultimate.Invincible.Slam)
				
				-- Start Listening for mouse position
				self.Combat.Mouse:BeginRequesting(nil, "Invincible_Ultimate")
			
				self.Thread.OnClosed:Connect(function()
					self.Combat.Mouse:EndRequesting()
				end)
				
				-- Velocity
				self.Thread.Job:Task(FlightStart:GetMarkerReachedSignal("Velocity"):Connect(function(Parameter)
					if Parameter == "forward" then
						-- Slam Hitbox Setup
						local SlamHitbox = self:CreateHitbox(true)
						SlamHitbox.Params.Offset = CFrame.new(0, 0, 0)
						SlamHitbox.Params.Size = 140
						SlamHitbox.Params.DestroyOnEndCast = false

						SlamHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
							local VictimLuaCharacter = VictimLuaPlayer.Character
							local VictimCombat = VictimLuaCharacter.Combat

							local Validated = self:Afflict(VictimLuaPlayer, {
								TriggerActiveCounterOverOrEqualLevel = -1,
								BreakBlock = true,
								Ragdoll = 4,
								Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 150 + Vector3.yAxis * 120, 0.1},
								Damage = 40
							})
						end)
						
						-- Fire Raycast towards mouse position
						local Root : BasePart = self.Combat:GetSimulatedRoot()
						local OriginCF : CFrame = Root.CFrame
						local Origin : Vector3 = OriginCF.Position

						local Map = workspace:FindFirstChild("Map")
						local Models = workspace:FindFirstChild("chars")
						
						local MapModel = Map:FindFirstChild("Model")
						local Props = MapModel:FindFirstChild("Props")
						
						local Params = RaycastParams.new()
						Params.FilterType = Enum.RaycastFilterType.Exclude
						Params.FilterDescendantsInstances = {Models, Props, workspace.Visuals, workspace.Ball}
						
						local Target = self.Combat.Mouse.Hit.LookVector --<<< might want to use the position of the hit and then just fire ray to that position
						
						local Raycast = workspace:Raycast(
							Origin, 
							(Target * 1500),
							Params
						)
						
						self.Combat.Mouse:EndRequesting()
						
						-- If raycast didnt hit anything, then default to a different direction
						if not Raycast then
							local AngleRad = math.rad(70)
							local YawCFrame = CFrame.new(Vector3.zero, Vector3.new(Root.CFrame.LookVector.X, 0, Root.CFrame.LookVector.Z)).Rotation
							
							local Direction = (YawCFrame * CFrame.Angles(-AngleRad, 0, 0)).LookVector * 1000
							
							Raycast = workspace:Raycast(
								Origin, 
								(Direction),
								Params
							)
						end
						
						if Raycast then
							local Studs = 400 -- Speed
							local Distance = (Origin - Raycast.Position).Magnitude
							local Duration = math.clamp(Distance / Studs, 0.05, 0.5)

							local CF = CFrame.lookAlong(Raycast.Position, OriginCF.LookVector)
							self:FireReliableVFX("Invincible/Ultimate", "Loop", self.LuaCharacter.Model, CF, Raycast.Normal, Duration)

							local Landed = false
							
							-- Destruction hitbox for anything while flying
							task.spawn(function()
								while not (Landed or self.Thread.Closed) do
									self.Combat.Hitbox:SphereDestruction(Root.Position, 30, 10, nil, {
										dont_create_debris = true
									})

									task.wait(0.05)
								end
							end)
							
							-- Hit ground
							self.Thread.Job:Task(task.delay(Duration, function()
								Landed = true
								
								SlamHitbox.Adornee = Raycast.Position
								SlamHitbox:Detect()

								self.Combat.Hitbox:Destruction(SlamHitbox.Params.Offset, Vector3.one * 140, 20)

								self.LuaCharacter.RootPart.AssemblyLinearVelocity = Vector3.zero
								self.LuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.zero

								SlamAnimation:Play(0)
								self:FireReliableVFX("Invincible/Ultimate", "Slam", self.LuaCharacter.Model, CF)

								task.wait(2)
								self:Close()
							end))
						else
							print("not found")
							self:Close()
						end
					end
				end))
				
				self:FireReliableVFX("Invincible/Ultimate", "Flight", self.LuaCharacter.Model)
			end))

			self:FireReliableVFX("Invincible/Ultimate", "Start", self.LuaCharacter.Model)
		end,
	},
	
	OnRemoved = function(self)
		self.Character.Combat:StackState("CannotGainMeter", false)
	end,
	
	--WallCombo = {
	--	DistanceFromWall = 5.062,
	--	VictimOffset = CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0),

	--	DontPutIFrames = true,

	--	Function = function(self, VictimLuaPlayer)
	--		local VictimLuaCharacter = VictimLuaPlayer.Character
	--		local VictimCombat = VictimLuaCharacter.Combat

	--		local VictimModel = VictimLuaCharacter.Model
			
			
	--		local AttackerAnimation = self.Animations.WallCombo.Invincible.User
	--		local VictimAnimation = VictimLuaCharacter.Humanoid:LoadAnimation(replicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Invincible.Victim)

	--		local Ended = false

	--		self.Combat:StackState("HitboxImmunity", true)
	--		VictimCombat:StackState("HitboxImmunity", true)

	--		self.Thread.OnClosed:Connect(function()
	--			self.LuaCharacter:Anchor(false)
	--			VictimLuaCharacter:Anchor(false)

	--			if not Ended then
	--				self.Combat:StackState("HitboxImmunity", false)
	--				VictimCombat:StackState("HitboxImmunity", false)
	--				VictimCombat:Unstun()
	--			else
	--				task.delay(0.5, function()
	--					self.Combat:StackState("HitboxImmunity", false)
	--				end)
	--			end

	--			AttackerAnimation:Stop()
	--			VictimAnimation:Stop()
	--			VictimAnimation = nil
	--		end)
			
	--		AttackerAnimation:Play()
	--		VictimAnimation:Play()

	--		self:FireReliableVFX("Invincible/Wall Combo", "Start", self.LuaCharacter.Model, VictimLuaCharacter.Model)

	--		self.Combat:HideUI(true)
	--		VictimCombat:HideUI(true)

	--		self.Thread.OnClosed:Connect(function()
	--			self.Combat:HideUI(false)
	--			VictimCombat:HideUI(false)
	--		end)

	--		AttackerAnimation.Ended:Wait()

	--		if VictimModel == VictimLuaCharacter.Model then
	--			Ended = true

	--			self:Afflict(VictimLuaPlayer, {
	--				ExcludeAttempts = true,
	--				FinisherKill = true
	--			})

	--			VictimAnimation:Stop(0)

	--			VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")
	--			VictimCombat.Ragdoll:SetCollisionGroupOfColliders("NoPlayerCollision")

	--			VictimLuaCharacter:Anchor(false)

	--			VictimCombat.Ragdoll:Toggle(true, 2.1)
	--			VictimCombat:Unstun()

	--			task.delay(0.5 + (not VictimLuaPlayer.IsNPC and VictimLuaPlayer.Player:GetNetworkPing() or 0), function()
	--				if not VictimCombat:GetState("Grabbed") then
	--					VictimLuaCharacter:SetCollisionGroup("Player")
	--				end

	--				VictimCombat.Ragdoll:SetCollisionGroupOfColliders("Default")
	--			end)

	--			VictimCombat:StackState("GrabIFrames", false)
	--		end

	--		task.wait(0.35)

	--		self:Close()
	--	end,
	--}
}
