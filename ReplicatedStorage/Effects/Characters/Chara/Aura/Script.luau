return function(Model : Model)
	local Aura = {}
	
	for _, Limb in ipairs(Model:GetChildren()) do 
		if Limb:IsA("BasePart") and Limb.Name ~= "HumanoidRootPart" then
			for Index, Particle in script.Parent.Effects:GetChildren() do
				local ParticleClone = Particle:Clone()
				ParticleClone.Parent = Limb
				ParticleClone.Enabled = true
				table.insert(Aura, ParticleClone)
			end
		end
	end
	
	return Aura
end