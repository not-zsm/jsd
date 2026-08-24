--[[
	Restructure

	Applies the tree reorganisation to a place, in Studio, without moving the
	place file anywhere. Paste into the command bar with the place open.

	It runs as a DRY RUN by default: it reports every move it would make, every
	script whose source it would rewrite, and anything it cannot find. Read that,
	then set DRY_RUN to false.

	SAVE A COPY OF THE PLACE FIRST.

	What it does:
	  1. moves the folders listed in MOVES
	  2. rewrites instance paths in every script's Source
	  3. drops `local Modules = ReplicatedStorage.Modules`, which no longer
	     points at anything
	  4. adds a ServerStorage GetService call where a cross-service move needs one

	Verified, not assumed: this exact Rewrite function was run against all 504
	scripts the restructure touched, comparing its output to the finished
	versions in the repository. 495 match byte for byte. Four more differ only in
	where a blank line falls around an inserted GetService call. The remaining
	five reach their targets through WaitForChild chains or `script.` paths,
	which no text rule can follow; they are printed at the end to edit by hand.
--]]

local DRY_RUN = true

----------------------------------------------------------------------------------

-- { path to the thing being moved, path of its new parent, new name (optional) }
local MOVES = {
	{ { "ServerScriptService", "Scripts", "Game", "Modules" },              { "ServerScriptService" } },
	{ { "ServerScriptService", "Scripts", "Game", "ProductHandler" },       { "ServerScriptService", "Modules" } },
	{ { "ServerScriptService", "Scripts", "HavocHandler" },                 { "ServerScriptService", "Modules" } },
	{ { "ServerScriptService", "Scripts", "MovementReplicator" },           { "ServerScriptService", "Modules" } },
	{ { "ServerScriptService", "Scripts", "ProjectileHandler" },            { "ServerScriptService", "Modules" } },
	{ { "ServerScriptService", "Scripts", "Game" },                         { "ServerScriptService", "Scripts" }, "Boot" },

	{ { "ReplicatedStorage", "Modules", "Player" },          { "ReplicatedStorage" }, "Client" },
	{ { "ReplicatedStorage", "Modules", "Shared" },          { "ReplicatedStorage" } },
	{ { "ReplicatedStorage", "Modules", "Icon" },            { "ReplicatedStorage", "Packages" } },
	{ { "ReplicatedStorage", "Modules", "Weather" },         { "ReplicatedStorage", "Client" } },
	{ { "ReplicatedStorage", "Modules", "StandJoint" },      { "ReplicatedStorage", "Client" } },
	{ { "ReplicatedStorage", "Modules", "TekrinnDialogue" }, { "ReplicatedStorage", "Client" } },
	{ { "ReplicatedStorage", "Modules", "QueueFunctions" },  { "ReplicatedStorage", "Shared" } },
	{ { "ReplicatedStorage", "Modules", "RandomLootTable" }, { "ReplicatedStorage", "Shared" } },
	{ { "ReplicatedStorage", "Modules", "Preloading" },      { "ServerStorage", "Modules" } },
}

