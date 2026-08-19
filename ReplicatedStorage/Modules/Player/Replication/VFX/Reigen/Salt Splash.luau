local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local Splashes = {}

function VFX.Shine(Arm : BasePart)
	local Effect = script.shine:Clone()
	Effect.Parent = workspace.Visuals
	EffectUtility.Weld(Effect, Arm, CFrame.new(0, 0.668, 0))
	EffectUtility.Emit(Effect)
end

function VFX.Splash(RootPart : BasePart, Value : boolean)
	if Value then
		if (Splashes[RootPart] ~= nil) then return end
		
		local Splash = script.splash:Clone()
		Splash.Parent = RootPart
		EffectUtility.Weld(Splash, RootPart)
		EffectUtility.Toggle(Splash, true)
		
		local Shake
		if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
			Shake = CameraShake(1.25, 10, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.25)
		end
		
		Splashes[RootPart] = function()
			Splashes[RootPart] = nil
			
			if Shake then
				Shake:StartFadeOut(0.05)
			end
			
			EffectUtility.Toggle(Splash, false)
			task.delay(2, Splash.Destroy, Splash)
		end
		
		if (LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 15) then
			task.spawn(function()
				while (Splashes[RootPart] ~= nil) do
					Vignette(Color3.new(1, 1, 1), 0.75, 0.1)
					task.wait(0.075)
				end
			end)
		end
	else
		if (Splashes[RootPart] ~= nil) then
			Splashes[RootPart]()
		end
	end
end

function VFX.Hit(VictimRootPart : BasePart)
	if LocalPlayer:DistanceFromCharacter(VictimRootPart.Position) <= 50 then
		EffectUtility.EmitEffects(script.Hit, VictimRootPart)
	end
end

return VFX