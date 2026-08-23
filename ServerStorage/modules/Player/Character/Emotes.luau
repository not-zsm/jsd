local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local network = require( ReplicatedStorage.modules.network )
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local PolicyService = game:GetService("PolicyService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")
local Job = require( ReplicatedStorage.modules.shared.Utilities.Job )
local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )

local LuaPlayerList = require( ServerStorage.modules.LuaPlayerList )
local RemoteRateLimiter = require( ServerStorage.modules.Utility.RemoteRateLimiter )

local Limited_Emote_Dates = require( ReplicatedStorage.modules.shared.Game["Limited Emote Dates"] )
local Limited_Products_Ids = require( script["Limited Product Ids"] )
local Preloading = require( ServerStorage.modules.preloading )

local Remotes = ReplicatedStorage.Remotes

----------------------------------------------------------------------------------

local Emotes = {}
Emotes.__index = Emotes

local Data = require(script.Data)
local IndexTable = {}
local LimitedTable = {};

for Name, Data in pairs(Data) do
	if Data.NormalType then
		table.insert(IndexTable, Name)

	elseif Data.LimitedType then
		table.insert(LimitedTable, Name)
	end
end

----------------------------------------------------------------------------------

function Emotes:Destroy()
	task.spawn(function()
		if self.LuaPlayer.Data and self.LuaPlayer.Data.Profile then
			for Name in self.LuaPlayer.Data.Profile.Data.Emotes do
				local Animation = ReplicatedStorage.Animations.Emotes:FindFirstChild(Name)

				if Animation then
					Preloading.Remove(self.LuaPlayer.Player, Animation)
				end
			end
		end
	end)

	self.Job:Destroy()
end

----------------------------------------------------------------------------------

