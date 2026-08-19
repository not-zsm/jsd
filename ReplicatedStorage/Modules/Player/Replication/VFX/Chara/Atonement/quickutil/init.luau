local module = { }

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local MeshEmit = require(script.MeshEmit)
local BoatTween = require(script.BoatTween)

function module:interact(source, instance, property, value)

	for _, Instance in ipairs(source:GetDescendants()) do 
		if Instance:IsA(instance) then 
			Instance[property] = value
		end 
	end

end

function module:emit(effect)

	for _, ParticleEmitter in ipairs(effect:GetDescendants()) do 
		if ParticleEmitter:IsA("ParticleEmitter") then 
			ParticleEmitter:Emit(ParticleEmitter:GetAttribute("EmitCount")) 
		end 
	end

end

function module:mesh_emit(folder, mesh, transparency, flipbook, ids, framerate)

	local meshes = folder
	local MeshToEmit = mesh

	for _, Mesh in MeshToEmit:GetDescendants() do
		if Mesh.Name == "Start" then
			MeshEmit(Mesh, transparency, flipbook, ids, framerate)
		end
	end

end

function module:mesh_enable(folder, mesh, transparency, flipbook, ids, framerate, duration, interval)

	local meshes = folder
	local MeshToEmit = mesh

	for _, Mesh in MeshToEmit:GetDescendants() do
		
		if Mesh.Name == "Start" then

			task.spawn(function()
				for i = 1, duration do
					MeshEmit(Mesh, transparency, flipbook, ids, framerate)
					task.wait(interval)
				end
			end)

		end
	end

end

function module:mesh_burst(folder, mesh, transparency, flipbook, ids, framerate, duration, interval, multiplier)

	local meshes = folder
	local MeshToEmit = mesh

	local current_models = { }

	for _, Mesh in MeshToEmit:GetDescendants() do

		if Mesh:IsA("Model") then
			table.insert(current_models, Mesh)
		end

		if Mesh.Name == "Start" then

			task.spawn(function()

				for i = 1, duration do

					for _, Get in ipairs(current_models) do
						Get:SetAttribute("Duration", interval * 1.2)
					end

					MeshEmit(Mesh, transparency, flipbook, ids, framerate)
					task.wait(interval * multiplier + multiplier)

					interval += .1

				end

			end)

		end
	end

end

function module:tween_single(source, tweentime, easingstyle, easingdirection, dictionary, destroy)

	local Tween = TweenService:Create(source, TweenInfo.new(tweentime, easingstyle, easingdirection), dictionary)
	Tween:Play()

	task.spawn(function()

		Tween.Completed:Wait()
		Tween:Destroy()

		if destroy then
			source:Destroy()
		end

	end)

end

function module:tween_descendant(source, instance, tweentime, easingstyle, easingdirection, dictionary, destroy)

	for _, Instance in ipairs(source:GetDescendants()) do 
		if Instance:IsA(instance) then 

			local Tween = TweenService:Create(Instance, TweenInfo.new(tweentime, easingstyle, easingdirection), dictionary)
			Tween:Play()

			task.spawn(function()

				Tween.Completed:Wait()
				Tween:Destroy()

				if destroy then
					source:Destroy()
				end

			end)

		end 
	end

end

function module:custom_flipbook(source, instance, ids, speed)

	if instance == "Beam" then

		for _, Search in ipairs(source:GetDescendants()) do

			if Search:IsA("Beam") or Search:IsA("Decal") then

				task.spawn(function()
					for i = 1, #ids do
						Search.Texture = ids[i]
						task.wait(speed)
					end

				end)

			elseif Search:IsA("ImageLabel") then

				task.spawn(function()
					for i = 1, #ids do
						Search.Image = ids[i]
						task.wait(speed)
					end

				end)

			end

		end
	end

end

function module:framerate_beam(source, startlength, duration, interval, multipler)

	for _, Beam in ipairs(source:GetDescendants()) do

		if Beam:IsA("Beam") then

			task.spawn(function()

				Beam.TextureLength = startlength or 3

				for i = 1, duration do

					if Beam.TextureLength <= 0.2 then return end;

					Beam.TextureLength -= multipler
					task.wait(interval)

				end

			end)
		end	

	end

