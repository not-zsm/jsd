

local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require( replicatedStorage.modules.network )
local ServerStorage = game:GetService("ServerStorage")
local UserService = game:GetService("UserService")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")


----------------------------------------------------------------------------------

local Remotes = replicatedStorage.Remotes

local Shared = replicatedStorage.modules.shared
local SharedUtilities = Shared.Utilities

local NumberStack = require( SharedUtilities.NumberStack )
local EventService = require( SharedUtilities.EventService )
local Utility = require( SharedUtilities.Utility )
local Job = require( SharedUtilities.Job )

local rbxlscore = require( ServerStorage.modules.Utility.rbxlscore )
local CommandHandler = require( ServerStorage.modules.CommandHandler )

----------------------------------------------------------------------------------

local LuaCharacter = {}
LuaCharacter.__index = LuaCharacter

local Combat = require( ServerStorage.serverCombat )
local Emotes = require( script.Emotes )
local Title = require( script.Title )
local Items = require( script.Items )

----------------------------------------------------------------------------------

function LuaCharacter:Destroy()
	self:SetHumanoidAvailability(false, false)
	self:StopRespawnTimer()

	self.Job:Destroy()
	self.HumanoidJob:Destroy()
	self.DeathJob:Destroy()

	self.Emotes:Destroy()
	self.Combat:Destroy()
end

function LuaCharacter:_Init()
	self.Combat = Combat.new(self)

	if not self.LuaPlayer.IsNPC then
		self.Title = Title.new(self)
	end

	self.Emotes = Emotes.new(self)
	self.Items = Items.new(self)

	if not self.LuaPlayer.IsNPC then
		local function CharacterAdded(Model : Model)
			self.AppearanceLoaded = false
			self.Combat.Actions.LoadedProperly = false

			self:RegisterModel(Model);
			
			task.delay(0.1, function()
				CommandHandler:UpdateMacrosForPlayer(self.LuaPlayer);
			end)

			pcall(function()
				self:ApplyDescriptionToSelf()

				self.AppearanceLoaded = true
				self.OnAppearanceLoaded:Fire()
			end);
		end;

		local function CharacterRemoving()
			self:UnregisterModel()
		end

		if (self.LuaPlayer.Player.Character ~= nil) then
			task.defer(CharacterAdded, self.LuaPlayer.Player.Character)
		end

		self.LuaPlayer.Player.CharacterAdded:Connect(CharacterAdded)
		self.LuaPlayer.Player.CharacterRemoving:Connect(CharacterRemoving)
	else
		self:RegisterModel(self.LuaPlayer.Player)
	end

end

function LuaCharacter:SetOutfit(Id : number, ResetOld : boolean)
	--local data = rbxlscore.CheckUserId(Id)

	--if data and data.score and data.score[1] then
	--	local score : number = data.score[1]
	--	print("avatar score:", score)
		
	--	if (score >= 10) then
	--		local Success, Result = pcall(function()
	--			return Players:GetHumanoidDescriptionFromUserId(1)
	--		end)
			
	--		if Success then
	--			self.Humanoid:ApplyDescriptionReset(Result)
	--		end
			
	--		Remotes.Notification:FireClient(self.LuaPlayer.Player, {
	--			Title = "Error",
	--			Text = `Your avatar has been flagged as inappropriate. Please change.`,
	--			Duration = 4
	--		})
			
	--		return
	--	end
	--end

	local Success, Result = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(Id)
	end)
	
	if not Success then
		warn(Result)
	end
	
	if Success and Result then
		if ResetOld then
			self.Humanoid:ApplyDescriptionReset(Result)
		else
			self.Humanoid:ApplyDescription(Result)
		end

		self:AccessoryFix(Result)
	end
end

function LuaCharacter:GetDisguise()
	if (self.DisguiseId ~= nil) then
		return self.DisguiseId
	end
	
	if (self.LuaPlayer.Data.Profile and self.LuaPlayer.Data.Profile.Data.CurrentDisguise ~= nil) then
		return self.LuaPlayer.Data.Profile.Data.CurrentDisguise
	end
	
	return self.DisguiseId
end

local Verified_Badge = ""

function LuaCharacter:ApplyDescriptionToSelf()
	local Disguise : number? = self:GetDisguise()
	
	if (Disguise ~= nil) then
		local Success, Result = pcall(function()
			return UserService:GetUserInfosByUserIdsAsync({Disguise})
		end)

		if Success and Result then
			local Info = Result[1]

			if Info then
				self.OriginalDisplayName = self.Humanoid.DisplayName

				if Info.HasVerifiedBadge then
					self.Humanoid.DisplayName = Info.DisplayName .. Verified_Badge
				else
					self.Humanoid.DisplayName = Info.DisplayName
				end
				
				self.LuaPlayer.Player:AddTag("Disguise")
				self.LuaPlayer.Player:SetAttribute("Name", Info.Username)
				self.Humanoid:SetAttribute("PlayerName", Info.Username)
				
				self.LuaPlayer.Player:SetAttribute("UseNameAttributeForTextColor", true)
				self:SetOutfit(Disguise, true)
			end
		else
			warn(Result)
			self:SetOutfit(self.LuaPlayer.UserId, true)
		end
	else
		self.LuaPlayer.Player:RemoveTag("Disguise")
		self.LuaPlayer.Player:SetAttribute("Name", self.LuaPlayer.PlayerName)
		self.Humanoid:SetAttribute("PlayerName", self.LuaPlayer.PlayerName)
		
		if self.OriginalDisplayName then
			self.Humanoid.DisplayName = self.OriginalDisplayName
			self.OriginalDisplayName = nil
		end

		self.LuaPlayer.Player:SetAttribute("UseNameAttributeForTextColor", nil)
		self:SetOutfit(self.LuaPlayer.UserId, true)
	end
end

----------------------------------------------------------------------------------

function LuaCharacter.new(LuaPlayer)
	local self = setmetatable({}, LuaCharacter)

	self.LuaPlayer = LuaPlayer

	self.Job = Job.new()
	self.HumanoidJob = Job.new()
	self.DeathJob = Job.new()

	self.HumanoidAlive = false
	self.HumanoidExists = false
	self.AppearanceLoaded = false

	self.RespawningEnabled = true
	--self.RespawningStopped = false

	self.OnHumanoidAvailabilityChanged = self.Job:Task(EventService.new())
	self.OnHumanoidDied = self.Job:Task(EventService.new())

	self.OnAppearanceLoaded = self.Job:Task(EventService.new())

	self.OnRespawnTimerStopped = self.Job:Task(EventService.new())
	self.OnRespawnTimerCompleted = self.Job:Task(EventService.new())

	self.AnchorStack = self.Job:Task(NumberStack.new())

	self.DefaultRegenRate = 0.5/100 -- Regenerate this amount of MaxHealth per regen step.
	self.DefaultRegenStep = 1.5 -- Wait this long between each regeneration step.

	self.RegenRate = self.DefaultRegenRate 
	self.RegenStep = self.DefaultRegenStep

	self.DisguiseId = nil

	----------------------------------------

	self:_Init()

	return self
end

function LuaCharacter:RegisterModel(Model : Model)
	self.HumanoidJob:Clean()
	
	if self.Model then
		self.Model:Destroy()
	end

	self.Model = Model
	self.Model.Parent = workspace.chars :: Model
	--self.Model:AddTag("Men")

	self.Humanoid = self.Model:WaitForChild("Humanoid") :: Humanoid?
	self.Humanoid:SetAttribute("PlayerName", self.LuaPlayer.PlayerName)
	self.Humanoid:AddTag("ManHumanoid")

	self.Torso = self.Model:WaitForChild("Torso") :: BasePart?
	self.Head = self.Model:WaitForChild("Head") :: BasePart?
	self.RightArm = self.Model:WaitForChild("Right Arm") :: BasePart?
	self.RightLeg = self.Model:WaitForChild("Right Leg") :: BasePart?
	self.LeftArm = self.Model:WaitForChild("Left Arm") :: BasePart?
	self.LeftLeg = self.Model:WaitForChild("Left Leg") :: BasePart?
	self.Animator = self.Humanoid:WaitForChild("Animator") :: Animator?
	self.RootPart = self.Humanoid.RootPart or self.Model:WaitForChild("HumanoidRootPart")
	self.RootJoint = self.RootPart:WaitForChild("RootJoint") :: Motor6D
	self.RootAttachment = self.RootPart:WaitForChild("RootAttachment") :: Attachment
	self.Mouth = self.Head:WaitForChild("MouthAttachment") :: Attachment
	
	self.AnchorStack:Reset()

	do
		self.RootJoint.MaxVelocity = 2

		for _, Joint in ipairs(self.Torso:GetDescendants()) do
			if Joint:IsA("Motor6D") then
				Joint.MaxVelocity = 2
			end
		end
	end

	self.RootPart.RootPriority = 127
	self.Model.PrimaryPart = self.RootPart

	if self.LuaPlayer.IsNPC then
		self:SetOwnership(nil)
	end

	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

	task.defer(function() -- had to defer it or else ancestry changed runs after i spawn since its deferred
		self:SetHumanoidAvailability(true, true)

		local Connection : RBXScriptConnection; Connection = self.DeathJob:Task(self.RootPart.AncestryChanged:Connect(function(_, Parent)
			if (Parent == nil) then
				Connection:Disconnect()

				if self.LuaPlayer:PlayerExists() then
					self:SetHumanoidAvailability(false, false)

					if not self.LuaPlayer.IsNPC then
						network.humanoidDied.sendTo(nil, self.LuaPlayer.Player)
					end

					self.DeathJob:Clean()

					if not self.LuaPlayer.IsNPC and self.LuaPlayer:PlayerExists() then
						self.LuaPlayer.Player:LoadCharacter()
					end
				end
			end
		end))
	end)

	self.HumanoidJob:Task(self.Humanoid.HealthChanged:Connect(function(NewHealth)
		if (NewHealth <= 0.01) then
			self:Die()
		end
	end))

	self.HumanoidJob:Task(self.OnHumanoidAvailabilityChanged:Once(function()
		self:SetCollisionGroup("Player")
		self:StartRegen()
	end))

	if self.LuaPlayer.IsNPC then
		self.Humanoid.AutoRotate = (self.Humanoid:FindFirstChild("StopAutoRotate") == nil)

		local function ChildChanged()
			self.Humanoid.AutoRotate = (self.Humanoid:FindFirstChild("StopAutoRotate") == nil)
		end

		self.Humanoid.ChildRemoved:Connect(ChildChanged)
		self.Humanoid.ChildAdded:Connect(ChildChanged)
	end

	if not self.LuaPlayer.IsNPC and self.LuaPlayer.Data.Profile.Data.CurrentTitle ~= "" then
		self.Title:Equip(self.LuaPlayer.Data.Profile.Data.CurrentTitle)
	end
