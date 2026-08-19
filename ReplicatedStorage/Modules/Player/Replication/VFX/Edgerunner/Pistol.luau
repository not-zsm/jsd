local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local PistolAppearJobs = {}
local PistolShrinkJobs = {}

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

return {
	Appear = function(Model : Model)
		local Pistol : Model? = Model:WaitForChild("Pistol", 2) -- streaming enabled momento
		
		if PistolShrinkJobs[Pistol] then
			PistolShrinkJobs[Pistol]:Destroy()
			PistolShrinkJobs[Pistol] = nil
		end
		
		local Alpha = 0.1
		Pistol:ScaleTo(0.1)

		PistolAppearJobs[Pistol] = Job.new()
		
		PistolAppearJobs[Pistol]:Task(RunService.PreRender:Connect(function(Delta)
			if not PistolAppearJobs[Pistol] then
				return
			end
			
			Alpha += Delta

			local Clamped = math.clamp(Alpha, 0.1, 1)

			if (Clamped >= 1) then
				
				if Pistol and PistolAppearJobs[Pistol] then
					PistolAppearJobs[Pistol]:Destroy()
					PistolAppearJobs[Pistol] = nil
				end
				
				return
			end

			Pistol:ScaleTo(TweenService:GetValue(Clamped, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
		end))
		
		for _, Item in ipairs(Pistol:GetDescendants()) do
			if (Item:IsA("BasePart") or Item:IsA("Decal")) and not Item:HasTag("IgnoreTransparency") then
				Item.Transparency = 0
			end
		end
	end,
	
	Shrink = function(Model : Model)
		local Pistol = Model:WaitForChild("Pistol", 2) -- streaming enabled momento
		
		if PistolAppearJobs[Pistol] then
			PistolAppearJobs[Pistol]:Destroy()
			PistolAppearJobs[Pistol] = nil
		end
		
		EffectUtility.AddSFX(script.Holster, Pistol)
		
		local Alpha = 1
		
		Pistol:ScaleTo(1)
		PistolShrinkJobs[Pistol] = Job.new()

		PistolShrinkJobs[Pistol]:Task(RunService.PreRender:Connect(function(Delta)
			if not PistolShrinkJobs[Pistol] then
				return
			end
			
			Alpha -= Delta

			local Clamped = math.clamp(Alpha, 0.1, 1)

			if (Clamped <= 0.1 or not PistolShrinkJobs[Pistol]) then
				
				if Pistol and PistolShrinkJobs[Pistol] then
					PistolShrinkJobs[Pistol]:Destroy()
					PistolShrinkJobs[Pistol] = nil
				end
				
				return
			end

			Pistol:ScaleTo(TweenService:GetValue(Clamped, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
		end))
	end,
}