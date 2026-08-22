local VFX = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Utility = require( ReplicatedStorage.Shared.Utilities.Utility )

function VFX.Value(RootPart : BasePart, Damage : number)
	local UI = script.UI:Clone()
	UI.Name = "CharaDamageIndicator"
	UI.Value.Text = tostring(Utility.DecimalRound(Damage))
	UI.Value.TextTransparency = 1
	UI.Value.UIStroke.Transparency = 1
	UI.Parent = RootPart.Parent.Torso
	
	TweenService:Create(UI.Value, TweenInfo.new(0.25),
		{TextTransparency = 0}
	):Play()

	TweenService:Create(UI.Value.UIStroke, TweenInfo.new(0.25),
		{Transparency = 0}
	):Play()
	
	local X = Utility.Seed:NextNumber(-3, 3)
	local Y = Utility.Seed:NextNumber(-0.75, 1.25)
	
	local PX, PY, PZ = math.random(), math.random(), math.random()
	local Start = tick()
	local Time = 0
	
	local Size = 1.5
	local Scale = 1.7
	local SizeDuration = 0.6
	
	Utility.BindSignalDisconnectToInstanceDestroying(RunService.PreRender, UI, function(Delta)
		Time += Delta
		
		local ShakeX = math.noise(Start + PX,  Time * 7.15 + PY, PZ) * Scale * Size
		local ShakeY = math.noise(Start + PX, -Time * 7.19 + PZ, PY) * Scale * Size

		Size = 1 - TweenService:GetValue(math.clamp(Time * (1 / SizeDuration), 0, 1), Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
		UI.StudsOffsetWorldSpace = Vector3.new(X + ShakeX, Y + ShakeY)
	end)
	
	task.delay(1.5, function()
		TweenService:Create(UI.Value, TweenInfo.new(0.75),
			{TextTransparency = 1}
		):Play()
		
		TweenService:Create(UI.Value.UIStroke, TweenInfo.new(0.75),
			{Transparency = 1}
		):Play()
		
		task.delay(0.75, UI.Destroy, UI)
	end)
end

return VFX