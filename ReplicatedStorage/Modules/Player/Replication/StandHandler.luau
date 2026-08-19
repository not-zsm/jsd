local TweenService = game:GetService("TweenService")

local StandHandler = {};

function StandHandler.CreateStandMovement()
	
end;

function StandHandler.SetStandVisible(Character, Visible: boolean)
	local Stand = StandHandler.GetStand(Character)
	local Transparency = if Visible then 0 else 1;
	
	if Stand then
		for _, Item in Stand:GetDescendants() do
			if Item:GetAttribute("Invisible") then
				continue;
			end;
			
			if Item:IsA("BasePart") and (Item.Name ~= "HumanoidRootPart") then
				Item.Transparency = Transparency;
				
			elseif Item:HasTag("Aura") then
				Item.Visible = Visible;
			end;
		end;
	end;
end;

function StandHandler.GetStand(Character: Model): Model?
	if (Character == nil or Character.Parent == nil) then
		return nil;
	end

	local Stand = Character:WaitForChild("Stand", 2)
	
	return Stand;
end;

local StandTween: Tween?;

function StandHandler.Move(Character: Model, Coordinate : CFrame, Time: number)
	local Stand = StandHandler.GetStand(Character)

	if Stand then
		local Mover: Motor6D? = Stand.PrimaryPart:WaitForChild("Mover", 2);
		
		if Mover then
			if StandTween then
				StandTween:Cancel()
				StandTween = nil
			end;
			
			if (Time == 0) then
				Mover.C0 = Coordinate;
			else
				StandTween = TweenService:Create(Mover, TweenInfo.new(Time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {C0 = Coordinate})
				StandTween:Play()
			end;
		end;
	end;
end;

return StandHandler;