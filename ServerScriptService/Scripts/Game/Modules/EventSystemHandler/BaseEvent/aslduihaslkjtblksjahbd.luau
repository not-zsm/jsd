local BaseEvent = require( script.Parent );

local NewWorld = setmetatable({}, BaseEvent);
NewWorld.__index = NewWorld

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)
local Maid = require( ReplicatedStorage.Packages.Maid )

function NewWorld.new(...)
	local self = setmetatable(BaseEvent.new(...), NewWorld)
	
	-- Settings
	self.Settings = {
		EventDuration = 400, -- Seconds
	}
	
	self.Template = ServerStorage.EventAssets.Note
	self.SpawnsFolder = if  RunService:IsStudio() then workspace.TesterPlate.WorldEvents["Death Note"] else ServerStorage.ItemSpawns

	return self
end

function NewWorld:Start()
	if self.Active then return end;
	
	BaseEvent.Start(self);
	
	-- Announce Dead Drop
	--self.System.EventUtility:Announce("World Event - Conquest", "A portal has appeared somewhere on the map, investigate it further.")
	print("Begin NewWorld")
	self:Spawn()
	
	self.Maid:add(self.NoteSpawn.Root.Prompt.Triggered:Connect(function(Player)
		local LuaPlayer, LuaCharacter = self.System.EventUtility:GetLuaPlayer(Player)
		
		if LuaCharacter.Combat:NotStunned() and LuaCharacter.HumanoidAlive then
			self:StartKira(Player)
		end
	end))
	
	self.Maid:add(self.TimerThread)
end

function NewWorld:StartKira(Player : Player)
	local LuaPlayer, LuaCharacter = self.System.EventUtility:GetLuaPlayer(Player)
	self.Kira = LuaPlayer
	
	----- START OBTAINMENT -----
	self.NoteBook = LuaCharacter.Items:Give("Death Note")
	
	local ObtainmentMaid = self.Maid:limb()
	
	local Animation : AnimationTrack = LuaCharacter:LoadAnimation(ReplicatedStorage.Animations.WorldEvents.NewWorld.Obtainment.User)
	Animation.Priority = Enum.AnimationPriority.Action4
	Animation:Play(0)
	self.Maid:add(Animation.Stopped:Once(function()
		ObtainmentMaid:destroy()
	end))
	
	local NoRotate = LuaCharacter:StopAutoRotate()
	
	--self.NoteSpawn.Root.CFrame = LuaCharacter.RootPart.CFRame * CFrame.new(0.32, -3.995, -2.016) * CFrame.Angles(math.rad(-2.663), math.rad(-175.079), math.rad(-1.439))
	self.NoteSpawn:Destroy()
	
	LuaCharacter:Anchor(true, true)
	LuaCharacter.Combat:StackState("HitboxImmunity", true)
	LuaCharacter.Combat:StackState("Attacking", true)

	LuaPlayer.Replication:FireReliableVFX("WorldEvents/NewWorld", "Start", LuaCharacter.Model)
	
	--ObtainmentMaid:add(Animation:GetMarkerReachedSignal("End"):Once(function()
	--	self.NoteBook:StartIdleAnimation(0)
	--	Animation:Stop(0.1, 1, 0)
	--end))
	
	ObtainmentMaid:add(function()
		LuaCharacter:Anchor(false)

		if NoRotate then
			NoRotate:Destroy()
		end

		LuaCharacter.Combat:StackState("HitboxImmunity", false)
		LuaCharacter.Combat:StackState("Attacking", false)
	end)
	
	self.Maid:add(task.delay(self.Settings.EventDuration, function()
		self:End("OutOfTime")
	end))
end

-- Spawn Animation
function NewWorld:Spawn()
	local SpawnLocations = self.SpawnsFolder:GetChildren()

	local RandomSpawn = SpawnLocations[math.random(1, #SpawnLocations)]
	local SpawnCFrame = RandomSpawn.CFrame * CFrame.new(0, -0.188, 0)

	self.NoteSpawn = self.Maid:add(self.Template:Clone())
	self.NoteSpawn.Root.CFrame = SpawnCFrame
	self.NoteSpawn.Parent = workspace.Visuals

	self.NoteSpawn.Root.Prompt.Enabled = true
end

return NewWorld