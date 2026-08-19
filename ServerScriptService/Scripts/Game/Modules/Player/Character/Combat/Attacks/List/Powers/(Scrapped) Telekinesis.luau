local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )
local Signal = require( ReplicatedStorage.Packages.Signal )

local RocksFolder = workspace.Map.Model.Props.Rocks

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)


----------------------------------------------------------------------------------
-- im scrapping all this 💔
function Attack:PickupRock()
	if not self.LuaCharacter.Telekenisis then
		self.LuaCharacter.Telekenisis = {
			Rocks = {},
		}
		
		local Attachment1 = self.LuaCharacter.Job:Task(Instance.new("Attachment"))
		Attachment1.Position = Vector3.new(-4, 2.5, 2)
		Attachment1.Parent = self.LuaCharacter.RootPart
		self.LuaCharacter.Telekenisis["RockAttachment1"] = Attachment1
		
		local Attachment2 = self.LuaCharacter.Job:Task(Instance.new("Attachment"))
		Attachment2.Position = Vector3.new(4, 2.5, 2)
		Attachment2.Parent = self.LuaCharacter.RootPart
		self.LuaCharacter.Telekenisis["RockAttachment2"] = Attachment2
	end
	
	-- Find Closest Rock
	local ClosestRock, ClosestPos = nil, nil
	for _, Rock in pairs(RocksFolder:GetChildren()) do
		if Rock:IsA("MeshPart") then
			local Distance = self.LuaPlayer.Player:DistanceFromCharacter(Rock.Position)
			if Distance < 40 then
				if (not ClosestPos or Distance < ClosestPos) and Rock.Transparency == 0 then
					ClosestRock = Rock
					ClosestPos = Distance
				end
			end
		end
	end
	
	if not ClosestRock then return end
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(self.SpeedDecrease)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Cooldown)
		self.Combat:TimesSpeed(self.SpeedDecrease)
		self.Combat:StackState("Attacking", false)
	end)
	
	local Rock = self.LuaCharacter.Job:Task(ClosestRock:Clone())
	
	ClosestRock.Transparency = 1
	task.delay(5, function()
		TweenService:Create(ClosestRock, TweenInfo.new(3), {Transparency = 0})
	end)
	
	self.Thread.Job:Task(self.Animations.Pickup:GetMarkerReachedSignal("Grab"):Connect(function()
		Rock.CanCollide = false
		Rock.CanQuery = false
		Rock.CanTouch = false
		
		Rock.Massless = true
		Rock.Anchored = false
		Rock.Parent = workspace.Visuals
		
		local RockCenter = Instance.new("Attachment")
		RockCenter.Parent = Rock
		
		local AlignPosition = script.AlignPosition:Clone()
		AlignPosition.Attachment0 = RockCenter
		AlignPosition.Parent = Rock
		
		local TargetAttachment = nil
		if #self.LuaCharacter.Telekenisis.Rocks == 0 then
			TargetAttachment = self.LuaCharacter.Telekenisis.RockAttachment1
		else
			TargetAttachment = self.LuaCharacter.Telekenisis.RockAttachment2
		end
		
		Rock.AssemblyAngularVelocity = Vector3.new(10, 10, 10)
		
		AlignPosition.Attachment1 = TargetAttachment
		table.insert(self.LuaCharacter.Telekenisis.Rocks, Rock)
		
		self.Rocks += 1
	end))
	
	self.Animations.Pickup:Play(0.1, 1, 1.25)
	
	self.Thread.Job:Task(self.Animations.Pickup.Stopped:Wait())
	self:Close()
end

function Attack:Activate()
	if self.Rocks < 2 then
		self:PickupRock()
		return
	end
	
	-- Throw
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(self.SpeedDecrease)

	
	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(self.Cooldown)
		self.Combat:TimesSpeed(self.SpeedDecrease)
		self.Combat:StackState("Attacking", false)
	end)
	
	--self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("Flash"):Connect(function()
		
	--end))
	
	self.Thread.Job:Task(self.Animations.Windup.Stopped:Wait())
	task.wait(0.5)
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.TryToCancelMoves = true
	self.SpeedDecrease = 10
	self.Cooldown = 1
	self.Rocks = 0

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack