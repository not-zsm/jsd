local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Powers["Super Speed"]

---------------------------------------------------------------------

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

---------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local JobModule = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local quickutil = require( script.quickutil )
local handler = script.superspeedrun
local effects = handler.effects
local meshes = effects.meshes

local ATrainAfterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.ATrainAfterimage )
local Afterimage = require( ReplicatedStorage.Modules.Player.Replication.Global.Afterimage )
local BugoMesh = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo )

local DojyanMeshEmit = require( ReplicatedStorage.Modules.Player.Replication.Global.DojyanMeshEmit )

---------------------------------------------------------------------
local AfterimageVanishInfo = {0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out}
local AfterimageMoveInfo = {0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out}

local function Afterimage_Effect(Afterimage : Model)
	local Highlight = Instance.new("Highlight")
	Highlight.FillColor = Color3.fromRGB(112, 181, 255)
	Highlight.FillTransparency = 0.4
	Highlight.OutlineTransparency = 1
	Highlight.Parent = Afterimage

	local Tween = TweenService:Create(Highlight, TweenInfo.new(table.unpack(AfterimageVanishInfo)),
		{FillTransparency = 1}
	)

	Tween:Play()

	Tween.Completed:Once(function()
		Highlight:Destroy()
	end)
end

local function InvisibleModel(Model : Model, Value : boolean)
	local Transparent = (Value and 1 or 0)

	for _, Item in ipairs(Model:GetDescendants()) do
		if Item:IsA("BasePart") then
			Item.Transparency = Transparent
		end
	end
