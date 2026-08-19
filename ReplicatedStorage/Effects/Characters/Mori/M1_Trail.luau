return function(RootPart : BasePart, Time : number)
	local Model : Model = RootPart.Parent
	local LeftLeg = Model["Left Leg"]
	local RightLeg = Model["Right Leg"]

	local Trails = {}
	
	for Index = 1, 2 do
		local Trail = script.Trail:Clone()

		for _, Item in ipairs(Trail:GetChildren()) do
			if Item:IsA("Beam") then
				Item.Enabled = true
			end
		end

		Trails[Trail] = true
		Trail.Parent = (Index == 1 and LeftLeg or RightLeg)

		if Time then
			task.delay((Time * 1.25), Trail.Destroy, Trail)
		end
	end
	
	return Trails
end