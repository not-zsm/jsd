-- @author Swordphin123

local replicatedStorage = game:GetService("ReplicatedStorage")
local EventService = require( replicatedStorage.modules.shared.Utilities.EventService )

local RaycastHitbox = {}
RaycastHitbox.__index = RaycastHitbox

function RaycastHitbox.new(Object : BasePart)
	local self = {}
	setmetatable(self, require(script.HitboxCaster))
	
	self.Object = Object
	self.Visualizer = false
	
	self.Active = false
	self.Point = {}

	self.Hit = {}
	self.OnHit = EventService.new()

	self:_Init()

	return self
end

return RaycastHitbox