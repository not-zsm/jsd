local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local CrashoutMeter = LocalPlayer.PlayerGui.Videos.MobCrashout

---------------------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

---------------------------------------------------------------------------------

local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )


local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

---------------------------------------------------------------------------------

local SwrermMeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.SwrermMeshVFX )
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local MobCode = require( ReplicatedStorage.Modules.Player.Replication.VFX.Reigen["Part Time Employee"] )

---------------------------------------------------------------------------------

return {
	OnStart = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, ReplicatedStorage.Animations.Attacks.Reigen.CRASHOUT.User)
		if (Retrieved == nil) then return end

		local Animation = Retrieved.Animation
		local NewJob = Retrieved.Job

		local RootPart = Retrieved.RootPart

		local Shake

		local Colors = {
			Color3.fromRGB(162, 85, 255),
			Color3.fromRGB(105, 185, 255),
			Color3.fromRGB(90, 255, 115),
			Color3.fromRGB(146, 113, 255),
		}

		local ScreenVFX = coroutine.create(function()
			while true do
				Vignette(Colors[math.random(1, #Colors)], 0.3, 0.1)
				task.wait(0.075)
			end
		end)

		local MobExplosion = script.Holder.MobExplosion:Clone()
		local Aftercharge = script.Holder.AfterCharge:Clone()

		NewJob:Task(MobExplosion)
		NewJob:Task(Aftercharge)

		NewJob:Task(Animation:GetMarkerReachedSignal("mobexplode"):Connect(function()
			if EffectUtility.Distance_Close(Model, 50) then
				Shake = CameraShake(1.3, 40, 0.01, 0, Vector3.one * 0.5, Vector3.one * 1)
				coroutine.resume(ScreenVFX)
			end

			MobExplosion.CFrame = RootPart.CFrame * CFrame.new(0, -3, 0)
			MobExplosion.Parent = workspace.Visuals

			EffectUtility.Emit(MobExplosion, true)
			EffectUtility.Toggle(MobExplosion.Enable, true)
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("endmobexplode"):Connect(function()
			task.delay(1, MobExplosion.Enable.Destroy, MobExplosion.Enable)

			Aftercharge.CFrame = RootPart.CFrame * CFrame.new(0, -3, 0)
			Aftercharge.Parent = workspace.Visuals

			EffectUtility.Toggle(MobExplosion.Enable, false)
			EffectUtility.Toggle(Aftercharge, true)
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("endexplode"):Connect(function()
			EffectUtility.Toggle(Aftercharge, false)

			if Shake then
				Shake:StartFadeOut(0)
			end

			local Endexplosion = script.Holder.EndExplosion:Clone()
			Endexplosion.CFrame = RootPart.CFrame
			Endexplosion.Parent = workspace.Visuals
			EffectUtility.Emit(Endexplosion)

			if EffectUtility.Distance_Close(Model, 50) then
				CameraShake(5, 25, 0.01, 0.75, Vector3.one * 0.8, Vector3.one * 0.5)
			end

			Utility.CloseThreadSafe(ScreenVFX)
		end))
	end,

	Cutscene = function()
		local NewJob = Job.new()

		task.delay(0.5, SoundService.PlayLocalSound, SoundService, script.SFX)

		local Auras = {}

		local function AddAuraToPart(Part : BasePart)
			for _, Item in ipairs(script.Aura:GetChildren()) do
				local NewItem = Item:Clone()
				NewItem.Enabled = true
				NewItem.Parent = Part

				table.insert(Auras[Part.Parent], NewItem)
			end
		end

		local function Transform(CharacterModel : Model, Untransform : boolean)
			if not Untransform then
				Auras[CharacterModel] = {}

				for _, Item in ipairs(CharacterModel:GetChildren()) do
					if Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart" and Item.Name ~= "Tie" then
						AddAuraToPart(Item)

						Item.Color = Color3.new(0,0,0)
					end
				end

				CharacterModel["Accessory (MeshPartAccessory)"].Handle.Transparency = 1
				CharacterModel["Accessory (mob100_collar)"].Handle.Mesh.VertexColor = Vector3.new(0,0,0)
				CharacterModel.Pants.Color3 = Color3.fromRGB(0,0,0)
				CharacterModel.Shirt.Color3 = Color3.fromRGB(0,0,0)

				local Eyes = script.VFXHolder.Eyes:Clone()
				Eyes.Name = "MobEyes"
				Eyes.Parent = CharacterModel.Head
			else
				CharacterModel["Accessory (MeshPartAccessory)"].Handle.Transparency = 0
				CharacterModel["Accessory (mob100_collar)"].Handle.Mesh.VertexColor = Vector3.new(1,1,1)
				CharacterModel.Pants.Color3 = Color3.fromRGB(255, 255, 255)
				CharacterModel.Shirt.Color3 = Color3.fromRGB(255, 255, 255)

				CharacterModel.Head.MobEyes:Destroy()

				for Index, Aura in ipairs(Auras[CharacterModel]) do
					Aura:Destroy()
				end

				for _, Item in ipairs(CharacterModel:GetChildren()) do
					if Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart" then
						Item.Color = Color3.fromRGB(234, 184, 146)
					end
				end
			end
		end

		local Holder = NewJob:Task(script.Holder:Clone())
		Holder.Parent = workspace.Visuals

		local Camera = NewJob:Task(script.Camera:Clone())
		EffectUtility.Weld(Camera, Holder.Mob.HumanoidRootPart)
		Camera.Parent = workspace.Visuals
		NewJob:Task(Camera)
		
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		LocalPlayer.PlayerGui.Statistics.Enabled = false

		task.spawn(function()
			local IconModule = require(ReplicatedStorage.Modules.Icon)
			IconModule.setTopbarEnabled(false)
		end)
		
		local Mob = Holder.Mob
	
		Holder.SphereSurrounding.Transparency = 0

		local Animation = Holder.Mob.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Reigen.CRASHOUT.User)
		Animation:Play(0)

		local CameraAnimation : AnimationTrack = Camera.Humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Reigen.CRASHOUT.Camera)
		CameraAnimation:Play(0)

		NewJob:Task(RunCameraRig(Holder.Mob.HumanoidRootPart, Camera, CFrame.new(0, -3, 0) * CFrame.Angles(0, math.pi, 0), {
			DontSupportCutsceneSetting = true,
			DontSaveCameraPosition = true,
			DontDoTransition = true
		}))

		NewJob:Task(CameraAnimation.Stopped:Connect(function()
			Camera:Destroy()
		end))

		NewJob:Task(Animation.Stopped:Connect(function()
			NewJob:Destroy()
		end))

		Yuki_FOV.Immune = true
		CurrentCamera.FieldOfView = 20

		NewJob:Task(task.delay(4.1, function()
			CurrentCamera.FieldOfView = 40
		end))

		NewJob:Task(function()
			Yuki_FOV.Immune = false

			CurrentCamera.FieldOfView = 70
			
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			LocalPlayer.PlayerGui.Statistics.Enabled = true

			task.spawn(function()
				local IconModule = require(ReplicatedStorage.Modules.Icon)
				IconModule.setTopbarEnabled(true)
			end)
		end)

		local ScreenCover = NewJob:Task(script.ScreenCover:Clone())
		ScreenCover.Enabled = true
		ScreenCover.Parent = LocalPlayer.PlayerGui

		ScreenCover.Frame.BackgroundTransparency = 0

		local function Blink()
			ScreenCover.Frame.BackgroundTransparency = 1

			task.wait(0.03)

			ScreenCover.Frame.BackgroundTransparency = 0.15

			task.wait(0.06)

			ScreenCover.Frame.BackgroundTransparency = 1
		end

		TweenService:Create(ScreenCover.Frame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()

		EffectUtility.Emit(Camera.Torso.FX.RadiantLines)

		NewJob:Task(Animation:GetMarkerReachedSignal("fire"):Connect(function()
			EffectUtility.Toggle(Holder.FireEnvironment, true)
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("disappear1"):Connect(function()
			--ScreenCover.Frame.BackgroundTransparency = 0

			Holder.FireEnvironment:Destroy()

			EffectUtility.Toggle(Holder.Tornado, true)
			
			CrashoutMeter.First.TimePosition = 0
			CrashoutMeter.First.Visible = true
			CrashoutMeter.First:Play()
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("appear1"):Connect(function()
			CrashoutMeter.First.Visible = false
			--ScreenCover.Frame.BackgroundTransparency = 1
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("disappear2"):Connect(function()
			--ScreenCover.Frame.BackgroundTransparency = 0
			
			CrashoutMeter.Second.TimePosition = 0
			CrashoutMeter.Second.Visible = true
			CrashoutMeter.Second:Play()
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("explode"):Connect(function()
			EffectUtility.Emit(Holder.Explosion)
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("scene"):Connect(function()
			Holder.Tornado:Destroy()
			Holder["Black Floor"]:Destroy()

			Transform(Mob)
			--Transform(Model)

			EffectUtility.Toggle(Camera.Torso.FX.Bars, true)
			EffectUtility.Toggle(Holder.Lightning, true)
			EffectUtility.Toggle(Holder.Scene, true)

			Mob.Highlight.Enabled = true

			EffectUtility.Emit(Camera.Torso.FX.Transition)

			CurrentCamera.FieldOfView = 20

			TweenService:Create(CurrentCamera, TweenInfo.new(10.93), {FieldOfView = 70}):Play()	
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("endscene"):Connect(function()
			EffectUtility.Toggle(Holder.Scene, false)

			task.delay(2, Holder.Scene.Destroy, Holder.Scene)
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("scene2"):Connect(function()
			EffectUtility.Toggle(Holder.Scene2, true)

			task.spawn(function()
				for Index = 1, 7 do
					Blink()

					task.wait(0.25)
				end
			end)
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("endscene2"):Connect(function()
			EffectUtility.Toggle(Camera.Torso.FX.Bars, false)
			EffectUtility.Toggle(Holder.Scene2, false)

			task.delay(2, Holder.Scene2.Destroy, Holder.Scene2)
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("scene3"):Connect(function()
			CrashoutMeter.Second.Visible = false
			--ScreenCover.Frame.BackgroundTransparency = 1

			EffectUtility.Toggle(Holder.Scene3, true)
			EffectUtility.Toggle(Camera.Torso.FX.BarsVertical, true)

			CurrentCamera.CFrame = Mob.HumanoidRootPart.CFrame * CFrame.new(0, 1.3, -6.5) * CFrame.Angles(0, math.pi, 0)
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("cameraend"):Connect(function()
			ScreenCover.WhiteFrame.Visible = true

			TweenService:Create(ScreenCover.WhiteFrame, TweenInfo.new(0.05), {BackgroundTransparency = 0}):Play()	

			Camera:Destroy()

			CurrentCamera.CameraType = Enum.CameraType.Scriptable
			CurrentCamera.FieldOfView = 25
			CurrentCamera.CFrame = Mob.HumanoidRootPart.CFrame * CFrame.new(0, 1.3, -6.5) * CFrame.Angles(0, math.pi, 0)

			RunService:BindToRenderStep("fakecam", Enum.RenderPriority.Camera.Value + 3, function()
				CurrentCamera.CFrame = Mob.HumanoidRootPart.CFrame * CFrame.new(0, 1.3, -6.5) * CFrame.Angles(0, math.pi, 0)
			end)
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("endscene3"):Connect(function()			
			EffectUtility.Toggle(Holder.Scene3, false)
			EffectUtility.Toggle(Holder.Serious, true)

			TweenService:Create(CurrentCamera, TweenInfo.new(4.3), {FieldOfView = 27.5}):Play()	
			TweenService:Create(ScreenCover.WhiteFrame, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()	

			task.delay(2, function()
				Holder.Scene3:Destroy()

				--task.wait(2.3)

				--TweenService:Create(CurrentCamera, TweenInfo.new(0.36, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = 60}):Play()	
			end)
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("mobexplode"):Connect(function()
			Holder.SphereSurrounding:Destroy()
			Holder.Lightning:Destroy()

			EffectUtility.Toggle(Holder.Serious, false)

			RunService:UnbindFromRenderStep("fakecam")

			TweenService:Create(CurrentCamera, TweenInfo.new(0.73, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {FieldOfView = 75}):Play()	
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("endexplode"):Connect(function()
			--Transform(Model, true)

			TweenService:Create(CurrentCamera, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {FieldOfView = 70}):Play()	
		end))
	end,
}
