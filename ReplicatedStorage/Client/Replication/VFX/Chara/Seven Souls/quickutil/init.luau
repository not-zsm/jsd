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

function module:meshemit(folder, mesh, transparency, flipbook, ids, speed)
	
	local meshes = folder
	local MeshToEmit = mesh

	for _, Mesh in MeshToEmit:GetDescendants() do
		if Mesh.Name == "Start" then
			MeshEmit(Mesh, transparency, flipbook, ids, speed)
		end
	end

end

function module:meshenable(folder, mesh, transparency, flipbook, ids, speed, duration, waittime)

	local meshes = folder
	local MeshToEmit = mesh

	for _, Mesh in MeshToEmit:GetDescendants() do
		if Mesh.Name == "Start" then
			
			for i = 1, duration do
				MeshEmit(Mesh, transparency, flipbook, ids, speed)
				task.wait(waittime)
			end
			
		end
	end

end

function module:tweensingle(source, tweentime, easingstyle, easingdirection, dictionary, destroy)
	
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

function module:tweendescendant(source, instance, tweentime, easingstyle, easingdirection, dictionary, destroy)
	
	for _, Instance in ipairs(source:GetDescendants()) do 
		if Instance:IsA(instance) then 
			
			local Tween = TweenService:Create(Instance, TweenInfo.new(tweentime, easingstyle, easingdirection), dictionary)
			Tween:Play()
			
			task.spawn(function()

				Tween.Completed:Wait()
				Tween:Destroy()

				if destroy then
					Instance:Destroy()
				end

			end)
			
		end 
	end

end

return module