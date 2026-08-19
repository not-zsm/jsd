local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )


local function get_seconds_from_beat(BPM : number)
	return (60 / BPM)
end

function VFX.Pose(Torso : BasePart)
	local Effect = script.Aura:Clone()
	EffectUtility.Weld(Effect, Torso)
	Effect.Parent = workspace.Visuals
	
	local Theme = script.Theme:Clone()
	Theme.Parent = Torso
	Theme:Play()
	
	local oh_im_threading_it_oh_so_good = nil
	local looping = true
	
	oh_im_threading_it_oh_so_good = coroutine.create(function()
		task.wait(8.75) -- beat drop

		local BPM = get_seconds_from_beat(262)

		while looping do
			if LocalPlayer:DistanceFromCharacter(Torso.Position) <= 25 then
				Vignette(Color3.fromRGB(255, 0, 0), 0.85, BPM / 1.5)

				Yuki_FOV.Set(68)
				Yuki_FOV.Tween(70, {BPM, Enum.EasingStyle.Quart, Enum.EasingDirection.Out})
			end

			task.wait(BPM)
		end
	end)
	
	coroutine.resume(oh_im_threading_it_oh_so_good)
	
	AttributeListener.new(Torso, "RedMistPoseAura", function()
		if oh_im_threading_it_oh_so_good and coroutine.status(oh_im_threading_it_oh_so_good) == "suspended" then
			coroutine.close(oh_im_threading_it_oh_so_good)
		end
		
		looping = false
		Theme:Destroy()
		
		EffectUtility.Toggle(Effect, false)
		task.delay(1, Effect.Destroy, Effect)
	end)
end

return VFX
