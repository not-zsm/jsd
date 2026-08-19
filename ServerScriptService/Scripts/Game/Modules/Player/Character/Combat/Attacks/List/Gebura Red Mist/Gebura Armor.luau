local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:SwitchArmor(Value : boolean)
	if Value ~= self.UltimateForm then
		
		if (Value and self.ArmorFolder == nil) then
			self.ArmorFolder = Instance.new("Folder")
			self.ArmorFolder.Name = "Armor"
			
			for _, Item in ipairs(script.Armor:GetDescendants()) do
				if Item:IsA("BasePart") then
					local NewArmor = Item:Clone()
					
					local Weld = NewArmor:FindFirstChild("Weld")
					local WeldOn = NewArmor:GetAttribute("WeldOn")

					if Weld and WeldOn then
						local Limb = self.LuaCharacter.Model:FindFirstChild(WeldOn)
						
						if Limb then
							Weld.Part1 = Limb
						end
					end
					
					NewArmor.Parent = self.ArmorFolder
				end
			end

			self.ArmorFolder.Parent = self.LuaCharacter.Model
			
		elseif (not Value and self.ArmorFolder ~= nil) then
			self.ArmorFolder:Destroy()
			self.ArmorFolder = nil
		end
		
		self.InUltimateForm = Value
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	
	self.InUltimateForm = false
	self.ArmorFolder = nil

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack