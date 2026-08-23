local TS = game:GetService("TweenService")
local RS = game:GetService('RunService')

-- modules
local module = {}

function module.Clasic_tween(part, data)
	local size = data.size or nil
	local tim = data.tim or 1
	local pos = data.pos or nil
	local trans = data.trans or nil
	local cf = data.cf or nil
	local colr = data.colr or nil
	local EasingStyle = data.EasingStyle 
	local EasingDirection = data.EasingDirection 
	local redo = data.redo or false
	local dely = data.dely 
	
	if size ~= nil then
		local startSize = data.startSize or part.Size
		part.Size = startSize
		
		local sizeTim = data.sizeTim 
		local sizeDel = data.sizeDel 
		
		local Info = TweenInfo.new(
			sizeTim or tim,
			EasingStyle or Enum.EasingStyle.Linear,
			EasingDirection or Enum.EasingDirection.Out,
			0,
			redo,
			sizeDel or dely or 0
		)
		local new = {}
		new.Size = size
		local twee = TS:Create(part, Info, new)
		twee:Play()
		twee:Destroy()
	end
	
	if trans ~= nil then
		local startTrans = data.startTrans or part.Transparency
		part.Transparency = startTrans
		
		local transTim = data.transTim 
		local transDel = data.transDel 
		
		local Info = TweenInfo.new(
			transTim or tim ,
			EasingStyle or Enum.EasingStyle.Linear,
			EasingDirection or Enum.EasingDirection.Out,
			0,
			redo,
			transDel or dely or 0
		)
		local new = {}
		new.Transparency = trans
		local twee = TS:Create(part, Info, new)
		twee:Play()
		twee:Destroy()
	end
	
	if cf ~= nil then
		local startcf = data.startcf or part.CFrame
		part.CFrame = startcf
		
		local cfTim = data.cfTim 
		local cfDel = data.cfDel 
		
		local Info = TweenInfo.new(
			cfTim or tim,
			EasingStyle or Enum.EasingStyle.Linear,
			EasingDirection or Enum.EasingDirection.Out,
			0,
			redo,
			cfDel or dely or 0
		)
		local new = {}
		new.CFrame = cf or startcf
		local twee = TS:Create(part, Info, new)
		twee:Play()
		twee:Destroy()
	end
	
	-- pos
	if pos ~= nil then
		local posTim = data.posTim 
		local posDely = data.posDely 

		local Info = TweenInfo.new(
			posTim or tim,
			EasingStyle or Enum.EasingStyle.Linear,
			EasingDirection or Enum.EasingDirection.Out,
			0,
			redo,
			posDely or dely or 0
		)
		local new = {}
		new.Position = pos
		local twee = TS:Create(part, Info, new)
		twee:Play()
		twee:Destroy()
	end
	
	-- colr
	if colr ~= nil then
		local colrTim = data.colrTim 
		local colrDel = data.colrDel 
		
		if part:IsA('FileMesh') then
			local startColr = data.startColr 
			part.VertexColor = part.VertexColor
			if startColr then 	part.VertexColor =  Vector3.new(startColr.Color) end
			
			
			local Info = TweenInfo.new(
				colrTim or tim,
				EasingStyle or Enum.EasingStyle.Linear,
				EasingDirection or Enum.EasingDirection.Out,
				0,
				redo,
				colrDel or 0
			)
			local new = {}
			new.VertexColor =  Vector3.new( colr.Color)
			local twee = TS:Create(part, Info, new)
			twee:Play()
			twee:Destroy()
		else
			local startColr = data.startColr or part.BrickColor

			part.Color = startColr.Color
			local Info = TweenInfo.new(
				colrTim or tim,
				EasingStyle or Enum.EasingStyle.Linear,
				EasingDirection or Enum.EasingDirection.Out,
				0,
				redo,
				colrDel or dely or 0
			)
			local new = {}
			new.Color = colr.Color
			local twee = TS:Create(part, Info, new)
			twee:Play()
			twee:Destroy()
			
		end
		
	end
end

module.extend = function(part, data)
	local hroot = data.hroot 
	local request = data.request
	local cf_start_point = data.cf_start_point or hroot.CFrame * CFrame.new(0,0,-2.5)
	
	local lenth = data.lenth or 100
	local tim = data.tim or 1
	local redo = data.redo or false
	local EasingStyle = data.EasingStyle or Enum.EasingStyle.Quad
	local invese = data.invese or nil
	
	if request == "Y" then
		if invese then
			module.Clasic_tween(part, {cf = cf_start_point * CFrame.new(0,lenth/2,0), size = part.Size + Vector3.new(0,lenth,0), EasingStyle = EasingStyle, redo = redo, tim = tim })
		else
			module.Clasic_tween(part, {cf = cf_start_point * CFrame.new(0,-lenth/2,0), size = part.Size + Vector3.new(0,lenth,0), EasingStyle = EasingStyle, redo = redo, tim = tim })
		end
		
	elseif request == "X" then
		if invese then
			module.Clasic_tween(part, {cf = cf_start_point * CFrame.new(lenth/2,0,0), size = part.Size + Vector3.new(lenth,0,0), EasingStyle, redo = redo, tim = tim})
		else
			module.Clasic_tween(part, {cf = cf_start_point * CFrame.new(-lenth/2,0,0), size = part.Size + Vector3.new(lenth,0,0), EasingStyle, redo = redo, tim = tim})
		end
		
	elseif request == "Z" then
		if invese then
			module.Clasic_tween(part, {cf = cf_start_point * CFrame.new(0,0,lenth/2), size = part.Size + Vector3.new(0,0,lenth), EasingStyle , redo = redo, tim = tim})
		else
			module.Clasic_tween(part, {cf = cf_start_point * CFrame.new(0,0,-lenth/2), size = part.Size + Vector3.new(0,0,lenth), EasingStyle , redo = redo, tim = tim})
		end
		
	end
	
end

--cf2
function module.cf2(part, dur, cf, times)
	task.delay(dur,function()
		local Info = TweenInfo.new(
			times or 1,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out,
			0,
			false,
			0
		)
		local new = {}
		new.CFrame = cf
		local twee = TS:Create(part, Info, new)
		twee:Play()
		
	
		
		return twee
	end)
	
end

--invisable
function module.invisable(model, wai, durI, durO)
	coroutine.wrap(function()
		-- script
		for i, v in pairs(model:GetDescendants()) do 
			if v:IsA("BasePart") or v:IsA("MeshPart") then
				if v.Name ~= "HumanoidRootPart"  then
					if not v:FindFirstChild("Invisible Part") then
						--		print(v.Name)
						local Tween = TS:Create(v,TweenInfo.new(durI),{Transparency = 1})
						Tween:Play()
					end


				end	
			end
		end
		task.delay(wai, function()
			for i, v in pairs(model:GetDescendants()) do 
				if v:IsA("BasePart") or v:IsA("MeshPart") then
					if v.Name ~= "HumanoidRootPart" then
						if not v:FindFirstChild("Invisible Part") then
							--						print(v.Name)
							local Tween = TS:Create(v,TweenInfo.new(durO),{Transparency = 0})
							Tween:Play()
						end

					end	
				end
			end
		end)
	end)()

	
end

--invisable
function module.Total_Invisable_Char(model, data)
	coroutine.wrap(function()
		
		local PlrData = data.PlrData
		local tween = data.tween or false
		local durI = data.durationIn or .2
		local wai = data.WaiT or .5
		local durO = data.durationOut or durI
		
		local function AttributeCheck(v)
			task.delay(durO+.1, function()
				if v:GetAttribute("NormalTransparency") then
					v.Transparency = v:GetAttribute("NormalTransparency")
				end
			end)
			
		end
		
		local function CheckEquipUnequip(v, bool)
			if v:IsA("BasePart") then
				task.delay(durO+.1,function()

					-- 
					if PlrData and  model:FindFirstChild(PlrData.Weapon) then
						local weapon =  model:FindFirstChild(PlrData.Weapon)
						if weapon['Equipped'].Value == bool then
							v.Transparency = 1
						else
							v.Transparency = 0
							if v:FindFirstChild("Transperancy") then
								v.Transparency = v:FindFirstChild("Transperancy").Value
							end
						end
					end

				end)
			end
		end
		
		local WeaponCheck = function(v)
			if v.Name ==  'WeaponParts' then
				coroutine.wrap(function()
					for i, v in pairs(v:GetChildren()) do
						
						CheckEquipUnequip(v,false)
					end
				end)()
				
			end
			
			if v.Name == "InCaseWeapon" then
				coroutine.wrap(function()
					for i, v in pairs(v:GetChildren()) do
						CheckEquipUnequip(v,true)
						
					end
				end)()
			end
			
		end
		
		
		-- script
		for i, v in pairs(model:GetDescendants()) do 
			if v:IsA("BasePart") or v:IsA("MeshPart")  or v:IsA("Decal") then
				if v.Name ~= "HumanoidRootPart" and v.Name ~= "Handle" then
					coroutine.wrap(function()
						if tween == true then
							local Tween = TS:Create(v,TweenInfo.new(durI),{Transparency = 1})
							Tween:Play()
						else
							v.Transparency = 1

						end
					end)()
					
				end	
			end
		end
		task.wait(wai)
		
		for i, v in pairs(model:GetDescendants()) do 
			
			if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("Decal") then
				if v.Name ~= "HumanoidRootPart" and v.Name ~= "Handle" then
					local Tween = TS:Create(v,TweenInfo.new(durO ),{Transparency = 0})
					Tween:Play()
					
					coroutine.wrap(function()
						AttributeCheck(v)
					end)()
					
					
				end	
			end
			
			if v:IsA("Folder") then
				
				coroutine.wrap(function()
					WeaponCheck(v)
				end)()
			
				
			end
		end
	end)()


end
--//spin
function module.spin(part, data)
	local speed = data.speed or .5
	local ans = data.ans or "Y"
	local inverse = data.inverse or nil
	local EasingStyle = data.EasingStyle or Enum.EasingStyle.Sine
	
	if ans == "Y" then
		task.spawn(function()
			if inverse ~= nil then
				
				RS.RenderStepped:Connect(function()
					part.CFrame = part.CFrame*CFrame.Angles(0,math. rad(-speed),0)
				end)
				
			else
				RS.RenderStepped:Connect(function()
					part.CFrame = part.CFrame*CFrame.Angles(0,math. rad(speed),0)
				end)
			end
			
		end)
	end
	
	if ans == "X" then
		task.spawn(function()
			if inverse ~= nil then
				RS.RenderStepped:Connect(function()
					part.CFrame = part.CFrame*CFrame.Angles(math.rad(-speed),math. rad(0),math. rad(0))
				end)
			else
				RS.RenderStepped:Connect(function()
					part.CFrame = part.CFrame*CFrame.Angles(math.rad(speed),math. rad(0),math. rad(0))
				end)
			end
			
		end)
		
	end
	
	if ans == "Z" then
		task.spawn(function()
			if inverse ~= nil then
				RS.RenderStepped:Connect(function()
					part.CFrame = part.CFrame*CFrame.Angles(math.rad(0),math. rad(0),math. rad(-speed))
				end)
			else
				RS.RenderStepped:Connect(function()
					part.CFrame = part.CFrame*CFrame.Angles(math.rad(0),math. rad(0),math. rad(speed))
				end)
			end
			
		end)
		
	end
end

--//invert-spin
function module.invert_spin(part, speed, ans)
	if ans == "Y" then
		task.spawn(function()
			local	info = TweenInfo.new(speed or 1,Enum.EasingStyle.Linear)

			local	Spin1 = TS:Create(part,info,{CFrame = part.CFrame * CFrame.Angles(0,math.rad(-120),0)})
			local	Spin2 = TS:Create(part,info,{CFrame = part.CFrame * CFrame.Angles(0,math.rad(-240),0)})
			local	Spin3 = TS:Create(part,info,{CFrame = part.CFrame * CFrame.Angles(0,math.rad(-360),0)})

			-- loopin
			Spin1:Play()
			Spin1.Completed:Connect(function()Spin2:Play() end)
			Spin2.Completed:Connect(function()Spin3:Play() end)
			Spin3.Completed:Connect(function()Spin1:Play() end)
		end)

	end

	if ans == "X" then
		task.spawn(function()
			local	info = TweenInfo.new(speed or 1,Enum.EasingStyle.Linear)

			local	Spin1 = TS:Create(part,info,{CFrame = part.CFrame * CFrame.Angles(math.rad(-120),0,0)})
			local	Spin2 = TS:Create(part,info,{CFrame = part.CFrame * CFrame.Angles(math.rad(-240),0,0)})
			local	Spin3 = TS:Create(part,info,{CFrame = part.CFrame * CFrame.Angles(math.rad(-360),0,0)})

			-- loopin
			Spin1:Play()
			Spin1.Completed:Connect(function()Spin2:Play() end)
			Spin2.Completed:Connect(function()Spin3:Play() end)
			Spin3.Completed:Connect(function()Spin1:Play() end)
		end)

	end

	if ans == "Z" then
		task.spawn(function()
			local	info = TweenInfo.new(speed or 1,Enum.EasingStyle.Linear)

			local	Spin1 = TS:Create(part,info,{CFrame = part.CFrame * CFrame.Angles(0,0,math.rad(-120))})
			local	Spin2 = TS:Create(part,info,{CFrame = part.CFrame * CFrame.Angles(0,0,math.rad(-240))})
			local	Spin3 = TS:Create(part,info,{CFrame = part.CFrame * CFrame.Angles(0,0,math.rad(-360))})

			-- loopin
			Spin1:Play()
			Spin1.Completed:Connect(function()Spin2:Play() end)
			Spin2.Completed:Connect(function()Spin3:Play() end)
			Spin3.Completed:Connect(function()Spin1:Play() end)
		end)

	end
end

function module.stween2(part, maxSize, trans, times)
	local Info = TweenInfo.new(
		times or 1,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out,
		0,
		false,
		0
	)
	local new = {}
	new.Size = maxSize
	new.Transparency = trans
	local twee = TS:Create(part, Info, new)
	twee:Play()
	return twee
