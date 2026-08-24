local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer.PlayerGui

local CurrentCamera = workspace.CurrentCamera

---------------------------------------------------------------------

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = replicatedStorage.animations.Attacks.chara["Cursed Remedy"]

---------------------------------------------------------------------

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )
local Smoke = require( replicatedStorage.modules.client.replication.Global.Smoke )

local Yuki_FOV = require( replicatedStorage.modules.client.replication.Global.Yuki_FOV )

local Afterimage = require( replicatedStorage.modules.client.replication.Global.Afterimage )
local ATrainAfterimage = require( replicatedStorage.modules.client.replication.Global.ATrainAfterimage )

---------------------------------------------------------------------

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )

local VelocityUtil = require( replicatedStorage.modules.shared.Game.Velocity.VelocityUtil )
local RunCameraRig = require( replicatedStorage.modules.client.replication.Global.RunCameraRig )

local TekrinnDialogue = require( replicatedStorage.modules.effect.tekrinnDialogue )

---------------------------------------------------------------------

local function Hit_VFX(Model : Model, VictimModel : Model, Retrieved)
	local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
	local Animation, MainJob = Retrieved.Animation, Retrieved.Job

	MainJob:Task(EffectUtility.AddSFX(script.HitSFX, Torso, 0.5))

	local Velocity = VelocityUtil.Create(RootPart, "HOLDIN THAT BEAM LES GO SEEYUH")
	Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
	Velocity.Parent = RootPart

	local Z = 0

	Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
		Velocity.Velocity = (RootPart.CFrame.LookVector * Z)
	end)

	MainJob:Task(Velocity)

	local vfx_15 = MainJob:Task(script.Hit["15"]:Clone())
	vfx_15.Parent = RootPart

	MainJob:Task(Animation:GetMarkerReachedSignal("slow"):Connect(function(Parameter : string)
		local Slow = (Parameter == "true")
		local Info = TweenInfo.new(Slow and 0.25 or 0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

		for _, Effect in pairs(vfx_15:GetDescendants()) do 
			if Effect.ClassName == "ParticleEmitter" then 
				TweenService:Create(Effect, Info, {TimeScale = Slow and 0 or 1}):Play()
			end 
		end
	end))

	MainJob:Task(Animation:GetMarkerReachedSignal("barrage"):Connect(function(Parameter : string)
		if EffectUtility.Distance_Far(Model) then
			local Effect = script.Hit.barrage:Clone()
			Effect.Parent = workspace.Visuals
			EffectUtility.Weld(Effect, VictimModel.Head)
			EffectUtility.Arc.EmitAttachment(Effect)
		end

		if EffectUtility.Distance_Close(Model) then
			local Shake = CameraShake(1.5, 30, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.4)

			if Shake then
				task.delay(1, function()
					Shake:StartFadeOut(0.5)
				end)
			end
		end
	end))

	local CurrSlashFade
	local RunForwardFade

	local ColorCorrection = Instance.new("ColorCorrectionEffect")
	MainJob:Task(ColorCorrection)

	MainJob:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)

		if (Parameter == "13") then
			if CurrSlashFade then
				CurrSlashFade:Destroy()
			end

			if EffectUtility.Distance_Close(Model) then
				CameraShake(2, 20, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.2)
			end

			Z = -60

			local Fade; Fade = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
				if (Z == 0) then
					return Fade:Destroy()
				end

				local Elapsed = (Delta * 60)
				Z = math.min(Z + Elapsed * 0.75, 0)
			end)

			MainJob:Task(Fade)

			MainJob:Task(task.delay(0.5, function()
				Fade:Destroy()

				RunForwardFade = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
					if (Z >= 30) then
						return RunForwardFade:Destroy()
					end

					local Elapsed = (Delta * 60)
					Z = math.min(Z + Elapsed * 6.5, 125)
				end)

				MainJob:Task(RunForwardFade)
			end))

			if EffectUtility.Distance_Far(Model) then
				EffectUtility.Arc.CloneAndEmit(script.Hit["13"], RootPart)
			end

		elseif (Parameter == "14") then
			if RunForwardFade then
				RunForwardFade:Destroy()
			end

			if EffectUtility.Distance_Close(Model) then
				CameraShake(2, 20, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.2)
			end

			Z = 0

			if EffectUtility.Distance_Far(Model) then
				EffectUtility.Arc.CloneAndEmit(script.Hit["14"], RootPart)
			end

		elseif (Parameter == "15") then -- slow mo

			if EffectUtility.Distance_Close(Model) then
				ColorCorrection.Parent = Lighting

				TweenService:Create(ColorCorrection, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{TintColor = Color3.fromRGB(153, 153, 153)}
				):Play()

				CameraShake(2, 10, 0.01, 2, Vector3.one * 0.8)
				Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.4)

				Yuki_FOV.Tween(45, {2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})

				MainJob:Task(function()
					Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
				end)
			end

			EffectUtility.Arc.EmitAttachment(vfx_15)

		elseif (Parameter == "16") then -- final

			if (ColorCorrection.Parent ~= nil) then
				TweenService:Create(ColorCorrection, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{TintColor = Color3.fromRGB(255, 255, 255)}
				):Play()

				Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
			end

			if EffectUtility.Distance_Close(Model) then
				CameraShake(3, 20, 0.01, 1, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.4)
			end

			for _, Effect in pairs(vfx_15:GetDescendants()) do 
				if Effect.ClassName == "ParticleEmitter" then 
					Effect.TimeScale = 0
				end 
			end

			EffectUtility.Arc.CloneAndEmit(script.Hit["16"], RootPart)
		else
			if CurrSlashFade then
				CurrSlashFade:Clean()
				Velocity.Velocity = Vector3.zero
			end

			Z = 45

			CurrSlashFade = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
				if (Z <= 0) then
					return CurrSlashFade:Clean()
				end

				Z = math.max(Z - (Delta * 60) * 1.4, 0)
			end)

			local Effect = script.Hit:FindFirstChild(Parameter)

			if Effect and EffectUtility.Distance_Far(Model) then
				EffectUtility.Arc.CloneAndEmit(Effect, RootPart)
			end

			if EffectUtility.Distance_Close(Model) then
				CameraShake(2, 20, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.2)
			end
		end
	end))
end

local Finisher_Assets = script.Finisher

return {
	-- This is not my proudest work
	
	Finisher = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Finisher)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local MainAnimation, MainJob = Retrieved.Animation, Retrieved.Job

		local Knife = Model:FindFirstChild("Knife")
		local VictimHead : BasePart = VictimModel:FindFirstChild("Head")
		local VictimHumanoid : Humanoid = VictimModel:FindFirstChild("Humanoid")

		local IsLocalSource = (LocalPlayer.Character == Model or LocalPlayer.Character == VictimModel)
		local PlayRareSound = (math.random(1, 15) == 1)
		
		Hit_VFX(Model, VictimModel, Retrieved)

		MainJob:Task(MainAnimation:GetMarkerReachedSignal("finisher"):Connect(function()
			MainJob:Clean() -- Soo hacky, but i had to
			
			local ColorCorrection
			local HeadCutOff = false
			
			local function Toggle_Head(Transparency : number, DoAccessories : boolean)
				if VictimHead then
					VictimHead.Transparency = Transparency

					for _, Item in ipairs(VictimHead:GetChildren()) do
						if Item:IsA("BasePart") or Item:IsA("Decal") then
							Item.Transparency = Transparency
						end
					end
				end
				
				if VictimHumanoid then
					for _, Item in ipairs(VictimHumanoid:GetAccessories()) do
						local Handle = Item:FindFirstChild("Handle")

						if (Handle and (DoAccessories or Handle.AccessoryWeld.Part1 == VictimHead)) then
							Handle.Transparency = Transparency
						end
					end
				end
			end
			
			MainJob:Task(function()
				if not HeadCutOff then
					Toggle_Head(0, true)
				end
			end)
			
			do
				local Velocity = VelocityUtil.Create(RootPart, "HOLDIN THAT BEAM LES GO SEEYUH")
				Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
				Velocity.Parent = RootPart
				MainJob:Task(Velocity)

				local Z = -30

				Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
					if (Z == 0) then
						return Velocity:Destroy()
					end

					Velocity.Velocity = (RootPart.CFrame.LookVector * Z)

					local Elapsed = (Delta * 60) * 0.75
					Z = math.min(Z + Elapsed, 0)
				end)
			end
			
			if IsLocalSource then
				local Camera = MainJob:Task(Finisher_Assets.Camera:Clone())
				Camera:PivotTo(RootPart.CFrame)
				Camera.Parent = workspace.Visuals
				
				local CameraEnabled = true

				ColorCorrection = MainJob:Task(Finisher_Assets.ColorCorrection:Clone())
				ColorCorrection.Enabled = false
				ColorCorrection.Parent = Lighting

				MainJob:Task(MainAnimation:GetMarkerReachedSignal("zoom_scare"):Connect(function(Parameter : string)
					ColorCorrection.Enabled = (Parameter == "start")

					if ColorCorrection.Enabled then
						TweenService:Create(ColorCorrection, TweenInfo.new(3.216666666666667, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
							Contrast = 1.3,
							Saturation = -0.5
						}):Play()
					end
				end))

				local CameraAnimation = Camera.Humanoid.Animator:LoadAnimation(Animations.FinisherCamera)

				MainJob:Task(CameraAnimation:GetMarkerReachedSignal("hide_head"):Connect(function(Parameter : string)
					if not CameraEnabled then return end
					
					local Transparency = (Parameter == "true" and 1 or 0)
					Toggle_Head(Transparency, true)
				end))
				
				local GoALilHigher = false

				MainJob:Task(task.delay(478 / 60, function()
					GoALilHigher = true
				end))

				MainJob:Task(task.delay(562 / 60, function()
					GoALilHigher = false
				end))

				MainJob:Task(CameraAnimation:GetMarkerReachedSignal("camera"):Connect(function()
					LocalPlayer:SetAttribute("CannotCameraShake", true)
					StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
					LocalPlayerGui.Statistics.Enabled = false

					task.spawn(function()
						local IconModule = require(replicatedStorage.packages.Icon)
						IconModule.setTopbarEnabled(false)
					end)

					MainJob:Task(function()
						LocalPlayer:SetAttribute("CannotCameraShake", nil)

						StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
						StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
						LocalPlayerGui.Statistics.Enabled = true

						task.spawn(function()
							local IconModule = require(replicatedStorage.packages.Icon)
							IconModule.setTopbarEnabled(true)
						end)
						
						Camera:Destroy()
					end)

					MainJob:BindToRender("CursedRemedyFinisherHackyCameraOffset", Utility.ShiftlockRenderPriority, function()
						if GoALilHigher then
							Camera:PivotTo(RootPart.CFrame + Vector3.yAxis)
						else
							Camera:PivotTo(RootPart.CFrame)
						end
					end)
					
					RunCameraRig(nil, Camera, CFrame.identity, {
						DontSaveCameraPosition = true,
						
					}, function(Value)
						CameraEnabled = Value
					end)
				end))

				CameraAnimation:Play(0)
				CameraAnimation.TimePosition = MainAnimation.TimePosition
		
				MainJob:Task(Yuki_FOV.AnimateWithMoonFile(Finisher_Assets.FOV))
				
				do
					local Image = "85316557846229"
					local ExtraImageSize = UDim2.fromOffset(15, 15)

					local Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
						ColorSequenceKeypoint.new(0.25, Color3.fromRGB(181, 53, 53)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(109, 32, 32)),
						ColorSequenceKeypoint.new(0.75, Color3.fromRGB(181, 53, 53)),
						ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
					})
					
					local function CreateTaskDelay(Frame : number, Callback : () -> ())
						local Time = (Frame / 60)
						MainJob:Task(task.delay(Time, Callback))
					end
					
					local MinusStart = 382

					CreateTaskDelay(1155 - MinusStart, function()
						TekrinnDialogue.Speak(Model, 

							{
								Text = "Getting tired?",
								Image = Image,
								ExtraImageSize = UDim2.fromOffset(15, 15),
								TextStrokeColor = Color3.new(0, 0, 0),
								Color = Color,
								Shake = {
									Lifetime = 0.5,
									Enabled = true,
									Intensity = 1.5,
								},
								HigherUp = true,
								TypeSpeed = 0.05,
							}, 

							{
								StrokeColor = Color3.new(0, 0, 0),
								Color = Color,
							}, 

							2
						)
					end)

					CreateTaskDelay(1520 - MinusStart, function()
						TekrinnDialogue.Speak(Model, 

							{
								Text = "Sleep tight.",
								Image = Image,
								ExtraImageSize = UDim2.fromOffset(15, 15),
								TextStrokeColor = Color3.new(0, 0, 0),
								Color = Color,
								Shake = {
									Lifetime = 0.5,
									Enabled = true,
									Intensity = 1.5,
								},
								HigherUp = true,
								TypeSpeed = 0.05,
							}, 

							{
								StrokeColor = Color3.new(0, 0, 0),
								Color = Color,
							}, 

							2
						)
					end)
				end
			end

			MainJob:Task(MainAnimation:GetMarkerReachedSignal("fast_block"):Connect(function(Parameter : string)
				EffectUtility.CloneAndEmit(Finisher_Assets.VFX.fast[Parameter], RootPart)
			end))
			
			local Knife_Pulsing_VFX = Finisher_Assets.VFX.pulsing:Clone()
			
			if Knife then
				Knife_Pulsing_VFX.Parent = Knife.BladeInner;
			end;
			
			MainJob:Task(Knife_Pulsing_VFX)
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("stab"):Connect(function(Parameter : string)
				if IsLocalSource then
					Vignette(Color3.fromRGB(0, 0, 0), 0.1, 1)

					ColorCorrection.Saturation = 0
					ColorCorrection.TintColor = Color3.fromRGB(255, 197, 197)
					ColorCorrection.Contrast = 1
					ColorCorrection.Enabled = true
					
					Lighting.ExposureCompensation = 0.8
					
					TweenService:Create(ColorCorrection, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Contrast = 0, TintColor = Color3.fromRGB(255, 255, 255)}):Play()
					TweenService:Create(Lighting, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ExposureCompensation = 0}):Play()
				end

				EffectUtility.Arc.ToggleAttachment(Knife_Pulsing_VFX, true)
				EffectUtility.Arc.CloneAndEmit(Finisher_Assets.VFX.stab, RootPart)
			end))
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal("cut"):Connect(function(Parameter : string)
				if IsLocalSource then
					Vignette(Color3.fromRGB(0, 0, 0), 0, 1)

					ColorCorrection.Saturation = 0
					ColorCorrection.TintColor = Color3.fromRGB(255, 165, 165)
					ColorCorrection.Contrast = 1.4
					ColorCorrection.Enabled = true
					
					Lighting.ExposureCompensation = 1.5

					TweenService:Create(ColorCorrection, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Contrast = 0, TintColor = Color3.fromRGB(255, 255, 255)}):Play()
					TweenService:Create(Lighting, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ExposureCompensation = 0}):Play()
				end
				
				task.spawn(function()
					if not LocalPlayer:GetAttribute("Blood") then
						return -- DOESN'T SHOW IF BLOOD SETTING IS OFF TO SUPPORT CONTENT MATURITY
					end
					
					HeadCutOff = true
					
					local Clone_Head = VictimHead:Clone()
		
					local BottomAttachment = Instance.new("Attachment")
					BottomAttachment.CFrame = CFrame.new(0, -0.6, 0)
					BottomAttachment.Parent = Clone_Head
					
					for _, Item in ipairs(VictimHumanoid:GetAccessories()) do
						local Handle = Item:FindFirstChild("Handle")

						if Handle then
							local OriginalWeld = Handle:FindFirstChild("AccessoryWeld")
		
							if (OriginalWeld and OriginalWeld.Part1 == VictimHead) then
								local NewHandle = Handle:Clone()
								NewHandle.Anchored = false
								NewHandle.Transparency = 0
								
								NewHandle.AccessoryWeld.Part0 = NewHandle
								NewHandle.AccessoryWeld.Part1 = Clone_Head
			
								NewHandle.Parent = Clone_Head
							end
						end
					end

					Clone_Head.CFrame = VictimHead.CFrame
					Clone_Head.Name = "FakeHead"
					Clone_Head.CanCollide = true
					
					Clone_Head.Parent = workspace.Visuals
					
					Clone_Head.AssemblyLinearVelocity = Vector3.new(
						-35,
						Utility.Seed:NextNumber(-5, 10),
						0
					)
					
					Clone_Head.AssemblyAngularVelocity = Vector3.new(
						Utility.Seed:NextNumber(-5, 5),
						Utility.Seed:NextNumber(-5, 5),
						Utility.Seed:NextNumber(-5, 5)
					)
					
					task.spawn(function()
						while (Clone_Head and Clone_Head.Parent) do
							Clone_Head.Transparency = 0
							Clone_Head.face.Transparency = 0
			
							Blood.BloodRaysWithoutPreset(BottomAttachment, {
								Face = Enum.NormalId.Top,
								SpreadAngle = Vector2.new(180, 180), 
								Amount = Vector2.new(3, 4), 
							})

							if VictimModel and VictimModel.Parent then
								Blood.BloodRaysWithoutPreset(VictimModel.Torso.NeckAttachment, {
									Face = Enum.NormalId.Top,
									SpreadAngle = Vector2.new(180, 180), 
									Amount = Vector2.new(3, 4), 
								})
							end
						
							task.wait(0.1)
						end
					end)

					task.delay(10, Clone_Head.Destroy, Clone_Head)
					task.defer(Toggle_Head, 1)
				end)

				EffectUtility.Arc.ToggleAttachment(Knife_Pulsing_VFX, false)
				EffectUtility.Arc.CloneAndEmit(Finisher_Assets.VFX.cut, RootPart)
			end))

			MainJob:Task(MainAnimation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
				if (Parameter == "startcatch") then
					MainJob:Task(EffectUtility.AddSFX(Finisher_Assets.SFX[PlayRareSound and "Rare" or "Normal"], IsLocalSource and workspace or Torso, 0.4))
				end
				
				if IsLocalSource then

					if (Parameter == "hit3") then
						Lighting.ExposureCompensation = 1
						TweenService:Create(Lighting, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ExposureCompensation = 0}):Play()
						Vignette(Color3.fromRGB(0, 0, 0), 0.3, 0.5)
						
					elseif (Parameter == "hit1" or Parameter == "hit2") then
						Lighting.ExposureCompensation = 0.25
						TweenService:Create(Lighting, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ExposureCompensation = 0}):Play()
						Vignette(Color3.fromRGB(0, 0, 0), 0.5, 0.5, true)
					end
				end

				local VFX = Finisher_Assets.VFX:FindFirstChild(Parameter)
				if (VFX == nil) then return warn("this not valid buddy") end

				local Attached = VFX:GetAttribute("attached")
				local Person = VFX:GetAttribute("person")

				if (Knife and Person == "knife") then

					if (Parameter == "rotate") then
						local New_VFX = VFX:Clone()
						New_VFX.Parent = Knife.BladeInner
						EffectUtility.Arc.ToggleAttachment(New_VFX, true, 0.6)
						task.delay(2, New_VFX.Destroy, New_VFX)
					else
						EffectUtility.Arc.CloneAndEmit(VFX, Knife.BladeInner)
					end

				else
					local Parent = (Person == "attacker" and Model) or (Person == "victim" and VictimModel)
					EffectUtility.Arc.CloneAndEmit(VFX, Parent[Attached])
				end
			end))

			task.spawn(function()
				local VictimRetrieved = AnimationRetriever.new(VictimModel, Animations.FinisherVictim)
				if (VictimRetrieved == nil) then return end

				VictimRetrieved.Job:Task(VictimRetrieved.Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
					if (Parameter == "wipe") then
						EffectUtility.Arc.CloneAndEmit(Finisher_Assets.VFX.wipe, VictimHead)
					end
				end))
			end)
		end))
	end,
	
	Hit = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Hit)
		if (Retrieved == nil) then return end
		
		Hit_VFX(Model, VictimModel, Retrieved)

		--local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		--local Animation, MainJob = Retrieved.Animation, Retrieved.Job

		--MainJob:Task(EffectUtility.AddSFX(script.HitSFX, Torso, 0.3))

		--local Velocity = VelocityUtil.Create(RootPart, "HOLDIN THAT BEAM LES GO SEEYUH")
		--Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
		--Velocity.Parent = RootPart

		--local Z = 0

		--Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
		--	Velocity.Velocity = (RootPart.CFrame.LookVector * Z)
		--end)

		--MainJob:Task(Velocity)

		--local vfx_15 = script.Hit["15"]:Clone()
		--vfx_15.Parent = RootPart

		--MainJob:Task(Animation:GetMarkerReachedSignal("slow"):Connect(function(Parameter : string)
		--	local Slow = (Parameter == "true")
		--	local Info = TweenInfo.new(Slow and 0.25 or 0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

		--	for _, Effect in pairs(vfx_15:GetDescendants()) do 
		--		if Effect.ClassName == "ParticleEmitter" then 
		--			TweenService:Create(Effect, Info, {TimeScale = Slow and 0 or 1}):Play()
		--		end 
		--	end
		--end))

		--MainJob:Task(Animation:GetMarkerReachedSignal("barrage"):Connect(function(Parameter : string)
		--	if EffectUtility.Distance_Far(Model) then
		--		local Effect = script.Hit.barrage:Clone()
		--		Effect.Parent = workspace.Visuals
		--		EffectUtility.Weld(Effect, VictimModel.Head)
		--		EffectUtility.Arc.EmitAttachment(Effect)
		--	end

		--	if EffectUtility.Distance_Close(Model) then
		--		local Shake = CameraShake(1.5, 30, 0.01, 0, Vector3.one * 0.8, Vector3.one * 0.4)

		--		if Shake then
		--			task.delay(1, function()
		--				Shake:StartFadeOut(0.5)
		--			end)
		--		end
		--	end
		--end))

		--local CurrSlashFade
		--local RunForwardFade
		
		--local ColorCorrection = Instance.new("ColorCorrectionEffect")
		--MainJob:Task(ColorCorrection)
		
		--MainJob:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)

		--	if (Parameter == "13") then
		--		if CurrSlashFade then
		--			CurrSlashFade:Destroy()
		--		end

		--		if EffectUtility.Distance_Close(Model) then
		--			CameraShake(2, 20, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.3)
		--			Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.2)
		--		end

		--		Z = -60

		--		local Fade; Fade = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
		--			if (Z == 0) then
		--				return Fade:Destroy()
		--			end

		--			local Elapsed = (Delta * 60)
		--			Z = math.min(Z + Elapsed * 0.75, 0)
		--		end)

		--		MainJob:Task(Fade)

		--		MainJob:Task(task.delay(0.5, function()
		--			Fade:Destroy()

		--			RunForwardFade = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
		--				if (Z >= 30) then
		--					return RunForwardFade:Destroy()
		--				end

		--				local Elapsed = (Delta * 60)
		--				Z = math.min(Z + Elapsed * 6.5, 125)
		--			end)

		--			MainJob:Task(RunForwardFade)
		--		end))

		--		if EffectUtility.Distance_Far(Model) then
		--			EffectUtility.Arc.CloneAndEmit(script.Hit["13"], RootPart)
		--		end
				
		--	elseif (Parameter == "14") then
		--		if RunForwardFade then
		--			RunForwardFade:Destroy()
		--		end
				
		--		if EffectUtility.Distance_Close(Model) then
		--			CameraShake(2, 20, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.3)
		--			Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.2)
		--		end

		--		Z = 0

		--		if EffectUtility.Distance_Far(Model) then
		--			EffectUtility.Arc.CloneAndEmit(script.Hit["14"], RootPart)
		--		end

		--	elseif (Parameter == "15") then -- slow mo
				
		--		if EffectUtility.Distance_Close(Model) then
		--			ColorCorrection.Parent = Lighting

		--			TweenService:Create(ColorCorrection, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		--				{TintColor = Color3.fromRGB(153, 153, 153)}
		--			):Play()
					
		--			CameraShake(2, 10, 0.01, 2, Vector3.one * 0.8)
		--			Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.4)
					
		--			Yuki_FOV.Tween(45, {2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
					
		--			MainJob:Task(function()
		--				Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
		--			end)
		--		end
				
		--		EffectUtility.Arc.EmitAttachment(vfx_15)

		--	elseif (Parameter == "16") then -- final
				
		--		if (ColorCorrection.Parent ~= nil) then
		--			TweenService:Create(ColorCorrection, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		--				{TintColor = Color3.fromRGB(255, 255, 255)}
		--			):Play()
					
		--			Yuki_FOV.Tween(70, {0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
		--		end
				
		--		if EffectUtility.Distance_Close(Model) then
		--			CameraShake(3, 20, 0.01, 1, Vector3.one * 0.8, Vector3.one * 0.3)
		--			Vignette(Color3.fromRGB(255, 0, 0), 0.35, 0.4)
		--		end
				
		--		for _, Effect in pairs(vfx_15:GetDescendants()) do 
		--			if Effect.ClassName == "ParticleEmitter" then 
		--				Effect.TimeScale = 0
		--			end 
		--		end

		--		EffectUtility.Arc.CloneAndEmit(script.Hit["16"], RootPart)
		--	else
		--		if CurrSlashFade then
		--			CurrSlashFade:Clean()
		--			Velocity.Velocity = Vector3.zero
		--		end

		--		Z = 45

		--		CurrSlashFade = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
		--			if (Z <= 0) then
		--				return CurrSlashFade:Clean()
		--			end

		--			Z = math.max(Z - (Delta * 60) * 1.4, 0)
		--		end)

		--		local Effect = script.Hit:FindFirstChild(Parameter)

		--		if Effect and EffectUtility.Distance_Far(Model) then
		--			EffectUtility.Arc.CloneAndEmit(Effect, RootPart)
		--		end

		--		if EffectUtility.Distance_Close(Model) then
		--			CameraShake(2, 20, 0.01, 0.15, Vector3.one * 0.8, Vector3.one * 0.3)
		--			Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.2)
		--		end
		--	end
		--end))
	end,

	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, MainJob = Retrieved.Animation, Retrieved.Job

		local IsMainPlayer = (LocalPlayer.Character == Model)

		MainJob:Task(EffectUtility.AddSFX(script.StartupSFX, Torso, 0.2))

		local Z = 0
		local X = 0

		local Velocity = VelocityUtil.Create(RootPart, "HOLDIN THAT BEAM LES GO")
		Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
		Velocity.Parent = RootPart

		Utility.BindSignalDisconnectToInstanceDestroying(RunService.PostSimulation, Velocity, function(Delta : number)
			Velocity.Velocity = (RootPart.CFrame.LookVector * Z) + (RootPart.CFrame.RightVector * X)
		end)

		local FadeOutJob

		MainJob:Task(FadeOutJob)
		MainJob:Task(Velocity)

		if IsMainPlayer then
			MainJob:Task(function()
				Yuki_FOV.Tween(70, {0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
			end)
		end

		local BodyEffects = {}

		for _, Item in ipairs(script.WindupBody:GetChildren()) do
			for _, Attachment in ipairs(Item:GetChildren()) do
				local New = Attachment:Clone()
				New.Parent = Model[Item.Name]
				BodyEffects[New] = true
			end
		end

		MainJob:Task(function()
			for Effect in BodyEffects do
				EffectUtility.Arc.ToggleAttachment(Effect, false)
				task.delay(1, Effect.Destroy, Effect)
			end
		end)

		if IsMainPlayer then
			Yuki_FOV.Tween(60, {0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
		end

		local ThirdDash = true

		MainJob:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
			local Effect = script.Windup:FindFirstChild(Parameter)

			if Effect and EffectUtility.Distance_Far(Model) then
				EffectUtility.Arc.CloneAndEmit(Effect, RootPart)
			end

			if EffectUtility.Distance_Close(Model) then
				CameraShake(4, 40, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.4)
				Vignette(Color3.fromRGB(255, 0, 0), 0.25, 0.3)
				--Yuki_FOV.Tween(60, {0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, true})
			end

			local Dash_X_Scale = 1.5
			local Dash_X_Fade = 3

			if (Parameter == "1") then
				X = 50 * Dash_X_Scale
				Z = 60

				if FadeOutJob then
					FadeOutJob:Clean()
				end

				FadeOutJob = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
					local Elapsed = (Delta * 60)
					X = math.max(X - Elapsed * Dash_X_Fade, 0)
					Z = math.max(Z - Elapsed * 2, 0)
				end)

				if IsMainPlayer and ThirdDash then
					Yuki_FOV.Set(70)
					Yuki_FOV.Tween(80, {0.075, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, true})
				end

			elseif (Parameter == "2") then
				X = -94.5 * Dash_X_Scale
				Z = 60

				if FadeOutJob then
					FadeOutJob:Clean()
				end

				FadeOutJob = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
					local Elapsed = (Delta * 60)

					X = math.min(X + Elapsed * Dash_X_Fade, 0)
					Z = math.max(Z - Elapsed * 2, 0)
				end)

				if IsMainPlayer then
					Yuki_FOV.Set(70)
					Yuki_FOV.Tween(80, {0.075, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, true})
					ThirdDash = true
				end

			elseif (Parameter == "3") then
				X = 0
				Z = 65

				if FadeOutJob then
					FadeOutJob:Clean()
				end

				FadeOutJob = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
					Z = math.max(Z - (Delta * 60) * 1.15, 0)

					if (Z <= 0) then
						FadeOutJob:Destroy()
					end
				end)

				MainJob:Task(task.delay(0.3, function()
					while Z > 7.5 do
						RockHandler.Rocks("Side Dash", RootPart)
						Smoke(RootPart, 5, 2)

						task.wait(0.045)
					end
				end))

				if IsMainPlayer then
					Yuki_FOV.Set(70)
					Yuki_FOV.Tween(85, {0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out})

					task.delay(0.1, function()
						Yuki_FOV.Tween(70, {0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out})
					end)
				end
			end
		end))
	end,
}