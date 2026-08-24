local Lines = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local SoundService = game:GetService("SoundService")

local TekrinnDialogue = require( replicatedStorage.modules.effect.tekrinnDialogue )
local EffectUtility = require( replicatedStorage.modules.client.replication.EffectUtility )

local CurrentLine
local PreviousLinePriority = 0

function Lines.Create(Chara : Model, Text : string, Range : number)
	if (Chara == nil or Chara.Parent == nil) then return end
	
	Range = Range or 250
	
	local Distance = LocalPlayer:DistanceFromCharacter(Chara.PrimaryPart.Position)

	if (Distance < Range) then
		local Time = string.len(Text) / 11
		
		if CurrentLine then
			TweenService:Create(CurrentLine, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{Volume = 0}
			):Play()
			
			task.delay(0.1, CurrentLine.Destroy, CurrentLine)
			
			CurrentLine = nil
		end

		TekrinnDialogue.Speak(Chara, 

			{
				Text = Text,
				Image = "85316557846229",
				ExtraImageSize = UDim2.fromOffset(15, 15),
				TextStrokeColor = Color3.new(0, 0, 0),
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
					ColorSequenceKeypoint.new(0.25, Color3.fromRGB(181, 53, 53)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(109, 32, 32)),
					ColorSequenceKeypoint.new(0.75, Color3.fromRGB(181, 53, 53)),
					ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
				}),
				Shake = {
					Lifetime = 1.25,
					Enabled = true,
					Intensity = 1.75,
				},
				HigherUp = true,
				TypeSpeed = (Time / 67.5),
			}, 

			{
				StrokeColor = Color3.new(0, 0, 0),
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
					ColorSequenceKeypoint.new(0.25, Color3.fromRGB(181, 53, 53)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(109, 32, 32)),
					ColorSequenceKeypoint.new(0.75, Color3.fromRGB(181, 53, 53)),
					ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
				}),
			}, 

			Time
		)
		
		local Line = script.Boss:FindFirstChild(Text)

		if Line then
			local NewLine = Line:Clone()
			NewLine.Parent = (Distance < (Range / 1.5)) and workspace or Chara.PrimaryPart
			NewLine:Play()
			
			CurrentLine = NewLine
		end
	end
end

return Lines
