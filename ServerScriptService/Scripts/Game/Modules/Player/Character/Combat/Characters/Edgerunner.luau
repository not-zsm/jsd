local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberStack = require( ReplicatedStorage.Modules.Shared.Utilities.NumberStack )

return {
	GitHubWhitelist = "Edgerunner",
	RestrictSetCharacter = true,

	FrontDash = {
		TryCustomStart = true,
		MiddleTime = 0.25,
	},
	
	Ultimate = {
		Name = "Cyber Skeleton",
		
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(13, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(234, 255, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 255, 0)),
		}),
	},
	
	Stats = {
		M1 = {
			LastHitbox = {
				Offset = CFrame.new(0, 0, -2.65 * 1.5), 
				Size = Vector3.new(6, 6, 6.8 * 1.5)
			},
			
			Speed = 1,
			EndlagAfterSwing = 0.15
		},
	},
	
	Parry = {
		CustomFunction = function(self, VictimCombat, BlockAttack, BlockAnimationDirectory)
			local VictimLuaPlayer = VictimCombat.LuaPlayer
			local VictimLuaCharacter = VictimCombat.LuaCharacter

			self:StackState("Attacking", true)
			self:StackState("HitboxImmunity", true)
			self:DivideSpeed(100)

			VictimCombat:StackState("HitboxImmunity", true)
			
			BlockAttack:Deactivate()
			
			local GrabObject = self:GrabVictim(VictimLuaPlayer, self.LuaCharacter.RootPart, CFrame.new(0, 0, -4.308) * CFrame.Angles(0, math.pi, 0))
			
			local VictimAnimation : AnimationTrack = VictimLuaPlayer.Character.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Global.Block.Edgerunner.Victim)
			local AttackerAnimationTime : number = BlockAnimationDirectory.Catch.Length

			BlockAnimationDirectory.Catch:GetMarkerReachedSignal("Push"):Once(function()
				VictimAnimation:AdjustSpeed(1.4)
				
				VictimCombat:StackState("HitboxImmunity", false)
				VictimCombat:StackState("ForceDashPush", true, 1.1)
				
				GrabObject.Destroy(0.5)
				VictimCombat:Unstun()
				VictimCombat:TrueStun(0.9)
				
				VictimLuaCharacter.Model:PivotTo(self:GetSimulatedRoot().CFrame * CFrame.new(0, 0, -4.308) * CFrame.Angles(0, math.pi, 0))

				local Velocity = self:Velocity()
				Velocity.Settings.Duration = 0.8
				Velocity.Settings.RemoveTime = 0.4
				Velocity.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				Velocity.Settings.Controllable = true
				Velocity.Settings.Z = -40
				Velocity:Fire()
				
				local Velocity = VictimCombat:Velocity()
				Velocity.Settings.Duration = 1
				Velocity.Settings.RemoveTime = 1
				Velocity.Settings.MaxForce = Vector3.new(1, 0, 1) * 80000
				Velocity.Settings.Controllable = true
				Velocity.Settings.Z = -50
				Velocity:Fire()
			end)
			
			BlockAnimationDirectory.Catch:Play(0)
			VictimAnimation:Play(0)
			
			self.LuaPlayer.Replication:FireReliableVFX("Edgerunner/Parry", "Start", self.LuaCharacter.Model, VictimLuaPlayer.Character.Model)
			
			task.wait(AttackerAnimationTime)

			self:TimesSpeed(100)
			
			self:StackState("Attacking", false)
			self:StackState("HitboxImmunity", false)
		end,
	},
	
	M1 = {
		StartFunction = function(self)
			if (self.Count == 4 and self.Condition == nil) then
				self.LuaCharacter.Edgerunner_Pistol_Appear_Stack:Add(1.5)
				--self.LuaCharacter.Edgerunner_Pistol:SetAttribute("Invisible", false)
				
			elseif self.Count == 3 then
				self.LuaCharacter.Edgerunner_Pistol_Appear_Stack:Add(1.5)
				--self.LuaCharacter.Edgerunner_Pistol:SetAttribute("Invisible", false)
			end
		end,

		--EndFunction = function(self)
		--	if (self.Count == 4 and self.Condition == nil) then
		--		self.LuaCharacter.Edgerunner_Pistol_Appear_Stack:Subtract()
		--		--self.LuaCharacter.Edgerunner_Pistol:SetAttribute("Invisible", true)
				
		--	elseif (self.Count == 3) then
		--		self.LuaCharacter.Edgerunner_Pistol_Appear_Stack:Subtract()
		--		--self.LuaCharacter.Edgerunner_Pistol:SetAttribute("Invisible", true)
		--	end
		--end,
	},
	
	OnSpawn = function(LuaPlayer)
		local Sandy = LuaPlayer.Character.Combat.SpawnJob:Task(script.Sandy:Clone())
		Sandy.Weld.Part0 = LuaPlayer.Character.Torso
		Sandy.Parent = LuaPlayer.Character.Model
		
		local Pistol_Model = script.Pistol:Clone()
		Pistol_Model.Pistol.Weld.Part0 = LuaPlayer.Character.RightArm

		local Pistol_Appear_Stack = NumberStack.new()
		
		local Holster  : AnimationTrack = LuaPlayer.Character.Animator:LoadAnimation(ReplicatedStorage.Animations.Attacks.Edgerunner.Holster.Windup)
		Holster.Priority = Enum.AnimationPriority.Movement -- blue garden asked
		
		Pistol_Appear_Stack.OnChanged:Connect(function(Value)
			if not Value then
				Holster:Play(0.1, 1, 1.5)
			end
			
			LuaPlayer.Replication:FireReliableVFX("Edgerunner/Pistol", if Value then "Appear" else "Shrink", LuaPlayer.Character.Model)
		end)

		--Pistol_Model:GetAttributeChangedSignal("Invisible"):Connect(function()
		--	local Invisible : boolean? = Pistol_Model:GetAttribute("Invisible")
		--	LuaPlayer.Replication:FireReliableVFX("Edgerunner/Pistol", if Invisible then "Shrink" else "Appear", LuaPlayer.Character.Model)
			
		--	--if Thread and coroutine.status(Thread) == "suspended" then
		--	--	task.cancel(Thread)
		--	--end
			
		--	--Thread = task.delay(0.4, function()
		--	--	LuaPlayer.Replication:FireReliableVFX("Edgerunner/Pistol", if Invisible then "Shrink" else "Appear", LuaPlayer.Character.Model)
		--	--end)
			
			
		--	--local Invisible = Pistol_Model:GetAttribute("Invisible")
			
		--	--for _, Item in ipairs(Pistol_Model:GetDescendants()) do
		--	--	if (Item:IsA("BasePart") or Item:IsA("Decal")) and not Item:HasTag("IgnoreTransparency") then
		--	--		Item.Transparency = Invisible and 1 or 0
		--	--	end
		--	--end
		--end)
		
		Pistol_Model.Parent = LuaPlayer.Character.Model
		
		LuaPlayer.Character.Edgerunner_Pistol = Pistol_Model
		LuaPlayer.Character.Edgerunner_Pistol_Appear_Stack = Pistol_Appear_Stack
		
		LuaPlayer.Character.Combat.SpawnJob:Task(function()
			Pistol_Model:Destroy()
			LuaPlayer.Character.Edgerunner_Pistol = nil
		end)
	end,

	Attacks = {
		["Adrenal Bash"] = Enum.KeyCode.One,
		["Servo Cannon"] = Enum.KeyCode.Two,
	},
}
