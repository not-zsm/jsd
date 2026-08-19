local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

return {
	RestrictSetCharacter = true,
	GitHubWhitelist = "Hornet",

	FrontDash = {
		StartSpeed = 1,
		MiddleSpeed = 0.85
	},

	--Stats = {
	--	M1 = {
	--		Speed = 1,
	--		EndlagAfterSwing = 0.075
	--	},
	--},

	Attacks = {
		-- ["Sprint"] = Enum.KeyCode.LeftControl -- Scrapped
		["Bind"] = Enum.KeyCode.R
	},

	OnSpawn = function(LuaPlayer, UseDescription : boolean?)
		do
			local Needle = script.Needle:Clone()
			local Weld = Needle.Weld
			Weld.Part0 = LuaPlayer.Character.RightArm
			Needle.Parent = LuaPlayer.Character.Model

			LuaPlayer.Character.Needle = {
				Model = Needle,
				Handle = Needle.RHand,
				Weld = Weld
			}
		end
		
		do
			local Cloak = script["Cloak"]:Clone()
			
			LuaPlayer.Character.Cloak = {
				Model = Cloak,
			}
			
			local CloakTorso = Cloak.Torso
			CloakTorso.Weld.Part0 = LuaPlayer.Character.Torso
			
			-- Segments
			LuaPlayer.Character.Cloak["Middle"] = {
				Model = CloakTorso,
				Weld = CloakTorso.Weld
			}
			
			local LeftShoulder = Cloak.LeftShoulder
			LeftShoulder.Weld.Part0 = LuaPlayer.Character.LeftArm
			
			LuaPlayer.Character.Cloak["Left"] = {
				Model = LeftShoulder,
				Weld = LeftShoulder.Weld
			}
			
			local RightShoulder = Cloak.RightShoulder
			RightShoulder.Weld.Part0 = LuaPlayer.Character.RightArm
			
			LuaPlayer.Character.Cloak["Right"] = {
				Model = RightShoulder,
				Weld = RightShoulder.Weld
			}
			
			Cloak.Parent = LuaPlayer.Character.Model
		end
		
		LuaPlayer.Character.Combat:CreateAttack("Silk")
		LuaPlayer.Character.Combat:CreateAttack("Dive Nail")
		LuaPlayer.Character.Silk = LuaPlayer.Character.Combat.Attacks["Silk"]
	end,

	OnRemoved = function(LuaPlayer)
		if LuaPlayer.Character.Needle then
			local Model = LuaPlayer.Character.Needle.Model
			
			if Model then
				Model:Destroy()
			end
			
			LuaPlayer.Character.Needle = nil
		end
		
		if LuaPlayer.Character.Cloak then
			local Model = LuaPlayer.Character.Cloak.Model
			
			if Model then
				Model:Destroy()
			end
			
			LuaPlayer.Character.Cloak = nil
		end
		
		LuaPlayer.Character.Combat:RemoveAttack("Silk")
		LuaPlayer.Character.Combat:RemoveAttack("Dive Nail")
		
		LuaPlayer.Character.Silk = nil
	end,
}