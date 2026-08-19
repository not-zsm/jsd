local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

return {
	UsingAttacks = {
		"Limitless Strikes", "Flowing Hands", -- For Skill Builder
		
		"Reverse Cursed Technique",
		"Maximum Output - Purple"
	};
	VaultedAttacks = {
		"Limitless Strikes", "Flowing Hands", "Ruthless Kicks",
	};
	
	Attacks = {
		["Ruthless Beatdown"] = Enum.KeyCode.One,
		["Lapse Pull"] = Enum.KeyCode.Two,
		["Sweep"] = Enum.KeyCode.Three,
		["Palm Strikes"] = Enum.KeyCode.Four
	},
	
	FrontDash = {
		StartSpeed = 1,
		MiddleSpeed = 0.85
	},
	
	Stats = {
		M1 = {
			Speed = 1.45,
			EndlagAfterSwing = 0.12,
		},
	},

	Ultimate = {
		Name = "NO MORE HOLDING BACK..",
		
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 76, 255)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
		}),
		
		Attacks = {
			["Inhumane Speed"] = Enum.KeyCode.One,
			["Max Blue"] = Enum.KeyCode.Two,
			["0.2 Expansion"] = Enum.KeyCode.Three,
			["Ruthless Massacre"] = Enum.KeyCode.Four,
			["Maximum Output - Purple"] = Enum.KeyCode.Five,
		},
		
		Function = function(self)
			local Animation : AnimationTrack = self.Animations[self.Combat.CurrentCharacter.Name].Start
			
			for _, Event in {"drop", "jump", "shine", "fall", "land", "stance"} do
				Animation:GetMarkerReachedSignal(Event):Wait()
				
				if Event == "jump" then
					self.LuaCharacter.RootPart.Anchored = true -- fix going through the floor if you're under a roof
					
					self.Thread.OnClosed:Connect(function()
						self.LuaCharacter.RootPart.Anchored = false 
					end)
					
					local Hitbox = self:CreateHitbox(false);
					Hitbox.Params.Offset = CFrame.new(0, 2.5, 0)
					Hitbox.Params.Size = Vector3.one * 15

					Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
						local VictimLuaCharacter = VictimLuaPlayer.Character
						local VictimCombat = VictimLuaCharacter.Combat

						local Validated = self:Afflict(VictimLuaPlayer, {
							TriggerActiveCounterOverOrEqualLevel = -1,
							BreakBlock = true,
							Damage = 2.5,
							Ragdoll = 5,
							Velocity = {Vector3.new(Utility.Seed:NextNumber(-5, 5), 110, Utility.Seed:NextNumber(-5, 5)), 0.05}
						})
						
						if Validated then
							VictimLuaCharacter.RootPart.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(30, -30), 0, Utility.Seed:NextNumber(30, -30))
							self.Combat:VictimImpactGround(VictimLuaPlayer)
						end
					end)

					Hitbox:BeginCast(0.05)
					
				elseif Event == "land" then
					self.LuaCharacter.RootPart.Anchored = false
					
					local Hitbox = self:CreateHitbox(false);
					Hitbox.Params.Offset = CFrame.new(0, 10, 0)
					Hitbox.Params.Size = Vector3.one * 35

					Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
						local VictimLuaCharacter = VictimLuaPlayer.Character
						local VictimCombat = VictimLuaCharacter.Combat

						self:Afflict(VictimLuaPlayer, {
							TriggerActiveCounterOverOrEqualLevel = -1,
							BreakBlock = true,
							Damage = 10,
							Ragdoll = 2,
							Velocity = {(VictimLuaPlayer.Character.RootPart.Position - self.LuaCharacter.RootPart.Position).Unit * 45 + Vector3.yAxis * 50, 0.05}
						})
					end)

					Hitbox:BeginCast(0.05)
				end

				local CapitalizedText = string.upper(string.sub(Event, 1, 1)) .. string.sub(Event, 2, -1) -- converts first letter into a capital lol
				self:FireReliableVFX("Gojo/Ultimate", CapitalizedText, self.LuaCharacter.RootPart)
			end
	
			task.wait(1)

			self:Close()
		end
	},

	WallCombo = {
		DistanceFromWall = 7,
		VictimOffset = CFrame.new(0, 0, -3.5) * CFrame.Angles(0, math.pi, 0),

		Function = function(self, VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			
			local VictimModel = VictimLuaCharacter.Model

			local AttackerAnimation = self.Animations.WallCombo.Gojo.Normal
			local VictimAnimation = VictimLuaCharacter.Humanoid:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Gojo.Victim)
			
			local Ended = false
			
			self.Thread.OnClosed:Connect(function()
				self.LuaPlayer.Replication.Attributes:SetAttribute("GojoWallCombo", nil)
				
				self.LuaCharacter:Anchor(false)
				VictimLuaCharacter:Anchor(false)

				if not Ended then
					self.Combat:StackState("GrabIFrames", false)
					VictimCombat:StackState("GrabIFrames", false)
					VictimCombat:Unstun()
				else
					task.delay(0.5, function()
						self.Combat:StackState("GrabIFrames", false)
					end)
				end
				
				AttackerAnimation:Stop()

				VictimAnimation:Stop()
				VictimAnimation = nil
			end)
			
			self.Thread.CancelJob:Task(
				self:CreateMoveSFX("Gojo", "Wall Combo")
			)
			
			AttackerAnimation:Play()
			VictimAnimation:Play()
			
			AttackerAnimation.TimePosition = 0.1
			VictimAnimation.TimePosition = 0.1
			
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("step"):Connect(function(Parameter : string)
				self:FireReliableVFX("Gojo/Wall Combo", "Step", self.LuaCharacter.RootPart, Parameter)
			end))
			
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("slam"):Connect(function()
				self:FireReliableVFX("Gojo/Wall Combo", "Slam", self.LuaCharacter.RootPart)
				
				task.wait(0.5)
				
				self:FireReliableVFX("Gojo/Wall Combo", "Land", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("kick"):Connect(function()
				self:FireReliableVFX("Gojo/Wall Combo", "Kick", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("infinity"):Connect(function()
				self.LuaPlayer.Replication.Attributes:SetAttribute("GojoWallCombo", true)
				self:FireReliableVFX("Gojo/Wall Combo", "Infinity", self.LuaCharacter.RootPart)
			end))

			AttackerAnimation:GetMarkerReachedSignal("end"):Wait()

			self.LuaPlayer.Replication.Attributes:SetAttribute("GojoWallCombo", nil)

			if VictimModel == VictimLuaCharacter.Model then
				self:FireReliableVFX("Gojo/Wall Combo", "End", self.LuaCharacter.RootPart)
				self.Combat.Hitbox:Destruction(CFrame.new(0, 0, -3), Vector3.new(10, 10, 10), 2)

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 10
				})

				VictimAnimation:Stop(0)

				VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")
				VictimCombat.Ragdoll:SetCollisionGroupOfColliders("NoPlayerCollision")

				VictimLuaCharacter:Anchor(false)
				
				Ended = true
				VictimCombat:StackState("GrabIFrames", false)

				task.delay(3/60, function()
					local VelocityObject = self:VelocityOn(VictimCombat)
					
					if VelocityObject then
						VelocityObject.Settings.RemoveTime = 0.1
						VelocityObject.Settings.Velocity = -self.LuaCharacter.RootPart.CFrame.LookVector * 50 + Vector3.yAxis * 45
						VelocityObject:Fire()
					end
					
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true;
						Ragdoll = 2;
					})
					
					--VictimCombat.Ragdoll:Toggle(true, 2)
					VictimCombat:Unstun()
				end)

				task.delay(0.5 + (not VictimLuaPlayer.IsNPC and VictimLuaPlayer.Player:GetNetworkPing() or 0), function()
					if not VictimCombat:GetState("Grabbed") then
						VictimLuaCharacter:SetCollisionGroup("Player")
					end

					VictimCombat.Ragdoll:SetCollisionGroupOfColliders("Default")
				end)
			end
			
			task.wait(0.75)
			
			self:Close()
		end,
	},
	
	SpawnAnimationRng = 50,
	
	OnRespawn = function(LuaPlayer, _, Rng : number)
		local Animation : AnimationTrack = LuaPlayer.Character.Animator:LoadAnimation(ReplicatedStorage.Animations.CharacterSpawnAnimations.Gojo[Rng == 1 and "Spawn2" or "Spawn"])
		Animation:Play()
		
		local Sound : Sound = script[Rng == 1 and "Rare" or "Common"]:Clone()
		Sound.Parent = LuaPlayer.Character.RootPart

		local function PlaySound()
			Sound:Play()
			task.delay(Sound.TimeLength, Sound.Destroy, Sound)
		end

		if not Sound.IsLoaded then
			Sound.Loaded:Once(PlaySound)
		else
			PlaySound()
		end

		return Animation
	end,
}