end

--- The client asked to reset. Refused mid-fight, as the remote handler was.
function LuaCharacter:TryReset()
	if self.Combat.InCombat then return end

	self:Die()
end

function LuaCharacter:UnregisterModel()
	if self.Model then
		self.Model:RemoveTag("Men")
	end

	if self.Humanoid then
		self.Humanoid:RemoveTag("ManHumanoid")
	end
	
	self.Model:Destroy()
end

function LuaCharacter:Die()
	if not self.LuaPlayer:PlayerExists() then return end

	if self.HumanoidAlive then
		self:SetHumanoidAvailability(false, true)
		self.DeathJob:Clean()

		if not self.LuaPlayer.IsNPC then
			network.humanoidDied.sendTo(nil, self.LuaPlayer.Player)
		end

		self.Humanoid.Health = 0
		self.OnHumanoidDied:Fire()

		self:StartRespawnTimer()
	else
		if self.HumanoidExists and not self.Combat:GetState("Ragdolled") then
			self.Combat.Ragdoll:Toggle(true)
		end
	end
end

function LuaCharacter:Respawn()
	if not self.LuaPlayer:PlayerExists() then return end

	--if self.RespawningEnabled and not self.RespawningStopped then
	if self.RespawningEnabled then
		self.OnRespawnTimerCompleted:Fire()

		self.DeathJob:Clean()
		self:SetHumanoidAvailability(false, false)

		if not self.LuaPlayer.IsNPC and self.LuaPlayer:PlayerExists() then
			self.LuaPlayer.Player:LoadCharacter()
		end
	end
end


function LuaCharacter:Anchor(Value : boolean, DontFlipIfNearWall : boolean?, FlipSettings : {any}?)
	if not self.HumanoidExists then return end

	if Value then
		
		if self.AnchorStack:IsFalse() then
			self.RootPart.Anchored = true

			if Value and not DontFlipIfNearWall then
				self:FlipIfNearWall(FlipSettings)
			end
		end
		
		self.AnchorStack:Add()

	elseif not Value then
		self.AnchorStack:Subtract()
		
		if self.AnchorStack:IsFalse() then
			self.RootPart.Anchored = false
		end
	end
end


