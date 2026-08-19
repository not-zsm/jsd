local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer.PlayerGui

----------------------------------------------------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Mori["Renewal Taekwondo"]

----------------------------------------------------------------------------------------------------------------

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

----------------------------------------------------------------------------------------------------------------

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

----------------------------------------------------------------------------------------------------------------

local RunCameraRig = require( ReplicatedStorage.Modules.Player.Replication.Global.RunCameraRig )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )

----------------------------------------------------------------------------------------------------------------

local BugoVFX = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo )
local VelocityUtil = require( ReplicatedStorage.Modules.Shared.Game.Velocity.VelocityUtil )

----------------------------------------------------------------------------------------------------------------

local ImpactFrames = LocalPlayerGui.ImpactFrames.Mori_RT_Finisher

local Jin_Color = Color3.fromRGB(84, 144, 255)

local IndexToVFX = {
	["1"] = "KickStart",
	["2"] = "LittleSwirl",
	["3"] = "Bounce", 
	["4"] = "Bounce",
	["5"] = "RunStartUp",
	["7"] = "Bounce",
	["8"] = "Bounce",
	["10"] = "Slam",
	["11"] = "MeshForIgnite",
	["12"] = "BigSwirl",
	["14"] = "DragonSpawn",
	["19"] = "LaunchSlash",
}

----------------------------------------------------------------------------------------------------------------

