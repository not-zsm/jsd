local BaseEvent = require( script.Parent );

local InvincibleBoss = setmetatable({}, BaseEvent);
InvincibleBoss.__index = InvincibleBoss

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Shared.Utilities.EventService)
local Maid = require( ReplicatedStorage.Packages.Maid )

function InvincibleBoss.new(...)
	local self = setmetatable(BaseEvent.new(...), InvincibleBoss)
	
	-- Settings
	self.Settings = {
		TimeUntilTracking = 5, -- Seconds
		PortalDespawnDuration = 300,
		EventDuration = 400, -- Seconds
		BossHealth = 200,
	}
	
	self.PortalTemplate = ServerStorage.EventAssets.Portal
	self.SpawnsFolder = ServerStorage.EventAssets.PortalSpawns

	return self
end

function InvincibleBoss:Start()
	if self.Active then return end;
	
	BaseEvent.Start(self);
	
	-- Announce Dead Drop
	self.System.EventUtility:Announce("World Event - Conquest", "A portal has appeared somewhere on the map, investigate it further.")

	self:Spawn()
	
	self.Maid:add(self.Portal.Attachment.ProximityPrompt.Triggered:Connect(function(Player)
		local LuaPlayer, LuaCharacter = self.System.EventUtility:GetLuaPlayer(Player)
		
		if LuaCharacter.Combat:NotStunned() and LuaCharacter.HumanoidAlive and not LuaCharacter.Combat:IsWorldBoss() then
			self.Portal.Attachment.ProximityPrompt:Destroy()
			self:StartBoss(Player)
		end
	end))
	
	self.TimerThread = task.delay(self.Settings.PortalDespawnDuration, function()
		if self.Boss then return end;
		
		self:End("NoBoss")
	end);
	
	self.Maid:add(self.TimerThread)
end

function InvincibleBoss:_TogglePortal(Value : boolean)
	if self.Portal and self.Portal.VFX then
		for _, Item in ipairs(self.Portal.VFX:GetChildren()) do
			if Item:IsA("ParticleEmitter") or Item:IsA("Trail") or Item:IsA("Beam") or Item:IsA("PointLight") then
				Item.Enabled = Value
			end
		end
	end
end

--function InvincibleBoss:StartObtainment(LuaPlayer)
--	local LuaCharacter = LuaPlayer.Character
	
--	LuaCharacter.RootPart.Anchored = true
--	LuaCharacter.Combat:StackState("HitboxImmunity", true)
--	LuaCharacter.Combat:StackState("Attacking", true)
--	LuaCharacter.Combat:HideUI(true)
	
--	LuaPlayer.Replication:FireReliableVFXToSelf("WorldEvents/InvincibleEvent", "Enter")

--	self:_TogglePortal(false)
	
--	self.BossMaid:add(task.wait(12))
	
--	self:_TogglePortal(true)
	
--	self.BossMaid:add(task.wait(2))
	
--	LuaCharacter.RootPart.CFrame = self.Portal.CFrame * CFrame.new(0, -3.5, -24)
	
--	local Animation : AnimationTrack = LuaCharacter:LoadAnimation(ReplicatedStorage.Animations.WorldEvents.InvincibleBoss.PortalExit.User)
--	Animation:Play()
	
--	self.System.EventUtility:FireReliableVFX("WorldEvents/InvincibleEvent", "Exit", LuaCharacter.Model)
	
--	self.BossMaid:add(Animation.Stopped:Wait())
--	-- Obtainment Ended
	
--	LuaCharacter.RootPart.Anchored = false
--	LuaCharacter.Combat:HideUI(false)
	
--	LuaCharacter.Combat:StackState("HitboxImmunity", false)
--	LuaCharacter.Combat:StackState("Attacking", false)
--end

