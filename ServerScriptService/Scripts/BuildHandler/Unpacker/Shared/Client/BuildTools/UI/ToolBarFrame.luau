
local ToolBarFrame = {};
ToolBarFrame.__index = ToolBarFrame;

function ToolBarFrame.new(build_tools, text: string, icon: string)
	local button = build_tools.assets.RibbonToolOption:Clone();
	button.Interact.TextLabel.Text = text;
	button.Interact.ImageLabel.Image = icon;
	button.Visible = true;
	button.Name = "CustomButton";
	button.Parent = build_tools.elements.Left.Tools.Body;
	
	return button;
end

return ToolBarFrame