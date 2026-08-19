local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

return {
	Burn = function(Character : Model)
		local BodyColors : BodyColors = Character:FindFirstChild("Body Colors")
		
		if BodyColors then
			BodyColors.HeadColor3 = Color3.new(0,0,0)
			BodyColors.LeftArmColor3 = Color3.new(0,0,0)
			BodyColors.RightArmColor3 = Color3.new(0,0,0)
			BodyColors.LeftLegColor3 = Color3.new(0,0,0)
			BodyColors.RightLegColor3 = Color3.new(0,0,0)
			BodyColors.TorsoColor3 = Color3.new(0,0,0)
		end
		
		local BurnVFX = script.BurnVFX
		
		for _, Clothing in pairs(Character:GetChildren()) do
			if Clothing:IsA("Clothing") then
				Clothing:Destroy()
			end
		end
		
		for _, Limb in pairs(BurnVFX:GetChildren()) do
			for _, Effect in pairs(Limb:GetChildren()) do
				local NewEffect = Effect:Clone()
				NewEffect.Parent = Character:FindFirstChild(Limb.Name)
			end
		end
	end,
}
