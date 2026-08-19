local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

return {
	UsingAttacks = {
		"Vector Reflection",
		"Wind Turmoil",
		"Plasmic Degree",
	};
	VaultedAttacks = {
		"Wind Turmoil",
		"Plasmic Degree",
	};
	
	FrontDash = {
		OnStart = function(Attack)
			Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Vector Punch", "Charge", Attack.LuaPlayer.Character.RightArm)
		end,
		
		OnEnd = function(Attack)
			Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Vector Punch", "Uncharge", Attack.LuaPlayer.Character.RightArm)
		end
	},
	
	CustomM1Function = function(Attack)
		local AnimationDirectory = Attack:GetAnimationDirectory()
		local Animation : AnimationTrack = (Attack.Condition ~= nil and AnimationDirectory[Attack.Condition] or AnimationDirectory[tostring(Attack.Count)])
		Animation:Play(0.1, 1, Attack.Condition == nil and (Attack.Combat.CurrentCharacter.Info.M1Speed or 1) or 1)
		
		if (Attack.Count == 4 and Attack.Condition == nil) then
			Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Vector Punch", "Charge", Attack.LuaCharacter.RightArm)
			task.wait(0.5)
			Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Vector Punch", "Uncharge", Attack.LuaCharacter.RightArm)
		end
	end,
		
	WallCombo = {
		DistanceFromWall = 6.8,
		DontAnchor = true,

		Function = function(Attack, VictimLuaPlayer, WallRay)
			local VictimLuaCharacter = VictimLuaPlayer.Character
			local VictimCombat = VictimLuaCharacter.Combat
			local VictimRoot = VictimLuaCharacter.RootPart
			
			local Animations = Attack.Animations.WallCombo.Accelerator
			
			local Start : AnimationTrack = Animations.Start
			local Loop : AnimationTrack = Animations.Loop
			local Throw : AnimationTrack = Animations.Throw
			
			local VictimAnimations = ReplicatedStorage.Animations.Attacks.Global.Dash.WallCombo.Accelerator.Victim
			
			local StartVictim : AnimationTrack = VictimLuaCharacter.Humanoid:LoadAnimation(VictimAnimations.Start)
			local LoopVictim : AnimationTrack = VictimLuaCharacter.Humanoid:LoadAnimation(VictimAnimations.Loop)
			local ThrowVictim : AnimationTrack  = VictimLuaCharacter.Humanoid:LoadAnimation(VictimAnimations.Throw)

			local StopAutoRotate = Utility.StopAutoRotate(Attack.LuaCharacter.Humanoid)
			Attack.Combat:DivideSpeed(100)

			local GrabObject = Attack.Combat:GrabVictim(VictimLuaPlayer, Attack.LuaCharacter.RootPart, CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))
			local Ended = false
			
			Attack.Thread.CancelJob:Task(
				Attack.Combat:CreateMoveSFX("Accelerator", "Wall Combo", "Start")
			)
			
			Attack.Thread.OnClosed:Connect(function()
				StopAutoRotate:Destroy()
				Attack.Combat:TimesSpeed(100)
				
				Attack.LuaPlayer.Replication.Attributes:SetAttribute("AcceleratorWallCombo", nil)
				
				StartVictim:Stop()
				LoopVictim:Stop()
				ThrowVictim:Stop()
				Start:Stop()
				Loop:Stop()
				
				if not Ended then
					Throw:Stop()
					
					GrabObject.Destroy(0)
					VictimCombat:Unstun()
				end
			end)
			
			Start:Play()
			StartVictim:Play()

			local SoundLoop
			
			Attack.Thread.Job:Task(Start:GetMarkerReachedSignal("loop"):Once(function()
				Start:Stop()
				StartVictim:Stop()
				
				Loop:Play()
				LoopVictim:Play()
				
				SoundLoop = Attack.Thread.CancelJob:Task(
					Attack.Combat:CreateMoveSFX("Accelerator", "Wall Combo", "Loop")
				)

				local StartTime = os.clock()
				
				local FrontSize = Vector3.new(0.01, 0.01, 4)
				local SideSize = Vector3.new(0.01, 0.01, 6)
				
				local Duration = 3.25
				local Damage = 0.175
				local Time = 0.05
				
				local Root = Attack.Combat:GetSimulatedRoot()
				
				VictimLuaCharacter.HumanoidJob:Task(task.spawn(function()
					while Attack.LuaCharacter.HumanoidExists and VictimLuaCharacter.HumanoidExists do
						local CF : CFrame = Root.CFrame * CFrame.new(-4, -2.5, 0)
						local Position = CF.Position

						local FrontRaycast = workspace:Raycast(Position, CF.LookVector * 10, Utility.VisualParams)
						local SideRaycast = workspace:Raycast(Position, CF.RightVector * -10, Utility.VisualParams)

						--local FrontRaycast = workspace:Blockcast(CF, FrontSize, CF.LookVector * 10, Utility.VisualParams)
						--local SideRaycast = workspace:Blockcast(CF, SideSize, CF.RightVector * -7, Utility.VisualParams)

						if os.clock() - StartTime > Duration then
							break
						end

						if (SideRaycast ~= nil) or (FrontRaycast == nil) then
							break
						end

						Attack.Combat:Afflict(VictimLuaPlayer, {
							ExcludeAttempts = true,
							DontRestartRespawnTimer = true,

							Damage = {
								Amount = Damage,
								DontKill = true
							}  -- 10.39 damage in total, print this in output if you want to see it's total damage: print((Damage / Time) * Duration)
						})

						task.wait(Time)
					end
				end))

				Attack.LuaPlayer.Replication.Attributes:SetAttribute("AcceleratorWallCombo", nil)

				if Attack.LuaCharacter.HumanoidExists then
					Loop:Stop()
					LoopVictim:Stop()

					Throw:Play()
					ThrowVictim:Play()

					if SoundLoop then
						SoundLoop:Destroy()
					end

					Throw:GetMarkerReachedSignal("throw"):Wait()

					Ended = true
					ThrowVictim:Stop(0)

					GrabObject.Destroy(0.8)
					VictimCombat:Unstun()

					Attack.Combat:Afflict(VictimLuaPlayer, {
						Damage = 5,
						Ragdoll = 1,
						Velocity = {-Attack.LuaCharacter.RootPart.CFrame.RightVector * -80 + Vector3.yAxis * 30, 0.1}
					})

					do
						Attack.Thread.CancelJob:Task(
							Attack.Combat:CreateMoveSFX("Accelerator", "Wall Combo", "Throw")
						)

						Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Wall Combo", "Throw", Attack.LuaCharacter.RootPart)
					end
				end
				
				Attack:Close()
			end))
			
			Attack.Thread.Job:Task(Start:GetMarkerReachedSignal("slam"):Once(function()
				Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Wall Combo", "Slam", Attack.LuaCharacter.RootPart)
			end))
			
			Attack.Thread.Job:Task(Start:GetMarkerReachedSignal("land"):Once(function()
				Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Wall Combo", "Land", Attack.LuaCharacter.RootPart)
			end))
			
			Attack.Thread.Job:Task(Start:GetMarkerReachedSignal("launch"):Once(function()
				Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Wall Combo", "Launch", Attack.LuaCharacter.RootPart)
			end))
			
			Attack.Thread.Job:Task(Start:GetMarkerReachedSignal("tp"):Once(function()
				Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Wall Combo", "Tp", Attack.LuaCharacter.Torso)
			end))
			
			Attack.Thread.Job:Task(Start:GetMarkerReachedSignal("run"):Once(function()
				Attack.LuaPlayer.Replication.Attributes:SetAttribute("AcceleratorWallCombo", true)
				Attack.LuaPlayer.Replication:FireReliableVFXToSelf("Accelerator/Wall Combo", "RunVelocity", Attack.LuaCharacter.RootPart)
				Attack.LuaPlayer.Replication:FireReliableVFXToSelf("Accelerator/Wall Combo", "RunVFX", Attack.LuaCharacter.RootPart)
			end))
		end,
	},

	Ultimate = {
		Name = "LEVEL 5 ESPER", -- jimpee asked me to change these
		
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(78, 0, 147)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(169, 49, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(78, 0, 147))
		}),

		Attacks = {
			["Vector Grasp"] = Enum.KeyCode.One,
			["Power Display"] = Enum.KeyCode.Two,
			["Carnal Revolution"] = Enum.KeyCode.Three,
			["The Strongest"] = Enum.KeyCode.Four,
		},

		Function = function(Attack)
			local Animations = Attack.Animations[Attack.Combat.CurrentCharacter.Name]

			Attack.Thread.Job:Task(Animations.Cutscene:GetMarkerReachedSignal("laugh1"):Once(function()
				Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Ultimate", "Laugh1", Attack.LuaCharacter.RootPart)
			end))

			Attack.Thread.Job:Task(Animations.Cutscene:GetMarkerReachedSignal("blood"):Once(function()
				Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Ultimate", "Blood", Attack.LuaCharacter.Head)
			end))

			Attack.Thread.Job:Task(Animations.Cutscene:GetMarkerReachedSignal("wipe"):Once(function()
				Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Ultimate", "Wipe", Attack.LuaCharacter.Head)
			end))

			Attack.Thread.Job:Task(Animations.Cutscene:GetMarkerReachedSignal("impact"):Once(function()
				Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Ultimate", "Impact", Attack.LuaCharacter.RootPart)
			end))

			Attack.Thread.Job:Task(Animations.Cutscene:GetMarkerReachedSignal("explosions"):Once(function()
				Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Ultimate", "Explosions", Attack.LuaCharacter.RootPart)

				task.wait(1 / 60)
				
				Attack.Thread.Job:Task(task.spawn(function()
					local Rnd = Random.new();
					
					for Index = 1, 14 do
						local Hitbox = Attack.Combat.Hitbox:Create()
						Hitbox.Params.Offset = CFrame.new(0.5, 35, -2)
						Hitbox.Params.Size = Vector3.new(100, 75, 100)
						
						Attack.Combat.Hitbox:CreateHavocReplicated({
							parameters = {
								origin = Hitbox:GetCFrame() * CFrame.new(Rnd:NextNumber(-60, 60), -35, Rnd:NextNumber(-60, 60)),
								shape = "Sphere", 
								radius = 12,
								block_size = 9,
							},
							debris = {
								scale = 0.9,
								velocity = function(part)
									return Rnd:NextUnitVector() * 25 + Vector3.yAxis * 100;
								end,
							},
						});
						
						Attack.Thread.Job:Task(Hitbox)

						Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
							local VictimLuaCharacter = VictimLuaPlayer.Character
							local VictimCombat = VictimLuaCharacter.Combat

							Attack.Combat:Afflict(VictimLuaPlayer, {
								TriggerActiveCounterOverOrEqualLevel = -1,
								BreakBlock = true,
								Damage = 2.5,
								Ragdoll = 2,
								Velocity = {Vector3.new(Utility.Seed:NextNumber(-50, 50), 25, Utility.Seed:NextNumber(-50, 50)), 0.05}
							})
						end)

						Hitbox:BeginCast(0.1)

						task.wait(0.2)
					end
				end))
			end))

			Attack.Thread.Job:Task(Animations.Cutscene:GetMarkerReachedSignal("laugh2"):Once(function()
				Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Ultimate", "FinalLaugh", Attack.LuaCharacter.RootPart)
			end))

			Attack.Thread.Job:Task(Animations.Start:GetMarkerReachedSignal("Stomp"):Once(function()
				Attack.LuaPlayer.Replication:FireReliableVFX("Accelerator/Ultimate", "Stomp", Attack.LuaCharacter.RootPart)
				
				Animations.Cutscene:Play()

				local Hitbox = Attack.Combat.Hitbox:Create()
				Hitbox.Params.Offset = CFrame.new(0.5, 35, -2)
				Hitbox.Params.Size = Vector3.new(75, 75, 75)
				
				Attack.Thread.Job:Task(Hitbox)

				Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
					local VictimLuaCharacter = VictimLuaPlayer.Character
					local VictimCombat = VictimLuaCharacter.Combat

					Attack.Combat:Afflict(VictimLuaPlayer, {
						TriggerActiveCounterOverOrEqualLevel = -1,
						BreakBlock = true,
						Damage = 10,
						Ragdoll = 3,
						Velocity = {Vector3.yAxis * 125, 0.05}
					})
				end)

				Hitbox:BeginCast(0.05)
			end))

			task.delay(11.5, Attack.Close, Attack)
		end
	},

	Attacks = {
		["Bio Electric Burst"] = Enum.KeyCode.One,
		["Soundwave Punch"] = Enum.KeyCode.Two,
		["Tectonic Control"] = Enum.KeyCode.Three,
		["Accelerated Punishment"] = Enum.KeyCode.Four
	},
	
	OnRespawn = function(LuaPlayer, Job)
		local Animation : AnimationTrack = LuaPlayer.Character.Animator:LoadAnimation(ReplicatedStorage.Animations.CharacterSpawnAnimations.Accelerator.Spawn)
		Animation:Play()

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
		
		Job:Task(task.delay(0.125, function()
			LuaPlayer.Replication:FireReliableVFX("Accelerator/Vector Punch", "Charge", LuaPlayer.Character.LeftArm)
		end))
		
		task.delay(0.85, function()
			LuaPlayer.Replication:FireReliableVFX("Accelerator/Vector Punch", "Uncharge", LuaPlayer.Character.LeftArm)
		end)

		return Animation, Sound
	end,
}