local Tile = {}
local Cached = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeometryService = game:GetService("GeometryService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local TileTweenInfo = TweenInfo.new(1)

-- Function to split the tile
local function splitTile(part : BasePart)
	local size = part.Size
	local position = part.Position
	local orientation = part.Orientation
	local color = part.Color
	local material = part.Material

	-- Direction of split: change to Vector3.new(1, 0, 0) for vertical split
	local splitAxis = Utility.Seed:NextUnitVector()--Vector3.new(0, 1, 0) -- Y-axis split (horizontal)

	-- Create two new parts
	for i = -1, 1, 2 do
		local half = Instance.new("Part")
		half:AddTag("NoCameraOcclusion")
		half.Anchored = false
		half.CanCollide = true
		
		half.Size = Vector3.new(
			size.X * (1 - math.abs(splitAxis.X)),
			size.Y * (1 - math.abs(splitAxis.Y)) + size.Y * splitAxis.Y / 2,
			size.Z * (1 - math.abs(splitAxis.Z))
		)
		
		half.CFrame = part.CFrame * CFrame.new(splitAxis * (size * 0.25) * i)
		half.Color = color
		half.Material = material
	
		half.CollisionGroup = "Rockst"
		half.Parent = workspace.Visuals

		half.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-35, 35), Utility.Seed:NextNumber(55, 65), Utility.Seed:NextNumber(-35, 35))
		half.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15))

		task.delay(7.5, function()
			TweenService:Create(half, TileTweenInfo,
				{Size = Vector3.zero}
			):Play()

			task.delay(TileTweenInfo.Time, half.Destroy, half)
		end)
	end
end

function Tile.new(Object : BasePart)
	if not LocalPlayer:GetAttribute("Tile_Destruction") then return end

	local _, OnScreen = workspace.CurrentCamera:WorldToViewportPoint(Object.Position)

	local Holder = Instance.new("Attachment")
	Holder.WorldPosition = Object.Position
	
	local SFX = script.SFX:Clone()
	SFX.Volume = OnScreen and 0.5 or 0.05
	SFX.Parent = Holder

	Holder.Parent = workspace.Terrain
	SFX:Play()
	
	task.delay(2, Holder.Destroy, Holder)

	--do
	--	if #Cached < 20 then
	--		local Splits = {}

	--		for Count = 1, 2 do
	--			local Split = Instance.fromExisting(Object)
	--			local RandomOrientation = RNG:NextUnitVector() * math.pi
	--			Split.CFrame = Object.CFrame * CFrame.Angles(RandomOrientation.X, RandomOrientation.Y, RandomOrientation.Z)
	--			Split.Size = Vector3.new(128, Object.Size.Y / 2, 128)
	--			table.insert(Splits, Split)
	--		end

	--		local Parts = GeometryService:SubtractAsync(Object, Splits, {SplitApart = true})

	--		for _, Split in Splits do
	--			Split:Destroy()
	--		end

	--		table.insert(Cached, {Object.CFrame, Parts})
	--	end
	--end
	
	--local Parts = {}
	
	--local Choice = math.random(#Cached)
	--local Info = Cached[Choice] 

	--if Info then
	--	local Coordinate: CFrame = Info[1];
	--	local CacheParts: {BasePart} = Info[2];

	--	for _, Part in CacheParts do
	--		local Clone = Part:Clone();
	--		Instance.new("Highlight", Clone)
	--		Clone.CFrame = Object.CFrame
	--		Clone.Parent = workspace.Visuals
			
	--		table.insert(Parts, Clone)
	--	end
	--end
	
	if not LocalPlayer:GetAttribute("Tile_Split_Geometry") or not OnScreen then
		splitTile(Object)
	else
		local Splits = {}

		for Count = 1, 2 do
			local Split = Instance.fromExisting(Object)
			local RandomOrientation = Utility.Seed:NextUnitVector() * math.pi
			Split.CFrame = Object.CFrame * CFrame.Angles(RandomOrientation.X, RandomOrientation.Y, RandomOrientation.Z)
			Split.Size = Vector3.new(128, Object.Size.Y / 2, 128)
			table.insert(Splits, Split)
		end

		local Parts = GeometryService:SubtractAsync(Object, Splits, {SplitApart = true})

		for _, Split in Splits do
			Split:Destroy()
		end

		for _, TilePiece : BasePart in Parts do
			TilePiece.Anchored = false
			TilePiece.CanCollide = true
			TilePiece:AddTag("NoCameraOcclusion")
			TilePiece.CollisionGroup = "Rockst"
			TilePiece.Parent = workspace.Visuals

			TilePiece.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-35, 35), Utility.Seed:NextNumber(55, 65), Utility.Seed:NextNumber(-35, 35))
			TilePiece.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15))

			task.delay(7.5, function()
				TweenService:Create(TilePiece, TileTweenInfo,
					{Size = Vector3.zero}
				):Play()

				task.delay(TileTweenInfo.Time, TilePiece.Destroy, TilePiece)
			end)
		end
	end
end

--function Tile.new(Object : BasePart, OnScreen : boolean)
--	local RNG = Random.new()
--	local Pos = Object.Position

--	local Splits = {}

--	for Count = 1, 2 do
--		local Split = Instance.fromExisting(Object)
--		local RandomOrientation = RNG:NextUnitVector() * math.pi
--		Split.CFrame = Object.CFrame * CFrame.Angles(RandomOrientation.X, RandomOrientation.Y, RandomOrientation.Z)
--		Split.Size = Vector3.new(128, Object.Size.Y / 2, 128)
--		table.insert(Splits, Split)
--	end

--	local Parts = GeometryService:SubtractAsync(Object, Splits, {SplitApart = true})

--	for _, Split in Splits do
--		Split:Destroy()
--	end

--	local _, OnScreen = workspace.CurrentCamera:WorldToViewportPoint(Object.Position)

--	if OnScreen then
--		local Holder = Instance.new("Attachment")
--		local SFX = script.SFX:Clone()
--		SFX.Volume = OnScreen and 0.5 or 0.05

--		Holder.WorldPosition = Pos
--		SFX.Parent = Holder

--		Holder.Parent = workspace.Terrain
--		SFX:Play()
--	end


--	for _, TilePiece : BasePart in Parts do
--		TilePiece.Anchored = false
--		TilePiece.CanCollide = true
--		TilePiece:AddTag("NoCameraOcclusion")
--		TilePiece.CollisionGroup = "Rockst"
--		TilePiece.Parent = workspace.Visuals

--		TilePiece.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-35, 35), Utility.Seed:NextNumber(55, 65), Utility.Seed:NextNumber(-35, 35))
--		TilePiece.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15))

--		task.delay(7.5, function()
--			TweenService:Create(TilePiece, TileTweenInfo,
--				{Size = Vector3.zero}
--			):Play()

--			task.delay(TileTweenInfo.Time, TilePiece.Destroy, TilePiece)
--		end)
--	end
--end

return Tile
