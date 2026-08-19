local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local AI = require( ServerScriptService.Scripts.Game.Modules.AI )

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

return function(LuaPlayer, NPCJob)
	local LuaCharacter = LuaPlayer.Character
	local Combat = LuaCharacter.Combat

	local Health = LuaCharacter.Humanoid.Health

	Combat:CreateAttack("Shatter Slashes", Enum.KeyCode.Five)
	Combat:CreateAttack("Boss Special Hell", Enum.KeyCode.Six)
	Combat:CreateAttack("Seven Souls", Enum.KeyCode.Seven)
	Combat:CreateAttack("Atonement", Enum.KeyCode.Eight)

	Combat.IsChara = true
	
	Combat.DamageMultiplier = 2
	Combat.Ragdoll.TimeMultiplier = 0.75
	
	Combat.AngryHealth = 450

	local Entity = AI.new(LuaCharacter, require(script.Data))

	local BlockAttack = Combat.Attacks.Block
	local DashAttack = Combat.Attacks.Dash

	local function Evasive()
		local Direction = math.random(1, 2) == 1 and "Left" or "Right"
		DashAttack.Direction = Direction

		DashAttack:Evasive()
		DashAttack:Trigger()

		if math.random(1, 4) ~= 1 then
			local Angle = 37.5
			Entity:SetGyroRotationOffset(if Direction == "Left" then -Angle else Angle, 0.375)
		end
	end
	
	local BlockDeactivateThread

	Entity.OnMoveBegin:Connect(function(Info : {})
		local Name = Info.Name

		if Name == "Evasive" then
			if (Entity.Target.Character.Combat:GetState("Attacking")) then
				Evasive()
			else
				task.delay(Utility.Seed:NextNumber(0.3, 0.6), function()
					if DashAttack:NPCCanEvasive() then
						Evasive()
					end
				end)
			end

		elseif Name == "DefensiveAgainstM1" then
			local Turn_Around = (Entity.Target.Character.Combat:GetState("Dashing") and Entity.Target.Character.Combat:GetState("M1ing") and Entity:DistanceFromTarget() <= 8)
			
			if Turn_Around then
				Entity:SetGyroRotationOffset(
					180, 
					0.25
				)
			end
			
			Utility.CloseThreadSafe(BlockDeactivateThread)
			
			if not BlockAttack:ThreadAvailable() then
				BlockAttack:Trigger()
			end

			BlockDeactivateThread = task.delay(0.25, function()
				BlockDeactivateThread = nil
				BlockAttack:Deactivate()
			end)
			
		elseif Name == "DefensiveAgainstBlock" then
			local Rng = math.random(1, 2) == 1
			local Direction = Rng and "Left" or "Right"
			
			Entity:SetGyroRotationOffset(
				Rng and 90 or -90, 
				0.375
			)
			
			DashAttack.Direction = Direction
			DashAttack:Trigger()

		elseif Name == "DefensiveAgainstAttack" then
			BlockAttack:Trigger()

			task.delay(Utility.Seed:NextNumber(0.3, 0.6), function()
				BlockAttack:Deactivate()
			end)

		elseif Name == "DefensiveBackDash" then
			if math.random(1, 3) == 1 then
				LuaCharacter.Humanoid.Jump = true
				
				Entity:SetGyroRotationOffset(
					math.random(1, 2) == 1 and 150 or -150, 
					1.1
				)
			end

			DashAttack.Direction = "Back"
			DashAttack:Trigger()
			
		elseif Name == "SideDash" then
			local Direction = math.random(1, 2) == 1 and "Left" or "Right"
			local Angle = 37.5

			local TimeUntilDash = Utility.Seed:NextNumber(0.15, 0.25)
			
			Entity:SetGyroRotationOffset(
				if Direction == "Left" then -Angle else Angle, 
				TimeUntilDash + 0.375
			)

			local Stunned : RBXScriptConnection; Stunned = Combat:GetStateChanged("Stunned"):Connect(function()
				Stunned:Disconnect()
				Entity:SetGyroRotationOffset(0)
			end)
			
			task.delay(TimeUntilDash, function()
				if Stunned.Connected then
					Stunned:Disconnect()
				end
				
				if DashAttack:ConditionToActivate("Side Dash") then
					DashAttack.Direction = Direction
					DashAttack:Trigger()
					
					DashAttack.Thread.OnClosed:Connect(function()
						Entity:SetGyroRotationOffset(0)
					end)
				end
			end)
			
		elseif Name == "FrontDash" then
			DashAttack.Direction = "Front"
			DashAttack:Trigger()
		else
			local Move = Combat.Attacks[Info.Name]
			
			if Move then
				
				if Name == "Bloody Mary" then
					Entity:SetGyroRotationOffset(180)
					Move:Trigger()

					Move.Thread.OnClosed:Connect(function()
						Entity:SetGyroRotationOffset(0)
					end)

					Move.Thread.Job:Task(Move.Animations.Windup:GetMarkerReachedSignal("kick"):Connect(function()
						task.wait(Utility.Seed:NextNumber(0.5, 0.75))
						Entity:SetGyroRotationOffset(0)
					end))
					
				elseif Name == "Lethal Wound" then
					Entity:SetGyroRotationResponsiveness(30)
					Move:Trigger()
					
					Move.Thread.OnClosed:Connect(function()
						Entity:ResetGyroRotationResponsiveness()
					end)
				else
					Move:Trigger()
				end
				
			end
		end
	end)
	
	local DeathQuote = {
		["Gojo"] = "For someone titled the strongest, you're pretty weak.",
		["Accelerator"] = "Looks like i'm the strongest esper now.",
		["Reigen"] = "You're better off scamming people in hell, fraud.",
		["Kratos"] = "The only god that exists, is me.",
		["Chara"] = "How many times have you died already?"
	}
	
	local Emotes = {
		"Cancun", "Jersey Joe", "Spot", "Soda Pop", "Prince Of JSD"
	}
	
	local SaidDeathQuoteOn = {}

	Entity.OnTargetDied:Connect(function(DeadTarget)
		if not SaidDeathQuoteOn[DeadTarget] and DeathQuote[DeadTarget.Character.Combat.CurrentCharacter.Name] then
			SaidDeathQuoteOn[DeadTarget] = true
			LuaPlayer.Replication:FireReliableVFX("Chara/Voicelines", "Create", LuaCharacter.Model, DeathQuote[DeadTarget.Character.Combat.CurrentCharacter.Name])
			
			local Respawn : RBXScriptConnection; Respawn = DeadTarget.Character.OnHumanoidAvailabilityChanged:Connect(function(Value : boolean)
				if Value then
					Respawn:Disconnect()
					SaidDeathQuoteOn[DeadTarget] = nil
				end
			end)
		end
	
		local function Emote()
			local Emote = LuaCharacter.Emotes:PlayEmote(Emotes[math.random(1, #Emotes)])

			task.wait(4)

			if Emote then
				Emote:Destroy()
			end
		end
		
		local Event; Event = Combat.OnStateChanged:Connect(function(State, Value)
			if (State == "Attacking" or State == "M1ing") and not Value then
				Event:Disconnect()
				Emote()
			end
		end)
		
		if not Combat:GetState("Attacking") or not Combat:GetState("M1ing") then
			Emote()
		end

		task.delay(1, Event.Disconnect, Event)
	end)
	
	local SwitchCooldown = false
	local CharaSwitchCount = 0
	
	Entity.OnTargetSwitched:Connect(function()
		if SwitchCooldown or Combat:GetState("Grabbing") or Combat:GetState("Stunned") then return end
		
		--SwitchCooldown = true
		CharaSwitchCount += 1
		
		if CharaSwitchCount > 4 then
			CharaSwitchCount = 0
			
			if math.random(1, 3) == 1 then
				LuaPlayer.Replication:FireReliableVFX("Chara/Voicelines", "Create", LuaCharacter.Model, "Don't think i've forgotten about you EITHER!")
			end
		end
	
		--task.delay(10, function()
		--	SwitchCooldown = false
		--end)
	end)

	local RunAnimation : AnimationTrack = LuaCharacter.Animator:LoadAnimation(ReplicatedStorage.Animations.Movement.Chara.Run)
	local RunSpeed = RunAnimation.Animation:GetAttribute("SpeedMultiplier") or 1
	
	RunSpeed += 0.3
	RunAnimation.Priority = Enum.AnimationPriority.Idle

	local Running = false

	local function TryRun()
		if not Running and Combat.Actions.CanRun and Entity.IsRunning then
			Running = true

			RunAnimation:Play(0.1, 1, RunSpeed)
			LuaCharacter.Humanoid.WalkSpeed *= 2

		elseif Running and (not Combat.Actions.CanRun or not Entity.IsRunning) then
			Running = false

			RunAnimation:Stop()
			LuaCharacter.Humanoid.WalkSpeed /= 2
		end
	end
	
	local function Intro()
		Combat:StackState("Attacking", true)
		Combat:DivideSpeed(1000)
		
		NPCJob:Task(task.delay(3 / 60, function()
			local SpawnJob = Combat:FireSpawnAnimation()
			LuaPlayer.Replication:FireReliableVFX("Chara/Voicelines", "Create", LuaCharacter.Model, "You're in for a treat now..", 300)

			NPCJob:Task(task.delay(2, function()
				SpawnJob:Destroy()

				Combat:TimesSpeed(1000)
				Combat:StackState("Attacking", false)
			end))
		end))
	end
	
	local Chara_Spawn_Attachment = workspace.Terrain["Chara_Spawn"]
	local LastTime = os.clock()
	local Range = 215
	
	local function AntiStuck()
		LuaCharacter.Model:PivotTo(Chara_Spawn_Attachment.WorldCFrame)
		Intro()
	end
	
	NPCJob:Task(RunService.PostSimulation:Connect(function()
		if os.clock() - LastTime > 0.2 then
			local Y : number = LuaCharacter.RootPart.Position.Y
			
			if (Y < -5 or Y > 120) then
				AntiStuck()
			end
			
			if Entity.CanTarget then
				
				local Distance_From_Spawn = (LuaCharacter.RootPart.Position - Chara_Spawn_Attachment.WorldPosition).Magnitude

				if Distance_From_Spawn > Range then
					Entity.Time.History.TargetLastSighted = nil
					Entity.CanTarget = false
					Combat:StackState("HitboxImmunity", true)

					local OG_Health = LuaCharacter.Humanoid.Health
					local NewJob = Job.new()

					NewJob:Task(function()
						Combat:StackState("HitboxImmunity", false)
						Entity.CanTarget = true
					end)

					NewJob:Task(task.delay(3.5, function()
						if (LuaCharacter.RootPart.Position - Chara_Spawn_Attachment.WorldPosition).Magnitude > Range then
							AntiStuck()
						end
					end))

					NewJob:Task(LuaCharacter.Humanoid.HealthChanged:Connect(function(NewHealth : number)
						if NewHealth < OG_Health then
							NewJob:Destroy()
						end
					end))

					NewJob:Task(Entity.OnPathingEnded:Connect(function()
						NewJob:Destroy()
					end))
				end
				
			end
			
			TryRun()
			
			LastTime = os.clock()
		end
	end))
	
	Combat.AngryStage = false
	
	local Auras = {}
	
	NPCJob:Task(LuaCharacter.Humanoid.HealthChanged:Connect(function(NewHealth : number)
		if NewHealth < Combat.AngryHealth and not Combat.AngryStage then
			Combat.AngryStage = true
			
			LuaPlayer.Replication:FireReliableVFX("Chara/Voicelines", "Create", LuaCharacter.Model, "I'll turn you all to DUST!")
			Auras = require(ReplicatedStorage.Effects.Characters.Chara.Aura.Script)(LuaCharacter.Model)
		end
	end))
	
	NPCJob:Task(LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value : boolean)
		task.spawn(function()
			for _, Aura in Auras do
				Aura:Destroy()
			end
		end)
	end))
	
	local Highlight = Instance.new("Highlight")
	Highlight.Name = "BossHighlight"
	Highlight.FillTransparency = 1
	Highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
	Highlight.OutlineTransparency = 0.85
	Highlight.Parent = LuaCharacter.Model
	
	Intro()
	
	return function()
		Entity:Destroy()
		Entity = nil
	end
end