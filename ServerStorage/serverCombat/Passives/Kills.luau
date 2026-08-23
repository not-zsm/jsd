local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )

return {
	["Gojo"] = function(self)
		self:GiveOneTriggerMove("Reverse Cursed Technique", Enum.KeyCode.R) 
	end,
	
	["Accelerator"] = function(self)
		self:GiveOneTriggerMove("Vector Reflection", Enum.KeyCode.R, 60)
	end,
	
	["Kratos"] = function(self)
		self:CreateAttack("Guardian Shield", Enum.KeyCode.R)
	end,
	
	["Meaty Michael"] = function(self)
		local RandomMoves = {"Drake's Love", "Drake's Embrace"}
		local Move = RandomMoves[math.random(1, #RandomMoves)]

		if Move then
			self:GiveOneTriggerMove(Move, Enum.KeyCode.R, 10)
		end
	end,
	
	["Anubis"] = function(self)
		local PassiveMultipliers = self.LuaCharacter.PassiveMultipliers
		
		if not self.LuaCharacter.PassiveMultipliers then
			self.LuaCharacter.PassiveMultipliers = 0
		end
		
		if self.LuaCharacter.PassiveMultipliers < 5 then
			self.LuaCharacter.PassiveMultipliers += 1

			self:PlusDamage(0.02)
			self:MinusDefense(0.01)
		end
		
		self.LuaPlayer.Replication:FireReliableVFX("Anubis/Adapt", "KillHighlight", self.LuaCharacter.Model, self.LuaCharacter.Combat.Sword)
		
		--local Config = {
		--	ChanceBuff = 30,
		--	BuffDuration = 20
		--}
		
		--local ChanceBuff = 30
		--local BuffDuration = 30
		
		local Adapt = self.LuaCharacter.Combat.Attacks["Adapt"]

		if not Adapt.AdaptChanceBuffActive then
			Adapt.AdaptChanceBuffActive = true
			Adapt.CurrentAdaptChance += Adapt.Config.KillAdaptChanceBuff
			
			if Adapt.AdaptChanceBuffThread then
				Utility.CloseThreadSafe(Adapt.AdaptChanceBuffThread)
			end
			
			Adapt.AdaptChanceBuffThread = task.delay(Adapt.Config.KillAdaptChanceDuration, function()
				Adapt.AdaptChanceBuffThread = nil
				Adapt.AdaptChanceBuffActive = false
				Adapt.CurrentAdaptChance -= Adapt.Config.KillAdaptChanceBuff
				
				self.LuaPlayer.Replication:FireReliableVFX("Anubis/Adapt", "DestroyBuffVFX", self.LuaCharacter.Model)
			end)
		end

		--Adapt.AdaptChanceBuffExpire = os.clock() + Adapt.Config.KillAdaptChanceDuration

		--if not Adapt.AdaptChanceBuffThread then
		--	Adapt.AdaptChanceBuffThread = task.spawn(function()
		--		while Adapt.AdaptChanceBuffActive do
					
		--			if os.clock() >= Adapt.AdaptChanceBuffExpire then
		--				Adapt.AdaptChanceBuffThread = nil
		--				Adapt.AdaptChanceBuffActive = false
		--				Adapt.CurrentAdaptChance -= Adapt.Config.KillAdaptChanceBuff
						
		--				self.LuaPlayer.Replication:FireReliableVFX("Anubis/Adapt", "DestroyBuffVFX", self.LuaCharacter.Model)
						
		--				break
		--			end
					
		--			task.wait(0.1)
		--		end
		--	end)
		--end
	end,
	
}