function Emotes:_Init()
	if self.LuaPlayer.IsNPC or not self.LuaPlayer:PlayerExists() then return end

	local HasExtraSlots = self.LuaPlayer.Data:HasGamepass("Extra Emote Slots") -- yields
	local EmoteEvent = self.LuaPlayer.Remotes:WaitForChild("Emote", 100)

	local LoadSlotsEvent = EmoteEvent:WaitForChild("LoadSlots", 100)
	local UpdateEvent = EmoteEvent:WaitForChild("Update", 100)

	LoadSlotsEvent:FireClient(self.LuaPlayer.Player, HasExtraSlots)
	UpdateEvent:FireClient(self.LuaPlayer.Player, self.LuaPlayer.Data.Profile.Data.Emotes, self.LuaPlayer.Data.Profile.Data.CurrentEmoteSlots)

	self:UpdateEmoteKillClaim()

	for Name in self.LuaPlayer.Data.Profile.Data.Emotes do
		local Animation = ReplicatedStorage.Animations.Emotes:FindFirstChild(Name)

		if Animation then
			Preloading.Add(self.LuaPlayer.Player, Animation)
		end
	end

	if not self.LuaPlayer.Data.Profile.Data.GotFreeEmoteForJoining then
		self.LuaPlayer.Data.Profile.Data.GotFreeEmoteForJoining = true
		self:GetRandom("Give")
	end

	task.spawn(function()
		if shared.IsTestPlace then
			network.notify.sendTo({
				Title = "Notification",
				Text = `Since this is the test place, you get all emotes! (Limiteds too) ✌😛`,
				Duration = 6
			}, self.LuaPlayer.Player)

			self:GetAll(true)
		end
	end)

	self.Job:Task(self.LuaPlayer.Remotes.Emote.Clicked.OnServerEvent:Connect(function(Player2 : Player, EmoteName : string)
		if self.LuaPlayer.Player ~= Player2 then return end
		if typeof(EmoteName) ~= "string" then return end

		if (RemoteRateLimiter.Check(self.LuaPlayer.Remotes.Emote.Clicked, self.LuaPlayer.Player, 15) == false) then
			return
		end

		if self.LuaPlayer.Data.Profile.Data.Emotes[EmoteName] then
			self:PlayEmote(EmoteName)
		end
	end))

	self.Job:Task(self.LuaPlayer.Remotes.Emote.Claim.OnServerEvent:Connect(function(Player2 : Player)
		if self.LuaPlayer.Player ~= Player2 then return end

		if (RemoteRateLimiter.Check(self.LuaPlayer.Remotes.Emote.Claim, self.LuaPlayer.Player, 15) == false) then
			return
		end

		if self:CalculateKillsCanClaim() > 0 then -- very important check
			self:GetRandom("Claim")
		end
	end))

	self.Job:Task(self.LuaPlayer.Remotes.Emote.BuyRandom.OnServerEvent:Connect(function(Player2 : Player)
		if self.LuaPlayer.Player ~= Player2 then return end

		if (RemoteRateLimiter.Check(self.LuaPlayer.Remotes.Emote.BuyRandom, self.LuaPlayer.Player, 15) == true) then
			if not RunService:IsStudio() and self.LuaPlayer.Player.Name ~= "swrerm" and shared.IsTestPlace then
				network.notify.sendTo({
					Title = "Notification",
					Text = "Not recommended to buy this in the test place",
					Duration = 3,
				}, self.LuaPlayer.Player)

				return
			end

			if not RunService:IsStudio() and self.LuaPlayer.Player.Name ~= "swrerm" then
				if (self.LuaPlayer.PolicyInfo == nil) then 
					network.notify.sendTo({
						Title = "Notification",
						Text = "Roblox could not load your policy info, please wait or rejoin if this occurs again.",
						Duration = 3,
					}, self.LuaPlayer.Player)

					return
				end

				if self.LuaPlayer.PolicyInfo.ArePaidRandomItemsRestricted then
					network.notify.sendTo({
						Title = "Notification",
						Text = "You are unable to purchase a random emote due to gambling regulations in your region.",
						Duration = 4,
					}, self.LuaPlayer.Player)

					return
				end
			end

			if not self:HasAll() then
				MarketplaceService:PromptProductPurchase(self.LuaPlayer.Player, 2657712724)
			end
		end
	end))

	self.Job:Task(self.LuaPlayer.Remotes.Emote.BuySlots.OnServerEvent:Connect(function(Player2 : Player)
		if self.LuaPlayer.Player ~= Player2 then return end

		if (RemoteRateLimiter.Check(self.LuaPlayer.Remotes.Emote.BuySlots, self.LuaPlayer.Player, 15) == true) then
			MarketplaceService:PromptGamePassPurchase(self.LuaPlayer.Player, 966942108)
		end
	end))

	self.Job:Task(self.LuaPlayer.Remotes.Emote.BuyLimited.OnServerEvent:Connect(function(Player2 : Player, Name : string)
		if self.LuaPlayer.Player ~= Player2 then return end

		if (RemoteRateLimiter.Check(self.LuaPlayer.Remotes.Emote.BuyLimited, self.LuaPlayer.Player, 15) == false) then
			return false
		end

		if not RunService:IsStudio() and shared.IsTestPlace then
			network.notify.sendTo({
				Title = "Notification",
				Text = "Not recommended to buy this in the test place",
				Duration = 3,
			}, self.LuaPlayer.Player)

			return
		end

		local Date : number = Limited_Emote_Dates[Name]
		if (Date == nil) then return end

		if os.time() > Date then
			return
		end

		local Pass = false

		if Name == "Combat Gods + Isagi" then
			local CannotHave = {
				["Combat Gods"] = true,
				["Isagi"] = true
			}

			for Emote in self.LuaPlayer.Data.Profile.Data.Emotes do
				if CannotHave[Emote] then
					print("cannot have", Emote)
					Pass = false

					break
				end
			end

		elseif Name == "Love Train" then
			Pass = not self.LuaPlayer.Data.Profile.Data.Emotes["Love Train"]

		elseif Name == "Final Matchup" then
			Pass = not self.LuaPlayer.Data.Profile.Data.Emotes["Final Matchup"]

		elseif Name == "The Final Showdown" then
			Pass = not self.LuaPlayer.Data.Profile.Data.Emotes["The Final Showdown"]
		end

		if Pass and Limited_Products_Ids[Name] then
			MarketplaceService:PromptProductPurchase(self.LuaPlayer.Player, Limited_Products_Ids[Name])
		end
	end))

	self.LuaPlayer.Remotes.Emote.UpdateSlot.OnServerInvoke = function(Player2 : Player, Slot : string, Name : string)
		if (self.LuaPlayer.Player ~= Player2 or typeof(Slot) ~= "string" or typeof(Name) ~= "string") then 
			return false 
		end

		if (RemoteRateLimiter.Check(self.LuaPlayer.Remotes.Emote.UpdateSlot, self.LuaPlayer.Player, 5) == false) then
			return false
		end

		local SlotToNumber = math.floor(Slot)

		if (SlotToNumber >= 1 and SlotToNumber <= 8) then
			self.LuaPlayer.Data.Profile.Data.CurrentEmoteSlots[Slot] = Name
			return true
		end

		return false
	end
end

function Emotes:PlayEmote(Name : string)
	if not self.Combat:NotStunned() or not self.LuaCharacter.HumanoidAlive or self.EmoteCooldown then return end

	if not self:HasAccessTo(Name) then
		return print("can't use this emote")
	end

	local EmoteData = Data[Name]
	if (EmoteData == nil) then return end

	--if self.Combat:GetState("EmoteDebounce") then
	--local Start = os.clock()

	--while self.Combat:GetState("EmoteDebounce") and (os.clock() - Start < 0.75) do
	--	self.Combat:GetStateChanged("EmoteDebounce"):Wait()
	--end

	--if self.Combat:GetState("EmoteDebounce") then
	--	return
	--end
	--end

	self.EmoteCooldown = true

	task.delay(0.3, function() 
		self.EmoteCooldown = false
	end)

	if self.CurrentEmote then
		self.CurrentEmote:Destroy()
		self.CurrentEmote = nil
	end

	local NewJob = Job.new()

	local Weapon = self.Combat.Attacks["Anubis Weapon"]

	if (Weapon ~= nil) then
		Weapon:Sheathe()

		NewJob:Task(function()
			Weapon:Unsheathe()
		end)
	end

	local Music = ReplicatedStorage.Emotes:FindFirstChild(Name)

	local Animation = ReplicatedStorage.Animations.Emotes:FindFirstChild(Name)
	local AnimationTrack : AnimationTrack? = nil
	local StandTrack : AnimationTrack? = nil
	local D4CTrack : AnimationTrack?

	if Animation then
		if (EmoteData.Collab ~= nil) then
			local CollabData = EmoteData.Collab

			if Animation:IsA("Folder") then
				local StartAnimation = Animation:FindFirstChild("Start")

				if StartAnimation then
					AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(StartAnimation)
					AnimationTrack:Play()
				end
			else
				AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(Animation)
				AnimationTrack:Play()
			end

			self.Combat:DivideSpeed(50)

			NewJob:Task(function()
				self.Combat:TimesSpeed(50)
			end)

			local AttributeName = Utility.ConvertStringAttributeFriendly(Name)

			local Prompt = Instance.new("ProximityPrompt")
			Prompt.RequiresLineOfSight = false
			Prompt.ActionText = CollabData.ActionText or "Join"
			Prompt.ObjectText = CollabData.ObjectText or AttributeName
			Prompt.Enabled = true
			Prompt.Parent = self.LuaCharacter.Torso

			NewJob:Task(function()
				Prompt.Enabled = false
				Prompt:Destroy()
			end)

			local Joined = {}

			local function RemovePlayer(VictimLuaPlayer)
				if Joined[VictimLuaPlayer] then
					Joined[VictimLuaPlayer]:Destroy()
					VictimLuaPlayer.Character.Combat:StackState("Emoting", false)

					if EmoteData.Collab.UsesSigmaFolderMethod then
						Prompt.Enabled = true

						Remotes.Emotes.Collabs.Proxy:FireAllClients(self.LuaPlayer.Player, Prompt)
					else
						if (Utility.TableCount(Joined) == 0) then
							Prompt.Enabled = true

							if not NewJob.Destroyed and AnimationTrack and not AnimationTrack.IsPlaying then
								AnimationTrack:Play()
							end
						end

						Remotes.Emotes.Collabs.Proxy:FireAllClients(self.LuaPlayer.Player, Prompt)
					end

					Joined[VictimLuaPlayer] = nil
				end
			end

			NewJob:Task(function()
				for VictimLuaPlayer in Joined do
					RemovePlayer(VictimLuaPlayer)
				end
			end)

			--local Joined = {}
			--local JoinedJobs = {}

			--local function RemovePlayer(VictimLuaPlayer)
			--	local VictimLuaCharacter = VictimLuaPlayer.Character
			--	local VictimCombat = VictimLuaCharacter.Combat

			--	local WasIn = table.find(Joined, VictimLuaPlayer)

			--	if WasIn then
			--		if JoinedJobs[VictimLuaPlayer.Player] then
			--			JoinedJobs[VictimLuaPlayer.Player]:Destroy()
			--			JoinedJobs[VictimLuaPlayer.Player] = nil
			--		end

			--		VictimCombat:StackState("Emoting", false)

			--		table.remove(Joined, WasIn)

			--		if EmoteData.Collab.UsesSigmaFolderMethod then
			--			Prompt.Enabled = true

			--			Remotes.Emotes.Collabs.Proxy:FireAllClients(self.LuaPlayer.Player, Prompt)
			--		else
			--			if Utility.TableCount(Joined) == 0 then
			--				Prompt.Enabled = true

			--				if not NewJob.Destroyed and AnimationTrack and not AnimationTrack.IsPlaying then
			--					AnimationTrack:Play()
			--				end
			--			end

			--			Remotes.Emotes.Collabs.Proxy:FireAllClients(self.LuaPlayer.Player, Prompt)
			--		end

			--	end
			--end

			--NewJob:Task(function()
			--	for Index, VictimLuaPlayer in Joined do
			--		local VictimLuaCharacter = VictimLuaPlayer.Character
			--		local VictimCombat = VictimLuaCharacter.Combat

			--		if JoinedJobs[VictimLuaPlayer.Player] then
			--			JoinedJobs[VictimLuaPlayer.Player]:Destroy()
			--			JoinedJobs[VictimLuaPlayer.Player] = nil
			--		end

			--		VictimCombat:StackState("Emoting", false)

			--		table.remove(Joined, Index)

			--		if EmoteData.Collab.UsesSigmaFolderMethod then
			--			Prompt.Enabled = true

			--			Remotes.Emotes.Collabs.Proxy:FireAllClients(self.LuaPlayer.Player, Prompt)
			--		else
			--			if Utility.TableCount(Joined) == 0 then
			--				Prompt.Enabled = true

			--				if not NewJob.Destroyed and AnimationTrack and not AnimationTrack.IsPlaying then
			--					AnimationTrack:Play()
			--				end
			--			end

			--			Remotes.Emotes.Collabs.Proxy:FireAllClients(self.LuaPlayer.Player, Prompt)
			--		end
			--	end
			--end)

			Prompt.Triggered:Connect(function(PlayerWhoTriggered)
				if (PlayerWhoTriggered == self.LuaPlayer.Player or not Prompt.Enabled) then -- so they cant join their own emote
					return 
				end

				local VictimLuaPlayer = LuaPlayerList.LuaPlayers[PlayerWhoTriggered]

				if VictimLuaPlayer and VictimLuaPlayer.Character.Combat:NotStunned() and not Joined[VictimLuaPlayer] then
					local VictimLuaCharacter = VictimLuaPlayer.Character
					local VictimCombat = VictimLuaCharacter.Combat

					if CollabData.StopAnimationWhenPlayerJoins and AnimationTrack and AnimationTrack.IsPlaying then
						AnimationTrack:Stop(0)
					end

					VictimCombat:StackState("Emoting", true)

					if VictimLuaPlayer.Character.Emotes.CurrentEmote then
						VictimLuaPlayer.Character.Emotes.CurrentEmote:Destroy()
						VictimLuaPlayer.Character.Emotes.CurrentEmote = nil
					end

					local JoinedJob = Job.new()

					JoinedJob:Task(function()
						if CollabData.TeleportOnEmoteEnded then
							VictimLuaCharacter.Model:PivotTo(self.LuaCharacter.RootPart.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0))
						end
					end)

					JoinedJob:Task(VictimCombat.OnStateChanged:Connect(function(State : string, Value : boolean)
						if (State == "Attacking" or State == "Dashing" or State == "Backdashing" or State == "M1ing" or State == "Ragdolled" or State == "Stunned" or State == "Blocking") and Value then
							RemovePlayer(VictimLuaPlayer)
						end
					end))

					JoinedJob:Task(VictimCombat.OnStateUpdated:Connect(function(State : string, Value : boolean)
						if (State == "Emoting" and Value) then
							RemovePlayer(VictimLuaPlayer)
						end
					end))

					JoinedJob:Task(VictimLuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value : boolean)
						if not Value then
							RemovePlayer(VictimLuaPlayer)
						end
					end))

					JoinedJob:Task(VictimCombat.OnSpaceStateChanged:Connect(function(Value : boolean)
						if Value then
							RemovePlayer(VictimLuaPlayer)
						end
					end))

					if (self.CurrentMusic == nil and Music and Music:IsA("Folder")) then
						local CollabMusic = Music:FindFirstChild("Collab")

						if CollabMusic then
							local NewMusic : Sound = CollabMusic:Clone()
							NewMusic.RollOffMaxDistance = 150
							NewMusic.Parent = self.LuaCharacter.Torso
							NewMusic.Looped = not Music:GetAttribute("DontLoop")
							NewMusic:Play()

							JoinedJob:Task(function()
								NewMusic:Destroy()
								self.CurrentMusic = nil
							end)

							self.CurrentMusic = NewMusic
						end
					end

					if CollabData.Function then
						task.spawn(CollabData.Function, self.Combat, VictimCombat, NewJob, JoinedJob, AnimationTrack)
					else
						if CollabData.Function2 then
							task.spawn(CollabData.Function2, self.Combat, {
								JoinedCombat = VictimCombat,
								JoinedJob = JoinedJob,
								JoinedTable = Joined,
								MainJob = NewJob,
								MainAnimation = AnimationTrack,
							})
						end
					end

					--JoinedJobs[VictimLuaPlayer.Player] = JoinedJob
					--table.insert(Joined, VictimLuaPlayer)

					Joined[VictimLuaPlayer] = JoinedJob

					local NewCount = Utility.TableCount(Joined)

					--if (CollabData.Limit or 1) ~= -1 and (NewCount >= (CollabData.Limit or 1)) then
					--	Prompt.Enabled = false
					--else
					--	Prompt.Enabled = true
					--end

					Prompt.Enabled = not ((CollabData.Limit or 1) ~= -1 and (NewCount >= (CollabData.Limit or 1)))
					Remotes.Emotes.Collabs.Joined:FireClient(VictimLuaPlayer.Player, Prompt)
				end
			end)

			Remotes.Emotes.Collabs.Proxy:FireAllClients(self.LuaPlayer.Player, Prompt)
		else
			if Animation:IsA("Folder") then
				local StartAnimation = Animation:FindFirstChild("Start")

				if StartAnimation then
					AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(StartAnimation)
					AnimationTrack:Play()
				end
			else
				AnimationTrack = self.LuaCharacter.Animator:LoadAnimation(Animation)
				AnimationTrack:Play(0.1, 1, EmoteData.AnimationSpeed or 1)

				if EmoteData.StopAfterAnimationStop then
					NewJob:Task(AnimationTrack.Stopped:Once(function()
						NewJob:Destroy()
					end))
				end

				local Stand : Model = self.LuaCharacter.Model:FindFirstChild("Stand")
				local D4C : Model = self.LuaCharacter.Model:FindFirstChild("D4C")

				if not EmoteData.NoStand and D4C then
					local StandMover = D4C.HumanoidRootPart:FindFirstChild("StandWeld")

					if StandMover then
						local Pre = StandMover.C0
						StandMover.C0 = CFrame.new(-4, 0, 0)

						NewJob:Task(function()
							StandMover.C0 = Pre
						end)
					end

					D4CTrack = D4C:FindFirstChild("Animator", true):LoadAnimation(Animation)
					D4CTrack:Play(0.1, 1, EmoteData.AnimationSpeed or 1)
				end

				if not EmoteData.NoStand and Stand then
					StandTrack = Stand:FindFirstChild("Animator", true):LoadAnimation(Animation)
					StandTrack:Play(0.1, 1, EmoteData.AnimationSpeed or 1)
				end
			end
		end
	end

	local OriginalMusicVolume = 0

	if Music and Music:IsA("Sound") then
		if (self.CurrentMusic == nil) then
			local NewMusic : Sound = Music:Clone()
			NewMusic.RollOffMaxDistance = 150

			OriginalMusicVolume = NewMusic.Volume
			NewMusic.Volume = 0

			NewMusic.Parent = self.LuaCharacter.Torso
			NewMusic:Play()

			NewJob:Task(NewMusic)
			self.CurrentMusic = NewMusic

			if EmoteData.SyncMusicWithAnimationLoop and AnimationTrack.Looped then
				--NewJob:Task(AnimationTrack.Stopped:Connect(function()
				--	if NewMusic.IsPlaying then
				--		NewMusic:Stop()
				--	end

				--	NewMusic:Play()
				--	AnimationTrack:Play()
				--end))

				local CurrentTime = 0

				NewJob:Task(RunService.PreAnimation:Connect(function()
					local LastTime = CurrentTime;

					CurrentTime = AnimationTrack.TimePosition;

					if (CurrentTime - LastTime) < 0 then
						CurrentTime = 0;

						if NewMusic.IsPlaying then
							NewMusic:Stop()
						end

						NewMusic:Play()
						AnimationTrack:Play()
					end
				end))

				--NewJob:Task(AnimationTrack.DidLoop:Connect(function()
				--	if NewMusic.IsPlaying then
				--		NewMusic:Stop()
				--	end

				--	NewMusic:Play()
				--end))
			end
		end
	else
		if (EmoteData.Music and self.CurrentMusic == nil) then
			local NewMusic : Sound = Instance.new("Sound")
			NewMusic.SoundId = "rbxassetid://" .. tostring(EmoteData.Music.Id)
			NewMusic.Volume =  EmoteData.Music.Volume or 1
			NewMusic.SoundGroup = SoundService.Emotes
			NewMusic.RollOffMaxDistance = 150
			NewMusic.PlaybackSpeed = EmoteData.Music.PlaybackSpeed or 1
			NewMusic.Looped = not EmoteData.DontLoopAudio

			NewMusic.PlaybackRegionsEnabled = ( EmoteData.Music.PlaybackRegion ~= nil)

			if EmoteData.Music.PlaybackRegion then
				NewMusic.PlaybackRegion = EmoteData.Music.PlaybackRegion
			end

			OriginalMusicVolume = NewMusic.Volume
			NewMusic.Volume = 0

			NewMusic.Parent = self.LuaCharacter.Torso
			NewMusic:Play()

			NewJob:Task(NewMusic)

			self.CurrentMusic = NewMusic
		end
	end

	if self.CurrentMusic then
		TweenService:Create(self.CurrentMusic, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{Volume = OriginalMusicVolume}
		):Play()
	end

	if EmoteData.CustomFunction then
		task.spawn(EmoteData.CustomFunction, self.Combat, NewJob, AnimationTrack)
	else
		self.Combat:DivideSpeed(5)

		NewJob:Task(function()
			self.Combat:TimesSpeed(5)
		end)
	end

	if not EmoteData.DontMakeEmoting then
		self.Combat:StackState("Emoting", true)
	end

	NewJob:Task(function()
		self.CurrentEmote = nil
		self.CurrentMusic = nil

		self.Combat:StackState("EmoteDebounce", true)

		self.Combat.Job:Task(task.delay(1, function()
			self.Combat:StackState("EmoteDebounce", false)
		end))

		if not EmoteData.DontMakeEmoting then
			self.Combat:StackState("Emoting", false)
		end

		if AnimationTrack then
			AnimationTrack:Stop()
		end

		if StandTrack then
			StandTrack:Stop()
		end

		if D4CTrack then
			D4CTrack:Stop()
		end
	end)

	if EmoteData.MoveToCancel then
		NewJob:Task(self.LuaCharacter.Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
			if (self.LuaCharacter.Humanoid.MoveDirection ~= Vector3.zero) then
				NewJob:Destroy()
			end
		end))
	end

	NewJob:Task(self.Combat.OnStateChanged:Connect(function(State : string, Value : boolean)
		if (State == "Attacking" or State == "Dashing" or State == "Backdashing" or State == "M1ing" or State == "Ragdolled" or State == "Stunned" or State == "Blocking") and Value then
			NewJob:Destroy()
		end
	end))

	NewJob:Task(self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value : boolean)
		if not Value then
			NewJob:Destroy()
		end
	end))

	NewJob:Task(self.Combat.OnSpaceStateChanged:Connect(function(Value : boolean)
		if Value then
			NewJob:Destroy()
		end
	end))

	self.CurrentEmote = NewJob

	return NewJob
