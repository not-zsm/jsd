local replicatedStorage = game:GetService("ReplicatedStorage")

local Weather = require( replicatedStorage.modules.client.weather )
local NewWeather = Weather.new()

local Actor = script:GetActor()

Actor:BindToMessage("StartRain", function(IsMain, WeatherInfo)
	NewWeather.IsMain = IsMain or false
	NewWeather:SetSettings(WeatherInfo)
	NewWeather:Rain(true)
end)

Actor:BindToMessage("EndRain", function()
	NewWeather:Rain(false)
end)

NewWeather:_Init()