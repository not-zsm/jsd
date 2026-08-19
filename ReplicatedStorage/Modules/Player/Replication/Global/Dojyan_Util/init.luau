local module = { }

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

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

function module:mesh_emit(folder, mesh, transparency, flipbook, ids, speed)
	for _, Mesh in mesh:GetDescendants() do
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
			
			task.spawn(function()
				for i = 1, duration do
					MeshEmit(Mesh, transparency, flipbook, ids, speed)
					task.wait(interval)
				end
			end)
			
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

	Tween.Completed:Once(function()
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
			
			Tween.Completed:Once(function()
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

function module:afterimage(character : Model, tweentime, easingstyle, easingdirection, color, start)
	local ScreenGui = script:WaitForChild("ScreenGui"):Clone()
	
	local viewport = ScreenGui:WaitForChild("Viewport")
	viewport.ImageTransparency = start
	viewport.Ambient = color
	viewport.LightColor = color
	
	character.Archivable = true
	local clone = character:Clone()
	character.Archivable = false
	
	for _, item in ipairs(clone:GetDescendants()) do
		if item:IsA("ParticleEmitter") or item:IsA("LuaSourceContainer") then
			item:Destroy()
		end
	end
	
	clone.Parent = ScreenGui.Viewport.WorldModel
	
	viewport.CurrentCamera = workspace.CurrentCamera
	ScreenGui.Parent = LocalPlayer.PlayerGui
	
	local main_animator : Animator = character.Humanoid.Animator
	local clone_animator : Animator = clone.Humanoid.Animator
	
	for _, item : AnimationTrack in ipairs(main_animator:GetPlayingAnimationTracks()) do
		if item.IsPlaying then
			local clone_animation = clone_animator:LoadAnimation(item.Animation)
			clone_animation:Play(0, 1, 0)
			clone_animation.TimePosition = item.TimePosition
		end
	end

	module:tween_single(viewport, tweentime, easingstyle, easingdirection, {ImageTransparency = 1, ImageColor3 = color})
	task.delay(tweentime + 1, ScreenGui.Destroy, ScreenGui)
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

			Tween.Completed:Once(function()
				Tween:Destroy()
			end)

			Tween:Play()

		end	

	end
end


return module