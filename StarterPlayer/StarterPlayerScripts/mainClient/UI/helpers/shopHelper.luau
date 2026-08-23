--- Ported from jjk. Assets are script.assets; the shop GUI carries the keeper.
local replicatedStorage = game:GetService('ReplicatedStorage')
local tweenService = game:GetService('TweenService')
local soundService = game:GetService('SoundService')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

local animation = require(replicatedStorage.modules.shared.animationUtil)
local soundHandler = require(replicatedStorage.modules.shared.soundUtil)

local assetFolder = script.assets
local soundFolder = assetFolder.peopleSound
local config = require(script.Parent.Parent.config)

local localPlayer = players.LocalPlayer
local starterGUI = localPlayer:WaitForChild('PlayerGui')

local shopHelper = {}
shopHelper.__index = shopHelper

local function tvToggle(self, toggle)
	local tv = self.shop:WaitForChild('container')
		:WaitForChild('keepa')
		:WaitForChild('shopKeeper')
		:WaitForChild('worldModel')
		:WaitForChild('shopKeeper')
		:WaitForChild('crt')
	
	local screen = tv.Parts.Part.Texture
	
	if toggle then
		task.delay(0.1, function()
			screen.Transparency = 0
		end)
		task.delay(0.2, function()
			screen.Transparency = 1
		end)
		task.delay(0.25, function()
			screen.Transparency = 0
		end)
		task.delay(0.3, function()
			screen.Transparency = 1
		end)
		task.delay(0.45, function()
			screen.Transparency = 0
		end)
	else
		screen.Transparency = 1
	end
end

local function resetTimeout(self)
	self.idleTime = 0
	self.idleStep = 1
end

function shopHelper.new(keeperType, keeper, shop, container)
	local self = setmetatable({}, shopHelper)
	
	self.keeper = keeper
	self.animations = {
		intro = assetFolder[keeperType]['intro'],
		loop = assetFolder[keeperType]['loop'],
		yap = assetFolder[keeperType]['yap']
	}
	self.shop = shop
	self.container = container
	self.intro = true
	self.forceStop = false
	self.skipVoice = false
	self.speaking = false
	
	self.keeperSize = self.keeper.Parent.Parent.Size
	self.pokeLimit = 0
	
	self.idleTime = 0
	self.idleStep = 1
	
	local randomOccurance = math.random(1, config.shop.SKELETONCHANCE)
	if randomOccurance == 1 then self:_handleSkeleton() end
	
	local introAnim = animation:loadAnimation(keeper, self.animations.intro, nil, nil, false)
	local loopAnim = animation:loadAnimation(keeper, self.animations.loop, nil, nil, true)
	
	introAnim:Play(0)
	
	introAnim.Stopped:Connect(function()
		self.intro = false
		tvToggle(self, true)
		loopAnim:Play(0)
	end)
	
	return self
end

function shopHelper:shopkeeperYap(toYap)
	while self.intro or self.speaking do
		if self.forceStop then return end
		task.wait()
	end
	
	if self.forceStop then return end
	if not self.keeper then return end
	if not self.shop then return end
	self.speaking = true
	
	local yapAnim = animation:loadAnimation(self.keeper, self.animations.yap, nil, nil, true)
	
	local container = self.shop:FindFirstChild('container')
	local keepa = container and container:FindFirstChild('keepa')
	local keeperGui = keepa and keepa:FindFirstChild('shopKeeper')
	local dialogueHolder = keeperGui and keeperGui:FindFirstChild('dialogue')
	if not dialogueHolder then return end
	
	local thisText = dialogueHolder:WaitForChild('words')
	if not thisText then return end
	
	local specialType
	local eventDelay

	if typeof(toYap) == 'table' then
		specialType = toYap[2]
		eventDelay = toYap[3]
		toYap = toYap[1]
	end

	if specialType then self[`_{specialType}`](self, eventDelay) end
	
	local function typeText(text)
		local textSize = #text
		local count = 0
		local waitTime
		
		for i = 1, #text do
			if not self.shop then break end
			if not self.keeper then break end
			if self.forceStop then break end
			
			if not yapAnim.IsPlaying then yapAnim:Play(0) end
			
			waitTime = 0.05 -- reset
			count += 1
			
			if text == config.shop.keeper.yap[1] then
				if not self.skipVoice then
					local sound = soundFolder.tenya
					soundHandler:playSound(sound, soundService)
					self.skipVoice = true
				end
				waitTime = 0.11
			else
				if not self.skipVoice then
					-- one lookup per character of the line, so a missing voice
					-- would throw all the way through the sentence
					local sound = soundFolder:FindFirstChild(self.keeper:GetAttribute('nir') or '')
					if sound then
						soundHandler:playSound(sound, soundService)
					end
				end
			end
			
			local currentChar = string.sub(text, i, i)
			
			if currentChar == ',' then waitTime = 0.15 end
			if currentChar == ':' then waitTime = 0.35 end
			if currentChar == '.' then waitTime = 0.5 end
			
			local subString = string.sub(text, 1, i)
			
			thisText.Text = subString
			task.wait(waitTime)
			
			if self.yapTask then task.cancel(self.yapTask) end
			self.yapTask = task.delay(0.3, function()
				yapAnim:Stop(0.05)
			end)
				
			if count >= textSize then --failsafe
				if currentChar == '-' then yapAnim:Stop(0) break end
				task.wait(0.5)
				yapAnim:Stop(0.05)
			end
		end
	end
	
	if yapAnim then	yapAnim:Play() end
	dialogueHolder.Visible = true
	
	while yapAnim and yapAnim.IsPlaying and not self.intro and self.shop and not self.forceStop do
		typeText(toYap)
		self.speaking = false
	end
