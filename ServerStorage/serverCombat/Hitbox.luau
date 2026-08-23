

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")
----------------------------------------------------------------------------------

local Shared = ReplicatedStorage.modules.shared

local SharedUtilities = Shared.Utilities

----------------------------------------------------------------------------------

local LuaPlayerList = require( ServerStorage.modules.LuaPlayerList )

local Destruction = require( ServerStorage.modules.Destruction )
local HavocHandler = require( ServerStorage.modules.HavocHandler )

local Box = require( ReplicatedStorage.modules.shared.Game.Hitbox.Type.Box )
local Sphere = require( ReplicatedStorage.modules.shared.Game.Hitbox.Type.Sphere )

local EventService = require( ReplicatedStorage.modules.shared.Utilities.EventService )

local Hitbox = {}
Hitbox.__index = Hitbox

local Utility = require( SharedUtilities.Utility )

----------------------------------------------------------------------------------

function Hitbox:ValidateModel(Humanoid : Humanoid) : (boolean, any)
	local VictimLuaPlayer = LuaPlayerList.Get(Humanoid)
	local Validated = self:ValidatePlayer(VictimLuaPlayer)

	return Validated, VictimLuaPlayer
end


function Hitbox:ValidatePlayer(VictimLuaPlayer)
	if (VictimLuaPlayer == nil) then return false end

	local VictimLuaCharacter = VictimLuaPlayer.Character
	local VictimCombat = VictimLuaCharacter.Combat

	return (not VictimCombat:GetState("HitboxImmunity") and VictimLuaCharacter.HumanoidExists)
end


function Hitbox:Create(UseSphere : boolean)
	if not self.LuaCharacter.HumanoidExists then return end

	local Params = UseSphere and Sphere.NewParams() or Box.NewParams()
	Params.Ignore = {self.LuaCharacter.Model}
	Params.Debug = workspace:GetAttribute("HitboxVisible")

	local Adornee : BasePart = self.Combat:GetSimulatedRoot()

	local Hitbox = UseSphere and Sphere.new(Adornee, Params) or Box.new(Adornee, Params)
	Hitbox.Events.OnLuaPlayerHit = EventService.new()

	Hitbox.Events.HumanoidHit:Connect(function(Humanoid : Humanoid)
		local Validated, VictimLuaPlayer = self:ValidateModel(Humanoid)

		if Validated then
			if VictimLuaPlayer.Character.Combat.IsChara and not self.Combat:CanDamageAI() then
				return
			end
		
			Hitbox.Events.OnLuaPlayerHit:Fire(VictimLuaPlayer)
		end
	end)

	return Hitbox
end

function Hitbox:AoeHitboxForGrabs(GrabbedLuaPlayer, Offset : CFrame, Size : Vector3, UseSphere : boolean)
	local Hitbox = self:Create(UseSphere)
	Hitbox.Params.Offset = Offset
	Hitbox.Params.Size = Size
	Hitbox.Params.Ignore = {self.LuaCharacter.Model, GrabbedLuaPlayer.Character.Model}

	return Hitbox
end

function Hitbox:ClientSidedDestructionLoop(Offset : CFrame, Size : Vector3, Power : number)
	if self.LuaPlayer.IsNPC then 
		warn("an npc has ran client sided destruction loop, which does not do anything.")
		return function() end
	end

	local Cleaned = false

	if (self.LuaPlayer.Player.Parent ~= nil) then
		self.Replication.Attributes:SetAttribute("DestructibleDestroyLoop", true)

		if Power then
			self.Replication.Attributes:SetAttribute("DestructibleDestroyLoopPower", Power)
		end
	end

	local function Clean()
		if Cleaned then return end
		Cleaned = true

		if (self.LuaPlayer.Player.Parent ~= nil) then
			self.Replication.Attributes:SetAttribute("DestructibleDestroyLoop", nil)

			if Power then
				self.Replication.Attributes:SetAttribute("DestructibleDestroyLoopPower", nil)
			end
		end
	end

	if (self.LuaPlayer.Player.Parent ~= nil) then
		self.LuaPlayer.Remotes.DestructibleDestroyLoop:FireClient(self.LuaPlayer.Player, Offset, Size)
	end

	return Clean
end

function Hitbox:Destruction(Offset : CFrame, Size : Vector3, Power : number, CustomCallback : string)
	if self.LuaCharacter.HumanoidExists then
		local Adornee : BasePart = self.Combat:GetSimulatedRoot()
		local CF = Adornee.CFrame * Offset
		
		Destruction.Detect(
			CF, 
			Size, 
			Power, 
			CustomCallback
		)
	end
end

function Hitbox:DestructionAt(CF : CFrame, Size : Vector3, Power : number, CustomCallback : string)
	if self.LuaCharacter.HumanoidExists then 
		Destruction.Detect(CF, Size, Power, CustomCallback)
	end
end

function Hitbox:SphereDestruction(Position : Vector3, Size : number, Power : number, CustomCallback : string)
	if self.LuaCharacter.HumanoidExists then
		Destruction.SphereDetect(Position, Size, Power, CustomCallback)
	end
end 

function Hitbox:OffsetHitboxOnVelocity(HitboxObject, Divide : number)
	Divide = Divide or 15
	
	local Offset : CFrame = HitboxObject.Params.Offset

	local Connection = RunService.PostSimulation:Connect(function()
		local CF : CFrame = self.LuaCharacter.RootPart.CFrame
		local VelocityOffset : Vector3 =  CF:VectorToObjectSpace(self.LuaCharacter.RootPart.AssemblyLinearVelocity) / Divide
		HitboxObject.Params.Offset = Offset * CFrame.new(VelocityOffset)
	end)

	return Connection
end

function Hitbox:CreateHavocReplicated(tbl : {})
	if shared.IsRankedLobby or shared.IsRankedPlace then
		return
	end
	
	local parameters = tbl.parameters
	local crater = tbl.crater or {}
	local debris = tbl.debris
	
	local havoc = HavocHandler:create_replicated(parameters)

	local destructed, crater, debris = havoc:destruct({
		crater = crater,
		debris = debris
	});
	
	if (tbl.effects == nil or tbl.effects) then
		HavocHandler:create_effects_from(havoc);
	end
	
	return havoc, destructed, crater, debris
end

--function Hitbox:OffsetHitboxOnPingAndVelocity(HitboxObject)
--	local Offset : CFrame = HitboxObject.Params.Offset
--	local Ping = 0.1 -- self.LuaPlayer.Player:GetNetworkPing() -- Returns ping in seconds

--	local ScaledValue = 10 - (Ping * 40)
--	ScaledValue = math.clamp(ScaledValue, 5, 30)

--	print(`ping: "`, tostring(Ping * 1000), `" ping in seconds: "`, tostring(Ping), `"`)
--	print("scaled ping value:", ScaledValue)

--	local Connection = RunService.PostSimulation:Connect(function()
--		local CF : CFrame = self.LuaCharacter.RootPart.CFrame
--		local VelocityOffset : Vector3 =  CF:VectorToObjectSpace(self.LuaCharacter.RootPart.AssemblyLinearVelocity) / ScaledValue
--		HitboxObject.Params.Offset = Offset * CFrame.new(VelocityOffset)
--	end)

--	return Connection
--end

function Hitbox.new(Combat)
	local self = setmetatable({}, Hitbox)

	self.Combat = Combat
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaPlayer
	self.Replication = Combat.LuaPlayer.Replication

	return self
end

----------------------------------------------------------------------------------

table.freeze(Hitbox)

return Hitbox