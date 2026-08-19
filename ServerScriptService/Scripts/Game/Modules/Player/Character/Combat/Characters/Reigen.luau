local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GrabRemotes = ReplicatedStorage.Remotes.Grab

return {
	Stats = {
		M1 = {
			Speed = 0.775,
			EndlagAfterSwing = 0.21,
		},
	},
	
	UsingAttacks = {
		"CRASHOUT",
		"ERADICATE",
		"Spirit Link", -- For Skill Builder
		"SALTO SPLASHO!!!",
	};
	VaultedAttacks = {
		"Spirit Link",
		"SALTO SPLASHO!!!",
	};
	
	Attacks = {
		["SELF DEFENSE RUSH!!!"] = Enum.KeyCode.One,
		["SALT PUAAANNCH"] = Enum.KeyCode.Two,
		["GET A JOB YOU BUM!!!"] = Enum.KeyCode.Three,
		["GO GREEN BLOB!"] = Enum.KeyCode.Four,
		["YOU THOUGHT!"] = Enum.KeyCode.R
	},

	OnRespawn = function(LuaPlayer, Job)
		local Animation : AnimationTrack = LuaPlayer.Character.Animator:LoadAnimation(ReplicatedStorage.Animations.CharacterSpawnAnimations.Reigen.Spawn)

		local Hand = script.RightHandle:Clone()
		Hand.Weld.Part0 = LuaPlayer.Character.RightArm

		for _, Item in ipairs(Hand:GetDescendants()) do
			if Item:IsA("BasePart") then
				Item.Color = LuaPlayer.Character.RightArm.Color
			end
		end

		Hand.Parent = LuaPlayer.Character.Model
		Animation:Play()

		Animation.Stopped:Once(function()
			Hand:Destroy()
		end)

		local Sound : Sound = script.SFX:Clone()
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

		return Animation, Sound
	end,

	OnSpawn = function(LuaPlayer, UseDescription : boolean?)
		if (LuaPlayer.Player:GetAttribute("Accessories") and LuaPlayer.Character.ReigenTie == nil) then
			local Tie = script.Tie:Clone()
			Tie.Weld.Part0 = LuaPlayer.Character.Model.Torso
			Tie.Parent = LuaPlayer.Character.Model
			LuaPlayer.Character.ReigenTie = Tie
		end
	end,

	OnRemoved = function(LuaPlayer)
		if LuaPlayer.Character.ReigenTie then
			LuaPlayer.Character.ReigenTie:Destroy()
			LuaPlayer.Character.ReigenTie = nil
		end
	end,

	Ultimate = {
		Name = "1000%", -- jimpee asked me to change these

		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(162, 85, 255)),
			ColorSequenceKeypoint.new(0.138, Color3.fromRGB(105, 185, 255)),
			ColorSequenceKeypoint.new(0.486, Color3.fromRGB(90, 255, 115)),
			ColorSequenceKeypoint.new(0.578, Color3.fromRGB(146, 113, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(162, 85, 255)),
		}),

		Attacks = {
			["Emotional Damage"] = Enum.KeyCode.One,
			["Mask Remover"] = Enum.KeyCode.Two,
			["1000% Exorcism"] = Enum.KeyCode.Three,
			["Part Time Employee"] = Enum.KeyCode.Four
		},

		PlayAnimationManually = true,

		Function = function(self)
			local Animation : AnimationTrack = self.Animations[self.Combat.CurrentCharacter.Name].Start
			local Offset =  CFrame.new(0, 0, -4) * CFrame.Angles(0, math.pi, 0)

			local Mob = ReplicatedStorage.Effects.Characters.Reigen.Mob:Clone()
			Mob:PivotTo(self.Combat:GetSimulatedRoot().CFrame * Offset)
			Mob.Parent = workspace.Visuals

			local MobHumanoid = Mob:WaitForChild("Humanoid")
			local MobRootPart = Mob:WaitForChild("HumanoidRootPart")
			local MobAnimator = MobHumanoid:WaitForChild("Animator")

			self.Thread.Job:Task(Mob)

			task.wait(2 / 60)

			GrabRemotes.Set:FireAllClients(MobRootPart, self.LuaCharacter.RootPart, Offset)

			self.LuaPlayer.Replication.Attributes:SetAttribute("ReigenUltimateCamera", true)
			self:FireReliableVFXToSelf("Reigen/Ultimate", "Camera", self.LuaCharacter.RootPart)

			self.Thread.OnClosed:Connect(function()
				GrabRemotes.Detach:FireAllClients(MobRootPart)
				Animation:Stop()

				self:FireReliableVFX("Reigen/Ultimate", "Aura1", self.LuaCharacter.Torso, "false")
				self.LuaPlayer.Replication.Attributes:SetAttribute("ReigenUltimateCamera", nil)
			end)

			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("fov"):Connect(function(Parameter : string)
				self:FireReliableVFXToSelf("Reigen/Ultimate", "FOV", tonumber(Parameter))
			end))

			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("blue"):Connect(function(Parameter : string)
				self:FireReliableVFX("Reigen/Ultimate", "Blue", Mob, Parameter)
			end))

			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("red"):Connect(function(Parameter : string)
				self:FireReliableVFX("Reigen/Ultimate", "Red", Mob, Parameter)
			end))

			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("mobinvis"):Connect(function(Parameter : string)
				self:FireReliableVFXToSelf("Reigen/Ultimate", "MobInvis", Mob, Parameter)
			end))

			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("aura1"):Connect(function(Parameter : string)
				self:FireReliableVFX("Reigen/Ultimate", "Aura1", self.LuaCharacter.Torso, Parameter)
			end))

			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("aura2"):Connect(function()
				Mob:Destroy()
				self:FireReliableVFX("Reigen/Ultimate", "OnUltimateStart", self.LuaCharacter.Model)
			end))

			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("burst"):Connect(function()
				self:FireReliableVFX("Reigen/Ultimate", "Burst", self.LuaCharacter.RootPart)
				Animation:AdjustSpeed(0.55)
			end))

			self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "Ultimate"))

			Animation:Play()
			MobAnimator:LoadAnimation(ReplicatedStorage.Animations.Miscellaneous.ReigenAwakeningMob):Play()

			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("end"):Once(function()
				Animation:Stop(0)
				self.LuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.Angles(0, math.pi, 0))
				self:Close()
			end))
		end
	},

	WallCombo = {
		DistanceFromWall = 8.65,

		Function = function(self, VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local VictimModel = VictimLuaCharacter.Model

			local AttackerAnimation = self.Animations.WallCombo.Reigen.User
			local VictimAnimation = VictimLuaCharacter.Humanoid:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Reigen.Victim)

			local Ended = false

			self:CreateMoveSFX("Reigen", "Wall Combo")

			self.Thread.OnClosed:Connect(function()
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

			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("coin"):Connect(function(Parameter : string)
				self:FireReliableVFX("Reigen/Wall Combo", "Coin", self.LuaCharacter.Model, Parameter)

				if Parameter == "true" then
					self.Thread.OnClosed:Connect(function()
						self:FireReliableVFX("Reigen/Wall Combo", "Coin", self.LuaCharacter.Model, "false")
					end)
				end
			end))

			AttackerAnimation:Play()
			AttackerAnimation.TimePosition = 0.01

			AttackerAnimation:GetMarkerReachedSignal("hit"):Wait()

			VictimAnimation:Play(0)

			AttackerAnimation:GetMarkerReachedSignal("end"):Wait()

			Ended = true
			VictimLuaCharacter:Anchor(false)

			self:Afflict(VictimLuaPlayer, {
				ExcludeAttempts = true,
				Damage = 10,
				Ragdoll = 1.75;
			})

			VictimLuaCharacter:SetCollisionGroup("NoPlayerCollision")
			VictimCombat.Ragdoll:SetCollisionGroupOfColliders("NoPlayerCollision")

			VictimAnimation:Stop(0)
			VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -2.9) * CFrame.Angles(0, math.pi, 0))

			task.wait()

			local VelocityObject = self:VelocityOn(VictimCombat)

			if VelocityObject then
				VelocityObject.Settings.RemoveTime = 0.1
				VelocityObject.Settings.Velocity = self.LuaCharacter.RootPart.CFrame.RightVector * 75 + Vector3.yAxis * 30
				VelocityObject:Fire()
			end

			--VictimCombat.Ragdoll:Toggle(true, 1.75)

			task.delay(0.5 + (not VictimLuaPlayer.IsNPC and VictimLuaPlayer.Player:GetNetworkPing() or 0), function()
				if not VictimCombat:GetState("Grabbed") then
					VictimLuaCharacter:SetCollisionGroup("Player")
				end

				VictimCombat.Ragdoll:SetCollisionGroupOfColliders("Default")
			end)

			VictimCombat:StackState("GrabIFrames", false)
			VictimCombat:Unstun()

			task.wait(0.35)

			self:Close()
		end,
	},
}