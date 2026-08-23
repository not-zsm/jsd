local replicatedStorage = game:GetService("ReplicatedStorage")
local contextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Remotes = replicatedStorage.Remotes
local CombatRemotes = Remotes.Combat

local Shared = replicatedStorage.modules.shared
local SharedUtilities = Shared.Utilities

local Animations = replicatedStorage.Animations
local ass = replicatedStorage.ass

local ClientHandlers = script.ClientHandlers

local Combat = {}
Combat.__index = Combat

local OnCreatedMoves = require( script.OnCreatedMoves )

local EventService = require( replicatedStorage.modules.shared.Utilities.EventService )
local Utility = require( replicatedStorage.modules.shared.Utilities.Utility )
local Job = require( replicatedStorage.modules.shared.Utilities.Job )
local NumberStack = require( replicatedStorage.modules.shared.Utilities.NumberStack )
local network = require( replicatedStorage.modules.network )
local InfoCharacter = require( replicatedStorage.modules.client.character.InfoCharacter )

local Velocity = require( replicatedStorage.modules.shared.Game.Velocity )

function Combat:_Init()
	task.spawn(require, script.Quicktime);

	self.LockOn = require(script.LockOn).new(self)
	self.UI = Combat.UIFactory(self)

	self.FakeMouse = require(script.Mouse).new(self)

	for _, Action in ipairs(ClientHandlers:GetChildren()) do
		self.ClientHandlers[Action.Name] = require(Action).new(self)
	end

	self:InitializeHumanoidAvailability();
	self:Connect();

	self.UI:Init();
end

