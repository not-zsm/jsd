local replicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = replicatedStorage.Animations.Attacks.Chara.Fight

local AttributeListener = require( replicatedStorage.modules.client.replication.Global.AttributeListener )

---------------------------------------------------------------------

local RockHandler = require( replicatedStorage.modules.client.replication.Global.RockHandler )
local CameraShake = require( replicatedStorage.modules.client.replication.Global.CameraShake )
local Vignette = require( replicatedStorage.modules.client.replication.Global.Vignette )
local Blood = require( replicatedStorage.modules.client.replication.Global.Blood )

local Yuki_FOV = require( replicatedStorage.modules.client.replication.Global.Yuki_FOV )

local Afterimage = require( replicatedStorage.modules.client.replication.Global.Afterimage )
local ATrainAfterimage = require( replicatedStorage.modules.client.replication.Global.ATrainAfterimage )

local RunCameraRig = require( replicatedStorage.modules.client.replication.Global.RunCameraRig )

local Chara_Assets = replicatedStorage.modules.effect.assets.Characters.Chara

---------------------------------------------------------------------

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local VelocityUtil = require( replicatedStorage.modules.shared.Game.Velocity.VelocityUtil )

---------------------------------------------------------------------

local Fight_UI = require( replicatedStorage.modules.effect.assets.Characters.Chara.Fight_UI )

