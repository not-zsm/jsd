local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local MeshVFX = require( ReplicatedStorage.Modules.Player.Replication.Global.MeshVFX )

local AttributeListener = require( ReplicatedStorage.Modules.Player.Replication.Global.AttributeListener )
local CharacterTransparency = require( ReplicatedStorage.Modules.Player.Replication.Global.CharacterTransparency )

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )

local Phones = {}
local Phones = {}

function VFX.Phone(Model : Model, Value : string)
	if (Value == "true") then
		if (Phones[Model] == nil) then
			local Phone = script.Phone:Clone()
			Phone.Weld.Part0 = Model["Left Arm"]
			Phone.Parent = Model
			Phones[Model] = Phone
		end

	elseif Value == "false" then
		if (Phones[Model] ~= nil) then
			Phones[Model]:Destroy()
			Phones[Model] = nil
		end
	end
end
	
function VFX.PlayAs(Model : Model)
	if (Model and Model.Parent ~= nil) then
		CurrentCamera.CameraSubject = Model.Humanoid
	end
end

function VFX.ReigenFades(FakeReigen : Model)
	local Info = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	
	for _, Item in ipairs(FakeReigen:GetDescendants()) do
		if Item:IsA("BasePart") or Item:IsA("Decal") then
			TweenService:Create(Item, Info, {Transparency = 1}):Play()
			
		elseif Item:IsA("TextLabel") then
			local Stroke = Item:FindFirstChildOfClass("UIStroke")

			TweenService:Create(Item, Info, {TextTransparency = 1}):Play()
			
			if Stroke then
				TweenService:Create(Stroke, Info, {Transparency = 1}):Play()
			end
		end
	end
end

local AccessoryUpdaters = {}

function VFX.Hide(RealModel : Model)
	pcall(function()
		for _, UltAura in ipairs(RealModel:GetDescendants()) do
			if UltAura:HasTag("UltimateAura") then
				if UltAura:IsA("Attachment") then
					EffectUtility.Toggle(UltAura, false)
					
				elseif UltAura:IsA("ParticleEmitter") then
					UltAura.Enabled = false
				end
				
				task.delay(1, UltAura.Destroy, UltAura)
			end
		end
	end)
	
	AccessoryUpdaters[RealModel] = Job.new()
	
	AccessoryUpdaters[RealModel]:Task(RealModel.ChildAdded:Connect(function(Child)
		if Child:IsA("Accessory") then
			local Handle = Child:FindFirstChild("Handle")

			if Handle then
				Handle.Transparency = 1
			end
		end
	end))
	
	AccessoryUpdaters[RealModel]:Task(RealModel.DescendantAdded:Connect(function(Child)
		if Child:IsA("Decal") then
			Child.Transparency = 1
		end
	end))
	
	
	while RealModel and AccessoryUpdaters[RealModel] do
		CharacterTransparency(RealModel, 1)
		task.wait(0.1)
	end
end

function VFX.OnRealModelDescriptionLoaded(RealModel : Model)
	if AccessoryUpdaters[RealModel] then
		AccessoryUpdaters[RealModel]:Destroy()
		AccessoryUpdaters[RealModel] = nil
	end
end
	

function VFX.ThreadClosed(RealModel : Model)
	CharacterTransparency(RealModel, 0)
end

function VFX.MobAura(RealModel : Model)
	local Auras = {}

	local function AddAuraToPart(Part : BasePart)
		for _, Item in ipairs(script.MobAura:GetChildren()) do
			local NewItem = Item:Clone()
			NewItem.Enabled = true
			NewItem:AddTag("UltimateAura")
			NewItem.Parent = Part
			Auras[NewItem] = true
		end
	end
	
	for _, Item in ipairs(RealModel:GetChildren()) do
		if Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart" then
			AddAuraToPart(Item)
		end
	end

	return Auras
end

function VFX.Summon(RealModel : Model)
	VFX.OnRealModelDescriptionLoaded(RealModel)
	CharacterTransparency(RealModel, 0)

	local Auras = VFX.MobAura(RealModel)
	
	local Theme = script.Theme:Clone()
	Theme.Volume = 0
	Theme.Parent = RealModel.HumanoidRootPart
	Theme:Play()
	
	TweenService:Create(Theme, TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{Volume = 2}
	):Play()
	
	local Replication : Configuration? = AttributeListener.GetReplicationFromSource(RealModel)

	if Replication then
		AttributeListener.new(RealModel, "Ultimate", function()
			Theme:Destroy()
			
			for Aura in Auras do
				Aura:Destroy()
			end
		end)
	end
end

function VFX.Land(RealRootPart : BasePart)
	local Land = script.Land:Clone()
	Land.CFrame = RealRootPart.CFrame * CFrame.new(0, -0.8, 0)
	Land.Parent = workspace.Visuals
	EffectUtility.Emit(Land)
	
	if LocalPlayer:DistanceFromCharacter(RealRootPart.Position) < 25 then
		CameraShake(2.5, 25, 0.01, 0.4, Vector3.one * 0.8)
	end
	
	local Position = RealRootPart.Position
	local LookVector = Vector3.yAxis * -10
	
	EffectUtility.RaycastCraterSmoke("Small", Position, LookVector)
	
	coroutine.wrap(RockHandler.Crater)(Position, LookVector, {
		Amount = 9,
		Distance = 3.25,

		LookAt = { -- Where the rocks face towards (y axis)
			Min = -4,
			Max = 4
		},

		Exposure = {
			Min = 0.2,
			Max = 0.285
		},

		SizeMultiplier = 0.735,
	})

	coroutine.wrap(RockHandler.Crater)(Position, LookVector, {
		Amount = 12,
		Distance = 6.75,

		LookAt = { -- Where the rocks face towards (y axis)
			Min = -7,
			Max = 7
		},

		Exposure = {
			Min = 0.475,
			Max = 0.585
		},

		SizeMultiplier = 0.9,
	})

	coroutine.wrap(RockHandler.Rockst)(Position, LookVector, {
		Count = 15,
		Size = {0.4, 1},
		Velocity = 20,
		XZVelocity = NumberRange.new(0.8, 0.8),
		YVelocity = NumberRange.new(4, 4)
	})
end

return VFX