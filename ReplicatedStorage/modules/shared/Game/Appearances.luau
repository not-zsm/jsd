local replicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Observer = require( replicatedStorage.Packages.Observer )
local info = require(replicatedStorage.info)

local Appearances = {}
local DeveloperDescriptions = {} :: {HumanoidDescription}

--- nil until the outfits land: math.random(1, 0) raises rather than returning nothing.
function Appearances.GetRandomDeveloper() : HumanoidDescription?
	if (#DeveloperDescriptions == 0) then return nil end

	return DeveloperDescriptions[math.random(1, #DeveloperDescriptions)]
end

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
	
	for Index, Id in info.theBigFour do
		local Success, Result = pcall(Players.GetHumanoidDescriptionFromUserId, Players, Id)

		if Success then
			table.insert(NewDescriptions, Result)
		end
	end

	DeveloperDescriptions = NewDescriptions
end

AddDescriptions()

task.spawn(function()
	while task.wait(30) do
		AddDescriptions()
	end
end)

if RunService:IsServer() then
	Observer.observe_tag("RandomDevOutfit", function(Model : Model)
		--[[
			A rig tagged inside StarterGui exists twice as far as the server is
			concerned: the copy sitting there, and the clone PlayerGui takes of
			it per player, tag and all. Dressing both is what shows up as the
			outfit being applied twice, with the second roll landing on top of
			the first.

			The clone is the one anyone actually looks at, so skip the template
			and let each player get their own roll.
		--]]
		if Model:IsDescendantOf(StarterGui) then return end

		local Developer : HumanoidDescription = Appearances.GetRandomDeveloper()

		if Developer then
			local Humanoid : Humanoid = Model:FindFirstChild("Humanoid")

			if Humanoid then
				Humanoid:ApplyDescriptionAsync(Developer)
			end
		end
	end)
end

return Appearances