end

function module:afterimage(character, tweentime, easingstyle, easingdirection, color, start)

	local ScreenGui = script:WaitForChild("ScreenGui"):Clone()
	ScreenGui.Parent = game:GetService("StarterGui")

	local viewport = ScreenGui:WaitForChild("Viewport")
	viewport.ImageTransparency = start

	viewport.Ambient = color
	viewport.LightColor = color

	local clone = character:Clone()
	
	for _, vfx in ipairs(clone:GetDescendants()) do
		if vfx:IsA("ParticleEmitter") then
			vfx:Destroy()
		end
	end
	
	clone.Parent = ScreenGui.Viewport.WorldModel
	
	viewport.CurrentCamera = workspace.Camera

	module:tween_single(viewport, tweentime, easingstyle, easingdirection, {ImageTransparency = 1, ImageColor3 = color})

	game.Debris:AddItem(ScreenGui, tweentime + 1)

end

function module:shadow(character, magnitude, speed, duration, transparency, folder)

	local afterimage = character:clone()
	afterimage.Parent = folder
	
	afterimage.Name = "shadow"
	
	for _, vfx in ipairs(afterimage:GetDescendants()) do
		if vfx:IsA("ParticleEmitter") then
			vfx:Destroy()
		end
	end
	
	for _, bodypart in ipairs(afterimage:GetDescendants()) do

		if bodypart:IsA("Accessory") or bodypart:IsA("Decal") or bodypart:IsA("Clothing") then
			bodypart:Destroy()
		end
		
		if bodypart:IsA("Part") then

			if string.match(bodypart.Name, "Handle") then
				bodypart:Destroy()
			end

		end
		
		if bodypart:IsA("BasePart") or bodypart:IsA("MeshPart") then

			task.spawn(function()
				if bodypart.Name == "HumanoidRootPart" then return end
				bodypart.Transparency = transparency
			end)

			character.Archivable = true

			bodypart.Color = Color3.fromRGB(0, 0, 0)
			bodypart.CastShadow = false
			
			bodypart.CanCollide = false
			bodypart.Massless = true

			bodypart.Material = Enum.Material.Neon

		end

	end

	local rootpart = afterimage.PrimaryPart
	local originalCFrame = rootpart.CFrame

	local shakeMagnitude = magnitude
	local shakeSpeed = speed
	local shakeDuration = duration

	local startTime = tick()

	task.spawn(function()

		if shakeDuration == math.huge then return end

		task.delay(shakeDuration - 2, function()

			for _, bodypart in ipairs(afterimage:GetChildren()) do
				if bodypart:IsA("BasePart") or bodypart:IsA("MeshPart") then
					module:tween_single(bodypart, 1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Transparency = 1}, true)
				end
			end

		end)

	end)

	while tick() - startTime < shakeDuration do

		afterimage.PrimaryPart.CFrame = character.PrimaryPart.CFrame

		local offsetX = math.random() * shakeMagnitude * 2 - shakeMagnitude
		local offsetY = math.random() * shakeMagnitude * 2 - shakeMagnitude
		local offsetZ = math.random() * shakeMagnitude * 2 - shakeMagnitude

		rootpart.CFrame = afterimage.PrimaryPart.CFrame * CFrame.new(offsetX, offsetY, offsetZ)

		task.wait(shakeSpeed)

	end

	rootpart.CFrame = originalCFrame

end