function InvincibleBoss:StartBoss(Player : Player)
	local LuaPlayer, LuaCharacter = self.System.EventUtility:GetLuaPlayer(Player)
	
	self.BossMaid = self.Maid:limb()
	self.Boss = Player
	
	----------- BOSS CONNECTIONS -----------
	
	-- If Player Dies
	self.BossMaid:add(LuaCharacter.OnHumanoidAvailabilityChanged:Connect(function(Value : boolean)
		if not Value then
			self:End("Died")
		end
	end))

	-- If Player Leaves
	self.BossMaid:add(LuaPlayer.OnDestroyed:Connect(function()
		self:End("Left")
	end))

	-- If Player Switches Characters
	self.CharacterSwitchingConnection = LuaCharacter.Combat.OnCharacterSwitching:Connect(function(CharacterName : String)
		if CharacterName ~= "Invincible" then
			self:End("Died")
		end
	end)
	
	self.Maid:delete(self.TimerThread);
	self.BossMaid:add(self.CharacterSwitchingConnection)
	
	----- START OBTAINMENT -----
	
	--self:StartObtainment(LuaPlayer)
	
	local CutsceneMaid = self.BossMaid:limb()
	local NoRotate = LuaCharacter:StopAutoRotate()
	
	LuaCharacter:Anchor(true, true)
	LuaCharacter.RootPart.CFrame = CFrame.new(0, 2.997, -20000)
	LuaCharacter.Combat:StackState("HitboxImmunity", true)
	LuaCharacter.Combat:StackState("Attacking", true)
	LuaCharacter.Combat:HideUI(true)

	LuaPlayer.Replication:FireReliableVFXToSelf("WorldEvents/InvincibleEvent", "Enter")
	
	CutsceneMaid:add(function()
		self:_TogglePortal(false)
		
		LuaCharacter:Anchor(false)
		LuaCharacter.Combat:HideUI(false)

		if NoRotate then
			NoRotate:Destroy()
		end

		LuaCharacter.Combat:StackState("HitboxImmunity", false)
		LuaCharacter.Combat:StackState("Attacking", false)
	end)

	self:_TogglePortal(false)
	self.Portal.PortalLoop:Stop()

	CutsceneMaid:add(task.wait(12))

	self:_TogglePortal(true)

	CutsceneMaid:add(task.wait(2))

	do
		self.PreviousCharacter = LuaPlayer.Replication.Attributes:GetAttribute("CurrentCharacter") or "Default"
		
		LuaCharacter.Combat:SetCharacter("Invincible")
		LuaCharacter.Combat.IsInvincibleFromWorldEvent = true
		
		local Humanoid : Humanoid = LuaCharacter.Humanoid
		Humanoid.MaxHealth = self.Settings.BossHealth
		LuaCharacter:HealFull()
	end
	
	LuaCharacter:StopRegen()
	
	CutsceneMaid:add(task.spawn(function()
		for Index = 1, 20 do
			task.wait(0.2)
			
			LuaCharacter.RootPart.CFrame = self.Portal.CFrame * CFrame.new(0, -3.5, -24)
		end
	end))
	
	local Animation : AnimationTrack = LuaCharacter:LoadAnimation(ReplicatedStorage.Animations.WorldEvents.InvincibleBoss.PortalExit.User)
	
	LuaCharacter.RootPart.CFrame = self.Portal.CFrame * CFrame.new(0, -3.5, -24)
	Animation:Play(0)

	self.System.EventUtility:FireReliableVFX("WorldEvents/InvincibleEvent", "Exit", LuaCharacter.Model)
	
	do
		local Shirt = LuaCharacter.Model:FindFirstChildOfClass("Shirt")
		local Pants = LuaCharacter.Model:FindFirstChildOfClass("Pants")
		self.OldClothes = {}
		
		if Shirt then
			self.OldClothes["Shirt"] = Shirt.ShirtTemplate
		else
			Shirt = Instance.new("Shirt")
			Shirt.Parent = LuaCharacter.Model
		end
		
		if Pants then
			self.OldClothes["Pants"] = Pants.PantsTemplate
		else
			Pants = Instance.new("Pants")
			Pants.Parent = LuaCharacter.Model
		end
		
		Shirt.ShirtTemplate = "rbxassetid://15669236574"
		Pants.PantsTemplate = "rbxassetid://15669248678"
	end
	
	CutsceneMaid:add(Animation.Stopped:Connect(function()
		CutsceneMaid:destroy()

		-- Start Countdown
		if self.Boss then
			
			self.Maid:add(function()
				if self.CharacterSwitchingConnection then
					self.BossMaid:delete(self.CharacterSwitchingConnection)
				end

				local NewLuaPlayer, NewLuaCharacter = self.System.EventUtility:GetLuaPlayer(self.Boss)

				if NewLuaPlayer and NewLuaCharacter then
					NewLuaCharacter.Humanoid.MaxHealth = 100
					NewLuaCharacter:HealFull()
					NewLuaCharacter:StartRegen()

					if self.PreviousCharacter then
						NewLuaCharacter.Combat:SetCharacter(self.PreviousCharacter)
					else
						NewLuaCharacter.Combat:SetCharacter("Gojo")
					end

					LuaCharacter.Combat.IsInvincibleFromWorldEvent = nil

					do
						local Shirt = NewLuaCharacter.Model:FindFirstChildOfClass("Shirt")
						local Pants = NewLuaCharacter.Model:FindFirstChildOfClass("Pants")

						if self.OldClothes["Shirt"] then
							Shirt.ShirtTemplate = self.OldClothes["Shirt"]
						else
							Shirt:Destroy()
						end

						if self.OldClothes["Pants"] then
							Pants.PantsTemplate = self.OldClothes["Pants"]
						else
							Pants:Destroy()
						end
					end
				end
			end)
			
			self.Maid:add(task.delay(self.Settings.EventDuration, function()
				self:End("OutOfTime")
			end))

			-- Set BossBar
			self.BossConfig = self.BossMaid:add(Instance.new("Configuration"))
			self.BossConfig:SetAttribute("Title", `{LuaCharacter.Humanoid.DisplayName}, the Conquered`)
			self.BossConfig:SetAttribute("BarType", "Invincible")
			self.BossConfig.Parent = LuaCharacter.Humanoid
			self.BossConfig:AddTag("BossBar")

			self.System.EventUtility:Announce("World Event - Conquest", `{self.Boss:GetAttribute("Name")} has become the Conquered, defeat them if you wish to live.`)
		end
	end))
