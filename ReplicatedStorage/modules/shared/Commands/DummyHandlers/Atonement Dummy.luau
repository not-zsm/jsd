local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )
local AI = require( ServerStorage.modules.AI )

local Job = require( ReplicatedStorage.modules.shared.Utilities.Job )

return function(LuaPlayer, NPCJob)
	local LuaCharacter = LuaPlayer.Character
	local Combat = LuaCharacter.Combat
	
	local Knife = LuaCharacter.Job:Task(ServerStorage.serverCombat.Characters.Chara.Knife:Clone())
	Knife.Parent = LuaCharacter.Model
	Knife.Weld.Part0 = LuaCharacter.RightArm

	local Attack = Combat:CreateAttack("Atonement", Enum.KeyCode.Five)

	local Entity = AI.new(LuaCharacter, require(script.Data))

	Entity.OnMoveBegin:Connect(function(Info : {})
		local Name = Info.Name
		local Move = Combat.Attacks[Info.Name]
		
		if Move then
			Move:Trigger()
		end
	end)
	
	local Animate = script.Animate:Clone()
	Animate.Parent = LuaCharacter.Model
	Animate.Enabled = true
end