local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Yuki_FOV = require( replicatedStorage.modules.client.replication.Global.Yuki_FOV )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local RunCameraRig = require( replicatedStorage.modules.client.replication.Global.RunCameraRig )
local AttributeListener = require( replicatedStorage.modules.client.replication.Global.AttributeListener )

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Afterimage = require( replicatedStorage.modules.client.replication.Global.Afterimage )

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )

local AttackerVFX = script.Attacker
local VictimVFX = script.Victim

function cutesey_arc_vfx_emitter(instance : Instance, parent : Instance)
	local clone = instance:Clone()
	clone.Parent = parent
	EffectUtility.Arc.EmitAttachment(clone)
end

return {
	Start = function(Attacker : Model, Victim : Model)
		local Retrieved = AnimationRetriever.new(Attacker, replicatedStorage.Animations.Emotes["Combat Gods"].User)
		if (Retrieved == nil) then return end

		local Animation = Retrieved.Animation
		local Job = Retrieved.Job

		local RootPart = Retrieved.RootPart

		local function AttackerExists()
			return (Attacker ~= nil and Attacker.Parent ~= nil)
		end

		local function VictimExists()
			return (Victim ~= nil and Victim.Parent ~= nil)
		end

		local MainPlayer = Players:GetPlayerFromCharacter(Attacker)
		local VictimPlayer = Players:GetPlayerFromCharacter(Victim)

		local IsMainPlayer = (LocalPlayer == MainPlayer or LocalPlayer == VictimPlayer)
		
		local Sound = script.SFX:Clone()
		Sound.Parent = IsMainPlayer and workspace or Attacker.Torso
		Sound:Play()

		Job:Task(Sound)
		
		if IsMainPlayer then
			local Offset = CFrame.new(0, -3, 0) * CFrame.Angles(0, math.pi, 0)

			local Camera = replicatedStorage.modules.effect.assets["Camera's"].MJJBA:Clone()
			Camera:PivotTo(RootPart.CFrame * Offset)
			Camera.Parent = workspace.Visuals

			local Animation = Camera.Humanoid.Animator:LoadAnimation(replicatedStorage.Animations.Emotes["Combat Gods"].Camera)
			Animation:Play(0)
		
			Job:Task(RunCameraRig(RootPart, Camera, Offset, {
				DontDoTransition = true,
				DontSupportCutsceneSetting = true
			}))
			
			Job:Task(Yuki_FOV.AnimateWithMoonFile(replicatedStorage.FOVFiles.CombatGods))
			Job:Task(Camera)
		end

		-----------------------------------------------------------------------------------------------
		-- ATTACKER

		Job:Task(Animation:GetMarkerReachedSignal("M_HRP_vfx"):Connect(function(vfx_name : string)
			if not AttackerExists() then return end

			if vfx_name == "49" then
				local Item = script.Attacker.HumanoidRootPart["49"]:Clone()
				Item.CFrame = RootPart.CFrame * CFrame.new(-0.203, 0.481, 3.77)
				Item.Parent = workspace.Visuals
				EffectUtility.Arc.EmitAttachment(Item)
			else
				cutesey_arc_vfx_emitter(script.Attacker.HumanoidRootPart[vfx_name], RootPart)
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("M_T_vfx"):Connect(function(vfx_name : string)
			if AttackerExists() then
				cutesey_arc_vfx_emitter(script.Attacker.Torso[vfx_name], Attacker.Torso)
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("M_LA_vfx"):Connect(function(vfx_name : string)
			if AttackerExists() then
				cutesey_arc_vfx_emitter(script.Attacker["Left Arm"][vfx_name], Attacker["Left Arm"])
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("M_LL_vfx"):Connect(function(vfx_name : string)
			if AttackerExists() then
				cutesey_arc_vfx_emitter(script.Attacker["Left Leg"][vfx_name], Attacker["Left Leg"])
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("M_RA_vfx"):Connect(function(vfx_name : string)
			if AttackerExists() then
				cutesey_arc_vfx_emitter(script.Attacker["Right Arm"][vfx_name], Attacker["Right Arm"])
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("M_RL_vfx"):Connect(function(vfx_name : string)
			if AttackerExists() then
				cutesey_arc_vfx_emitter(script.Attacker["Right Leg"][vfx_name], Attacker["Right Leg"])
			end
		end))

		-----------------------------------------------------------------------------------------------
		-- ENEMY

		Job:Task(Animation:GetMarkerReachedSignal("E_HRP_vfx"):Connect(function(vfx_name : string)
			if VictimExists() then
				cutesey_arc_vfx_emitter(script.Victim.HumanoidRootPart[vfx_name], Victim.PrimaryPart)
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("E_T_vfx"):Connect(function(vfx_name : string)
			if VictimExists() then
				cutesey_arc_vfx_emitter(script.Victim.Torso[vfx_name], Victim.Torso)

				local ShowVFX = false

				if LocalPlayer.Character then
					ShowVFX = ((LocalPlayer.Character.PrimaryPart.Position - Victim.PrimaryPart.Position).Magnitude <= 10)
				end

				if vfx_name == "3" and ShowVFX then
					Vignette(Color3.fromRGB(0, 166, 255), 0.5, 0.1)
					CameraShake(1.1, 40, 0.01, 0.1, Vector3.one * 0.8, Vector3.one * 0.3)

					task.spawn(function()
						for Index = 1, 4 do
							Afterimage(Victim, {0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out}, 3)
							task.wait(0.05)
						end
					end)
				end
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("E_LA_vfx"):Connect(function(vfx_name : string)
			if VictimExists() then
				cutesey_arc_vfx_emitter(script.Victim["Left Arm"][vfx_name], Victim["Left Arm"])
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("E_LL_vfx"):Connect(function(vfx_name : string)
			if VictimExists() then
				cutesey_arc_vfx_emitter(script.Victim["Left Leg"][vfx_name], Victim["Left Leg"])
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("E_RA_vfx"):Connect(function(vfx_name : string)
			if VictimExists() then
				cutesey_arc_vfx_emitter(script.Victim["Right Arm"][vfx_name], Victim["Right Arm"])
			end
		end))

		Job:Task(Animation:GetMarkerReachedSignal("E_RL_vfx"):Connect(function(vfx_name : string)
			if VictimExists() then
				cutesey_arc_vfx_emitter(script.Victim["Right Leg"][vfx_name], Victim["Right Leg"])
			end
		end))
	end
}
