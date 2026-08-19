local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Whitelist = require( ReplicatedStorage.Modules.Shared.Game.Whitelist )

return {
	GitHubWhitelist = "Gebura",
	DonatorAccess = true,
	
	Stats = {
		M1 = {
			Speed = 1.05,
			EndlagAfterSwing = 0.15,

			LastM1KnocksUp = false,

			Hitbox = {
				Offset = CFrame.new(0, 0, -2.65 * 1.4),
				Size = Vector3.new(6, 6, 6.8 * 1.4)
			}
		},
	},
	
	--M1Speed = 1.05,
	--M1EndlagAfterSwing = 0.15,
	--TimeUntilSwing = 0.125,

	Attacks = {
		["Spear"] = Enum.KeyCode.One,
		["Upstanding Slash"] = Enum.KeyCode.Two,
		["Level Slash"] = Enum.KeyCode.Three,
		--["Pose"] = Enum.KeyCode.P,
	},
	
	FrontDash = {
		TryCustomHit = true,
		TryCustomStart = true,

		StartSpeed = 1.5,
		MiddleSpeed = 1.4,
		PauseSpeed = 0.5
	},
	
	OnSpawn = function(LuaPlayer, UseDescription : boolean?)
		--task.spawn(function()
		--	if not LuaPlayer.Character.AppearanceLoaded then
		--		LuaPlayer.Character.OnAppearanceLoaded:Wait()
		--	end
			
		--	if LuaPlayer.Player:GetAttribute("Red_Mist_Avatar") and LuaPlayer.Character.PreviousDescription == nil then
		--		LuaPlayer.Character.PreviousDescription = LuaPlayer.Character.Humanoid:GetAppliedDescription()
		--		LuaPlayer.Character.Humanoid:ApplyDescriptionReset(script.Outfit)
		--	end
		--end)

		LuaPlayer.Character:SetHealthAndHeal(150)
		
		LuaPlayer.Character.Combat:CreateAttack("Gebura Armor")
		LuaPlayer.Character.Combat:CreateAttack("E.G.O. Pose", Enum.KeyCode.P)

		--if Whitelist.is_permitted(LuaPlayer.UserId, "Gebura") then
		--	LuaPlayer.Character:SetHealthAndHeal(150)
		--	LuaPlayer.Character.Combat:CreateAttack("E.G.O. Pose", Enum.KeyCode.P)
		--end
		
		local Sword = script.Mimicry:Clone()
		local Weld = Sword.Weld
		
		Weld.Part0 = LuaPlayer.Character.RightArm
		Weld.Part1 = Sword.PrimaryPart
		Sword.Parent = LuaPlayer.Character.Model
		
		LuaPlayer.Character.Combat.SwordWeld = Weld
		LuaPlayer.Character.Combat.Sword = Sword
	end,
	
	OnRemoved = function(LuaPlayer)
		LuaPlayer.Character.Combat:RemoveAttack("Gebura Armor")
		LuaPlayer.Character.Combat:RemoveAttack("E.G.O. Pose")
		
		--if table.find(Whitelist, LuaPlayer.UserId) then
		--	LuaPlayer.Character.Combat:RemoveAttack("Pose")
		--end
		
		if LuaPlayer.Character.Combat.Sword then
			LuaPlayer.Character.Combat.Sword:Destroy()
			LuaPlayer.Character.Combat.Sword = nil
		end
		
		if LuaPlayer.Character.Combat.SwordWeld then
			LuaPlayer.Character.Combat.SwordWeld:Destroy()
			LuaPlayer.Character.Combat.SwordWeld = nil
		end
		
		if LuaPlayer.Character.RedMistSecondTorso then
			LuaPlayer.Character.RedMistSecondTorso:Destroy()
			LuaPlayer.Character.RedMistSecondTorso = nil
		end
		
		if (LuaPlayer.Character.PreviousDescription ~= nil) then
			LuaPlayer.Character.Humanoid:ApplyDescriptionReset(LuaPlayer.Character.PreviousDescription )
			LuaPlayer.Character.PreviousDescription = nil
		end
	end,
	
	Ultimate = {
		Name = "E.G.O",
		
		Attacks = {
			["Great Split - Vertical"] = Enum.KeyCode.One,
			["Kali"] = Enum.KeyCode.Two,
		},
		
		Function = function(self)
			local Animation : AnimationTrack = self.Animations[self.Combat.CurrentCharacter.Name].Start
			local Armor = self.Combat.Attacks["Gebura Armor"]
			local Sword : typeof(script.Mimicry) = self.Combat.Sword
			local SwordWeld : Weld = self.Combat.SwordWeld
			
			Animation:Play()
			
			self:FireReliableVFX("Gebura Red Mist/Ultimate", "Start", self.LuaCharacter.Model)
			
			self.Thread.Job:Task(Animation:GetMarkerReachedSignal("SwordGround"):Connect(function(State : string)
				if State == "true" then
					SwordWeld.Enabled = false
					Sword.Handle.Anchored = true
					Sword.Handle.CFrame = SwordWeld.Part0.CFrame:ToObjectSpace(SwordWeld.C0)

				elseif State == "false" then
					Sword.Handle.Anchored = false
					SwordWeld.Enabled = true
				end
			end))
			
			self.Thread.Job:Task(task.delay(730/60, function()
				if Armor then
					Armor:SwitchArmor(true)
				end
				
				self.OnUltimateEnded:Once(function()
					if Armor then
						Armor:SwitchArmor(false)
					end
				end)
			end))
			
			self.Thread.Job:Task(Animation.Ended:Once(function()
				self:Close()
			end))
		end,
		
		--SkipIntro = true,
		
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
			ColorSequenceKeypoint.new(0.25 + 0.1, Color3.new(0.462745, 0, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 0, 0)),
			ColorSequenceKeypoint.new(0.75 - 0.1, Color3.new(0.462745, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
		}),
	},
	
	WallCombo = {
		DistanceFromWall = 2,

		Function = function(self, VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local AttackerAnimation : AnimationTrack = self.Animations.WallCombo["Gebura Red Mist"].User
			local VictimAnimation : AnimationTrack = VictimLuaCharacter.Humanoid:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Dash.WallCombo["Gebura Red Mist"].Victim)

			self.Thread.OnClosed:Connect(function()
				AttackerAnimation:Stop(0)
				VictimAnimation:Stop(0)

				self.LuaCharacter:Anchor(false)
				VictimLuaCharacter:Anchor(false)

				self.Combat:StackState("GrabIFrames", false)
				VictimCombat:StackState("GrabIFrames", false)
			end)

			AttackerAnimation:Play()
			VictimAnimation:Play()

			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
				self:FireReliableVFX("Gebura Red Mist/Wall Combo", "VFX", self.LuaCharacter.RootPart, Parameter)
				
				if Parameter == "4" then
					AttackerAnimation:Stop(0.4)
					self:Close()

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Damage = 10,
						Ragdoll = 2,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 30 + Vector3.yAxis * 5, 0.1}
					})

					task.defer(VictimCombat.Unstun, VictimCombat)

				elseif Parameter == "1" or Parameter == "3" then
					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						
						Damage = {
							DontKill = true,
							Amount = 5
						},
						
						DontRestartRespawnTimer = true
					})
				end
			end))
		end
	}
}