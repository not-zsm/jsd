--- Weather, was a LocalScript under StarterPlayerScripts. Body unchanged.
return {
	Name = "Weather",
	Priority = 100,
	Async = true,

	Start = function()
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end

		local replicatedStorage = game:GetService("ReplicatedStorage")
		local Players = game:GetService("Players")
		local TweenService = game:GetService("TweenService")

		if workspace:GetAttribute("IsRankedLobby") or workspace:GetAttribute("IsRankedPlace") then
			return
		end

		local Player = Players.LocalPlayer
		local Weather = require( replicatedStorage.modules.client.weather )

		local ACTOR_THREADS = 5

		local Threads = {} :: {Actor}

		local Effects = Instance.new("Attachment")
		Effects.Name = "RainEffects"
		Effects.Parent = workspace.Terrain

		local Raining = false

		local function StartRain(Settings)
			Raining = true
	
			TweenService:Create(workspace.Terrain.Clouds, TweenInfo.new(2), {
				Cover = 0.85
			}):Play()

			workspace.DefaultAmbience:Stop()
			workspace.RainStart:Play()
			workspace.RainAmbience:Play()

			local DistributedSettings = table.clone(Settings or Weather.defaults)

			if DistributedSettings.RainDensity then
				DistributedSettings.RainDensity /= ACTOR_THREADS
			end

			for Index, Actor in pairs(Threads) do
				Actor:SendMessage("StartRain", Index == 1, DistributedSettings)
			end
		end

		local function EndRain(Settings)
			Raining = false
	
			TweenService:Create(workspace.Terrain.Clouds, TweenInfo.new(2), {
				Cover = 0.613
			}):Play()

			workspace.RainAmbience:Stop()
			workspace.DefaultAmbience:Play()

			for _, Actor in pairs(Threads) do
				Actor:SendMessage("EndRain")
			end
		end

		-- this module lives in replicatedStorage now, where a LocalScript will
		-- not run, so the actors have to be parented into PlayerScripts. The
		-- template stays put rather than being destroyed, since it is shared.
		local Holder = Instance.new("Folder")
		Holder.Name = "WeatherThreads"
		Holder.Parent = Player:WaitForChild("PlayerScripts")

		for Index = 1, ACTOR_THREADS do
			local Actor = script.Main:Clone()
			Actor.Name = "Thread" .. Index
			Actor.Script.Enabled = true
			Actor.Parent = Holder

			table.insert(Threads, Actor)
		end

		task.wait(5 / 60)

		if workspace:GetAttribute("Rain") and Player:GetAttribute("Rain") then
			StartRain()
		end

		workspace:GetAttributeChangedSignal("Rain"):Connect(function()
			if workspace:GetAttribute("Rain") and Player:GetAttribute("Rain") then
				StartRain()
			else
				EndRain()
			end
		end)

		Player:GetAttributeChangedSignal("Rain"):Connect(function()
			if Raining and not Player:GetAttribute("Rain") then
				EndRain()
		
			elseif workspace:GetAttribute("Rain") and Player:GetAttribute("Rain") then
				StartRain()
			end
		end)
	end,
}
