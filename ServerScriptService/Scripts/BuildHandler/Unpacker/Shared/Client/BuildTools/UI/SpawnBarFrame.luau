
local SpawnBarFrame = {}
SpawnBarFrame.__index = SpawnBarFrame;

function SpawnBarFrame.new(build_tools, text: string, icon: string)
	local button = build_tools.assets.PrimitiveInsertOption:Clone();
	button.Interact.TextLabel.Text = text;
	button.Interact.ImageLabel.Image = icon;
	button.Visible = true;
	button.Name = "CustomButton";
	button.Parent = build_tools.elements.Left.Spawn.Body;
	
	return button;
end

return SpawnBarFrame;