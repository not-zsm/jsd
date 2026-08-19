local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CharaAssets = ReplicatedStorage.Effects.Characters.Chara

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local Yuki_Skeleton = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_Skeleton )

-- these racks in my bridges huh got my pants faallinnnnn

function VFX.Start(RootPart : BasePart)
	local Camera = script.Camera:Clone()
	Camera:PivotTo(RootPart.CFrame)
	Camera.Parent = workspace.Visuals
	
	local CleanFOVRunner = Yuki_FOV.AnimateWithMoonFile(script.FOV)
	local Clean = RunCameraRig(RootPart, Camera)
	
	local Animation = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Accelerator["Accelerated Punishment"].Camera)
	Animation:Play(0)

	AttributeListener.new(RootPart, "AcceleratedPunishmentFinisher", function()
		CleanFOVRunner()
		Clean()
	end)
end

local function neweffect(root : BasePart, effect : BasePart)
	local neweffect = effect:Clone()
	neweffect.CFrame = root.CFrame * effect.CFrame + Vector3.yAxis * -3
	neweffect.Parent = workspace.Visuals
	EffectUtility.Emit(neweffect)
end

function VFX.Hit(RootPart : BasePart, VictimModel : Model, Count : string)
	neweffect(RootPart, script["hit" .. Count])
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25 then
		CameraShake(3, 30, 0.01, 0.225)
	end

	if VictimModel then
		local Hitting = Count == 1 and VictimModel.Torso or VictimModel.Head
		
		if Hitting then
			Yuki_Skeleton(Hitting, 0.1, 0.1)
			Blood.BloodRays("SpitOut",  Hitting)
		end
	end
end

function VFX.Kick(RootPart : BasePart, VictimModel : Model, Type : string)
	neweffect(RootPart, script["kick" .. Type])
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25 then
		CameraShake(3, 30, 0.01, 0.225)
	end

	if VictimModel then
		Yuki_Skeleton(VictimModel.Head, 0.1, 0.1)
	end
	
	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or LocalPlayer == Players:GetPlayerFromCharacter(VictimModel) then
		task.spawn(function()
			local ImpactFrame = Instance.new("ColorCorrectionEffect")
			ImpactFrame.Contrast = 5
			ImpactFrame.Saturation = -1
			ImpactFrame.Parent = Lighting

			task.wait(2 / 60)

			ImpactFrame.Contrast = -5
			ImpactFrame.Saturation = -1

			task.wait(2 / 60)

			ImpactFrame.Contrast = 5
			ImpactFrame.Saturation = -1

			task.wait()

			ImpactFrame:Destroy()
		end)
	end
end

function VFX.Slam(RootPart : BasePart)
	neweffect(RootPart, script.slam)
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25 then
		CameraShake(2.5, 20, 0.01, 0.2)
	end
end

function VFX.Land(RootPart : BasePart)
	neweffect(RootPart, script.land)
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25 then
		CameraShake(2, 10, 0.01, 0.15)
	end
end

function VFX.Vanish(Torso : BasePart)
	EffectUtility.EmitEffectsOnBasePart(script.Vanish, Torso)
end

function VFX.Punch(RootPart : BasePart, VictimModel : Model)
	neweffect(RootPart, script.punch)
	
	if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) or LocalPlayer == Players:GetPlayerFromCharacter(VictimModel) then
		task.spawn(function()
			local ImpactFrame = Instance.new("ColorCorrectionEffect")
			ImpactFrame.Contrast = 5
			ImpactFrame.Saturation = -1
			ImpactFrame.Parent = Lighting

			task.wait(4 / 60)

			ImpactFrame.Contrast = -5
			ImpactFrame.Saturation = -1

			task.wait(4 / 60)

			ImpactFrame.Contrast = 5
			ImpactFrame.Saturation = -1

			task.wait(4 / 60)

			ImpactFrame:Destroy()
		end)
	end
end

function VFX.End(RootPart : BasePart)
	neweffect(RootPart, script.endhit)
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) < 100 then
		local punchwave = script.beam:Clone()
		punchwave.CFrame = RootPart.CFrame * script.beam.CFrame + Vector3.yAxis * -3
		punchwave.Parent = workspace.Visuals

		for _, Item in pairs(punchwave.Beam:GetDescendants()) do
			if Item:IsA("Beam") then
				Item.Brightness = 0.6
				Item.TextureSpeed = 5

				TweenService:Create(Item, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), 
					{Brightness = 0}
				):Play()

				TweenService:Create(Item, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), 
					{TextureSpeed = 0}
				):Play()
			end
		end

		task.delay(4, punchwave.Destroy, punchwave)
	end
	
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 30 then
		CameraShake(8, 75, 0.01, 0.75)
	end
end

return VFX