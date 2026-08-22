--[[
	Footsteps
	LocalScript -> StarterPlayer > StarterPlayerScripts

	Raycasts down from each foot every frame. When a foot goes from "in the
	air" to "touching ground", it plays a sound picked from the surface
	material, and spits out a splash on water.

	No animation events needed, so it works with any walk/run animation.
	Works on R6 ("Left Leg"/"Right Leg") and R15 ("LeftFoot"/"RightFoot").
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
	StepDebounce = 0.1, -- min seconds between steps on the same foot
	Volume = 0.5,
	PitchJitter = 0.08, -- +/- random playback speed
	RayPadding = 0.3, -- extra ray length below the foot
	RollOffMin = 5,
	RollOffMax = 65,

	ApplyToOtherPlayers = true,
	MaxAudibleDistance = 200,

	-- If workspace.Map exists the rays only hit it (like the original
	-- controller did). Otherwise everything except characters is hit.
	MapFolderName = "Map",

	WaterSplash = true,
}

-- Swap these for your own asset ids
local MATERIAL_SOUNDS = {
	[Enum.Material.Plastic] = "rbxassetid://5761648082",
	[Enum.Material.SmoothPlastic] = "rbxassetid://5761648082",
	[Enum.Material.Slate] = "rbxassetid://5639243489",
	[Enum.Material.Concrete] = "rbxassetid://5639243489",
	[Enum.Material.Brick] = "rbxassetid://5639243489",
	[Enum.Material.Cobblestone] = "rbxassetid://5639243489",
	[Enum.Material.Fabric] = "rbxassetid://619083295",
	[Enum.Material.Glass] = "rbxassetid://3437778169",
	[Enum.Material.Metal] = "rbxassetid://5639245164",
	[Enum.Material.DiamondPlate] = "rbxassetid://5639245590",
	[Enum.Material.Wood] = "rbxassetid://5632735811",
	[Enum.Material.WoodPlanks] = "rbxassetid://5632735811",
	[Enum.Material.Grass] = "rbxassetid://5639244517",
	[Enum.Material.Ground] = "rbxassetid://5639243992",
	[Enum.Material.Sand] = "rbxassetid://5639245918",
	[Enum.Material.Snow] = "rbxassetid://7437372937",
	[Enum.Material.Water] = "rbxassetid://5639245918", -- replace with a real water step
}

local DEFAULT_SOUND = MATERIAL_SOUNDS[Enum.Material.Concrete]

---------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------

local function makeFootSound(parent)
	local sound = Instance.new("Sound")
	sound.Name = "Footstep"
	sound.Volume = CONFIG.Volume
	sound.RollOffMinDistance = CONFIG.RollOffMin
	sound.RollOffMaxDistance = CONFIG.RollOffMax
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.Parent = parent
	return sound
end

local function makeSplash(position, normal)
	if not CONFIG.WaterSplash then
		return
	end

	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(position + normal * 0.1, position + normal)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0.9),
	})
	emitter.Lifetime = NumberRange.new(0.35, 0.6)
	emitter.Speed = NumberRange.new(4, 8)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Acceleration = Vector3.new(0, -40, 0)
	emitter.Rate = 0
	emitter.Enabled = false
	emitter.Parent = part

	part.Parent = workspace:FindFirstChild("Effects") or workspace
	emitter:Emit(8)
	Debris:AddItem(part, 2)
end

local function getFeet(character, humanoid)
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		return character:FindFirstChild("LeftFoot"), character:FindFirstChild("RightFoot")
	end
	return character:FindFirstChild("Left Leg"), character:FindFirstChild("Right Leg")
end

---------------------------------------------------------------------
-- tracking
---------------------------------------------------------------------

local tracked = {}

local function untrack(character)
	tracked[character] = nil
end

local function track(character)
	if tracked[character] then
		return
	end

	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not (humanoid and root and character.Parent) then
			return
		end

		local left, right = getFeet(character, humanoid)
		if not (left and right) then
			return
		end

		local params = RaycastParams.new()
		local map = workspace:FindFirstChild(CONFIG.MapFolderName)
		if map then
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = { map }
		else
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { character }
		end

		tracked[character] = {
			humanoid = humanoid,
			root = root,
			params = params,
			feet = {
				{ part = left, grounded = false, lastStep = 0, sound = makeFootSound(left) },
				{ part = right, grounded = false, lastStep = 0, sound = makeFootSound(right) },
			},
		}
	end)
end

local function hookPlayer(player)
	if player ~= LocalPlayer and not CONFIG.ApplyToOtherPlayers then
		return
	end
	if player.Character then
		track(player.Character)
	end
	player.CharacterAdded:Connect(track)
	player.CharacterRemoving:Connect(untrack)
end

for _, player in ipairs(Players:GetPlayers()) do
	hookPlayer(player)
end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		untrack(player.Character)
	end
end)

---------------------------------------------------------------------
-- step detection
---------------------------------------------------------------------

local SKIP_STATES = {
	[Enum.HumanoidStateType.Physics] = true,
	[Enum.HumanoidStateType.Seated] = true,
	[Enum.HumanoidStateType.Swimming] = true,
	[Enum.HumanoidStateType.Dead] = true,
}

local function playStep(foot, result, scale)
	local now = os.clock()
	if now - foot.lastStep < CONFIG.StepDebounce then
		return
	end
	foot.lastStep = now

	local isWater = result.Material == Enum.Material.Water
		or (result.Instance and result.Instance.Name == "Water")

	if isWater then
		makeSplash(result.Position, result.Normal)
	end

	local sound = foot.sound
	sound.SoundId = MATERIAL_SOUNDS[result.Material] or DEFAULT_SOUND
	sound.PlaybackSpeed = 1 + (math.random() * 2 - 1) * CONFIG.PitchJitter
	sound.Volume = CONFIG.Volume * scale
	sound:Play()
end

RunService.Stepped:Connect(function()
	local camera = workspace.CurrentCamera
	local camPos = camera and camera.CFrame.Position

	for character, data in pairs(tracked) do
		if not (character.Parent and data.root.Parent) then
			tracked[character] = nil
			continue
		end

		if camPos and (camPos - data.root.Position).Magnitude > CONFIG.MaxAudibleDistance then
			continue
		end

		local state = data.humanoid:GetState()
		local skip = SKIP_STATES[state] == true
		local scale = character.GetScale and character:GetScale() or 1

		for _, foot in ipairs(data.feet) do
			if not foot.part.Parent then
				skip = true
			end

			if skip then
				foot.grounded = false
				continue
			end

			local origin = foot.part.Position + foot.part.CFrame.UpVector * scale
			local direction = foot.part.CFrame.UpVector * -(2 * scale + CONFIG.RayPadding)
			local result = workspace:Raycast(origin, direction, data.params)

			if result and not foot.grounded then
				foot.grounded = true
				playStep(foot, result, scale)
			elseif not result and foot.grounded then
				foot.grounded = false
			end
		end
	end
end)