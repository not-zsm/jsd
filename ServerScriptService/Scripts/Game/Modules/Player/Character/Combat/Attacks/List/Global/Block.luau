local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

----------------------------------------------------------------------------------

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate(State) : boolean
	return self:BasicConditions() and not self.Combat:GetState("Blocking") and not self.Combat:GetState("M1ing")
end

function Attack:Activate()
	local AnimationDirectory = self:GetAnimationDirectory()
	
	local Ultimate = self.Combat:GetFirstAttack("Ultimate");
	local PlayUltimateBlock = (Ultimate and Ultimate.InUltimate and AnimationDirectory.Ult)

	local Reactions = AnimationDirectory.Reactions or self.Animations.Default.Reactions
	local Hold = AnimationDirectory.Hold or self.Animations.Default.Hold
	local Windup = AnimationDirectory.Windup or self.Animations.Default.Windup

	local ShieldAttack = self.Combat.Attacks["Guardian Shield"]
	local IsKratosShieldState = (ShieldAttack and ShieldAttack.InShield)

	if PlayUltimateBlock then
		if AnimationDirectory.Ult.Hold then
			AnimationDirectory.Ult.Hold:Play(0.05)
		end
	else
		if IsKratosShieldState then -- didn't want to do this but im too lazy
			AnimationDirectory.ShieldHold:Play()
		else
			if Windup then
				Windup:Play(0.05, 1, 2)
			end
		end
	end
	
	self.Combat:StackState("Blocking", true)
	self.Combat:DivideSpeed(3)

	local DashAttack, DashAttackMatched = self.Combat:MatchAttack("Dash", Enum.KeyCode.Q)

	if (DashAttackMatched) then
		local DashAnimationDirectory = DashAttack:GetAnimationDirectory()

		if DashAnimationDirectory then
			DashAnimationDirectory.Hit:Stop()
		end
	end

	if not self:HasCertainCooldown("PerfectBlock") and not self:HasCertainCooldown("PerfectBlockCooldown") then
		self.PerfectBlockWindow = true

		self:AddCertainCooldown("PerfectBlock", (IsKratosShieldState and 0.3 or self.PerfectBlockWindowTime), function() 
			self.PerfectBlockWindow = false
		end)
	end

	if not PlayUltimateBlock and not IsKratosShieldState then
		self.Thread.Job:Task(task.delay(Windup.Length - 0.2, function()
			Windup:Stop()
			Hold:Play(0.001)
		end))
	end
	
	self:FireVFX("Global/Block", "Start", self.LuaCharacter.RootPart)

	self.Thread.OnCancelled:Connect(function()
		if PlayUltimateBlock then
			for _, Animation : AnimationTrack in AnimationDirectory.Ult.Reactions do
				if Animation.IsPlaying then
					Animation:Stop(0.001)
				end
			end
			
			if AnimationDirectory.Ult.Hold then
				AnimationDirectory.Ult.Hold:Stop()
			end
		end
		
		if not IsKratosShieldState then
			for _, Animation : AnimationTrack in Reactions do
				if Animation.IsPlaying then
					Animation:Stop(0.001)
				end
			end

			Windup:Stop(0.001)
			Hold:Stop()
		else
			for _, Animation : AnimationTrack in AnimationDirectory.ShieldBlocks do
				if Animation.IsPlaying then
					Animation:Stop(0.001)
				end
			end
			
			AnimationDirectory.ShieldHold:Stop()
		end
	end)
	
	self.Thread.OnClosed:Connect(function()
		self:AddCertainCooldown("PerfectBlockCooldown", 0.15, nil, true)
		
		self.Combat:TimesSpeed(3)
		self.Combat:StackState("Blocking", false)
	end)
end

function Attack:Deactivate()
	local AnimationDirectory = self:GetAnimationDirectory()
	local ShieldAttack = self.Combat.Attacks["Guardian Shield"]

	if AnimationDirectory.ShieldHold and AnimationDirectory.ShieldHold.IsPlaying then
		AnimationDirectory.ShieldHold:Stop()
	end
	
	if AnimationDirectory.Ult and AnimationDirectory.Ult.Hold and AnimationDirectory.Ult.Hold.IsPlaying then
		AnimationDirectory.Ult.Hold:Stop()
	end
	
	if not (ShieldAttack and ShieldAttack.InShield) then
		local Reactions = AnimationDirectory.Reactions or self.Animations.Default.Reactions
		local Hold = AnimationDirectory.Hold or self.Animations.Default.Hold
		local Windup = AnimationDirectory.Windup or self.Animations.Default.Windup

		for _, Animation : AnimationTrack in Reactions do
			if Animation.IsPlaying then
				Animation:Stop(0)
			end
		end

		Windup:Stop(0)
		Hold:Stop()
	end
	
	self:Close()
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)

	self.ActivateOnInputEnded = true
	self.BlockAngle = math.rad(90)
	
	self.PerfectBlockWindow = false
	self.PerfectBlockTime = -1
	self.PerfectBlockWindowTime = 0.1 --0.085

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack