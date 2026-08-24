local Holstering = {}
Holstering.__index = Holstering

local replicatedStorage = game:GetService("ReplicatedStorage")
local Job = require( replicatedStorage.modules.shared.Utilities.Job )

local StatesThatWait = {"Attacking", "M1ing", "Stunned", "CannotDrawWeapon"}

local function Unanchor_Model(Model : Model)
	for _, Item in ipairs(Model:GetDescendants()) do
		if Item:IsA("BasePart") then
			Item.Anchored = false
		end
	end
end

function Holstering:OnAxe(Value : boolean)
	self:Disconnect()

	if Value then
		self:Appear()
		
		local CanHolster = true
		
		for _, State in ipairs(StatesThatWait) do
			if (self.Combat:GetState(State) == true) then
				CanHolster = false
				continue
			end
		end

		if not CanHolster then
			self:WaitUntilNotAttacking()
		else
			self:StartPutBackThread()
		end
	else
		self:Holster()
	end
end

function Holstering:WaitUntilNotAttacking()
	self.Connections.WaitUntilNotAttacking = self.Job:Task(self.Combat.OnStateChanged:Connect(function(State : any, Value : any)
		if table.find(StatesThatWait, State) and not Value then
			self.Connections.WaitUntilNotAttacking:Disconnect()
			self:StartPutBackThread()
		end
	end))
end

function Holstering:Disconnect()
	self:StopPutBackThread()
	
	if self.Connections.HolsteringThread then
		coroutine.close(self.Connections.HolsteringThread)
		self.Connections.HolsteringThread = nil
	end
	
	self.Weapons.Animations.AxeHolster:Stop()
	
	pcall(function()
		self.Weapons.Axe.Axe.Sheathe:Stop()
	end)
end

function Holstering:Appear()
	--if not self.Holstered then return end
	
	self.Holstered = false
	
	if self.Weapons.CurrentlyUsing == "Axe" and self.Weapons.Axe then
		self.HolsteredAxe.Axe.Transparency = 1
		Unanchor_Model(self.Weapons.Axe)
		self.Weapons.Axe.Parent = self.LuaCharacter.Model
	end
end

function Holstering:Holster()
	--if self.Holstered then return end

	self.Holstered = true
	
	if self.Weapons.CurrentlyUsing == "Axe" and self.Weapons.Axe then
		self.Weapons.Axe.Parent = nil
		
		if not self.Weapons.ThrownAxe then
			self.HolsteredAxe.Axe.Transparency = 0
		end
	end
end

function Holstering:StopPutBackThread()
	if self.Connections.PutBackThread then
		task.cancel(self.Connections.PutBackThread)
		self.Connections.PutBackThread = nil
	end
end

function Holstering:StartPutBackThread()
	self:StopPutBackThread()

	self.Connections.PutBackThread = task.delay(3, function()
		self.Connections.PutBackThread = nil
		self:PutAway()
	end)
end

function Holstering:PutAway()
	self:Disconnect()
	
	if self.Weapons.CurrentlyUsing == "Axe" and self.Weapons.Axe then
		self.Connections.HolsteringThread = coroutine.create(function()
			self.Weapons.Animations.AxeHolster:Play()
			self.Weapons.Axe.Axe.Sheathe:Play()
			
			self.Weapons.Animations.AxeHolster:GetMarkerReachedSignal("holster"):Wait()

			self.Connections.HolsteringThread = nil
			self:Holster()
		end)
	end

	if self.Connections.HolsteringThread then
		coroutine.resume(self.Connections.HolsteringThread)
	end
end

function Holstering.new(Weapons)
	local self = setmetatable({}, Holstering)

	self.Job = Weapons.Job
	self.Weapons = Weapons
	self.Combat = Weapons.Combat
	self.LuaCharacter = Weapons.LuaCharacter
	
	self.Connections = {}
	self.Holstered = false

	local HolsteredAxe = script.Axe:Clone()
	HolsteredAxe.Weld.Part0 = self.LuaCharacter.Torso
	HolsteredAxe.Parent = self.LuaCharacter.Model
	
	for _, Item in ipairs(HolsteredAxe:GetDescendants()) do
		if Item:IsA("BasePart") then
			Item:GetPropertyChangedSignal("Anchored"):Connect(function()
				Item.Anchored = false
			end)
		end
	end
	
	self.HolsteredAxe = HolsteredAxe

	self.Job:Task(self.Combat.OnStateChanged:Connect(function(State : any, Value : any)
		if table.find(StatesThatWait, State) and Value then
			self:Disconnect()
			self:StartPutBackThread()
			
			if self.Holstered then
				self:Appear()
			end
		end
	end))

	self.Job:Task(HolsteredAxe)
	
	return self
end

table.freeze(Holstering)

return Holstering