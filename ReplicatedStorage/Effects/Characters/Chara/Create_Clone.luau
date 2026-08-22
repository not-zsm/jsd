local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )

return function(Model : Model, DontMakeHighlight : boolean)
	local Clone = script.Model:Clone()
	Clone.Archivable = false
	Clone.Name = "DRUGS ALL IN MY CUP GOT A GIRL SO DIZZY 😴😴😴"

	local CloneHumanoid = Clone:FindFirstChild("Humanoid")
	local CloneRootPart = Clone:FindFirstChild("HumanoidRootPart")

	if not DontMakeHighlight then
		local Highlight = Instance.new("Highlight")
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.FillColor = Color3.fromRGB(42, 136, 150)
		Highlight.FillTransparency = 13
		Highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
		Highlight.OutlineTransparency = 0.6
		Highlight.Parent = Clone
	end

	for _, Part : BasePart in ipairs(Clone:GetDescendants()) do
		if Part:IsA("BasePart") then
			Part.CollisionGroup = "NoCollision"
			Part.CanCollide = false
			Part.CanTouch = false
			Part.CanQuery = false
			Part.Massless = true
			Part.CastShadow = false
		end
	end

	EffectUtility.Weld(Clone, Model.PrimaryPart)

	Clone:PivotTo(Model:GetPivot())

	return Clone, CloneHumanoid, CloneRootPart
end
