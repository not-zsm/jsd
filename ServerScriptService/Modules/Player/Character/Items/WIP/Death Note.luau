local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )

local Settings = {
	SpeedDecrease = 10
}

return {
	Template = script["Death Note"],
	
	Object = nil,
	IdleAnimation = true,
	Name = "Death Note",
	
	OnPickedUp = function(self, Item)
		local Pen = Item.Job:Task(script.Pen:Clone())
		Pen.Weld.Part0 = self.LuaCharacter.RightArm
		Pen.Parent = Item.Object
		
		Item.Job:Task(function()
			self.LuaPlayer.Replication:FireReliableVFXToSelf("Items/Death Note", "Use/Destroy", self.LuaCharacter.Model)
		end)
	end,
	
	--Equipped = function(self)
	--	print("Equipped")
	--end,
	
	--Unequipped = function(self)
	--	print("Unequipped")
	--end,
	
	Triggered = function(self)
		self:UseMove("DN Use")
	end,
}