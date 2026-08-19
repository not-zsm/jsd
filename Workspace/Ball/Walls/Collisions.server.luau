for _, Item in ipairs(script.Parent:GetChildren()) do
	if Item:IsA("BasePart") then
		Item.CanCollide = false
	end
end