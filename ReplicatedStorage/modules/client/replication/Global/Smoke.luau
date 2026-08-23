local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )
local RockHandler = require( ReplicatedStorage.modules.client.replication.Global.RockHandler )

return function(Part : BasePart, RaycastDistance : number, PartSize : number)
	local Raycast = workspace:Raycast(
		Part.Position + (Vector3.yAxis * 2), 
		Vector3.yAxis * -(RaycastDistance or 8), 
		Utility.VisualParams
	)

	if (Raycast) then
		local Dust = ReplicatedStorage.modules.effect.assets.Parts.Dust:Clone()
		Dust.Smoke.Size = NumberSequence.new(Utility.Seed:NextNumber(1.45, 1.8))
		
		Dust.Smoke.Color = ColorSequence.new(Color3.new(
			math.clamp(Raycast.Instance.Color.R * 0.95, 0, 1),
			math.clamp(Raycast.Instance.Color.G * 0.95, 0, 1),
			math.clamp(Raycast.Instance.Color.B * 0.95, 0, 1)
		))
			
		Dust.Position = Raycast.Position - Vector3.yAxis
		Dust.Orientation = RockHandler.GenerateRandomOrientation()
		Dust.Parent = workspace.Visuals
		
		if PartSize then
			Dust.Size = Vector3.new(PartSize, 1, PartSize)
			Dust.Smoke:Emit(18 * (PartSize / 2))
		else
			Dust.Smoke:Emit(18)
		end
		
		task.delay(Dust.Smoke.Lifetime.Max, Dust.Destroy, Dust)
	end
end