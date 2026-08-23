local SoundService = game:GetService("SoundService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local AnimationRetriever = require(replicatedStorage.modules.client.replication.VFX.AnimationRetriever)
local RunCameraRig = require(replicatedStorage.modules.client.replication.Global.RunCameraRig)
local CameraShake = require(replicatedStorage.modules.client.replication.Global.CameraShake)
local RockHandler = require(replicatedStorage.modules.client.replication.Global.RockHandler)
local EffectBlood = require(replicatedStorage.modules.client.replication.VFX.Global.Blood)
local VelocityUtil = require(replicatedStorage.modules.shared.Game.Velocity.VelocityUtil)
local EffectUtility = require(replicatedStorage.modules.client.replication.EffectUtility)
local BugoVFX = require(replicatedStorage.modules.client.replication.EffectUtility.Bugo)
local Yuki_FOV = require(replicatedStorage.modules.client.replication.Global.Yuki_FOV)

local Animation = replicatedStorage.Animations.Emotes["Idol V2"]
local Emit = require( script.Emit )

return { 
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animation)
		if (Retrieved == nil) then return end

		local Torso, RootPart = Retrieved.Torso, Retrieved.RootPart
		local Animation, Job = Retrieved.Animation, Retrieved.Job
		
		local Ended = false
		
		local Active = {}
		
		local function GetPivot(VFX : Model)
			return VFX:GetPivot() * CFrame.new(-2, 0, 0)
		end
		
		local VFX = {
			["1"] = function()
				local Fire = Job:Task(script.YourIdol.BackFire1:Clone())
				
				Fire:PivotTo(RootPart.CFrame * GetPivot(Fire))
				Fire.Parent = workspace.Visuals
				Emit(Fire)
				EffectUtility.Toggle(Fire, true)
				
				Active["Fire1"] = Fire
			end,
		
			["2"] = function()
				EffectUtility.Toggle(Active["Fire1"], false)
				
				------------------------------------------------
				local Fire = Job:Task(script.YourIdol.BackFire2:Clone())

				Fire:PivotTo(RootPart.CFrame * GetPivot(Fire))
				Fire.Parent = workspace.Visuals
				Emit(Fire)
				EffectUtility.Toggle(Fire, true)

				Active["Fire2"] = Fire
			end,
			
			["3"] = function()
				EffectUtility.Toggle(Active["Fire2"], false)

				------------------------------------------------
				local Fire = Job:Task(script.YourIdol.BackFire3:Clone())

				Fire:PivotTo(RootPart.CFrame * GetPivot(Fire))
				Fire.Parent = workspace.Visuals
				EffectUtility.Toggle(Fire, true)
				Emit(Fire)

				Active["Fire3"] = Fire
			end,
			
			["4"] = function()
				EffectUtility.Toggle(Active["Fire3"], false)

				------------------------------------------------
				local Fire = script.YourIdol.BackFire4:Clone()
				Job:Task(function()
					if not Ended then
						Fire:Destroy()
					end
				end)
				
				Fire:PivotTo(RootPart.CFrame * GetPivot(Fire))
				Fire.Parent = workspace.Visuals
				EffectUtility.Toggle(Fire, true)
				Emit(Fire)

				Active["Fire4"] = Fire
			end,
			
			["5"] = function()
				Ended = true
				
				EffectUtility.Toggle(Active["Fire4"], false)
				task.delay(3, Active["Fire4"].Destroy, Active["Fire4"])
			end,
		}
		
		Job:Task(Animation:GetMarkerReachedSignal("VFX"):Connect(function(Parameter : string)
			local Func = VFX[Parameter]
			if Func then
				Func()
			end
		end))
	end,
}