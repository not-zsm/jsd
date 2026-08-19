local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )
local BloodVFX = require( ReplicatedStorage.Modules.Player.Replication.VFX.Global.Blood )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Yuki_FOV = require( ReplicatedStorage.Modules.Player.Replication.Global.Yuki_FOV )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local function NewEffect(RootPart : BasePart, Effect : BasePart)
	local Effect = Effect:Clone()
	Effect.CFrame = RootPart.CFrame * Effect.CFrame + Vector3.yAxis * -3
	Effect.Parent = workspace.Visuals
	EffectUtility.Emit(Effect)
end

function VFX.Grab(RootPart : BasePart)
	if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 15 then
		CameraShake(1, 7.5, 0.01, 0.15)
	end
	
	NewEffect(RootPart, script.grab)
end

local LeftCharges = {}
local RightCharges = {}

function VFX.Charge(RootPart : BasePart, Type : string)
	if Type == "left" then
		if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 15 then
			CameraShake(2.5, 10, 0.05, 0.2)
			Vignette(Color3.fromRGB(193, 45, 45), 0.75, 0.3)
		end
		
		if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
			Yuki_FOV.Tween(60, {0.4})

			task.delay(0.4, function()
				Yuki_FOV.Tween(70, {0.3})
			end)
		end
		
		if (LeftCharges[RootPart] == nil) then
			local Arm = script.leftred:Clone()
			Arm.Parent = workspace.Visuals
			
			task.delay(3, Arm.Destroy, Arm)
			
			EffectUtility.Weld(Arm, RootPart.Parent["Left Arm"])
			EffectUtility.Toggle(Arm, true)
			
			LeftCharges[RootPart] = Arm
		end
	else
		if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 15 then
			CameraShake(2.5, 10, 0.05, 0.2)
			Vignette(Color3.fromRGB(193, 45, 45), 0.4, 0.7)
		end
		
		if LocalPlayer == Players:GetPlayerFromCharacter(RootPart.Parent) then
			Yuki_FOV.Tween(50, {0.6})

			task.delay(0.7, function()
				Yuki_FOV.Tween(70, {0.025})
			end)
		end
		
		if (RightCharges[RootPart] == nil) then
			local Arm = script.leftred:Clone()
			Arm.Parent = workspace.Visuals
			
			task.delay(3, Arm.Destroy, Arm)
			
			EffectUtility.Weld(Arm, RootPart.Parent["Right Arm"])

			for _, Item in pairs(Arm:GetDescendants()) do 
				if Item:IsA("ParticleEmitter") then 
					Item.TimeScale = 0
					Item.Enabled = true

					TweenService:Create(Item, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
						{TimeScale = 1}
					):Play()
				end 
			end

			RightCharges[RootPart] = Arm
		end
		
		task.wait(0.35)
		
		NewEffect(RootPart, script.headcharge)
	end
end

function VFX.Blast(RootPart : BasePart, VictimModel : Model, Type : string)
	if Type == "left" then
		if LeftCharges[RootPart] then
			LeftCharges[RootPart]:Destroy()
			LeftCharges[RootPart] = nil
		end

		if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25 then
			CameraShake(3, 22.5, 0.05, 0.3)
			NewEffect(RootPart, script.armblast)
		end
		
		if LocalPlayer:GetAttribute("Blood") then
			VictimModel["Right Arm"].Transparency = 1
			
			for Index = 1, 4 do
				Blood.BloodRaysWithoutPreset(VictimModel["Right Arm"], {
					Face = Index == 1 and Enum.NormalId.Top or Index == 2 and Enum.NormalId.Left or Index == 3 and Enum.NormalId.Right or Index == 4 and Enum.NormalId.Bottom, 
					SpreadAngle = Vector2.new(90, 90), 
					Amount = Vector2.new(4, 6), 
					PoolSize = 1.25,
					PoolSizeRandom = Vector2.new(-0.6, 0.6),
				})
			end
		end
	else
		if RightCharges[RootPart] then
			RightCharges[RootPart]:Destroy()
			RightCharges[RootPart] = nil
		end
		
		if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25 then
			CameraShake(4, 30, 0.01, 0.4)
			NewEffect(RootPart, script.headblast)
		end
		
		if LocalPlayer:GetAttribute("Blood") then
			VictimModel.Head.Transparency = 1

			for _, Item in ipairs(VictimModel:GetChildren()) do
				if Item:IsA("Accessory") then
					local Handle = Item:FindFirstChild("Handle")

					if (Handle ~= nil and Handle:IsA("BasePart") and (string.find(Handle.Name, "Face") or string.find(Handle.Name, "Hat") or string.find(Handle.Name, "Hair"))) then
						Handle.Transparency = 1
					end
				end
			end
			
			for Index = 1, 4 do
				Blood.BloodRaysWithoutPreset(VictimModel["Left Leg"], {
					Face = Index == 1 and Enum.NormalId.Top or Index == 2 and Enum.NormalId.Left or Index == 3 and Enum.NormalId.Right or Index == 4 and Enum.NormalId.Bottom, 
					SpreadAngle = Vector2.new(90, 90), 
					Amount = Vector2.new(4, 6), 
					PoolSize = 1.25,
					PoolSizeRandom = Vector2.new(-0.6, 0.6),
				})
			end
		end
	end
end

return VFX