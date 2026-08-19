local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MichaelUtil = require( ReplicatedStorage.Modules.Player.Replication.VFX["Meaty Michael"]["Michael Awakening"].Util )
local Whitelist = require( ReplicatedStorage.Modules.Shared.Game.Whitelist )

local Moves = {
	["I'll Show You Darkness"] = Enum.KeyCode.One,
	["The Last Oil"] = Enum.KeyCode.Two,
	["Helping Hand"] = Enum.KeyCode.Three,
	["Meaty Michael Slap"] = Enum.KeyCode.Four,
}

return {
	GitHubWhitelist = "Meaty",
	InWorldEvent = true;
	DisableInSkillBuilder = true;
	StandName = "Meaty Platinum",
	
	UsingAttacks = {
		"I'll Show You Darkness",
		"The Last Oil",
		"Helping Hand",
		"Meaty Michael Slap",
		"Drake's Embrace",
		"Drake's Love",
	};
	
	OnRemoved = function(LuaPlayer)
		for Name, Key in Moves do
			LuaPlayer.Character.Combat:RemoveAttack(Name, Key);
		end;
		
		LuaPlayer.Character.Combat:RemoveAttack("Meaty Platinum");
	end,
	
	OnSpawn = function(LuaPlayer)
		if Whitelist.is_permitted(LuaPlayer.UserId, "Crusader") then
			LuaPlayer.Character.Combat:CreateAttack("Meaty Platinum");
		else
			for Name, Key in Moves do
				LuaPlayer.Character.Combat:CreateAttack(Name, Key);
			end;
		end;
		
		local M1, Matched = LuaPlayer.Character.Combat:MatchAttack("M1", Enum.UserInputType.MouseButton1)
		
		if Matched then
			LuaPlayer.Character.Combat.SpawnJob:Task(M1.OnHit:Connect(function(VictimLuaPlayer)
				if M1.Count ~= 4 then return end
				
				VictimLuaPlayer.Replication:FireReliableVFXToSelf("Meaty Michael/Meaty Scare", "new")
			end))
		end
	end,

	Stats = {
		M1 = {
			Speed = 0.7,
			EndlagAfterSwing = 0.1,
		}
	},
	
	Ultimate = {
		OneTimePop = true,
		
		Name = "MEATY MICHAEL'S WRATH",
		
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 139, 214)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(168, 0, 0)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(168, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 139, 214)),
		}),

		Function = function(self, StartAnimation : AnimationTrack)
			self.LuaPlayer.Replication.Attributes:SetAttribute("MeatyMichaelAwakening", true)
			self:FireReliableVFXToSelf("Meaty Michael/Michael Awakening", "Camera", self.LuaCharacter.RootPart)

			local Rnd = Random.new();

			local Steak = script.Steak:Clone()
			Steak.SteakJoint.Part0 = self.LuaCharacter.Torso;
			Steak.Parent = self.LuaCharacter.Model;

			self.Thread.OnClosed:Connect(function()
				Steak:SetAttribute("Stop", true);
				Steak.Transparency = 1
				
				task.delay(1, function()
					Steak:Destroy();
				end)

				self.LuaPlayer.Replication.Attributes:SetAttribute("MeatyMichaelAwakening", nil)
			end)

			local LaserHitbox = self:CreateHitbox(true)
			LaserHitbox.Params.Size = 30 
			LaserHitbox.Params.DestroyOnEndCast = true

			local LaserOffset = CFrame.new(0, 0, -35);
			local LaserCoordinate = CFrame.identity;
			local Elapsed = 0;

			LaserHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				self:Afflict(VictimLuaPlayer, {
					TriggerActiveCounterOverOrEqualLevel = -1,

					DontBypassIFrames = {},
					BreakBlock = true,

					Damage = {
						Amount = 5,
						DontCountToUltimate = true
					},

					Ragdoll = 2,
					Velocity = {(Rnd:NextUnitVector() + Vector3.yAxis).Unit  * 30 + Vector3.yAxis * 2.5, 0.25}
				})

				task.delay(0.1, function()
					LaserHitbox:RemoveHumanoid(VictimLuaCharacter.Humanoid)
				end)
			end)

			self.Thread.Job:Task(StartAnimation:GetMarkerReachedSignal("Attack"):Once(function()
				local RootPart : BasePart = self.LuaCharacter.RootPart;

				StartAnimation:AdjustSpeed(0.4)
				self:FireReliableVFX("Meaty Michael/Michael Awakening", "AttackStart", Steak, RootPart, LaserOffset)

				self.Thread.Job:Task(RunService.PreSimulation:Connect(function(Delta)
					Elapsed += Delta;
					LaserCoordinate = MichaelUtil.GetLaserCoordinateAtTime(RootPart.CFrame * LaserOffset, Elapsed);
					
					LaserHitbox.Adornee = LaserCoordinate.Position;
					self.Combat.Hitbox:SphereDestruction(LaserHitbox.Adornee, LaserHitbox.Params.Size + 5, 10)
				end))

				self.Thread.Job:Task(task.delay(0.05, function()
					LaserHitbox:BeginCast();
				end))
			end))

			self.Thread.Job:Task(StartAnimation:GetMarkerReachedSignal("Footstep"):Connect(function()
				self:FireReliableVFX("Meaty Michael/Michael Awakening", "Footstep", Steak)
			end));

			self.Thread.Job:Task(StartAnimation:GetMarkerReachedSignal("AttackEnd"):Once(function()
				StartAnimation:AdjustSpeed(1.9);
				Steak:SetAttribute("Stop", true);
				LaserHitbox:EndCast()
			end))

			self.Thread.Job:Task(StartAnimation:GetMarkerReachedSignal("Swing"):Once(function()
				self:FireReliableVFX("Meaty Michael/Michael Awakening", "Swing", self.LuaCharacter.RootPart);

				local Hitbox = self:CreateHitbox(true, true);
				Hitbox.Adornee = self.LuaCharacter.RootPart.Position;
				Hitbox.Params.Size = 14;

				Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
					local VictimLuaCharacter = VictimLuaPlayer.Character
					local VictimCombat = VictimLuaCharacter.Combat

					local Validated = self:Afflict(VictimLuaPlayer, {
						Damage = 13,
						BreakBlock = true
					})

					if Validated then
						VictimCombat:TrueStun(15)

						self.Combat:TSBPushVictim(VictimLuaPlayer, {
							LandedRollVelocityZ = 150,
							LandedRollDuration = 0.835,
						})
					end
				end)

				Hitbox:Detect()

				task.defer(function()
					Hitbox:Destroy()
				end)
			end));

			self.Thread.Job:Task(StartAnimation:GetMarkerReachedSignal("Disappear"):Once(function()
				self:FireReliableVFX("Meaty Michael/Michael Awakening", "FloorSteak", Steak, true)
			end));

			self.Thread.Job:Task(StartAnimation:GetMarkerReachedSignal("PreSummon"):Once(function()
				self:FireReliableVFX("Meaty Michael/Michael Awakening", "PreSummon", Steak)
			end))

			self.Thread.Job:Task(StartAnimation:GetMarkerReachedSignal("Summon"):Once(function()
				self:FireReliableVFX("Meaty Michael/Michael Awakening", "Summon", Steak)
			end))

			StartAnimation.Stopped:Wait()
			self:Close()
		end,
	},
	
	StandOnAttacks = {
		["Yare Yare Daze"] = Enum.KeyCode.One,
	};

	StandOffAttacks = Moves,
	
	Attacks = {
		--["I'll Show You Darkness"] = Enum.KeyCode.One,
		--["The Last Oil"] = Enum.KeyCode.Two,
		--["Helping Hand"] = Enum.KeyCode.Three,
		--["Meaty Michael Slap"] = Enum.KeyCode.Four,
	},
	
	WallCombo = {
		DistanceFromWall = 4.5,
		VictimOffset = CFrame.new(0, 0, 0.5),

		Function = function(self, VictimLuaPlayer)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat

			local AttackerAnimation : AnimationTrack = self.Animations.WallCombo["Meaty Michael"].User
			local VictimAnimation : AnimationTrack = VictimLuaCharacter.Humanoid:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Dash.WallCombo["Meaty Michael"].Victim)

			self.Thread.OnClosed:Connect(function()
				AttackerAnimation:Stop(0)
				VictimAnimation:Stop(0)
				
				task.delay(0.1, function()
					self.LuaCharacter:Anchor(false)
				end);
				
				VictimLuaCharacter:Anchor(false)

				VictimCombat:Unstun()

				self.Combat:StackState("GrabIFrames", false)
				VictimCombat:StackState("GrabIFrames", false)
			end)
			
			AttackerAnimation:Play(0, 1, 0.8)
			VictimAnimation:Play(0, 1, 0.8)
			
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("Swing"):Once(function()
				AttackerAnimation:AdjustSpeed(1)
				VictimAnimation:AdjustSpeed(1)
				
				self:FireReliableVFX("Meaty Michael/Wall Combo", "Swing", self.LuaCharacter.RootPart)
			end))

			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("Slam"):Once(function()
				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = {
						DontKill = true,
						Amount = 7
					},
					DontRestartRespawnTimer = true
				})
				
				self:FireReliableVFX("Meaty Michael/Wall Combo", "Slam", self.LuaCharacter.RootPart)
				VictimLuaPlayer.Replication:FireReliableVFXToSelf("Meaty Michael/Meaty Scare", "new")
			end))
			
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("Ringing"):Once(function()
				AttackerAnimation:AdjustSpeed(1);
				VictimAnimation:AdjustSpeed(1);
				self:FireReliableVFX("Meaty Michael/Wall Combo", "Ringing", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("KickHit"):Once(function()
				self:FireReliableVFX("Meaty Michael/Wall Combo", "KickHit", self.LuaCharacter.RootPart)

				AttackerAnimation:Stop(0.5);

				self:Afflict(VictimLuaPlayer, {
					ExcludeAttempts = true,
					Damage = 7,
					Ragdoll = 2,
					Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * -40 + Vector3.yAxis * 35, 0.1}
				})
				
				self:Close()
			end))
	
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("SwingKick"):Once(function()
				self:FireReliableVFX("Meaty Michael/Wall Combo", "SwingKick", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("Call"):Once(function()
				self:FireReliableVFX("Meaty Michael/Wall Combo", "Call", self.LuaCharacter.RootPart)
			end))
			
			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("FlipPhone"):Once(function()
				self:FireReliableVFX("Meaty Michael/Wall Combo", "FlipPhone", self.LuaCharacter.Model);
			end))

			self.Thread.Job:Task(AttackerAnimation:GetMarkerReachedSignal("HangUp"):Once(function()
				self:FireReliableVFX("Meaty Michael/Wall Combo", "HangUp", self.LuaCharacter.Model)
				AttackerAnimation:AdjustSpeed(1.1);
				VictimAnimation:AdjustSpeed(1.1);
			end))
		end
	}
}
