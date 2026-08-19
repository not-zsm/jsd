local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local Character = StarterPlayer.StarterCharacter;

local Player = Players.LocalPlayer;
local Assets = script;

local RockHandler = require( ReplicatedStorage.Modules.Player.Replication.Global.RockHandler )
local CameraShake = require( ReplicatedStorage.Modules.Player.Replication.Global.CameraShake )
local Vignette = require( ReplicatedStorage.Modules.Player.Replication.Global.Vignette )

local AenoirEmit = require( ReplicatedStorage.Modules.Player.Replication.EffectUtility.AenoirEmit )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

local VFX = {}

local function IsInDistance(Point : Vector3, Distance : number)
	return Player:DistanceFromCharacter(Point) < Distance
end

local function WallCrater(root : BasePart)
	if IsInDistance(root.Position, 75) then
		local CF = root.CFrame * CFrame.new(1, 0.5, 1.5)
		local Direction = CF.LookVector * 10

		local Raycast = workspace:Raycast(CF.Position, Direction, Utility.VisualParams)

		if (Raycast ~= nil) then
			coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
				Amount = 9,
				Distance = 4,

				LookAt = { -- Where the rocks face towards (y axis)
					Min = -3,
					Max = -3
				},

				Exposure = {
					Min = 0.4,
					Max = 0.6
				},

				SizeMultiplier = 0.95,
			})

			coroutine.wrap(RockHandler.Crater)(Raycast.Position, Direction, {
				Amount = 13,
				Distance = 6.35,
				SizeMultiplier = 1.15,
			})

			coroutine.wrap(RockHandler.Rockst)(Raycast.Position, Direction, {
				Count = 7,
				Size = {0.3, 1},
				Velocity = 60,
			})
		end
	end
end

function VFX.Slam(rootpart : BasePart)
	local attachment = Instance.new("Attachment");
	attachment.CFrame = CFrame.new(1, 0.5, -4) * CFrame.Angles(0, math.rad(-180), 0);
	attachment.Parent = rootpart
	
	AenoirEmit(Assets.MichaelKick, attachment, function()
		attachment:Destroy()
	end)
	
	if IsInDistance(rootpart.Position, 25) then
		CameraShake(2, 14, 0.01, 0.75, Vector3.one * 0.8)
		Vignette(Color3.fromRGB(255, 90, 90), 0.65, 0.2)
	end
	
	WallCrater(rootpart)
end

function VFX.KickHit(rootpart : BasePart)
	local attachment = Instance.new("Attachment");
	attachment.CFrame = CFrame.new(1, 0.5, -4) * CFrame.Angles(0, math.rad(-180), 0);
	attachment.Parent = rootpart
	
	AenoirEmit(Assets.MichaelKick, attachment, function()
		attachment:Destroy()
	end)
	
	if IsInDistance(rootpart.Position, 25) then
		CameraShake(3, 20, 0.01, 0.5, Vector3.one * 0.8)
		Vignette(Color3.fromRGB(255, 90, 90), 0.475, 0.25)
	end
	
	WallCrater(rootpart)
end

function VFX.Ringing(rootpart : BasePart)
	AenoirEmit(Assets.Ringing, rootpart);
end

function VFX.Swing(rootpart : BasePart)
	AenoirEmit(Assets.Swing, rootpart);
end

function VFX.SwingKick(rootpart : BasePart)
	AenoirEmit(Assets.SwingKick, rootpart);
end

function VFX.Call(rootpart : BasePart)
	AenoirEmit(Assets.Call, rootpart);
end

function VFX.FlipPhone(attacker : Model)
	local steak = Assets.Steak:Clone()
	steak.Name = "FlipPhoneSteak"
	steak.SteakJoint.Part0 = attacker["Left Arm"];
	steak.Parent = attacker;
end

function VFX.HangUp(attacker : Model)
	task.wait(1)
	
	local phone = attacker:FindFirstChild("FlipPhoneSteak")
	if phone then phone:Destroy() end
end

return VFX