end

function Emotes:HasAccessTo(Name)
	local EmoteData = Data[Name]

	if (EmoteData == nil) then
		return false
	end

	if EmoteData.UserIds and not table.find(EmoteData.UserIds, self.LuaPlayer.UserId) then
		return false
	end

	return true
end


--function Emotes:Get(Name : string, Claim : boolean?, Purchase : boolean?, Given : boolean?)
--	if self.LuaPlayer.IsNPC or self.LuaPlayer.Data.Profile.Data.Emotes[Name] then 
--		return false
--	end

--	local Animation = ReplicatedStorage.Animations.Emotes:FindFirstChild(Name)

--	if Animation then
--		Preloading.Add(self.LuaPlayer.Player, Animation)
--	end

--	self.LuaPlayer.Data.Profile.Data.Emotes[Name] = true

--	if Claim then
--		self.LuaPlayer.Data.Profile.Data.ClaimedEmotes += 1
--		print("actually claimed 1")

--	elseif Purchase then
--		self.LuaPlayer.Data.Profile.Data.BoughtEmotes[Name] = true
--	end

--	self.LuaPlayer.Remotes.Emote.Get:FireClient(self.LuaPlayer.Player, Name, Claim, Purchase, Given)
--	self:UpdateEmoteKillClaim()

