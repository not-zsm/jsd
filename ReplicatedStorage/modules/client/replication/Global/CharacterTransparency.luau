local PreviousTransparency = {}
local PreviousEnabled = {}
local PreviousParticleTransparency = {};

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AenoirEmit = require( ReplicatedStorage.modules.client.replication.EffectUtility.AenoirEmit )

return function(Model : Model, NewValue : number)
	
	for _, Item in ipairs(Model:GetDescendants()) do
		
		if Item:GetAttribute("Transparent") or Item:HasTag("RagdollCollider") then
			continue;
		end;
		
		if (Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart") or Item:IsA("Decal") then
			if (NewValue == 0) then
				Item.Transparency = PreviousTransparency[Item] or 0

				if PreviousTransparency[Item] then
					PreviousTransparency[Item] = nil
				end
			else
				if (PreviousTransparency[Item] == nil) then
					PreviousTransparency[Item] = Item.Transparency
				end

				Item.Transparency = math.max(NewValue, PreviousTransparency[Item] or 0)
			end

		elseif ( (Item:IsA("ParticleEmitter") or Item:IsA("Beam")) and Item:HasTag("Aura") ) or Item:IsA("BillboardGui") then
			local IsParticle = Item:IsA("ParticleEmitter") or Item:IsA("Beam");
			
			if (PreviousEnabled[Item] == nil) then
				PreviousEnabled[Item] = Item.Enabled
			end
			
			if (IsParticle and PreviousParticleTransparency[Item] == nil) then
				PreviousParticleTransparency[Item] = Item.Transparency
			end;
			
			if (NewValue == 1) then
				Item.Enabled = false;
				
				if IsParticle then
					Item.Transparency = NumberSequence.new(1);
				end
			else
				Item.Enabled = PreviousEnabled[Item];
				
				if IsParticle then
					Item.Transparency = AenoirEmit.LerpNumberSequence(PreviousParticleTransparency[Item], 1, NewValue);
				end
				
				if (NewValue == 0) then
					PreviousParticleTransparency[Item] = nil;
				end;
				
				PreviousEnabled[Item] = nil;
			end
		end
	end
end