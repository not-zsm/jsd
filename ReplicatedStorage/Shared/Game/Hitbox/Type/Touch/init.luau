local Type = script.Parent
local Hitbox = require(Type.Parent)
local Params = require(script.Params)

local Touch = {}
Touch.__index = Touch

setmetatable(Touch, Hitbox)

---------------------------------

function Touch:BeginCast()
	self.ActiveEvent = self.Adornee.Touched:Connect(function(Part)
		
		local Model = Part:FindFirstAncestorWhichIsA("Model")
		
		if not (Model and Model:IsA("Model")) then
			return
		end

		local Humanoid = self:GetHumanoidFrom(Model)
		
		if (Humanoid == nil or self:OnIgnoreList(Model)) then-- or self:HasBeenHit(Humanoid) then
			return
		end
		
		self:AddToHit(Humanoid)
	end)
end

function Touch:EndCast()
	if self.ActiveEvent and self.ActiveEvent.Connected then
		self.ActiveEvent:Disconnect()
		self.ActiveEvent = nil
	end
end

---------------------------------

local Main = {}
Main.NewParams = Params.new

function Main.new(Adornee, Params)
	local self = Hitbox.Create(Adornee, Params)

	setmetatable(self, Touch)
	return self
end

return Main