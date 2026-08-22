local function AttachAccessoryManually(Accessory: Accessory, TargetCharacter: Model)
	local Handle = Accessory:FindFirstChild("Handle")
	if not Handle then return end

	local AttachmentInHandle = Handle:FindFirstChildOfClass("Attachment")
	if not AttachmentInHandle then return end

	local TargetAttachment
	for _, Part in ipairs(TargetCharacter:GetDescendants()) do
		local A = Part:FindFirstChild(AttachmentInHandle.Name)
		if A and A:IsA("Attachment") then
			TargetAttachment = A
			break
		end
	end

	if TargetAttachment then
		-- Align handle manually
		local WorldCFrame = TargetAttachment.WorldCFrame * AttachmentInHandle.CFrame:Inverse()
		Handle.CFrame = WorldCFrame
	end

	-- Parent the accessory to the character manually
	Accessory.Parent = TargetCharacter
end


return {
	CopyCharacterAppearence = function(SourceCharacter: Model, Viewport : ViewportFrame)
		-- Clean up existing visual elements
		for _, Object in pairs(Viewport:GetChildren()) do
			if Object:IsA("Model") then
				Object:Destroy()
			end
		end
		
		-- Check for CustomViewPort
		local CustomRig = nil
		for _, CustomCharacter in pairs(script.CustomViewports:GetChildren()) do
			if CustomCharacter.Name == SourceCharacter.Name then
				CustomRig = CustomCharacter
				break
			end
		end
		
		if CustomRig then
			CustomRig = CustomRig:Clone()
			CustomRig.Parent = Viewport
			return
		else
			local TargetCharacter = script:FindFirstChild("R6"):Clone()
			TargetCharacter.Parent = Viewport

			local SourceHead = SourceCharacter:FindFirstChild("Head")
			local TargetHead = TargetCharacter:FindFirstChild("Head")

			local Humanoid = TargetCharacter:FindFirstChildOfClass("Humanoid")

			-- Copy Accessories
			for _, Accessory in ipairs(SourceCharacter:GetChildren()) do
				if Accessory:IsA("Accessory") then
					local Cloned = Accessory:Clone()
					AttachAccessoryManually(Cloned, TargetCharacter)
				end
			end

			-- Copy Clothing
			local Shirt = SourceCharacter:FindFirstChildOfClass("Shirt")
			if Shirt then
				local ClonedShirt = Shirt:Clone()
				ClonedShirt.Parent = TargetCharacter
			end

			local Pants = SourceCharacter:FindFirstChildOfClass("Pants")
			if Pants then
				local ClonedPants = Pants:Clone()
				ClonedPants.Parent = TargetCharacter
			end

			-- Copy Body Colors
			local BodyColors = SourceCharacter:FindFirstChildOfClass("BodyColors")
			if BodyColors then
				local ClonedColors = BodyColors:Clone()
				ClonedColors.Parent = TargetCharacter
			end

			-- Copy CharacterMeshes (mostly for R6 characters)
			for _, CharMesh in ipairs(SourceCharacter:GetChildren()) do
				if CharMesh:IsA("CharacterMesh") then
					local ClonedMesh = CharMesh:Clone()
					ClonedMesh.Parent = TargetCharacter
				end
			end

			if SourceHead and TargetHead then
				local Face = SourceHead:FindFirstChild("face")
				if Face and Face:IsA("Decal") then
					local ClonedFace = Face:Clone()
					ClonedFace.Parent = TargetHead
				end

				local Mesh = SourceHead:FindFirstChild("Mesh")
				local ClonedMesh = Mesh:Clone()
				ClonedMesh.Parent = TargetHead
			end
		end
	end,
}