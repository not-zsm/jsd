local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replication_VFX = ReplicatedStorage.Modules.Player.Replication.VFX
local Mori_Effects = ReplicatedStorage.Effects.Characters.Mori

local AnimationRetriever = require( Replication_VFX.AnimationRetriever )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Animations = ReplicatedStorage.Animations.Attacks.Global.M1.Mori.Ult

local TranslateNameToCount = {
	["Down"] = 4,
	["Up"] = 4,
}

local function GetCF(RootPart : BasePart)
	return RootPart.CFrame - Vector3.yAxis * 3
end

local function VFX(RootPart : BasePart, Name : string, NoWeld : boolean)
	local NewVFX = script[Name]:Clone()
	NewVFX:PivotTo(GetCF(RootPart) * script[Name]:GetPivot())
	NewVFX.Parent = workspace.Visuals
	EffectUtility.Arc.EmitAttachment(NewVFX)
	
	if not NoWeld then
		EffectUtility.Weld(NewVFX, RootPart, script[Name]:GetPivot() - Vector3.yAxis * 3)
	end
	
	return NewVFX :: BasePart
end

return {
	Hit = function(VictimRoot : BasePart, Count : number)
		if EffectUtility.Distance_Close(VictimRoot.Parent, 15) then
			CameraShake(1, 10, 0.01, 0.25, Vector3.one * 0.8)
		end
		
		EffectUtility.EmitEffects(Replication_VFX.Global.M1.Hit.Default, VictimRoot)
		
		local Sound = script.SFX.Hit:FindFirstChild(Count)
		
		if Sound then
			local SFX = EffectUtility.AddSFX(Sound, VictimRoot)
			task.delay(2, SFX.Destroy, SFX)
		end
	end,
	
	Start = function(Model : Model, Animation_Name : string)
		local Retrieved = AnimationRetriever.new(Model, Animations[Animation_Name])
		if (Retrieved == nil) then return end
		
		local Pole_Model = Model:FindFirstChild("Pole")
		local Pole_Handle = Pole_Model and Pole_Model:FindFirstChild("Handle")
		local Pole = Pole_Handle and Pole_Handle:FindFirstChild("Poll")
		
		local M1_Count : number = TranslateNameToCount[Animation_Name] or tonumber(Animation_Name)
		
		local Animation = Retrieved.Animation
		local RootPart, Job = Retrieved.RootPart, Retrieved.Job
		
		local function Trails(Value : boolean)
			if (Pole == nil or Pole.Parent == nil) then return end

			if (Value == nil) then
				Value = false
			end
			
			for _, Item in ipairs(Pole:GetDescendants()) do
				if Item:IsA("Trail") then 
					Item.Enabled = Value
				end
			end
		end
		
		Job:Task(EffectUtility.AddSFX(script.SFX.Whoosh[M1_Count], RootPart))
		
		Trails(true)
		Job:Task(Trails)

		local function Luh_Calm_Shake()
			if EffectUtility.Distance_Close(Model, 15) then
				CameraShake(0.75, 7.5, 0.01, 0.3, Vector3.one * 0.8)
			end
		end
		
		if (M1_Count == 1) then
			Job:Task(task.delay(12 / 60, function()
				Luh_Calm_Shake()
				VFX(RootPart, "WindedSlash1")
				VFX(RootPart, "SlashDust")
			end))
			
		elseif (M1_Count == 2) then
			Job:Task(task.delay(12 / 60, function()
				Luh_Calm_Shake()
				VFX(RootPart, "WindedSlash2")
				VFX(RootPart, "SlashDust")
			end))
			
		elseif (M1_Count == 3) then
			Job:Task(task.delay(5 / 60, function()
				if (Pole == nil or Pole.Parent == nil) then
					return
				end
				
				EffectUtility.Arc.ToggleAttachment(Pole.Spiner, true, 0.12)
			end))
			
			Job:Task(task.delay(23 / 60, function()
				Luh_Calm_Shake()
				VFX(RootPart, "WindedSlash3")
				VFX(RootPart, "SlashDust")
			end))
			
		elseif (M1_Count == 4 and tonumber(Animation_Name)) then
			local SecondaryPole = Model:FindFirstChild("SecondaryStaff")
			
			if SecondaryPole and Pole then
				Job:Task(function()
					Pole.Transparency = 0
					SecondaryPole.Poll.Transparency = 1
				end)

				Job:Task(Animation:GetMarkerReachedSignal("fake_staff"):Connect(function(Parameter : string?)
					if (Parameter == "true") then
						Pole.Transparency = 1
						SecondaryPole.Poll.Transparency = 0
					else
						Pole.Transparency = 0
						SecondaryPole.Poll.Transparency = 1
					end
				end))
			end
			
			Job:Task(Animation:GetMarkerReachedSignal("hit"):Connect(function(Parameter : string?)
				if (Parameter ~= "stun") then
					local NewVFX = VFX(RootPart, "PoleSlam", true)
					
					local Position = NewVFX:GetPivot().Position
					local Direction = Vector3.yAxis * -10
					
					if EffectUtility.Distance_Close(Model, 15) then
						CameraShake(1.5, 15, 0.01, 0.6, Vector3.one * 0.8, Vector3.one * 0.8)
					end
		
					coroutine.wrap(RockHandler.Crater)(Position, Direction, {
						Amount = 7,
						Distance = 4.5,

						LookAt = { -- Where the rocks face towards (y axis)
							Min = -5,
							Max = -5
						},

						Exposure = {
							Min = 0.5,
							Max = 0.7
						},

						BaseZ = 1.35,

						SizeMultiplier = 0.85,
					})

					coroutine.wrap(RockHandler.Crater)(Position, Direction, {
						Amount = 12,
						Distance = 5.5,

						LookAt = { -- Where the rocks face towards (y axis)
							Min = 7,
							Max = -7
						},

						Exposure = {
							Min = 0.5,
							Max = 0.7
						},

						SizeMultiplier = 1.1,
					})

					coroutine.wrap(RockHandler.Rockst)(Position, Direction, {
						Count = 20,
						Size = {0.35, 0.9},
						Velocity = 40,
					})
				end
			end))
	
			Job:Task(task.delay(11 / 60, function()
				Luh_Calm_Shake()
				VFX(RootPart, "PoleHit", true)
			end))
		end
	end,
}
