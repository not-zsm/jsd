local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local LocalPlayer = Players.LocalPlayer
local Slice = nil

function VFX.Stab(VictimRootPart : BasePart)
	if LocalPlayer:DistanceFromCharacter(VictimRootPart.Position) < 20 then
		CameraShake(2.5, 25, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.25)
		Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.35)
	end
	
	if (VictimRootPart ~= nil and VictimRootPart.Parent ~= nil) then
		Blood.BloodRays("SpitOut", VictimRootPart.Parent.Head.MouthAttachment)
	end
	
	EffectUtility.CloneAndEmit(script.Assets.stab, VictimRootPart)
end

function VFX.StabToLeft(VictimRootPart : BasePart)
	if LocalPlayer:DistanceFromCharacter(VictimRootPart.Position) < 20 then
		CameraShake(2.5, 25, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.25)
		Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.35)
	end

	Blood.BloodRays("SpitOut", VictimRootPart.Parent.Head.MouthAttachment)
	EffectUtility.CloneAndEmit(script.Assets.stabtoleft, VictimRootPart)
end

function VFX.ThrowLeft(VictimRootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.throwleft, VictimRootPart)
end

function VFX.ThrowBack(VictimRootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.throwback, VictimRootPart)
end

function VFX.Slice(VictimRootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.slice, VictimRootPart)
end

--local Slices = {}

function VFX.Slicing(VictimRootPart : BasePart, Enable : boolean)
	if Enable then
		local Slicing = script.Assets.slicing:Clone()
		Slicing.Parent = VictimRootPart
		EffectUtility.Toggle(Slicing, true)
		
		local Distance = LocalPlayer:DistanceFromCharacter(VictimRootPart.Position)

		Slice = {
			VFX = Slicing,
			Shake = Distance <= 25 and CameraShake(1.75, 17.5, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.5) or nil,
			Loop = coroutine.create(function()
				if (Distance > 50) then 
					return
				end

				while (VictimRootPart.Parent ~= nil) do
					if LocalPlayer:DistanceFromCharacter(VictimRootPart.Position) < 20 then
						Vignette(Color3.fromRGB(255, 0, 0), 0.75, 0.075)
					end

					Blood.BloodRays("SpitOut", VictimRootPart.Parent.Head.MouthAttachment)
					task.wait(0.05)
				end
			end)
		}

		coroutine.resume(Slice.Loop)
	else
		VFX.StopSlicing(VictimRootPart)
	end
end

function VFX.StopSlicing(VictimRootPart : BasePart)
	if Slice then
		if coroutine.status(Slice.Loop) == "suspended" then
			coroutine.close(Slice.Loop)
		end
		
		if Slice.Shake then
			Slice.Shake:StartFadeOut(0.1)
		end
		
		local Effect = Slice.VFX
		EffectUtility.Toggle(Effect, false)
		task.delay(1, Effect.Destroy, Effect)
		
		Slice = nil
	end
end

function VFX.Sliced(VictimRootPart : BasePart)
	if LocalPlayer:DistanceFromCharacter(VictimRootPart.Position) < 20 then
		CameraShake(2.5, 25, 0.01, 0.5, Vector3.one * 0.8, Vector3.one * 0.25)
		Vignette(Color3.fromRGB(255, 0, 0), 0.15, 0.35)
	end

	Blood.BloodRays("BigSpitOut", VictimRootPart.Parent.Head.MouthAttachment)
	EffectUtility.CloneAndEmit(script.Assets.sliced, VictimRootPart)
end

return VFX