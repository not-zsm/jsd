
local ServerScriptService = game:GetService("ServerScriptService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ServerStorage = game:GetService("ServerStorage")
----------------------------------------------------------------------------------

local Remotes = ReplicatedStorage.Remotes
local ProjectileRemotes = Remotes.Projectile

local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )

local Job = require( ReplicatedStorage.modules.shared.Utilities.Job )
local EventService = require( ReplicatedStorage.modules.shared.Utilities.EventService )

local Destruction = require( ServerStorage.modules.Destruction )

----------------------------------------------------------------------------------

local Projectile = {}
Projectile.__index = Projectile

local DownwardVector = Vector3.yAxis * -30

@native function Projectile:Update(Delta : number)
	if not self.Active then return end

	if self.Traveled >= self.MaxDistance or (os.clock() - self.StartTime) > self.MaxTime then
		self.OnExpire:Fire()
		return self:Destroy()
	end
	
	local Position : Vector3 = self.Position
	local Direction : Vector3 = self.Direction

	self.Hitbox.Adornee = Position
	self.Hitbox:Detect()
	
	local AntiTunnelPosition = Position + Direction.Unit * (Direction.Magnitude * Delta)
	local Raycast = workspace:Blockcast(CFrame.new(Position) + self.HeightVector, self.BlockcastSize, AntiTunnelPosition - Position, self.Params)

	if Raycast then
		local Destructible = Destruction.Destruct(Raycast.Instance, self.DestructionPower)
	
		if Destructible and Destructible:GetAttribute("Destructed") then
			self.Params:AddToFilter(Destructible)
		else
			self.OnMapHit:Fire(Raycast)
		
			return self:Destroy()
		end
	end
	
	local NewDirection = Direction * Delta
	local NewPosition = Position + NewDirection

	if self.HeightenWithGround then
		local GroundRaycast = workspace:Raycast(Position, DownwardVector, Utility.VisualParams)

		if GroundRaycast then
			self.Position = ((GroundRaycast.Position + self.HeightVector) + NewDirection)
		else
			self.Position = NewPosition
		end
	else
		self.Position = NewPosition
	end
	
	ProjectileRemotes.Update:FireAllClients(self.Instance, self.Position, NewDirection)
	self.Traveled += NewDirection.Magnitude
end

function Projectile:Start()
	if not self.Active then
		self.Active = true
		
		self.StartTime = os.clock()
		self.Projectiles.ActiveProjectiles[self] = true
		self.OnStart:Fire()
	end
end

function Projectile:Stop()
	if self.Active then
		self.Active = false
		self.Projectiles.ActiveProjectiles[self] = nil
		
		self.OnStop:Fire()
	end
end

function Projectile:Destroy()
	self:Stop()
	
	if self.Hitbox then
		self.Hitbox:Destroy()
		self.Hitbox = nil
	end
	
	self.Instance:Destroy()
	self.Job:Destroy()
end

function Projectile:InitHitbox()
	if (self.Hitbox == nil) then
		self.Hitbox = self.Combat.Hitbox:Create(true)
		self.Hitbox.Params.Size = self.DetectionSize
	end
end

function Projectile.new(Projectiles, Name : string, Origin : Vector3, Direction : Vector3, Settings : {})
	local self = setmetatable({}, Projectile)

	self.Projectiles = Projectiles
	self.Combat = Projectiles.Combat
	self.LuaCharacter = Projectiles.LuaCharacter
	self.LuaPlayer = Projectiles.LuaPlayer

	self.Job = Job.new()

	self.OnMapHit = self.Job:Task(EventService.new())
	self.OnStart = self.Job:Task(EventService.new())
	self.OnStop = self.Job:Task(EventService.new())
	self.OnExpire = self.Job:Task(EventService.new())

	self.Instance = Instance.new("Configuration")
	self.Instance.Name = Name
	self.Instance.Parent = workspace.Projectiles
	
	self.MaxDistance = Settings.MaxDistance or 500
	self.DestructionPower = Settings.DestructionPower or 10
	self.DetectionSize = Settings.DetectionSize or 20
	self.MaxTime = Settings.MaxTime or 5
	self.HeightenWithGround = Settings.HeightenWithGround
	
	self.Height = Settings.Height or 5
	self.HeightVector = Vector3.yAxis * self.Height
	
	self.BlockcastSize = Vector3.new(self.DetectionSize, 0.001, self.DetectionSize)

	self.Traveled = 0
	self.Active = false
	
	self.Position = Origin + self.HeightVector
	self.Direction = Direction
	self.OriginalDirection = Direction

	self.Params = RaycastParams.new()
	self.Params.FilterDescendantsInstances = {workspace.Visuals, workspace.chars, workspace["NPC's"]}
	self.Params.FilterType = Enum.RaycastFilterType.Exclude

	self:InitHitbox()
	ProjectileRemotes.Create:FireAllClients(self.Instance, self.Position, self.Direction)

	return self
end

table.freeze(Projectile)

return Projectile