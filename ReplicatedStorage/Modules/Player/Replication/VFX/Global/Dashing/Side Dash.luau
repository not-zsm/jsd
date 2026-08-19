local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local DashRocks = require( ReplicatedStorage.Modules.Player.Replication.Global.DashRocks )
local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local VFX = {}

function VFX.Start(RootPart : BasePart)
	if (LocalPlayer.Character ~= RootPart.Parent) then
		local Replication = AttributeListener.GetReplicationFromSource(RootPart)
		
		local CancelAttribute : RBXScriptConnection = nil
		local RemoveFunc = nil

		CancelAttribute = Replication:GetAttributeChangedSignal("SideDash"):Connect(function()
			if not Replication:GetAttribute("SideDash") and RemoveFunc then
				RemoveFunc()
			end
		end)

		RemoveFunc = DashRocks(RootPart, "Side Dash", 0.325, function()
			if CancelAttribute ~= nil and CancelAttribute.Connected then
				CancelAttribute:Disconnect()
			end
		end)

		if not Replication:GetAttribute("SideDash") and RemoveFunc then
			RemoveFunc()
		end
		
		local Attachment = Instance.new("Attachment")
		Attachment.Name = "SideDashSound"
		Attachment.CFrame = CFrame.new(0, -3, 0)
		Attachment.Parent = RootPart

		local Sound : Sound = script[tostring(math.random(1, 2))]:Clone()
		Sound.Parent = Attachment
		Sound:Play()

		Sound.Ended:Once(function()
			Attachment:Destroy()
		end)
	end
end

return VFX