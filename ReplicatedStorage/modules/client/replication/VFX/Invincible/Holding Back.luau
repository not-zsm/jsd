local VFX = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )

local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local SparksThread = {}

function VFX.Windup(RootPart : BasePart)
	EffectUtility.EmitEffects(script.Windup, RootPart)
end

function VFX.Grabbed(RootPart : BasePart)
	EffectUtility.EmitEffects(script.Hit, RootPart)
end

local function Impact(Model : Model, Time : number)
	local ColorCorrection = Instance.new("ColorCorrectionEffect")
	ColorCorrection.Brightness = 1
	ColorCorrection.Parent = Lighting

	if Model then
		local Highlight = Instance.new("Highlight")
		Highlight.FillTransparency = 0
		Highlight.FillColor = Color3.new(1, 0, 0)
		Highlight.OutlineColor = Color3.new(0, 0, 0)
		Highlight.Parent = Model
		task.delay(Time or 0.03, Highlight.Destroy, Highlight)
	end
	
	task.delay(Time or 0.03, ColorCorrection.Destroy, ColorCorrection)
end

function VFX.Hit(RootPart : BasePart, Parameter : Number)
	local BloodEnabled = LocalPlayer:GetAttribute("Blood")

	local Assets
	if BloodEnabled then
		Assets = script.Assets
	else
		Assets = script.NoBloodAssets
	end
	
	EffectUtility.CloneAndEmit(Assets[Parameter], RootPart)
	
	if (LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25) then
		Impact(RootPart.Parent)
	end
	
	if Parameter == "1" then
		if (LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25) then
			CameraShake(7.5, 65, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.5)
		end
		
	elseif Parameter == "2" then
		if (LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25) then
			CameraShake(10, 65, 0.01, 0.3, Vector3.one * 0.8)
		end
		
	elseif Parameter == "3" then
		if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
			CameraShake(10, 65, 0.01, 0.4, Vector3.one * 0.8)
			Vignette(Color3.fromRGB(255, 0, 0), 0.8, 1)
		end
	end
end

function VFX.Teleport(Torso : BasePart)
	EffectUtility.CloneAndEmit(script.TorsoAssets["1"], Torso)
end

function VFX.TeleportSFX(RootPart : BasePart)
	EffectUtility.EmitEffects(script.Slam, RootPart)
end

return VFX