function Combat:Connect()
	local EquippedMove = nil

	local function ConsoleJumpHold(_, input_state, input)
		if (input_state == Enum.UserInputState.Begin) then
			self:StartHoldingJump(false);

		elseif (input_state == Enum.UserInputState.End) then
			self:StartNotHoldingJump();
		end

		return Enum.ContextActionResult.Pass;
	end

	contextActionService:BindActionAtPriority("ConsoleJumpCapture", ConsoleJumpHold, false, 2500, Enum.KeyCode.ButtonA);

	UserInputService.InputBegan:Connect(function(Input, Typing)
		if self:IsDisabled() then return end

		if Input.KeyCode == Enum.KeyCode.Space then
			self:StartHoldingJump(Typing)
		end

		if not Typing then
			local Key = Utility.TranslateInput(Input)

			if self.UsingController then
				Key = Utility.ControllerToKeyboardInputs[Key] or Key
			end

			if self.LuaPlayer.Player:GetAttribute("Auto_Use") then
				for Name, Table in self.Attacks do
					if Table.Key == Key then
						self:_AttackInputUpdate(Name, true, Key)
					end
				end
			else
				if Key == Enum.UserInputType.MouseButton1 and EquippedMove then
					self:_AttackInputUpdate(EquippedMove.Name)
				end

				local function Equip(Name, Key)
					EquippedMove = {
						Name = Name,
						Key = Key
					}

					self.UI:OverlayOnHotbar(EquippedMove.Name, true)
				end

				for Name, Table in self.Attacks do
					if Table.Key ~= Key then
						continue
					end

					if self.UI.Hotbar:Get(Name) then -- if its a 1 2 3 4 move 
						if EquippedMove then
							self.UI:OverlayOnHotbar(EquippedMove.Name, false)

							if EquippedMove.Key == Key then
								EquippedMove = nil
							else
								Equip(Name, Table.Key)
							end
						else
							Equip(Name, Table.Key)
						end
					else
						self:_AttackInputUpdate(Name, true, Key)
					end
				end
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(Input)
		if Input.KeyCode == Enum.KeyCode.Space then
			self:StartNotHoldingJump()
		end

		local Key = Utility.TranslateInput(Input)

		if self.UsingController then
			Key = Utility.ControllerToKeyboardInputs[Key] or Key
		end

		if self.LuaPlayer.Player:GetAttribute("Auto_Use") then
			for Name, Table in self.Attacks do
				if Table.Key == Key then
					self:_AttackInputUpdate(Name, false, Key)
				end
			end
		else
			for Name, Table in self.Attacks do
				if Table.Key == Key and not self.UI.Hotbar:Get(Name) then
					self:_AttackInputUpdate(Name, false, Key)
				end
			end
		end
	end)

	network.updateJump.listen(function(Value : boolean)
		if not self.LuaCharacter.HumanoidAlive then return end

		self.LuaCharacter.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, not Value)
	end)

	network.ragdoll.listen(function(Value : boolean)
		self:ToggleRagdollStates(Value)
	end)

	network.updatePivot.listen(function(player)
		local ClientReplicator = require( replicatedStorage.modules.shared.movementReplicator.ClientReplicator )
		local replicant = ClientReplicator.other_replicators[player];

		if replicant and replicant.character then
			replicant.character:PivotTo( replicant.target_cframe );
		end;
	end);

	network.createAttack.listen(function(data)
		local Name, DirectoryName, Properties = data.move, data.directory, data.properties
		local Key = Enum.KeyCode[data.key] or Enum.UserInputType[data.key]
		if (self.Attacks[Name] ~= nil) then 
			local Slot = self.UI.Hotbar:Get(Name)

			if Slot then
				Slot.RemoveCooldown:Fire()
			end

			return 
		end

		--local SavedKeybind = nil

		--if not DontUseSavedKeybind then
		--	SavedKeybind = self:GetKeybindForMove(Name)
		--end

		--Key = SavedKeybind or Key

		self.Attacks[Name] = {
			Name = Name,
			Key = Key,
			DirectoryName = DirectoryName,
			Properties = Properties or {},
			--KeySwitched = (SavedKeybind ~= nil)
		}

		self.OnAttackChanged:Fire(self.Attacks[Name], true);

		if OnCreatedMoves[Name] and OnCreatedMoves[Name].Created then
			local NewJob = Job.new()
			self.CreatedMoveJobs[Name] = NewJob
			task.spawn(OnCreatedMoves[Name].Created, self, NewJob)
		end
	end)

	network.removeAttack.listen(function(Name : string)
		if (self.Attacks[Name] == nil) then return end

		local Attack = self.Attacks[Name];

		self.Attacks[Name] = nil
		self.OnAttackChanged:Fire(Attack, false);

		if OnCreatedMoves[Name] and OnCreatedMoves[Name].Removed then
			task.spawn(OnCreatedMoves[Name].Removed, self)
		end

		if self.CreatedMoveJobs[Name] then
			self.CreatedMoveJobs[Name]:Destroy()
			self.CreatedMoveJobs[Name] = nil
		end
	end)

	network.changeAttackKey.listen(function(data)
		local Name, NewKey = data.move, Enum.KeyCode[data.key] or Enum.UserInputType[data.key]
		self:ChangeAttackKey(Name, NewKey)
	end)

	network.resetJumpFatigue.listen(function()
		self:ResetJumpFatigue()
	end)

	network.velocitySettings.listen(function(Settings : {})
		local NewObject = self:Velocity()
		NewObject.Settings = Settings
		NewObject:Fire()
	end)

	network.setCharacter.listen(function(Name : string)
		self:SetAsCurrentCharacter(Name);
	end)

	network.destructibleLoop.listen(function(data)
		self:DestructibleDestroyLoop(data.offset, data.size)
	end)

	network.standUpright.listen(function(DownwardY : number?)
		self:StandUpright(DownwardY)
	end)

	network.fixCenter.listen(function()
		self.LuaCharacter:FixCenter()
	end)

	network.moveCooldown.listen(function(data)
		self:AddCooldown(data.move, data.duration)
	end)

	self.ResetStack = NumberStack.new()

	local ResetEvent = Instance.new("BindableEvent")

	ResetEvent.Event:Connect(function(...)
		if self.ResetStack:IsFalse() then
			network.tryReset.send()
		end
	end)

	local function Stack(Value : boolean)
		if Value == true then
			self.ResetStack:Add()

		elseif Value == false then
			self.ResetStack:Subtract()
		end
	end

	task.spawn(function()
		local ResetButtonSuccess = pcall(function()
			StarterGui:SetCore("ResetButtonCallback", ResetEvent)
		end)

		if not ResetButtonSuccess then
			while true do
				ResetButtonSuccess = pcall(function()
					StarterGui:SetCore("ResetButtonCallback", ResetEvent)
				end)

				if ResetButtonSuccess then
					break
				end

				task.wait()
			end
		end
	end)

	self:GetStateChanged("Attacking"):Connect(function()
		Stack(self:GetState("Attacking"))
		--self.LuaCharacter:FixCenter()
	end)

	self:GetStateChanged("Stunned"):Connect(function()
		Stack(self:GetState("Stunned"))
		--self.LuaCharacter:FixCenter()
	end)

	self:GetStateChanged("Ragdolled"):Connect(function()
		--self.LuaCharacter:FixCenter()
	end)

	self:GetStateChanged("Dashing"):Connect(function()
		--self.LuaCharacter:FixCenter()
	end)

	self.AttributeValues:GetAttributeChangedSignal("InCombat"):Connect(function()
		Stack(self.AttributeValues:GetAttribute("InCombat"))
	end)

	self.CurrentCharacterChanged:Connect(function(Name : string)
		if (Name == "Anubis" and not self.LuaPlayer.Player:GetAttribute("AnubisInfoNotified")) then
			self.LuaPlayer.Player:SetAttribute("AnubisInfoNotified", true)
			self.UI.Icons.InformationIcon:notify()
		end
	end)
