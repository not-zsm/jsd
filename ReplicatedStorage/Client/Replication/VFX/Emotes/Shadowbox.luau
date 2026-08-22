local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local EffectUtility = require( ReplicatedStorage.Client.Replication.EffectUtility )
local AnimationRetriever = require( ReplicatedStorage.Client.Replication.VFX.AnimationRetriever )

local GUI = nil

local Connections = {}

local function SwapLeftRight(inputTable)
	local result = {}

	for i, value in ipairs(inputTable) do
		if value == "Left" then
			result[i] = "Right"
		elseif value == "Right" then
			result[i] = "Left"
		else
			result[i] = value 
		end
	end

	return result
end

return {
	ChooseDirection = function(AvailableDirections : Table, IsLeader : Bolean)
		if not IsLeader then
			AvailableDirections = SwapLeftRight(AvailableDirections)
		end
		
		if not GUI then
			warn("Shadowbox GUI not found")
			ReplicatedStorage.Remotes.Emotes.ChooseDirection:FireServer(AvailableDirections[math.random(1, #AvailableDirections)])
			return
		end
		
		GUI.Enabled = true
		
		for _, Button in pairs(GUI.Holder:GetChildren()) do
			if Button:IsA("ImageButton") then
				Button.Visible = false
			end
		end
		
		for _, Direction in pairs(AvailableDirections) do
			local Button : ImageButton = GUI.Holder[Direction]
			Button.Visible = true
			
			Connections[Direction] = Button.MouseButton1Click:Connect(function()
				if table.find(AvailableDirections, Direction) then
					GUI.Enabled = false
					ReplicatedStorage.Remotes.Emotes.ChooseDirection:FireServer(Direction)
				end
			end)
		end
	end,
	
	Setup = function(Character: Model)
		local Retrieved = AnimationRetriever.new(Character, ReplicatedStorage.Animations.Emotes.Shadowbox.Start)
		if (Retrieved == nil) then return end

		local Job = Retrieved.Job
		
		GUI = Job:Task(script.ShadowboxUI:Clone())
		GUI.Parent = PlayerGui
		GUI.Enabled = false
		
		Job:Task(function()
			for _, Connection in pairs(Connections) do
				Connection:Disconnect()
			end
			Connections = {}
		end)
	end
}
