-- //Services// --

local TweenService = game:GetService("TweenService")

-- //Module// --

local BubbleModule = {}

function BubbleModule.CreateBubble(CF, StartSize, StartTr, EndSize, Time) -- Origin CFrame, Mesh ID, Start Size, Start Transparency, End Size, Time
	local Part = game.ReplicatedStorage.Bubblestop_Mesh:Clone()
	Part.CFrame = CF
	Part.Anchored = true
	Part.CanCollide = false
	Part.Massless = true
	Part.Parent = workspace:FindFirstChild("Effects") or workspace
	Part.Material = Enum.Material.Glass
	Part.Size = StartSize
	Part.Transparency = StartTr
	
	local RequiredHighlight = Instance.new("Highlight")
	RequiredHighlight.Enabled = false
	RequiredHighlight.Parent = Part
	
	game.Debris:addItem(Part, Time)

	local Info = TweenInfo.new(
		Time, -- Length
		Enum.EasingStyle.Sine, -- Easing Style
		Enum.EasingDirection.Out, -- Easing Direction
		0, -- Times repeated
		false, -- Reverse
		0 -- Delay
	)

	local Goals =
		{
			Transparency = 1;
			Size = EndSize;
		}

	local Tween = TweenService:Create(Part, Info, Goals)

	Tween:Play()
end

return BubbleModule
