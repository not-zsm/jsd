local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

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
		SortFn(List, self:GetCFrame().Position)
	end
end

function Box:TranslateAdornee()
	if typeof(self.Adornee) == "Instance" then
		return self.Adornee.CFrame
	end
	
	if typeof(self.Adornee) == "Vector3" then
		return CFrame.new(self.Adornee)
	end
	
	return self.Adornee
end

function Box:GetCFrame()
	return (self:TranslateAdornee() * self.Params.Offset)
end

function Box:GetPosition()
	return (self:TranslateAdornee() * self.Params.Offset).Position
end

function Box:Detect(InRunLoop : boolean)
	if not self:Valid() then return end
	
	local CurrentCF = self:GetCFrame()
	
	if self.Params.Debug then
		if InRunLoop then
			if (self.DebugPart == nil) then
				self.DebugPart = ReplicatedStorage.Effects.Parts.BoxDebug:Clone()
				self.DebugPart.CFrame = CurrentCF
				self.DebugPart.Size = self.Params.Size
				self.DebugPart.Parent = workspace.Visuals
			else
				self.DebugPart.CFrame = self:GetCFrame()
			end
		else
			local Part = ReplicatedStorage.Effects.Parts.BoxDebug:Clone()
			Part.CFrame = CurrentCF
			Part.Size = self.Params.Size
			Part.Parent = workspace.Visuals
			task.delay(0.1, Part.Destroy, Part)
		end
	end
	
	local Overlap = self.Params.OverlapParams or Utility.HitboxParams
	local Bounds = workspace:GetPartBoundsInBox(CurrentCF, self.Params.Size, Overlap)

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

	table.clear(List)
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