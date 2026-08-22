local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )

return function(Position : (Instance | Vector3), StartTransparency : number, StartSize : Vector3, FinalSize : Vector3, Duration : number, RemoveDuration : number)
	local Part = script.Bubble:Clone()
	
	if typeof(Position) == "Instance" then
		local Id = tostring({})
		
		RunService:BindToRenderStep(Id, Utility.CharacterRenderPriority, function()
			Part.Position = Position.Position
		end)
		
		Part.Destroying:Once(function()
			RunService:UnbindFromRenderStep(Id)
		end)
	else
		Part.Position = Position
	end
	
	Part.Material = Enum.Material.Glass
	Part.Size = StartSize
	Part.Transparency = StartTransparency

	local RequiredHighlight = Instance.new("Highlight")
	RequiredHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	RequiredHighlight.FillTransparency = 1
	RequiredHighlight.OutlineTransparency = 1
	RequiredHighlight.Enabled = false
	RequiredHighlight.Parent = Part
	
	Part.Parent = workspace.Visuals

	TweenService:Create(Part,  TweenInfo.new(Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.In), 
		{Transparency = 1, Size = FinalSize}
	):Play()
	
	task.delay(RemoveDuration or Duration, Part.Destroy, Part)
	
	return Part
end