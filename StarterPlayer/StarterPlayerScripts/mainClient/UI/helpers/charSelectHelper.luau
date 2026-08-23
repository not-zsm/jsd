--- Ported from jjk. Per-character assets go under script.assets.
local replicatedStorage = game:GetService('ReplicatedStorage')
local tweenService = game:GetService('TweenService')
local soundService = game:GetService('SoundService')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

local animation = require(replicatedStorage.modules.shared.animationUtil)
local soundHandler = require(replicatedStorage.modules.shared.soundUtil)

-- you author these per character: assets/<moveset>/{model, intro, idle}
local assetFolder = script:FindFirstChild("assets")
local config = require(script.Parent.Parent.config)

local localPlayer = players.LocalPlayer
local starterGUI = localPlayer:WaitForChild('PlayerGui')

local charSelectHelper = {}
charSelectHelper.__index = charSelectHelper

function charSelectHelper.new(moveset, viewport)
	local self = setmetatable({}, charSelectHelper)
	
	if not viewport then warn('you forgot the viewport idiot fat boy') return end
	
	-- every character needs assets/<moveset>/{model, intro, idle}. jjk fell back
	-- to yuji; there is nothing sensible to fall back to here, so say so.
	self.assetFolder = assetFolder and assetFolder:FindFirstChild(moveset)

	if not self.assetFolder then
		warn(`charSelectHelper: no assets for "{moveset}" -- needs model, intro and idle under helpers.charSelectHelper.assets`)
		return
	end

	self.characterModel = self.assetFolder.model:Clone()
	
	self.animations = {
		intoAnim = self.assetFolder.intro,
		idleAnim = self.assetFolder.idle,
	}
	
	self.intro = true
	self.idling = false
	
	self.characterModel.Parent = viewport
	
	local ogPos = self.characterModel.WorldPivot

	local tweenProxy = Instance.new("CFrameValue")
	tweenProxy.Value = self.characterModel:GetPivot()

	local startPos = self.characterModel:GetPivot() * CFrame.new(0, 3, 0)
	local endPos = ogPos
	tweenProxy.Value = startPos

	tweenProxy.Changed:Connect(function()
		self.characterModel:PivotTo(tweenProxy.Value)
	end)

	local tween = tweenService:Create(tweenProxy, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Value = endPos})
	tween:Play()

	tween.Completed:Connect(function()
		tweenProxy:Destroy()
	end)
	
	local introAnim = animation:loadAnimation(self.characterModel.character, self.animations.intoAnim, nil, nil, false)
	local idleAnim = animation:loadAnimation(self.characterModel.character, self.animations.idleAnim, nil, nil, true)
	
	introAnim:Play(0)
	
	introAnim.Stopped:Connect(function()
		self.intro = false
		idleAnim:Play(0)
		self.idling = true
	end)
	
	return self
end

function charSelectHelper:destroy()
	self.characterModel:Destroy()
end

return charSelectHelper