end

-- Spawn Animation
function InvincibleBoss:Spawn()
	local SpawnLocations = self.SpawnsFolder:GetChildren()

	local RandomSpawn = SpawnLocations[math.random(1, #SpawnLocations)]
	local SpawnCFrame = RandomSpawn.CFrame -- * CFrame.new(0, 1, 0)

	self.Portal = self.Maid:add(self.PortalTemplate:Clone())
	self.Portal.CFrame = SpawnCFrame
	self.Portal.Parent = workspace.Visuals

	self.Portal.PortalLoop:Play()
	self.Portal.Attachment.ProximityPrompt.Enabled = true
	
	self:_TogglePortal(true)
end

function InvincibleBoss:End(Result)
	if not self.Active then return end;
	
	if Result == "NoBoss" then
		self.System.EventUtility:Announce("World Event - Conquest", `Nobody found the portal in time.`)
		
	elseif Result == "OutOfTime" then
		self.System.EventUtility:Announce("World Event - Conquest", `The Earth has failed to defeat {self.Boss:GetAttribute("Name")}, the Conquered in time.`)
		
	elseif Result == "EventEnded" then
		self.System.EventUtility:Announce("World Event - Conquest", `The event was ended.`)
		
	elseif self.Boss then
		self.System.EventUtility:Announce("World Event - Conquest", `The Earth has defeated {self.Boss:GetAttribute("Name")}, the Conquered.`)
	end;
	
	BaseEvent.End(self, Result);
end

return InvincibleBoss