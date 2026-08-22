local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VelocityUtil = require(ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil)
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local JobModule = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local function CreateVelocity(Name : String, RootPart : BasePart, BaseStrength : Number)
	local Velocity = VelocityUtil.Create(RootPart, Name)
	Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
	Velocity.Parent = RootPart

	local VelStrength = Instance.new("NumberValue")
	VelStrength.Value = 40 --BaseStrength
	VelStrength.Name = "Strength"
	VelStrength.Parent = Velocity

	Utility.BindSignalDisconnectToInstanceDestroying(RunService.Stepped, Velocity, function()
		Velocity.Velocity = RootPart.CFrame.LookVector * VelStrength.Value
		RootPart:SetNetworkOwner(nil)
	end)

	return Velocity
end

return function(LuaCharacter : Model, Anim : AnimationTrack)
	local Job = JobModule.new()
	
	Job:Task(Anim.Stopped:Connect(function()
		Job:Destroy()
	end))
	
	local Model = LuaCharacter.Model
	local RootPart = LuaCharacter.RootPart
	
	
	local Velocities = {
		-->> Kick
		["1"] = function()
			local Velocity = Job:Task(CreateVelocity("Atonement Kick", RootPart, 0))

			-- Increase
			TweenService:Create(Velocity.Strength, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				Value = 95
			}):Play()

			-- Decrease
			Job:Task(task.delay(0.2, function()
				TweenService:Create(Velocity.Strength, TweenInfo.new(1.25 , Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Value = 0
				}):Play()
			end))

			Job:Task(task.delay(1.5, Velocity.Destroy, Velocity))
		end,

		-->> Dash 1
		["2"] = function()
			local Velocity = Job:Task(CreateVelocity("Atonement Dash 1", RootPart, 0))

			-- Increase
			TweenService:Create(Velocity.Strength, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Value = 110
			}):Play()

			-- Decrease
			Job:Task(task.delay(0.3, function()
				TweenService:Create(Velocity.Strength, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Value = 14
				}):Play()
			end))
		end,

		-->> Slice
		["3"] = function()
			local Velocity = Job:Task(CreateVelocity("Atonement Slice", RootPart, 55))

			-- Decrease
			TweenService:Create(Velocity.Strength, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Value = 0
			}):Play()
		end,

		-->> Dash 2
		["4"] = function()
			local Velocity = Job:Task(CreateVelocity("Atonement Dash 2", RootPart, 0))

			-- Increase
			TweenService:Create(Velocity.Strength, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Value = 140
			}):Play()

			-- Decrease
			Job:Task(task.delay(0.25, function()
				TweenService:Create(Velocity.Strength, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Value = 0
				}):Play()
			end))
		end,
	}
	
	Job:Task(Anim:GetMarkerReachedSignal("Velocity"):Connect(function(Parameter : string)
		local Func = Velocities[Parameter]
		if Func then
			Func()
		end
	end))
end