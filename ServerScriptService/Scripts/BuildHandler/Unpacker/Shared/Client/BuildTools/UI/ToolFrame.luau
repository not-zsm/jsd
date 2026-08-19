local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Stylus = require( ReplicatedStorage.Packages.Stylus )

local Builds = workspace:WaitForChild("Builds");

local ToolFrame = {};
ToolFrame.__index = ToolFrame;

function ToolFrame.new(build_tools, text: string, icon: string, tooltip: string, callback: any)
	local tool = build_tools.assets.ExtraToolOption:Clone();

	if string.sub(icon, 1, 1) == "/" then
		Stylus:set_sprite_icon(tool.Interact.ImageLabel, string.sub(icon, 2));
	else
		tool.Interact.ImageLabel.Image = icon;
	end
	
	Stylus:set_tooltip(tool.Interact, tooltip);
	
	tool.Name = "CustomButton";
	tool.Interact.TextLabel.Text = text;
	tool.Visible = true;

	tool.Interact.MouseButton1Click:Connect(function()
		callback(tool);
	end);

	tool.Parent = build_tools.elements.Left.Context.Body.ScrollingFrame;

	return tool;
end

table.freeze(ToolFrame);

return ToolFrame;