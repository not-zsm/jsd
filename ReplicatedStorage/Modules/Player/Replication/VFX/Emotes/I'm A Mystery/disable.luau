return function(effect)
	if effect:IsA("ParticleEmitter") or effect:IsA("Trail") or effect:IsA("Beam") then
		effect.Enabled = false
	end

	for _, fx in effect:GetDescendants() do
		if fx:IsA("ParticleEmitter") or fx:IsA("Trail") or fx:IsA("Beam") then
			fx.Enabled = false
		end
	end
end