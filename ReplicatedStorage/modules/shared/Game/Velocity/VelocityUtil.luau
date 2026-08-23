local VelocityUtil = {}

function VelocityUtil.Clear(RootPart : BasePart)
	--if (RootPart == nil or RootPart.Parent == nil) then return end
	
	for _, BodyVelocity : BodyVelocity in ipairs(RootPart:GetChildren()) do
		if BodyVelocity:IsA("BodyVelocity") then
			BodyVelocity:Destroy()
		end
	end
end

function VelocityUtil.Create(RootPart : BasePart, Name : string)
	VelocityUtil.Clear(RootPart)
	
	local NewBodyVelocity = Instance.new("BodyVelocity")

	if Name then
		NewBodyVelocity.Name = Name
	end

	return NewBodyVelocity
end

return VelocityUtil