local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local SparksThread = {}

function VFX.Sparks(RootPart : BasePart, Parameter : string)
	local Sword : Model = RootPart.Parent:FindFirstChild("Mimicry")
	if (Sword == nil) then return end

	if Parameter == "true" then
		Sword.Blade.Attachment1.Trail.Enabled = true

		task.delay(0.75, function()
			Sword.Blade.Attachment1.Trail.Enabled = false
		end)
		
		if (LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) and SparksThread[RootPart]  == nil) then
			SparksThread[RootPart] = coroutine.create(function()
				for Index = 1, 10 do
					CameraShake(0.25, 5.75, 0.01, 0.8, Vector3.one * 0.8)
					Vignette(Color3.fromRGB(255, 219, 148), 0.8, 0.075)

					task.wait(0.05)
				end
			end)
			
			coroutine.resume(SparksThread[RootPart])
		end
		
		EffectUtility.Toggle(Sword.Blade.sparks, true)
	else
		EffectUtility.Toggle(Sword.Blade.sparks, false)
	end
end

function VFX.Slash(RootPart : BasePart)
	EffectUtility.CloneAndEmit(script.Assets.slash, RootPart)
end

function VFX.Ground(RootPart : BasePart)
	local RaycastResult = workspace:Raycast(RootPart.Position, Vector3.yAxis * -30, Utility.VisualParams)

	if RaycastResult then
		local GroundClone = script.Assets.ground:Clone()
		GroundClone.WorldCFrame = RootPart.CFrame * CFrame.new(0, -RaycastResult.Distance + 0.05, -6.599)
		GroundClone.Parent = workspace.Terrain
		EffectUtility.Emit(GroundClone)
		
		EffectUtility.CloneAndEmit(script.Assets.up, RootPart)
	end
	
	if SparksThread[RootPart] then
		coroutine.close(SparksThread[RootPart])
		SparksThread[RootPart] = nil
	end

	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
		Vignette(Color3.fromRGB(255, 0, 0), 0.5, 1)
	end
	
	if (LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25) then
		CameraShake(6.5, 50, 0.02, 0.3, Vector3.one * 0.8)
	end
end

return VFX
