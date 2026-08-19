local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnubisAnimations = ReplicatedStorage.Animations.Attacks.Global.Ultimate.Anubis

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Anubis_Utility = require(ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.List.Anubis["Anubis Utility"])

return {
	--Whitelist = Anubis_Whitelist,
	--RestrictSetCharacter = true,

	UsuableAttacks = {
		"Death Sprial"
	};
	
	FrontDash = {
		TryCustomHit = true,
		TryCustomStart = true,
		HitAnimStarted = true,

		StartSpeed = 1,
		MiddleSpeed = 0.85
	},

	Stats = {
		M1 = {
			--Speed = 1,
			--EndlagAfterSwing = 0.075,
			
			Speed = 1.125,
			EndlagAfterSwing = 0.075,
		},
	},

	M1 = {
		StartFunction = function(self)
			if (self.Condition ~= nil) then
				return
			elseif self.Count < 4 then
				
				--if self.Combat:GetState("AirLocked") or self.Combat:GetState("UpTilted") then
				--	Anubis_Utility.AirLock(self.Combat, true)
				--	Anubis_Utility.SetUpTilted(self.Combat, true)
					
				--	self.Combat.Job:Task(task.delay(if table.find({2, 3}, self.Count) then 0.65 else 0.45, function()
				--		Anubis_Utility.AirLock(self.Combat, false)
						
				--		self.Combat.Job:Task(task.delay(0.15, function()
				--			Anubis_Utility.SetUpTilted(self.Combat, false)
				--		end))
				--	end))
				--end
				
			else
				local Weapon = self.Combat.Attacks["Anubis Weapon"]

				if (Weapon == nil) then
					return
				end

				Weapon:Sheathe()
			end
		end,

		EndFunction = function(self)
			if self.Count ~= 4 or self.Condition ~= nil then
				return
			end

			local Weapon = self.Combat.Attacks["Anubis Weapon"]

			if (Weapon == nil) then
				return
			end

			Weapon:Unsheathe()
		end,
	},

	Attacks = {
		["Possession Flurry"] = Enum.KeyCode.One,
		["Wailing Fang"] = Enum.KeyCode.Two,
		["Crypt Cutter"] = Enum.KeyCode.Three,
		--["Sky Fang"] = Enum.KeyCode.Three,
		--["Death Spiral"] = Enum.KeyCode.Three,
		["Evil Spirit"] = Enum.KeyCode.Four,
		["Pose"] = Enum.KeyCode.R
	},

	Ultimate = {
		Name = "Phantom Dominion",

		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(102, 51, 153)),
			--ColorSequenceKeypoint.new(0.25, Color3.fromRGB(237, 138, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(212, 83, 255)),
			--ColorSequenceKeypoint.new(0.75, Color3.fromRGB(237, 138, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(102, 51, 153)),
		}),
		
		OneTimePop = true,
		CanRotate = true,
		DontHeal = true,
		CanSeeUI = true,

		Function = function(self, StartAnimation : AnimationTrack)
			--StartAnimation:Play(nil, 1, 1)
			self.Combat:StackState("HitboxImmunity", true)
			self.Combat:StackState("Attacking", true)
			self.Combat:DivideSpeed(50)
			
			self.LuaCharacter:Heal(45)
			
			local UltHit = false
			
			local function SyncedFrameDelay(duration : number, callback : (...any) -> (), ...)
				-- return self.Thread.Job:Task(task.delay(math.max(0, (duration/60) - StartAnimation.TimePosition), callback, ...))

				return self.Thread.Job:Task(task.delay(math.max(0, (duration/60) - StartAnimation.TimePosition), function(...)
					if not UltHit then
						callback(...)
					end
				end))
			end
			
			self.Thread.OnClosed:Connect(function()
				self.Combat:TimesSpeed(50)
				self.Combat:StackState("HitboxImmunity", false)
				self.Combat:StackState("Attacking", false)
			end)
			
			self.Thread.Job:Task(StartAnimation.Stopped:Once(function()
				if not UltHit then
					self:Close()
				end
			end))

			local Root : BasePart = self.Combat:GetSimulatedRoot()
			
			SyncedFrameDelay(200, function()
				local SliceHitbox = self:CreateHitbox()
				SliceHitbox.Params.Size = Vector3.new(9, 12, 13)
				SliceHitbox.Params.Offset = CFrame.new(0, 3, -3)
				
				SliceHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
					local VictimLuaCharacter = VictimLuaPlayer.Character
					local VictimCombat = VictimLuaCharacter.Combat

					if not UltHit then
						local Validated = self:Afflict(VictimLuaPlayer, {
							TriggerActiveCounterOverOrEqualLevel = -1,
							DontCheckBlock = true,
						})

						if Validated then
							UltHit = true
							VictimCombat:StackState("HitboxImmunity", true)

							self.LuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.Angles(0, math.pi, 0))
							self.LuaCharacter:Anchor(true)

							self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

							VictimLuaCharacter:StopRespawnTimer()

							local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart)

							local UserAnim : AnimationTrack = self.LuaCharacter:LoadAnimation(AnubisAnimations.User)
							local VictimAnim : AnimationTrack = VictimLuaCharacter:LoadAnimation(AnubisAnimations.Victim)

							self.Combat:HideUI(true)
							VictimCombat:HideUI(true)

							self.LuaCharacter.Model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

							self.Thread.OnClosed:Connect(function()
								UserAnim:Stop(0)

								if VictimAnim then
									VictimAnim:Stop(0)
								end

								self.Combat:HideUI(false)
								VictimCombat:HideUI(false)

								self.LuaCharacter:Anchor(false)

								if not GrabObject.Destroyed then
									GrabObject.Destroy(0)
									VictimCombat:Unstun()
								end

								VictimLuaCharacter:RestartRespawnTimer()
								VictimCombat:StackState("HitboxImmunity", false)

								self.LuaCharacter.Model.ModelStreamingMode = Enum.ModelStreamingMode.Default
							end)

							StartAnimation:Stop(0)
							UserAnim:Play(0)

							if VictimAnim then
								VictimAnim:Play(0)
							end

							self:FireReliableVFX("Anubis/Ultimate", "UltimateHit", self.LuaCharacter.Model, VictimLuaCharacter.Model, self.Combat.Sword, self.Combat.Sheathe)

							self.Thread.Job:Task(UserAnim:GetMarkerReachedSignal("KillVictim"):Connect(function(Parameter)
								local CF = self.Combat:GetSimulatedRoot().CFrame

								GrabObject.Destroy(0)
								VictimLuaCharacter.Model:PivotTo(CF * CFrame.new(0, 0, -12) * CFrame.Angles(0, math.pi, 0))

								if VictimAnim then
									VictimAnim:Stop(0)
								end

								self:Afflict(VictimLuaPlayer, {
									ExcludeAttempts = true,
									FinisherKill = true,
								})

								VictimCombat:Unstun()
							end))

							self.Thread.Job:Task(UserAnim.Stopped:Once(function()
								self:Close()
							end))
						end
					else
						local ForwardVelocity = {Root.CFrame.LookVector * 30, 0.1} 

						local Validated = self:Afflict(VictimLuaPlayer, {
							TriggerActiveCounterOverOrEqualLevel = -1,
							DontBypassIFrames = {},
							Damage = 20,
							TrueStun = 2,
							DontCheckBlock = true,
							Velocity = ForwardVelocity,
							DontRestartRespawnTimer = true,
							PlayRandomHitReaction = true
						})

						if Validated then
							self:FireReliableVFX("Anubis/Possession Flurry", "Emit", VictimLuaCharacter.RootPart, "HitEffect")
						end
					end
				end)

				SliceHitbox:BeginCast(0.05)
			end)
			
			for _, Frame in {241, 261} do
				SyncedFrameDelay(Frame, function()
					local SlashHitbox = self:CreateHitbox(true)
					SlashHitbox.Params.Offset = CFrame.new(0, 0, -4)
					SlashHitbox.Params.Size = 10

					SlashHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
						local VictimLuaCharacter = VictimLuaPlayer.Character
						local VictimCombat = VictimLuaCharacter.Combat

						local ForwardVelocity = {Root.CFrame.LookVector * 10, 0.1} 

						local Validated = self:Afflict(VictimLuaPlayer, {
							TriggerActiveCounterOverOrEqualLevel = -1,
							Damage = 10,
							TrueStun = 2,
							DontCheckBlock = true,
							Velocity = ForwardVelocity,
							DontRestartRespawnTimer = true,
							PlayRandomHitReaction = true
						})

						if Validated then
							self:FireReliableVFX("Anubis/Possession Flurry", "Emit", VictimLuaCharacter.RootPart, "HitEffect")
						end
					end)

					SlashHitbox:BeginCast(0.05)
					
					local ProjectileName = if Frame == 241 then "AnubisSlash 1" else "AnubisSlash 2"
					
					local Projectile = self.Combat.Projectiles:Create(ProjectileName, self.LuaCharacter.RootPart.Position, self.LuaCharacter.RootPart.CFrame.LookVector * 230, {
						HeightenWithGround = false,
						Height = 0,
						MaxDistance = 350,
						DetectionSize = 8
					})

					Projectile.Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
						self:Afflict(VictimLuaPlayer, {
							DontBypassIFrames = {},
							BreakBlock = true,

							Damage = {
								Amount = 10,
								DontCountToUltimate = true
							},

							TriggerActiveCounterOverOrEqualLevel = 2,

							Ragdoll = 2,
							Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 60 + Vector3.yAxis * 10, 0.1},
						})
						
						self:FireReliableVFX("Anubis/Ultimate", "ProjectileHit", VictimLuaPlayer.Character.RootPart, true)
						
						Projectile:Destroy()
					end)

					Projectile:Start()
				end)
			end

			SyncedFrameDelay(366, function()
				local Root : BasePart = self.Combat:GetSimulatedRoot()

				local Raycast = workspace:Raycast(Root.Position + Vector3.yAxis * 2, Vector3.yAxis * -50, Utility.VisualParams)
				local Distance = Raycast and Raycast.Distance or 0
				
				local SlamHitbox = self:CreateHitbox()
				SlamHitbox.Params.Offset = CFrame.new(0, -(Distance / 2), -4)
				SlamHitbox.Params.Size = Vector3.one * 30
				
				local Rnd = Random.new();
				
				self.Combat.Hitbox:CreateHavocReplicated({
					parameters = {
						origin = SlamHitbox:GetCFrame(),
						shape = "Sphere", 
						radius = 18,
						block_size = 8,
					},
					debris = {
						scale = 0.9,
						velocity = function(part)
							return Rnd:NextUnitVector() * 25 + Vector3.yAxis * 100;
						end,
					},
				});
				
				self.Thread.OnClosed:Connect(function()
					SlamHitbox:Destroy()
				end)

				SlamHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
					self:Afflict(VictimLuaPlayer, {
						TriggerActiveCounterOverOrEqualLevel = -1,
						DontBypassIFrames = {},
						Damage = 30,
						Ragdoll = 3,
						DontCheckBlock = true,
						Velocity = {self.Combat:CalculateUnitDifference(VictimLuaPlayer) * 60 + Vector3.yAxis * 125, 0.05},
						DontRestartRespawnTimer = true,
						PlayRandomHitReaction = true
					})
				end)
				
				SlamHitbox:Detect()
			end)
			
			self:FireReliableVFX("Anubis/Ultimate", "Start", self.LuaCharacter.Model, self.Combat.Sword)
		end,
	},

	OnSpawn = function(LuaPlayer, UseDescription : boolean?)
		local Sheathe = script.Sheathe:Clone()
		local SheatheHandle = Sheathe.M6D
		SheatheHandle.Part0 = LuaPlayer.Character.LeftArm
		SheatheHandle.Name = "SheatheHandle"
		SheatheHandle.Parent = LuaPlayer.Character.LeftArm
		Sheathe.Parent = LuaPlayer.Character.Model

		LuaPlayer.Character.Combat.Sheathe = {
			Model = Sheathe,
			Handle = SheatheHandle,
		}

		local Sword = script.Anubis:Clone()
		local SwordHandle = Sword.M6D
		SwordHandle.Part0 = LuaPlayer.Character.RightArm
		SwordHandle.Name = "Handle"
		SwordHandle.Parent = LuaPlayer.Character.RightArm
		Sword.Parent = LuaPlayer.Character.Model

		LuaPlayer.Character.Combat.Sword = {
			Model = Sword,
			Handle = SwordHandle
		}

		local M1Attack, Exsists = LuaPlayer.Character.Combat:MatchAttack("M1", Enum.UserInputType.MouseButton1)

		if Exsists then
			M1Attack.Damage[3] = 1
		end
		
		LuaPlayer.Character.Combat:CreateAttack("Anubis Weapon")
		LuaPlayer.Character.Combat:CreateAttack("Adapt")
	end,

	OnRemoved = function(LuaPlayer)
		local M1Attack, Exsists = LuaPlayer.Character.Combat:MatchAttack("M1", Enum.UserInputType.MouseButton1)

		if Exsists then
			M1Attack.Damage[3] = 2
		end

		for _, SwordName in {"Sheathe", "Sword"} do
			local SwordTable = LuaPlayer.Character.Combat[SwordName]

			if SwordTable == nil then
				continue
			end

			if SwordTable.Model then
				SwordTable.Model:Destroy()
			end

			if SwordTable.Handle then
				SwordTable.Handle:Destroy()
			end

			SwordTable = nil
			LuaPlayer.Character.Combat[SwordName] = nil
		end

		LuaPlayer.Character.Combat:RemoveAttack("Anubis Weapon")
		LuaPlayer.Character.Combat:RemoveAttack("Adapt")
		
		if LuaPlayer.Character.PassiveMultipliers then
			LuaPlayer.Character.PassiveMultipliers = nil
		end
	end,
	
	WallComboFinisher = {
		DistanceFromWall = 6,
		VictimOffset = CFrame.new(0, 0, -4.5) * CFrame.Angles(0, math.pi, 0),

		Condition = function(VictimLuaPlayer)
			return VictimLuaPlayer.Character.Humanoid.Health <= 15
		end,

		DontPutIFrames = true,

		Function = function(self, VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local UserAnimation : AnimationTrack = self.Animations.WallCombo.Anubis.FinisherUser
			local VictimAnimation : AnimationTrack? = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Anubis.FinisherVictim)
			local VictimFlung = false

			self.Combat:StackState("HitboxImmunity", true)
			VictimCombat:StackState("HitboxImmunity", true)

			self.Thread.OnClosed:Connect(function()
				VictimLuaCharacter:RestartRespawnTimer()

				UserAnimation:Stop()

				if VictimAnimation then
					VictimAnimation:Stop()
				end

				self.LuaCharacter:Anchor(false)
				
				self.Combat:StackState("HitboxImmunity", false)
				VictimCombat:StackState("HitboxImmunity", false)

				if not VictimFlung then
					VictimLuaCharacter:Anchor(false)
					VictimCombat:Unstun()
				end
			end)
			
			self.Thread.CancelJob:Task(self:CreateMoveSFX("Anubis", "Wall Combo", "FinisherSFX"))

			UserAnimation:Play(0)

			if VictimAnimation then
				VictimAnimation:Play(0)
			end

			self.Thread.Job:Task(UserAnimation:GetMarkerReachedSignal("dmg"):Connect(function(Parameter : string)
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {Amount = tonumber(Parameter), DontKill = true},
				})
			end))

			self.Thread.Job:Task(UserAnimation:GetMarkerReachedSignal("fling"):Once(function()
				do
					local Weapon = self.Combat.Attacks["Anubis Weapon"]

					if (Weapon ~= nil) then
						Weapon:Sheathe()
					end

					self.Thread.OnClosed:Connect(function()
						local Weapon = self.Combat.Attacks["Anubis Weapon"]

						if (Weapon ~= nil) then
							Weapon:Unsheathe()
						end
					end)
				end

				VictimFlung = true
			
				VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -4) * CFrame.Angles(0, math.pi, 0))
				VictimLuaCharacter:Anchor(false)

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					FinisherKill = true,
				})

				VictimAnimation:Stop(0)
				VictimCombat:Unstun()
			end))

			self.Thread.Job:Task(UserAnimation:GetMarkerReachedSignal("end"):Once(function()
				self:Close()
			end))
		end,
	},
	
	WallCombo = {
		DistanceFromWall = 6,
		VictimOffset = CFrame.new(0, 0, -4.5) * CFrame.Angles(0, math.pi, 0),

		Function = function(self, VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local UserAnimation : AnimationTrack = self.Animations.WallCombo.Anubis.User
			local VictimAnimation : AnimationTrack? = VictimLuaCharacter:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Anubis.Victim)
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
			
			self.Thread.CancelJob:Task(self:CreateMoveSFX("Anubis", "Wall Combo"))

			UserAnimation:Play(0)

			if VictimAnimation then
				VictimAnimation:Play(0)
			end

			self.Thread.Job:Task(UserAnimation:GetMarkerReachedSignal("dmg"):Connect(function(Parameter : string)
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {Amount = tonumber(Parameter), DontKill = true},
				})
			end))

			self.Thread.Job:Task(UserAnimation:GetMarkerReachedSignal("fling"):Once(function()
				VictimFlung = true

				VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -4) * CFrame.Angles(0, math.pi, 0))
				VictimLuaCharacter:Anchor(false)

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 4,
					Ragdoll = 2,
					Velocity = {self.LuaCharacter.RootPart.CFrame.RightVector * -45 + Vector3.yAxis * 8.5, 0.1}
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