return function(effect)
	for _, particleEmitter in effect:GetDescendants() do
		if not particleEmitter:IsA("ParticleEmitter") then continue end
		
		local emitDelay = particleEmitter:GetAttribute("EmitDelay")
		
		if emitDelay then
			task.delay(emitDelay, function()
				particleEmitter:Emit(particleEmitter:GetAttribute("EmitCount"))
			end)
			
			continue
		end
		
		particleEmitter:Emit(particleEmitter:GetAttribute("EmitCount"))
	end
end