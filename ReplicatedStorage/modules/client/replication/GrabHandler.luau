local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Grabs = setmetatable({}, {__mode = "k"})
local GrabHandler = {}
local XZ = Vector3.new(1, 0, 1)

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )
local Presets = require( script.Presets )

function GrabHandler.Set(Part0 : BasePart, BoundTo : BasePart, Offset : CFrame, PresetName : string)
	if (Part0 == nil or Part0.Parent == nil) or (BoundTo == nil or BoundTo.Parent == nil) then return end
	
	if (Part0 == BoundTo) then
		return -- no self grab
	end
	
	local Preset = PresetName and Presets[PresetName]
	local RenderPriority = Preset and Preset.RenderPriority or Utility.CharacterRenderPriority
	local NoY = false
	
	if Preset then
		NoY = (Preset.NoY == true)
	end

	Grabs[Part0] = {
		Offset = Offset or CFrame.identity,
		BoundTo = BoundTo
	}
	
	local Height = BoundTo.CFrame.Y;

	if NoY then
		local Raycast = workspace:Raycast(BoundTo.Position, Vector3.yAxis * -20, Utility.VisualParams)
		
		if Raycast then
			Height = Raycast.Position.Y
		end
	end
	
	RunService:BindToRenderStep(tostring(Grabs[Part0]), RenderPriority, function()
		if (BoundTo == nil or BoundTo.Parent == nil) then
			return GrabHandler.Remove(Part0)
		end
		
		local GrabData = Grabs[Part0]

		if GrabData and GrabData.BoundTo and GrabData.Offset then
			local Offset = GrabData.Offset
			local CF = GrabData.BoundTo.CFrame
			
			if NoY then
				Part0.CFrame = (CF.Rotation + CF.Position * XZ + Vector3.yAxis * (Height - 2)) * Offset
			else
				Part0.CFrame = CF * Offset
			end
		end
	end)
end

function GrabHandler.SetBound(Part0 : BasePart, NewBound : BasePart)
	if (Part0 == nil or Grabs[Part0] == nil) then return end

	Grabs[Part0].BoundTo = NewBound
end

function GrabHandler.SetOffset(Part0 : BasePart, NewOffset : CFrame)
	if (Part0 == nil or Grabs[Part0] == nil) then return end

	Grabs[Part0].Offset = NewOffset
end

function GrabHandler.Remove(Part0 : BasePart)
	if (Part0 == nil or Grabs[Part0] == nil) then return end
	
	RunService:UnbindFromRenderStep(tostring(Grabs[Part0]))
	table.clear(Grabs[Part0])
	Grabs[Part0] = nil
end

return GrabHandler
