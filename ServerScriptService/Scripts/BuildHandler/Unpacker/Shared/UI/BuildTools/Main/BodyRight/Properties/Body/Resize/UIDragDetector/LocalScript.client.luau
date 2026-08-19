local DragDetector = script.Parent;
local Body = DragDetector.Parent.Parent;
local Reference = Body.Parent;

local function DragCallback(input_position: Vector2)
	local deltaX = input_position.X - Reference.AbsolutePosition.X
	local absSize = Reference.AbsoluteSize;
	
	Body.Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(0 - math.clamp(deltaX, -absSize.X * 2, absSize.X / 2), 0)
end

DragDetector:SetDragStyleFunction(DragCallback)