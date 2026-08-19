local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

function VFX.Slide(RootPart : BasePart)
	local Thread = coroutine.create(function()
		while (RootPart.Parent ~= nil) do
			RockHandler.Rocks("CharaLethalWoundSlide", RootPart)
			Smoke(RootPart, 7.5)
			
			task.wait(0.035)
		end
	end)
	
	coroutine.resume(Thread)
	
	AttributeListener.new(RootPart, "LethalWoundSlide", function()
		if coroutine.status(Thread) == "suspended" then
			coroutine.close(Thread)
		end
	end)
end
	
function VFX.Tackle(RootPart : BasePart)
	local Dist = LocalPlayer:DistanceFromCharacter(RootPart.Position)
	
	if Dist < 20 then
		CameraShake(1, 10, 0.01, 0.4, Vector3.one * 0.4, Vector3.one * 0.85)
	end
	
	if Dist < 80 then
		local Thread = coroutine.create(function()
			while (RootPart.Parent ~= nil) do
				RockHandler.Rocks("CharaLethalWoundSlide", RootPart)
				Smoke(RootPart, 7.5, 2.25)

				task.wait(0.03)
			end
		end)
		
		coroutine.resume(Thread)

		task.delay(0.65, function()
			if coroutine.status(Thread) == "suspended" then
				coroutine.close(Thread)
			end
		end)
	end
	
	EffectUtility.CloneAndEmit(script.Assets.tackle, RootPart)
	
	do
		local Knife : Model = RootPart.Parent:FindFirstChild("Knife")

		if Knife then
			Knife.Handle.BladeAttachment.Trail.Enabled = true

			AttributeListener.new(RootPart, "LethalWoundHit", function()
				Knife.Handle.BladeAttachment.Trail.Enabled = false
			end)
		end
	end
end

function VFX.Stab(RootPart : BasePart, VictimHead : BasePart, Type : number)
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 20 then
		CameraShake(2.5, 25, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.25)
		Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.35)
	end

	Blood.BloodRays("SpitOut", VictimHead.MouthAttachment)
	EffectUtility.CloneAndEmit(script.Assets[Type], RootPart)
end

return VFX