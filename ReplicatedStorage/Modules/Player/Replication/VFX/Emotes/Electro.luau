local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local VFX = {}
VFX.Effects = {}

function VFX.Add(Model : Model)
	if (Model == nil or Model.Parent == nil) then return end -- shuts up output
	
	local Attachment = script.VFX.Attachment:Clone()
	for _, Effect in pairs(Attachment:GetChildren()) do
		Effect.Enabled = true
	end
	
	Attachment.Parent = Model.Torso
	VFX.Effects[Model] = Attachment
end

function VFX.Remove(Model : Model)
	if (VFX.Effects[Model] == nil) then return end
	
	VFX.Effects[Model]:Destroy()
	VFX.Effects[Model] = nil
end

return VFX
