local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local AenoirEmit = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.AenoirEmit )
local LocalPlayer = Players.LocalPlayer

local VFX = {}

function VFX.new()
	local Steak = script.SteakGui:Clone()
	Steak.Enabled = true;
	Steak.Parent = LocalPlayer.PlayerGui;

	local Tween = TweenService:Create(Steak.Michael, TweenInfo.new(0.5), {ImageTransparency = 1})
	Tween:Play()
	
	Tween.Completed:Once(function()
		Steak:Destroy();
	end)

	AenoirEmit(script.SteakJumpscare, Steak);
end

return VFX