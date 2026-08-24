--[[
	DeleteRemovedInstances

	Paste into the Studio command bar, with the place open, to delete every
	instance this repository's strip-down removed.

	It runs as a DRY RUN by default: it reports what it would delete and what it
	could not find, and changes nothing. Read that output, then set DRY_RUN to
	false and run it again.

	SAVE A COPY OF THE PLACE FIRST. This deletes about ninety subtrees, each with
	everything inside it -- scripts, models, particles, sounds. Undo is not a
	backup.

	What it does NOT cover: this list was built from a Rojo export, which holds
	only scripts. Instances with no script inside them are invisible to it --
	animation folders, NPC models, GUIs, ServerStorage assets, remotes. Those are
	listed at the end of studio/MIGRATION.md and have to be deleted by hand.
--]]

local DRY_RUN = true

----------------------------------------------------------------------------------

local TARGETS = {
	{ "ReplicatedStorage", "BuildTools" },
	{ "ReplicatedStorage", "Domains" },
	{ "ReplicatedStorage", "Effects", "Characters", "Mori" },
	{ "ReplicatedStorage", "Effects", "Characters", "Reigen" },
	{ "ReplicatedStorage", "Modules", "BossBar" },
	{ "ReplicatedStorage", "Modules", "Player", "Character", "Combat", "UI", "Icons", "Characters" },
	{ "ReplicatedStorage", "Modules", "Player", "Character", "Combat", "UI", "Icons", "JoinMainPlace" },
	{ "ReplicatedStorage", "Modules", "Player", "Character", "Combat", "UI", "Icons", "JoinRankedLobby" },
	{ "ReplicatedStorage", "Modules", "Player", "Character", "Combat", "UI", "Icons", "JoinVCServer" },
	{ "ReplicatedStorage", "Modules", "Player", "Character", "Movement", "Handlers", "Hornet" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Accelerator" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Anubis" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Edgerunner" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Garou" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Gebura Red Mist" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Gojo" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Hornet" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "invincible" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Items" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Jimpee" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "kratos" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Meaty Michael" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Mori" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Oops" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Powers" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Reigen" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Stardust Crusader" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Steve" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Universal" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "Walter" },
	{ "ReplicatedStorage", "Modules", "Player", "Replication", "VFX", "WorldEvents" },
	{ "ReplicatedStorage", "ServerBrowser" },
	{ "ServerScriptService", "Scripts", "BuildHandler" },
	{ "ServerScriptService", "Scripts", "DomainHandler" },
	{ "ServerScriptService", "Scripts", "Game", "GlobalQueueHandler" },
	{ "ServerScriptService", "Scripts", "Game", "MatchManager" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Arcade" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "CharaSpawner" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "EventSystemHandler" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "GlobalQueue" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "ItemSpawnHandler" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "MainTeleporter" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Accelerator" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Anubis" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Edgerunner" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Garou" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Gebura Red Mist" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Gojo" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "invincible" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Items" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Jimpee" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "kratos" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Meaty Michael" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Mori" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Powers" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Reigen" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Stands" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Stardust Crusader" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Steve" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Universal" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Attacks", "List", "Walter" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Accelerator" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Anubis" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Edgerunner" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Garou" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Gebura Red Mist" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Gojo" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Hornet" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "invincible" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Jimpee" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "kratos" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Meaty Michael" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Mori" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "None" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Reigen" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Stardust Crusader" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Steve" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "Player", "Character", "Combat", "Characters", "Walter" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "RankedTeleporter" },
	{ "ServerScriptService", "Scripts", "Game", "Modules", "VCServerTeleporter" },
	{ "ServerScriptService", "Scripts", "HostHandler" },
	{ "ServerScriptService", "Scripts", "TeleportToBattleRoyale" },
	{ "StarterGui", "TesterWatermark" },
	{ "Workspace", "NPC's", "Black Market Dealer" },
	{ "Workspace", "NPC's", "BruhSalino" },
	{ "Workspace", "NPC's", "FadeUnchanged" },
	{ "Workspace", "NPC's", "HW5567" },
	{ "Workspace", "NPC's", "Jade" },
	{ "Workspace", "NPC's", "Jimpee" },
	{ "Workspace", "NPC's", "Mymy32100" },
	{ "Workspace", "NPC's", "News Boy" },
	{ "Workspace", "NPC's", "Sketch" },
	{ "Workspace", "NPC's", "TheCookieGuy" },
	{ "Workspace", "NPC's", "Tough" },
	{ "Workspace", "NPC's", "Wellworks" },
	{ "Workspace", "TesterPlate" },}

----------------------------------------------------------------------------------

--[[
	Walks a path of instance names.

	Returns the instance, or nil plus the segment index that could not be found,
	so a partial match can say where it stopped rather than just "missing".
--]]
local function Resolve(Path: { string }): (Instance?, number?)
	local Cursor: Instance

	if Path[1] == "Workspace" then
		Cursor = workspace
	else
		local Ok, Service = pcall(game.GetService, game, Path[1])

		if not Ok or not Service then
			return nil, 1
		end

		Cursor = Service
	end

	for Index = 2, #Path do
		local Child = Cursor:FindFirstChild(Path[Index])

		if not Child then
			return nil, Index
		end

		Cursor = Child
	end

	return Cursor
end

local function Describe(Path: { string }, Upto: number?): string
	local Segments = {}

	for Index = 1, (Upto or #Path) do
		table.insert(Segments, Path[Index])
	end

	return table.concat(Segments, ".")
end

----------------------------------------------------------------------------------

local Found, Missing = {}, {}

for _, Path in TARGETS do
	local Instance, FailedAt = Resolve(Path)

	if Instance then
		table.insert(Found, { Path = Path, Instance = Instance })
	else
		table.insert(Missing, { Path = Path, FailedAt = FailedAt })
	end
end

print(("=== %d of %d targets found ==="):format(#Found, #TARGETS))

for _, Entry in Found do
	local Count = #Entry.Instance:GetDescendants()
	print(("  %s  (%s, %d descendants)"):format(Describe(Entry.Path), Entry.Instance.ClassName, Count))
end

if #Missing > 0 then
	print(("\n=== %d not found ==="):format(#Missing))

	-- Already deleted, renamed, or never there. Worth reading: a path that stops
	-- early means the parent is missing too, which usually means it moved.
	for _, Entry in Missing do
		print(("  %s   (stopped at \"%s\")"):format(Describe(Entry.Path), Entry.Path[Entry.FailedAt]))
	end
end

if DRY_RUN then
	print("\nDRY RUN -- nothing was deleted. Set DRY_RUN = false to apply.")
	return
end

local Deleted = 0

for _, Entry in Found do
	local Ok, Problem = pcall(function()
		Entry.Instance:Destroy()
	end)

	if Ok then
		Deleted += 1
	else
		warn(("failed to delete %s: %s"):format(Describe(Entry.Path), Problem))
	end
end

print(("\nDeleted %d of %d."):format(Deleted, #Found))
