local module = { }

local TweenService = game:GetService("TweenService")
local MeshEmit = require(script.MeshEmit)

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

function module:mesh_emit(folder, mesh, transparency, flipbook, ids, speed)
	
	local meshes = folder
	local MeshToEmit = mesh

	for _, Mesh in MeshToEmit:GetDescendants() do
		if Mesh.Name == "Start" then
			MeshEmit(Mesh, transparency, flipbook, ids, speed)
		end
	end

end

function module:mesh_enable(folder, mesh, transparency, flipbook, ids, speed, duration, interval)

	local meshes = folder
	local MeshToEmit = mesh

	for _, Mesh in MeshToEmit:GetDescendants() do
		if Mesh.Name == "Start" then
			
			for i = 1, duration do
				MeshEmit(Mesh, transparency, flipbook, ids, speed)
				task.wait(interval)
			end
			
		end
	end

end

function module:mesh_burst(folder, mesh, transparency, flipbook, ids, speed, duration, interval, multiplier)

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

					MeshEmit(Mesh, transparency, flipbook, ids, speed)
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
	ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	
	local viewport = ScreenGui:WaitForChild("Viewport")
	viewport.ImageTransparency = start
	
	viewport.Ambient = color
	viewport.LightColor = color
	
	local clone = character:Clone()
	clone.Humanoid:Destroy()
	clone.HumanoidRootPart:Destroy()
	
	for _, v in clone:GetDescendants() do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Anchored = true
		end
	end
	
	clone.Parent = ScreenGui.Viewport.WorldModel
	
	viewport.CurrentCamera = workspace.Camera
	
	module:tween_single(viewport, tweentime, easingstyle, easingdirection, {ImageTransparency = 1, ImageColor3 = color})
	
	game.Debris:AddItem(ScreenGui, tweentime + 1)

end

return module