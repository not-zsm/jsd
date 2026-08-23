local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

type ActiveData = {
	PivotMethod : boolean,
	To : BasePart,
	Offset : CFrame
}

local FakeWeld = {}
local Active : {[BasePart | Model] : ActiveData} = {}

local BulkParts = {}
local BulkCFrames = {}

local function GetCF(Part : (BasePart | Attachment), Offset : CFrame) : CFrame
	return (Part.ClassName == "Attachment" and Part.WorldCFrame or Part.CFrame) * Offset
end

RunService:BindToRenderStep("FakeWelds", Utility.CharacterRenderPriority, function()
	table.clear(BulkParts)
	table.clear(BulkCFrames)

	for Object, Data in Active do
		local To = Data.To

		if (Object == nil or Object.Parent == nil) then continue end
		if (To == nil or To.Parent == nil) then continue end

		local CF = GetCF(To, Data.Offset)

		if Data.PivotMethod then
			Object:PivotTo(CF)
		else
			table.insert(BulkParts, Object)
			table.insert(BulkCFrames, CF)
		end
	end

	workspace:BulkMoveTo(BulkParts, BulkCFrames, Enum.BulkMoveMode.FireCFrameChanged)
end)

function FakeWeld.new(Object : (Model | BasePart), To : BasePart, Offset : CFrame?)
	if (Active[Object] ~= nil) then
		return
	end
	
	Active[Object] = {
		PivotMethod = Object:IsA("Model"),
		To = To,
		Offset = Offset or CFrame.identity
	}

	local Connection : RBXScriptConnection; Connection = Object.AncestryChanged:Connect(function(_, Parent)
		if (Parent == nil) then
			Connection:Disconnect()
			
			if Active[Object] then
				Active[Object] = nil
			end
		end
	end)
end

return FakeWeld
