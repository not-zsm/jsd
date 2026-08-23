local Destruction = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeometryService = game:GetService("GeometryService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )
local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )

local Tile = require( script.Tile )
Destruction.Tile = Tile.new

function Destruction.Rock(Object : Model | BasePart)
	local function RockFly(Rock : BasePart)
		if Rock.Size.Y >= 5 then
			EffectUtility.EmitEffects(script.Rock, Rock)
		else
			EffectUtility.EmitEffects(script.SmallRock, Rock)
		end

		Rock.Anchored = false
		Rock.CanCollide = false
		Rock.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-35, 35), Utility.Seed:NextNumber(55, 65), Utility.Seed:NextNumber(-35, 35))
		Rock.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15))
	end
	
	if Object:IsA("BasePart") then
		RockFly(Object)
	else
		for _, Rock in ipairs(Object:GetChildren()) do
			if Rock:IsA("BasePart") then
				RockFly(Rock)
			end
		end
	end
end

function Destruction.Bush(Model : Model)
	local SFX = Instance.new("Attachment")
	SFX.WorldCFrame = Model:GetPivot()
	SFX.Parent = workspace.Terrain

	script.Bush.SFX:Clone().Parent = SFX
	EffectUtility.Emit(SFX)

	for _, Object in ipairs(Model:GetChildren()) do
		if Object:IsA("BasePart") then
			Object.Anchored = false
			Object.CanCollide = false
			Object.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-35, 35), Utility.Seed:NextNumber(55, 65), Utility.Seed:NextNumber(-35, 35))
			Object.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15))
		end
	end
end

function Destruction.Crate(BasePart : BasePart)
	EffectUtility.EmitEffects(script.Wood, BasePart)
	
	BasePart.Anchored = false
	BasePart.CanCollide = false
	BasePart.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-25, 25), Utility.Seed:NextNumber(27.5, 37.5), Utility.Seed:NextNumber(-25, 25))
	BasePart.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-10, 10), Utility.Seed:NextNumber(-10, 10), Utility.Seed:NextNumber(-10, 10))
end

function Destruction.Tree(Model : Model)
	for _, Object in ipairs(Model:GetChildren()) do
		if Object:IsA("BasePart") then
			Object.Anchored = false
			Object.CanCollide = false
			
			if Object.Name == "Leaf" then
				EffectUtility.EmitEffects(script.Bush, Object)
				
			elseif Object.Name == "Wood" then
				EffectUtility.EmitEffects(script.Wood, Object)
			end
			
			Object.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-35, 35), Utility.Seed:NextNumber(55, 65), Utility.Seed:NextNumber(-35, 35))
			Object.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15))
		end
	end
end

function Destruction.Lamp(Model : Model)
	local METALCLANK = Instance.new("Attachment")
	METALCLANK.WorldCFrame = Model:GetPivot()
	METALCLANK.Parent = workspace.Terrain
	
	script.Lamp.SFX:Clone().Parent = METALCLANK
	
	EffectUtility.Emit(METALCLANK)
	
	for _, Object in ipairs(Model:GetDescendants()) do
		if Object:IsA("BasePart") then
			local Light = Object:FindFirstChild("SurfaceLight")
			
			if Light then
				Object.Color = Color3.new()
				Light.Enabled = false
			end
			
			Object.Anchored = false
			Object.CanCollide = false
			Object.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-35, 35), Utility.Seed:NextNumber(55, 65), Utility.Seed:NextNumber(-35, 35))
			Object.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15))
		end
	end
end

function Destruction.Pillar(Model : Model)
	local Pivot =  Model:GetPivot()
	
	local METALCLANK = Instance.new("Attachment")
	METALCLANK.WorldCFrame = Pivot
	METALCLANK.Parent = workspace.Terrain

	script.Lamp.SFX:Clone().Parent = METALCLANK
	EffectUtility.Emit(METALCLANK)

	for _, Object in ipairs(Model:GetDescendants()) do
		if Object:IsA("BasePart") then
			Object.Anchored = false
			Object.CanCollide = false
			Object.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-35, 35), Utility.Seed:NextNumber(55, 65), Utility.Seed:NextNumber(-35, 35))
			Object.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15))
		end
	end
	
	EffectUtility.RaycastCraterSmoke("Big", Pivot.Position, Vector3.yAxis * -20)
