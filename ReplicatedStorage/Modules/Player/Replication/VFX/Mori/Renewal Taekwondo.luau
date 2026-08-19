local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animations = ReplicatedStorage.Animations.Attacks.Mori["Renewal Taekwondo"]

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local BugoVFX = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.Bugo )

local Hit_Assets = script.Hit_Assets
local Jin_Trail = script.Jin_Trail

local Jin_Color = Color3.fromRGB(84, 144, 255)

local function Trails(Model : Model, Limbs : {})
	local Trails = {}
	
	for _, Item in ipairs(Model:GetChildren()) do
		if Item:IsA("BasePart") and table.find(Limbs, Item.Name) then
			local A0 = Jin_Trail.A0:Clone()
			local A1 = Jin_Trail.A1:Clone()
			
			A0.Trail1.Attachment0, A0.Trail1.Attachment1 = A0, A1
			A0.Trail2.Attachment0, A0.Trail2.Attachment1 = A0, A1
			
			A0.Parent = Item
			A1.Parent = Item
			
			Trails[A0] = true
			Trails[A1] = true
		end
	end
	
	return Trails
end

local Hit_Parameter_Functions = {
	["1"] = function() -- start
		CameraShake(2, 20, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.3)
		Vignette(Jin_Color, 0.5, 0.2)
	end,
	
	["2"] = function() -- sweep
		CameraShake(0.6, 12, 0.01, 0.5, Vector3.one * 0.5, Vector3.one * 0.65)
	end,
	
	["3"] = function() -- sweeped
		CameraShake(1.5, 1.5, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.3)
		Vignette(Jin_Color, 0.5, 0.2)
	end,
	
	["4"] = function() -- kicked down
		CameraShake(2.75, 27.5, 0.01, 0.38, Vector3.one * 0.8, Vector3.one * 0.15)
		Vignette(Jin_Color, 0.25, 0.35)
	end,
	
	["5"] = function() -- kicks
		CameraShake(1.5, 17.5, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.15)
		Vignette(Jin_Color, 0.5, 0.2)
	end,
	
	["6"] = function() -- kick spin
		CameraShake(2, 20, 0.01, 0.3, Vector3.one * 0.8, Vector3.one * 0.3)
		Vignette(Jin_Color, 0.5, 0.2)
	end,
	
	["7"] = function() -- lasts
		CameraShake(2.5, 25, 0.01, 0.2, Vector3.one * 0.8, Vector3.one * 0.3)
		Vignette(Jin_Color, 0.5, 0.2)
	end,
}

return {
	["Start"] = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Windup)
		if (Retrieved == nil) then return end

		local MainAnimation = Retrieved.Animation
		local MainJob = Retrieved.Job

		local Trails = Trails(Model, {"Right Leg"})
		
		MainJob:Task(function()
			for Trail in Trails do
				Trail:Destroy()
			end
			
			table.clear(Trails)
		end)
		
		MainJob:Task(EffectUtility.AddSFX(script.SFX.Windup, Retrieved.Torso, 0.3))
		
		MainJob:Task(MainAnimation:GetMarkerReachedSignal("hit"):Connect(function()
			if EffectUtility.Distance_Close(Model) then
				CameraShake(0.75, 10, 0.01, 0.4, Vector3.one * 0.8, Vector3.one * 0.3)
			end
		end))
	end,
	
	["Hit"] = function(Model : Model, VictimModel : Model)
		local Retrieved = AnimationRetriever.new(Model, Animations.Hit)
		if (Retrieved == nil) then return end
		
		local RootPart = Retrieved.RootPart
		local MainAnimation = Retrieved.Animation
		local MainJob = Retrieved.Job
		
		MainJob:Task(EffectUtility.AddSFX(script.SFX.Hit, Retrieved.Torso, 0.3))
		
		local Trails = Trails(Model, {"Right Leg", "Left Leg"})

		MainJob:Task(function()
			for Trail in Trails do
				Trail:Destroy()
			end

			table.clear(Trails)
		end)
		
		local function VFX(Parameter : string)
			local Effect = Hit_Assets:FindFirstChild(Parameter)

			if Effect and EffectUtility.Distance_Far(Model) then
				local NewEffect = Effect:Clone()
				NewEffect.CFrame = RootPart.CFrame * (Effect.CFrame - Vector3.yAxis * 3)
				NewEffect.Parent = workspace.Visuals
				EffectUtility.Arc.EmitAttachment(NewEffect)
			end
			
			if EffectUtility.Distance_Close(Model) and Hit_Parameter_Functions[Parameter] then
				task.spawn(Hit_Parameter_Functions[Parameter])
			end
		end
		
		MainJob:Task(MainAnimation:GetMarkerReachedSignal("vfx"):Connect(VFX))
		
		if EffectUtility.Distance_Far(Model) then
			VFX("1")
		end
	end,
}