end

function shopHelper:pressKeeper()
	self.keeper.Parent.Parent.Size = self.keeperSize + UDim2.new(0, -200, 0, -100)
	resetTimeout(self)
	
	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
	local tween = tweenService:Create(self.keeper.Parent.Parent, tweenInfo, {Size = self.keeperSize})
	tween:Play()
	
	if not self.speaking then 
		if self.pokeLimit == 0 then
			self:shopkeeperYap(config.shop.keeper.yap[math.random(3, 10)])
		elseif self.pokeLimit == 1 then
			self:shopkeeperYap('wait that kinda hurts...')
		else
			local lines = config.shop.keeper.pokeResponses[self.keeper:GetAttribute('nir')]

			if lines then
				local range = if self.pokeLimit == 2 then 1 else #lines
				self:shopkeeperYap(lines[math.random(1, range)])
			end
		end
		
		self.pokeLimit += 1
	end
end

function shopHelper:timeoutResponses()
	local responses = {
		{ delay = 10,  text = 'right, take your sweet time mate' },
		{ delay = 20,  text = 'okay hurry up i aint got all day' },
		{ delay = 30,  text = 'uhhh hello?' },
		{ delay = 50,  text = 'you just gonna... stare all day?' },
		{ delay = 60,  text = '...why are you STILL here??' },
		{ delay = 300, text = 'alr bro just take the achievement 🫩' },
	}

	resetTimeout(self)

	self.timeoutTask = task.spawn(function()
		while not self.forceStop do
			local dt = task.wait(0.5)

			-- keeper busy → don't count idle time, don't fire mid-sentence
			if self.speaking or self.intro then
				self.idleTime = 0
				continue
			end

			self.idleTime += dt

			local step = responses[self.idleStep]
			if step and self.idleTime >= step.delay then
				self:shopkeeperYap(step.text)
				self.idleStep += 1
			end
			
			if self.idleStep >= 300 then
				warn('waow u js got an achievemento!')
			end
		end
	end)

	self.container:Task(self.timeoutTask)
end

function shopHelper:_handleSkeleton()
	local skeletonModel = self.keeper.Parent:FindFirstChild('skell')
	if not skeletonModel then return end
	self.container:Task(skeletonModel)
	
	local viewport = starterGUI:FindFirstChild('upperViewport')
	if not viewport then return end -- jjk had a full-screen viewport to run across

	skeletonModel.Parent = viewport.cg.vf.wm
	
	local skeletonAnim = animation:loadAnimation(skeletonModel, assetFolder.skeletonRun, nil, nil, true)
	skeletonAnim:Play(0) --nil error.. mayb animation cant handle r15?
	skeletonAnim:AdjustSpeed(3)
	
	local sound = soundFolder.skeleton
	soundHandler:playSound(sound, soundService)
	
	local start = skeletonModel:GetPivot()
	local goal = start * CFrame.new(2, 0, -955)--CFrame.new(0, 0, -946.5)
	local elapsed = 0

	local function easeOutCirc(t)
		return math.sqrt(1 - (t - 1) ^ 2)
	end

	local conn
	conn = runService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local alpha = math.min(elapsed / 2.5, 1)
		skeletonModel:PivotTo(start:Lerp(goal, easeOutCirc(alpha)))
		if alpha >= 1 then conn:Disconnect() end
	end)
end

function shopHelper:_train(delay)
	print('cant stop the nir train')
end

function shopHelper:_whoop(delay)
	print('mane FUCK this guy')
end

function shopHelper:_sneaker(delay)
	print('we cant stop him.... not with THOSE sneakers.')
end

function shopHelper:Destroy()
	self.forceStop = true
	
	if self.yapTask then
		task.cancel(self.yapTask)
		self.yapTask = nil
	end
	
	self.keeper = nil
	self.shop = nil
	self.skipVoice = false
	self.speaking = false
	self.pokeLImit = 0
	self.forceStop = false
end

return shopHelper