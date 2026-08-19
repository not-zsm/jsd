local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return self:BasicConditions() and not self.Combat:GetState("Blocking")
end

function Attack:Activate()
	self.Hit = false
	
	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)
	
	self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())
	self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "ERADICATE"))

	self:FireReliableVFX("Reigen/ERADICATE", "Start", self.LuaCharacter.RootPart)
	
	local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

	local Hitbox = self:CreateHitbox(false);
	Hitbox.Params.Offset = CFrame.new(0, 7.5, -14.675)
	Hitbox.Params.Size = Vector3.new(35, 25, 25)
	Hitbox.Params.MaxTargets = 1
	Hitbox.Params.DestroyOnEndCast = false
	
	self:FireReliableVFX("Reigen/ERADICATE CUTSCENE", "LoadImpactFrames", self.LuaCharacter.RootPart)

	Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
		local VictimLuaCharacter = VictimLuaPlayer.Character
		local VictimCombat = VictimLuaCharacter.Combat

		local Validated = self:Afflict(VictimLuaPlayer, {
			BreakBlock = true,
			DontHitDeadPeople = true,
			TriggerActiveCounterOverOrEqualLevel = -1,
		})

		if Validated then
			self.Hit = true

			VictimCombat:StackState("HitboxImmunity", true)

			VictimCombat:TrueStun()
			VictimCombat.Ragdoll:ForceToggleOff()

			self.Combat:HideUI(true)
			VictimCombat:HideUI(true)
			
			self.LuaCharacter:Anchor(true, true)
			VictimLuaCharacter:Anchor(true, true)
			
			if Matched then
				Ultimate:StopMusic()
			end
			
			local CutscenePlaying = false
			
			self:FireReliableVFX("Reigen/ERADICATE CUTSCENE", "Crush", self.LuaCharacter.Model, VictimLuaCharacter.Model, true)
		
			self.Thread.OnClosed:Connect(function()
				if not CutscenePlaying then
					self:FireReliableVFX("Reigen/ERADICATE CUTSCENE", "Crush", self.LuaCharacter.Model, VictimLuaCharacter.Model, false)
				end
			end)
			
			local function Cutscene(Value : boolean)
				CutscenePlaying = Value
				
				if Value then
					self:FireReliableVFXToSelf("Reigen/ERADICATE CUTSCENE", "Start", self.LuaPlayer.Player, VictimLuaPlayer.Player)

					if not VictimLuaPlayer.IsNPC then
						VictimLuaPlayer.Replication:FireReliableVFXToSelf("Reigen/ERADICATE CUTSCENE", "Start", self.LuaPlayer.Player, VictimLuaPlayer.Player)
					end

					self.Thread.OnClosed:Connect(function()
						self:FireReliableVFXToSelf("Reigen/ERADICATE CUTSCENE", "Remove", self.LuaPlayer.Player)

						if not VictimLuaPlayer.IsNPC then
							VictimLuaPlayer.Replication:FireReliableVFXToSelf("Reigen/ERADICATE CUTSCENE", "Remove", self.LuaPlayer.Player)
						end
					end)
				end

				self:FireReliableVFX("Reigen/ERADICATE CUTSCENE", "StartOthers", self.LuaCharacter.Model, VictimLuaCharacter.Model, Value)
			end

			self.Thread.Job:Task(self.Animations.Hit:GetMarkerReachedSignal("jump"):Connect(function()
				VictimCombat.Ragdoll:ForceToggleOff()
				Cutscene(true)

				self.Thread.OnClosed:Connect(function()
					Cutscene(false)
				end)

				local AttackerCF : CFrame = self.LuaCharacter.RootPart.CFrame
				local VictimCF : CFrame = VictimLuaCharacter.RootPart.CFrame

				self.LuaCharacter.Model:PivotTo(AttackerCF + Vector3.yAxis * 100)
				VictimLuaCharacter.Model:PivotTo(VictimCF + Vector3.yAxis * 100)

				self.Thread.Job:Task(task.delay(20.83333396911621, function()
					self.LuaCharacter.Model:PivotTo(AttackerCF)
					
					local Raycast = workspace:Raycast(AttackerCF.Position, AttackerCF.LookVector * 75, Utility.VisualParams)
					local Offset
					
					if Raycast then
						Offset = CFrame.new(0, 5, -(Raycast.Distance - 2)) * CFrame.Angles(0, math.pi, 0)
						VictimLuaCharacter.Model:PivotTo(VictimCF * Offset)
					else
						Offset = CFrame.new(0, 5, -75) * CFrame.Angles(0, math.pi, 0)
						VictimLuaCharacter.Model:PivotTo(VictimCF * Offset)
					end
					
					self:FireReliableVFX("Reigen/ERADICATE CUTSCENE", "Boom", self.LuaPlayer.Player)
					
					local AOEHitbox = self.Combat.Hitbox:AoeHitboxForGrabs(VictimLuaPlayer, Offset, Vector3.one * 80)

					if AOEHitbox then
						AOEHitbox.Params.DestroyOnEndCast = false

						AOEHitbox.Events.OnLuaPlayerHit:Connect(function(NewVictimLuaPlayer)
							self.Combat:Afflict(NewVictimLuaPlayer, {
								TriggerActiveCounterOverOrEqualLevel = -1,
								DontBypassIFrames = {},
								BreakBlock = true,
								Damage = 25,
								Ragdoll = 2,
								Velocity = { (NewVictimLuaPlayer.Character.RootPart.Position - VictimLuaPlayer.Character.RootPart.Position).Unit * 75 + Vector3.yAxis * 115, 0.1}
							})
						end)

						AOEHitbox:Detect()

						task.delay(2 / 60, function()
							AOEHitbox:Destroy()
						end)
					end

					self:Afflict(VictimLuaPlayer, {
						ExcludeAttempts = true,
						Ragdoll = 3,
						FinisherKill = true,
						Velocity = {self.LuaCharacter.RootPart.CFrame.LookVector * 75 + Vector3.yAxis * 115, 0.1}
					})

					task.wait(0.5)

					self:Close()
				end))
			end))

			self.Thread.OnClosed:Connect(function()
				self.Combat:HideUI(false)
				VictimCombat:HideUI(false)
			
				VictimCombat:Unstun()

				self.LuaCharacter:Anchor(false)
				VictimLuaCharacter:Anchor(false)
				
				VictimCombat:StackState("HitboxImmunity", false)
			end)
			
			self.Animations.Windup:Stop(0)
			self.Animations.Hit:Play(0)
		end
	end)

	
	if Matched then
		Ultimate:SetBarPausing(true)
		Ultimate:SetValue(100)
	end
	
	self.Thread.OnClosed:Connect(function()
		if Matched then
			Ultimate:SetBarPausing(false)
			Ultimate:StopUltimate()
		end
		
		self.Combat:TimesSpeed(50)
		
		self.Combat:StackState("HitboxImmunity", false)
		self.Combat:StackState("Attacking", false)
	end)
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("rocksout"):Connect(function()
		self:FireReliableVFX("Reigen/ERADICATE", "RocksOut", self.LuaCharacter.RootPart)
	end))
	
	self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("clap"):Connect(function()
		self:FireReliableVFX("Reigen/ERADICATE", "Clap", self.LuaCharacter.RootPart)
		Hitbox:Detect()
	end))
	
	self.Animations.Windup.Stopped:Wait()

	if not self.Hit then
		self:Close()
	end
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