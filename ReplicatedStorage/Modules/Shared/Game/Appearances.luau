local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Appearances = {}
local DeveloperDescriptions = {} :: {HumanoidDescription}

function Appearances.GetRandomDeveloper() : HumanoidDescription
	return DeveloperDescriptions[math.random(1, #DeveloperDescriptions)]
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

AddDescriptions()

task.spawn(function()
	while task.wait(30) do
		AddDescriptions()
	end
end)

if RunService:IsServer() then
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Observer = require( ReplicatedStorage.Packages.Observer )

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
