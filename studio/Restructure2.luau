--[[
	Moves clientCombat and serverCombat, and adds info.

	Paste into the command bar. DRY RUN by default -- read the output, then set
	DRY_RUN to false. Save a copy of the place first.

	Scripts whose source changed are NOT rewritten here; there are 36 of them and
	the repo is the verified copy. After running this, sync sources from the repo
	(or just open the .rbxlx I generate alongside it).
--]]

local DRY_RUN = true

local MOVES = {
	{ { "ReplicatedStorage", "Client", "Character", "Combat" },           { "ReplicatedStorage" }, "clientCombat" },
	{ { "ServerScriptService", "Modules", "Player", "Character", "Combat" }, { "ServerStorage" },  "serverCombat" },
}

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

print("=== moves ===")

local Pending = {}

for _, Move in MOVES do
	local Source, FailedAt = Resolve(Move[1])
	local Label = table.concat(Move[1], ".")

	if not Source then
		print(`  [not found] {Label}  (stopped at "{Move[1][FailedAt]}")`)
		continue
	end

	local Destination = Resolve(Move[2])
	print(`  {Label}  ->  {table.concat(Move[2], ".")}.{Move[3]}`)
	table.insert(Pending, { Source = Source, Destination = Destination, Name = Move[3] })
end

if DRY_RUN then
	print("\nDRY RUN -- nothing changed. Set DRY_RUN = false to apply.")
	return
end

for _, Entry in Pending do
	Entry.Source.Name = Entry.Name
	Entry.Source.Parent = Entry.Destination
end

print(`\nMoved {#Pending}.`)
print("Now sync script sources from the repo -- 36 files changed, including the")
print("two require(script.Combat) call sites in Character on each side.")