--	return true
--end

function Emotes:Claim(Name : string)
	if not self:HasAccessTo(Name) then
		return false
	end

	if self.LuaPlayer.IsNPC or self.LuaPlayer.Data.Profile.Data.Emotes[Name] then 
		return false
	end

	local Animation = ReplicatedStorage.Animations.Emotes:FindFirstChild(Name)

	if Animation then
		Preloading.Add(self.LuaPlayer.Player, Animation)
	end

	self.LuaPlayer.Data.Profile.Data.Emotes[Name] = true
	self.LuaPlayer.Data.Profile.Data.ClaimedEmotes += 1

	self.LuaPlayer.Remotes.Emote.Get:FireClient(self.LuaPlayer.Player, Name, "Claim")
	self:UpdateEmoteKillClaim()

	return true
end

function Emotes:ClaimByExtra(Name : string)
	if not self:HasAccessTo(Name) then
		return false
	end

	if self.LuaPlayer.IsNPC or self.LuaPlayer.Data.Profile.Data.Emotes[Name] then 
		return false
	end

	local Animation = ReplicatedStorage.Animations.Emotes:FindFirstChild(Name)

	if Animation then
		Preloading.Add(self.LuaPlayer.Player, Animation)
	end

	self.LuaPlayer.Data.Profile.Data.ExtraEmoteClaims = math.max(0, self.LuaPlayer.Data.Profile.Data.ExtraEmoteClaims - 1)
	self.LuaPlayer.Data.Profile.Data.Emotes[Name] = true
	self.LuaPlayer.Remotes.Emote.Get:FireClient(self.LuaPlayer.Player, Name, "Claim")
	self:UpdateEmoteKillClaim()

	return true
