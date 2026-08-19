local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local VFX = {}
VFX.Emoters = {}

function VFX.Add(Model : Model)
	VFX.Emoters[Model] = {}
	
	for _, Item in ipairs(Model:GetChildren()) do
		if Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart" then
			for _, Particle in ipairs(script.VFX:GetChildren()) do
				local NewParticle = Particle:Clone()
				NewParticle.Parent = Item
				
				VFX.Emoters[Model][NewParticle] = true
				NewParticle.Enabled = true
			end
		end
	end
end

function VFX.Remove(Model : Model)
	if (VFX.Emoters[Model] == nil) then return end
	
	for VFX in VFX.Emoters[Model] do
		VFX:Destroy()
	end
end

return VFX
