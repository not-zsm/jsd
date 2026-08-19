local TweenService = game:GetService("TweenService")

return function(Character : Model, VanishInfo : {}, MoveInfo : {}, DelayFactor : number, CustomEffect : () -> ())
	local StarterRootPosition = Character.HumanoidRootPart.Position

	local Holder = Instance.new("Model")
	Holder.Name = "Afterimage"

	local Humanoid = Instance.new("Humanoid")
	Humanoid.DisplayDistanceType = "None"
	Humanoid.HealthDisplayType = "AlwaysOff"
	Humanoid.BreakJointsOnDeath = false
	Humanoid.EvaluateStateMachine = false
	Humanoid.RequiresNeck = false
	Humanoid.AutomaticScalingEnabled = false

	local Shirt = Character:FindFirstChildOfClass("Shirt")
	local Pants = Character:FindFirstChildOfClass("Pants")

	if (Shirt ~= nil) then Shirt:Clone().Parent = Holder end
	if (Pants ~= nil) then Pants:Clone().Parent = Holder end

	for _, Part : BasePart in ipairs(Character:GetDescendants()) do
		if Part:IsA("BasePart") and Part.Name ~= "HumanoidRootPart" and not Part:HasTag("RagdollCollider") and not Part:GetAttribute("Transparent") then
			local Clone = Part:Clone()

			for _, Item in ipairs(Clone:GetChildren()) do
				if not Item:IsA("SpecialMesh") then
					Item:Destroy()
				end
			end

			Clone.CollisionGroup = "NoCollision"
			Clone.Anchored = true
			Clone.CanCollide = false
			Clone.CanTouch = false
			Clone.CanQuery = false
			Clone.Massless = true
			Clone.CastShadow = false
			Clone.Archivable = true
			Clone.Transparency = 0
			Clone.Parent = Holder

			TweenService:Create(Clone, TweenInfo.new(table.unpack(VanishInfo)), {
				Transparency = 1
			}):Play()

			task.delay(DelayFactor / 60, function()
				TweenService:Create(Clone, TweenInfo.new(table.unpack(MoveInfo)), {
					CFrame = Part.CFrame - (Character.HumanoidRootPart.Position - StarterRootPosition)
				}):Play()
			end)

		elseif Part:IsA("CharacterMesh") then
			Part:Clone().Parent = Holder
		end
	end
	
	if CustomEffect then
		task.spawn(CustomEffect, Holder)
	end

	Humanoid.Parent = Holder
	Holder.Parent = workspace.Visuals

	task.delay(VanishInfo[1], Holder.Destroy, Holder)
end
