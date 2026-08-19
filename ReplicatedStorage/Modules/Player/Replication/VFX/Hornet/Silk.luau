local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )
local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )

local Meter = nil

local SilkIds = {
	[0] = "rbxassetid://76692539706815",
	[1] = "rbxassetid://122860555962788",
	[2] = "rbxassetid://80176937783467",
	[3] = "rbxassetid://78631976505412",
	[4] = "rbxassetid://139899671269563",
	[5] = "rbxassetid://91772468044196",
	[6] = "rbxassetid://138001342337998",
	[7] = "rbxassetid://133144220321048",
	[8] = "rbxassetid://139871164442594",
	[9] = "rbxassetid://102550541192280",
}

local function Preload(UI)
	for Index, SilkId in pairs(SilkIds) do
		local Image : ImageLabel = UI.Preload.Template:Clone()
		Image.Image = SilkId
		
		Image.Parent = UI.Preload
		Image.Visible = true
	end
end

return {
	CreateMeter = function()
		Meter = script:WaitForChild("Meter"):Clone()
		Meter.Parent = LocalPlayer.PlayerGui
		
		Preload(Meter)
	end,
	
	Update = function(NewTotal : Number)
		if Meter then
			Meter.Holder.ImageLabel.Image = SilkIds[NewTotal]
		end
	end,
	
	DestroyMeter = function()
		if Meter then
			Meter:Destroy()
			Meter = nil
		end
	end,
}

