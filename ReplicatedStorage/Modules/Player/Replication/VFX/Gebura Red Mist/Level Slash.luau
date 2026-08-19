local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local BloodVFX = require( ReplicatedStorage.Modules.Player.Replication.VFX.Global.Blood )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local AuraThread = {}
local Auras = {}

function VFX.Aura(RootPart : BasePart, Parameter : string)
	if Parameter == "true" then
		if (LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) and AuraThread[RootPart]  == nil) then
			AuraThread[RootPart] = coroutine.create(function()
				for Index = 1, 10 do
					CameraShake(2, 15, 0.01, 0.075, Vector3.one * 0.8)
					Vignette(Color3.fromRGB(255, 0, 0), 0.7, 0.09)

					task.wait(0.05)
				end
			end)

			coroutine.resume(AuraThread[RootPart])
		end
		
		local NewAura = script.Assets.aura:Clone()
		NewAura.Parent = RootPart
		EffectUtility.Toggle(NewAura, true)
		
		Auras[RootPart] = NewAura
	else
		if Auras[RootPart] then
			EffectUtility.Toggle(Auras[RootPart], false)
			task.delay(1, Auras[RootPart].Destroy, Auras[RootPart])
			Auras[RootPart] = nil
		end
	end
end

function VFX.Swing(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.swing, RootPart)
end

function VFX.Hit(RootPart : BasePart)
	-- Close Previous Aura Thread
	if AuraThread[RootPart] then
		coroutine.close(AuraThread[RootPart])
		AuraThread[RootPart] = nil
	end
	
	EffectUtility.CloneAndEmit(script.Assets.hit, RootPart)
	
	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
		Vignette(Color3.fromRGB(255, 0, 0), 0.6, 1)
	end
	
	if (LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25) then
		CameraShake(5, 35, 0.01, 0.4, Vector3.one * 0.8)
	end
end

function VFX.Finisher(Head : BasePart)
	BloodVFX.CutHead(Head)
end

return VFX
