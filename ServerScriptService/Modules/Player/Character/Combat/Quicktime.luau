local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteHandler = ReplicatedStorage.Remotes.CreateQT

local EventService = require(ReplicatedStorage.Shared.Utilities.EventService)
local Job = require(ReplicatedStorage.Shared.Utilities.Job)

local QuicktimeHandler = {}
QuicktimeHandler.__index = QuicktimeHandler

type object = {
	Owner : Player,
	
	Job : Job.object,
	Destroyed : boolean,
	
	Range : NumberRange,
	Key : Enum.KeyCode,
	
	OnUpdate : EventService.object,
	RecievedInput : boolean,
}

local Active: { [object]: boolean } = {}

function QuicktimeHandler.new(Player : Player, Key : Enum.KeyCode, ControllerKey : Enum.KeyCode, Range : NumberRange): QuicktimeEvent & typeof(object)
	local self = setmetatable({}, QuicktimeHandler) :: QuicktimeEvent & typeof(object)
	self.Owner = Player
	
	self.Job = Job.new()
	self.Destroyed = false
	
	self.Range = Range
	
	self.Key = Key
	self.ControllerKey = ControllerKey

	self.OnUpdate = self.Job:Task(EventService.new())
	self.RecievedInput = false
	
	self:_Init()

	return self
end

function QuicktimeHandler._Init(self : object)
	if not self.Owner:IsA("Player") then 
		return warn("dummies cannot do qte's")
	end
	
	local NetworkPing = self.Owner:GetNetworkPing()

	if math.ceil(NetworkPing * 1000) >= 100 then
		local Added = math.abs(NetworkPing * 1.5)
		local NewRange = NumberRange.new(self.Range.Min + Added, self.Range.Max + Added)
		
		self.Range = NewRange
	end

	self.Job:Task(task.delay(self.Range.Max, function()
		if not self.RecievedInput then
			self.OnUpdate:Fire(false)
			
			task.defer(function()
				self:Destroy()
			end)
		end
	end))

	self.Job:Task(self.Owner.AncestryChanged:Connect(function(_, Parent)
		self:Destroy()
	end))

	Active[self] = true
	RemoteHandler:FireClient(self.Owner, self.Key, self.ControllerKey, self.Range)
	
	self.Job:Task(RemoteHandler.OnServerEvent:Connect(function(Player : Player, Success : boolean)
		if self.Owner ~= Player then return end
		if typeof(Success) ~= "boolean" then return end

		self.RecievedInput = true
		self.OnUpdate:Fire(Success)
	
		task.defer(function()
			self:Destroy()
		end)
	end))
end

function QuicktimeHandler.Destroy(self : object)
	if self.Destroyed then return end
	self.Destroyed = true
	
	Active[self] = nil
	self.Job:Destroy()
end

return QuicktimeHandler