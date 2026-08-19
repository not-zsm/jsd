-- it's all sunshines and rainbows now!!!!
-- blehhh!

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Assets = script.Assets

----------------------------------------------------------------------------------

local BloodHandler = {}
local Rays = {}

type Settings = {
	Gravity : number,
	Power : number,

	Amount : Vector2,
	Spread : Vector2,

	Face : Enum.NormalId,

	PoolSize : number,
	PoolSizeRandom : Vector2,

	Color : Color3,

	PoolDuration : number,
	PoolDurationTransition : number,
	PoolTransition : number,
}

local DefaultBloodSettings = {
	Gravity = 125,
	Power = 25,
	
	Amount = Vector2.new(2, 4),
	Spread = Vector2.new(45, 45),
	
	Face = Enum.NormalId.Front,

	PoolSize = 1,
	PoolSizeRandom = Vector2.new(-0.25, 0.25),

	--Color = Color3.fromRGB(85, 0, 0),
	
	PoolDuration = 3,
	PoolDurationTransition = 1,
	PoolTransition = Utility.Seed:NextNumber(1, 1.5),
} :: Settings

DefaultBloodSettings.__index = DefaultBloodSettings

local Presets = require(script.Presets)

for Name, Table in Presets do
	setmetatable(Table, DefaultBloodSettings)
end

----------------------------------------------------------------------------------

function BloodHandler.CanShowBlood()
	return (Player:GetAttribute("Blood") == true)
end

function BloodHandler.ParticleSupportsBlood(Particle : ParticleEmitter)
	if string.find(string.lower(Particle.Name), "blood") then
		return BloodHandler.CanShowBlood()
	end
	
	return true
end
	
function BloodHandler.BloodRay(Item : (BasePart | Attachment), Settings : {})
	if (Item == nil or Item.Parent == nil) then
		return
	end
	
	local Position = Item:IsA("Attachment") and Item.WorldPosition or Item.Position
	
	if (Player:DistanceFromCharacter(Position) > 75) then
		return
	end
	
	local Ray = {}
	
	local RainbowAndSunshineColor = Color3.new(Utility.Seed:NextNumber(0, 1), Utility.Seed:NextNumber(0, 1), Utility.Seed:NextNumber(0, 1))

	local Trail = Assets.BloodHolder.Blood:Clone()
	Trail.Trail.Color = ColorSequence.new(RainbowAndSunshineColor) --ColorSequence.new(Settings.Color)
	Trail.Position = Position
	Trail.Parent = workspace.Terrain

	task.delay(5, Trail.Destroy, Trail)

	local AdorneeAngle = Utility.VectorToRotation((Item:IsA("Attachment") and Item.WorldCFrame or Item.CFrame).LookVector)
	local FacingAngle = Utility.VectorToRotation(Utility.Faces[Settings.Face])
	
	local SpreadAngle = CFrame.fromEulerAngles(
		math.rad(Utility.Seed:NextNumber(-Settings.Spread.X, Settings.Spread.X)),
		math.rad(Utility.Seed:NextNumber(-Settings.Spread.Y, Settings.Spread.Y)), 0
	)

	local Velocity = (AdorneeAngle * FacingAngle * SpreadAngle).LookVector * Settings.Power
	
	function Ray.Simulate(Delta : number)
		if (Trail.Parent == nil) then
			return Ray.Destroy()
		end

		local NewPosition = Position + Velocity * Delta

		local Raycast = workspace:Raycast(Position, NewPosition - Position, Utility.VisualParams)
		Trail.Position = NewPosition

		if (Raycast ~= nil) then
			Ray.Destroy()

			local Splatter = Assets.Splatter:Clone()
			
			local AntiZFight = Utility.Seed:NextNumber(0.09, 0.11)
			local RandomRotation = CFrame.Angles(0, Utility.Seed:NextNumber(-360, 360), 0)
			
			--Splatter.Color = Settings.Color
			
			Splatter.Color = RainbowAndSunshineColor
			Splatter.CFrame = CFrame.new(Raycast.Position, Raycast.Position + Raycast.Normal) * CFrame.Angles(math.rad(-90), 0, 0) * RandomRotation
			Splatter.Size = Vector3.new(0, AntiZFight, 0)
			Splatter.Parent = workspace.Visuals

			local Size = Utility.Seed:NextNumber(Settings.PoolSizeRandom.X, Settings.PoolSizeRandom.Y)

			TweenService:Create(Splatter, TweenInfo.new(Settings.PoolTransition), {
				Size = Vector3.new(Settings.PoolSize + Size, AntiZFight, Settings.PoolSize + Size),
				Transparency = 0
			}):Play()

			task.delay(Settings.PoolDuration + Utility.Seed:NextNumber(-1, 1), function()
				TweenService:Create(Splatter, TweenInfo.new(Settings.PoolDurationTransition), {
					Transparency = 1
				}):Play()

				task.delay(Settings.PoolDurationTransition, Splatter.Destroy, Splatter)
			end)

			return
		end

		Velocity -= Vector3.new(0, Settings.Gravity, 0) * Delta
		Position = NewPosition
	end

	function Ray.Destroy()
		if (Trail.Parent ~= nil) then
			task.delay(Trail.Trail.Lifetime, Trail.Destroy, Trail)
		end

		Rays[Ray] = nil
		table.clear(Ray)
	end

	Rays[Ray] = true
end

function BloodHandler.BloodRays(PresetName : string, Item : (BasePart | Attachment))
	if BloodHandler.CanShowBlood() then
		local Settings = {}
		setmetatable(Settings, {__index = Presets[PresetName]})

		for Index = 1, math.random(Settings.Amount.X, Settings.Amount.Y) do
			BloodHandler.BloodRay(Item, Settings)
		end
	end
end

function BloodHandler.BloodRaysWithoutPreset(Item : (BasePart | Attachment), Settings : Settings)
	if BloodHandler.CanShowBlood() then
		setmetatable(Settings, DefaultBloodSettings)

		for Index = 1, math.random(Settings.Amount.X, Settings.Amount.Y) do
			BloodHandler.BloodRay(Item, Settings)
		end
	end
end

RunService.PreSimulation:Connect(function(Delta)
	for Ray, _ in Rays do
		Ray.Simulate(Delta)
	end
end)

return BloodHandler