end

function Emotes:Purchase(Name : string)
	if not self:HasAccessTo(Name) then
		return false
	end

	if self.LuaPlayer.IsNPC or self.LuaPlayer.Data.Profile.Data.Emotes[Name] then 
		return false
	end

	local Animation = ReplicatedStorage.Animations.Emotes:FindFirstChild(Name)

	if Animation then
		Preloading.Add(self.LuaPlayer.Player, Animation)
	end

	self.LuaPlayer.Data.Profile.Data.Emotes[Name] = true
	self.LuaPlayer.Data.Profile.Data.BoughtEmotes[Name] = true

	self.LuaPlayer.Remotes.Emote.Get:FireClient(self.LuaPlayer.Player, Name, "Purchase")
	self:UpdateEmoteKillClaim()

	return true
end

function Emotes:Give(Name : string)
	if not self:HasAccessTo(Name) then
		return false
	end

	if self.LuaPlayer.IsNPC or self.LuaPlayer.Data.Profile.Data.Emotes[Name] then 
		return false
	end

	local Animation = ReplicatedStorage.Animations.Emotes:FindFirstChild(Name)

	if Animation then
		Preloading.Add(self.LuaPlayer.Player, Animation)
	end

	self.LuaPlayer.Data.Profile.Data.Emotes[Name] = true

	self.LuaPlayer.Remotes.Emote.Get:FireClient(self.LuaPlayer.Player, Name, "Give")
	self:UpdateEmoteKillClaim()

	return true