end

function Destruction.Trashcan(Model : Model)
	local METALCLANK = Instance.new("Attachment")
	METALCLANK.WorldPosition = Model:GetPivot().Position
	script.TrashCan.SFX:Clone().Parent = METALCLANK
	
	METALCLANK.Parent = workspace.Terrain
	EffectUtility.Emit(METALCLANK)

	Model.Main.Anchored = false
	Model.Main.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-35, 35), Utility.Seed:NextNumber(55, 65), Utility.Seed:NextNumber(-35, 35))
	Model.Main.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15))
end

function Destruction.Fence(Model : Model)
	local Holder = Instance.new("Attachment")
	Holder.WorldCFrame = Model:GetPivot()
	Holder.Parent = workspace.Terrain

	script.Fence.SFX:Clone().Parent = Holder

	EffectUtility.Emit(Holder)

	for _, Object in ipairs(Model:GetDescendants()) do
		if Object:IsA("BasePart") then
			Object.Anchored = false
			Object.CanCollide = false
			Object.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-35, 35), Utility.Seed:NextNumber(55, 65), Utility.Seed:NextNumber(-35, 35))
			Object.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15))
		end
	end
end

function Destruction.Station(Model : Model)
	for _, Object in ipairs(Model:GetDescendants()) do
		if Object:IsA("BasePart") then
			Object.Anchored = false
			Object.CanCollide = false
			Object.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-50, 50), Utility.Seed:NextNumber(75, 100), Utility.Seed:NextNumber(-50, 50))
			Object.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-7, 7), Utility.Seed:NextNumber(-7, 7), Utility.Seed:NextNumber(-7, 7))
		end
	end
end

function Destruction.Glass(Object : BasePart)
	local RNG = Random.new()
	local Splits = {}

	for Count = 1, 4 do
		local Split = Instance.fromExisting(Object)
		local RandomOrientation = RNG:NextUnitVector() * math.pi
		Split.CFrame = Object.CFrame * CFrame.Angles(RandomOrientation.X, RandomOrientation.Y, RandomOrientation.Z)
		Split.Size = Vector3.new(128, Object.Size.Y / 2, 128)
		table.insert(Splits, Split)
	end

	local Pos = Object.Position
	local Parts = GeometryService:SubtractAsync(Object, Splits, {SplitApart = true})

	for _, Split in Splits do
		Split:Destroy()
	end

	EffectUtility.RaycastCraterSmoke("Normal", Pos + Vector3.yAxis * 1.25, Vector3.yAxis * -5)

	local Holder = Instance.new("Attachment")
	Holder.WorldPosition = Pos
	Holder.Parent = workspace.Terrain
	script.Glass.SFX:Clone().Parent = Holder
	EffectUtility.Emit(Holder)

	for _, TilePiece : BasePart in Parts do
		TilePiece.Anchored = false
		TilePiece.CanCollide = true
		TilePiece.CollisionGroup = "Rockst"
		TilePiece.Parent = workspace.Visuals

		TilePiece.AssemblyLinearVelocity = Vector3.new(Utility.Seed:NextNumber(-35, 35), Utility.Seed:NextNumber(55, 65), Utility.Seed:NextNumber(-35, 35))
		TilePiece.AssemblyAngularVelocity = Vector3.new(Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15), Utility.Seed:NextNumber(-15, 15))

		task.delay(7.5, function()
			TweenService:Create(TilePiece, TweenInfo.new(1),
				{Size = Vector3.zero}
			):Play()

			task.delay(1, TilePiece.Destroy, TilePiece)
		end)
	end
end

return Destruction
