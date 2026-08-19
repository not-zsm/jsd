local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replication_VFX = ReplicatedStorage.Modules.Player.Replication.VFX
local Mori_Effects = ReplicatedStorage.Effects.Characters.Mori

local AnimationRetriever = require( Replication_VFX.AnimationRetriever )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )

local Animations = ReplicatedStorage.Animations.Attacks.Global.Dash.Mori.Ult

local Forward_Dash = require( ReplicatedStorage.Modules.Player.Replication.VFX.Global.Dashing["Forward Dash"])

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
end

return {
	Hit = function(AttackerRoot : BasePart, VictimRoot : BasePart)
		Forward_Dash.Hit(AttackerRoot, VictimRoot)
	end,

	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Loop)
		if (Retrieved == nil) then return end

		local Pole_Model = Model:FindFirstChild("Pole")
		local Pole_Handle = Pole_Model and Pole_Model:FindFirstChild("Handle")
		local Pole = Pole_Handle and Pole_Handle:FindFirstChild("Poll")

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

		task.spawn(Forward_Dash.Start, RootPart)

		Trails(true)
		
		Job:Task(function()
			task.delay(0.6, Trails)
			
			task.spawn(function()
				local Hit_Retrieved = AnimationRetriever.new(Model, Animations.Hit) -- Scuffed 😭
				if (Hit_Retrieved == nil) then return end

				Hit_Retrieved.Job:Task(task.delay(0.06, function()
					VFX(RootPart, "WindedSlash1")
					VFX(RootPart, "SlashDust")
				end))
			end)
		end)
	end,
}