function LuaCharacter:FlipIfNearWall(Settings : {any}?)
	if not self.HumanoidExists then return end

	Settings = Settings or {}

	local Direction : Vector3 = Settings.Direction or Vector3.zero
	local FlipRaycastLength : number = Settings.FlipRaycastLength or 30

	local SimulatedRoot : BasePart = self.Combat:GetSimulatedRoot()
	local CF = nil

	if Direction == Vector3.zero then
		CF = SimulatedRoot.CFrame
	else
		CF = CFrame.lookAlong(SimulatedRoot.Position, Direction)
	end

	if not Settings.DontDoStandRaycast then
		self:StandUpright(30)

		--local StandRaycast = workspace:Raycast(SimulatedRoot.Position + (Vector3.yAxis * 5), Vector3.yAxis * -30, Utility.VisualParams)

		--if (not Settings.DontDoStandRaycast and StandRaycast ~= nil) then
		--	self.RootPart.CFrame = CFrame.new(CF.X, StandRaycast.Position.Y + 3, CF.Z) * CF.Rotation
		--end
	end

	local Raycast = workspace:Raycast(SimulatedRoot.Position, CF.LookVector * (FlipRaycastLength or 30), Utility.VisualParams)

	if Raycast and Raycast.Instance.CanCollide then
		self.RootPart.CFrame *= CFrame.Angles(0, math.pi, 0)
	end
end

-- it has to use the rig cause roblox makes accessories pixelated on r6 rigs and this puts it on a r15 rig to fix
function LuaCharacter:AccessoryFix(Description) 
	local AccessoryRig = ServerStorage.AccessoryRig:Clone()
	AccessoryRig.Parent = ServerStorage.AccessoryRigFolder

	local RigHumanoid = AccessoryRig:FindFirstChildOfClass("Humanoid")

	if RigHumanoid then
		RigHumanoid:ApplyDescription(Description)

		for _, Child in self.Model:GetChildren() do
			if Child:IsA("Accessory") then
				Child:Destroy()
			end
		end

		for _, Accessory in AccessoryRig:GetChildren() do
			if Accessory:IsA("Accessory") then
				local Handle : BasePart? = Accessory:FindFirstChild("Handle")

				if Handle then
					Handle.Massless = true
					Handle.CanCollide = false
					Handle.CanQuery = false
					Handle.CanTouch = false
				end

				Accessory.Parent = self.Model
			end
		end
	end

	AccessoryRig:Destroy()
end

function LuaCharacter:StopRespawnTimer()
	if (self.RespawnTimer == nil) then return end

	--self.RespawningStopped = true

	if coroutine.status(self.RespawnTimer) == "suspended" then
		task.cancel(self.RespawnTimer)
	end

	self.OnRespawnTimerStopped:Fire()
end

function LuaCharacter:RestartRespawnTimer()
	if (self.RespawnTimer == nil) then return end

	self:StopRespawnTimer()
	self:StartRespawnTimer()
end

function LuaCharacter:StartRespawnTimer()
	if not self.HumanoidExists then return end
	if self.HumanoidAlive then return end -- Should prolly keep this, i saw alot of prints with this!!!!!

	if not self.RespawningEnabled then 
		return 
	end

	--self.RespawningStopped = false

	self.RespawnTimer = task.delay(4, function() 
		self.RespawnTimer = nil
		self:Respawn()
	end)
end

function LuaCharacter:ForceStartRespawnTimer()
	if not self.RespawningEnabled then 
		return 
	end

	--self.RespawningStopped = false

	self.RespawnTimer = task.delay(4, function() 
		self.RespawnTimer = nil
		self:Respawn()
	end)
end

function LuaCharacter:StopAutoRotate()
	if not self.HumanoidExists then 
		return {
			Destroy = function() end -- = no errors
		}
	end

	return Utility.StopAutoRotate(self.Humanoid)
end

function LuaCharacter:HideTitle(Value : bolean)
	if not self.LuaPlayer.IsNPC and self.LuaPlayer:PlayerExists() then
		local TitleUI = self.Head:FindFirstChild("Title")

		if TitleUI then
			TitleUI.Enabled = not Value
		end
	end
end

function LuaCharacter:SetHumanoidAvailability(Alive : boolean, Exists : boolean)
	local Available = (Alive and Exists)

	self.HumanoidAlive = Available 
	self.HumanoidExists = Exists 

	self.OnHumanoidAvailabilityChanged:Fire(Available, Exists)
end

function LuaCharacter:StopRegen()
	if self.RegenThread and coroutine.status(self.RegenThread) == "suspended" then 
		task.cancel(self.RegenThread) 
	end
end

function LuaCharacter:StartRegen()
	if self.LuaPlayer.IsNPC then return end

	self:StopRegen()

	self.RegenThread = coroutine.create(function()
		self:_Regen()
	end)

	coroutine.resume(self.RegenThread)
end

function LuaCharacter:ResetRegenSettingsToDefault()
	self.RegenRate = self.DefaultRegenRate 
	self:SetRegenStep(self.DefaultRegenStep)
end

