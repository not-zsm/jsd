local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Affected = {}

return function(Settings : {Character : Model, Rate : number?, StartPercentage : number?})
	local Character = Settings.Character
	if (Character == nil) then return end
	
	if Affected[Character] then
		Affected[Character].Percent = 1
		return
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if  (Humanoid == nil) then return end
	
	local Animator = Humanoid:FindFirstChildOfClass("Animator")
	if  (Animator == nil) then return end
	
	local RootPart = Character:FindFirstChild("HumanoidRootPart")
	if  (RootPart == nil) then return end

	local RootJoint = RootPart:FindFirstChild("RootJoint")
	if  (RootJoint == nil) then return end

	local Rate = Settings.Rate or 2
	
	local Data = {Percent = Settings.StartPercentage or 1, RootOffset = (RootJoint.C0)}
	Affected[Character] = Data
	
	local Connection : RBXScriptConnection; Connection = RunService.PreSimulation:Connect(function(Delta)
		Data.Percent -= (Delta * Rate)
		
		if (Data.Percent <= 0) then
			Connection:Disconnect()
			Affected[Character] = nil
			return
		end

		local X = (math.random() - 0.5) * Data.Percent
		local Z = (math.random() - 0.5) * Data.Percent
		
		RootJoint.Transform = Data.RootOffset * CFrame.new(X, 0, Z):ToWorldSpace(Data.RootOffset) * (#Animator:GetPlayingAnimationTracks() > 0 and RootJoint.Transform or CFrame.identity)
	end)
end