local replicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local network = require( replicatedStorage.modules.network )

local Icon = require( replicatedStorage.packages.Icon )
local InfoCharacter = require( replicatedStorage.modules.client.character.InfoCharacter )

local FALLBACK_IMAGE = "85316557846229"

local function Entry(Name: string, Info: {})
	return Icon.new()
		:setLabel(Info.DisplayName or Name)
		:oneClick()
		:bindEvent("selected", function()
			SoundService.GUI.BasicOpen:Play()
			network.switchCharacter.send({ character = Name })
		end)
end

return function()
	local Root = Icon.new()
		:setLeft()
		:setImage(FALLBACK_IMAGE)
		:setOrder(2)
		:setLabel("Characters")

	Root.name = "Characters"

	-- The server only sends what this player can use, so everything received
	-- gets an entry.
	InfoCharacter.OnCharactersReady(function(List)
		local Names = {}

		for Name in List do
			table.insert(Names, Name)
		end

		table.sort(Names, function(A, B)
			return (List[A].DisplayName or A) < (List[B].DisplayName or B)
		end)

		local Entries = {}

		for _, Name in Names do
			table.insert(Entries, Entry(Name, List[Name]))
		end

		Root:setDropdown(Entries)
	end)

	return Root
end