function module:shadow_emit(character, magnitude, speed, duration, decrease, transparency, folder)

	local afterimage = character:clone()
	afterimage.Parent = folder
	
	for _, vfx in ipairs(afterimage:GetDescendants()) do
		if vfx:IsA("ParticleEmitter") then
			vfx:Destroy()
		end
	end
	
	afterimage.Name = "shadow"

	for _, bodypart in ipairs(afterimage:GetDescendants()) do
		
		if bodypart:IsA("Accessory") or bodypart:IsA("Decal") or bodypart:IsA("Clothing") or bodypart:IsA("MeshPart") then
			bodypart:Destroy()
		end
		
		if bodypart:IsA("Part") then
			
			if string.match(bodypart.Name, "Handle") then
				bodypart:Destroy()
			end
			
		end
		
		if bodypart:IsA("BasePart") or bodypart:IsA("MeshPart") then
			
			task.spawn(function()
				if bodypart.Name == "HumanoidRootPart" then return end
				bodypart.Transparency = transparency
			end)

			character.Archivable = true

			bodypart.CastShadow = false
			
			bodypart.CanCollide = false
			bodypart.Massless = true
			
			local BodyColors = afterimage:WaitForChild("Body Colors")
			
			BodyColors.HeadColor3 = Color3.fromRGB(0,0,0)
			BodyColors.LeftArmColor3 = Color3.fromRGB(0,0,0)
			BodyColors.RightArmColor3 = Color3.fromRGB(0,0,0)
			BodyColors.LeftLegColor3 = Color3.fromRGB(0,0,0)
			BodyColors.RightLegColor3 = Color3.fromRGB(0,0,0)
			BodyColors.TorsoColor3 = Color3.fromRGB(0,0,0)
			
			bodypart.Material = Enum.Material.Neon

		end

	end

	afterimage.PrimaryPart.CFrame = character.PrimaryPart.CFrame

	local rootpart = afterimage.PrimaryPart
	local originalCFrame = rootpart.CFrame

	local shakeMagnitude = magnitude
	local shakeSpeed = speed
	local shakeDuration = duration

	local startTime = tick()

	task.delay(shakeDuration - 5, function()

		for _, bodypart in ipairs(afterimage:GetChildren()) do
			if bodypart:IsA("BasePart") or bodypart:IsA("MeshPart") then
				module:tween_single(bodypart, .5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Transparency = 1}, true)
			end
		end

		game.Debris:AddItem(afterimage, 2)

	end)

	while tick() - startTime < shakeDuration do

		local offsetX = math.random() * shakeMagnitude * 2 - shakeMagnitude
		local offsetY = math.random() * shakeMagnitude * 2 - shakeMagnitude
		local offsetZ = math.random() * shakeMagnitude * 2 - shakeMagnitude

		rootpart.CFrame = originalCFrame * CFrame.new(offsetX, offsetY, offsetZ)

		if shakeMagnitude <= 0 then break end
		shakeMagnitude = shakeMagnitude - decrease

		task.wait(shakeSpeed)

	end

	rootpart.CFrame = originalCFrame

end

function module:rock_emit(origin, amount, velocityspread, upwardforce, startsize, lifetime, folder)

	for i = 1, amount do

		task.wait()

		local force = {
			X = {-velocityspread, velocityspread},
			Y = {10, upwardforce},
			Z = {-velocityspread, velocityspread},
		}	

		local Velocity = Vector3.new(math.random(force.X[1], force.X[2]), math.random(force.Y[1], force.Y[2]), math.random(force.Z[1], force.Z[2]))

		local randomizedgoal = math.random(-180, 180)

		local rock = script:WaitForChild("Rock"):Clone()
		rock.Parent = folder

		rock.CFrame = CFrame.new(origin.Position) * CFrame.Angles(math.random(0, 360), math.random(0, 360), math.random(0, 360))
		rock.Size = startsize or Vector3.new(2, 1, 2)

		local BodyVelocity = Instance.new("BodyVelocity")
		BodyVelocity.Parent = rock

		BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

		local lookForce = math.random(force.Z[1], force.Z[2])
		local rightForce = math.random(force.X[1], force.X[2])
		local upForce = math.random(force.Y[1], force.Y[2])

		local lookVector = origin.CFrame.LookVector.Unit * lookForce
		local rightVector = origin.CFrame.RightVector.Unit * rightForce
		local upVector = origin.CFrame.UpVector.Unit * upForce

		BodyVelocity.Velocity = lookVector + upVector + rightVector

		local OriginalOrientation = rock.Orientation
		local GoalOrientation = Vector3.new(rock.Orientation.X + randomizedgoal, rock.Orientation.Y + randomizedgoal, rock.Orientation.Z + randomizedgoal)

		local Tween = TweenService:Create(rock, TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge), {Orientation = GoalOrientation})
		Tween:Play()

		task.spawn(function()

			Tween.Completed:Wait()
			Tween:Destroy()

		end)

		Debris:AddItem(BodyVelocity, .1)

		task.delay(lifetime, function()
			module:tween_single(rock, 1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Size = Vector3.zero}, true)
		end)

		local params = RaycastParams.new()

		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {workspace.map}
		params.IgnoreWater = true

		local newray = workspace:Raycast(rock.Position + Vector3.new(0, 500, 0),Vector3.new(0, -1000, 0), params)

		if newray and newray.Instance then

			rock.Material = newray.Instance.Material
			rock.Color = newray.Instance.Color
			rock.Transparency = newray.Instance.Transparency

			if newray.Instance.Material == Enum.Material.Grass then
				rock.Material = Enum.Material.Mud
				rock.Color = Color3.fromRGB(86, 71, 64)
			end
		end

	end

end

function module:rocks_fly(origin, amount, startsize, lifetime, folder)

	for i = 1, amount do

		local randomizedstart = math.random(-180, 180)
		local randomizedgoal = math.random(-360, 360)

		local rock = script:WaitForChild("Rock"):Clone()
		rock.Parent = folder

		rock.Position = origin.Position + Vector3.new(math.random(-origin.Size.X/2, origin.Size.X/2), 0, math.random(-origin.Size.Z, origin.Size.Z))

		rock.Size = Vector3.zero

		module:tween_single(rock, .3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Size = startsize})

		module:tween_single(rock, 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {["CFrame"] = rock.CFrame * CFrame.new(0, 10, 0) * CFrame.Angles(math.rad(randomizedgoal), math.rad(randomizedgoal), math.rad(randomizedgoal))})

		local OriginalOrientation = rock.Orientation
		local GoalOrientation = Vector3.new(rock.Orientation.X + randomizedgoal, rock.Orientation.Y + randomizedgoal, rock.Orientation.Z + randomizedgoal)

		local Tween = TweenService:Create(rock, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge), {Orientation = GoalOrientation})
		Tween:Play()

		task.spawn(function()

			Tween.Completed:Wait()
			Tween:Destroy()

		end)

		task.delay(lifetime, function()
			module:tween_single(rock, 1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Size = Vector3.zero}, true)
		end)

		local params = RaycastParams.new()

		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {workspace.map}
		params.IgnoreWater = true

		local newray = workspace:Raycast(rock.Position + Vector3.new(0, 500, 0),Vector3.new(0, -1000, 0), params)

		if newray and newray.Instance then

			rock.Material = newray.Instance.Material
			rock.Color = newray.Instance.Color
			rock.Transparency = newray.Instance.Transparency

			if newray.Instance.Material == Enum.Material.Grass then
				rock.Material = Enum.Material.Mud
				rock.Color = Color3.fromRGB(86, 71, 64)
			end
		end

		task.wait(.1)

	end

end

function module:spawn_projectile(origin, projectile, power, CFrame, folder)

	local clone = projectile:Clone()
	clone.Parent = folder

	clone.CFrame = origin.CFrame

	module:tween_single(clone, power, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, {["CFrame"] = clone.CFrame * CFrame}, true)

end

function module:follow_cframe(origin, object, length)
	
	task.spawn(function()
		
		for i = 1, length do
			object.CFrame = CFrame.new(origin.CFrame.Position) * object.CFrame.Rotation 
			task.wait(.05)
		end
		
	end)
	
end

function module:beam_transparency(source, time)

	for _, Beam in ipairs(source:GetDescendants()) do

		if Beam:IsA("Beam") then

			local Tween = BoatTween:Create(Beam, {

				Time = time;
				EasingStyle = "Quint";
				EasingDirection = "Out";

				Reverses = false;
				DelayTime = 0;
				RepeatCount = 0;

				StepType = "Heartbeat";

				Goal = {
					Transparency = NumberSequence.new(1)
				};
			})

			Tween:Play()

		end	

	end
end

return module