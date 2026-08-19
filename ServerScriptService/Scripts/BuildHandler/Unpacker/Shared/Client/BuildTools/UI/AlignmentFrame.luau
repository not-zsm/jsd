
local AligmentFrame = {}
AligmentFrame.__index = AligmentFrame;

function AligmentFrame.new(build_tools, color: Color3, tooltip: string, press)
	local self = setmetatable({}, AligmentFrame)
	
	self.build_tools = build_tools;
	
	local Alignment = build_tools.elements.Main.BodyTop.Ribbon.Right.Alignment;
	
	local button = Alignment.Items.Default:Clone();
	button.Image = `rbxassetid://9940310586`;
	button.ImageColor3 = color;
	button.Visible = true;
	button.Name = "CustomButton";
	
	button:AddTag("UI-ButtonClick");
	button:AddTag("UI-ButtonPop");
	button:AddTag("UI-Tooltip");
	button:SetAttribute("Tooltip", tooltip);
	
	button.Parent = Alignment.Items;
	
	button.MouseButton1Click:Connect(function()
		press(self);
	end)
	
	self.button = button;
	
	return button;
end

return AligmentFrame;