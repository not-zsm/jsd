local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Appearances = {}
local DeveloperDescriptions = {} :: {HumanoidDescription}

--- Where the server leaves the rigs it has dressed, for the client to copy.
local RIGS = "DeveloperRigs"

--- nil until the outfits land: math.random(1, 0) raises rather than returning nothing.
function Appearances.GetRandomDeveloper() : HumanoidDescription?
	if (#DeveloperDescriptions == 0) then return nil end

	return DeveloperDescriptions[math.random(1, #DeveloperDescriptions)]
end

--[[
	A copy of a rig the server has already dressed, or nil if none turn up.

	ApplyDescription only runs on the server, so this is the only way a
	LocalScript gets an outfit onto a preview: take a copy of one the server
	built. Yields, because the rigs sit behind three web calls.
--]]
function Appearances.GetRandomDeveloperRig() : Model?
	local Folder = ReplicatedStorage:FindFirstChild(RIGS) or ReplicatedStorage:WaitForChild(RIGS, 10)
	if (Folder == nil) then return nil end

	for _ = 1, 20 do
		local Rigs = Folder:GetChildren()

		if (#Rigs > 0) then
			return Rigs[math.random(1, #Rigs)]:Clone()
		end

		task.wait(0.5)
	end

	return nil
end

local RandomOutfits = {
	7207821215,
	141123572,
	465427335
}

--if RunService:IsStudio() and shared.IsTestPlace then
--	RandomOutfits = { -- Don't question it
--		7108500910,
--		4471433226,
--		4077150880,
--		7987032614,
--		2364313966,
--		7063404298,
--		6161847158,
--		349382507,
--		47088811,
--	}
--else
--	RandomOutfits = {
--		7207821215, -- swrerm
--		2603403653, -- bugo wugo the goat
--		1862053911, -- arcie
--		141123572, -- jimpee
--		289049081, -- solid
--		462646322, -- ziptune
--		242509995, -- binx
--		166263406, -- boost
--		2496412033 -- grow a blue garden
--	}
--end

local function AddDescriptions()
	local NewDescriptions = {}
	
	for Index, Id in RandomOutfits do
		local Success, Result = pcall(Players.GetHumanoidDescriptionFromUserId, Players, Id)

		if Success then
			table.insert(NewDescriptions, Result)
		end
	end

	DeveloperDescriptions = NewDescriptions
end

--[[
	Only the server fetches. A description is no use to a LocalScript -- it
	cannot apply one -- so the client waits for the rigs below instead of
	spending three web calls every thirty seconds on data it cannot use.
--]]
if RunService:IsServer() then
	local Observer = require( ReplicatedStorage.Packages.Observer )

	--[[
		One dressed rig per outfit, built once. Only outfits that have no rig
		yet get built, so a web call that failed the first time gets another go
		without churning the ones that landed.
	--]]
	local function BuildRigs()
		local Folder = ReplicatedStorage:FindFirstChild(RIGS)

		if (Folder == nil) then
			Folder = Instance.new("Folder")
			Folder.Name = RIGS
			Folder.Parent = ReplicatedStorage
		end

		for Index, Description in DeveloperDescriptions do
			local Name = tostring(Index)

			if Folder:FindFirstChild(Name) then continue end

			local Success, Rig = pcall(
				Players.CreateHumanoidModelFromDescription,
				Players, Description, Enum.HumanoidRigType.R6
			)

			if not Success then
				warn(`could not build a developer rig: {Rig}`)
				continue
			end

			local Humanoid : Humanoid? = Rig:FindFirstChildOfClass("Humanoid")

			if Humanoid then
				Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			end

			Rig.Name = Name
			Rig.Parent = Folder
		end
	end

	AddDescriptions()
	BuildRigs()

	task.spawn(function()
		while task.wait(30) do
			AddDescriptions()
			BuildRigs()
		end
	end)

	Observer.observe_tag("Random_Developer_Outfit", function(Model : Model)
		local Developer : HumanoidDescription = Appearances.GetRandomDeveloper()

		if Developer then
			local Humanoid : Humanoid = Model:FindFirstChild("Humanoid")

			if Humanoid then
				Humanoid:ApplyDescription(Developer)
			end
		end
	end)
end

return Appearances
