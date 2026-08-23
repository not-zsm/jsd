local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Chara["Special Hell"]

---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.modules.client.replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.modules.client.replication.Global.Vignette )
local Blood = require( ReplicatedStorage.modules.client.replication.Global.Blood )

local RunCameraRig = require( ReplicatedStorage.modules.client.replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.modules.client.replication.Global.Yuki_FOV )

local Afterimage = require( ReplicatedStorage.modules.client.replication.Global.Afterimage )
local ATrainAfterimage = require( ReplicatedStorage.modules.client.replication.Global.ATrainAfterimage )

local CharacterTransparency = require( ReplicatedStorage.modules.client.replication.Global.CharacterTransparency )

local TekrinnDialogue = require( ReplicatedStorage.modules.effect.tekrinnDialogue )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )
local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )

local VelocityUtil = require( ReplicatedStorage.modules.shared.Game.Velocity.VelocityUtil )

---------------------------------------------------------------------

local function Distance_Close(Model : Model)
	return (if LocalPlayer.Character == Model then true else LocalPlayer:DistanceFromCharacter(Model.PrimaryPart.Position) < 50)
end

local function Distance_Far(Model : Model)
	return (if LocalPlayer.Character == Model then true else LocalPlayer:DistanceFromCharacter(Model.PrimaryPart.Position) < 150)
end

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job

		local Is_Source = (LocalPlayer.Character == Model)
		
		Job:Task(EffectUtility.AddSFX(script.SFX, Torso, 0.3))

		local RedColor = Color3.fromRGB(255, 198, 198)
		local RedderColor = Color3.fromRGB(255, 137, 137)
		
		local Screen_Effect = script.ScreenEffect:Clone()
		Screen_Effect.Enabled = false
		Screen_Effect.Parent = Lighting
		
		Job:Task(Screen_Effect)

		Job:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
			local Effect = script.Assets:FindFirstChild(Parameter)

			if Effect and Distance_Far(Model) then
				if Effect:IsA("BasePart") then
					local NewEffect = Effect:Clone()
					NewEffect.CFrame = RootPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
					NewEffect.Parent = workspace.Visuals
					EffectUtility.Arc.EmitAttachment(NewEffect)
				else
					if Parameter == "3" then
						local NewEffect = script.Assets["3_floor"]:Clone()
						NewEffect.CFrame = RootPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
						NewEffect.Parent = workspace.Visuals
						EffectUtility.Arc.EmitAttachment(NewEffect)
					end

					EffectUtility.Arc.CloneAndEmit(Effect, Model[Effect:GetAttribute("attached")])
				end
				
				if (Parameter == "1") then -- circle
					CameraShake(3, 30, 0.01, 1.15, Vector3.one * 0.8, Vector3.one * 0.5)

				elseif (Parameter == "2") then -- lil booms
					CameraShake(1.5, 15, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.15)
					
					Screen_Effect.Enabled = true

					TweenService:Create(Screen_Effect, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
						{TintColor = RedColor}
					):Play()

				elseif (Parameter == "2.5") then -- impacts before big booms
					CameraShake(2.5, 40, 0.01, 0.55, Vector3.one * 0.8, Vector3.one * 0.3)
					
					TweenService:Create(Screen_Effect, TweenInfo.new(0.75, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
						{TintColor = RedderColor}
					):Play()
					
				elseif (Parameter == "2.8") then -- big booms
					CameraShake(7.5, 75, 0.05, 1.25, Vector3.one * 0.8, Vector3.one * 0.5)
					
				elseif (Parameter == "3") then -- big boom at end
					TweenService:Create(Screen_Effect, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
						{TintColor = Color3.new(1, 1, 1)}
					):Play()

					CameraShake(10, 100, 0.01, 0.75, Vector3.one * 0.8, Vector3.one * 0.5)
				end
			end
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("invis"):Connect(function(Parameter : string)
			CharacterTransparency(Model, (Parameter == "true") and 1 or 0)
		end))
	end,
}