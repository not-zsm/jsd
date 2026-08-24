local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )

local Whitelist = require( replicatedStorage.modules.shared.Game.Whitelist )

return {
	DisplayName = "Chara",
	Icon = "85316557846229",

	UsingAttacks = {
		"Check",
		--"Death Charge",
	};
	VaultedAttacks = {
		"Death Charge",
	};
	
	Stats = {
		M1 = {
			Speed = 1.3,
			EndlagAfterSwing = 0.1,

			ArmFlashes = {
				[1] = { Limb = "Left Arm", Colour = Color3.fromRGB(255, 60, 60), Duration = 0.35 },
				[2] = false,
				[3] = { Limb = "Right Leg", Colour = Color3.fromRGB(255, 60, 60), Duration = 0.35 },
				[4] = false,

				Up = { Limb = "Right Arm", Colour = Color3.fromRGB(255, 60, 60), Duration = 0.4 },
				Down = { Limb = "Right Leg", Colour = Color3.fromRGB(255, 60, 60), Duration = 0.4 },
			},
		},
	},

	Attacks = {
		["Onslaught"] = Enum.KeyCode.One, 
		-- feral takedown - air variant
		-- spiraling cascade - ragdoll variant

		["Lethal Wound"] = Enum.KeyCode.Two,
		["Bloody Mary"] = Enum.KeyCode.Three,
		["Fight"] = Enum.KeyCode.Four,
		--["Shatter Slashes"] = Enum.KeyCode.Five,
		--["Special Hell"] = Enum.KeyCode.Six
	},

	Ultimate = {
		Name = "SINCE WHEN WERE YOU THE ONE IN CONTROL?",

		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(181, 53, 53)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(109, 32, 32)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(181, 53, 53)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
		}),

		DontHeal = true,
		CanUseWhileDead = true,
		ManuallyFireStartRemote = true,
		
		OnStart = function(self)
			self.Combat:TimesSpeed(1.3)

			self.Combat.Attacks.Ultimate.OnUltimateEnded:Once(function()
				self.Combat:DivideSpeed(1.3)
			end)
		end,

		Function = function(self)
			if self.LuaCharacter.Humanoid.Health <= 10 then -- alt

				if not self.LuaCharacter.HumanoidAlive then
					self.LuaCharacter:StopRespawnTimer()

					self.LuaCharacter.HumanoidAlive, self.LuaCharacter.HumanoidExists = true, true 
					network.humanoidRevived.sendTo(nil, self.LuaPlayer.Player)
					self.LuaCharacter:StartRegen()

					self.Combat.AwardedToSomeoneAsKill = false
					
					if self.Combat.HasFinisherKillIFrames then
						self.Combat:StackState("HitboxImmunity", false)
					end

					self.Combat:ResetStun()
					self.Combat.Ragdoll:ForceToggleOff()
				end

				local Animation : AnimationTrack = self.Animations[self.Combat.CurrentCharacter.Name].Alt.Start
				Animation:Play(0)

				self:FireReliableVFX("Chara/Ultimate_Alt", "Start", self.LuaCharacter.Model)

				self.Thread.OnClosed:Connect(function()
					self:FireReliableVFX(`Chara/Ultimate`, "OnUltimateStart", self.LuaCharacter.Model)
				end)
				
				self.Thread.Job:Task(Animation:GetMarkerReachedSignal("pause"):Once(function()
					task.wait(0.75)
					Animation:Stop()
				end))

				self.Thread.Job:Task(Animation.Stopped:Once(function()
					self:Close()
				end))

				self.LuaCharacter:Heal(25)
			else
				self.LuaCharacter:Anchor(true, true)

				self.Thread.OnClosed:Connect(function()
					self.LuaCharacter:Anchor(false)
				end)
				
				local Animation : AnimationTrack = self.Animations[self.Combat.CurrentCharacter.Name].Default.Start
				Animation:Play(0)

				self.Thread.Job:Task(Animation:GetMarkerReachedSignal("transition"):Once(function()
					self:FireReliableVFX(`Chara/Ultimate`, "OnUltimateStart", self.LuaCharacter.Model)
					self.LuaCharacter:Anchor(false)
					Animation:AdjustSpeed(1.1)
				end))

				self:FireReliableVFX("Chara/Ultimate", "Start", self.LuaCharacter.Model)

				self.Thread.Job:Task(Animation.Stopped:Once(function()
					self:Close()
				end))

				self.LuaCharacter:HealFull()
			end
		end,

		--function(self)
		--	local Animation : AnimationTrack = self.Animations[self.Combat.CurrentCharacter.Name].Alt.Start
		--	Animation:Play(0)

		--	self:FireReliableVFX("Chara/Ultimate_Alt", "Start", self.LuaCharacter.Model)

		--	--self.Thread.Job:Task(Animation:GetMarkerReachedSignal("pause"):Once(function()
		--	--	task.wait(0.75)
		--	--	Animation:Stop()
		--	--end))

		--	self.Thread.Job:Task(Animation.Stopped:Once(function()
		--		self:Close()
		--	end))
		--end

		--function(self)
		--	local Animation : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(game.ReplicatedStorage.Animations.Emotes["Tuff Floss Boi"])
		--	Animation:Play(0)
			
		--	local Animation2 : AnimationTrack = self.Animations[self.Combat.CurrentCharacter.Name].Alt.Start
		--	Animation2:Play(0, 0.001, 0.001)

		--	self:FireReliableVFX("Chara/Ultimate_Alt", "Start", self.LuaCharacter.Model)
			
		--	self.Thread.Job:Task(task.delay(10, function()
		--		self:Close()
		--	end))
		--end

		--Attacks = {
		--	["Cursed Remedy"] = Enum.KeyCode.One,
		--	["Shatter Slashes"] = Enum.KeyCode.Two, 
		--	["Special Hell"] = Enum.KeyCode.Three, 
		--	["Reset"] = Enum.KeyCode.Four, 
		--},
		
		Attacks = {
			["Cursed Remedy"] = Enum.KeyCode.One,
			["Reset"] = Enum.KeyCode.Two,
			["Atonement"] = Enum.KeyCode.Three,
			["Seven Souls"] = Enum.KeyCode.Four,
			["Special Hell"] = Enum.KeyCode.Five,
		},
	},

	FrontDash = {
		TryCustomHit = true,
		TryCustomStart = true,

		StartSpeed = 1,
		MiddleSpeed = 1
	},

	OnRespawn = function(LuaPlayer, _, Rng : number)
		local Animation : AnimationTrack = LuaPlayer.Character.Animator:LoadAnimation(replicatedStorage.Animations.CharacterSpawnAnimations.Chara.Spawn)

		Animation:Play()
		LuaPlayer.Replication:FireReliableVFX("Chara/Spawn", "Start", LuaPlayer.Character.Model)

		return Animation
	end,

	OnSpawn = function(LuaPlayer, UseDescription : boolean?)
		local LuaCharacter = LuaPlayer.Character
		local Combat = LuaCharacter.Combat
		
		LuaPlayer.PermittedToCharaBossMoves = Whitelist.is_permitted(LuaPlayer.UserId, "Cursed Child Boss Moves")
		
		if LuaPlayer.PermittedToCharaBossMoves then
			Combat:CreateAttack("Shatter Slashes", Enum.KeyCode.Five)
			Combat:CreateAttack("Boss Special Hell", Enum.KeyCode.Six)
		end
		
		local Ultimate = Combat:GetFirstAttack("Ultimate")
		
		if Ultimate then
			Combat.SpawnJob:Task(Ultimate.OnUltimateBegan:Connect(function()
				if LuaPlayer.PermittedToCharaBossMoves then
					Combat:RemoveAttack("Shatter Slashes", Enum.KeyCode.Five)
					Combat:RemoveAttack("Boss Special Hell", Enum.KeyCode.Six)
				end
			end))
			
			Combat.SpawnJob:Task(Ultimate.OnUltimateEnded:Connect(function()
				if Whitelist.is_permitted(LuaPlayer.UserId, "Cursed Child Boss Moves") then -- Recheck incase they got removed from the whitelist
					Combat:CreateAttack("Shatter Slashes", Enum.KeyCode.Five)
					Combat:CreateAttack("Boss Special Hell", Enum.KeyCode.Six)
				end
			end))
		end
		
		if (LuaPlayer.Player:GetAttribute("Accessories") and LuaPlayer.Character.CharaNecklace == nil) then
			local Necklace = script.Necklace:Clone()
			Necklace.Weld.Part1 = LuaPlayer.Character.Model.Torso
			Necklace.Parent = LuaPlayer.Character.Model

			LuaPlayer.Character.CharaNecklace = Necklace
		end

		if (LuaPlayer.Character.Combat.Sword == nil) then
			local Sword = script.Knife:Clone()
			Sword.Weld.Part0 = LuaPlayer.Character.RightArm
			Sword.Parent = LuaPlayer.Character.Model

			LuaPlayer.Character.Combat.Sword = Sword
		end
	end,

	OnRemoved = function(LuaPlayer)
		if LuaPlayer.PermittedToCharaBossMoves then
			LuaPlayer.Character.Combat:RemoveAttack("Shatter Slashes", Enum.KeyCode.Five)
			LuaPlayer.Character.Combat:RemoveAttack("Boss Special Hell", Enum.KeyCode.Six)
			LuaPlayer.PermittedToCharaBossMoves = nil
		end
		
		if LuaPlayer.Character.CharaNecklace then
			LuaPlayer.Character.CharaNecklace:Destroy()
			LuaPlayer.Character.CharaNecklace = nil
		end

		if LuaPlayer.Character.Combat.Sword then
			LuaPlayer.Character.Combat.Sword:Destroy()
			LuaPlayer.Character.Combat.Sword = nil
		end
	end,

	WallCombo = {
		DistanceFromWall = 2.486,

		Function = function(self, VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local UserAnimation : AnimationTrack = self.Animations.WallCombo.Chara.User
			local VictimAnimation : AnimationTrack? = VictimLuaCharacter:LoadAnimation(replicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Chara.Victim)
			local VictimFlung = false

			self.Thread.OnClosed:Connect(function()
				UserAnimation:Stop()

				if VictimAnimation then
					VictimAnimation:Stop()
				end

				self.LuaCharacter:Anchor(false)
				VictimCombat:StackState("GrabIFrames", false)

				if not VictimFlung then
					self.Combat:StackState("GrabIFrames", false)

					VictimLuaCharacter:Anchor(false)
					VictimCombat:Unstun()
				else
					task.delay(0.5, self.Combat.StackState, self.Combat, "GrabIFrames", false)
				end
			end)

			self.Thread.CancelJob:Task(self:CreateMoveSFX("Chara", "Wall Combo"))

			UserAnimation:Play(0)

			if VictimAnimation then
				VictimAnimation:Play(0)
			end

			self.Thread.Job:Task(UserAnimation:GetMarkerReachedSignal("stab"):Connect(function()
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {Amount = 1, DontKill = true},
				})
			end))

			self.Thread.Job:Task(UserAnimation:GetMarkerReachedSignal("big_stab"):Once(function()
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {Amount = 3, DontKill = true}
				})
			end))

			self.Thread.Job:Task(UserAnimation:GetMarkerReachedSignal("hit"):Once(function()
				VictimFlung = true

				VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -2.486) * CFrame.Angles(0, math.pi, 0))
				VictimLuaCharacter:Anchor(false)

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 2,
					Ragdoll = 2,
					Velocity = {self.LuaCharacter.RootPart.CFrame.RightVector * 75 + Vector3.yAxis * 8.5, 0.1}
				})

				VictimAnimation:Stop(0)
				VictimCombat:Unstun()
			end))

			self.Thread.Job:Task(UserAnimation:GetMarkerReachedSignal("end"):Once(function()
				self:Close()
			end))
		end,
	}
}