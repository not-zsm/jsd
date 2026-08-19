local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local CurrentCamera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer.PlayerGui

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Global.Ultimate.Mori

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )

local AenoirUtil = require( ReplicatedStorage.Modules.Shared.Utilities.Utility.AenoirUtil )

local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Dojyan_Util = require( ReplicatedStorage.Modules.Player.Replication.Global.Dojyan_Util )
local MeshEmit = require( ReplicatedStorage.Modules.Player.Replication.Global.Dojyan_Util.MeshEmit )

local HideAllUI = require( ReplicatedStorage.Modules.Player.Replication.Global.HideAllUI )

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local VFX = script.VFX
local Throne = script.Throne

local function Theme(Model : Model, Parent : Instance)
	local Theme = Instance.new("Sound")
	Theme.Name = "Mori_Theme"
	Theme.SoundId = "rbxassetid://118667192746367" --"rbxassetid://98136904900963"
	Theme.Volume = 1.5
	Theme.Looped = true
	Theme.SoundGroup = SoundService.UltimateMusic
	Theme.Parent = Parent
	Theme:Play()
	
	local ThemeJob = AttributeListener.new(Model, "Ultimate", function()
		TweenService:Create(Theme, TweenInfo.new(0.5),
			{Volume = 0}
		):Play()

		task.delay(1, Theme.Destroy, Theme)
	end)

	local Listener = AttributeListener.GetReplicationFromSource(Model)

	if Listener then
		ThemeJob:Task(Listener:GetAttributeChangedSignal("Ultimate_Mute"):Connect(function()
			local Mute = Listener:GetAttribute("Ultimate_Mute")

			if Mute then
				Theme:Pause()
			else
				Theme:Resume()
			end
		end))
	end
end

return {
	OnUltimateStart = function(Model : Model, SkipIntro : boolean)
		if SkipIntro then
			Theme(Model, (LocalPlayer.Character == Model) and workspace or Model.PrimaryPart)
		end
	end,
	
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Start)
		if (Retrieved == nil) then return end
		
		local Pole = Model:FindFirstChild("Pole")
		local Pole_Handle = Pole and Pole:FindFirstChild("Handle")
		
		local Big_Pole = Model:FindFirstChild("BIGPOLL")
		
		local MainAnimation = Retrieved.Animation
		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local MainJob = Retrieved.Job
		
		local SFX_Parent : boolean = (Retrieved.IsLocalSource and workspace or Model.Torso)
		
		--local Theme = Instance.new("Sound")
		--Theme.Name = "Mori_Theme"
		--Theme.SoundId = "rbxassetid://118667192746367" --"rbxassetid://98136904900963"
		--Theme.Volume = 1.5
		--Theme.Looped = true
		--Theme.SoundGroup = SoundService.UltimateMusic
		--Theme.Parent = SFX_Parent
		--Theme:Play()
		
		Theme(Model, SFX_Parent)
		MainJob:Task(EffectUtility.AddSFX(script.SFX.Start, SFX_Parent, 0.4))

		--local ThemeJob = AttributeListener.new(Model, "Ultimate", function()
		--	TweenService:Create(Theme, TweenInfo.new(0.5),
		--		{Volume = 0}
		--	):Play()

		--	task.delay(1, Theme.Destroy, Theme)
		--end)

		--local Listener = AttributeListener.GetReplicationFromSource(Model)

		--if Listener then
		--	ThemeJob:Task(Listener:GetAttributeChangedSignal("Ultimate_Mute"):Connect(function()
		--		local Mute = Listener:GetAttribute("Ultimate_Mute")

		--		if Mute then
		--			Theme:Pause()
		--		else
		--			Theme:Resume()
		--		end
		--	end))
		--end
		
		if Retrieved.IsLocalSource then
			MainJob:Task(HideAllUI())
			
			local CameraDisabled = false
			
			--local ScreenCover = MainJob:Task(script.ScreenCover:Clone())
			--ScreenCover.Enabled = true
			--ScreenCover.Frame.BackgroundTransparency = 1
			--ScreenCover.Parent = LocalPlayerGui
			
			local Videos = MainJob:Task(script.Videos:Clone())
			Videos.Name = "MoriVideos"
			Videos.Parent = LocalPlayerGui

			local ThroneJob = Job.Extend(MainJob)
			local Throne_CF = CFrame.new(-20000, 0, 0)
			
			local ThroneRoom = Throne.Throne_Room:Clone()
			local ThroneCamera = ThroneRoom:FindFirstChild("Camera")
			ThroneJob:Task(ThroneRoom)

			local Throne_Character = AenoirUtil.CloneCharacter(Model)
			local Throne_Character_Humanoid : Humanoid?, Throne_Character_Animator : Animator, Throne_Character_RootPart : BasePart?
			
			task.spawn(function()
				Throne_Character_Humanoid = Throne_Character:WaitForChild("Humanoid")
				Throne_Character_Animator = Throne_Character_Humanoid:WaitForChild("Animator")
				Throne_Character_RootPart = Throne_Character_Humanoid.RootPart

				Throne_Character_RootPart.Anchored = true
				Throne_Character:PivotTo(Throne_CF)
				Throne_Character.Parent = workspace.Visuals
			end)
			
			ThroneJob:Task(Throne_Character)
			require(script.Clothes)(Throne_Character)
			
			ThroneRoom:PivotTo(Throne_CF)
			ThroneRoom.Parent = workspace.Visuals

			local Camera = script.Camera:Clone()
			Camera:PivotTo(RootPart.CFrame - Vector3.yAxis * 3)
			Camera.Parent = workspace.Visuals
			
			local Vignette = ReplicatedStorage.Effects.Moon_Vignette:Clone()
			Vignette.Parent = LocalPlayerGui
			MainJob:Task(Vignette)
			
			local CameraAnimation = Camera.Humanoid.Animator:LoadAnimation(Animations.Camera)
			CameraAnimation:Play(0)
			
			RunCameraRig(RootPart, Camera, CFrame.new(0, -3, 0), {DontDoTransition = true, DontDeleteRigOnClean = true}, function(Value)
				CameraDisabled = (not Value)
			end)
			
			MainJob:Task(CameraAnimation.Stopped:Once(function()
				Camera:Destroy()
			end))
			
			MainJob:Task(Camera)
			
			local CleanFOV, PauseFOV = Yuki_FOV.AnimateWithMoonFile(script.FOV)
			MainJob:Task(CleanFOV)
			
			local Fall = VFX.camfx.fall:Clone()
			Fall.Weld.Part0 = Camera.CamPart
			Fall.Parent = Camera

			local SpeedLines = VFX.camfx.speedlines:Clone()
			SpeedLines.Weld.Part0 = Camera.CamPart
			SpeedLines.Parent = Camera
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("close_up"):Connect(function()
				TweenService:Create(Vignette.Image, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
				
				if not CameraDisabled then
					Dojyan_Util:interact(SpeedLines, "ParticleEmitter", "Enabled", true)
				end
				
				if not LocalPlayer:GetAttribute("Epileptic_Mode") then
					Videos.Frame.Dream.Visible = true
					Videos.Frame.Dream:Play()

					Videos.Frame.Dream.Ended:Once(function()
						Videos.Frame.BackgroundTransparency = 0
						Videos.Frame.Dream.Visible = false

						TweenService:Create(Videos.Frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
							{BackgroundTransparency = 1}
						):Play()
					end)
				end
				
				PauseFOV(true)

				ThroneJob:Task(function()
					PauseFOV(false)
				end)
				
				--task.wait(0.75)
				
				--TweenService:Create(ScreenCover.Frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				--	{BackgroundTransparency = 0}
				--):Play()
			end))

			MainJob:Task(MainAnimation:GetMarkerReachedSignal("throne_start"):Connect(function()
				--TweenService:Create(ScreenCover.Frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				--	{BackgroundTransparency = 1}
				--):Play()
				
				Vignette.Image.ImageTransparency = 1
				Dojyan_Util:interact(SpeedLines, "ParticleEmitter", "Enabled", false)

				--do
				--	Theme:Play()

				--	TweenService:Create(Theme, TweenInfo.new(0.25),
				--		{Volume = 0.5}
				--	):Play()

				--	local ThemeJob = AttributeListener.new(Model, "Ultimate", function()
				--		TweenService:Create(Theme, TweenInfo.new(0.5),
				--			{Volume = 0}
				--		):Play()

				--		task.delay(1, Theme.Destroy, Theme)
				--	end)

				--	local Listener = AttributeListener.GetReplicationFromSource(Model)

				--	if Listener then
				--		ThemeJob:Task(Listener:GetAttributeChangedSignal("Ultimate_Mute"):Connect(function()
				--			local Mute = Listener:GetAttribute("Ultimate_Mute")

				--			if Mute then
				--				Theme:Pause()
				--			else
				--				Theme:Resume()
				--			end
				--		end))
				--	end
				--end
				
				------- THRONE -------
				
				local Properties = {
					"Ambient",
					"Brightness",
					"ClockTime",
					"GeographicLatitude",
					"ColorShift_Top",
					"ColorShift_Bottom",
					"OutdoorAmbient",
				}

				local Previous = {}

				for _, Property in ipairs(Properties) do
					Previous[Property] = Lighting[Property]
				end
	
				local Sky = Throne.Sky:Clone()
				Sky.Parent = Lighting
				ThroneJob:Task(Sky)
				
				Lighting.Ambient = Color3.fromRGB(138, 138, 138)
				Lighting.Brightness = 1
				Lighting.ClockTime = 12.302
				Lighting.GeographicLatitude = -0.41
				Lighting.ColorShift_Top = Color3.new(0, 0, 0)
				Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
				Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)

				ThroneJob:Task(function()
					for Property, Value in pairs(Previous) do
						Lighting[Property] = Value
					end
				end)
				
				local ThroneMoriAnimation = Throne_Character_Animator:LoadAnimation(Animations.ThroneStart)
				
				if ThroneCamera then
					local ThroneCameraAnimation = ThroneCamera.Humanoid.Animator:LoadAnimation(Animations.ThroneCamera)
					ThroneCameraAnimation:Play(0)
					
					local CleanFOV, PauseFOV = Yuki_FOV.AnimateWithMoonFile(Throne.FOV)
					ThroneJob:Task(CleanFOV)
					
					PauseFOV(true)
					CurrentCamera.FieldOfView = 1

					local Tween = TweenService:Create(CurrentCamera, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
						FieldOfView = 32.44
					})

					Tween:Play()
					
					Tween.Completed:Once(function()
						PauseFOV(false)
					end)

					RunCameraRig(nil, ThroneCamera, nil, {DontDoTransition = true, DontDeleteRigOnClean = true, DontSupportCutsceneSetting = true})
				end
				
				ThroneMoriAnimation:Play(0)
				
				ThroneJob:Task(task.delay(153 / 60, function()
					TweenService:Create(Vignette.Image, TweenInfo.new(1.5166666666666666, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
				end))
				
				ThroneJob:Task(task.delay(240 / 60, function()
					if LocalPlayer:GetAttribute("Epileptic_Mode") then return end
					
					Videos.Frame.Snapback.Visible = true
					Videos.Frame.Snapback:Play()

					Videos.Frame.Snapback.Ended:Once(function()
						--Videos.Frame.BackgroundTransparency = 0
						Videos.Frame.Snapback.Visible = false
					end)
					
					--TweenService:Create(ScreenCover.Frame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					--	{BackgroundTransparency = 0}
					--):Play()
				end))
			end))

			MainJob:Task(MainAnimation:GetMarkerReachedSignal("throne_end"):Connect(function()
				--TweenService:Create(Videos.Frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				--	{BackgroundTransparency = 1}
				--):Play()
				
				ThroneJob:Clean()
				
				Vignette.Image.ImageTransparency = 1
				RunCameraRig(RootPart, Camera, CFrame.new(0, -3, 0), {DontDoTransition = true})
				ThroneRoom:Destroy()
			end))

			MainJob:Task(MainAnimation:GetMarkerReachedSignal("cam_fall"):Connect(function()
				if not CameraDisabled then
					Dojyan_Util:interact(Fall, "Beam", "Enabled", true)
					Dojyan_Util:interact(Fall, "ParticleEmitter", "Enabled", true)
				end
			end))

			MainJob:Task(MainAnimation:GetMarkerReachedSignal("pole_land"):Connect(function()
				Vignette.Image.ImageTransparency = 0.5
				TweenService:Create(Vignette.Image, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {ImageTransparency = 1}):Play()
				
				if not CameraDisabled then
					Dojyan_Util:interact(Fall, "Beam", "Enabled", false)
					Dojyan_Util:interact(Fall, "ParticleEmitter", "Enabled", false)
				end
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("boom"):Connect(function()
				local Brightness = Lighting.Brightness
				
				Vignette.Image.ImageTransparency = 0
				Lighting.Brightness = (Brightness - 0.5)

				TweenService:Create(Lighting, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Brightness = Brightness}):Play()
				TweenService:Create(Vignette.Image, TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {ImageTransparency = 1}):Play()
			end))
		end
		
		do
			local Sense = VFX.sense:Clone()
			Sense:PivotTo(Torso.CFrame)
			Sense.Parent = workspace.Visuals
			EffectUtility.Weld(Sense, Torso)
			MainJob:Task(Sense)
			
			local Inner = VFX.inner:Clone()
			Inner:PivotTo(Torso.CFrame)
			Inner.Parent = workspace.Visuals
			EffectUtility.Weld(Inner, Torso)
			MainJob:Task(Inner)
			
			local Dialogue = VFX.dialogue:Clone()
			Dialogue:PivotTo(Torso.CFrame)
			Dialogue.Parent = workspace.Visuals
			EffectUtility.Weld(Dialogue, Torso, CFrame.new(-0.022, 0, 0))
			MainJob:Task(Dialogue)
			
			local PoleFall = VFX.pollfall:Clone()
			MainJob:Task(PoleFall)
			
			if Big_Pole then
				PoleFall.Weld.Part0 = Big_Pole
				PoleFall.Parent = workspace.Visuals
			end
			
			local PoleSpin = VFX.spin:Clone()
			MainJob:Task(PoleSpin)

			if Pole_Handle then
				PoleSpin.Weld.Part0 = Pole_Handle
				PoleSpin.Parent = workspace.Visuals
			end
			
			Dojyan_Util:interact(Sense, "ParticleEmitter", "Enabled", true)
			Dojyan_Util:emit(Inner)
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("throne_start"):Connect(function()
				Dojyan_Util:interact(Sense, "ParticleEmitter", "Enabled", false)
			end))
			
			local function get_root_cf()
				return (RootPart.CFrame - Vector3.yAxis * 3)
			end
			
			local function mesh(name : string)
				local mesh = VFX.meshes[name]:Clone()
				mesh:PivotTo(get_root_cf())

				for _, Start in ipairs(mesh:GetDescendants()) do
					if Start.Name == "Start" then
						MeshEmit(Start, true)
					end
				end

				task.delay(1, mesh.Destroy, mesh)
			end
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("lets_finish_this"):Connect(function()
				Dojyan_Util:emit(Dialogue.Attachment["1"])
				task.wait(0.4)
				Dojyan_Util:emit(Dialogue.Attachment["2"])
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("pole_fall"):Connect(function()
				mesh("pole_spawn")
				Dojyan_Util:interact(PoleFall, "ParticleEmitter", "Enabled", true)
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("pole_transform"):Connect(function()
				local clone = VFX.transform_highlight:Clone()
				clone.Parent = Big_Pole

				Dojyan_Util:tween_single(clone, .6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {FillTransparency = 1}, true)

				mesh("transform1")

				MainJob:Task(task.delay(0.19, function()
					mesh("transform2")
				end)) ---im watching you...🤨🤨🤨😈😈😈
				-- what....
				
				MainJob:Task(task.delay(0.23, function()
					mesh("transformend")
				end))

				local transform = VFX.transform:Clone()
				transform:PivotTo(get_root_cf() * VFX.transform.CFrame)
				transform.Parent = workspace.Visuals
				Dojyan_Util:emit(transform)
				task.delay(5, transform.Destroy, transform)
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("pole_rotate"):Connect(function()
				local clone = VFX.smokerotate:Clone()
				clone:PivotTo(get_root_cf() * VFX.smokerotate.CFrame)
				clone.Parent = workspace.Visuals
				Dojyan_Util:tween_single(clone, .5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {["CFrame"] = clone.CFrame * CFrame.Angles(0, math.rad(-180), 0)})
				task.delay(3, clone.Destroy, clone)

				task.delay(.25, function()
					Dojyan_Util:interact(clone, "ParticleEmitter", "Enabled", false)
				end)
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("boom"):Connect(function()
				mesh("blow")

				local clone = VFX.blow:Clone()
				clone:PivotTo(get_root_cf() * VFX.blow.CFrame)
				clone.Parent = workspace.Visuals
				Dojyan_Util:emit(clone)
				Dojyan_Util:tween_descendant(clone, "ParticleEmitter", 1.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TimeScale = 0.1})

				task.delay(1.8, function()
					Dojyan_Util:tween_descendant(clone, "ParticleEmitter", 2, Enum.EasingStyle.Back, Enum.EasingDirection.InOut, {TimeScale = 1})
					task.delay(3, clone.Destroy, clone)
				end)
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("pole_land"):Connect(function()
				Dojyan_Util:interact(PoleFall, "ParticleEmitter", "Enabled", false)

				local land_cf = get_root_cf() * VFX.land.CFrame
				local land_direction = Vector3.yAxis * -10
		
				coroutine.wrap(RockHandler.Crater)(land_cf.Position, land_direction, {
					Amount = 22,

					Distance = {
						Min = 9, 
						Max = 13.5
					},

					LookAt = { -- Where the rocks face towards (y axis)
						Min = 6,
						Max = -6
					},

					Exposure = {
						Min = 0.55,
						Max = 0.75
					},

					BaseZ = 1.75,
					SizeMultiplier = 1.4,
					
					CanCollide = false,
				})

				local land = VFX.land:Clone()
				land:PivotTo(land_cf)
				land.Parent = workspace.Visuals
				Dojyan_Util:emit(land)
				task.delay(5, land.Destroy, land)

				mesh("land")

				local clone = VFX.landbeams:Clone()
				clone:PivotTo(get_root_cf() * VFX.landbeams.CFrame)
				clone.Parent = workspace.Visuals
				Dojyan_Util:tween_single(clone, 3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {["CFrame"] = clone.CFrame * CFrame.Angles(0, math.rad(-210), 0)})
				task.delay(3, clone.Destroy, clone)

				Dojyan_Util:tween_descendant(clone, "Beam", 2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {TextureSpeed = 1, Brightness = 0, CurveSize1 = -10}, true)
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("pole_spin"):Connect(function()
				Dojyan_Util:interact(Pole_Handle, "Trail", "Enabled", true)
				Dojyan_Util:interact(PoleSpin, "ParticleEmitter", "Enabled", true)
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("pole_unspin"):Connect(function()
				Dojyan_Util:interact(Pole_Handle, "Trail", "Enabled", false)
				Dojyan_Util:interact(PoleSpin, "ParticleEmitter", "Enabled", false)
			end))
		end
	end,
}