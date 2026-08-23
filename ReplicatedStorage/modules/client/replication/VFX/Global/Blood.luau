local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )
local Blood = require( ReplicatedStorage.modules.client.replication.Global.Blood )
local CameraShake = require( ReplicatedStorage.modules.client.replication.Global.CameraShake )

local VFX = {}

function VFX.Explode(RootPart : BasePart)
	if not LocalPlayer:GetAttribute("Blood") then return end
	
	EffectUtility.EmitEffects(script.Explode, RootPart)
	
	for _, Item in ipairs(RootPart.Parent:GetDescendants()) do
		if Item:IsA("BasePart") then
			local random = math.random(1, 4)
			
			Blood.BloodRaysWithoutPreset(RootPart, {
				Face = random == 1 and Enum.NormalId.Top or random == 2 and Enum.NormalId.Left or random == 3 and Enum.NormalId.Right or random == 4 and Enum.NormalId.Bottom, 
				SpreadAngle = Vector2.new(90, 90), 
				Amount = Vector2.new(4, 6), 
				PoolSize = 1.5,
				PoolSizeRandom = Vector2.new(-0.6, 0.6),
			})
			
			EffectUtility.EmitEffects(ReplicatedStorage.modules.effect.assets.Blood.Splash, Item)
			Item.Transparency = 1
			
		elseif Item:IsA("Decal") then
			Item.Transparency = 1
		end
	end
	
	CameraShake(7.5, 100, 0.03, 0.65)
end

function VFX.CutHead(Head : BasePart)
	if not LocalPlayer:GetAttribute("Blood") then return end
	
	EffectUtility.EmitEffects(script.Explode, Head)
	CameraShake(7.5, 100, 0.03, 0.65)
	
	for Index = 1, 40 do
		if (Head ~= nil and Head.Parent ~= nil) then
			Blood.BloodRaysWithoutPreset(Head.Parent.Torso.NeckAttachment, {
				Face = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(360, 50), Amount = Vector2.new(10, 12), PoolSize = 2
			})

			Blood.BloodRaysWithoutPreset(Head, {
				Face = Enum.NormalId.Bottom,
				SpreadAngle = Vector2.new(360, 50), Amount = Vector2.new(10, 12), PoolSize = 2
			})

			task.wait(0.15)
		else
			break
		end
	end
end

return VFX

