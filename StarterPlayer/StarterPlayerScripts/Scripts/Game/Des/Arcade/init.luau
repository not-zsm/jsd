--== Imports ==--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local Players           = game:GetService("Players")

local CharacterTransparency = require( ReplicatedStorage.Modules.Player.Replication.Global.CharacterTransparency )

local Packages = ReplicatedStorage.Packages.Des
local Event    = ReplicatedStorage.PlayerRemotes.Arcade.Main
local EndEvent = ReplicatedStorage.PlayerRemotes.Arcade.ForceEnd

local Component = require(Packages.Component)
local Trove     = require(Packages.Trove)
local Music = require(script.MusicManager)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

--== Constants ==--
local TWEEN_INOUT   = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local CAMERA_OFFSET = CFrame.new(2, 0, 0)

local ANIMS = script.Animations
local RNG   = Random.new()

--== Module ==--
local Module = Component.new({
	Tag       = "Arcade",
	Ancestors = { Workspace },
})

--== Private ==--
local function getFromInstance(instance: Instance)
	for _, component in ipairs(Module:GetAll()) do
		if component.Instance == instance then
			return component
		end
	end
end

--== Public ==--
function Module:StartSession()
	local character = player.Character
	local humanoid  = character and character:FindFirstChild("Humanoid") :: Humanoid
	local animator  = humanoid and humanoid:FindFirstChild("Animator") :: Animator
	if not humanoid or not animator or humanoid.Health <= 0 then
		return
	end

	local pivot  = self.Screen.CFrame
	local target = pivot:ToWorldSpace(CAMERA_OFFSET)
	local lookAt = CFrame.lookAt(target.Position, pivot.Position + Vector3.new(0, CAMERA_OFFSET.Y, 0), Vector3.yAxis)

	camera.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(camera, TWEEN_INOUT, {CFrame = lookAt}):Play()
	CharacterTransparency(character, 1)

	self.Game:Focus()
	self.Session:Connect(character.AncestryChanged, function() self:StopSession() end)
	--self.Session:Connect(player.AncestryChanged, function() self:StopSession()end)
	self.Session:Connect(self.Game.Signal, function() self:StopSession() end)
	--self.Session:Connect(humanoid.Died, function() self:StopSession() end)
	
	self.Session:Add(task.spawn(function()
		while task.wait(RNG:NextNumber(0.75, 1.25)) do
			self.Animations.Random[RNG:NextInteger(1, #self.Animations.Random)]:Play()
		end
	end))
	
	self.Animations = {
		Focus = animator:LoadAnimation(ANIMS.Focus),
		Idle  = animator:LoadAnimation(ANIMS.Idle),
		
		Random = {}
	}
	
	for _, anim in ipairs(ANIMS.Random:GetChildren()) do
		table.insert(self.Animations.Random, animator:LoadAnimation(anim))
	end
	
	self.Animations.Focus:Play()
	self.Animations.Idle:Play()
	
	Music:Start()
end

function Module:StopSession()
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = player.character.Humanoid
	CharacterTransparency(player.character, 0)
	Event:FireServer()
	
	if self.Animations then
		self.Animations.Focus:Stop(0.2)
		self.Animations.Idle:Stop(0.2)
		
		for _, anim in ipairs(self.Animations.Random) do
			anim:Stop(0.2)
		end
	end
	
	Music:Stop()

	self.Game:Unfocus()
	self.Session:Clean()
end

--== Lifecycle ==--
function Module:Construct()
	local instance = self.Instance :: Model
	
	self.Session = Trove.new()
	self.Trove   = Trove.new()

	self.Config = instance:WaitForChild("Config")
	self.Prompt = instance:WaitForChild("Prompt")
	self.Screen = instance:WaitForChild("Screen")
end

function Module:Start()
	local config = self.Config :: Configuration

	local name   = config:GetAttribute("Game")
	local module = script.Games:WaitForChild(name)

	self.Game = require(module).new(self.Screen)
end

function Module:Stop()
	self.Session:Destroy()
	self.Trove:Destroy()
end

--== Hooks ==--
Event.OnClientEvent:Connect(function(instance: Instance, action: "Start" | "End")
	local component = getFromInstance(instance)
	if component then
		if action == "Start" then
			component:StartSession()
		elseif action == "End" then
			component:StopSession()
		end
	end
end)

local function set_all_screens_animated(animated: boolean): ()
	for _, component in Module:GetAll() do
		local screen = component.Instance:FindFirstChild("Screen");
		
		if screen then
			screen:SetAttribute("DisableTextAnimation", not animated);
		end;
	end;
end;

task.defer(set_all_screens_animated, false);

task.spawn(function()
	local in_arcade_radius = false;
	
	while task.wait(0.5) do
		local distance_from_arcade = Players.LocalPlayer:DistanceFromCharacter(workspace.ArcadeCenter.Position);
		local last_in_radius = in_arcade_radius;
		
		if distance_from_arcade < 160 then
			in_arcade_radius = true;
		else
			in_arcade_radius = false;
		end;
		
		if in_arcade_radius ~= last_in_radius then
			set_all_screens_animated(in_arcade_radius);
		end;
	end;
end)


--== Return ==--
return Module