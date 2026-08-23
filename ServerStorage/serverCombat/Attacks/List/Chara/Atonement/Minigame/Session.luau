--== Imports ==--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local network = require( ReplicatedStorage.modules.network )
local RunService        = game:GetService("RunService")

local Packages = ReplicatedStorage.Packages.Des
local Trove    = require(Packages.Trove)


--== Constants ==--
local SURVIVE_SECONDS     = 9.0
local MIN_HEALTH_FLOOR    = 1
local DAMAGE_COOLDOWN_SEC = 0.10
local MAX_DAMAGE_PER_HIT  = 25

--== Module ==--
local Session = {}
Session.__index = Session

--== Lifecycle ==--
function Session.new(player: Player, onFinish: ((Player, string, any) -> ())?)
	local self = setmetatable({
		Player        = player,
		Trove         = Trove.new(),
		Humanoid      = nil :: Humanoid?,

		StartClock     = os.clock(),
		LastDamageTick = 0.0,
		Active         = false,

		OnFinish = onFinish,
	}, Session)

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid  = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if not humanoid then
		self:Destroy()
		return nil
	end
	self.Humanoid = humanoid

	self.Trove:Connect(player.CharacterAdded, function()
		self:Finish("respawn")
	end)
	self.Trove:Connect(humanoid.Died, function()
		self:Finish("death")
	end)

	self.Trove:Connect(RunService.Heartbeat, function()
		if not self.Active then return end
		if (os.clock() - self.StartClock) >= SURVIVE_SECONDS then
			self:Finish("success")
			return
		end
		local h = self.Humanoid and self.Humanoid.Health or 0
		if h > 0 and h < MIN_HEALTH_FLOOR then
			self.Humanoid.Health = MIN_HEALTH_FLOOR
		end
	end)

	self.Active = true
	player:SetAttribute("CharaMinigame", true)
	network.minigame.sendTo({ action = "Start", payload = { duration = SURVIVE_SECONDS } }, player)

	return self
end

--== Public ==--
function Session:ApplyDamage(amount: number?)
	if not (self.Active and self.Humanoid) then return end
	local now = os.clock()
	if now - self.LastDamageTick < DAMAGE_COOLDOWN_SEC then return end
	self.LastDamageTick = now

	local dmg = math.clamp(tonumber(amount or 0) or 0, 0, MAX_DAMAGE_PER_HIT)
	if dmg <= 0 then return end

	local newHealth = math.max(MIN_HEALTH_FLOOR, self.Humanoid.Health - dmg)
	self.Humanoid.Health = newHealth

	if newHealth <= MIN_HEALTH_FLOOR then
		self:Finish("fail")
	end
end

function Session:RequestComplete()
	if not self.Active then return end
	if (os.clock() - self.StartClock) >= SURVIVE_SECONDS then
		self:Finish("success")
	end
end

function Session:Finish(reason: string)
	if not self.Active then return end
	self.Active = false

	local p = self.Player
	if p and p.Parent then
		network.minigame.sendTo({ action = "Stop", payload = { reason = reason } }, p)
		p:SetAttribute("CharaMinigame", false)
	end

	if self.OnFinish then
		pcall(self.OnFinish, p, reason, self)
	end

	self:Destroy()
end

function Session:Destroy()
	self.Trove:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

--== Return ==--
return Session