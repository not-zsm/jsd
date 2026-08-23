local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
	LocalPlayer = {
		PlayerGui = game.StarterGui
	}
end

local function Clone(vvv: string)
	return replicatedStorage.modules.effect.assets:FindFirstChild(vvv,true):Clone()
end

local function Modify(vvv: any?,instances: {any?}) : Instance?
	assert(vvv,"no object passed bitch")
	assert(instances,"no instance data passed")

	for i,v in instances do
		vvv[i] = v
	end
end

local function ChangeEffect(UI: ScreenGui,reset)
	if not reset then

		for i,v in UI:GetChildren() do
			TweenService:Create(v,
				TweenInfo.new(0.6,Enum.EasingStyle.Quad),
				{
					ImageTransparency = 1
				}
			):Play()
		end

	else
		local rotation = math.random(1,2) == 1
		for i,v in UI:GetChildren() do
			v.ImageTransparency = 0
			v.Rotation = rotation and -30 or 30;

			TweenService:Create(v,
				TweenInfo.new(0.5,Enum.EasingStyle.Elastic),
				{
					Rotation = 0
				}
			):Play()
		end
	end
end


local FX = {}

function FX.New(Data)
	local newVFX = setmetatable({},{__index = FX})

	newVFX.Player = LocalPlayer
	newVFX.Data = Data
	newVFX.Instances = {}

	return newVFX
end

function FX:Track()
	self.Started = os.time()
end

function FX:Fire()
	local UI = Clone("Count") :: ScreenGui
	UI.Parent = LocalPlayer.PlayerGui

	table.insert(self.Instances,UI)

	local Counting = "rbxassetid://103234222807665"

	for _,v in UI:GetChildren() do
		v.AnchorPoint = Vector2.new(0.5, 0.5) --THANKS DEVFORUM FOR TELLING ME ABOUT ANCHORPOINT
		v.Position = UDim2.fromScale(0.5, 0.5)
		v.Size = UDim2.fromScale(0, 0)

		v.Rotation = -30
		v.ImageTransparency = 1

		v.ScaleType = Enum.ScaleType.Fit

		TweenService:Create(
			v,
			TweenInfo.new(0.8, Enum.EasingStyle.Exponential),
			{
				Rotation = 0,
				Size = UDim2.fromScale(0.733, 0.522),
				ImageTransparency = 0
			}
		):Play()
	end


	SoundService.Ranked[`Sound{math.random(1,3)}`]:Play()
	Modify(UI.Main,{
		Image = Counting
	})
	Modify(UI.Shadow,{
		Image = Counting
	})

	task.wait(2)
	ChangeEffect(UI)

	task.delay(1,function()
		self:Ended()
	end)
end

function FX:Ended()
	if self.Started then
		print(`time taken: {os.time() - self.Started}s`)
	end
	for i,v in self.Instances do
		v:Destroy()
	end

	self = nil
end

return FX