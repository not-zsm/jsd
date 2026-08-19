return function(Model : Model)
	local Outfit = script.Outfit:Clone()
	
	local OutfitFolder = Instance.new("Folder");
	OutfitFolder.Name = Outfit.Name;
	
	for _, Item in ipairs(Outfit:GetDescendants()) do
		if Item:IsA("BasePart") then
			local Weld = Item:FindFirstChild("Weld")

			if Weld then
				local Limb = Model:FindFirstChild(Item.Parent.Name)

				if Limb then
					Weld.Part1 = Limb
				end
			end
			
			Item.Parent = OutfitFolder
		end
	end
	
	OutfitFolder.Parent = Model
	
	return OutfitFolder
end

--return function(Model : Model)
--	local Outfit = script.Outfit:Clone()

--	for _, Item in ipairs(Outfit:GetDescendants()) do
--		if Item:IsA("BasePart") then
--			local NewPiece = Item:Clone()
--			local Weld = NewPiece:FindFirstChild("Weld")

--			if Weld then
--				local Limb = Model:FindFirstChild(Item.Parent.Name)

--				if Limb then
--					Weld.Part1 = Limb
--				end
--			end

--			NewPiece.Parent = Outfit
--		end
--	end

--	Outfit.Parent = Model

--	return Outfit
--end