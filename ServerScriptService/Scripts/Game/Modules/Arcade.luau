--== Imports ==--
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace           = game:GetService("Workspace")

local Packages = ReplicatedStorage.Packages.Des
local Event    = ReplicatedStorage.PlayerRemotes.Arcade.Main
local EndEvent = ReplicatedStorage.PlayerRemotes.Arcade.ForceEnd

local Component = require(Packages.Component)
local Trove     = require(Packages.Trove)

local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )

--== Constants ==--
local CHARACTER_OFFSET = CFrame.new(0, -0.5, -2.75)

--== Module ==--
local Module = Component.new({
	Tag       = "Arcade",
	Ancestors = { Workspace },
})

--== Public ==--
function Module:isBusy(): boolean
	return self.Config:GetAttribute("isBusy")
end

function Module:StartSession(player: Player)
	if self:isBusy() or player:GetAttribute("ArcadeMinigame") then
        return
	end
	
	local LuaPlayer = LuaPlayerList.LuaPlayers[player]
	if not LuaPlayer.Character.Combat:NotStunned() then return end

    local character = player.Character
    local humanoid  = character and character:FindFirstChild("Humanoid") :: Humanoid
    if not humanoid or humanoid.Health <= 0 then
        return
	end
	
	self.Config:SetAttribute("isBusy", true)
	player:SetAttribute("ArcadeMinigame", true)
	player:SetAttribute("CannotCameraShake", true)
	character:SetAttribute("BlockShiftlock", true)
	LuaPlayer.Character.Combat:StackState("Attacking", true)
	LuaPlayer.Character.Combat:HideUI(true)
	LuaPlayer.Character.Combat:ToggleHeadMovement(false)
	
	self.Session:Connect(Event.OnServerEvent, function(_player: Player)
		if _player == player then
			self:StopSession(player)
		end
	end)
	self.Session:Connect(LuaPlayer.Character.Combat.OnStateChanged, function(State, Value)
		if (State ~= "Attacking") then
			self.StopFor(player)
		end
	end)
	-- On Death
	self.Session:Connect(LuaPlayer.Character.OnHumanoidAvailabilityChanged, function(Value : boolean)
		if not Value then
			print("Player Respawned")
			self.StopFor(player)
		end
	end)
	self.Session:Connect(character.AncestryChanged, function() self:StopSession() end)
	
	---- On characterswitched
	--self.Session:Connect(LuaPlayer.Character.Combat.OnCharacterSwitching, function()
	--	self.StopFor(player)
	--end)

	local pivot  = self.Instance:GetPivot()
	local target = pivot:ToWorldSpace(CHARACTER_OFFSET)
	local lookAt = CFrame.lookAt(target.Position, pivot.Position + Vector3.new(0, CHARACTER_OFFSET.Y, 0), Vector3.yAxis)

	character:PivotTo(lookAt)
	humanoid.RootPart.Anchored = true

	self.Player = player
	Event:FireClient(player, self.Instance, "Start")
end

function Module:StopSession()
	if not self:isBusy() then
		return
	end
	
	local LuaPlayer = LuaPlayerList.LuaPlayers[self.Player]

	local character = self.Player.Character
	local humanoid  = character and character:FindFirstChild("Humanoid") :: Humanoid
	if humanoid then
		humanoid.RootPart.Anchored = false
	end

	self.Config:SetAttribute("isBusy", false)
	self.Player:SetAttribute("ArcadeMinigame", false)
	self.Player:SetAttribute("CannotCameraShake", false)
	
	if LuaPlayer then
		LuaPlayer.Character.Model:SetAttribute("BlockShiftlock", nil)
		LuaPlayer.Character.Combat:StackState("Attacking", false)
		LuaPlayer.Character.Combat:HideUI(false)
		LuaPlayer.Character.Combat:ToggleHeadMovement(true)
		LuaPlayer.Character.Humanoid.AutoRotate = true
	end
	
	self.Session:Clean()
	self.Player = nil
end

function Module.StopFor(player: Player)
	for _, session in Module:GetAll() do
		if session.Player ~= player then
			continue
		end

		Event:FireClient(player, session.Instance, "End")
	end
end

--== Lifecycle ==--
function Module:Construct()
	local instance = self.Instance :: Model

	self.Session = Trove.new()
	self.Trove   = Trove.new()

	self.Config = instance:WaitForChild("Config")
	self.Prompt = instance:WaitForChild("Prompt")
end

function Module:Start()
	local config = self.Config :: Configuration
	local prompt = self.Prompt :: ProximityPrompt

	local name = config:GetAttribute("Game")
	prompt.ObjectText = name
	prompt.ActionText = "Play"
	prompt.Enabled    = not self:isBusy()

	self.Trove:Connect(prompt.Triggered, function(player: Player)
		local LuaPlayer = LuaPlayerList.LuaPlayers[player]
		if LuaPlayer.Character.Combat.CurrentDevicePlayingOn == "Controller" then
			ReplicatedStorage.Remotes.Notification:FireClient(player, {
				Title = "Arcade",
				Text = "Arcade Machines are not yet compattible with controller/console, this will become available in the future.",
				Duration = 3
			})
			return
		end
		
		self:StartSession(player)
	end)

	self.Trove:Connect(config:GetAttributeChangedSignal("isBusy"), function()
		prompt.Enabled = not self:isBusy()
	end)
end

function Module:Stop()
	self.Session:Destroy()
	self.Trove:Destroy()
end

--== Return ==--
return Module