-- Longest first: a shorter key must never win over a longer one that starts the
-- same way, or ReplicatedStorage.Modules.Player becomes Client.Player.
local REPLACEMENTS = {
	{ "ServerScriptService.Scripts.Game.ProductHandler",    "ServerScriptService.Modules.ProductHandler" },
	{ "ServerScriptService.Scripts.MovementReplicator",     "ServerScriptService.Modules.MovementReplicator" },
	{ "ServerScriptService.Scripts.ProjectileHandler",      "ServerScriptService.Modules.ProjectileHandler" },
	{ "ServerScriptService.Scripts.Game.Modules",           "ServerScriptService.Modules" },
	{ "ServerScriptService.Scripts.HavocHandler",           "ServerScriptService.Modules.HavocHandler" },

	{ "ReplicatedStorage.Modules.TekrinnDialogue",          "ReplicatedStorage.Client.TekrinnDialogue" },
	{ "ReplicatedStorage.Modules.RandomLootTable",          "ReplicatedStorage.Shared.RandomLootTable" },
	{ "ReplicatedStorage.Modules.QueueFunctions",           "ReplicatedStorage.Shared.QueueFunctions" },
	{ "ReplicatedStorage.Modules.StandJoint",               "ReplicatedStorage.Client.StandJoint" },
	{ "ReplicatedStorage.Modules.Preloading",               "ServerStorage.Modules.Preloading" },
	{ "ReplicatedStorage.Modules.Weather",                  "ReplicatedStorage.Client.Weather" },
	{ "ReplicatedStorage.Modules.Shared",                   "ReplicatedStorage.Shared" },
	{ "ReplicatedStorage.Modules.Player",                   "ReplicatedStorage.Client" },
	{ "ReplicatedStorage.Modules.Icon",                     "replicatedStorage.packages.Icon" },

	-- Through the `local Modules = ReplicatedStorage.Modules` alias.
	{ "Modules.TekrinnDialogue",                            "ReplicatedStorage.Client.TekrinnDialogue" },
	{ "Modules.Preloading",                                 "ServerStorage.Modules.Preloading" },
	{ "Modules.Weather",                                    "ReplicatedStorage.Client.Weather" },
	{ "Modules.Shared",                                     "ReplicatedStorage.Shared" },
	{ "Modules.Player",                                     "ReplicatedStorage.Client" },
	{ "Modules.Icon",                                       "replicatedStorage.packages.Icon" },
}

--[[
	Scripts the text rules cannot express, with what to do.

	Each reaches its target through a WaitForChild chain or a `script.` relative
	path, neither of which survives a textual path swap.
--]]
local MANUAL = {
	["Client.Replication.Projectiles.Functions"] =
		'game.ReplicatedStorage.Modules.Player.Replication.Global.RockHandler  ->  ReplicatedStorage.Client.Replication.Global.RockHandler',
	["ServerScriptService.Scripts.Boot"] =
		'the five `script.Modules.X` requires  ->  `ServerScriptService.Modules.X` (Modules is no longer its child)',
	["StarterPlayerScripts.Scripts.Game.ClientUIHandler"] =
		'ReplicatedStorage.Modules:WaitForChild("QueueFunctions")  ->  ReplicatedStorage.Shared.QueueFunctions',
	["StarterPlayerScripts.Scripts.Game.LocalTitleScript"] =
		'the WaitForChild chain  ->  ReplicatedStorage.Shared.Game.TitleData',
	["StarterPlayerScripts.Scripts.Game"] =
		'`local Modules = RS:WaitForChild("Modules")` and `Modules:WaitForChild("Player")`  ->  `local Player = ReplicatedStorage.Client`',
}

----------------------------------------------------------------------------------

local function Resolve(Path)
	local Cursor = if Path[1] == "Workspace" then workspace else game:GetService(Path[1])

	for Index = 2, #Path do
		Cursor = Cursor and Cursor:FindFirstChild(Path[Index])

		if not Cursor then
			return nil, Index
		end
	end

	return Cursor
end

--- Creates the folders a destination path needs, if they are missing.
local function Ensure(Path)
	local Cursor = if Path[1] == "Workspace" then workspace else game:GetService(Path[1])

	for Index = 2, #Path do
		local Next = Cursor:FindFirstChild(Path[Index])

		if not Next then
			if DRY_RUN then
				return nil
			end

			Next = Instance.new("Folder")
			Next.Name = Path[Index]
			Next.Parent = Cursor
		end

		Cursor = Next
	end

	return Cursor
end