end

function Combat:IsEnabled()
	return self.EnabledStack:IsFalse()
end

function Combat:IsDisabled()
	return self.EnabledStack:IsTrue()
end

function Combat:IsInUltimate()
	return self.LuaPlayer.Replication.Attributes:GetAttribute("Ultimate")
end

function Combat:StartHoldingJump(Typing : boolean)
	self.HoldingJump = true
	self.OnSpaceChanged:Fire(true)

	if not Typing then
		network.spaceHeld.send(true)
	end

	network.airState.send("Up")
end

function Combat:StartNotHoldingJump()
	self.HoldingJump = false
	self.OnSpaceChanged:Fire(false)

	network.spaceHeld.send(false)

	if not self.FreeFalling then
		network.airState.send("")
	end
end

--function Combat:GetKeybindForMove(Name : string, CertainDevice : string?)
--	local Device = CertainDevice or self.CurrentDevice

--	--print("from GetDeviceKeybindForMove:", Device, self.UI.Settings.DeviceKeybinds)

--	if self.UI.Settings.DeviceKeybinds[Device] then
--		return self.UI.Settings.DeviceKeybinds[Device][Name]
--	end
--end

function Combat:ChangeAttackKey(Name : string, NewKey : (Enum.KeyCode | Enum.UserInputType))
	if (self.Attacks[Name] == nil) then return end

	local DirectoryName = self.Attacks[Name].DirectoryName

	self.Attacks[Name] = {
		Name = Name,
		Key = NewKey,
		DirectoryName = DirectoryName,
		--KeySwitched = true
	}

	if DirectoryName ~= "Global" then
		self.UI:AddOnHotbar(Name, NewKey)
	end
end

function Combat:AddCooldown(Name : string, Duration : number?)
	self:RemoveCooldown(Name)

	if self.LuaPlayer.Replication.Attributes:GetAttribute("DisabledClientCooldowns") then 
		return
	end

	Duration = Duration or self.PresetCooldowns[Name] or nil

	if (Duration == nil) then
		return warn("no cooldown duration specified for", Name)
	end

	local Data = {}

	if not self.UI.Hotbar:Get(Name) then
		Data.Cancel = self.UI.Hotbar:AddExtraCooldown(Name, Duration)
	end

	Data.Thread = task.delay(Duration, self.RemoveCooldown, self, Name)
	self.Cooldowns[Name] = Data
end


function Combat:RemoveCooldown(Name : string)
	if not self.Cooldowns[Name] then return end

	if (coroutine.status(self.Cooldowns[Name].Thread) == "suspended") then
		task.cancel(self.Cooldowns[Name].Thread)
	end

	if self.Cooldowns[Name].Cancel then
		self.Cooldowns[Name].Cancel()
	end

	self.Cooldowns[Name] = nil
end


function Combat:CooldownExists(Name : string)
	return (self.Cooldowns[Name] ~= nil)
end

function Combat:CreateBodyVelocity(Name : string)
	if not self.LuaCharacter.HumanoidExists then 
		return 
	end

	if Name == "M1PullIn" and self.LuaCharacter.RootPart:FindFirstChild("Dash") then -- m1 pull in wont cancel dash velocity
		return
	end

	if (Name == "FrontDash" and self.LuaCharacter.RootPart:FindFirstChild("M1PullIn")) then -- front dash wont cancel m1 pull in, making the 3 m1 q work
		return
	end

	return Velocity.Utility.Create(self.LuaCharacter.RootPart, Name)
