local ReplicatedStorage = game:GetService("ReplicatedStorage")


local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local VFX = {}
VFX.Models = {}

function VFX.AddAura(Model : Model)
	if (Model == nil or Model.Parent == nil or VFX.Models[Model] ~= nil) then return end
	
	VFX.Models[Model] = {}
	
	EffectUtility.EmitEffects(script.SFX, Model.HumanoidRootPart)
	
	for _, Item in ipairs(Model:GetChildren()) do
		if Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart" then
			VFX.Models[Model][Item] = {}
			
			local Asset = script.Assets:FindFirstChild(Item.Name)
			if (Asset == nil) then continue end

			for _, AssetItem in ipairs(Asset:GetChildren()) do
				local NewItem = AssetItem:Clone()
				NewItem.Parent = Item
				
				if NewItem:IsA("ParticleEmitter") then
					NewItem.Enabled = true
				end
				
				VFX.Models[Model][Item][NewItem] = true
			end
		end
	end
	
	for _, Item in ipairs(Model:GetChildren()) do
		if Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart" then
			for AssetItem in VFX.Models[Model][Item] do
				if AssetItem:IsA("Attachment") then
					for _, Beam in ipairs(AssetItem:GetChildren()) do
						Beam.Attachment1 = Item.Attachment2
					end

					EffectUtility.Toggle(AssetItem, true)
				end
			end
		end
	end
end

function VFX.RemoveAura(Model : Model)
	if (Model == nil or VFX.Models[Model] == nil) then return end

	for _, Item in ipairs(Model:GetChildren()) do
		if Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart" then
			for AssetItem in VFX.Models[Model][Item] do
				if AssetItem:IsA("Attachment") then
					EffectUtility.Toggle(AssetItem, false)
					
				elseif AssetItem:IsA("ParticleEmitter") then
					AssetItem.Enabled = false
				end
				
				task.delay(2, AssetItem.Destroy, AssetItem)
			end
		end
	end
	
	VFX.Models[Model] = nil
end

return VFX
