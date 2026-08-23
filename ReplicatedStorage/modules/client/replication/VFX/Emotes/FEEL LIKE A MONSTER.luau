local replicatedStorage = game:GetService("ReplicatedStorage")

local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local Yuki_FOV = require( replicatedStorage.modules.client.replication.Global.Yuki_FOV )

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )

local VFX = {}

function VFX.MONSTER(Model : Model)
	local Retrieved = AnimationRetriever.new(Model, replicatedStorage.Animations.Emotes["FEEL LIKE A MONSTER"])
	
	if Retrieved then
		Retrieved.Job:Task(task.spawn(function()
			while true do
				Yuki_FOV.Set(45)
				Yuki_FOV.Tween(70, {0.4})
				
				CameraShake(1.5, 20, 0.01, 0.45, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.fromRGB(157, 0, 255), 0.5, 0.3)
				
				task.wait(0.4)
			end
		end))
	end
end

return VFX
