local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

-------------------------------------------------------------------------------

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

-------------------------------------------------------------------------------

local VFX = script.VFX
local CraterDirection = Vector3.yAxis * -15

local function Emit(vfx : BasePart, root : BasePart, offset : CFrame)
	local new_vfx = vfx:Clone()
	new_vfx.CFrame = root.CFrame * (offset or (vfx.CFrame - Vector3.yAxis * 3))
	new_vfx.Parent = workspace.Visuals
	EffectUtility.Arc.EmitAttachment(new_vfx)
end

-------------------------------------------------------------------------------

return {
	OnWindup = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model,
			ReplicatedStorage.Animations.Attacks.Accelerator["Tectonic Control"].Variant
		)
		
		if (Retrieved == nil) then return end

		local Animation = Retrieved.Animation
		local Job = Retrieved.Job

		local Humanoid = Retrieved.Humanoid
		local RootPart = Retrieved.RootPart

		Job:Task(Animation:GetMarkerReachedSignal("tp"):Connect(function()
			Emit(VFX.speed, RootPart)
		end))
	end,
	
	OnHit = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model,
			ReplicatedStorage.Animations.Attacks.Accelerator["Tectonic Control"].VariantHit
		)
		
		if (Retrieved == nil) then return end

		local Animation = Retrieved.Animation
		local Job = Retrieved.Job

		local Humanoid = Retrieved.Humanoid
		local RootPart = Retrieved.RootPart

		local lightning = VFX.lightning:Clone()
		lightning.Parent = workspace.Visuals
		EffectUtility.Weld(lightning, RootPart, VFX.lightning.CFrame - Vector3.yAxis * 3)
		EffectUtility.Arc.ToggleAttachment(lightning, true)

		Job:Task(lightning)
		
		local Distance = 0
		
		local function SetDistance()
			Distance = LocalPlayer:DistanceFromCharacter(RootPart.Position)
		end
		
		SetDistance()
		
		local function ScreenEffect(Contrast : number, Time : number)
			if (Distance <= 25) then
				local Color = script.ColorCorrection:Clone()
				Color.Contrast = Contrast
				Color.Parent = Lighting

				TweenService:Create(Color, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Contrast = 0}
				):Play()

				task.delay(Time, Color.Destroy, Color)
			end
		end

		Job:Task(Animation:GetMarkerReachedSignal("fling"):Connect(function()
			SetDistance()
			ScreenEffect(1.6, 0.4)
			
			if (Distance <= 25) then
				CameraShake(2, 25, 0.01, 0.4, Vector3.one * 0.8, 0.15)
			end
			
			EffectUtility.Arc.ToggleAttachment(lightning, false)
			Emit(VFX.knockback, RootPart)
		end))
		
		SetDistance()
		ScreenEffect(0.75, 0.35)
		Emit(VFX.hit, RootPart)
		
		if (Distance <= 25) then
			CameraShake(1.35, 20, 0.01, 0.75, Vector3.one * 0.8, 0.2)
		end
	end,
	
	OnFling = function(VictimModel : Model)
		local Retrieved = AnimationRetriever.new(VictimModel,
			ReplicatedStorage.Animations.Attacks.Accelerator["Tectonic Control"].VariantVictimFling
		)

		if (Retrieved == nil) then return end
		
		local Animation = Retrieved.Animation
		local Job = Retrieved.Job

		local Torso : BasePart = VictimModel.Torso
		local RootPart = Retrieved.RootPart

		local function GetPosition()
			local CF = CFrame.lookAlong(Torso.Position, RootPart.CFrame.LookVector) * CFrame.new(0, 0, -1.5)
			
			return (CF.Position + (Vector3.yAxis * 1.5))
		end

		Job:Task(Animation:GetMarkerReachedSignal("land1"):Connect(function()
			local Position = GetPosition()
			
			if LocalPlayer:DistanceFromCharacter(Torso.Position) <= 45 then
				CameraShake(3, 30, 0.01, 0.3, Vector3.one * 0.8, 0.2)
			end
			
			Emit(VFX.land1, RootPart, CFrame.new(0, -2, 0))

			task.spawn(RockHandler.Crater, Position, CraterDirection, {
				Amount = 9,
				Distance = {Min = 5, Max = 7.5},
				LookAt = {Min = 3.5, Max = 5},

				Exposure = {Min = 0.4, Max = 0.55},
				BaseZ = 1.25,
				SizeMultiplier = 1.3,
			})

			task.spawn(RockHandler.Crater, Position, CraterDirection, {
				Amount = 5,
				Distance = {Min = 2.5, Max = 5},
				LookAt = {Min = 4, Max = 6},

				Exposure = 0.2,
				BaseZ = 0.75,
				SizeMultiplier = 0.9,
			})

			task.spawn(RockHandler.Rockst, Position, CraterDirection, {
				Size = {0.5, 0.75},
				Count = 10,
				Velocity = 75,
				SpawnVariance = 7;
			})
		end))

		Job:Task(Animation:GetMarkerReachedSignal("land2"):Connect(function()
			local Position = GetPosition()
			
			if LocalPlayer:DistanceFromCharacter(Torso.Position) <= 45 then
				CameraShake(2, 30, 0.01, 0.3, Vector3.one * 0.8, 0.2)
			end
			
			Emit(VFX.land2, RootPart, CFrame.new(0, -2, 0))

			coroutine.wrap(RockHandler.Crater)(Position, CraterDirection, {
				Amount = 8,
				Distance = 5.5,
				SizeMultiplier = 1.4,
			})

			task.spawn(RockHandler.Rockst, Position, CraterDirection, {
				Size = {0.35, 0.5},
				Count = 6,
				Velocity = 75,
				SpawnVariance = 5;
			})

			for Index = 1, 8 do
				local Position = GetPosition()

				task.spawn(RockHandler.Rockst, Position, CraterDirection, {
					Size = {0.1, 0.3},
					Count = 5,
					Velocity = 10,
					SpawnVariance = 0.5;
				})

				RockHandler.Rocks("Dragged", Position)
				Smoke(Torso, 7.5, 1.5)

				task.wait(0.1)
			end
		end))
	end

}