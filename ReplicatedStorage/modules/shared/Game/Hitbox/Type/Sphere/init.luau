local replicatedStorage = game:GetService("ReplicatedStorage")

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local Type = script.Parent
local HitboxInstance = Type.Parent

local Hitbox = require(HitboxInstance)

local Params = require(script.Params)
local Sorting = require(HitboxInstance.Sorting)

local Box = {}
Box.__index = Box

setmetatable(Box, Hitbox)

---------------------------------

function Box:Sort(List)
	local SortFn = Sorting[self.Params.Sorting]

	if (SortFn ~= nil) then
		SortFn(List, self:GetPosition())
	end
end

function Box:TranslateCFrameAdornee()
	if typeof(self.Adornee) == "Instance" then
		return self.Adornee.CFrame
	end

	if typeof(self.Adornee) == "Vector3" then
		return CFrame.new(self.Adornee)
	end

	return self.Adornee
end

function Box:TranslatePositionAdornee()
	if typeof(self.Adornee) == "Instance" or typeof(self.Adornee) == "CFrame" then
		return self.Adornee.Position
	end

	return self.Adornee
end

function Box:GetCFrame()
	return CFrame.new( self:GetPosition() )
end

function Box:GetPosition()
	if self.Params.Offset ~= CFrame.identity then
		return (self:TranslateCFrameAdornee() * self.Params.Offset).Position
	else
		return self:TranslatePositionAdornee()
	end;
end;

function Box:Detect(InRunLoop : boolean)
	if not self:Valid() then return end
	
	local Position : Vector3 = self:GetPosition()
	
	if self.Params.Debug then
		if InRunLoop then
			if (self.DebugPart == nil) then
				self.DebugPart = replicatedStorage.modules.effect.assets.Parts.BallDebug:Clone()
				self.DebugPart.Position = Position
				self.DebugPart.Size = Vector3.one * (self.Params.Size * 2)
				self.DebugPart.Parent = workspace.Visuals
			else
				self.DebugPart.Position = Position
			end
		else
			local Part = replicatedStorage.modules.effect.assets.Parts.BallDebug:Clone()
			Part.Position = Position
			Part.Size = Vector3.one * (self.Params.Size * 2)
			Part.Parent = workspace.Visuals
			task.delay(0.1, Part.Destroy, Part)
		end
	end

	local Bounds = workspace:GetPartBoundsInRadius(Position, self.Params.Size, Utility.HitboxParams)
	local List = {}
	
	for _, Hit in pairs(Bounds) do
		local Model = Hit:FindFirstAncestorOfClass("Model")
		
		if not Model then
			continue
		end

		local Humanoid = self:GetHumanoidFrom(Model)

		if (Humanoid == nil or self:OnIgnoreList(Model)) then
			continue
		end

		table.insert(List, Humanoid)
	end

	if self.Params.TrySorting then
		self:Sort(List)
	end
	
	for _, Item in List do
		self:AddToHit(Item)
	end
end

---------------------------------

local Main = {}
Main.NewParams = Params.new

function Main.new(Adornee, Params)
	local self = Hitbox.Create(Adornee, Params)
	setmetatable(self, Box)
	
	return self
end

return Main