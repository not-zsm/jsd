local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local TweenService = game:GetService 'TweenService'
local Debris = game:GetService 'Debris'

local AnimationRetriever = require( ReplicatedStorage.Modules.Player.Replication.VFX.AnimationRetriever )
local Animation = ReplicatedStorage.Animations.Emotes["I'm A Mystery"]

local EffectUtility = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility )

local FrameMarker = require(script.FrameMarker)

local emit_util = require(script.emit)
local enable_util = require(script.enable)
local disable_util = require(script.disable)
local highlight_emit_util = require(script.highlight_emit)

return {
	Start = function(Model : Model)
		local Retrieved = AnimationRetriever.new(Model, Animation)
		if (Retrieved == nil) then return end

		local RootPart = Retrieved.RootPart
		local Job = Retrieved.Job
		
		local LeftArm = Model["Left Arm"]
		local RightArm = Model["Right Arm"]

		local VFX = Job:Task(script.PartFx:Clone())
		EffectUtility.Weld(VFX, RootPart)
		VFX.Parent = workspace.Visuals

		local Left = Job:Task(script.Left:Clone())
		local Right = Job:Task(script.Right:Clone())
		Left.Parent = LeftArm
		Right.Parent = RightArm
		
		local MarkerObject = FrameMarker.new{Framerate = 60}
		Job:Task(MarkerObject)
		
		local function StartChain()
			MarkerObject._FrameMarkerElapsed = 0
			MarkerObject._sequences = {}
			MarkerObject:Chain{

				[1] = function ()

					enable_util(Right.Trail)


				end,

				[14] = function ()

					emit_util(Right.Pop)

					highlight_emit_util.tweenHighlight(
						RootPart.Parent,
						Color3.fromRGB(124, 170, 255),
						Color3.fromRGB(83, 86, 255),
						.62,
						Enum.HighlightDepthMode.Occluded,
						"In",
						0.2
					)

				end,

				[28] = function ()

					disable_util(Right.Trail)

				end,

				[48] = function ()

					enable_util(Left.Trail)

					emit_util(Left.Pop)

					highlight_emit_util.tweenHighlight(
						RootPart.Parent,
						Color3.fromRGB(124, 170, 255),
						Color3.fromRGB(83, 86, 255),
						.62,
						Enum.HighlightDepthMode.Occluded,
						"In",
						0.2
					)

				end,

				[82] = function ()

					disable_util(Left.Trail)

				end,

				[107] = function ()

					emit_util(VFX.Part.Top)

					highlight_emit_util.tweenHighlight(
						RootPart.Parent,
						Color3.fromRGB(124, 170, 255),
						Color3.fromRGB(83, 86, 255),
						.62,
						Enum.HighlightDepthMode.Occluded,
						"In",
						0.2
					)

				end,

				[125] = function ()

					emit_util(VFX.Part.Bottom)

				end,

				[141] = function ()

					emit_util(VFX.Part.Top)

					highlight_emit_util.tweenHighlight(
						RootPart.Parent,
						Color3.fromRGB(124, 170, 255),
						Color3.fromRGB(83, 86, 255),
						.62,
						Enum.HighlightDepthMode.Occluded,
						"In",
						0.2
					)

				end,

				[156] = function ()

					emit_util(VFX.Part.Bottom)

				end,

				[190] = function ()

					enable_util(Left.Trail)

					highlight_emit_util.tweenHighlight(
						RootPart.Parent,
						Color3.fromRGB(124, 170, 255),
						Color3.fromRGB(83, 86, 255),
						.62,
						Enum.HighlightDepthMode.Occluded,
						"In",
						0.2
					)

				end,

				[208] = function ()

					disable_util(Left.Trail)

					emit_util(Left.Pop)

				end,

				[212] = function ()

					emit_util(VFX.Part.Top2)

				end,

				[222] = function ()

					emit_util(VFX.Part.Step)

					highlight_emit_util.tweenHighlight(
						RootPart.Parent,
						Color3.fromRGB(124, 170, 255),
						Color3.fromRGB(83, 86, 255),
						.62,
						Enum.HighlightDepthMode.Occluded,
						"In",
						0.2
					)

				end,

				[233] = function ()

					emit_util(VFX.Part.Bottom2)

				end,


				[246] = function ()

					emit_util(VFX.Part.Step2)

				end,

				[249] = function ()

					emit_util(VFX.Part.Top3)

					highlight_emit_util.tweenHighlight(
						RootPart.Parent,
						Color3.fromRGB(124, 170, 255),
						Color3.fromRGB(83, 86, 255),
						.62,
						Enum.HighlightDepthMode.Occluded,
						"In",
						0.2
					)


				end,

				[280] = function ()

					emit_util(Left.Pop)

					emit_util(Right.Pop)

				end,

				[298] = function ()

					enable_util(VFX.Part.Spin)

					enable_util(Left.Trail)

					enable_util(Right.Trail)

					highlight_emit_util.tweenHighlight(
						RootPart.Parent,
						Color3.fromRGB(124, 170, 255),
						Color3.fromRGB(83, 86, 255),
						.62,
						Enum.HighlightDepthMode.Occluded,
						"In",
						0.2
					)

				end,

				[310] = function ()

					disable_util(VFX.Part.Spin)

					disable_util(Left.Trail)

					disable_util(Right.Trail)

				end,

				[343] = function ()

					enable_util(Left.Trail)

					enable_util(Right.Trail)

					highlight_emit_util.tweenHighlight(
						RootPart.Parent,
						Color3.fromRGB(124, 170, 255),
						Color3.fromRGB(83, 86, 255),
						.62,
						Enum.HighlightDepthMode.Occluded,
						"In",
						0.2
					)

				end,

				[350] = function ()

					emit_util(VFX.Part.Step3)

				end,

				[376] = function ()

					emit_util(VFX.Part.Step4)

				end,

				[384] = function ()

					disable_util(Left.Trail)

					disable_util(Right.Trail)

					emit_util(Left.Pop)

					emit_util(Right.Pop)

					highlight_emit_util.tweenHighlight(
						RootPart.Parent,
						Color3.fromRGB(124, 170, 255),
						Color3.fromRGB(83, 86, 255),
						.62,
						Enum.HighlightDepthMode.Occluded,
						"In",
						0.2
					)


				end,

				[403] = function ()

					emit_util(VFX.Part.Top4)

				end,

				[410] = function ()

					emit_util(VFX.Part.Bottom3)

					enable_util(Right.Trail)

					highlight_emit_util.tweenHighlight(
						RootPart.Parent,
						Color3.fromRGB(124, 170, 255),
						Color3.fromRGB(83, 86, 255),
						.62,
						Enum.HighlightDepthMode.Occluded,
						"In",
						0.2
					)
				end,
			}
		end
		
		Job:Task(Retrieved.Animation.DidLoop:Connect(StartChain))
		StartChain()
	end
}
