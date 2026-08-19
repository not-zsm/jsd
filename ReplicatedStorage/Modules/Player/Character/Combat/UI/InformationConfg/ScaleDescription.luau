local ScaleDescription = {}

function ScaleDescription.ScaleTextLabel(textLabel)
	local resolution = workspace.CurrentCamera.ViewportSize

	local screenResolution = resolution
	local screenWidth = screenResolution.X
	local screenHeight = screenResolution.Y

	-- Calculate the text size based on the resolution
	local textSize = (screenWidth / 1920) * 25

	-- Ensure the text size is within a reasonable range
	textSize = math.max(textSize, 17)
	textSize = math.min(textSize, 40)

	-- Set the text size
	textLabel.TextSize = textSize
end

return ScaleDescription
