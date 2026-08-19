
local ChangeHistoryFrame = {}
ChangeHistoryFrame.__index = ChangeHistoryFrame;

function ChangeHistoryFrame.new(build_tools, image: string, tooltip: string, press)
	local self = setmetatable({}, ChangeHistoryFrame)
	
	self.build_tools = build_tools;
	
	local MainUI = build_tools.ui.Main;
	local ChangeHistory = MainUI.BodyTop.Ribbon.Left.History;
	
	local button = ChangeHistory.Items.Default:Clone();
	button.Image = image;
	button.Visible = true;
	button.Name = "CustomButton";
	
	button:AddTag("UI-ButtonClick");
	button:AddTag("UI-ButtonPop");
	button:AddTag("UI-Tooltip");
	button:SetAttribute("Tooltip", tooltip);
	
	button.Parent = ChangeHistory.Items;
	
	button.MouseButton1Click:Connect(function()
		press(self);
	end)
	
	self.button = button;
	
	return button;
end

return ChangeHistoryFrame;