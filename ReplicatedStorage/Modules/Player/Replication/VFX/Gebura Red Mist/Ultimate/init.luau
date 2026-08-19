local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local ScreenPulse = require( ReplicatedStorage.Modules.Player.Replication.Global.ScreenPulse )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV)
local FadeOut = require(ReplicatedStorage.Modules.Player.Replication.Global.FadeOut)
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

local JobApplication = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local ATrainAfterimage = require(ReplicatedStorage.Modules.Player.Replication.Global.ATrainAfterimage)
local Afterimage = require(ReplicatedStorage.Modules.Player.Replication.Global.Afterimage)

local CreateVignette = require(script.Vignette.Create)

local ImpactFrames = LocalPlayer.PlayerGui.ImpactFrames.GreatSplitVerical

local AnimationFolder = ReplicatedStorage.Animations.Attacks.Global.Ultimate:FindFirstChild("Gebura Red Mist")

local function Clear(RootPart : BasePart, Type : "BodyVelocity" | "LinearVelocity")
	for _, Item in RootPart:GetDescendants() do
		if not Item:IsA(Type) then
			continue
		end

		Item:Destroy()
	end
end

return {
	Start = function(Character : Model)
		local Retrieved = AnimationRetriever.new(Character, AnimationFolder.Start)
		if (Retrieved == nil) then print("no anim") return end
		
		local IsPlayer = Players:GetPlayerFromCharacter(Character) == LocalPlayer

		local Job = Retrieved.Job
		local Animation = Retrieved.Animation
		local RootPart = Retrieved.RootPart

		local HeadEffects = Job:Task(script.HeadEffects:Clone())
		HeadEffects.Join.Part0 = Character.Head
		HeadEffects.Parent = workspace.Visuals
		
		local RootEffects = Job:Task(script.RootEffects:Clone())
		RootEffects.Join.Part0 = RootPart
		RootEffects.Parent = workspace.Visuals
		
		local function GetData(Data : string)
			local PartName, EffectName = unpack(Data:split("-"))

			local Holder = if PartName == "Head" then
				HeadEffects 
			elseif PartName == "HumanoidRootPart" then 
				RootEffects 
			else nil
		
			return Holder:FindFirstChild(`{EffectName}`)
		end
		
		local Sound = Job:Task(script.SFX:Clone())
		Sound.Parent = RootPart
		
		if IsPlayer then
			local Camera = Job:Task(script.Camera:Clone())
			Camera.RootPart.CFrame = RootPart.CFrame
			Camera.Parent = workspace.Visuals
			
			Sound.Parent = Camera.camera

			local CameraAnimation = Camera.AnimationController.Animator:LoadAnimation(AnimationFolder.Camera)
			CameraAnimation:Play(0)

			Job:Task(RunCameraRig(RootPart, Camera, CFrame.new(0.0999908447, -2.0036211, -2.53619766, 1, 0, 0, 0, 1, 0, 0, 0, 1)))
			
			Job:Task(Yuki_FOV.AnimateWithMoonFile(script.FOV))
			
			local SpeedLines = Job:Task(script.speedline:Clone())
			SpeedLines.Anchored = true
			SpeedLines.CFrame = CFrame.new(0, 1000, 0)
			SpeedLines.Parent = workspace.Visuals
			
			Job:Task(task.delay(369/60, function()
				SpeedLines.Anchored = false
				SpeedLines.Join.Part0 = RootPart
			end))
			
			Job:Task(task.delay(413/60, function()
				SpeedLines:Destroy()
			end))
			
			Job:Task(task.delay(830/60, function()
				local screen = script.FadeScreen:Clone()
				screen.Parent = LocalPlayer.PlayerGui
				
				TweenService:Create(screen.Fade, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					BackgroundTransparency = 0
				}):Play()
				
				task.delay(0.65, function()
					TweenService:Create(screen.Fade, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
						BackgroundTransparency = 1
					}):Play()
					
					task.delay(0.5, screen.Destroy, screen)
				end)
			end))
			
			local Vignette, VignetteUpdate = CreateVignette() -- like this
			
			Job:Task(Vignette); Job:Task(VignetteUpdate)
			
			Job:Task(task.delay(414/60, function() -- this is cooked af but im just copying 1:1 so jimpee dont complain, ima port it to use the method i made when i get back
				local ColorCorrection = Job:Task(Instance.new("ColorCorrectionEffect"))
				ColorCorrection.Brightness = -1
				ColorCorrection.Contrast = -1
				ColorCorrection.Saturation = 0
				ColorCorrection.TintColor = Color3.new(1, 1, 1)
				ColorCorrection.Parent = Lighting
				
				task.wait(2/60) -- 💔
				
				ColorCorrection.Brightness = 1 
				
				task.wait(2/60)-- 💔
				
				ColorCorrection.Brightness = 0
				ColorCorrection.Contrast = 100
				
				task.wait(2/60)-- 💔
				
				ColorCorrection.Brightness = 1
				
				task.wait(2/60)-- 💔
				
				ColorCorrection.Brightness = -1
				ColorCorrection.Contrast = -1
				
				task.wait(2/60)-- 💔
				
				ColorCorrection.Brightness = 1
				
				task.wait(2/60)-- 💔
				
				ColorCorrection.Brightness = 0
				ColorCorrection.Contrast = 100
				
				task.wait(2/60)-- 💔
				
				ColorCorrection.Brightness = 1
				
				task.wait(3/60)-- 💔
				
				ColorCorrection.Brightness = -1
				ColorCorrection.Contrast = -1
				
				task.wait(3/60)-- 💔
				
				ColorCorrection.Brightness = 1
				
				task.wait(2/60)-- 💔
				
				ColorCorrection:Destroy()
			end))
		end
		
		Sound:Play()
		
		Job:Task(Animation:GetMarkerReachedSignal("Emit"):Connect(function(Data : string)
			local ToEmit = GetData(Data)

			if not ToEmit then
				return
			end
			
			EffectUtility.EmitAttachment(ToEmit, true)
		end))

		Job:Task(Animation:GetMarkerReachedSignal("Enable"):Connect(function(Data : string)
			local ToEnable = GetData(Data)

			if not ToEnable then
				return
			end

			EffectUtility.Toggle(ToEnable, true)
		end))

		Job:Task(Animation:GetMarkerReachedSignal("Disable"):Connect(function(Data : string)
			local ToDisable = GetData(Data)

			if not ToDisable then
				return
			end

			EffectUtility.Toggle(ToDisable, false)
		end))
		
		local Highlight = Job:Task(Instance.new("Highlight"))
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.FillColor = Color3.fromRGB(148, 148, 148)
		Highlight.FillTransparency = 5
		Highlight.OutlineColor = Color3.fromRGB(255, 56, 56)
		Highlight.OutlineTransparency = 1
		Highlight.Adornee = Character
		Highlight.Parent = Character
		
		Job:Task(task.delay(12/60, function() -- again so jimpee dotn complain its kinda cooked ngl
			TweenService:Create(Highlight, TweenInfo.new(5/60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				OutlineTransparency = 0
			}):Play()
			
			task.wait(5/60)-- 💔
			
			TweenService:Create(Highlight, TweenInfo.new(1/60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				OutlineTransparency = 1
			}):Play()
			
			task.wait(1/60)-- 💔
			
			TweenService:Create(Highlight, TweenInfo.new(3/60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				OutlineTransparency = 0
			}):Play()
			
			task.wait(5/60)-- 💔
			
			TweenService:Create(Highlight, TweenInfo.new(1/60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				OutlineTransparency = 1
			}):Play()

			task.wait(1/60)-- 💔
			
			TweenService:Create(Highlight, TweenInfo.new(1/60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				OutlineTransparency = 0
			}):Play()

			task.wait(1/60)-- 💔
			
			TweenService:Create(Highlight, TweenInfo.new(10/60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				OutlineTransparency = 1
			}):Play()

			task.wait(47/60)-- 💔
			
			TweenService:Create(Highlight, TweenInfo.new(5/60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				OutlineTransparency = 0
			}):Play()

			task.wait(5/60)-- 💔
		end))
	end,
}