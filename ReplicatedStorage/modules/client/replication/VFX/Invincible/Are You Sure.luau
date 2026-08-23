local VFX = {}

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CameraShake = require( ReplicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.modules.client.replication.Global.Vignette )

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )

local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )
local Job = require( ReplicatedStorage.modules.shared.Utilities.Job )

local SparksThread = {}

function VFX.Shockwave(RootPart : BasePart)
	local Assets
	local BloodEnabled = LocalPlayer:GetAttribute("Blood")
	if BloodEnabled then
		Assets = script.Assets
	else
		Assets = script.NoBloodAssets
	end
	
	local Distance = RootPart and LocalPlayer:DistanceFromCharacter(RootPart.Position) or 0
	
	if Distance < 75 then
		EffectUtility.CloneAndEmit(Assets.uppercut, RootPart)
		EffectUtility.EmitEffects(script.Shockwave, RootPart)
	end
	
	if Distance < 20 then
		CameraShake(7.5, 45, 0.01, 0.2, Vector3.one * 0.8)
	end
end

function VFX.Hit(RootPart : BasePart, VictimRootPart : BasePart)
	local Distance = RootPart and LocalPlayer:DistanceFromCharacter(RootPart.Position) or 0
	
	local BloodEnabled = LocalPlayer:GetAttribute("Blood")
	
	local Assets
	if BloodEnabled then
		Assets = script.Assets
	else
		Assets = script.NoBloodAssets
	end
	
	if Distance < 75 then
		if Assets.Blood then
			EffectUtility.CloneAndEmit(Assets.Blood, RootPart)
		end
		EffectUtility.EmitEffects(script.Hit, RootPart)
	end
	
	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or LocalPlayer == Players:GetPlayerFromCharacter(VictimRootPart.Parent) then
		local ColorCorrection = Instance.new("ColorCorrectionEffect")
		ColorCorrection.Brightness = 1
		ColorCorrection.Parent = Lighting

		local Highlight = Instance.new("Highlight")
		Highlight.FillTransparency = 0
		Highlight.FillColor = Color3.new(1, 0, 0)
		Highlight.OutlineColor = Color3.new(0, 0, 0)

		if RootPart.Parent then
			Highlight.Parent = RootPart.Parent
		end

		task.delay(0.03, function()
			Highlight:Destroy()
			ColorCorrection:Destroy()
		end)
	end
end

return VFX