end

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		local IsMainPlayer = (LocalPlayer.Character == Model)
		
		local SFX = script.SFX --if math.random(1, 5) == 5 then script.SFXMusic else script.SFX
		
		Job:Task(EffectUtility.AddSFX(SFX, Torso, 0.5))
		
		Job:Task(Animation:GetMarkerReachedSignal("Leap"):Connect(function()
			if IsMainPlayer then
				-- Velocity
				local Velocity = Job:Task(VelocityUtil.Create(RootPart, "Super Speed Leap"))
				Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
				Velocity.Parent = RootPart

				local VelStrength = Instance.new("NumberValue")
				VelStrength.Value = 200
				VelStrength.Parent = Velocity

				TweenService:Create(VelStrength, TweenInfo.new(1.8, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
					Value = 0
				}):Play()

				Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function()
					Velocity.Velocity = RootPart.CFrame.LookVector * VelStrength.Value
				end)

				task.delay(2, Velocity.Destroy, Velocity)
				
				Vignette(Color3.new(0.215686, 0.658824, 1), 0.9, 3)
				CameraShake(2, 10, 0.01, 0.2, Vector3.one * 0.8)
				
				-- FOV Cam
				Job:Task(function()
					Yuki_FOV.Set(70)
				end)
	
				Yuki_FOV.Tween(80, {0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
				task.wait(0.1)
				Yuki_FOV.Tween(70, {0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In})
			end
			
			EffectUtility.CloneAndEmit(effects.jump.Jump, RootPart)
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("Sprint"):Connect(function()
			if IsMainPlayer then
				local Velocity = Job:Task(VelocityUtil.Create(RootPart, "Super Speed Sprint"))
				Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
				Velocity.Parent = RootPart

				local VelStrength = Instance.new("NumberValue")
				VelStrength.Value = 225
				VelStrength.Parent = Velocity

				Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function()
					Velocity.Velocity = RootPart.CFrame.LookVector * VelStrength.Value
				end)
				
				-- FOV Cam
				CameraShake(3, 30, 0.01, 0.5, Vector3.one * 0.8)
				Yuki_FOV.Tween(90, {0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In})
				
				local LoopCoroutine = coroutine.create(function()
					while true do
						Vignette(Color3.new(0.215686, 0.658824, 1), 0.9, 3)
						CameraShake(1, 12, 0.05, 0.1, Vector3.one * 0.8)

						task.wait(0.1)
					end
				end)

				Job:Task(LoopCoroutine)
				task.spawn(LoopCoroutine)
				
				Job:Task(Animation:GetMarkerReachedSignal("Stop"):Connect(function()
					TweenService:Create(VelStrength, TweenInfo.new(0.8, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
						Value = 0
					}):Play()

					task.delay(0.9, Velocity.Destroy, Velocity)
					
					-- FOV Cam
					Yuki_FOV.Tween(70, {0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
					task.cancel(LoopCoroutine)
				end))
			end
			
			-- VFX
			ATrainAfterimage(Model, true)
			Afterimage(Model, AfterimageVanishInfo, AfterimageMoveInfo, 2, Afterimage_Effect)
			
			-- Trails
			local Trails = Job:Task(effects.trails:Clone())
			for _, Limb in ipairs(Trails:GetChildren()) do
				Limb.Weld.Part0 = Model[Limb.Name]
			end
			
			Trails.Parent = workspace.Visuals
			quickutil:interact(Trails, "Trail", "Enabled", true)
			
			-- Speed
			local SpeedVFX = Job:Task(effects.speed:Clone())
			SpeedVFX.Weld.Part0 = RootPart
			SpeedVFX.Parent = workspace.Visuals
			
			quickutil:interact(SpeedVFX, "ParticleEmitter", "Enabled", true)
			EffectUtility.CloneAndEmit(effects.rush.Rush, RootPart)
			-- EffectUtility.Dojyan.VFXCFramedWithItself(effects.speed, RootPart)

			--DojyanMeshEmit(effects.meshes.rush.aa, true)
			BugoMesh(script.RushMesh, RootPart)
			
			--task.spawn(function()
			--	for i = 1, 23 do
			--		local clone = Instance.new("Highlight")
			--		clone.FillColor = Color3.fromRGB(255, 179, 179)
			--		clone.FillTransparency = 16
			--		clone.Name = "speed"
			--		clone.OutlineColor = Color3.fromRGB(255, 255, 255)
			--		clone.OutlineTransparency = 0.99
					
			--		clone.Parent = Model

			--		quickutil:tween_single(clone, .07, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {FillTransparency = 1}, true)
			--		task.wait(.1)
			--	end
			--end)
			
			Job:Task(Animation:GetMarkerReachedSignal("Stop"):Connect(function()
				quickutil:interact(SpeedVFX, "ParticleEmitter", "Enabled", false)
				local StopEffect = EffectUtility.CloneAndToggle(effects.stop.Stop, RootPart)
				Job:Task(StopEffect)
				task.delay(0.3, EffectUtility.Toggle, StopEffect, false)

				quickutil:interact(Trails, "Trail", "Enabled", false)
				ATrainAfterimage(Model, false)
			end))
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("Beams"):Connect(function()
			--ATrainAfterimage(Model, true)
			--task.delay(0.3, ATrainAfterimage, Model, false)
			local CloneThread = coroutine.create(function()
				for i = 1, 9 do
					local clone = Job:Task(effects.beams.attachment:Clone())
					clone.Parent = RootPart

					quickutil:tween_single(clone, .35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {["CFrame"] = clone.CFrame * CFrame.Angles(0, 0, math.rad(180))}, true)
					quickutil:tween_descendant(clone, "Beam", .12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {Width0 = 0, Width1 = 0}, true)

					task.wait(.25)
				end
			end)
			
			Job:Task(CloneThread)
			coroutine.resume(CloneThread)
		end))
		
		Job:Task(Animation:GetMarkerReachedSignal("AfterImage"):Connect(function()
			--ATrainAfterimage(Model, true)
			--task.delay(0.3, ATrainAfterimage, Model, false)
			local AfterImageThread = coroutine.create(function()
				for i = 1, 40 do
					Afterimage(Model, AfterimageVanishInfo, AfterimageMoveInfo, 2, Afterimage_Effect)
					task.wait(.05)
				end
			end)
			
			Job:Task(AfterImageThread)
			coroutine.resume(AfterImageThread)
		end))
		
		Job:Task(function()
			ATrainAfterimage(Model, false)
		end)
	end,
	
	Finisher = function(VictimModel : Model)
		local BloodEnabled = LocalPlayer:GetAttribute("Blood")
		
		if BloodEnabled then
			EffectUtility.EmitEffects(ReplicatedStorage.Effects.Blood.Splash, VictimModel.HumanoidRootPart)
			
			local Welds = {"Left Hip", "Left Shoulder", "Neck", "Right Hip", "Right Shoulder"}
			
			--for _, WeldName in pairs(Welds) do
			--	local Weld = VictimModel.Torso:FindFirstChild(WeldName)
				
			--	if Weld then
			--		Weld:Destroy()
			--	end
			--end
		end
	end,
}