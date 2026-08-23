local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local EventService = require( replicatedStorage.modules.shared.Utilities.EventService )
local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local remove_effects = {}

return function(part : BasePart, value : boolean)
	if value then
		if remove_effects[part] ~= nil then return end
		
		local newJob = Job.new()
		local disconnected = false
		
		local LockOnUI = script.LockOn:Clone()
		local currentUpdate = (LockOnUI:GetAttribute("_Update") or 0)+1 

		do
			LockOnUI:SetAttribute("_Update",currentUpdate)
			LockOnUI.Parent = part
		end

		TweenService:Create(LockOnUI.SpinRatio,TweenInfo.new(0.05,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Value = 150}):Play()

		task.delay(0.05,function()
			TweenService:Create(LockOnUI.SpinRatio,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value = 50}):Play()
		end)

		local Images, Segami = {
			[1] = LockOnUI:WaitForChild("Top");
			[2] = LockOnUI:WaitForChild("Middle");
			[3] = LockOnUI:WaitForChild("Bottom");
		}, {
			[1] = LockOnUI:WaitForChild("Top");
			[2] = LockOnUI:WaitForChild("Middle");
			[3] = LockOnUI:WaitForChild("Bottom");
		}

		for Index, Image in ipairs(Images) do
			newJob:Task(task.delay(-0.05 + 0.05 * Index, function()
				if currentUpdate ~= LockOnUI:GetAttribute("_Update") then return end
				
				if Index == 1 then
					TweenService:Create(Image,TweenInfo.new(0.15,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{ImageTransparency = 0}):Play()
					TweenService:Create(Image,TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Size = UDim2.fromScale(1.1,1.1)}):Play()
					
					newJob:Task(task.delay(0.15,function()
						if currentUpdate ~= LockOnUI:GetAttribute("_Update") then return end
						TweenService:Create(Image,TweenInfo.new(0.35,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{ImageTransparency = 0.5}):Play()
					end))
					
				elseif Index == 2 then
					TweenService:Create(Image,TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Size = UDim2.fromScale(0.7,0.7),ImageTransparency = 0.75}):Play()
					
				elseif Index == 3 then
					TweenService:Create(Image,TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Size = UDim2.fromScale(0.35,0.35),ImageTransparency = 0.9}):Play()
				end
			end))
		end
	
		remove_effects[part] = EventService.new()

		newJob:Task(remove_effects[part]:Connect(function(_c)
			disconnected = true

			remove_effects[part]:Destroy()
			remove_effects[part] = nil
		end))
		
		local Delta = 1/60 * LockOnUI.SpinRatio.Value
		
		while not disconnected do
			LockOnUI.Bottom.Rotation += -0.35 * Delta
			LockOnUI.Middle.Rotation += 0.75 * Delta
			LockOnUI.Top.Rotation += -1 * Delta
			Delta = task.wait()*LockOnUI.SpinRatio.Value
		end
		
		newJob:Destroy()
		TweenService:Create(LockOnUI.SpinRatio,TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value = 15}):Play()
		
		for Index, Image in ipairs(Segami) do
			task.delay(-0.05 + 0.05 * Index, function()
				if currentUpdate ~= LockOnUI:GetAttribute("_Update") then return end
				
				if Index == 3 then
					TweenService:Create(Image,TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Size = UDim2.fromScale(1.25,1.25),ImageTransparency = 2}):Play()
					
				elseif Index == 2 then
					TweenService:Create(Image,TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Size = UDim2.fromScale(1.5,1.5),ImageTransparency = 1}):Play()
					
				elseif Index == 1 then
					TweenService:Create(Image,TweenInfo.new(0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Size = UDim2.fromScale(2,2),ImageTransparency = 01}):Play()
				end
			end)
		end
		
		local Tick = tick()
		
		while currentUpdate == LockOnUI:GetAttribute("_Update") and tick() - Tick <= 0.5 do
			LockOnUI.Bottom.Rotation += -0.35 * Delta
			LockOnUI.Middle.Rotation += 0.75 * Delta
			LockOnUI.Top.Rotation += -1 * Delta
			Delta = task.wait() * LockOnUI.SpinRatio.Value
		end
		
		if currentUpdate == LockOnUI:GetAttribute("_Update") then
			LockOnUI:Destroy()
		end
	else
		if remove_effects[part] then
			remove_effects[part]:Fire()
		end
	end
end