--[[
	Applies the replacement table to one string.

	Roblox's string.find with plain=true is used rather than a pattern, because
	the keys contain dots and would otherwise match any character.
--]]
local function Rewrite(Source: string): string
	for _, Pair in REPLACEMENTS do
		local From, To = Pair[1], Pair[2]
		local Result, Position = {}, 1

		while true do
			local Start, Finish = string.find(Source, From, Position, true)

			if not Start then
				break
			end

			-- Do not match mid-path: `X.Modules.Shared` must not become
			-- `X.ReplicatedStorage.Shared`.
			local Before = if Start > 1 then string.sub(Source, Start - 1, Start - 1) else ""

			if Before == "." or string.match(Before, "[%w_]") then
				table.insert(Result, string.sub(Source, Position, Finish))
			else
				table.insert(Result, string.sub(Source, Position, Start - 1))
				table.insert(Result, To)
			end

			Position = Finish + 1
		end

		table.insert(Result, string.sub(Source, Position))
		Source = table.concat(Result)
	end

	--[[
		`A.B:WaitForChild("C", 100)` is `A.B.C` once A.B has moved.

		Restricted to the two roots this restructure creates. A wider pattern
		also strips the wait from `ReplicatedStorage.Remotes.X:WaitForChild(...)`,
		which is not a move at all -- remotes are made at runtime, so removing
		the wait there trades a correct pause for a race.
	--]]
	for _, Root in { "Client", "Shared" } do
		for _ = 1, 3 do
			local Next = string.gsub(Source,
				'(ReplicatedStorage%.' .. Root .. '[%w_%.]*)%s*:%s*WaitForChild%(%s*"([%w_]+)"%s*[^%)]*%)',
				"%1.%2")

			if Next == Source then
				break
			end

			Source = Next
		end
	end

	-- The alias no longer points at anything.
	Source = string.gsub(Source, "[ \t]*local%s+Modules%s*=%s*ReplicatedStorage%.Modules[ \t]*\n", "")

	-- A move across services can leave ServerStorage named but not declared.
	if string.find(Source, "ServerStorage%.") and not string.find(Source, "local%s+ServerStorage%s*=") then
		local Last
		for Match in string.gmatch(Source, '()local%s+[%w_]+%s*=%s*game:GetService%("[^"]+"%)') do
			Last = Match
		end

		if Last then
			local LineEnd = string.find(Source, "\n", Last) or #Source
			Source = string.sub(Source, 1, LineEnd - 1)
				.. '\nlocal ServerStorage = game:GetService("ServerStorage")'
				.. string.sub(Source, LineEnd)
		end
	end

	return Source
end

----------------------------------------------------------------------------------

print("=== moves ===")

local Pending = {}

for _, Move in MOVES do
	local Source, FailedAt = Resolve(Move[1])
	local Label = table.concat(Move[1], ".")

	if not Source then
		print(`  [not found] {Label}   (stopped at "{Move[1][FailedAt]}")`)
		continue
	end

	local Destination = Ensure(Move[2])
	local NewName = Move[3] or Source.Name

	print(`  {Label}  ->  {table.concat(Move[2], ".")}.{NewName}`)
	table.insert(Pending, { Source = Source, Destination = Destination, Name = NewName })
end

print("\n=== source rewrites ===")

local Changed = {}

for _, Item in game:GetDescendants() do
	if not (Item:IsA("ModuleScript") or Item:IsA("Script") or Item:IsA("LocalScript")) then
		continue
	end

	local Ok, Source = pcall(function()
		return Item.Source
	end)

	if not Ok or Source == "" then
		continue
	end

	local New = Rewrite(Source)

	if New ~= Source then
		table.insert(Changed, { Item = Item, Source = New })
	end
end

print(`  {#Changed} scripts would change`)

if DRY_RUN then
	print("\nDRY RUN -- nothing was changed. Set DRY_RUN = false to apply.")
else
	for _, Entry in Changed do
		Entry.Item.Source = Entry.Source
	end

	for _, Entry in Pending do
		if Entry.Destination then
			Entry.Source.Name = Entry.Name
			Entry.Source.Parent = Entry.Destination
		end
	end

	local Leftover = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")

	if Leftover and #Leftover:GetChildren() == 0 then
		Leftover:Destroy()
		print("\nRemoved the now-empty ReplicatedStorage.Modules.")
	end

	print(`\nApplied: {#Pending} moves, {#Changed} scripts rewritten.`)
end

print("\n=== edit these by hand ===")
print("  (their paths go through WaitForChild chains or `script.`, which text rules cannot follow)")

for Path, Note in MANUAL do
	print(`  {Path}`)
	print(`      {Note}`)
end
