
local IncrementerFrame = {}
IncrementerFrame.__index = IncrementerFrame;

function IncrementerFrame.new(build_tools, text: string)
	local button = build_tools.assets.SnappingButton:Clone();
	button.TextLabel.Text = text;
	button.Visible = true;
	button.Name = "CustomButton";
	button.Parent = build_tools.elements.Left.Snapping;
	
	return button;
end

return IncrementerFrame;