return {
	["Start"] = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Finisher)
		if (Retrieved == nil) then return end

		local RootPart = Retrieved.RootPart
		local MainAnimation = Retrieved.Animation
		local MainJob = Retrieved.Job
		
		local IsMainPlayer = (LocalPlayer.Character == Model)
		local ShowCamera = (IsMainPlayer or LocalPlayer.Character == VictimModel)
		
		local Ended = false
		
		local Auras = {}
		
		local function ClearAuras()
			for Aura in Auras do
				Aura:Destroy()
			end

			table.clear(Auras)
		end
		
		MainJob:Task(function()
			if not Ended then
				ClearAuras()
			else
				task.delay(0.75, function()
					for Aura in Auras do
						Aura.Enabled = false
					end

					task.delay(2, ClearAuras)
				end)
			end
		end)

		local SFX = EffectUtility.AddSFX(script.SFX, Retrieved.Torso, 0.35)

		MainJob:Task(function()
			if not Ended then
				SFX:Destroy()
			end
		end)
		
		local Camera = script.Camera:Clone()
		MainJob:Task(Camera)

		if ShowCamera then
			EffectUtility.ToggleImpactFrames(ImpactFrames, true)
			
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			LocalPlayerGui.Statistics.Enabled = false

			task.spawn(function()
				local IconModule = require(ReplicatedStorage.Modules.Icon)
				IconModule.setTopbarEnabled(false)
			end)

			MainJob:Task(function()
				EffectUtility.ToggleImpactFrames(ImpactFrames, false)
				
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
				LocalPlayerGui.Statistics.Enabled = true

				task.spawn(function()
					local IconModule = require(ReplicatedStorage.Modules.Icon)
					IconModule.setTopbarEnabled(true)
				end)
			end) 

			Camera:PivotTo(RootPart.CFrame * CFrame.new(0, -3, 0))
			Camera.Parent = workspace.Visuals
			Camera.AnimationController.Animator:LoadAnimation(Animations.FinisherCamera):Play(0)

			local RemoveFOVRunner = MainJob:Task(Yuki_FOV.AnimateWithMoonFile(script.FOV))
			Camera.Destroying:Once(RemoveFOVRunner)

			MainJob:Task(RunCameraRig(RootPart, Camera, CFrame.new(0, -3, 0)))
		end

		local RunVFX = script.VFX.RunEnabled.Emit.DashWind:Clone()
		MainJob:Task(RunVFX)
		
		do
			EffectUtility.Weld(RunVFX, RootPart)
			RunVFX.Parent = workspace.Visuals
		end
		
		local Dragon = script.Dragon:Clone()
		MainJob:Task(Dragon)

		do
			EffectUtility.Weld(Dragon, RootPart, CFrame.new(0, -3, 0) * CFrame.Angles(0, math.pi, 0))
			
			for _, Item in ipairs(Dragon:GetDescendants()) do
				if Item:IsA("BasePart") then
					Item.Transparency = 1
				end
			end

			Dragon.Parent = workspace.Visuals
			Dragon.AnimationController.Animator:LoadAnimation(Animations.FinisherDragon):Play(0)
		end

		local Multiply = 0

		local Velocity = VelocityUtil.Create(RootPart, "Kitty.")
		Velocity.MaxForce = Vector3.new(1, 0, 1) * 80000
		Velocity.Parent = RootPart
	
		MainJob:Task(Velocity)
		
		local BlowJobs

		local function VFX(Parameter : string)
			if (Parameter == "6") then
				
				if IsMainPlayer then
					
					local MaxVel = 70
					local Time = 2
					
					BlowJobs = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
						if (Multiply == MaxVel) then
							return BlowJobs:Clean()
						end
						
						Multiply = math.clamp(Multiply + (Delta * 60) * Time, 0, MaxVel)
						Velocity.Velocity = (-RootPart.CFrame.RightVector) * Multiply
					end)
				end
				
				for _, particle in pairs(RunVFX:GetDescendants()) do
					if particle:IsA("ParticleEmitter") then
						particle.Enabled = true
					end
				end
				
			elseif (Parameter == "9") then
				for _, particle in pairs(RunVFX:GetDescendants()) do
					if particle:IsA("ParticleEmitter") then
						particle.Enabled = false
					end
				end
				
				if BlowJobs then
					BlowJobs:Clean()
				end
				
				local Time = 1.4
				
				BlowJobs = Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreSimulation, Velocity, function(Delta : number)
					if (Multiply <= 0) then
						return BlowJobs:Clean()
					end
					
					Multiply = math.max(0, Multiply - (Delta * 60) * Time)
					Velocity.Velocity = (-RootPart.CFrame.RightVector) * Multiply
				end)
				
			elseif (Parameter == "13") then
				for _, particle in pairs(Dragon.RootPart.Bone.VFXFAKEPART:GetDescendants()) do
					if particle:IsA("ParticleEmitter") then
						particle.Enabled = true
					end
				end

				for _, Item in ipairs(script.LegAura:GetChildren()) do
					local NewAura = Item:Clone()
					NewAura.Parent = Model["Right Leg"]
					NewAura.Enabled = true
					Auras[NewAura] = true
				end
				
			elseif (Parameter == "15") then
				for _, particle in pairs(Dragon.RootPart.Bone.LowerMouth.def5:GetDescendants()) do
					if particle:IsA("ParticleEmitter") then
						particle.Enabled = true
					end
				end
				
			elseif (Parameter == "16") then
				for _, particle in pairs(Dragon.RootPart.Bone.VFXFAKEPART.VfxRealPart.BeamAttachment:GetDescendants()) do
					if particle:IsA("Beam") then
						particle.Enabled = true
					end
				end
				
			elseif (Parameter == "17") then
				for _, particle in pairs(Dragon.RootPart.Bone.LowerMouth.def5:GetDescendants()) do
					if particle:IsA("ParticleEmitter") then
						particle.Enabled = false
					end
				end

				if ShowCamera then
					EffectUtility.EmitImpactFrames(ImpactFrames, 24)
				end
				
			elseif (Parameter == "18") then
				for _, particle in pairs(Dragon.RootPart.Bone.VFXFAKEPART.VfxRealPart.BeamAttachment:GetDescendants()) do
					if particle:IsA("Beam") then
						particle.Enabled = false
					end
				end
				
			elseif (Parameter == "20") then
				Ended = true

				Camera:Destroy()
				
				if EffectUtility.Distance_Close(Model, 45) then
					CameraShake(3.5, 35, 0.01, 0.75, Vector3.one * 0.8, Vector3.one * 0.3)
					Vignette(Jin_Color, 0.5, 0.45)
				end
				
				BugoVFX(script.VFX.Explode, RootPart)

				for _, particle in pairs(Dragon.RootPart.Bone.VFXFAKEPART:GetDescendants()) do
					if particle:IsA("ParticleEmitter") then
						particle.Enabled = false
					end
				end
				
				local Info = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

				for _, Item in ipairs(Dragon:GetDescendants()) do
					if Item:IsA("BasePart") then
						TweenService:Create(Item, Info, {Transparency = 1}):Play()
					end
				end

				local EndAnimation = Retrieved.Animator:LoadAnimation(Animations.FinisherEnd)
				MainAnimation:Stop(0)
				RootPart.CFrame *= CFrame.new(-9.401, 0, -0.52)
				EndAnimation:Play(0)
			else
				local VFX_Name = IndexToVFX[Parameter]
				
				if VFX_Name then
					BugoVFX(script.VFX[VFX_Name], RootPart)
				end
			end
		end

		for Index = 1, 20 do
			local Name = tostring(Index)
			
			MainJob:Task(MainAnimation:GetMarkerReachedSignal(Name):Connect(function()
				VFX(Name)
			end))
		end

		MainJob:Task(MainAnimation:GetMarkerReachedSignal("dragon"):Once(function()
			local Info = TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			for _, Item in ipairs(Dragon:GetDescendants()) do
				if Item:IsA("BasePart") and Item.Name ~= "RootPart" and not string.find(string.lower(Item.Name), "vfx") then
					TweenService:Create(Item, Info, {Transparency = 0}):Play()
				end
			end
		end))
	end,
}