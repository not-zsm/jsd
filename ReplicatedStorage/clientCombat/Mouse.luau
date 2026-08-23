local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local CurrentCamera = workspace.CurrentCamera

----------------------------------------------------------------------------------

local Remotes = ReplicatedStorage.Remotes

local FakeMouseRemotes = Remotes.Combat.FakeMouse

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )
local AimAssist = require( ReplicatedStorage.modules.shared.Game.AimAssist )
local AimPresets = require( script.AimPresets )

----------------------------------------------------------------------------------

local FakeMouse = {}
FakeMouse.__index = FakeMouse	

function FakeMouse:AimTo(Value : boolean, Preset : string?)
	if not self.LuaCharacter.HumanoidAlive then return end

	if Value then
		if (self.AimGyro == nil) then
			if (Preset and AimPresets[Preset] ~= nil) then
				local Gyro = AimPresets[Preset](self)
				self.AimGyro = Gyro
			else
				local Gyro = Instance.new("BodyGyro")
				Gyro.MaxTorque = Vector3.new(0, 1, 0) * 600000
				Gyro.D = 100
				Gyro.P = 10000

				local function Update()
					local Position : Vector3 = self.LuaCharacter.RootPart.Position
					local LookAt : Vector3 = self.LuaPlayer.Mouse.Hit.LookVector * Vector3.new(1, 0, 1)

					Gyro.CFrame = CFrame.lookAlong(Position, LookAt)
				end

				Update()
				RunService:BindToRenderStep("AimToMouseGyroUpdate", Utility.CharacterRenderPriority, Update)

				Gyro.Destroying:Once(function()
					RunService:UnbindFromRenderStep("AimToMouseGyroUpdate")
				end)

				Gyro.Parent = self.LuaCharacter.RootPart
				self.AimGyro = Gyro
			end
		end
	else
		if (self.AimGyro ~= nil) then
			self.AimGyro:Destroy()
			self.AimGyro = nil
		end
	end
end

--function FakeMouse:AimAssist(Origin : Vector3, UnitDirection : Vector3, Distance : number) : Model
--	local Value, Target = Distance, nil

--	for _, Man : Model in CollectionService:GetTagged("Men") do
--		if table.find(self.Params.FilterDescendantsInstances, Man) then continue end

--		local Position = Man:GetBoundingBox().Position
--		local Magnitude = UnitDirection:Cross(Position - Origin).Magnitude

--		if (Magnitude < Value) then
--			Target = Man
--			Value = Magnitude
--		end
--	end

--	return Target
--end

function FakeMouse:Check()
	if (self.Params == nil) then return end
	
	--local Inset = GuiService:GetGuiInset()
	--local Location = UserInputService:GetMouseLocation()
	
	--local Point = CurrentCamera:ScreenPointToRay(Location.X, Location.Y - Inset.Y, 2 ^ 17)
	--local Origin = CurrentCamera.CFrame.Position

	--local Target = self:AimAssist(Origin, Point.Direction, 5)
	
	local Target : Humanoid? = AimAssist.get(5, 200, CollectionService:GetTagged("ManHumanoid"))
	local Target_Model : Model = Target and Target.Parent
	
	return self.LuaPlayer.Mouse.Hit, Target_Model
end

function FakeMouse:CleanRequestLoop()
	if (self.UpdateLoop ~= nil and self.UpdateLoop.Connected) then
		self.UpdateLoop:Disconnect()
	end
end

function FakeMouse:InitializeHumanoidAvailability()
	local function OnAvailabilityEvent(Value)
		self.Params = RaycastParams.new()
		self.Params.FilterType = Enum.RaycastFilterType.Exclude
		self.Params.FilterDescendantsInstances = {workspace.Visuals, self.LuaCharacter.Model}
	end
	
	if self.LuaCharacter.HumanoidAlive then
		OnAvailabilityEvent(true)
	end

	self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(OnAvailabilityEvent)
end

function FakeMouse.new(Combat)
	local self = setmetatable({}, FakeMouse)

	self.Combat = Combat
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaPlayer

	self.Params = RaycastParams.new()
	self.Params.FilterType = Enum.RaycastFilterType.Exclude
	self.Params.FilterDescendantsInstances = {workspace.Visuals}

	self.UpdateLoop = nil

	FakeMouseRemotes.RequestUpdate.OnClientEvent:Connect(function(Value : boolean, MouseAimPreset : string?)
		if Value then
			
			if (MouseAimPreset ~= nil) then
				
				if (MouseAimPreset == "Default") then
					self:AimTo(true)
				else
					self:AimTo(true, MouseAimPreset)
				end
				
			end
			
			self:CleanRequestLoop()
			
			self.UpdateLoop = RunService.PreRender:Connect(function()
				FakeMouseRemotes.UpdateAsRequested:FireServer(self:Check())
			end)
		else
			self:AimTo(false)
			self:CleanRequestLoop()
		end
	end)
	
	self:InitializeHumanoidAvailability()

	return self
end

table.freeze(FakeMouse)

return FakeMouse