function LuaCharacter:SetRegenStep(Value: number)
	if Value ~= self.RegenStep then
		self.RegenStep = Value
		self:StartRegen()
	end
end

function LuaCharacter:HealFull()
	if not self.HumanoidExists then return end

	self.Humanoid.Health = self.Humanoid.MaxHealth
	table.clear(self.Combat.TotalBeenDamaged)

	self.LuaPlayer.Replication:FireReliableVFXToSelf("Global/Regeneration", "OnRegenStep")
end


function LuaCharacter:SetHealthAndHeal(Value : number)
	if not self.HumanoidExists then return end

	self.Humanoid.MaxHealth = Value
	self:HealFull()
end

function LuaCharacter:Heal(Value : number)
	if not self.HumanoidExists then return end

	self.Humanoid.Health = math.min(self.Humanoid.Health + Value, self.Humanoid.MaxHealth)

	for Attacker in self.Combat.TotalBeenDamaged do
		local CurrentValue = self.Combat.TotalBeenDamaged[Attacker] 

		if (CurrentValue > 0) then
			self.Combat.TotalBeenDamaged[Attacker] = math.max(0, 
				(CurrentValue - Value)
			)
		else
			self.Combat.TotalBeenDamaged[Attacker] = nil
		end
	end

	if self.RegenRate >= 0.1 then
		self.LuaPlayer.Replication:FireVFXToSelf("Global/Regeneration", "OnRegenStep")
	end
end

function LuaCharacter:_Regen()
	while self.HumanoidAlive do
		while (self.Humanoid.Health < self.Humanoid.MaxHealth) do
			local Time = task.wait(self.RegenStep)

			if not self.Combat:GetState("Grabbing") and not self.Combat:GetState("Stunned") and not self.Combat:GetState("Ragdolled") then 
				self:Heal(
					(Time * self.RegenRate * self.Humanoid.MaxHealth)
				)
			end
		end

		self.Humanoid.HealthChanged:Wait()
	end
end

function LuaCharacter:SetCollisionGroup(Group : string)
	if not self.HumanoidExists then return end

	self.CurrentCollisionGroup = Group

	for _, Item in ipairs(self.Model:GetChildren()) do
		if Item:IsA("BasePart") then
			Item.CollisionGroup = Group
		end
	end
end

function LuaCharacter:StandUpright(DownwardY : number?)
	if not self.LuaPlayer:PlayerExists() then return end

	if not self.LuaPlayer.IsNPC then
		network.standUpright.sendTo(DownwardY, self.LuaPlayer.Player)
	else
		self:StandUprightServer(DownwardY)
	end
end

function LuaCharacter:StandUprightServer(DownwardY : number?)
	if not self.HumanoidExists then return end

	DownwardY = -(DownwardY or 3)

	local Raycast = workspace:Raycast(self.RootPart.Position, Vector3.yAxis * DownwardY, Utility.VisualParams)
	Raycast = Raycast or {Position = self.RootPart.Position}

	self.Model:PivotTo(
		Utility.VectorToRotation(self.RootPart.CFrame.RightVector:Cross(-Vector3.yAxis)) + 
			(self.RootPart.Position * Vector3.new(1, 0, 1)) + 
			(Vector3.yAxis * (3 + Raycast.Position.Y))
	)
end

function LuaCharacter:SetCameraOcclude(Value : boolean)
	if not self.HumanoidExists then return end

	if Value then
		for _, Item : BasePart? in ipairs(self.Model:GetChildren()) do
			if Item:IsA("BasePart") then
				Item:AddTag("NoCameraOcclusion")
			end
		end
	else
		for _, Item : BasePart? in ipairs(self.Model:GetChildren()) do
			if Item:IsA("BasePart") then
				Item:RemoveTag("NoCameraOcclusion")
			end
		end
	end
end

function LuaCharacter:SetOwnership(Owner : (Player | nil))
	for _, Item in ipairs(self.Model:GetDescendants()) do
		if Item:IsA("BasePart") and Item:CanSetNetworkOwnership() then
			Item:SetNetworkOwner(Owner)
		end
	end
end

function LuaCharacter:LoadAnimation(Animation : Animation)
	local Track = nil

	if self.HumanoidExists then
		Track = self.Animator:LoadAnimation(Animation)
	end

	return Track
end

function LuaCharacter:FixCenter()
	if not self.LuaPlayer:PlayerExists() then return end

	if not self.LuaPlayer.IsNPC then
		network.fixCenter.sendTo(nil, self.LuaPlayer.Player)
	else
		--self:FixCenterServer()
	end
end

----------------------------------------------------------------------------------

table.freeze(LuaCharacter)

return LuaCharacter