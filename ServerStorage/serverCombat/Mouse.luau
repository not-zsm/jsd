

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local Remotes = ReplicatedStorage.Remotes
local FakeMouseRemotes = Remotes.Combat.FakeMouse

local Job = require( ReplicatedStorage.modules.shared.Utilities.Job )
local NumberStack = require( ReplicatedStorage.modules.shared.Utilities.NumberStack )

----------------------------------------------------------------------------------

local FakeMouse = {}
FakeMouse.__index = FakeMouse	

function FakeMouse:Destroy()
	self.Job:Destroy()
end

function FakeMouse:_Init()
	local function OnEvent(Player2 : Player, Hit : CFrame, Target : Model?)
		if self.LuaPlayer.Player ~= Player2 then return end
		
		if typeof(Hit) == "CFrame" then
			self:Update(Hit, Target)
		end
	end
	
	self.Job:Task(FakeMouseRemotes.UpdatePosition.OnServerEvent:Connect(OnEvent))
	self.Job:Task(FakeMouseRemotes.UpdateAsRequested.OnServerEvent:Connect(OnEvent))
end

function FakeMouse:IsRequesting()
	return (self.RequestStack:IsTrue())
end
	
function FakeMouse:BeginRequesting(Duration : number, MouseAimPreset : string?)
	if not self:IsRequesting() then
	
		if not self.LuaPlayer.IsNPC then
			FakeMouseRemotes.RequestUpdate:FireClient(self.LuaPlayer.Player, true, MouseAimPreset)
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
			FakeMouseRemotes.RequestUpdate:FireClient(self.LuaPlayer.Player, false)
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