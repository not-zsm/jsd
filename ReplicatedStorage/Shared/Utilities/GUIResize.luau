local UIS = game:GetService("UserInputService")

local ResizeModule = {}
ResizeModule.__index = ResizeModule

function ResizeModule.new(Gui)
	local self = setmetatable({}, ResizeModule)

	-- GUI References
	self.Gui = Gui
	self.ResizeButton = Gui:FindFirstChild("ResizeButton")
	self.AspectRatioConstraint = Gui:FindFirstChildWhichIsA("UIAspectRatioConstraint")

	if not self.ResizeButton then return end

	-- Resizing Settings
	self.Resizing = false
	self.ScreenSize = workspace.CurrentCamera.ViewportSize
	self.MaxSize = nil
	self.MinSize = nil
	self.StartSize = nil
	self.StartMouse = nil
	self.OriginalAspectRatio = nil

	-- Initialize size
	task.wait()
	
	self:SetSize("Scale")
	self.MaxSize = Vector2.new(self.Gui.Size.X.Scale, self.Gui.Size.Y.Scale)
	self.MinSize = Vector2.new(self.Gui.Size.X.Scale / 4, self.Gui.Size.Y.Scale / 4)

	-- Connect Events
	self.ResizeButton.InputBegan:Connect(function(input) 
		self:StartResizing(input) 
	end)
	
	UIS.InputEnded:Connect(function() 
		self:StopResizing()
	end)
	
	UIS.InputChanged:Connect(function() 
		self:ResizeGUI() 
	end)

	return self
end

function ResizeModule:PropertyExists(Obj, Prop)
	return ({pcall(function() if(typeof(Obj[Prop]) == "Instance") then error() end end)})[1]
end

function ResizeModule:SetSize(Params)
	if self.Gui:IsA("GuiBase2d") and self:PropertyExists(self.Gui, "Size") then
		local ViewportSize

		if self:PropertyExists(self.Gui.Parent, "AbsoluteSize") then
			ViewportSize = self.Gui.Parent.AbsoluteSize
		elseif self.Gui:FindFirstAncestorWhichIsA("GuiObject") and self:PropertyExists(self.Gui:FindFirstAncestorWhichIsA("GuiObject"), "AbsoluteSize") then
			ViewportSize = self.Gui:FindFirstAncestorWhichIsA("GuiObject").AbsoluteSize
		else
			ViewportSize = workspace.CurrentCamera.ViewportSize
		end
		
		local GuiSize = self.Gui.AbsoluteSize
		
		if Params == "Scale" then
			self.Gui.Size = UDim2.new(GuiSize.X / ViewportSize.X, 0, GuiSize.Y / ViewportSize.Y, 0)
		elseif Params == "Offset" then
			self.Gui.Size = UDim2.new(0, GuiSize.X, 0, GuiSize.Y)
		end
	end
end

function ResizeModule:StartResizing(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		self.Resizing = true
		self.StartMouse = UIS:GetMouseLocation()

		if self.AspectRatioConstraint then
			self.AspectRatioConstraint:Destroy()
			self.AspectRatioConstraint = nil
		end

		if not self.MaxSize or self.MaxSize == Vector2.new(0, 0) then
			task.wait(0.05)
			self:SetSize("Scale")
			self.MaxSize = Vector2.new(self.Gui.Size.X.Scale, self.Gui.Size.Y.Scale)
		end

		self.StartSize = self.Gui.Size
		self.OriginalAspectRatio = self.StartSize.X.Scale / self.StartSize.Y.Scale
	end
end

function ResizeModule:StopResizing()
	self.Resizing = false
end

function ResizeModule:ResizeGUI()
	if not self.Resizing then return end

	local CurrentMouse = UIS:GetMouseLocation()
	local Delta = (CurrentMouse - self.StartMouse) / self.ScreenSize

	local NewWidth = math.clamp(self.StartSize.X.Scale + Delta.X, self.MinSize.X, self.MaxSize.X)
	local NewHeight = math.clamp(self.StartSize.Y.Scale + Delta.Y, self.MinSize.Y, self.MaxSize.Y)

	self.Gui.Size = UDim2.new(NewWidth, 0, NewHeight, 0)
end

return ResizeModule