end

function Combat:Velocity() -- CLIENT SIDE
	return Velocity.new(self)
end

function Combat:DestructibleDestroyLoop(Offset: CFrame, Size: (Vector3 | number))
	local Power = self.LuaPlayer.Replication.Attributes:GetAttribute("DestructibleDestroyLoopPower") or 1

	local AttributeConnection: RBXScriptConnection = nil
	local Connection: RBXScriptConnection = nil

	local List = {}

	local DoSphere = (typeof(Size) == "number")

	local function RecogniseDestructible(Object: BasePart): (Instance)
		local Model = Object:FindFirstAncestorOfClass("Model")

		if Model and Model:HasTag("DestructibleModel") then
			return Model
		end

		return Object
	end

	Connection = RunService.PostSimulation:Connect(function()
		local ProcessedObjects = {}

		local Center = self.LuaCharacter.RootPart.CFrame * Offset
		local Bounds

		if DoSphere then
			Bounds = workspace:GetPartBoundsInRadius(Center.Position, Size, Utility.DestructiblesParams)
		else
			Bounds = workspace:GetPartBoundsInBox(Center, Size, Utility.DestructiblesParams)
		end

		for _, Part in pairs(Bounds) do
			local DestructibleEntity = RecogniseDestructible(Part)

			if ProcessedObjects[DestructibleEntity] then continue end
			ProcessedObjects[DestructibleEntity] = true

			if DestructibleEntity:GetAttribute("Destructed") then continue end

			if Power >= (DestructibleEntity:GetAttribute("DestructibleStrength") or 0) then
				DestructibleEntity:SetAttribute("Destructed", true)

				self.LuaPlayer.Replication:Destruct(DestructibleEntity)

				task.delay(Utility.DestructionRespawnTime, function()
					pcall(function()
						DestructibleEntity:SetAttribute("Destructed", false)
					end)
				end)

				network.clientDestruction.send(DestructibleEntity)
			end
		end
	end)

	if not self.LuaPlayer.Replication.Attributes:GetAttribute("DestructibleDestroyLoop") then
		Connection:Disconnect()
	end

	AttributeConnection = self.LuaPlayer.Replication.Attributes:GetAttributeChangedSignal("DestructibleDestroyLoop"):Connect(function()
		if not self.LuaPlayer.Replication.Attributes:GetAttribute("DestructibleDestroyLoop") then
			AttributeConnection:Disconnect()
			Connection:Disconnect()
		end
	end)
end

function Combat:MatchAttack(Name : string, Key : (Enum.KeyCode | Enum.UserInputType))
	local Attack = self.Attacks[Name]

	if (Attack ~= nil and Attack.Key == Key) then
		return Attack, true
	end

	return nil, false
end


function Combat:ToggleRagdollStates(Value : boolean)
	if not self.LuaCharacter.HumanoidExists then return end

	if Value then
		self.LuaCharacter.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	else
		self.LuaCharacter.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

function Combat:ResetJumpFatigue()
	self.LuaCharacter.Humanoid.JumpPower = 50
	self.JumpFatigueResetTimer = -1
	self.JumpFatigue = 0
end