end

function Emotes:AddEmoteClaims(Amount : number)
	self.LuaPlayer.Data.Profile.Data.ExtraEmoteClaims += Amount
	self:UpdateEmoteKillClaim()
end

function Emotes:CalculateKillsCanClaim()
	local Profile = self.LuaPlayer.Data.Profile

	if Profile and Profile:IsActive() then
		local Calculation = ((Profile.Data.Kills - self.KillsUntilEmote*Profile.Data.ClaimedEmotes) // self.KillsUntilEmote) + Profile.Data.ExtraEmoteClaims

		return math.max(Calculation, 0)
	end

	return 0
end

function Emotes:CalculateKillsToClaim()
	local Profile = self.LuaPlayer.Data.Profile

	if Profile and Profile:IsActive() then
		local Calculation = (self.KillsUntilEmote - (Profile.Data.Kills % self.KillsUntilEmote))

		return math.max(Calculation, 0)
	end

	return 0
end

function Emotes:UpdateEmoteKillClaim()
	self.LuaPlayer.Remotes.Emote.UpdateKillClaim:FireClient(self.LuaPlayer.Player, 
		self:CalculateKillsCanClaim(), 
		self:CalculateKillsToClaim(), 
		self:HasAll()
	)
end

function Emotes:HasAll()
	if self.LuaPlayer.IsNPC then 
		return false 
	end

	local LimitedCount = 0

	for _, Name in LimitedTable do
		if self.LuaPlayer.Data.Profile.Data.Emotes[Name] then
			LimitedCount += 1
		end
	end

	return Utility.TableCount(self.LuaPlayer.Data.Profile.Data.Emotes) >= #IndexTable + LimitedCount
end

function Emotes:GetAll(IncludeLimited : boolean)

	local function EditedGive(Name : string)
		if not self:HasAccessTo(Name) then
			return
		end

		local Animation = ReplicatedStorage.Animations.Emotes:FindFirstChild(Name)

		if Animation then
			Preloading.Add(self.LuaPlayer.Player, Animation)
		end

		self.LuaPlayer.Data.Profile.Data.Emotes[Name] = true
		self.LuaPlayer.Remotes.Emote.Get:FireClient(self.LuaPlayer.Player, Name, "Give")
	end

	for Index, Name : string in IndexTable do
		EditedGive(Name)
	end

	if IncludeLimited then
		for Index, Name : string in LimitedTable do
			EditedGive(Name)
		end
	end
end

function Emotes:GetRandom(Type : string)
	if self.LuaPlayer.IsNPC then return end

	if self:HasAll() then
		self.LuaPlayer.Remotes.Emote.ClaimedAll:FireClient(self.LuaPlayer.Player)
		return false
	end

	local Profile = self.LuaPlayer.Data.Profile

	local Emote = Utility.PickRandom(IndexTable, function(Emote)
		return (Profile.Data.Emotes[Emote] == nil)
	end)

	if Emote then
		if Profile.Data.ExtraEmoteClaims >= 1 then
			return self:ClaimByExtra(Emote), Emote
		else
			if (Type == "Claim") then
				return self:Claim(Emote), Emote

			elseif (Type == "Purchase") then
				return self:Purchase(Emote), Emote

			elseif Type == "Give" then
				return self:Give(Emote), Emote
			end
		end
	end

	return false
end

function Emotes:PlayRandomEmote()
	local Emote = IndexTable[math.random(1, #IndexTable)]

	if Emote then
		self:PlayEmote(Emote)
	end
end

function Emotes:Remove(Name : string)
	if self.LuaPlayer.IsNPC then return end

	if self.LuaPlayer.Data.Profile.Data.Emotes[Name] then
		self.LuaPlayer.Data.Profile.Data.Emotes[Name] = nil
		self.LuaPlayer.Remotes.Emote.Removed:FireClient(self.LuaPlayer.Player, Name)
	end
end

----------------------------------------------------------------------------------

function Emotes.new(LuaCharacter)
	local self = setmetatable({}, Emotes)

	self.Job = Job.new()

	self.LuaCharacter = LuaCharacter
	self.Combat = LuaCharacter.Combat
	self.LuaPlayer = LuaCharacter.LuaPlayer

	self.KillsUntilEmote = 50
	self.EmoteCooldown = false

	----------------------------------------

	self:_Init()

	return self
end

----------------------------------------------------------------------------------

table.freeze(Emotes)

return Emotes