local function Hit_VFX(Model : Model, AnimationName : string, Finisher : boolean)
	local Retrieved = AnimationRetriever.new(Model, Animations[AnimationName])
	if (Retrieved == nil) then return end

	local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
	local Animation, MainJob = Retrieved.Animation, Retrieved.Job

	if not Finisher then
		MainJob:Task(EffectUtility.AddSFX(script.HitSFX, Torso, 0.3))
	end
	
	local IsChara = (LocalPlayer.Character == Model)

	if IsChara then
		MainJob:Task(Animation:GetMarkerReachedSignal("attack"):Once(function()
			local FightRemote : RemoteEvent? = Model:FindFirstChild("CharaFightRemote")
			if (FightRemote == nil) then return end
			
			Fight_UI(Model, FightRemote, Enum.KeyCode.Four, MainJob)
			
			--local FightRemote : RemoteEvent? = Model:FindFirstChild("CharaFightRemote")
			--if (FightRemote == nil) then return end

			--SoundService:PlayLocalSound(Chara_Assets.QTE.UI_SFX.Appear)

			--local UI = Chara_Assets.QTE.UI:Clone()
			--UI.Parent = LocalPlayer.PlayerGui

			--do
			--	TweenService:Create(UI.Bar, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			--		{ImageTransparency = 0, BackgroundTransparency = 0}
			--	):Play()

			--	TweenService:Create(UI.Bar.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			--		{Transparency = 0}
			--	):Play()

			--	TweenService:Create(UI.Bar.Line, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			--		{BackgroundTransparency = 0}
			--	):Play()

			--	TweenService:Create(UI.Bar.Line.UIStroke, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			--		{Transparency = 0}
			--	):Play()
			--end

			--local AttackTime = Utility.Seed:NextNumber(0.7, 1)

			----local MinRange = (AttackTime / 2.4)
			----local MaxRange = (AttackTime / 1.6)

			--local MinRange = (AttackTime / 2.2)
			--local MaxRange = (AttackTime / 1.8)

			--local Start = time()

			--local LineTween = TweenService:Create(UI.Bar.Line, TweenInfo.new(AttackTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
			--	{Position = UDim2.fromScale(1, 0.489)}
			--)

			--local function InRange() : boolean
			--	local Elapsed = (time() - Start)

			--	return 
			--		(Elapsed > MinRange) and
			--		(Elapsed < MaxRange)
			--end

			--local InputJob = Job.Extend(MainJob)

			--local function Trigger()
			--	InputJob:Destroy()
			--	LineTween:Pause()

			--	local WasInRange = InRange()

			--	if WasInRange then
			--		TweenService:Create(UI.Bar, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true),
			--			{Size = UI.Bar.Size + UDim2.fromScale(0.0085, 0.0085)}
			--		):Play()

			--		Vignette(Color3.fromRGB(0, 255, 0), 0.75, 0.15)
			--		SoundService:PlayLocalSound(Chara_Assets.QTE.UI_SFX.Success)

			--		UI.Bar.Line.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			--	else
			--		Vignette(Color3.fromRGB(255, 0, 0), 0.75, 0.15)
			--		SoundService:PlayLocalSound(Chara_Assets.QTE.UI_SFX.Miss)

			--		UI.Bar.Line.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			--	end

			--	UI.Bar.Line.Size += UDim2.fromScale(0.01, 0.1)

			--	TweenService:Create(UI.Bar.Line, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			--		{BackgroundTransparency = 1, Size = UDim2.fromScale(0, 0)}
			--	):Play()

			--	TweenService:Create(UI.Bar.Line.UIStroke, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			--		{Transparency = 1}
			--	):Play()

			--	FightRemote:FireServer(WasInRange)
			--end

			--InputJob:Task(UserInputService.InputBegan:Connect(function(Input)
			--	if (Input.KeyCode == Utility.KeyboardToControllerInputs[Enum.KeyCode.Four]) or (Input.KeyCode == Enum.KeyCode.Four) then
			--		Trigger()
			--	end
			--end))

			--InputJob:Task(UI.Bar.Hitbox.MouseButton1Click:Connect(Trigger))

			--LineTween:Play()

			--MainJob:Task(function()
			--	local GoTween = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

			--	TweenService:Create(UI.Bar, GoTween, {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
			--	TweenService:Create(UI.Bar.UIStroke, GoTween, {Transparency = 1}):Play()
			--	TweenService:Create(UI.Bar.Line, GoTween, {BackgroundTransparency = 1}):Play()
			--	TweenService:Create(UI.Bar.Line.UIStroke, GoTween, {Transparency = 1}):Play()

			--	task.delay(GoTween.Time, UI.Destroy, UI)
			--end)
		end))
	end

	MainJob:Task(Animation:GetMarkerReachedSignal("vfx"):Connect(function(Parameter : string)
		local Effect = script.Assets:FindFirstChild(Parameter)

		if Effect and EffectUtility.Distance_Far(Model) then
			EffectUtility.Arc.CloneAndEmit(Effect, Model[Effect:GetAttribute("attached")])
		end

		if EffectUtility.Distance_Close(Model) then
			if (Parameter == "1") then
				CameraShake(1, 15, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.4)
				Vignette(Color3.fromRGB(255, 0, 0), 0.8, 0.2)

			elseif (Parameter == "2") then
				CameraShake(1, 15, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.4)
				Vignette(Color3.fromRGB(255, 0, 0), 0.8, 0.2)
			end
		end
	end))

	EffectUtility.Arc.CloneAndEmit(script.Assets["1"], RootPart)

	if EffectUtility.Distance_Close(Model) then
		CameraShake(1.25, 22.5, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.25)
		Vignette(Color3.fromRGB(255, 0, 0), 0.6, 0.25)
	end
	
	return Retrieved
end

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		Retrieved.Job:Task(EffectUtility.AddSFX(script.StartupSFX, Retrieved.Torso, 0.3))
	end,

	Hit = function(Model : Model)
		Hit_VFX(Model, "Hit")
	end,
	
	Finisher = function(Model : Model)
		local Retrieved = Hit_VFX(Model, "Finisher", true)
		if (Retrieved == nil) then return end
		
		local Torso : BasePart, RootPart : BasePart = Retrieved.Torso, Retrieved.RootPart
		local Animation : AnimationTrack, MainJob : Job.object = Retrieved.Animation, Retrieved.Job

		if (LocalPlayer.Character == Model) then
			local CameraJob = Job.new()
			local Camera = script.Finisher.Camera:Clone()
			local CF = script.Finisher.Camera:GetPivot()

			Camera.Parent = workspace.Visuals

			local CameraAnimation = Camera.Humanoid.Animator:LoadAnimation(Animations.FinisherCamera)
			CameraAnimation:Play(0)

			MainJob:Task(Animation:GetMarkerReachedSignal("hit"):Connect(function()
				RunCameraRig(RootPart, Camera, CF)
			end))

			Camera.AncestryChanged:Once(function()
				CameraJob:Destroy()
			end)

			CameraJob:Task(CameraAnimation.Stopped:Once(function()
				Camera:Destroy()
			end))

			MainJob:Task(Animation:GetMarkerReachedSignal("cut"):Connect(function()
				Camera:Destroy()
			end))

			CameraJob:Task(AttributeListener.new(Model, "GrowABlueGarden", function()
				Camera:Destroy()
			end))
		end
	end,
	
	Slash = function(Model : Model, InRange : boolean)
		local Retrieved = AnimationRetriever.new(Model, Animations.Hit)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, MainJob = Retrieved.Animation, Retrieved.Job
		
		if EffectUtility.Distance_Far(Model) then
			EffectUtility.Arc.CloneAndEmit(
				script.Assets[InRange and "3_success" or "3_fail"], 
				RootPart
			)
		end
		
		if EffectUtility.Distance_Close(Model) then
			if InRange then
				EffectUtility.AddSFX(script.SuccessHitSFX, Torso)
				
				CameraShake(2.5, 37.5, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.fromRGB(255, 0, 0), 0.25, 0.4)
			else
				EffectUtility.AddSFX(script.MissHitSFX, Torso)
				
				CameraShake(1.75, 27.5, 0.01, 0.25, Vector3.one * 0.8, Vector3.one * 0.3)
				Vignette(Color3.fromRGB(255, 0, 0), 0.5, 0.4)
			end
		end
	end,
}