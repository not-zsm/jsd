local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local UIRemotes = Remotes.Combat.UI
local HotbarRemotes = UIRemotes.Hotbar

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:StackState("Attacking", true)

	if not self.LuaPlayer.IsNPC then
		self.LuaPlayer.Remotes.ToggleHeadMovement:FireClient(self.LuaPlayer.Player)
		UIRemotes.Hide:FireClient(self.LuaPlayer.Player, true)
	end
	
	self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
	self.LuaCharacter:Anchor(true)
	self.Combat:DivideSpeed(100)

	local Damage = 115
	local HitboxRange = 235
	
	local Hitbox = self:CreateHitbox(true);
	Hitbox.Params.Size = HitboxRange
	Hitbox.Params.DestroyOnEndCast = false
	Hitbox.Params.MaxTargets = 30
	Hitbox.Params.TrySorting = false
	
	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Difference : Vector3 = (VictimLuaCharacter.RootPart.Position - self.LuaCharacter.RootPart.Position)
		local DistanceDamage = math.clamp(Damage * (1 - (Difference.Magnitude / 250)), 0, 100)

		self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			
			DontBypassIFrames = {},
			BreakBlock = true,
			
			Damage = {
				Amount = DistanceDamage,
				DontCountToUltimate = true
			},
			
			Ragdoll = 2,
			Velocity = {Difference.Unit * 75 + Vector3.yAxis * 50, 0.1}
		})
	end)

	self.Thread.OnClosed:Connect(function()
		if not self.LuaPlayer.IsNPC then
			self.Available = false
		end
		
		self:AddCooldown(100)
		
		self.LuaCharacter:Anchor(false)

		if not self.LuaPlayer.IsNPC then
			self.LuaPlayer.Remotes.ToggleHeadMovement:FireClient(self.LuaPlayer.Player)
			UIRemotes.Hide:FireClient(self.LuaPlayer.Player, false)
		end
		
		self.LuaPlayer.Replication.Attributes:SetAttribute("GojoMaxPurple", nil)

		self.Combat:TimesSpeed(100)
		
		self.Combat:StackState("Attacking", false)
		self.Combat:StackState("HitboxImmunity", false)
	end)

	self.LuaPlayer.Replication.Attributes:SetAttribute("GojoMaxPurple", true)
	self:FireReliableVFX("Gojo/Max Purple", "Start", self.LuaCharacter.Model, HitboxRange)
	
	local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

	if Matched then
		Ultimate:StopUltimate()
	end
	
	task.wait(2)

	local CrushHitbox = self:CreateHitbox(true);
	CrushHitbox.Params.Offset = CFrame.identity
	CrushHitbox.Params.Size = 70
	CrushHitbox.Params.DestroyOnEndCast = false
	
	CrushHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			
			BreakBlock = true,
		})

		if Validated then
			VictimCombat:TrueStun(15)

			self.Combat:TSBPushVictim(VictimLuaPlayer, {
				LandedRollVelocityZ = 150,
				LandedRollDuration = 0.835,
			})
		end
	end)
	
	CrushHitbox:Detect()

	task.wait(16)
	
	self.Combat.Hitbox:CreateHavocReplicated({
		parameters = {
			origin = CFrame.new(self.LuaCharacter.RootPart.Position),
			shape = "Sphere", 
			radius = HitboxRange,
			block_size = HitboxRange / 5, 
		},
	})

	self.Combat.Hitbox:SphereDestruction(self.LuaCharacter.RootPart.Position, HitboxRange, 10, nil, "None")
	Hitbox:Detect()
	
	task.wait(2)
	
	self:Close()
end

function Attack:CompleteStep1()
	if not self.CompletedStep1 then
		self.CompletedStep1 = true
		HotbarRemotes.ImportantChangeDisplay:FireClient(self.LuaPlayer.Player, "Maximum Output - Purple", "Maximum Output - Purple", "ONE STEP TAKEN", Color3.fromRGB(255, 255, 255))
	end
end

function Attack:CompleteStep2()
	if self.CompletedStep1 then
		self:SetAvailability(true)

		local Remove = task.delay(5, function()
			self.CompletedStep1 = false
			self:SetAvailability(false)
		end)

		self.OnTriggered:Once(function()
			if coroutine.status(Remove) == "suspended" then
				task.cancel(Remove)
			end
		end)
	end
end

function Attack:SetAvailability(Value : boolean)
	self.Available = Value

	if Value then
		HotbarRemotes.ImportantChangeDisplay:FireClient(self.LuaPlayer.Player, self.Name, self.DisplayName, "READY", Color3.fromRGB(140, 0, 255))
	else
		HotbarRemotes.ImportantChangeDisplay:FireClient(self.LuaPlayer.Player, self.Name, self.DisplayName, "NOT READY", Color3.fromRGB(255, 255, 255))
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true

	task.defer(self.SetAvailability, self, false)
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack