local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage.Remotes
local GrabRemotes = Remotes.Grab

----------------------------------------------------------------------------------

local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )
local Job = require( ReplicatedStorage.Modules.Shared.Utilities.Job )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

local MobMoves = {
	["ERADICATE"] = Enum.KeyCode.One,
}

----------------------------------------------------------------------------------

function Attack:ConditionToActivate()
	return (self:BasicConditions() and not self.Combat:GetState("Blocking") and self.FakeCharacter and self.FakeCharacter.Parent ~= nil)
end

function Attack:Activate()
	--self.Available = false

	self.Combat:StackState("HitboxImmunity", true)
	self.Combat:StackState("Attacking", true)
	self.Combat:DivideSpeed(50)

	self.Combat:HideUI(true)
	
	local Ultimate, Matched = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G)

	if Matched then
		Ultimate:SetBarPausing(true)
		Ultimate:SetValue(100)

		Ultimate.OnUltimateEnded:Once(function()
			Ultimate:SetBarPausing(false)
		end)
	end

	local AlreadyPlayingAsMyself = false

	self.Thread.Job:Task(self.LuaCharacter:StopAutoRotate())

	self.Thread.Job:Task(task.delay(0.1, function()
		self.Thread.CancelJob:Task(self:CreateMoveSFX("Reigen", "Part Time Employee"))
	end))

	self:FireReliableVFX("Reigen/Part Time Employee", "Hide", self.LuaCharacter.Model)

	local FakeReigenAnimation = self.FakeCharacterAnimator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Reigen["Part Time Employee"].Reigen)

	self.Thread.Job:Task(FakeReigenAnimation:GetMarkerReachedSignal("summonmob"):Connect(function()
		self:FireReliableVFX("Reigen/Part Time Employee", "Summon", self.LuaCharacter.Model)
		self:FireReliableVFXToSelf("Reigen/Part Time Employee", "PlayAs", self.LuaCharacter.Model)

		if not self.LuaPlayer.IsNPC then
			self.LuaPlayer.Remotes.SetHeadMovementAttach:FireClient(self.LuaPlayer.Player, nil)
		end

		self.Animations.Mob:Play(0)
		AlreadyPlayingAsMyself = true
	end))

	self.Thread.Job:Task(FakeReigenAnimation:GetMarkerReachedSignal("phone"):Connect(function(Value : string)
		self:FireReliableVFX("Reigen/Part Time Employee", "Phone", self.FakeCharacter, Value)

		if Value == "true" then
			self.Thread.OnClosed:Connect(function()
				self:FireReliableVFX("Reigen/Part Time Employee", "Phone", self.FakeCharacter, "false")
			end)
		end
	end))

	self.Thread.Job:Task(self.Animations.Mob:GetMarkerReachedSignal("land"):Connect(function()
		self:FireReliableVFX("Reigen/Part Time Employee", "Land", self.LuaCharacter.RootPart)

		for Name, Key in self.Combat.CurrentCharacter.Info.Ultimate.Attacks do
			self.Combat:RemoveAttack(Name, (Name == script.Name)) -- so it doesnt cancel this moves thread
		end

		for Name, Key in MobMoves do
			self.Combat:CreateAttack(Name, Key)
		end
		
		local DealtAsMob = 0

		local DamageConnection = self.Combat.OnDamageDealt:Connect(function(Value : number)
			DealtAsMob += Value
			
			if DealtAsMob > 25 then
				self.Combat:CreateAttack("CRASHOUT", Enum.KeyCode.Two)
			end
		end)
	
		self.Combat.AttributeValues:SetAttribute("UltimateBar", false)

		Ultimate.OnUltimateEnded:Once(function()
			if DamageConnection then
				DamageConnection:Disconnect()
			end
			
			self.Combat:RemoveAttack("CRASHOUT", true)
		
			for Name in MobMoves do
				self.Combat:RemoveAttack(Name, true)
			end

			task.spawn(function()
				self.LuaCharacter:ApplyDescriptionToSelf()
			end)
			
			if self.LuaCharacter.ReigenTie then
				self.LuaCharacter.ReigenTie.Transparency = 0
			end
			
			self.Combat.AttributeValues:SetAttribute("UltimateBar", true)
		end)

		self.Thread.Job:Task(task.delay(1, function()
			self:FireReliableVFX("Reigen/Part Time Employee", "ReigenFades", self.FakeCharacter)
		end))
	end))

	self.FakeCharacter:PivotTo(self.LuaCharacter.RootPart.CFrame)
	FakeReigenAnimation:Play(0)

	GrabRemotes.Set:FireAllClients(self.FakeCharacterRootPart, self.LuaCharacter.RootPart, nil, "ReigenSummonMob")

	if not self.LuaPlayer.IsNPC then
		self.LuaPlayer.Remotes.SetHeadMovementAttach:FireClient(self.LuaPlayer.Player, self.FakeCharacter.Head)
	end

	self:FireReliableVFXToSelf("Reigen/Part Time Employee", "PlayAs", self.FakeCharacter)
	
	task.spawn(function()
		local Humanoid : Humanoid = self.LuaCharacter.Humanoid
		
		if self.LuaCharacter.ReigenTie then
			self.LuaCharacter.ReigenTie.Transparency = 1
		end
		
		self.Thread.Job:Task(Humanoid.ApplyDescriptionFinished:Connect(function()
			if self.Thread.Closed then return end
			
			task.wait()
			
			self:FireReliableVFX("Reigen/Part Time Employee", "OnRealModelDescriptionLoaded", self.LuaCharacter.Model)
		end))
		
		--local PreviousDescription = Humanoid:GetAppliedDescription()
		Humanoid:ApplyDescriptionReset(ReplicatedStorage.Effects.Characters.Reigen.Mob.Humanoid.HumanoidDescription)
		
		Ultimate.OnUltimateEnded:Once(function()
			task.spawn(function()
				self.LuaCharacter:ApplyDescriptionToSelf()
			end)

			if self.LuaCharacter.ReigenTie then
				self.LuaCharacter.ReigenTie.Transparency = 0
			end
		end)
		
		--self.Thread.OnClosed:Connect(function()
		--	if self.LuaCharacter.ReigenTie then
		--		self.LuaCharacter.ReigenTie.Transparency = 0
		--	end
			
		--	Humanoid:ApplyDescriptionReset(PreviousDescription)
		--end)
	end)
	
	self.Thread.OnClosed:Connect(function()
		if not self.LuaPlayer.IsNPC and not AlreadyPlayingAsMyself then
			self.LuaPlayer.Remotes.SetHeadMovementAttach:FireClient(self.LuaPlayer.Player, nil)
		end
		
		self.Combat:HideUI(false)

		self:FireReliableVFX("Reigen/Part Time Employee", "ThreadClosed", self.LuaCharacter.Model)
		self:FireReliableVFXToSelf("Reigen/Part Time Employee", "PlayAs", self.LuaCharacter.Model)

		GrabRemotes.Detach:FireAllClients(self.FakeCharacterRootPart)

		FakeReigenAnimation:Stop(0)
		self.FakeCharacter:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 10e8, 0))

		self.Combat:TimesSpeed(50)

		self.Combat:StackState("HitboxImmunity", false)
		self.Combat:StackState("Attacking", false)
	end)

	self.Animations.Mob.Stopped:Wait()

	if not self.Hit then
		self:Close()
	end
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	self.TryToCancelMoves = true

	task.spawn(function()
		self.LuaCharacter.Model.Archivable = true
		local FakeCharacter : Model = self.LuaCharacter.Model:Clone()
		self.LuaCharacter.Model.Archivable = false

		local FakeCharacterHumanoid : Humanoid = FakeCharacter:WaitForChild("Humanoid")
		local FakeCharacterRootPart : BasePart = FakeCharacterHumanoid.RootPart
		local FakeCharacterAnimator : Animator = FakeCharacterHumanoid:WaitForChild("Animator")

		FakeCharacterHumanoid.AutomaticScalingEnabled = false
		FakeCharacterHumanoid.EvaluateStateMachine = false
		FakeCharacterHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		FakeCharacterHumanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

		FakeCharacterRootPart.Anchored = true

		FakeCharacter.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		FakeCharacter.Name = `Fake{self.LuaCharacter.Model}`

		for _, Item in FakeCharacter:GetDescendants() do
			if Item:IsA("BasePart") then
				Item.CanCollide = false
				Item.CollisionGroup = "NoCollision"
			end

			if (Item:IsA("BasePart") and Item.Name ~= "HumanoidRootPart") or Item:IsA("Decal") then
				Item.Transparency = 0

			elseif Item:IsA("TextLabel") then
				Item.TextTransparency = 0

			elseif Item:IsA("Folder") and Item.Name == "RagdollComponents" then
				Item:Destroy()
			end
		end

		FakeCharacter:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 10e8, 0))
		FakeCharacter.Parent = workspace.Visuals

		self.FakeCharacter = FakeCharacter
		self.FakeCharacterHumanoid = FakeCharacterHumanoid
		self.FakeCharacterRootPart = FakeCharacterRootPart
		self.FakeCharacterAnimator = FakeCharacterAnimator

		self.Job:Task(FakeCharacter)
	end)

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack