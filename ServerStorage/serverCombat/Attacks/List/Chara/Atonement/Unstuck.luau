local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnstuckModule = {}
UnstuckModule.StepDistance = 3
UnstuckModule.MaxSteps = 20

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local function IsCFrameSafe(TestCFrame, Character)
	local HRP = Character:FindFirstChild("HumanoidRootPart")
	if not HRP then return false end

	local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = { Character }

	local BoxSize = HRP.Size-- + Vector3.new(0.5, 0, 0.5)
	local Parts = Workspace:GetPartBoundsInBox(TestCFrame, BoxSize, Params)

	for _, Part in ipairs(Parts) do
		if Part.CanCollide and not Part:IsDescendantOf(Character) then
			print(`Collided With: {Part}`)
			return false
		end
	end

	return true
end

function UnstuckModule:FindNearestSafePosition(Character, StartCFrame)
	local HRP = Character:FindFirstChild("HumanoidRootPart")
	if not HRP then return nil end

	local CurrentCFrame = StartCFrame

	for _ = 1, self.MaxSteps do
		for Height = 0, 5, 2 do
			local TestCFrame = CurrentCFrame * CFrame.new(0, Height, 0)
			if IsCFrameSafe(TestCFrame, Character) then
				return TestCFrame
			end
		end

		CurrentCFrame = CurrentCFrame * CFrame.new(0, 0, self.StepDistance)

		-- Stop early if near HRP
		if (CurrentCFrame.Position - HRP.Position).Magnitude < 2 then
			break
		end
	end

	return nil
end

function UnstuckModule:Unstuck(Character, StartCFrame)
	local HRP = Character:FindFirstChild("HumanoidRootPart")
	if not HRP then return false end

	HRP.Anchored = true
	if not StartCFrame then
		StartCFrame = HRP.CFrame
	end

	local SafeCFrame = self:FindNearestSafePosition(Character, StartCFrame)
	if SafeCFrame then
		HRP.CFrame = SafeCFrame
		print(`Found Safe CFrame: {tostring(SafeCFrame.Position)}`)
		HRP.Anchored = false
		return true
	end

	HRP.Anchored = false

	if workspace:GetAttribute("IsTestPlace") then
		local Player = Players:GetPlayerFromCharacter(Character)
		if Player then
			ReplicatedStorage.Remotes.Notification:FireClient(Player, {
				Title = "Unstuck Error",
				Text = "Unable to find a safe position for a player.",
				Duration = 2
			})
		end
	end

	return false
end

return UnstuckModule
