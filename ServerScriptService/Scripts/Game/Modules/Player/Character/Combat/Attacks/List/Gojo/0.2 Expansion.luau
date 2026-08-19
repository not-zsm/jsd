local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes
local UIRemotes = Remotes.Combat.UI

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
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(100)
	
	self.Thread.CancelJob:Task(
		self:CreateMoveSFX("Gojo", "Expansion")
	)
	
	local StopAutoRotate = Utility.StopAutoRotate(self.LuaCharacter.Humanoid)
	local DomainCollision = script.DomainCollider:Clone()
	
	local DomainHitbox = self:CreateHitbox(true);
	DomainHitbox.Params.Size = 48
	DomainHitbox.Params.DestroyOnEndCast = false

	DomainHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			TriggerActiveCounterOverOrEqualLevel = -1,
			DontBypassIFrames = {},
			BreakBlock = true
		})

		if Validated then
			VictimCombat:TrueStun(8)
			VictimCombat:StackState("CannotDash", true)

			task.delay(8, function()
				VictimCombat:StackState("CannotDash", false)
			end)
			
			self:FireReliableVFX("Gojo/Expansion", "Stunned", VictimLuaCharacter.Head)
		end
	end)

	self:FireReliableVFX("Gojo/Expansion", "Start", self.LuaCharacter.Model, true)

	self.Thread.OnClosed:Connect(function()
		self:AddCooldown(15)
		
		StopAutoRotate:Destroy()
		DomainCollision:Destroy()
		
		self:FireReliableVFX("Gojo/Expansion", "Start", self.LuaCharacter.Model, false)
		
		self.Combat:TimesSpeed(100)
		self.Combat:StackState("Attacking", false)
	end)
	
	for _, Event in {"wind", "focus", "camera", "eyes", "domain", "cracks", "break"} do
		self.Animations.Windup:GetMarkerReachedSignal(Event):Wait()
		
		if Event == "focus" then
			self.Combat:StackState("HitboxImmunity", true)
			self.Combat:HideUI(true);

			self.Thread.OnClosed:Connect(function()
				self.Combat:HideUI(false);
				self.Combat:StackState("HitboxImmunity", false)
			end)
			
		elseif Event == "domain" then
			DomainCollision.Position = self.LuaCharacter.RootPart.Position
			DomainCollision.Parent = workspace.Visuals
		
		elseif Event == "cracks" then
			DomainHitbox:BeginCast(0.05)
			
		elseif Event == "break" then
			DomainCollision:Destroy()
		end

		if Event == "camera" then
			self:FireReliableVFXToSelf("Gojo/Expansion", "Camera", self.LuaCharacter.RootPart)
			
			local CameraHitbox = self:CreateHitbox(true, true);
			CameraHitbox.Params.Size = 15

			CameraHitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
				local VictimLuaCharacter = VictimLuaPlayer.Character
				local VictimCombat = VictimLuaCharacter.Combat

				local Validated = self:Afflict(VictimLuaPlayer, {
					TriggerActiveCounterOverOrEqualLevel = -1,
					DontBypassIFrames = {"Grab"},
					BreakBlock = true
				})

				if Validated then
					VictimCombat:TrueStun(2)
					VictimCombat:StackState("CannotDash", true)
					
					task.delay(2, function()
						VictimCombat:StackState("CannotDash", false)
					end)
					
					if not VictimLuaPlayer.IsNPC then
						VictimLuaPlayer.Replication:FireReliableVFXToSelf("Gojo/Expansion", "Camera", self.LuaCharacter.RootPart)
					end
				end
			end)
			
			CameraHitbox:BeginCast(0.05)
		else
			self:FireReliableVFX("Gojo/Expansion", string.upper(string.sub(Event, 1, 1)) .. string.sub(Event, 2, -1), self.LuaCharacter.RootPart)
			
			if Event == "domain" then
				self.Thread.OnClosed:Connect(function()
					self:FireReliableVFX("Gojo/Expansion", "ClearDomain", self.LuaCharacter.RootPart)
				end)
			end
		end
	end

	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack