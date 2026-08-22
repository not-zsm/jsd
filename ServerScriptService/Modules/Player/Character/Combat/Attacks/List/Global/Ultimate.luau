 local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

----------------------------------------------------------------------------------

local Modules = ReplicatedStorage.Modules
local Remotes = ReplicatedStorage.Remotes

local UIRemotes = Remotes.Combat.UI

local EventService = require( Modules.Shared.Utilities.EventService )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )
local NumberStack = require( ReplicatedStorage.Modules.Shared.Utilities.NumberStack )

----------------------------------------------------------------------------------

local Attack = {}
Attack.__index = Attack

local BaseAttack = require( ServerScriptService.Modules.Player.Character.Combat.Attacks.BaseAttack )

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:AddValue(Value : number)
	local PreviousValue = self.Value
	local NewValue = math.min(100, self.Value + Value)

	self.Value = NewValue
	self.OnUltimateValueChanged:Fire(NewValue - PreviousValue);
	
	if not self.LuaPlayer.IsNPC then
		self.Combat.AttributeValues:SetAttribute("Ultimate", NewValue)
	end
	
	if (PreviousValue ~= NewValue and NewValue == 100 and not self.InUltimate) then
		self.OnUltimateReached:Fire()
	end;
end;

function Attack:ForceSetValue(Value : number)
	self:_SetValue(Value)
end

function Attack:SetValue(Value : number)
	if not (Value == 0 and self:BarPaused()) then 
		self:_SetValue(Value)
	end
end

function Attack:_SetValue(Value : number)
	local PreviousValue = self.Value;
	local NewValue = math.min(100, Value);
	
	self.Value = NewValue
	self.OnUltimateValueChanged:Fire(NewValue - PreviousValue);
	
	if not self.LuaPlayer.IsNPC and self.LuaPlayer:PlayerExists() then
		self.Combat.AttributeValues:SetAttribute("Ultimate", NewValue)
	end

	if (PreviousValue ~= NewValue and NewValue == 100 and not self.InUltimate) then
		self.OnUltimateReached:Fire()
	end;
end

function Attack:ConditionToActivate() : boolean
	local UltData = self.Combat.CurrentCharacter.Info.Ultimate
	
	if (UltData and not self.LuaCharacter.HumanoidAlive and UltData.CanUseWhileDead) then
		return not self.Combat:GetState(`Cannot{self.NameNoSpaces}`)
			and not self.Combat:GetState("Grabbed") 
			and not self.Combat:GetState("WallComboed") 
			and (self.Value == 100)
			and not self.InUltimate
	else
		return (self.LuaCharacter.HumanoidAlive and self:BasicConditions() and not self.Combat:GetState("Blocking") and not self.Combat:GetState("M1ing") and self.Value == 100 and not self.InUltimate)
	end
end

function Attack:HasAnUltimate()
	return (self.Combat:HasACharacter() and self.Combat.CurrentCharacter.Info.Ultimate ~= nil)
end

function Attack:BarDraining()
	return self.DrainStack:IsFalse()
end

function Attack:BarPaused()
	return self.DrainStack:IsTrue()
end

function Attack:SetBarPausing(Value : boolean, Time : number?)
	self.DrainStack:Change(Value, Time)
	
	if self:BarDraining() then
		self:StartBarDraining()
	else
		self:StopBarDraining()
	end
end

function Attack:DrainThreadActive()
	return (self.BarDrainThread ~= nil and coroutine.status(self.BarDrainThread) == "suspended")
end

function Attack:StartBarDraining()
	if self:BarPaused() or self:DrainThreadActive() or not self.InUltimate then return end
	
	self:PlayMusic()
	
	self.BarDrainThread = coroutine.create(function()
		while (self.Value > 0) do
			self.Value = math.max(0, self.Value - (self.UltimateDrainTime / (self.UltimateTime / 100)) * self.TimeMultiplier)
			self.Combat.AttributeValues:SetAttribute("Ultimate", self.Value)

			task.wait(self.UltimateDrainTime * self.DrainMultiplier)
		end

		if (self.Value == 0) then
			self:StopUltimate()
		end
	end)
	
	coroutine.resume(self.BarDrainThread)
end

function Attack:StopBarDraining()
	if self:DrainThreadActive() then
		coroutine.close(self.BarDrainThread)
	end
	
	self:StopMusic()
end

function Attack:StopUltimate(DontRemoveAttacks : boolean)
	if self:HasAnUltimate() and self.InUltimate then
		if self.CurrentMusic then
			self.CurrentMusic:Destroy()
			self.CurrentMusic = nil
		end

		self:StopBarDraining()
		self:ForceSetValue(0)

		self.InUltimate = false
		self.LuaPlayer.Replication.Attributes:SetAttribute("Ultimate", nil)

		if not self:IsOneTimePop() and self:HasAnUltimate() and not DontRemoveAttacks then
			
			if self.Combat.CurrentCharacter.Info.Ultimate.Attacks then
				for Name in self.Combat.CurrentCharacter.Info.Ultimate.Attacks do
					self.Combat:RemoveAttack(Name, true)
				end
			end
		
			for Name, Key in self.Combat.CurrentCharacter.Info.Attacks do
				self.Combat:CreateAttack(Name, Key)
			end
		end

		self.OnUltimateEnded:Fire()
	end
end

function Attack:SetMusicVolume(Volume : number)
	if not self.CurrentMusic then return end
	
	self.CurrentMusic.Volume = Volume
end

function Attack:StopMusic()
	if self.CurrentMusic and self.CurrentMusic.Playing then
		self.PreviousMusicPosition = self.CurrentMusic.TimePosition
		self.CurrentMusic:Stop()
	end
end

function Attack:PlayMusic()
	if self.CurrentMusic and not self.CurrentMusic.Playing then
		self.CurrentMusic.TimePosition = self.PreviousMusicPosition or 0
		self.CurrentMusic:Play()
	end
end

function Attack:IsOneTimePop()
	return (self.OneTimePop or self.Combat.CurrentCharacter.Info.Ultimate.OneTimePop)
end

function Attack:StartUltimate()
	if self.InUltimate or not self:HasAnUltimate() then return end
	
	if self:IsOneTimePop() then
		return self:SetValue(0)
	end
	
	self.InUltimate = true

	local Info = self.Combat.CurrentCharacter.Info;
	self:ActivateCustomFunction(Info.CustomFunction);
	
	for Name, Key in Info.Attacks do
		self.Combat:RemoveAttack(Name)
	end
	
	if Info.Ultimate.Attacks then
		for Name, Key in Info.Ultimate.Attacks do
			self.Combat:CreateAttack(Name, Key)
		end
	end
	
	local UltimateFunction = self:GetFunction();
	
	if UltimateFunction then
		self.CurrentMusic = self:CreateMoveSFX(self.Combat.CurrentCharacter.Name, "Ultimate", "Theme")
		self.LuaPlayer.Replication.Attributes:SetAttribute("Ultimate", true)

		local SkipIntro = self:WillSkipIntro()
		
		if SkipIntro or not Info.Ultimate.ManuallyFireStartRemote then
			self:FireReliableVFX(`{self.Combat.CurrentCharacter.Name}/Ultimate`, "OnUltimateStart", self.LuaCharacter.Model, SkipIntro)
		end

		if Info.Ultimate.OnStart then
			task.spawn(Info.Ultimate.OnStart, self)
		end
	end

	self.OnUltimateBegan:Fire();
	self:StartBarDraining();
end

function Attack:GetFunction()
	local Ultimate = self.Combat.CurrentCharacter.Info.Ultimate;
	
	if not Ultimate then
		return;
	end;
	
	if Ultimate.CustomFunction then
		return Ultimate.CustomFunction;
	else
		return Ultimate.Function;
	end;
end

function Attack:WillSkipIntro()
	return self.SkipIntro or (self.Combat.CurrentCharacter.Info.Ultimate and self.Combat.CurrentCharacter.Info.Ultimate.SkipIntro)
end

function Attack:Activate()
	if self:HasAnUltimate() then
		
		if self:WillSkipIntro() and not self:IsOneTimePop() then
			return self:StartUltimate()
		end
		
		local UltimateFunction = self:GetFunction();
		
		if UltimateFunction then
			local Ultimate_Info = self.Combat.CurrentCharacter.Info.Ultimate;

			if not Ultimate_Info.DontMakeAttacking then
				self.Combat:StackState("HitboxImmunity", true)
				self.Combat:StackState("Attacking", true)
				self.Combat:StackState("Ulting", true)
				self.Combat:DivideSpeed(100)

				if not Ultimate_Info.CanRotate then
					self.Thread.Job:Task(Utility.StopAutoRotate(self.LuaCharacter.Humanoid))
				end

				if not Ultimate_Info.CanSeeUI then
					self.Combat:HideUI(true)
				end
				
				if not Ultimate_Info.DontHeal then
					self.LuaCharacter:HealFull()
				end
				
				self.Thread.OnClosed:Connect(function()
					if not Ultimate_Info.CanSeeUI then
						self.Combat:HideUI(false)
					end

					self:StartUltimate()
					
					if self:IsOneTimePop() then
						self.LuaPlayer.Replication.Attributes:SetAttribute("Ultimate", nil) -- Bug fix
					end

					task.delay(1, function()
						self.Combat:StackState("HitboxImmunity", false)
					end)

					self.Combat:TimesSpeed(100)
					
					self.Combat:StackState("Ulting", false)
					self.Combat:StackState("Attacking", false)
				end)
				
				self.Thread.CancelJob:Task(self:CreateMoveSFX(self.Combat.CurrentCharacter.Name, "Ultimate", "Start"))
				self.LuaPlayer.Replication.Attributes:SetAttribute("Ultimate", true)
				
				if self.Animations[self.Combat.CurrentCharacter.Name] then
					local Animation : AnimationTrack = self.Animations[self.Combat.CurrentCharacter.Name].Start
					
					if Animation then
						if not Ultimate_Info.PlayAnimationManually then
							Animation:Play()
						end;

						self:ActivateCustomFunction(UltimateFunction, Animation); -- this can yield so last
					else
						self:ActivateCustomFunction(UltimateFunction); -- this can yield so last
					end;
				end;
			else
				self:ActivateCustomFunction(UltimateFunction);
				self:StartUltimate()
				self:Close()
			end
		else
			self:NoUltimateActivation()
		end
	else
		self:NoUltimateActivation()
	end
end

function Attack:CloseForRespawn(...)
	self:StopUltimate();
	BaseAttack.CloseForRespawn(self, ...);
end

function Attack:NoUltimateActivation()
	self.LuaCharacter:HealFull()
	self:SetValue(0)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.Value = 0;
	
	self.UltimateDrainTime = 0.1
	self.UltimateTime = 45
	
	self.DrainMultiplier = 1
	self.TimeMultiplier = 1
	
	self.DrainStack = NumberStack.new()
	self.BarDrainThread = nil
	
	self.OnUltimateBegan = self.Job:Task(EventService.new())
	self.OnUltimateReached = self.Job:Task(EventService.new())
	self.OnUltimateEnded = self.Job:Task(EventService.new())
	self.OnUltimateValueChanged = self.Job:Task(EventService.new());
	
	self.InUltimate = false
	self.SkipIntro = false
	
	self.BypassHumanoidAlive = true

	self.Job:Task(self.Combat.OnCharacterSwitched:Connect(function()
		self:StopUltimate(true)
	end))
	
	self.Job:Task(self.OnUltimateReached:Connect(function()
		self:FireReliableVFXToSelf("Global/Ultimate", "Reached", self.LuaCharacter.Model)
	end))

	self:SetValue(RunService:IsStudio() and 100 or 0)
	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack