local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

-------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )
local Job = require( ReplicatedStorage.modules.shared.Utilities.Job )

-------------------------------------------------------------------------------

local CameraShake = require( ReplicatedStorage.modules.client.replication.Global.CameraShake )

local RockHandler = require( ReplicatedStorage.modules.client.replication.Global.RockHandler )
local EffectUtility = require( ReplicatedStorage.modules.client.replication.EffectUtility )
local Smoke = require( ReplicatedStorage.modules.client.replication.Global.Smoke )
local Blood = require( ReplicatedStorage.modules.client.replication.Global.Blood )

local AnimationRetriever = require( ReplicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local VelocityUtil = require( ReplicatedStorage.modules.shared.Game.Velocity.VelocityUtil )
local RunCameraRig = require( ReplicatedStorage.modules.client.replication.Global.RunCameraRig )
local Vignette = require( ReplicatedStorage.modules.client.replication.Global.Vignette )

local Flies = setmetatable({}, {__mode = "k"}) -- removes automatically if index is nil

-------------------------------------------------------------------------------

local CraterDirection = Vector3.yAxis * -15

local function Emit(vfx : BasePart, root : BasePart)
	--local offset = root.CFrame * (if vfx:IsA("Model") then vfx:GetPivot() else vfx.CFrame) -- relies on the cframe in the vfx file (rigs at 0 0 0)
	local offset = (if vfx:IsA("Model") then vfx:GetPivot() else vfx.CFrame)
	
	local new_vfx = vfx:Clone()
	-- new_vfx:PivotTo(root.CFrame)
	EffectUtility.Weld(new_vfx, root, offset)
	
	new_vfx.Parent = workspace.Visuals
	EffectUtility.Emit(new_vfx)
end
-------------------------------------------------------------------------------


return {
	StartBeatdown = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model,
			ReplicatedStorage.Animations.Attacks.Invincible["Holding Back"].Finisher.User
		)

		if (Retrieved == nil) then return end
		
		local Ended = false
		
		local Animation = Retrieved.Animation
		local Job = Retrieved.Job

		local Humanoid = Retrieved.Humanoid
		local RootPart = Retrieved.RootPart
		
		local BloodEnabled = LocalPlayer:GetAttribute("Blood")
		local PlayerIsAttackerOrVictim = (Players:GetPlayerFromCharacter(Model) == LocalPlayer or Players:GetPlayerFromCharacter(VictimModel) == LocalPlayer)
		local SFX
		if BloodEnabled then
			SFX = script.FinisherSFX:Clone()
		else
			SFX = script.FinisherNoBloodSFX:Clone()
		end
		
		if PlayerIsAttackerOrVictim then
			SFX.Parent = workspace
		else
			SFX.Parent = Retrieved.Torso
		end		
		SFX:Play()
		
		Job:Task(function()
			if Ended == false then
				SFX:Destroy()
			end
		end)
		
		task.delay(27, SFX.Destroy, SFX)
		
		-- Start Camera
		if PlayerIsAttackerOrVictim then
			local Camera : Model = Job:Task(ReplicatedStorage.modules.effect.assets["Camera's"].MJJBA:Clone())
			Camera:PivotTo(RootPart.CFrame)
			Camera.Parent = workspace.Visuals

			local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Invincible["Holding Back"].Finisher.BeatdownCamera)
			CameraAnimation:Play(0)

			Job:Task(CameraAnimation.Stopped:Connect(function()
				Camera:Destroy()
			end))
			
			Job:Task(Animation:GetMarkerReachedSignal("camera_start"):Connect(function()
				Job:Task(RunCameraRig(RootPart, Camera, nil, {
					DontDoTransition = true
				}))
			end))
		end
		
		-- VFX Listeners
		local VFXNames = {0, 0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
		local SpitBloodVFX = {7, 8}
		-- 6, 10 big
		
		for _, i in ipairs(VFXNames) do
			Job:Task(Animation:GetMarkerReachedSignal(i):Connect(function(Parameter : string)
				if BloodEnabled then
					EffectUtility.CloneAndEmit(script.Assets[tostring(i)], RootPart)
				else
					EffectUtility.CloneAndEmit(script.NoBloodAssets[tostring(i)], RootPart)
				end
				
				if i == 0.5 then
					CameraShake(1, 10, 0.03, 0.55, Vector3.one * 0.8, Vector3.one * 0.4)
					
				elseif i == 1 or i == 2 then
					CameraShake(1.2, 15, 0.03, 0.6, Vector3.one * 0.8, Vector3.one * 0.4)
				end
				
				if (VictimModel and VictimModel.Parent) then
					if table.find(SpitBloodVFX, i) then
						Blood.BloodRaysWithoutPreset(VictimModel.Head.MouthAttachment, {
							Amount = Vector2.new(5, 8),
							Spread = Vector2.new(45, 45),
							Face = Enum.NormalId.Front,
							PoolSize = 0.9,
						})

						if PlayerIsAttackerOrVictim then
							Vignette(Color3.fromRGB(255, 0, 0), 0.9, 0.5)
						end
					elseif i == 6 then
						Blood.BloodRaysWithoutPreset(VictimModel.Head.MouthAttachment, {
							Amount = Vector2.new(10, 20),
							Spread = Vector2.new(45, 45),
							Face = Enum.NormalId.Front,
							PoolSize = 1.4,
						})

						if PlayerIsAttackerOrVictim then
							Vignette(Color3.fromRGB(255, 0, 0), 0.7, 0.7)
						end
					elseif i == 10 then
						Blood.BloodRaysWithoutPreset(VictimModel.Head.MouthAttachment, {
							Amount = Vector2.new(30, 35),
							Spread = Vector2.new(55, 55),
							Face = Enum.NormalId.Front,
							PoolSize = 1.8,
						})

						if PlayerIsAttackerOrVictim then
							Vignette(Color3.fromRGB(255, 0, 0), 0.7, 0.5)
						end

						Ended = true
					end
				end
			end))
		end
		
		-- crappy ahh mesh vfx
		--local FlyMesh = script.Mesh.fly:Clone()
		--FlyMesh:PivotTo(RootPart.CFrame * CFrame.new(2.972, 59.274, -6.963) * CFrame.Angles(0, math.rad(90), math.rad(-90)))
		--FlyMesh.Parent = workspace.Visuals
		
		--local TrailUser = script.Mesh.trailuser:Clone()
		--TrailUser:PivotTo(RootPart.CFrame * CFrame.new(-0.688, 7.775, 0.977) * CFrame.Angles(math.rad(-90), math.rad(-180), 0))
		--TrailUser.Parent = workspace.Visuals
		
		--local TrailVictim = script.Mesh.trailvictim:Clone()
		--TrailVictim:PivotTo(RootPart.CFrame * CFrame.new(-0.688, 7.775, 0.977) * CFrame.Angles(math.rad(-90), math.rad(-180), 0))
		--TrailVictim.Parent = workspace.Visuals
		
	end
}		
	



































		
		
		
		
		
		
		
		
	
