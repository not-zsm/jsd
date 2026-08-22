local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local UserGameSettings : UserGameSettings = UserSettings():GetService("UserGameSettings")
local Quality = UserGameSettings.SavedQualityLevel.Value

UserGameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function()
	Quality = UserGameSettings.SavedQualityLevel.Value
end)

local function biDirRandom(Value : number)
	return Value - math.random() * Value * 2
end

-- dont want the actors running utility module like 6 times

----------------------------------------------------------------------------------

local Shared = ReplicatedStorage.Shared

local EventService = require( Shared.Utilities.EventService )
local Job = require( Shared.Utilities.Job )

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )

----------------------------------------------------------------------------------

export type RainImpact = {Raycast: RaycastResult, Origin: Vector3}

local Weather = {}
Weather.__index = Weather
Weather.defaults = {
	RainViewFrame = 50,
	RainHeight = 30,
	RainDensity = 1.5,
	RainUptime = 0.1
}

local Assets = script.Rain

local Params = RaycastParams.new()
Params.FilterType = Enum.RaycastFilterType.Include
Params.FilterDescendantsInstances = {workspace.Map, workspace.Visuals}

----------------------------------------------------------------------------------

function Weather:SetSettings(Settings)
	self.Settings = setmetatable(Settings or {}, {__index = Weather.defaults})
end

function Weather:Rain(Value : boolean)
	if self.IsRaining ~= Value then
		self.RainJob:Clean()
		self.IsRaining = Value
		self.OnRainToggled:Fire()
	end
end

function Weather:_OnRainFrame()
	local CameraPosition = workspace.CurrentCamera.CFrame.Position

	local NewPosition = CameraPosition + Vector3.new(biDirRandom(self.Settings.RainViewFrame), self.Settings.RainHeight, biDirRandom(self.Settings.RainViewFrame))
	local Raycast = workspace:Raycast(NewPosition, -(Vector3.yAxis * (self.Settings.RainHeight * 4)), Params)

	if (Raycast ~= nil) then
		table.insert(self.ComputeSerial, {Raycast = Raycast, Origin = NewPosition})
	end
end

function Weather:_OnRainFrameSerial(RainImpact: RainImpact)
	local RainRay = self:GetCached("RainRay");
	RainRay.Trail.Enabled = true
	RainRay.Position = RainImpact.Origin

	local Tween = TweenService:Create(RainRay, TweenInfo.new(self.Settings.RainUptime, Enum.EasingStyle.Linear), {
		Position = RainImpact.Raycast.Position
	})

	Tween:Play()

	Tween.Completed:Once(function()
		task.defer(self.ReleaseCached, self, "RainRay", RainRay)

		local RainSplash = self:GetCached("RainSplash");
		RainSplash.Position = RainImpact.Raycast.Position

		local _, Lifetime = EffectUtility.Emit(RainSplash, true, true)
		task.delay(Lifetime, self.ReleaseCached, self, "RainSplash", RainSplash)
	end)
end

function Weather:OnRainingStart()
	if self.IsMain then
		self.RainJob:Task(Player:GetAttributeChangedSignal("UnderRoof"):Connect(function()
			if Player:GetAttribute("UnderRoof") then
				TweenService:Create(workspace.RainAmbience.Effect, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					HighGain = -30,
					LowGain = -30,
					MidGain = 4
				}):Play()
			else
				TweenService:Create(workspace.RainAmbience.Effect, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					HighGain = 0,
					LowGain = 0,
					MidGain = 0
				}):Play()
			end
		end))
	end
	
	-- Rain is computed in parallel, then in serial to apply positions and effects.
	self.RainJob:Task(RunService.PreSimulation:ConnectParallel(function(Delta)
		-- Parallel Phase
		if not Player.Character or not self.InFocus then return end

		self.DeltaTotal += Delta

		table.clear(self.ComputeSerial)

		local Count = math.floor( (self.Settings.RainDensity * Quality) * self.DeltaTotal * 60 )
		local AmbientRaycast = if self.IsMain then workspace:Raycast(Player.Character:GetPivot().Position, Vector3.yAxis * self.Settings.RainHeight, Params) else nil

		for Index = 1, Count do
			self.DeltaTotal = 0
			self:_OnRainFrame()
		end

		task.synchronize()
		
		-- Serial Phase
		for _, RainImpact in ipairs(self.ComputeSerial) do
			self:_OnRainFrameSerial(RainImpact)
		end

		if self.IsMain then
			Player:SetAttribute("UnderRoof", (AmbientRaycast ~= nil))
		end
	end))
end


function Weather:GetCached(Name: string)
	local CacheInstance = next(self.Cached[Name]);
	
	if (CacheInstance == nil) then
		if Name == "RainRay" then
			CacheInstance = Assets.Particles.Ray:Clone()
			
		elseif Name == "RainSplash" then
			CacheInstance = Assets.Particles[`Splash{math.random(1, 2)}`]:Clone()
		end;
		
		CacheInstance.Parent = workspace.Terrain.RainEffects
	else
		self.Cached[Name][CacheInstance] = nil
	end
	
	return CacheInstance
end

function Weather:ReleaseCached(Name: string, Object: Instance)
	if Name == "RainRay" then
		Object.Trail.Enabled = false
	end
	
	Object.WorldPosition = Vector3.new(0, 10e8, 0);
	self.Cached[Name][Object] = true;
end


function Weather:_Init()
	self.InFocus = false
	
	UserInputService.WindowFocused:Connect(function()
		self.InFocus = true
	end)
	
	UserInputService.WindowFocusReleased:Connect(function()
		self.InFocus = false
	end)
	
	self.OnRainToggled:Connect(function()
		if self.IsRaining then
			self:OnRainingStart()
		end
	end)
end

----------------------------------------------------------------------------------

function Weather.new()
	local self = setmetatable({}, Weather)

	self.IsRaining = false
	self.IsMain = false
	self.OnRainToggled = EventService.new()
	self.RainJob = Job.new()

	self.DeltaTotal = 0
	self.ComputeSerial = {} :: {RainImpact}
	
	self.Cached = {
		RainSplash = {};
		RainRay = {};
	};
	
	self.RainConnection = nil

	self:SetSettings()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Weather)

return Weather