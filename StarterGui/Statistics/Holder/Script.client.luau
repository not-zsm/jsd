local replicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local function Format(Int)
	return string.format("%02i", Int)
end

local function ConvertToHMS(Seconds)
	local Minutes = (Seconds - Seconds % 60) / 60
	Seconds = Seconds - Minutes * 60
	local Hours = (Minutes - Minutes % 60) / 60
	Minutes = Minutes - Hours * 60
	return Format(Hours) .. ":" .. Format(Minutes) .. ":" .. Format(Seconds)
end

local Player = Players.LocalPlayer

local StatisticsFrame = script.Parent
local StatisticsGUI = StatisticsFrame.Parent
StatisticsGUI.Enabled = true

local RegionLabel = StatisticsFrame.Region
local VersionLabel = StatisticsFrame.Version
local PerformanceLabel = StatisticsFrame.Performance
local ServerTimeLabel = StatisticsFrame.ServerTime

VersionLabel.Text = `V1.{game.PlaceVersion}`

task.spawn(function()
	if not workspace:GetAttribute("Region") then
		workspace:GetAttributeChangedSignal("Region"):Wait()
	end
	
	local Region = HttpService:JSONDecode(workspace:GetAttribute("Region"))
	
	if (Region.City == nil) then
		RegionLabel.Text = `([{Region.Country}] - {Region.Region})`
	else
		RegionLabel.Text = `[{Region.Country}] {Region.City} - {Region.Region}`
	end
end)

local ClockCycles = 0
local ClockElapsed = 0
local ClockThreshold = 1
local LastFpsUpdate = 0
local Fps = 60

local CurrentDelta = 0

local ServerTimeStart = 0
local LastServerTimeNow = 0
local StartServerTimer = false

local function UpdateServerTimeStart()
	ServerTimeStart = workspace:GetAttribute("ServerTimeStart")
	LastServerTimeNow = workspace:GetServerTimeNow()
	StartServerTimer = true
end

if workspace:GetAttribute("ServerTimeStart") then
	UpdateServerTimeStart()
else
	workspace:GetAttributeChangedSignal("ServerTimeStart"):Connect(UpdateServerTimeStart)
end

local ServerTimeText = "Server Time: "
local UpdateTimeStep = 0

local function FPSAndPingStatisticsUpdate(Delta)
	if not StatisticsGUI.Enabled then return end
	
	ClockCycles += 1
	ClockElapsed += Delta
	CurrentDelta = Delta
	
	if (os.clock() - LastFpsUpdate >= ClockThreshold) then
		LastFpsUpdate = os.clock()
		Fps = ClockCycles // ClockElapsed
		ClockElapsed, ClockCycles = 0, 0
		UpdateTimeStep += 1
		
		local Ping = math.floor(Player:GetNetworkPing() * 1000)
		PerformanceLabel.Text = `{Ping}ms Ping - {Fps} FPS` 
		
		if StartServerTimer then
			if UpdateTimeStep >= 15 then -- roblox said using :GetServerTimeNow() is expensive so i do it sparingly
				UpdateTimeStep = 0
				LastServerTimeNow = workspace:GetServerTimeNow()
				ServerTimeLabel.Text = ServerTimeText .. ConvertToHMS((LastServerTimeNow - ServerTimeStart))
			else
				ServerTimeLabel.Text = ServerTimeText .. ConvertToHMS(((LastServerTimeNow + UpdateTimeStep) - ServerTimeStart))
			end
		end
	
	end
end

--task.spawn(function()
--	if not workspace:GetAttribute("ServerTimeStart") then
--		workspace:GetAttributeChangedSignal("ServerTimeStart"):Wait()
--	end
	
--	local ServerTime = workspace:GetAttribute("ServerTimeStart")
	
--	while task.wait(1) do
--		ServerTimeLabel.Text = Text .. (workspace:GetServerTimeNow() - ServerTime)
--	end
--end)

RunService.PostSimulation:Connect(FPSAndPingStatisticsUpdate)

StatisticsGUI:GetPropertyChangedSignal("Enabled"):Connect(function()
	if StatisticsGUI.Enabled then
		FPSAndPingStatisticsUpdate(CurrentDelta)
	end
end)