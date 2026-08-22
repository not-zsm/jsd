local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local AttributeListener = require( ReplicatedStorage.Client.Replication.Global.AttributeListener )

local Normal = "rbxassetid://74426750731046"
local Alt = "rbxassetid://113613695330573"

return function(PlayLocally : boolean, PlayAlt : boolean, Model : Model)
	local Theme = Instance.new("Sound")
	Theme.Name = "Chara_Theme"
	Theme.PlaybackRegionsEnabled = true
	Theme.PlaybackRegion = NumberRange.new(PlayAlt and 0.1 or 5, 60000)
	Theme.SoundId = PlayAlt and Alt or Normal
	Theme.Volume = 0
	Theme.Looped = true
	Theme.SoundGroup = SoundService.UltimateMusic
	Theme.Parent = (PlayLocally and workspace or Model.Torso)
	Theme:Play()

	TweenService:Create(Theme, TweenInfo.new(0.25),
		{Volume = 0.75}
	):Play()

	local ThemeJob = AttributeListener.new(Model, "Ultimate", function()
		TweenService:Create(Theme, TweenInfo.new(0.5),
			{Volume = 0}
		):Play()

		task.delay(1, Theme.Destroy, Theme)
	end)

	local Listener = AttributeListener.GetReplicationFromSource(Model)

	if Listener then
		local MuteTween
		
		ThemeJob:Task(Listener:GetAttributeChangedSignal("Ultimate_Mute"):Connect(function()
			local Mute = Listener:GetAttribute("Ultimate_Mute")

			if MuteTween then
				MuteTween:Cancel()
			end
			
			if Mute then
				MuteTween = TweenService:Create(Theme, TweenInfo.new(0.25),
					{Volume = 0}
				)
				
				MuteTween:Play()
					
				MuteTween.Completed:Once(function(State)
					if State == Enum.PlaybackState.Completed then
						Theme:Pause()
					end
				end)
			else
				Theme:Resume()
				
				MuteTween = TweenService:Create(Theme, TweenInfo.new(0.25),
					{Volume = 0.75}
				)
					
				MuteTween:Play()
			end
		end))
	end
end