function Combat:InitializeHumanoidAvailability()
	local function OnAvailabilityEvent(Alive, Exists)

		if Alive then

			if not self.ConnectedToSpeed then
				self.ConnectedToSpeed = true

				network.scaleSpeed.listen(function(data)
		if not data.divide then return end
		local Humanoid, Amount = data.humanoid, data.amount
					if not Humanoid or self.LuaCharacter.Humanoid ~= Humanoid then return end;

					self.LuaCharacter.Humanoid.WalkSpeed /= Amount
				end);

				network.scaleSpeed.listen(function(data)
		if data.divide then return end
		local Humanoid, Amount = data.humanoid, data.amount
					if not Humanoid or self.LuaCharacter.Humanoid ~= Humanoid then return end;

					self.LuaCharacter.Humanoid.WalkSpeed *= Amount
				end);

				-- gulp....
				network.setSpeed.listen(function(data)
		local Humanoid, Value = data.humanoid, data.value
					if not Humanoid or self.LuaCharacter.Humanoid ~= Humanoid then return end;

					self.LuaCharacter.Humanoid.WalkSpeed = Value
				end);
			end;

			self.FixCenterLoop = task.spawn(function()
				while self.LuaCharacter.HumanoidAlive do
					self.LuaCharacter:FixCenter()
					task.wait(0.5)
				end
			end)

			task.spawn(function()
				--if not self.ConnectedToSetCurrentCharacter then
				--	self.ConnectedToSetCurrentCharacter = true

				--	network.setCharacter.listen(function(Name : string)
				--		print("SetCurrentCharacter OnClientEvent")
				--		self:SetAsCurrentCharacter(Name);
				--	end)
				--end

				--local CurrentCharacter = self.LuaPlayer.Replication.Attributes:GetAttribute("CurrentCharacter")

				--if not CurrentCharacter then
				--	self.LuaPlayer.Replication.Attributes:GetAttributeChangedSignal("CurrentCharacter"):Wait()
				--	CurrentCharacter = self.LuaPlayer.Replication.Attributes:GetAttribute("CurrentCharacter")
				--end;

				--print("SetCurrentCharacter")
				--self:SetAsCurrentCharacter(CurrentCharacter);

				--task.delay(5, function()
				--	if self.CurrentCharacter == "Anubis" and not self.LuaPlayer.Player:GetAttribute("AnubisInfoNotified") then
				--		self.LuaPlayer.Player:SetAttribute("AnubisInfoNotified", true)
				--		self.UI.Icons.InformationIcon:notify()
				--	end
				--end)
			end)

			if self.ResetStack then
				self.ResetStack:Reset()
			end

			for _, self in self.ClientHandlers do
				self:OnHumanoidLoaded()
			end

			network.airState.send("")
			network.spaceHeld.send(false)

			self.LuaCharacter.Humanoid.Jumping:Connect(function(Active : boolean)
				if Active then
					if self.CurrentCharacter == "Hornet" then return end

					if (time() - self.JumpFatigueResetTimer > 1.25) then
						self:ResetJumpFatigue()
					end

					self.JumpFatigueResetTimer = time()
					self.JumpFatigue += 1.5

					self.LuaCharacter.Humanoid.JumpPower = math.max(self.LuaCharacter.Humanoid.JumpPower - self.JumpFatigue, 27)

					network.clientJumped.send()
				end
			end)

			local MinHealthThreshold = 35 -- The HP threshold below which speed scaling starts
			local SpeedMultiplierAtZeroHP = 0.75 -- The multiplier when the player has 0 HP

			local LastSpeedMultiplier = 1

			self.LuaCharacter.Humanoid.HealthChanged:Connect(function(NewHealth : number)
				local Percent = math.clamp(NewHealth / MinHealthThreshold, 0, 1)
				local SpeedMultiplier = SpeedMultiplierAtZeroHP + (1 - SpeedMultiplierAtZeroHP) * (Percent ^ 3)

				self.LuaCharacter.Humanoid.WalkSpeed *= SpeedMultiplier
				self.LuaCharacter.Humanoid.WalkSpeed /= LastSpeedMultiplier

				LastSpeedMultiplier = SpeedMultiplier
			end)

			self.LuaCharacter.Humanoid.StateChanged:Connect(function(OldState, NewState)
				if NewState == Enum.HumanoidStateType.FallingDown then
					self.LuaCharacter.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				end

				if NewState == Enum.HumanoidStateType.Freefall then
					self.FreeFalling = true
					self.OnFreeFalling:Fire()

					network.airState.send("Down")

				elseif (NewState == Enum.HumanoidStateType.Landed or NewState == Enum.HumanoidStateType.Physics) then
					self.FreeFalling = false
					self.OnLanded:Fire()

					network.clientLanded.send()

					if not self.HoldingJump then
						network.airState.send("")
					else
						network.airState.send("Up")
					end
				end
			end)

			--self.CurrentCharacter = self.LuaPlayer.Replication.Attributes:GetAttribute("CurrentCharacter")
		else
			--if not Exists then
			--	self:SetAsCurrentCharacter(nil);
			--end

			if self.FixCenterLoop then
				Utility.CloseThreadSafe(self.FixCenterLoop)
				self.FixCenterLoop = nil
			end
		end
	end

	if self.LuaCharacter.HumanoidAlive then
		OnAvailabilityEvent(true)
	end

	self.LuaCharacter.OnHumanoidAvailabilityChanged:Connect(OnAvailabilityEvent)
