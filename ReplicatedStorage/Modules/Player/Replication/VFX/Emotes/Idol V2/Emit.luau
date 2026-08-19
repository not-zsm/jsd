return function(Item : Instance)
	for _, Descendant in pairs(Item:GetDescendants()) do
		if Descendant:IsA("ParticleEmitter") then
			Descendant:Emit(Descendant:GetAttribute("EmitCount"))
		end
	end
end