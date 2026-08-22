local TS = game:GetService('TweenService')
local RS = game:GetService('RunService')

local module = {}

module.Spin = function(data)
	local part = data.part
	local speed = data.speed or .01
	local tim = data.tim or .5
	
	local angleX, angleY, angleZ = data.angleX or 0, data.angleY or 0, data.angleZ or 0
	local disconnect = false
	local dp = data.dp or false 
	

	--// Spin
	local spin = function()
		--print('still running')
		if disconnect == false then
			
			--
			if dp then 
				part.Position = dp.Position
			--	local tween1 = TS:Create(part, TweenInfo.new(.0001, Enum.EasingStyle.Linear, Enum.EasingDirection.Out) ,  {Position = dp.Position })
			--	tween1:Play()
			end
			
			--
			if angleY == 360 or angleY == -360 then
				local ti = TweenInfo.new(speed/3 or .03/3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out) 
				local propertyToTween = {

					CFrame = part.CFrame*CFrame.Angles(math.rad(  0),math.rad(angleY/6),math.rad(0))
				}
				local tween1 = TS:Create(part, ti, propertyToTween)
				tween1:Play()
				
				-- tween2
				local tween2 = TS:Create(part, ti, propertyToTween)
				tween1.Completed:Connect(function() tween2:Play() end)
				
				-- tween3
				local tween3 = TS:Create(part, ti, propertyToTween)
				tween2.Completed:Connect(function() tween3:Play() end)
				
				-- tween4
				local tween4 = TS:Create(part, ti, propertyToTween)
				tween3.Completed:Connect(function() tween4:Play() end)
				
				-- tween5
				local tween5 = TS:Create(part, ti, propertyToTween)
				tween4.Completed:Connect(function() tween5:Play() end)
				
				-- tween6
				local tween6 = TS:Create(part, ti, propertyToTween)
				tween5.Completed:Connect(function() tween6:Play() end)
			else
				local ti = TweenInfo.new(speed or .03, Enum.EasingStyle.Sine, Enum.EasingDirection.Out) 
				local propertyToTween = {
					--CFrame = part.CFrame* CFrame.fromEulerAnglesXYZ(math.rad(angleX or 0),math.rad(angleY or 80),math.rad(angleZ or 0)),
					--Orientation = Vector3.new( part.Orientation.X + 360,part.Orientation.Y+0,part.Orientation.Z+0)

					CFrame = part.CFrame*CFrame.fromOrientation(math.rad( angleX or 0),math.rad(angleY or 0),math.rad( angleZ or 0))
				}
				local tween = TS:Create(part, ti, propertyToTween)
				tween:Play()
			end

		end
	end


	local n = tim

	--[[ RS_Spin
	task.spawn(function()
		while tim > 0 do
			task.wait()
			spin()
		end
	end)]]
	
	
	
	--
	local RS_Spin = RS.RenderStepped:Connect(function()
		spin()
	end)


	task.delay(tim, function()
		n = 0
		disconnect = true
		RS_Spin:Disconnect()
		if dp then dp:Destroy() end
	end)

end

return module
