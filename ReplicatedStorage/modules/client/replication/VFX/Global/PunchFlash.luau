local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

local FADE = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RANGE = 150

local VFX = {}

--[[
	A neon copy of the limb that threw the punch, welded over it and faded out.

	The moveset says which limb and what colour per punch, so a character
	swinging a weapon on some of its combo can leave those entries out rather
	than glowing an empty hand.
--]]
function VFX.Arm(Character : Model, LimbName : string, Colour : Color3, Duration : number)
	if not (Character and LimbName) then return end

	local Limb = Character:FindFirstChild(LimbName, true)
	if not (Limb and Limb:IsA("BasePart")) then return end

	if Players.LocalPlayer:DistanceFromCharacter(Limb.Position) > RANGE then return end

	Colour = Colour or Color3.new(1, 1, 1)
	Duration = Duration or 0.4

	local Flash = Limb:Clone()

	-- keep the silhouette, drop everything hanging off it
	for _, Child in Flash:GetChildren() do
		if not Child:IsA("DataModelMesh") then
			Child:Destroy()
		end
	end

	Flash.Name = LimbName .. " Flash"
	Flash.CanCollide = false
	Flash.CanQuery = false
	Flash.CanTouch = false
	Flash.Anchored = false
	Flash.Massless = true
	Flash.CastShadow = false
	Flash.Material = Enum.Material.Neon
	Flash.Color = Colour
	Flash.Transparency = 0.8
	Flash.Size = Limb.Size * 1.08
	Flash.CFrame = Limb.CFrame

	EffectUtility.Weld(Flash, Limb)
	Flash.Parent = workspace.Visuals

	task.delay(Duration, function()
		if Flash.Parent then
			TweenService:Create(Flash, FADE, { Transparency = 1 }):Play()
		end
	end)

	Debris:AddItem(Flash, Duration + 0.2)
end

--- The whole body lighting up on a landed hit.
function VFX.Highlight(Character : Model, Colour : Color3, Duration : number)
	if not Character then return end

	Duration = Duration or 0.15

	-- a rapid combo should restart it rather than stack
	local Existing = Character:FindFirstChild("_PunchHighlight")
	if Existing then Existing:Destroy() end

	local Highlight = Instance.new("Highlight")
	Highlight.Name = "_PunchHighlight"
	Highlight.FillColor = Colour or Color3.new(1, 1, 1)
	Highlight.FillTransparency = 0
	Highlight.OutlineTransparency = 1
	Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	Highlight.Parent = Character

	TweenService:Create(Highlight, TweenInfo.new(Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FillTransparency = 1,
	}):Play()

	Debris:AddItem(Highlight, Duration + 0.05)
end

return VFX
