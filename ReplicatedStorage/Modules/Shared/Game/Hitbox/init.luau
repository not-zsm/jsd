local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local EventService = require( ReplicatedStorage.Modules.Shared.Utilities.EventService )

local ActiveList = {}

---------------------------------

local Hitbox = {}
Hitbox.__index = Hitbox

---------------------------------

function Hitbox:GetHumanoidFrom(Model : Model)
	return Model:FindFirstChild("Humanoid")
end


function Hitbox:Valid()
	if typeof(self.Adornee) == "Instance" then
		return (self.Available and self.Adornee ~= nil and self.Adornee.Parent ~= nil)
	else
		return self.Available
	end
end


function Hitbox:OnIgnoreList(Item : (Model | BasePart))
	for _, Object in self.Params.Ignore do
		if (Item == Object) or Object:IsDescendantOf(Item) then
			return true
		end
	end

	return false
end


function Hitbox:AddToHit(Humanoid : Humanoid)
	if (Humanoid == nil) then
		return false
	end

	if self.Params.Recursive then
		self:HitHumanoid(Humanoid)
	else
		if (self.Params.MaxTargets ~= -1 and self.HitCount >= self.Params.MaxTargets) then
			return false
		end
		
		if (self.Humanoids[Humanoid] == nil) then
			self:HitHumanoid(Humanoid)
		end
	end

	return true
end


function Hitbox:HumanoidBeenHit(Humanoid : Humanoid)
	return (self.Humanoids[Humanoid] == true)
end


function Hitbox:HitHumanoid(Humanoid : Humanoid)
	local AddCount = (self.Humanoids[Humanoid] == nil)
	self.Humanoids[Humanoid] = true

	if AddCount then
		self.HitCount += 1
	end

	self.Events.HumanoidHit:Fire(Humanoid)
end


function Hitbox:RemoveHumanoid(Humanoid : Humanoid)
	local RemoveCount = (self.Humanoids[Humanoid] == true)
	self.Humanoids[Humanoid] = nil

	if RemoveCount then
		self.HitCount -= 1
	end
end


function Hitbox:Reset()
	table.clear(self.Humanoids)
	self.HitCount = 0
end


function Hitbox:BeginCast(Duration : number?)
	if ActiveList[self] then
		return
	end

	self:Reset()
	
	ActiveList[self] = true
	self.Events.OnCastBegin:Fire()
	
	task.defer(self.Detect, self, true)
	
	if (Duration ~= nil) then
		task.delay(Duration, self.EndCast, self)
	end
end


function Hitbox:EndCast()
	if (ActiveList[self] == nil) then
		return
	end

	ActiveList[self] = nil
	self.Events.OnCastEnded:Fire()

	if (self.DebugPart ~= nil) then
		self.DebugPart:Destroy()
		self.DebugPart = nil
	end
	
	if self.Params.DestroyOnEndCast then
		self:Destroy()
	end
end


function Hitbox:Destroy()
	if not self.Available then return end
	
	self.Available = false
	self.Events.OnDestroyed:Fire()
	self:Reset()
	
	for _, Event in self.Events do
		Event:Destroy()
	end
end

---------------------------------

function Hitbox.Create(Adornee, Params)
	assert(Adornee, "No adornee was provided.")
	assert(Params, "No params were given.")
	
	local self = {
		Frame = 0,

		Adornee = Adornee,
		Params = Params,

		Available = true,

		Humanoids = {},
		BehindHitHumanoids = {},
		
		HitCount = 0,
		
		Events = {
			HumanoidHit = EventService.new(),
			OnDestroyed = EventService.new(),
			OnCastBegin = EventService.new(),
			OnCastEnded = EventService.new(),
		}
	}

	setmetatable(self, Hitbox)
	return self
end

---------------------------------

RunService.PostSimulation:Connect(function()
	for self in ActiveList do
		self:Detect(true)
	end
end)

return Hitbox