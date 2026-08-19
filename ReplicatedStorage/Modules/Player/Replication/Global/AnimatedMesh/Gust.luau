--// Service
local rp = game:GetService('ReplicatedStorage')
local RS = game:GetService('RunService')
local TS = game:GetService('TweenService')

--// Module(s)
local SharedModules = {}
for i,v in pairs(script.Parent:GetChildren()) do
	if v:IsA('ModuleScript') and v.Name~= script.Name then
		SharedModules[v.Name] = require(v)
	end
end

--// Utilities
local module = {}

--// GroundWind
module.GroundWind = function(Data)
	local part = Data.part 
	local ttab =Data.ttab or {.5,.4,.3}
	local xn = Data.xn or  4.4/2
	local spd = Data.speed
	local forlop = Data.forlop or 1
	local wait_= Data.wait_ 
	local gtab = Data.gtab or {true, false, false,false}
	local cf = Data.cf -- hroot.CFrame * CFrame.new(0,-2.5,0) --* CFrame.Angles(math.rad(0),0,math.rad(45))
	local _CF = cf
	local timCrun = Data.timCrun or 1
	
	local colr = Data.colr 
	task.spawn(function()
	
		for i = 1, forlop do
			local tim = Data.tim or  ttab[math.random(1,#ttab)]
			local glass = Data.glass or  gtab[math.random(1,#gtab)]
			-- CurveWind
			
			tim = tim * timCrun
			cf = _CF
			
			if cf then 
				cf = cf * CFrame.Angles(math.rad(math.random(-25,25)),0,0) 
			else 
				cf = part.CFrame * CFrame.new(0,-2.5,0) * CFrame.Angles(math.rad(math.random(-25,25)),0,0)  
			end
			
			local Wind = script.VFX["CurveWind"]:Clone()
			Wind.CFrame = cf
			
			if colr then 
				Wind.BrickColor = colr 
			end

			Wind.Parent = workspace.Visuals
			
			SharedModules['TM'].Clasic_tween(Wind, {startSize = Vector3.new(0,20*xn,0),size = Vector3.new(25*xn, 5*xn, 25*xn),  tim = tim, startTrans = .5,trans = 1,  EasingStyle = Enum.EasingStyle.Sine, EasingDirection = Enum.EasingDirection.Out})
			SharedModules['Spin'].Spin({part = Wind, angleY = 360, tim = tim, speed = spd or math.random(.3/2, 3/2)})
			
			task.delay(tim, Wind.Destroy, Wind)
			
			--growing wind
			cf = _CF
			
			if cf then 
				cf = cf  
			else 
				cf = part.CFrame * CFrame.new(0,-2.5,0)  
			end
			
			local Wind = script.VFX["growing wind"]:Clone()
			Wind.CFrame = cf
			
			if colr then 
				Wind.BrickColor = colr 
			end
			
			if glass then 
				Wind.Material = Enum.Material.Glass 
			end
			
			Wind.Parent = workspace.Visuals

			SharedModules['TM'].Clasic_tween(Wind, {startSize = Vector3.new(1*xn,20*xn,1*xn),size = Vector3.new(16*xn, 3.5*xn, 16*xn),  tim = tim, startTrans = 0,trans = 1,  EasingStyle = Enum.EasingStyle.Sine, EasingDirection = Enum.EasingDirection.Out})
			SharedModules['Spin'].Spin({part = Wind, angleY = 360, tim = tim, speed = spd or math.random(.3/2, 3/2)})
			
			task.delay(tim, Wind.Destroy, Wind)
			
			-- CurveWind
			cf = _CF
			
			if cf then 
				cf = cf * CFrame.Angles(math.rad(math.random(-25,25)),0,0) 
			else 
				cf = part.CFrame * CFrame.new(0,-2.5,0) * CFrame.Angles(math.rad(math.random(-25,25)),0,0)  
			end
			
			local Wind = script.VFX["CurveWind"]:Clone()
			Wind.CFrame = cf
			
			if colr then Wind.BrickColor = colr end
		
			Wind.Parent = workspace.Visuals
			
			SharedModules['TM'].Clasic_tween(Wind, {startSize = Vector3.new(0,20*xn,0),size = Vector3.new(25*xn, 5*xn, 25*xn),  tim = tim, startTrans = .5,trans = 1,  EasingStyle = Enum.EasingStyle.Sine, EasingDirection = Enum.EasingDirection.Out})
			SharedModules['Spin'].Spin({part = Wind, angleY = 360, tim = tim, speed = spd or math.random(.3/2, 3/2)})
			
			task.delay(tim, Wind.Destroy, Wind)

			if Data.wait_ then
				task.wait(wait_ or tim/2)
			end
		end
	end)
end


module['LinesWindRemastered'] = function(Data)
	local part = Data.part
	local tim = Data.tim 
	local speed = Data.speed or .5/2
	
	local colorTab = Data.colorTab or {BrickColor.new('White'),BrickColor.new('Really black')}
	local xn = Data.xn or 1
	local two = Data.two
	local wait_ = Data.wait_
	
	
	local C1tab,   C2tab =  Data.C1tab or {["x"] = 5 ,["y"] = 7,["z"] = 25/4},            Data.C2tab or  {["x"] = 0,["y"] = 0,["z"] = -25}
	print(C1tab['x'])
	local S1tab, S2tab =  Data.S1tab or {["x"] = 1/2 ,["y"] = 1/2,["z"] = 15},            Data.S2tab or  {["x"] = 0,["y"] = 0,["z"] = 15}
	print(S1tab['x'], 'size x')
	--print(colorTab[math.random(1,#colorTab)])

	if tim then
		task.spawn(function()
			while tim > 0  do
				local CFtab = Data.CFtab or {cf1 = CFrame.new(math.random(-C1tab['x']*xn,C1tab['x']*xn),math.random(-C1tab['y']*xn,C1tab['y']),math.random(C1tab['z']*xn,C1tab['z']*xn)), cf2 = CFrame.new(0,0,C2tab['z']*xn)}
				local SZtab = Data.SZtab or {size1 =  Vector3.new(S1tab['x']*xn, S1tab['y']*xn, S1tab['z']*xn) , size2 = Vector3.new(S2tab['x']*xn, S2tab['y']*xn, S2tab['z']*xn) }
				--
				local cf = part * CFtab['cf1'] --part.CFrame * CFrame.new(math.random(-5,5),math.random(-5,5),math.random(25/4,25/2))
				local sphere = script.MeshFold["Sphere"]:Clone()
			
				sphere.CFrame = cf
				sphere.Color = colorTab[math.random(1,#colorTab)].Color
				sphere.Material, sphere.CastShadow = Enum.Material.Neon, false
				SharedModules['TM'].Clasic_tween(sphere,{cf = sphere.CFrame * CFtab['cf2'], cfTim =  speed , startSize = SZtab['size1'], size = SZtab['size2'],startColr = colorTab[math.random(1,#colorTab)] , tim = speed,EasingStyle = Enum.EasingStyle.Cubic, EasingDirection = Enum.EasingDirection.Out, startTrans = .5,trans = 1})
				sphere.Parent = workspace.Visuals
				
				game.Debris:AddItem(sphere, speed)

				task.wait(.0001)
				
				if wait_ then
					task.wait(wait_)
				end
				
				if two then
					--
					local cf = part * CFtab['cf1'] --part.CFrame * CFrame.new(math.random(-5,5),math.random(-5,5),math.random(25/4,25/2))
					local sphere = script.MeshFold["Sphere"]:Clone()
					sphere.Parent = workspace.Visuals
					sphere.CFrame = cf
					sphere.Color = colorTab[math.random(1,#colorTab)].Color
					sphere.Material, sphere.CastShadow = Enum.Material.Neon, false
					SharedModules['TM'].Clasic_tween(sphere,{cf = sphere.CFrame * CFtab['cf2'], cfTim =  speed , startSize = SZtab['size1'], size = SZtab['size2'],startColr = colorTab[math.random(1,#colorTab)] , tim = speed,EasingStyle = Enum.EasingStyle.Cubic, EasingDirection = Enum.EasingDirection.Out, startTrans = 0,trans = 1})

					game.Debris:AddItem(sphere, speed)
					
					--
					local cf = part * CFtab['cf1'] --part.CFrame * CFrame.new(math.random(-5,5),math.random(-5,5),math.random(25/4,25/2))
					local sphere = script.MeshFold["Sphere"]:Clone()
					sphere.Parent = workspace.Visuals
					sphere.CFrame = cf
					sphere.Color = colorTab[math.random(1,#colorTab)].Color
					sphere.Material, sphere.CastShadow = Enum.Material.Neon, false
					SharedModules['TM'].Clasic_tween(sphere,{cf = sphere.CFrame * CFtab['cf2'], cfTim = speed , startSize = SZtab['size1'], size = SZtab['size2'],startColr = colorTab[math.random(1,#colorTab)] , tim = speed,EasingStyle = Enum.EasingStyle.Cubic, EasingDirection = Enum.EasingDirection.Out, startTrans = 0,trans = 1})

					game.Debris:AddItem(sphere, speed)
				end
				
				--[[
				local sphere = SharedModules['UtilitlesModules'].locaL( rp.Storage.Mesh['Sphere']:Clone(), cf or part.CFrame * CFrame.new(math.random(-8,8),math.random(-8,8),math.random(30/4,30/2)))
				sphere.Color = colorTab[math.random(1,#colorTab)].Color
				sphere.Material, sphere.CastShadow = Enum.Material.Neon, false
				SharedModules['TM'].Clasic_tween(sphere,{cf = sphere.CFrame * CFrame.new(0,0,-30/2), startSize = Vector3.new(1,1,15), size = Vector3.new(0,0,15),startColr = colorTab[math.random(1,#colorTab)] , tim = .5/2,EasingStyle = Enum.EasingStyle.Cubic, EasingDirection = Enum.EasingDirection.Out, trans = 1})

				game.Debris:AddItem(sphere, .5/2)]]




			end

		end)

		task.spawn(function()
			task.wait(tim)
			tim = 0 
		end)

	end

	--[[
	local Tween1 = TS:Create(sphere,TweenInfo.new(.5/2,Enum.EasingStyle.Cubic),{Transparency = 0, Size = Vector3.new(.1,0,.1)})

	Tween1:Play()
	]]

end

module['HeatGround - Trail'] = function(Data)
	local part = Data.part 
	local name = Data.name or 'HeatGround Trail (Debris)'
	local cf1, cf2 = Data.cf1, Data.cf2
	local colr = Data.colr or BrickColor.new('Neon orange')
	local width = Data.width or .3
	local tim = Data.tim or 1
	local lifetime = Data.lifetime or .5

	local lazer = script["Particle/Trails"][name]:Clone()
	lazer.Parent = workspace.Visuals
	lazer.CFrame = cf1 or part.CFrame * CFrame.new(0,-2.5,0)
	SharedModules['TM'].Clasic_tween(lazer, { cf = cf2,tim = tim, EasingStyle = Enum.EasingStyle.Exponential, EasingDirection = Enum.EasingDirection.Out})
	lazer['1'].Position = Vector3.new(-width, 0,0)
	lazer['2'].Position = Vector3.new(width, 0,0)
	-- properites
	lazer.Anchored = true

	if lazer:FindFirstChild('Trail')  and lazer:FindFirstChild('Trail2')  then
		local trail, trail1 =  lazer:FindFirstChild('Trail') , lazer:FindFirstChild('Trail2') 
		trail.Lifetime = lifetime
		trail1.Lifetime = lifetime
		
		trail.Enabled = true
		trail1.Enabled = true
		
		trail.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, colr.Color), ColorSequenceKeypoint.new(1, BrickColor.new('Really black').Color)}
		trail1.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, colr.Color), ColorSequenceKeypoint.new(1, BrickColor.new('Really black').Color)}
	end

	--SharedModules['Particle'].Play({part = lazer, tim = tim})
	game.Debris:AddItem(lazer, tim*5)

	return lazer
end
return module
