local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local MaidModule = require( ReplicatedStorage.Packages.Maid )

return function()
	local Character = script.Parent
	local RootPart = Character:WaitForChild("HumanoidRootPart", 100)
	local Hitbox = Character:WaitForChild("NewsboyHitbox")
	
	local WavingIdle : AnimationTrack = Character.Humanoid.Animator:LoadAnimation(script.WavingIdle)
	local NearIdle : AnimationTrack = Character.Humanoid.Animator:LoadAnimation(script.NearIdle)
	
	local WaveToNear : AnimationTrack = Character.Humanoid.Animator:LoadAnimation(script["Wave -> Near"])
	local NearToWave : AnimationTrack = Character.Humanoid.Animator:LoadAnimation(script["Near -> Wave"])
	
	local GiveAnim : AnimationTrack = Character.Humanoid.Animator:LoadAnimation(script.Give)
	GiveAnim.Priority = Enum.AnimationPriority.Action4
	
	WavingIdle:Play(0)
	
	local Maid = MaidModule.new()
	local FalseMaid
	local LoopCoroutine
	
	local HitboxConnection
	
	local function OnConnection()
		HitboxConnection:Disconnect()
		if FalseMaid then
			task.cancel(FalseMaid)
		end
		
		local NPCPosition = RootPart.Position

		Maid:add(RunService.PreSimulation:Connect(function()
			local TargetPosition = LocalPlayer.Character.HumanoidRootPart.Position
			RootPart.CFrame = CFrame.lookAt(NPCPosition, Vector3.new(TargetPosition.X, NPCPosition.Y, TargetPosition.Z))
		end))

		Maid:add(task.spawn(function()
			while task.wait(0.3) do
				if (LocalPlayer:DistanceFromCharacter(NPCPosition) > 50) then
					Maid:clean()

					-- Animation
					NearIdle:Stop()
					WaveToNear:Stop(0)
					NearToWave:Play()

					FalseMaid = task.delay(0.8, function()
						WavingIdle:Play()
					end)
					
					break
				end
			end
		end))
		
		Maid:add(function()
			-- Restart Touched Connection
			HitboxConnection = Hitbox.Touched:Connect(function(PartTouched)
				if PartTouched.Parent == LocalPlayer.Character then
					OnConnection()
				end
			end)
		end)
		
		Maid:add(Character:GetAttributeChangedSignal("Reading"):Connect(function()
			if Character:GetAttribute("Reading") then
				GiveAnim:Play()

				Maid:add(GiveAnim:GetMarkerReachedSignal("Give"):Connect(function()
					Character.RolledPaper.Transparency = 1

					task.delay(1, function()
						TweenService:Create(Character.RolledPaper, TweenInfo.new(2), {Transparency = 0}):Play()
					end)
				end))
			end
		end))
		
		-- Animation
		WavingIdle:Stop()
		NearToWave:Stop(0)
		WaveToNear:Play()
		
		Maid:add(task.delay(0.8, function()
			NearIdle:Play()
		end))
	end
	
	HitboxConnection = Hitbox.Touched:Connect(function(PartTouched)
		if PartTouched.Parent == LocalPlayer.Character then
			OnConnection()
		end
	end)
end