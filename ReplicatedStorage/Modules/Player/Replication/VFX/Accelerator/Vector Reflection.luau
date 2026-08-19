local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local DojyanMeshEmit = require( ReplicatedStorage.Modules.Player.Replication.Global.DojyanMeshEmit )

local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

return {
	Start = function(Model : Model)
		local Torso : BasePart = Model:FindFirstChild("Torso")
		
		if LocalPlayer:DistanceFromCharacter(Torso.Position) <= 10 then
			Vignette(Color3.fromRGB(128, 17, 255), 0.75, 0.15)
			CameraShake(1, 20, 0.01, 0.1, Vector3.one * 0.8, Vector3.one * 0.3)
		end
		
		local Aura = script.Aura:Clone()
		EffectUtility.Weld(Aura, Torso)
		Aura.Parent = Model

		EffectUtility.Emit(Aura, true)
		
		AttributeListener.new(Model, "VectorReflecting", function()
			EffectUtility.Toggle(Aura, false)
			task.delay(2, Aura.Destroy, Aura)
		end)
	end,
	
	Reflect = function(Model : Model)
		local CF : CFrame = Model.PrimaryPart.CFrame
		
		local Reflect = script.Reflect:Clone()
		local Meshes = script.Mesh:Clone()
		
		local RequiredHighlight = Instance.new("Highlight")
		RequiredHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
		RequiredHighlight.FillTransparency = 1
		RequiredHighlight.OutlineTransparency = 1
		RequiredHighlight.Enabled = false
		RequiredHighlight.Parent = Meshes.DistorionSphere.Start
		
		Reflect:PivotTo(CF)
		Meshes:PivotTo(CF)
	
		for _, Mesh in ipairs(Meshes:GetChildren()) do
			if Mesh:IsA("Model") then
				DojyanMeshEmit(Mesh, true)
			end
		end
		
		Reflect.Parent = workspace.Visuals
		EffectUtility.Emit(Reflect)

		task.delay(1, Meshes.Destroy, Meshes)
		
		if LocalPlayer:DistanceFromCharacter(CF.Position) <= 30 then
			Vignette(Color3.fromRGB(128, 17, 255), 0.5, 0.2)
			CameraShake(2, 20, 0.01, 0.5, Vector3.one * 0.8, Vector3.one * 0.5)
		end
	end,
}