local TextChatService = game:GetService("TextChatService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )

local Settings = {
	SpeedDecrease = 10
}

return {
	Template = script["Helmet of Peace"],
	
	Object = nil,
	HelmetObject = nil,
	Name = "Helmet of Peace",
	
	PutOn = false,
	OnCooldown = false,
	UsesLeft = 3,
	
	Config = {
		Cooldown = 3
	},
	
	--Equipped = function(self)
	--	print("Equipped")
	--end,
	
	
	--OnPickedUp = function(self, Item)
	--	Item.Object["Peacekeeper helmet"].Transparency = 1
	--end,
	
	--Unequipped = function(self)
	--	print("Unequipped")
	--end,
	
	Triggered = function(self)
		local Item = self.EquippedItem
		
		if Item.OnCooldown then return end
		
		if not Item.PutOn then
			Item.OnCooldown = true			
			self.Combat:StackState("Attacking", true)
			self.Combat:StackState("HitboxImmunity", true)
			self.Combat:DivideSpeed(50)
			
			local EquipAnimation = self.LuaCharacter:LoadAnimation(replicatedStorage.Animations.Items["Helmet Of Peace"].Use)
			EquipAnimation:Play()
			
			local SFX = script.SFX:Clone()
			SFX.Parent = self.LuaCharacter.RootPart
			task.delay(4, SFX.Destroy, SFX)
			SFX:Play()
			
			Item.Job:Task(EquipAnimation.Stopped:Once(function()
				EquipAnimation:Stop(0.5)
				self.Combat:StackState("Attacking", false)
				self.Combat:StackState("HitboxImmunity", false)
				self.Combat:TimesSpeed(50)
				
				Item.Object.RHand["Peacekeeper helmet"].Transparency = 1

				Item.HelmetObject = Item.Job:Task(script["Peacekeeper helmet"]:Clone())
				Item.HelmetObject.Weld.Part0 = self.LuaCharacter.Head
				Item.HelmetObject.Parent = self.LuaCharacter.Model
				
				Item.PutOn = true
				self.PeacemakerHelmet = Item
				self.UnusableItems["Helmet of Peace"] = true
				Item.Job:Task(function()
					self.UnusableItems["Helmet of Peace"] = nil
				end)
				
				task.delay(3, function()
					if Item then
						Item.OnCooldown = false
					end
				end)
				
				-- Listen for player's message
				Item.Job:Task(self.LuaPlayer.Player.Chatted:Connect(function(Message : String)
					if not Item.OnCooldown and string.match(string.lower(Message), "activate sonic boom") then
						if Item.UsesLeft > 0 then
							Item.UsesLeft -= 1
							Item.OnCooldown = true
							self:UseMove("Helmet of Peace")

							task.delay(Item.Config.Cooldown, function()
								if Item then
									Item.OnCooldown = false
								end
							end)
						end
					end
				end))
			end))
		end
	end,
}