local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local LoveTrainStorage = replicatedStorage.modules.client.replication.VFX.Emotes["Love Train"]
local ChainsawStorage = replicatedStorage.modules.client.replication.VFX.Emotes["Chainsaw Heart"]

local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )
local JobApplication = require( replicatedStorage.modules.shared.Utilities.Job )

local EyeOfRah_Assets = replicatedStorage.modules.effect.assets["Eye Of Rah"]
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local ModelTransparency = require( replicatedStorage.modules.client.replication.Global.CharacterTransparency )

return {
	["Combat Gods"] = {
		Collab = {
			ObjectText = "Combat Gods",
			ActionText = "Battle",

			TeleportOnEmoteEnded = true,
			StopAnimationWhenPlayerJoins = true,

			Function = function(self, TargetCombat, MainJob, JoinedJob)
				local attacker : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(replicatedStorage.ass.emotes["Combat Gods"].User)
				local victim : AnimationTrack = TargetCombat.LuaCharacter.Animator:LoadAnimation(replicatedStorage.ass.emotes["Combat Gods"].Victim)

				local thread = coroutine.create(function()
					local Loading = false

					local function Load()
						if Loading then return end

						Loading = true

						if not self.LuaPlayer.IsNPC then
							network.notify.sendTo({
								Title = "Notification",
								Text = "Loading the Combat Gods emote, this may take a little.",
								Duration = 1.5
							}, self.LuaPlayer.Player)
						end

						if not TargetCombat.LuaPlayer.IsNPC then
							network.notify.sendTo({
								Title = "Notification",
								Text = "Loading the Combat Gods emote, this may take a little.",
								Duration = 1.5
							}, TargetCombat.LuaPlayer.Player)
						end
					end

					if attacker.Length <= 0 then
						Load()

						repeat task.wait() until attacker.Length > 0
					end

					if victim.Length <= 0 then
						Load()

						repeat task.wait() until victim.Length > 0
					end

					JoinedJob:Task(self.LuaCharacter:StopAutoRotate())
					JoinedJob:Task(TargetCombat.LuaCharacter:StopAutoRotate())

					self.LuaCharacter:Anchor(true)
					TargetCombat.LuaCharacter:Anchor(true)

					TargetCombat.LuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame)
					network.grabSet.sendToAll({ part = TargetCombat.LuaCharacter.RootPart, boundTo = self.LuaCharacter.RootPart, offset = CFrame.identity })

					attacker:Play(0)
					victim:Play(0)

					self.LuaPlayer.Replication:FireReliableVFX("Emotes/Combat Gods", "Start", self.LuaCharacter.Model, TargetCombat.LuaCharacter.Model)

					self:HideUI(true)
					TargetCombat:HideUI(true)

					JoinedJob:Task(attacker.Stopped:Once(function()
						MainJob:Destroy()
					end))

					JoinedJob:Task(function()
						self:HideUI(false)
						TargetCombat:HideUI(false)

						self.LuaCharacter:Anchor(false)
						TargetCombat.LuaCharacter:Anchor(false)

						network.grabDetach.sendToAll(TargetCombat.LuaCharacter.RootPart)
					end)
				end)

				coroutine.resume(thread)

				JoinedJob:Task(function()
					if coroutine.status(thread) == "suspended" then
						coroutine.close(thread)
					end

					attacker:Stop(0)
					victim:Stop(0)
				end)
			end,
		}
	},

	["Isagi"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self.LuaCharacter:Anchor(true)
			self:HideUI(true)
			
			Job:Task(self.LuaCharacter:StopAutoRotate())

			self.LuaPlayer.Replication:FireReliableVFX("Emotes/Isagi", "OnStart", self.LuaCharacter.Model)

			Job:Task(Animation.Stopped:Once(function()
				Job:Destroy()
			end))

			Job:Task(function()
				self:HideUI(false)
				self.LuaCharacter:Anchor(false)
			end)
		end,
	},
	
	["Love Train"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			--self.LuaCharacter:Anchor(true)
			self:DivideSpeed(200)
			self:HideUI(true)
			
			local WasInterupted = true
			
			Job:Task(self.LuaCharacter:StopAutoRotate()) 

			Job:Task(function()
				self:TimesSpeed(200)
			end)
			
			local Stand : typeof(LoveTrinStorage.Stand) = self.LuaCharacter.Model:FindFirstChild("D4C")
			local Join
			
			local FirstTimePLaying = false
			
			if Stand then
				Join = Stand.HumanoidRootPart:FindFirstChild("StandWeld")
				
				Join.C0 = CFrame.identity
				
				for _, Item : ParticleEmitter in self.LuaCharacter.Model:GetDescendants() do
					if not Item:HasTag("LoveTrainAura") then
						continue
					end

					Item:Destroy()
				end
			else
				Stand = LoveTrainStorage.Stand:Clone()
				Stand.Name = "D4C"
				
				Join = Instance.new("Weld")
				Join:AddTag("DontModifyOnRagdoll")
				Join.Part0 = Stand.HumanoidRootPart
				Join.Part1 = self.LuaCharacter.RootPart
				Join.Name = "StandWeld"
				Join.Parent = Stand.HumanoidRootPart
				Stand.Parent = self.LuaCharacter.Model
				
				FirstTimePLaying = true
			end
			
			local CurrentStack = Stand:GetAttribute("StandStack") or 0
			CurrentStack += 1
			
			Stand:SetAttribute("StandStack", CurrentStack)
			
			local SFX : Sound = self.LuaCharacter.RootPart:FindFirstChild("LoveTrainTheme") or LoveTrainStorage.SFX:Clone()
			SFX.Name = "LoveTrainTheme"
			SFX.Parent = self.LuaCharacter.RootPart
			SFX:Play()
			
			self.LuaPlayer.Replication:FireReliableVFX("Emotes/Love Train", "OnStart", self.LuaCharacter.Model)
			
			Job:Task(Animation.Stopped:Once(function()
				Job:Destroy()
			end))
			
			Job:Task(Animation:GetMarkerReachedSignal("BarrierRemove"):Once(function()
				WasInterupted = false
			end))
			
			local LoveTrainBarrier
			
			Job:Task(Animation:GetMarkerReachedSignal("FlareRemove"):Once(function()
				for _, Part in {"Head", "LeftArm", "Torso", "RightArm", "LeftLeg", "RightLeg"} do
					if not self.LuaCharacter[Part] then
						continue
					end
					
					for _, Item in LoveTrainStorage.Aura:GetChildren() do
						Item:Clone().Parent = self.LuaCharacter[Part]
					end
				end
			end))
			
			Job:Task(function()
				self:HideUI(false)
				--self.LuaCharacter:Anchor(false)
				
				if WasInterupted then
					Stand:Destroy()
					SFX:Destroy()
				else
					if FirstTimePLaying then
						Stand.Controller.Animator:LoadAnimation(replicatedStorage.ass.emotes["Love Train"].StandIdle):Play(0)
					end
					
					if not CollectionService:HasTag(self.LuaCharacter.Model, "LoveTrainBarrier") then
						CollectionService:AddTag(self.LuaCharacter.Model, "LoveTrainBarrier")
					end
					
					local NewJob = JobApplication.new()
					
					NewJob:Task(self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value)
						if not Value then
							NewJob:Destroy()
						end
					end))
					
					NewJob:Task(SFX.Ended:Once(function()
						NewJob:Destroy()
					end))
					
					NewJob:Task(function()
						local CurrentStack = Stand:GetAttribute("StandStack") or 0
						
						CurrentStack -= 1
						
						if CurrentStack > 0 then
							Stand:SetAttribute("StandStack", CurrentStack)
							return
						end
						
						CollectionService:RemoveTag(self.LuaCharacter.Model, "LoveTrainBarrier")
						
						Stand:Destroy()
						SFX:Destroy()
						
						for _, Item : ParticleEmitter in self.LuaCharacter.Model:GetDescendants() do
							if not Item:HasTag("LoveTrainAura") then
								continue
							end
							
							Item:Destroy()
						end
					end)
					
					Join.C0 = CFrame.new(2, -1, -2)
				end
			end)
		end,
	},
	
	["Final Matchup"] = {
		CustomFunction = function(self, Job, Animation)
			local Ball = Job:Task(replicatedStorage.modules.client.replication.VFX.Emotes["Final Matchup"].Ball:Clone())
			Ball.Parent = self.LuaCharacter.Model
			Ball.Motor.Part0 = self.LuaCharacter.RootPart
		end,
		
		Collab = {
			ObjectText = "Final Matchup",
			ActionText = "Battle",
			
			--TeleportOnEmoteEnded = true,
			StopAnimationWhenPlayerJoins = true,

			Function = function(self, TargetCombat, MainJob, JoinedJob)
				local ReplicationModule = replicatedStorage.modules.client.replication.VFX.Emotes["Final Matchup"]
				local Animations = replicatedStorage.ass.emotes["Final Matchup"]
				
				local KeyframelessTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(Animations.Keyframeless)
				
				local thread = coroutine.create(function()
					local Ball = self.LuaCharacter.Model:FindFirstChild("Ball")

					if Ball then
						Ball:Destroy()
					end
					
					local FriendTable = self.LuaPlayer.FriendTable
					
					if next(FriendTable) == nil and next(TargetCombat.LuaPlayer.FriendTable) ~= nil then
						FriendTable = TargetCombat.LuaPlayer.FriendTable
					end
					
					local Loading = false

					local function Load()
						if Loading then return end

						Loading = true

						if not self.LuaPlayer.IsNPC then
							network.notify.sendTo({
								Title = "Notification",
								Text = "Loading the Final Matchup emote, this may take a little.",
								Duration = 1.5
							}, self.LuaPlayer.Player)
						end

						if not TargetCombat.LuaPlayer.IsNPC then
							network.notify.sendTo({
								Title = "Notification",
								Text = "Loading the Final Matchups emote, this may take a little.",
								Duration = 1.5
							}, TargetCombat.LuaPlayer.Player)
						end
					end
					
					if KeyframelessTrack.Length <= 0 then
						Load()
						repeat task.wait() until KeyframelessTrack.Length > 0
					end
					
					JoinedJob:Task(self.LuaCharacter:StopAutoRotate())
					JoinedJob:Task(TargetCombat.LuaCharacter:StopAutoRotate())

					KeyframelessTrack:Play(0)
					
					local GeneratedFriends = {
						Nagi = FriendTable[math.random(1, #FriendTable)],
						Isagi = FriendTable[math.random(1, #FriendTable)],
						Barou = FriendTable[math.random(1, #FriendTable)],
					}
					
					
					for _, Replication in {self.LuaPlayer.Replication, TargetCombat.LuaPlayer.Replication} do
						Replication:FireReliableVFXToSelf("Emotes/Final Matchup", "Start", self.LuaCharacter.Model, TargetCombat.LuaCharacter.Model, GeneratedFriends)
					end
					
					JoinedJob:Task(KeyframelessTrack.Stopped:Once(function()
						MainJob:Destroy()
					end))
				end)
				
				self:HideUI(true)
				TargetCombat:HideUI(true)

				self.LuaCharacter:Anchor(true)
				TargetCombat.LuaCharacter:Anchor(true)
				
				self.LuaCharacter:SetCollisionGroup("NoCollision")
				TargetCombat.LuaCharacter:SetCollisionGroup("NoCollision")
				
				coroutine.resume(thread)
				
				JoinedJob:Task(function()
					self:HideUI(false)
					TargetCombat:HideUI(false)
					
					self.LuaCharacter:Anchor(false)
					TargetCombat.LuaCharacter:Anchor(false)
					
					self.LuaCharacter:SetCollisionGroup("Player")
					TargetCombat.LuaCharacter:SetCollisionGroup("Player")
					
					if coroutine.status(thread) == "suspended" then
						coroutine.close(thread)
					end
					
					KeyframelessTrack:Stop(0)
				end)
			end,
		}
	},

	["The Final Showdown"] = {
		Collab = {
			ObjectText = "The Final Showdown",
			ActionText = "Accept Challenge",

			--TeleportOnEmoteEnded = true,
			StopAnimationWhenPlayerJoins = true,

			Function = function(self, TargetCombat, MainJob, JoinedJob)
				local Animations = replicatedStorage.ass.emotes["The Final Showdown"]
				local KeyframelessTrack : AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(Animations.Keyframeless)

				local thread = coroutine.create(function()
					KeyframelessTrack:Play(0)
					
					self.LuaPlayer.Replication:FireReliableVFX("Emotes/The Final Showdown", "OutsideView", self.LuaCharacter.Model, TargetCombat.LuaCharacter.Model)
					
					for _, Replication in {self.LuaPlayer.Replication, TargetCombat.LuaPlayer.Replication} do
						Replication:FireReliableVFXToSelf("Emotes/The Final Showdown", "Start", self.LuaCharacter.Model, TargetCombat.LuaCharacter.Model)
					end
				end)
				
				MainJob:Task(KeyframelessTrack.Stopped:Once(function()
					MainJob:Destroy()
				end))
				
				local AttackerNoRotation = self.LuaCharacter:StopAutoRotate()
				local VictimNoRotation = TargetCombat.LuaCharacter:StopAutoRotate()
				
				coroutine.resume(thread)
				
				self:HideUI(true)
				TargetCombat:HideUI(true)

				self.LuaCharacter:Anchor(true)
				TargetCombat.LuaCharacter:Anchor(true)
				
				self.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
				TargetCombat.LuaCharacter:SetCollisionGroup("NoPlayerCollision")
				
				self.LuaCharacter.RootPart.CFrame = TargetCombat.LuaCharacter.RootPart.CFrame
				
				local Ended = false
				
				local function End()
					if Ended then return end 
					
					Ended = true
					
					self:HideUI(false)
					TargetCombat:HideUI(false)
					
					self.LuaCharacter:Anchor(false)
					TargetCombat.LuaCharacter:Anchor(false)
					
					self.LuaCharacter:SetCollisionGroup("Player")
					TargetCombat.LuaCharacter:SetCollisionGroup("Player")
					
					AttackerNoRotation:Destroy()
					VictimNoRotation:Destroy()

					if coroutine.status(thread) == "suspended" then
						coroutine.close(thread)
					end

					KeyframelessTrack:Stop(0)
				end
				
				MainJob:Task(End)
				JoinedJob:Task(End)
				
				JoinedJob:Task(task.delay(34.967, function() --34.8 + 17.33
					MainJob:Destroy()
				end))
			end,
		}
	},
	
	--["Eye Of Peace And Prosperity"] = {
	--	OwnerOnly = true,
		
	--	CustomFunction = function(self, Job)
	--		local OriginalFace = self.LuaCharacter.Head:FindFirstChildOfClass("Decal")

	--		if OriginalFace then
	--			OriginalFace.Parent = nil
	--		end

	--		local Smile = EyeOfRah_Assets["smile no eyes"]:Clone()
	--		Smile.Parent = self.LuaCharacter.Head

	--		for _, Item in ipairs(self.LuaCharacter.Model:GetDescendants()) do
	--			if Item:IsA("Accessory") then
	--				Item.Handle.Transparency = 1
	--			end
	--		end

	--		local Eye = EyeOfRah_Assets.Part1:Clone()
	--		Eye.Weld.Part1 = self.LuaCharacter.Head
	--		Eye.Parent = self.LuaCharacter.Head

	--		local Hair = EyeOfRah_Assets.Part2:Clone()
	--		Hair.Weld.Part1 = self.LuaCharacter.Head
	--		Hair.Parent = self.LuaCharacter.Head

	--		local Effects = Eye.effect
	--		local Flames = Effects.Flames

	--		Effects.Sound.RollOffMaxDistance = 10000
	--		Effects.Sound.PlaybackSpeed = 1.5
	--		Effects.Sound.Volume = 10

	--		local new_sequence = {};
	--		local size_factor = 10

	--		for _, keypoint in Flames.Size.Keypoints do
	--			table.insert(new_sequence, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * size_factor, keypoint.Envelope))
	--		end

	--		Flames.Size = NumberSequence.new(new_sequence)

	--		Job:Task(task.defer(function()
	--			while task.wait(Utility.Seed:NextNumber(0.15, 0.75)) do
	--				Flames.Parent = nil

	--				if Eye.effect.Sound.IsPlaying then
	--					Eye.effect.Sound:Stop()
	--				end
					
	--				if Eye.effect.sparkle.IsPlaying then
	--					Eye.effect.sparkle:Stop()
	--				end

	--				task.delay(1 / 60, function()
	--					if (Eye.Parent == nil) then return end

	--					Flames.Parent = Eye.effect
	--					Flames:Emit(5)
						
	--					Eye.effect.Sound:Play()
	--					Eye.effect.sparkle:Play()
						
	--					local RawColor = Color3.fromRGB(Utility.Seed:NextNumber(0, 255), Utility.Seed:NextNumber(0, 255), Utility.Seed:NextNumber(0, 255))
						
	--					self.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/EyeOfRah", "Rah", RawColor)
						
	--					Hair.Color = RawColor
	--					Flames.Color = ColorSequence.new(RawColor)
						
	--					local Hitbox = self.Hitbox:Create(true)
	--					Hitbox.Params.Offset = CFrame.identity
	--					Hitbox.Params.Size = 35

	--					Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
	--						local VictimLuaCharacter = VictimLuaPlayer.Character
	--						local VictimCombat = VictimLuaCharacter.Combat

	--						local Validated = self:Afflict(VictimLuaPlayer, {
	--							TriggerActiveCounterOverOrEqualLevel = -1,
	--							DontBypassIFrames = {},
	--							BreakBlock = true,
	--						})

	--						if Validated then
	--							VictimLuaCharacter:Heal(5)
	--						end
	--					end)

	--					Hitbox:Detect()
	--					Hitbox:Destroy()
	--				end)
	--			end
	--		end))

	--		Job:Task(function()
	--			Eye:Destroy()
	--			Hair:Destroy()
	--			Smile:Destroy()

	--			for _, Item in ipairs(self.LuaCharacter.Model:GetDescendants()) do
	--				if Item:IsA("Accessory") then
	--					Item.Handle.Transparency = 0
	--				end
	--			end

	--			if OriginalFace then
	--				OriginalFace.Parent = self.LuaCharacter.Head
	--			end
	--		end)
	--	end,
	--},
	
	--["Eye Of Doom And Despair"] = {
	--	OwnerOnly = true,
		
	--	CustomFunction = function(self, Job)
	--		local OriginalFace = self.LuaCharacter.Head:FindFirstChildOfClass("Decal")

	--		if OriginalFace then
	--			OriginalFace.Parent = nil
	--		end

	--		local Smile = EyeOfRah_Assets["smile no eyes"]:Clone()
	--		Smile.Parent = self.LuaCharacter.Head

	--		for _, Item in ipairs(self.LuaCharacter.Model:GetDescendants()) do
	--			if Item:IsA("Accessory") then
	--				Item.Handle.Transparency = 1
	--			end
	--		end

	--		local Eye = EyeOfRah_Assets.Part1:Clone()
	--		Eye.Weld.Part1 = self.LuaCharacter.Head
	--		Eye.Parent = self.LuaCharacter.Head

	--		local RawColor = Color3.new(0.372549, 0, 0)

	--		local Hair = EyeOfRah_Assets.Part2:Clone()
	--		Hair.Color = RawColor
	--		Hair.Weld.Part1 = self.LuaCharacter.Head
	--		Hair.Parent = self.LuaCharacter.Head

	--		local Effects = Eye.effect
	--		local Flames = Effects.Flames

	--		Effects.Sound.RollOffMaxDistance = 10000
	--		Effects.Sound.PlaybackSpeed = 0.5
	--		Effects.Sound.Volume = 10

	--		local new_sequence = {};
	--		local size_factor = 10

	--		for _, keypoint in Flames.Size.Keypoints do
	--			table.insert(new_sequence, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * size_factor, keypoint.Envelope))
	--		end

	--		Flames.Color = ColorSequence.new(RawColor)
	--		Flames.Size = NumberSequence.new(new_sequence)

	--		Job:Task(task.defer(function()
	--			while task.wait(Utility.Seed:NextNumber(0.15, 0.75)) do
	--				Flames.Parent = nil

	--				if Eye.effect.Sound.IsPlaying then
	--					Eye.effect.Sound:Stop()
	--				end

	--				task.delay(1 / 60, function()
	--					if (Eye.Parent == nil) then return end

	--					Flames.Parent = Eye.effect
	--					Flames:Emit(5)

	--					Eye.effect.Sound:Play()

	--					self.LuaPlayer.Replication:FireReliableVFXToSelf("Emotes/EyeOfRah", "Rah", RawColor)

	--					local Hitbox = self.Hitbox:Create(true)
	--					Hitbox.Params.Offset = CFrame.identity
	--					Hitbox.Params.Size = 35

	--					self.Hitbox:SphereDestruction(self.LuaCharacter.RootPart.Position, 25, 10)
						
	--					self.Hitbox:CreateHavocReplicated({
	--						parameters = {
	--							origin = CFrame.new(self.LuaCharacter.RootPart.Position),
	--							shape = "Sphere", 
	--							radius = 25,
	--							block_size = 6, 
	--						},
	--					})

	--					Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
	--						local VictimLuaCharacter = VictimLuaPlayer.Character
	--						local VictimCombat = VictimLuaCharacter.Combat

	--						local Validated = self:Afflict(VictimLuaPlayer, {
	--							TriggerActiveCounterOverOrEqualLevel = -1,
	--							DontBypassIFrames = {},
	--							BreakBlock = true,
	--						})

	--						if Validated then
	--							if math.random(1, 100) == 1 then
	--								self:Afflict(VictimLuaPlayer, {
	--									ExcludeAttempts = true,
	--									FinisherKill = true,
	--								})

	--								EffectUtility.EmitEffects(EyeOfRah_Assets.finisher, VictimLuaCharacter.RootPart)

	--								VictimCombat.Ragdoll:Toggle(true)

	--								local VelocityObject = self:VelocityOn(VictimCombat)
	--								VelocityObject.Settings.RemoveTime = 0.1
	--								VelocityObject.Settings.Velocity = self:CalculateUnitDifference(VictimLuaPlayer) * 300 + Vector3.yAxis * 200
	--								VelocityObject:Fire()

	--								VictimCombat:ImpactOnGroundHit()
	--							else
	--								self:DealDamage(VictimLuaPlayer, 20)
									
	--								local VelocityObject = self:VelocityOn(VictimCombat)
	--								VelocityObject.Settings.RemoveTime = 0.1
	--								VelocityObject.Settings.Velocity = self:CalculateUnitDifference(VictimLuaPlayer) * 80 + Vector3.yAxis * 90
	--								VelocityObject:Fire()
									
	--								self:Afflict(VictimLuaPlayer, {
	--									ExcludeAttempts = true;
	--									Ragdoll = 4;
	--								})
									
	--								--VictimCombat.Ragdoll:Toggle(true, 4)
	--								VictimCombat:ImpactOnGroundHit()
	--							end
	--						end
	--					end)

	--					Hitbox:Detect()
	--					Hitbox:Destroy()
	--				end)
	--			end
	--		end))

	--		Job:Task(function()
	--			Eye:Destroy()
	--			Hair:Destroy()
	--			Smile:Destroy()

	--			for _, Item in ipairs(self.LuaCharacter.Model:GetDescendants()) do
	--				if Item:IsA("Accessory") then
	--					Item.Handle.Transparency = 0
	--				end
	--			end

	--			if OriginalFace then
	--				OriginalFace.Parent = self.LuaCharacter.Head
	--			end
	--		end)
	--	end,
	--},
	
	---- eye of what ?!? 🥀
	--["Eye Of Malice And Malevolence"] = {
	--	OwnerOnly = true,
		
	--	CustomFunction = function(self, Job)
	--		local OriginalFace = self.LuaCharacter.Head:FindFirstChildOfClass("Decal")

	--		if OriginalFace then
	--			OriginalFace.Parent = nil
	--		end

	--		local Smile = EyeOfRah_Assets["smile no eyes"]:Clone()
	--		Smile.Parent = self.LuaCharacter.Head

	--		for _, Item in ipairs(self.LuaCharacter.Model:GetDescendants()) do
	--			if Item:IsA("Accessory") then
	--				Item.Handle.Transparency = 1
	--			end
	--		end

	--		local Eye = EyeOfRah_Assets.Part1:Clone()
	--		Eye.Weld.Part1 = self.LuaCharacter.Head
	--		Eye.Parent = self.LuaCharacter.Head
			
	--		local RawColor = Color3.new(0.0117647, 0.670588, 0)

	--		local Hair = EyeOfRah_Assets.Part2:Clone()
	--		Hair.Color = RawColor
	--		Hair.Weld.Part1 = self.LuaCharacter.Head
	--		Hair.Parent = self.LuaCharacter.Head

	--		local Effects = Eye.effect
	--		local Flames = Effects.Flames

	--		Effects.Sound.RollOffMaxDistance = 10000
	--		Effects.Sound.Volume = 10

	--		local new_sequence = {};
	--		local size_factor = 10

	--		for _, keypoint in Flames.Size.Keypoints do
	--			table.insert(new_sequence, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * size_factor, keypoint.Envelope))
	--		end

	--		Flames.Color = ColorSequence.new(RawColor)
	--		Flames.Size = NumberSequence.new(new_sequence)

	--		Job:Task(task.defer(function()
	--			while task.wait(Utility.Seed:NextNumber(0.15, 0.75)) do
	--				Flames.Parent = nil

	--				if Eye.effect.Sound.IsPlaying then
	--					Eye.effect.Sound:Stop()
	--				end

	--				task.delay(1 / 60, function()
	--					if (Eye.Parent == nil) then return end

	--					Flames.Parent = Eye.effect
	--					Flames:Emit(5)

	--					Effects.Sound.PlaybackSpeed = Utility.Seed:NextNumber(1, 1.5)
	--					Effects.Sound:Play()

	--					local Hitbox = self.Hitbox:Create(true)
	--					Hitbox.Params.Offset = CFrame.identity
	--					Hitbox.Params.Size = 35

	--					Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
	--						local VictimLuaCharacter = VictimLuaPlayer.Character
	--						local VictimCombat = VictimLuaCharacter.Combat

	--						local Validated = self:Afflict(VictimLuaPlayer, {
	--							TriggerActiveCounterOverOrEqualLevel = -1,
	--							DontBypassIFrames = {},
	--							BreakBlock = true,
	--						})

	--						if Validated then
	--							self:Afflict(VictimLuaPlayer, {
	--								ExcludeAttempts = true;
	--								Ragdoll = 1.25;
	--							})
	--							--VictimCombat.Ragdoll:Toggle(true, 1.25)

	--							local VelocityObject = self:VelocityOn(VictimCombat)
	--							VelocityObject.Settings.RemoveTime = 0.1
	--							VelocityObject.Settings.Velocity = -VictimLuaCharacter.RootPart.CFrame.LookVector * 20
	--							VelocityObject:Fire()
	--						end
	--					end)

	--					Hitbox:Detect()
	--					Hitbox:Destroy()
	--				end)
	--			end
	--		end))

	--		Job:Task(function()
	--			Eye:Destroy()
	--			Hair:Destroy()
	--			Smile:Destroy()

	--			for _, Item in ipairs(self.LuaCharacter.Model:GetDescendants()) do
	--				if Item:IsA("Accessory") then
	--					Item.Handle.Transparency = 0
	--				end
	--			end

	--			if OriginalFace then
	--				OriginalFace.Parent = self.LuaCharacter.Head
	--			end
	--		end)
	--	end,
	--},
	
	--["Slow It Down"] = {
	--	UserIds = {3207108852, 7207821215},
		
	--	CustomFunction = function(self, Job, Animation : AnimationTrack)
	--		self:DivideSpeed(200)

	--		Job:Task(function()
	--			self:TimesSpeed(200)
	--		end)
	--	end,
	--},
	
	["Toxic Moshpit"] = {
		UserIds = {7207821215},
		
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			self:DivideSpeed(200)
			
			Job:Task(function()
				self:TimesSpeed(200)
			end)
			
			Job:Task(Animation:GetMarkerReachedSignal("FAH"):Connect(function()
				do
					local WAH = replicatedStorage.modules.effect.assets.Emotes["Toxic Moshpit"].WAH:Clone()
					WAH.Parent = self.LuaCharacter.RootPart
					WAH.Flames:Emit()
				
					local new_sequence = {};
					local size_factor = 10

					for _, keypoint in WAH.Flames.Size.Keypoints do
						table.insert(new_sequence, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * size_factor, keypoint.Envelope))
					end

					WAH.Flames.Size = NumberSequence.new(new_sequence)
					
					task.delay(5, WAH.Destroy, WAH)
				end
				
				self.LuaPlayer.Replication:FireReliableVFX("Emotes/Toxic Moshpit", "FAH", self.LuaCharacter.Model)
				
				local SFX = EffectUtility.AddSFX(replicatedStorage.modules.effect.assets.Emotes["Toxic Moshpit"].FAH, self.LuaCharacter.RootPart)
				task.delay(2, SFX.Destroy, SFX)
				
				local Hitbox = self.Hitbox:Create(true)
				Hitbox.Params.Offset = CFrame.identity
				Hitbox.Params.Size = 35

				self.Hitbox:SphereDestruction(self.LuaCharacter.RootPart.Position, 35, 10)

				self.Hitbox:CreateHavocReplicated({
					parameters = {
						origin = CFrame.new(self.LuaCharacter.RootPart.Position),
						shape = "Sphere", 
						radius = 35,
						block_size = 6, 
					},
				})

				Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
					local VictimLuaCharacter = VictimLuaPlayer.Character
					local VictimCombat = VictimLuaCharacter.Combat

					local Validated = self:Afflict(VictimLuaPlayer, {
						TriggerActiveCounterOverOrEqualLevel = -1,
						DontBypassIFrames = {},
						BreakBlock = true,
					})

					if Validated then
						self:DealDamage(VictimLuaPlayer, 20)

						local VelocityObject = self:VelocityOn(VictimCombat)
						VelocityObject.Settings.RemoveTime = 0.1
						VelocityObject.Settings.Velocity = self:CalculateUnitDifference(VictimLuaPlayer) * 80 + Vector3.yAxis * 90
						VelocityObject:Fire()

						VictimCombat.Ragdoll:Toggle(true, 4)
						VictimCombat:ImpactOnGroundHit()
					end
				end)

				Hitbox:Detect()
				Hitbox:Destroy()
			end))
		end,
	},
	
	["Chainsaw Heart"] = {
		CustomFunction = function(self, Job, Animation : AnimationTrack)
			--self.LuaCharacter:Anchor(true)
			self:DivideSpeed(200)
			self:HideUI(true)

			local WasInterupted = true

			Job:Task(self.LuaCharacter:StopAutoRotate()) 

			Job:Task(function()
				self:TimesSpeed(200)
			end)

			local OldChainsaw = self.LuaCharacter.Model:FindFirstChild("Chainsaw")
			
			if OldChainsaw then
				OldChainsaw:Destroy()
			end
				
			local Chainsaw = ChainsawStorage.Chainsaw:Clone()
			ModelTransparency(Chainsaw, 1)
			
			Job:Task(task.delay(1, function()
				ModelTransparency(Chainsaw, 0)
			end))
			Chainsaw.Parent = self.LuaCharacter.Model
			
			for _, Segment in pairs(Chainsaw:GetChildren()) do
				for _, Weld in pairs(Segment:GetChildren()) do
					local Weld = Segment:FindFirstChild("Weld")
					if Weld then
						Weld.Part0 = self.LuaCharacter.Model[Segment.Name]
						Weld:AddTag("DontModifyOnRagdoll")
					end
				end
			end

			local SFX : Sound = ChainsawStorage.SFX:Clone() -- temporary
			SFX.Name = "ChainsawTheme"
			SFX.Parent = Chainsaw.Head
			SFX:Play()

			self.LuaPlayer.Replication:FireReliableVFX("Emotes/Chainsaw Heart", "Start", self.LuaCharacter.Model, Chainsaw)

			Job:Task(Animation.Stopped:Once(function()
				Job:Destroy()
			end))

			Job:Task(Animation:GetMarkerReachedSignal("Finish"):Once(function()
				WasInterupted = false
			end))

			Job:Task(function()
				self:HideUI(false)
				--self.LuaCharacter:Anchor(false)

				if WasInterupted then
					Chainsaw:Destroy()
					--SFX:Destroy()
				else
					local NewJob = JobApplication.new()

					NewJob:Task(self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value)
						if not Value then
							NewJob:Destroy()
						end
					end))

					NewJob:Task(SFX.Ended:Once(function()
						NewJob:Destroy()
					end))
					
					NewJob:Task(Chainsaw)
					--NewJob:Task(SFX)
				end
			end)
		end,
	},
}
