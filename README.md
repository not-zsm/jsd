# JSD

A Roblox battleground: the combat system, one character, and the systems that
character needs.

## Layout

| Path | What lives there |
| --- | --- |
| `ServerScriptService/Scripts/Game/Modules/Player/Character/Combat` | the combat engine, plus Chara and the shared moves |
| `ReplicatedStorage/Modules/Player` | client character, camera, movement, replication and VFX |
| `ReplicatedStorage/Modules/Shared` | code both sides need |
| `ServerScriptService/Scripts/HavocHandler`, `ReplicatedStorage/Havoc` | map destruction |
| `ServerScriptService/Scripts/MovementReplicator`, `ReplicatedStorage/MovementReplicator` | movement replication |
| `ServerScriptService/Scripts/Game/Modules` | players, data, NPCs, emotes, leaderboards, commands |
| `tools/check_requires.py` | resolves every `require` in the tree against the files that exist |

The tree mirrors the Roblox datamodel and is meant to be synced with Rojo.
`default.project.json` is not committed, so the mapping to the datamodel lives
only on whoever's machine last synced it.

## Combat

`Combat/init.luau` is the engine: hitboxes, block and parry validation, i-frames,
counters, ragdolls, stuns, grabs, velocity, animation routing, move buffering and
replication. `Attacks/BaseAttack.luau` is the base class every move inherits.

`Attacks/List/Global` holds the moves every character gets — M1, Block, Dash,
Vault, WallRun, Ultimate. `Attacks/List/Chara` holds Chara's kit. The folder a
move sits in is how the engine decides which character it belongs to.

## Adding a character

Write a definition in `Combat/Characters/<Name>.luau`. The only required field is
`Attacks`, a map of move name to keybind:

```lua
return {
	Attacks = {
		["Your Move"] = Enum.KeyCode.One,
	},
}
```

Then write each move in `Combat/Attacks/List/<Name>/<Your Move>.luau`, inheriting
from `BaseAttack`. Look at `Attacks/List/Chara/Onslaught.luau` for a worked
example. No engine file needs editing.

Chara is the default character — `Combat:SetCharacter` falls back to it when a
player has no saved character.

## Applying changes to the place

This repository is a one-way export from Studio: it holds scripts and nothing
else. The place cannot be rebuilt from it, and syncing it back would replace
your scripts while leaving them with nothing to operate on.

`studio/MIGRATION.md` is the procedure for applying the strip-down to a place by
hand, and `studio/DeleteRemovedInstances.luau` is a command-bar script that
deletes the instances it removed.

## Cleanup in progress

`docs/module-inventory.md` is the current audit: which modules are genuinely
duplicated, which only look duplicated because of the client/server split, what
is dead, and a sketch for the centralised `Info` module.

## Checking the tree

```sh
tools/check_requires.py .
```

Prints every `require` that does not resolve to a module in the tree. Two are
expected: test stubs inside `ReplicatedStorage/Packages/Des` that point at a
test runner this game does not have.

```sh
tools/module_inventory.py [keyword]
```

Lists modules with their line count and how many files require them. Note that
attacks and VFX show zero users because the engine resolves them by name rather
than by `require`.
