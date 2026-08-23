

local UserInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local connect = require( replicatedStorage.modules.network.connect )
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------


local Job = require( replicatedStorage.modules.shared.Utilities.Job )
local NumberStack = require( replicatedStorage.modules.shared.Utilities.NumberStack )

----------------------------------------------------------------------------------

local FakeMouse = {}
FakeMouse.__index = FakeMouse	

function FakeMouse:Destroy()
	self.Job:Destroy()
end

function FakeMouse:_Init()
	self.Job:Task(connect(network.mouseAim, function(data, Player2 : Player)
		if self.LuaPlayer.Player ~= Player2 then return end

		self:Update(data.hit, data.target)
	end))
end

function FakeMouse:IsRequesting()
	return (self.RequestStack:IsTrue())
end
	
function FakeMouse:BeginRequesting(Duration : number, MouseAimPreset : string?)
	if not self:IsRequesting() then
	
		if not self.LuaPlayer.IsNPC then
			network.requestMouseAim.sendTo({ active = true, preset = MouseAimPreset }, self.LuaPlayer.Player)
		end

		if (Duration) then
			task.delay(Duration or 1, self.EndRequesting, self)
		end

		self.RequestStack:Add()
	end
end

function FakeMouse:EndRequesting(Duration : number)
	if self:IsRequesting() then
		self.RequestStack:Subtract()
		
		if not self:IsRequesting() and not self.LuaPlayer.IsNPC then
			network.requestMouseAim.sendTo({ active = false }, self.LuaPlayer.Player)
		end
	end
end

function FakeMouse:Update(Hit : CFrame, Target : Model?)
	self.Hit = Hit
	self.Target = Target
	
	--if (Target ~= nil and typeof(Target) == "Instance" and Target:IsA("Model")) then
	--	self.Target = Target
	--end
end

function FakeMouse.new(Combat)
	local self = setmetatable({}, FakeMouse)

	self.Combat = Combat
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaPlayer

	self.Hit = CFrame.identity
	self.Target = nil :: Model?

	self.RequestStack = NumberStack.new()
	self.Requesting = false

	self.Job = Job.new()

	self:_Init()

	return self
end

table.freeze(FakeMouse)

return FakeMouse