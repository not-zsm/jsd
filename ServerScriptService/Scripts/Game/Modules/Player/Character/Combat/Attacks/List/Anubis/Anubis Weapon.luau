local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:Sheathe()
	self.SheathedStack += 1
	
	if self.SheathedStack > 1 then
		return
	end
	
	self.Combat.Sword.Handle.Part0 = self.SheathedPart
	self.Combat.Sword.Handle.C0 = self.SheathedOffset
end

function Attack:Unsheathe()
	self.SheathedStack = math.clamp(self.SheathedStack - 1, 0, math.huge)
	
	if self.SheathedStack ~= 0 then
		return
	end
	
	self.Combat.Sword.Handle.Part0 = self.UnsheathedPart
	self.Combat.Sword.Handle.C0 = self.UnsheathedOffset
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.CoreCharacter = true;
	self.SheathedStack = 0
	
	self.SheathedOffset = CFrame.new(0.022277832, -0.0242147446, -1.83789062, -1, 0, 0, 0, 1, 0, 0, 0, -1)
	self.UnsheathedOffset = CFrame.new(-0.0566635132, -0.952118874, -0.0264379978, 0.999913812, -0.00926470011, -0.00974644721, 0.00916702114, 0.999910772, -0.0100231897, 0.00983847026, 0.00993294362, 0.999905288)
	
	self.SheathedPart = self.Combat.Sheathe.Model.PrimaryPart
	self.UnsheathedPart = self.LuaCharacter.RightArm
	
	self:_Init()
	
	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack