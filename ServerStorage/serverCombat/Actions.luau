

local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local RunService = game:GetService("RunService")



local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local Actions = {}
Actions.__index = Actions

function Actions:Destroy()
	self.Job:Destroy()
end

--[[
	One move input from the client: press, release, or a one-shot.

	This was a remote handler wired per player, opening with an identity check
	and hand-written type checks. byteNet types the payload and the networker
	resolves the sender, so both are gone; State stays nilable because a
	one-shot move sends no state at all.
--]]
function Actions:UseMove(Name : string, State : boolean?, Extra : {}?)
	if shared.IsRankedLobby then return end

	local Attack = self.Combat.Attacks[Name]

	if (Attack ~= nil and Attack.Available and Attack.Activate ~= nil) then

		if (State ~= nil) then
			Attack.HeldState = State
		end

		Attack:UpdateAirVariantChecking(Extra)

		if (Attack.BeginRequestingMouseOnBuffer and State ~= nil) then
			if State then
				self.Combat.Mouse:BeginRequesting()
			else
				self.Combat.Mouse:EndRequesting()
			end
		end

		if (Attack.BypassHumanoidAlive or self.LuaCharacter.HumanoidAlive) then
			if (State == nil) then
				if not self:IsEnabled() then return end

				if Attack.Pretrigger then
					Attack:Pretrigger(Extra, State)
				end

				if Attack:ConditionToActivate(true) and not self.Combat:GetState("CannotUse" .. Attack.DirectoryParent) then
					Attack:Trigger()

					if not self.LuaPlayer.IsNPC then
						network.hotbarUse.sendTo(Attack.Name, self.LuaPlayer.Player)
					end
				end
			else
				if State and self:IsEnabled() then
					if Attack.Pretrigger then
						Attack:Pretrigger(Extra, State)
					end

					if Attack:ConditionToActivate(State) and not self.Combat:GetState("CannotUse" .. Attack.DirectoryParent) then
						Attack:Trigger()

						if not self.LuaPlayer.IsNPC then
							network.hotbarUse.sendTo(Attack.Name, self.LuaPlayer.Player)
						end
					end

				elseif not State then
					if (Attack.Deactivate ~= nil and Attack:ThreadAvailable()) then
						if Attack.Pretrigger then
							Attack:Pretrigger(Extra, State)
						end

						Attack:Deactivate()
					end
				end
			end

		end
	end
end

function Actions:_Init()

	self.Job:Task(RunService.PostSimulation:Connect(function()
		if (self.BufferReady == false) then return end
		self.BufferReady = false

		if not self.LuaCharacter.HumanoidAlive or not self:IsEnabled() then
			return
		end

		for _, Attack in self.Combat.Attacks do
			if Attack.DontBuffer or not Attack.Available or (Attack.Thread ~= nil and Attack.Thread.Errored) then
				continue
			end

			if not (Attack.HeldState and Attack:ConditionToActivate() and not self.Combat:GetState("CannotUse" .. Attack.DirectoryParent)) then 
				continue 
			end

			Attack:UpdateAirVariantChecking(self.ClientSentExtra)
			Attack:Trigger()

			if not self.LuaPlayer.IsNPC then
				network.hotbarUse.sendTo(Attack.Directory.Name, self.LuaPlayer.Player)
			end
		end
	end))

	self.Combat.OnStateChanged:Connect(function(State : any, Value : any)
		self:UpdateStates(State, Value)
		self.BufferReady = true
	end)

	self.Combat.OnAttackChanged:Connect(function(Attack, Value : boolean)
		if Value then
			local CooldownConnection = Attack.OnCooldownChanged:Connect(function(Value : boolean)
				if not Value then
					self.BufferReady = true
				end
			end)

			local RemovedConnection; RemovedConnection = self.Combat.OnAttackChanged:Connect(function(AttackName : string, NewValue : boolean)
				if Attack.Directory.Name == AttackName and not Value then
					RemovedConnection:Disconnect()
					CooldownConnection:Disconnect()
				end
			end)
		end
	end)

	self:SetEnabled(true)
end

function Actions:IsEnabled()
	if self.LuaPlayer.IsNPC then
		return self.Enabled
	end

	return self.Combat.AttributeValues:GetAttribute("CombatEnabled")
end

function Actions:SetEnabled(Value : boolean)
	if self.LuaPlayer.IsNPC then
		self.Enabled = Value
	else
		if self.LuaPlayer:PlayerExists() then
			self.Combat.AttributeValues:SetAttribute("CombatEnabled", Value)
		end
	end
end

function Actions:UpdateStates(State : any, Value : boolean)
	local States = (
		State == "Attacking" or 
			State == "Stunned" or 
			State == "Ragdolled" or
			State == "Blocking" or
			State == "M1ing"
	)

	if (States or State == "Dashing" or State == "Backdashing") then
		self.Combat.Values.Jump:Change(Value)
	end

	local JumpValue = self.Combat.Values.Jump:IsTrue()

	if (States or State == "Emoting" or State == "CannotRun" or State == "Backdashing") then
		self.Combat.Values.Run:Change(Value)
		self.CanRun = self.Combat.Values.Run:IsFalse()

		if not self.LuaPlayer.IsNPC then
			self.Combat.AttributeStates:SetAttribute("Run", self.Combat.Values.Run:IsFalse())
		end
	end

	if not self.LuaPlayer.IsNPC then
		network.updateJump.sendTo(JumpValue, self.LuaPlayer.Player)
	else
		if self.LuaCharacter.HumanoidAlive then
			self.LuaCharacter.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, JumpValue)
		end
	end
end

function Actions.new(Combat)
	local self = setmetatable({}, Actions)

	self.Combat = Combat
	self.LuaCharacter = Combat.LuaCharacter
	self.LuaPlayer = Combat.LuaPlayer

	self.Job = Job.new()

	self.BufferReady = false
	self.CanRun = true

	self:_Init()

	return self
end

return Actions