end

function Combat:SetAsCurrentCharacter(Character: string)
	if (self.CurrentCharacter == Character) then
		return;
	end;

	self.CurrentCharacter = Character;
	self.CurrentCharacterInfo = nil;

	if Character then
		InfoCharacter.OnCharacterReady(Character, function(Info)
			self.CurrentCharacterInfo = Info;
		end)
	end;

	self.CurrentCharacterChanged:Fire(Character)
end;

function Combat:GetCurrentCharacter()
	return self.CurrentCharacter
end

function Combat:_AttackInputUpdate(Name : string, State : boolean, Key : (Enum.KeyCode | Enum.UserInputType))
	if (self.ClientHandlers[Name] == nil) then
		if (Key ~= Enum.UserInputType.MouseButton1 and Key ~= Enum.UserInputType.MouseButton2) then
			CombatRemotes.FakeMouse.UpdatePosition:FireServer(self.FakeMouse:Check())
		end

		if self.HoldingJump or self.FreeFalling then
			network.useMove.send({ move = Name, state = State, extra = {
				HoldingJump = self.HoldingJump, 
				FreeFalling = self.FreeFalling
			} })
		else
			network.useMove.send({ move = Name, state = State })
		end
	else
		if (Name == "Dash") then
			self.ClientHandlers.Dash.KeyHeldDown = State

			if State then
				self.ClientHandlers.Dash:OnInput()
			end
		end
	end
end

function Combat:GetState(Name : string)
	return self.AttributeStates:GetAttribute(Name)
end

function Combat:GetStateChanged(Name : string)
	return self.AttributeStates:GetAttributeChangedSignal(Name)
end

function Combat:StandUpright(DownwardY : number?) -- LOL!!!
	DownwardY = -(DownwardY or 3)

	local Raycast = workspace:Raycast(self.LuaCharacter.RootPart.Position, Vector3.yAxis * DownwardY, Utility.VisualParams)
	Raycast = Raycast or {Position = self.LuaCharacter.RootPart.Position}

	self.LuaCharacter.Model:PivotTo(
		Utility.VectorToRotation(self.LuaCharacter.RootPart.CFrame.RightVector:Cross(-Vector3.yAxis)) + (self.LuaCharacter.RootPart.Position * Vector3.new(1, 0, 1)) + (Vector3.yAxis * (3 + Raycast.Position.Y))
	)
end

----------------------------------------------------------------------------------

function Combat.new(LuaCharacter)
	local self = setmetatable({}, Combat)

	self.LuaCharacter = LuaCharacter
	self.LuaPlayer = self.LuaCharacter.LuaPlayer

	self.ClientHandlers = {}

	self.Attacks = {}
	self.AttackKeys = {}
	self.OnAttackChanged = EventService.new()

	self.CreatedMoveJobs = {}

	self.FreeFalling = false

	self.EnabledStack = NumberStack.new()

	self.OnFreeFalling = EventService.new()
	self.OnLanded = EventService.new()
	self.OnSpaceChanged = EventService.new()
	self.OnDeviceChanged = EventService.new()

	self.JumpFatigueResetTimer = -1
	self.JumpFatigue = 0

	self.Cooldowns = {}

	self.PresetCooldowns = {
		["Side Dash"] = 2,
		["FrontBack Dash"] = 6,
		["Wall Combo"] = 7.5,
		["Evasive"] = 35
	}

	self.StatesHolder = self.LuaPlayer.PlayerGui:WaitForChild("StatesHolder", 100)
	self.AttributeStates = self.StatesHolder:WaitForChild("States")
	self.AttributeValues = self.StatesHolder:WaitForChild("Values")

	self.LastUsingTouch = false
	self.UsingTouch = false

	self.LastUsingController = false
	self.UsingController = false

	self.CurrentCharacterChanged = EventService.new()

	self.CurrentDevice = ""

	return self
end

----------------------------------------------------------------------------------

--table.freeze(Combat)

return Combat