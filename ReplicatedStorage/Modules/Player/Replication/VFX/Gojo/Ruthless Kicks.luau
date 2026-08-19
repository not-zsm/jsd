local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

---------------------------------------------------------------------------------

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

---------------------------------------------------------------------------------

local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local Smoke = require( ReplicatedStorage.Modules.Player.Replication.Global.Smoke )

local Blood = require( ReplicatedStorage.Modules.Player.Replication.Global.Blood )

---------------------------------------------------------------------------------

local SwrermMeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.SwrermMeshVFX )

---------------------------------------------------------------------------------

local function ArcEmit(name : string, parent : BasePart)
	local VFX = script.VFX:FindFirstChild(name)

	if VFX then
		VFX = VFX:Clone()
		VFX.Parent = parent
		EffectUtility.Arc.EmitAttachment(VFX)
	end
end

local function EmitMesh(Model : Model, RootPart : BasePart)
	Model:PivotTo(RootPart.CFrame)

	for _, Mesh in ipairs(Model:GetChildren()) do
		if Mesh:IsA("Model") then
			SwrermMeshVFX.Emit(Mesh)
		end
	end
end

local function PushForward(RootPart : BasePart, Amount : number, IndexTime : number)
	for Index = 1, (Amount or 10) do
		RockHandler.Rocks("Dragged", RootPart)
		Smoke(RootPart, 7.5, 1.5)
		
		task.wait(IndexTime or 0.05)
	end
end

---------------------------------------------------------------------------------

return {
	OnStart = function(AttackerModel : Model)
		local Trail = EffectUtility.WeldArmTrail(AttackerModel["Right Arm"])
		
		if Trail then
			task.delay(1.25, Trail.Destroy, Trail)
		end
	end,
	
	OnHit = function(AttackerModel : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(AttackerModel,
			ReplicatedStorage.Animations.Attacks.Gojo["Ruthless Beatdown"].VariantHit
		)
		
		if (Retrieved == nil) then return end
		
		local Animation, NewJob = Retrieved.Animation, Retrieved.Job
		local RootPart = Retrieved.RootPart
		
		local function InRangeForVFX()
			if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 100 then
				return true
			end
		end

		local function InRangeForScreenEffects()
			if LocalPlayer:DistanceFromCharacter(RootPart.Position) <= 25 then
				return true
			end
		end
		
		local function BloodIfSettingOn()
			if (VictimModel and VictimModel.Parent ~= nil) then
				local Head = VictimModel:FindFirstChild("Head")

				if Head then
					Blood.BloodRays("SpitOut", Head.MouthAttachment)
				end
			end
		end
		
		local Mesh1 = script.Mesh1:Clone()
		NewJob:Task(Mesh1)
		
		local Mesh2 = script.Mesh2:Clone()
		NewJob:Task(Mesh2)

		NewJob:Task(Animation:GetMarkerReachedSignal("hit"):Connect(function(Parameter : string)
			if InRangeForScreenEffects() then
				CameraShake(2, 25, 0.01, 0.3, Vector3.one * 0.8)
				Vignette(Color3.fromRGB(41, 87, 255), 0.75, 0.15)
			end

			if InRangeForVFX() then
				ArcEmit(Parameter, RootPart)
				
				if Parameter == "1" then
					ArcEmit("j2", RootPart)
					
					task.spawn(PushForward, RootPart, 5)

				elseif Parameter == "2" then
					EmitMesh(Mesh1, RootPart)
					
					if (VictimModel and VictimModel.Parent ~= nil) then
						task.delay(0.6, PushForward, VictimModel.HumanoidRootPart, 8)
					end

				elseif Parameter == "3" then
					EmitMesh(Mesh2, RootPart)
					
					task.spawn(PushForward, RootPart, 7)
				end
				
				BloodIfSettingOn()
			end
		end))

		NewJob:Task(Animation:GetMarkerReachedSignal("dash"):Connect(function(Parameter : string)
			if InRangeForVFX() then
				ArcEmit("j3", RootPart)
			end
		end))
		
		NewJob:Task(Animation:GetMarkerReachedSignal("slightpush"):Once(function(Parameter : string)
			task.spawn(PushForward, RootPart, 7)
		end))

		if InRangeForVFX() then
			ArcEmit("1", RootPart)
			ArcEmit("j1", RootPart)
		end
		
		if InRangeForScreenEffects() then
			CameraShake(2.5, 30, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.3)
			Vignette(Color3.fromRGB(56, 132, 255), 0.65, 0.35)
		end
		
		BloodIfSettingOn()
	end
}
