local UserInputService = game:GetService("UserInputService")
local Tips = script.Parent;
local AnchoringSide = 1;

local function update_input()
	local position = UserInputService:GetMouseLocation();
	Tips.Position = UDim2.fromOffset(position.X + 4 * AnchoringSide, position.Y);
end

UserInputService.InputChanged:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseMovement) then
		update_input();
	end
end)

local function change_side()
	if Tips.AbsoluteSize.Y > Tips.AbsoluteSize.X then
		Tips.AnchorPoint = Vector2.new(1, 1);
		AnchoringSide = -1;
	else
		Tips.AnchorPoint = Vector2.new(0, 1);
		AnchoringSide = 1;
	end;
	
	update_input();
end

--change_side();
Tips.ChildAdded:Connect(change_side);
Tips.ChildRemoved:Connect(change_side);
--Tips:GetPropertyChangedSignal("AbsoluteSize"):Connect(change_side);