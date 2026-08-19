local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local JobModule = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

--local function DoubleJump(LuaPlayer)
--	local LuaCharacter = LuaPlayer.Character
--	local RootPart : BasePart = LuaCharacter.RootPart
	
--	local Job = JobModule.new()
	
--	--local Velocity = Job:Task(VelocityUtil.Create(RootPart, "Float"))
--	--Velocity.MaxForce = Vector3.new(0, 1, 0) * 80000
--	--Velocity.Parent = RootPart
	
--	local StartupUserAnim : AnimationTrack = LuaCharacter.Humanoid.Animator:LoadAnimation(script["Double Jump"])
--	StartupUserAnim.Priority = Enum.AnimationPriority.Movement
	
--	Job:Task(StartupUserAnim.Stopped:Connect(function()
--		Job:Destroy()
--	end))
	
--	StartupUserAnim:Play(0.025, 1, 1.5)
	
--	Job:Task(StartupUserAnim:GetMarkerReachedSignal("Jump"):Once(function()
--		-- Apply upward velocity
--		--Velocity:Destroy()
		
--		RootPart.AssemblyLinearVelocity = RootPart.CFrame.UpVector * 83
--		LuaCharacter.Combat:AddCooldown("Double Jump", 1)
		
--		task.wait(0.5)
		
--		StartupUserAnim:Stop(0.35)
--	end))
--end

--return function(Movement)
--	local LuaPlayer = Movement.LuaPlayer
--	local LuaCharacter = LuaPlayer.Character
	
--	local Humanoid : Humanoid = LuaPlayer.Character.Humanoid
	
--	local CanDoubleJump = false

--	Humanoid.StateChanged:Connect(function(OldState, NewState)
--		if NewState == Enum.HumanoidStateType.Jumping and not LuaCharacter.Combat:CooldownExists("Double Jump") and not CanDoubleJump then
--			task.wait(0.1)

--			if (Humanoid:GetState() == Enum.HumanoidStateType.Freefall) then
--				CanDoubleJump = true 
--			end
			
--		elseif NewState == Enum.HumanoidStateType.Landed then 
--			CanDoubleJump = false
--		end
--	end)

--	UserInputService.InputBegan:Connect(function(Input)
--		if (Input.KeyCode == Enum.KeyCode.Space or Input.KeyCode == Enum.KeyCode.ButtonA) and CanDoubleJump and Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
--			CanDoubleJump = false 
--			DoubleJump(LuaPlayer)
--		end
--	end)
--end

return function(Movement)
	local LuaPlayer = Movement.LuaPlayer
	local LuaCharacter = LuaPlayer.Character

	local Humanoid : Humanoid = LuaCharacter.Humanoid
	local RootPart : BasePart = LuaCharacter.RootPart

	local CanDoubleJump = false
	
	local DoubleJumpAnimation : AnimationTrack = LuaCharacter.Humanoid.Animator:LoadAnimation(script["Double Jump"])
	DoubleJumpAnimation.Priority = Enum.AnimationPriority.Movement

	local Job = JobModule.Extend(LuaCharacter.HumanoidJob)

	Job:Task(Humanoid.StateChanged:Connect(function(OldState, NewState)
		if NewState == Enum.HumanoidStateType.Jumping and not LuaCharacter.Combat:CooldownExists("Double Jump") and not CanDoubleJump then
			task.wait(0.1)

			if (Humanoid:GetState() == Enum.HumanoidStateType.Freefall) then
				CanDoubleJump = true 
			end

		elseif NewState == Enum.HumanoidStateType.Landed then 
			CanDoubleJump = false
		end
	end))

	Job:Task(UserInputService.InputBegan:Connect(function(Input)
		if (Input.KeyCode == Enum.KeyCode.Space or Input.KeyCode == Enum.KeyCode.ButtonA) and CanDoubleJump and Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
			CanDoubleJump = false 

			DoubleJumpAnimation:Play(0.025, 1, 1.5)
			
			Job:Task(DoubleJumpAnimation:GetMarkerReachedSignal("Jump"):Once(function()
				RootPart.AssemblyLinearVelocity = RootPart.CFrame.UpVector * 83
				LuaCharacter.Combat:AddCooldown("Double Jump", 1)

				task.wait(0.5)

				DoubleJumpAnimation:Stop(0.35)
			end))
		end
	end))
	
	return function()
		Job:Destroy()
	end
end