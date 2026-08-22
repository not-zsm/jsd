local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local AnimationRetriever = require( ReplicatedStorage.Client.Replication.VFX.AnimationRetriever )

local RunCameraRig = require( ReplicatedStorage.Client.Replication.Global.RunCameraRig )

return {
	Start = function(Character : Model)
		local Retrieved = AnimationRetriever.new(Character, ReplicatedStorage.Animations.Emotes["Lonely Lonely"].Start)
		if (Retrieved == nil) then return end

		local RootPart = Retrieved.RootPart
		local Job = Retrieved.Job

		local Offset = CFrame.new(0.1, -2, -3)

		local Camera = script.Camera:Clone()
		Camera:PivotTo(RootPart.CFrame * Offset)
		Camera.Parent = workspace.Visuals

		local Animation = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Emotes["Lonely Lonely"].Camera)
		Animation:Play(0)

		--function(Value : boolean)
		--	for _, Item in ipairs(Camera:GetChildren()) do
		--		if Item:IsA("BasePart") and Item.Transparency == 0 then
		--			Item.Transparency = Value and 0 or 1
		--		end
		--	end
		--end)
		
		Job:Task(Camera)
		Job:Task(RunCameraRig(RootPart, Camera, Offset, {
			DontDoTransition = true
		}))
	end,
}