end


function module.stween(part,maxSize, trans, times)
	local Info = TweenInfo.new(
		times or 1,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		0,
		false,
		0
	)
	local new = {}
	new.Size = maxSize
	new.Transparency = trans
	local twee = TS:Create(part, Info, new)
	twee:Play()
	return twee
end

function module.transtween(part, trans, times, dur)
	task.delay(dur,  function() 
		local Info = TweenInfo.new(
			times or 1,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out,
			0,
			false,
			0
		)
		local new = {}
		new.Transparency = trans
		local twee = TS:Create(part, Info, new)
		twee:Play()
		return twee
	end)
end

function module.trans_tween(part, data)
	local dur = data.dur
	local times = data.tim
	local trans = data.tran
	local EasingStyle = data.EasingStyle
	local tweendestry = data.bool or true
	
	--
	task.delay(dur or 0,  function() 
		local Info = TweenInfo.new(
			times or 1,
			EasingStyle or Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out,
			0,
			false,
			0
		)
		local new = {}
		new.Transparency = trans
		local twee = TS:Create(part, Info, new)
		twee:Play()
		
		if tweendestry == true then
			twee.Completed:Connect(function()
				twee:Destroy()
			end)
		end
		return twee
	end)
end

--size
function module.size_tween(part, data)
	local times = data.tim
	local maxSize = data.size
	local EasingStyle = data.EasingStyle
	local tweendestry = data.bool or true
	
	--
	local Info = TweenInfo.new(
		times or 1,
		EasingStyle or Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		0,
		false,
		0
	)
	local new = {}
	new.Size = maxSize
	local twee = TS:Create(part, Info, new)
	twee:Play()
	
	if tweendestry == true then
		twee.Completed:Connect(function()
			twee:Destroy()
		end)
	end
	
	return twee
end


function module.color_tween(part, data)
	local colr = data.colr or part.BrickColor
	local tim = data.tim or 1
	
	local Info = TweenInfo.new(
		tim ,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		0,
		false,
		0
	)
	local new = {}
	new.Color = colr.Color
	local twee = TS:Create(part, Info, new)
	twee:Play()
	
	return twee
end

-- colr 
function module.colortween(part, color, times)
	local Info = TweenInfo.new(
		times or 1,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		0,
		false,
		0
	)
	local new = {}
	new.Color = color
	local twee = TS:Create(part, Info, new)
	twee:Play()
	return twee
end

-- colr + return
function module.colortweenreturn(part, color, times)
	local Info = TweenInfo.new(
		times or 1,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		0,
		true,
		0
	)
	local new = {}
	new.Color = color
	local twee = TS:Create(part, Info, new)
	twee:Play()
	return twee
end

--cframe
function module.cframetween(part, cf, times, EasingStyle)
	local Info = TweenInfo.new(
		times or 1,
		EasingStyle or Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		0,
		false,
		0
	)
	local new = {}
	new.CFrame = cf
	local twee = TS:Create(part, Info, new)
	twee:Play()
	

	return twee
end


--modelCframe
function module.cframetweenModel(model, cf, times)
	local Info = TweenInfo.new(
		times or 1,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		0,
		false,
		0
	)
	local new = {}
	new.CFrame = cf
	local twee = TS:Create(model, Info, new)
	twee:Play()
	return twee
end

--size
function module.sizetween(part, maxSize, times)
	local Info = TweenInfo.new(
		times or 1,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		0,
		false,
		0
	)
	local new = {}
	new.Size = maxSize
	local twee = TS:Create(part, Info, new)
	twee:Play()
	return twee
end

--everything
function module.ctween(part,style, direction, maxSize, trans, times, color, cf)
	local Info = TweenInfo.new(
		times or 1,
		style,
		direction,
		0,
		false,
		0
	)
	local new = {}
	new.Size = maxSize
	new.Transparency = trans
	new.Color = color
	new.CFrame = cf
	local twee = TS:Create(part, Info, new)
	twee:Play()
	return twee
end

function module.ctween2(part,style, direction, maxSize, trans, times)
	local Info = TweenInfo.new(
		times or 1,
		style,
		direction,
		0,
		false,
		0
	)
	local new = {}
	new.Size = maxSize
	new.Transparency = trans
	local twee = TS:Create(part, Info, new)
	twee:Play()
	return twee
end

function module.btween(part, maxSize, trans, times, color, cf)
	local Info = TweenInfo.new(
		times or 1,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out,
		0,
		false,
		0
	)
	local new = {}
	new.Size = maxSize
	new.Transparency = trans
	new.Color = color
	new.CFrame = cf
	local twee = TS:Create(part, Info, new)
	twee:Play()
	return twee
end

return module