local ContentProvider = game:GetService("ContentProvider")
local display = script.Parent:FindFirstChild("Display")  -- Frame where images appear
local collection = script.Parent:FindFirstChild("Collection")  -- Frame containing all ImageLabels
local images = collection:GetChildren()  -- Get all images from Collection
local tweenService = game:GetService("TweenService")

local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)  -- 1-second transition
local index = 1  -- Start with first image

-- Create a clone of the image for display
local function createClone(imageLabel)
	local clone = imageLabel:Clone()
	clone.Parent = display
	clone.Size = UDim2.new(1, 0, 1, 0)
	clone.Position = UDim2.new(0, 0, 0, 0)  -- Start at the center
	clone.Visible = true
	return clone
end

-- Initialize the first image
local currentClone = createClone(images[index])

-- Main slideshow function
local function startSlideshow()
	while true do
		wait(5)  -- Wait before transition

		local nextIndex = (index % #images) + 1
		local nextClone = createClone(images[nextIndex])
		nextClone.Position = UDim2.new(-1, 0, 0, 0)  -- Start off-screen to the left

		-- Tween animations
		local tweenOut = tweenService:Create(currentClone, tweenInfo, {Position = UDim2.new(1, 0, 0, 0)})  -- Move right
		local tweenIn = tweenService:Create(nextClone, tweenInfo, {Position = UDim2.new(0, 0, 0, 0)})  -- Move to center

		tweenOut:Play()
		tweenIn:Play()
		
		-- Change Creator Label
		display.Creator.Text = `@{nextClone.Name}`
		
		tweenIn.Completed:Wait()  -- Wait until animation completes

		currentClone:Destroy()  -- Remove the old image
		currentClone = nextClone  -- Update the current image
		index = nextIndex  -- Move to the next image
	end
end

startSlideshow()

ContentProvider:PreloadAsync(collection:GetChildren())
