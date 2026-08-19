local Main = script.Parent

local Ball = Main.Ball
local StartPosition = Ball.Position

local Scored = false
local KickCooldown = false

local Seed = Random.new()

Ball.Touched:Connect(function(Hit : BasePart)
	if Ball:CanSetNetworkOwnership() then
		Ball:SetNetworkOwner(nil)
	end
	
	if Hit.Name == "Goal" and not Scored then
		Scored = true
		Ball.Goal:Play()
		
		task.delay(Ball.Goal.TimeLength, function()
			Ball.AssemblyLinearVelocity = Vector3.zero
			Ball.AssemblyAngularVelocity = Vector3.zero
			Ball.Position = StartPosition
			
			Scored = false
		end)
	else
		if KickCooldown then
			return 
		end
		
		local Model = Hit.Parent
		if not Model:IsA("Model") then return end
		
		local Humanoid : Humanoid? = Model:FindFirstChild("Humanoid")
		if (Humanoid == nil) then return end
		
		KickCooldown = true

		local RootPart = Humanoid.RootPart
		if (RootPart == nil) then return end
		
		Ball.AssemblyLinearVelocity = RootPart.CFrame.LookVector * math.clamp(RootPart.AssemblyLinearVelocity.Magnitude, 2.5, 50)
		Ball.Kick.PlaybackSpeed = Seed:NextNumber(0.9, 1.1)
		Ball.Kick:Play()
		
		task.delay(0.1, function()
			KickCooldown = false
		end)
	end
end)