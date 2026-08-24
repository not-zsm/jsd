# Workflow

## Repo and place

The repo holds **scripts**. The `.rbxlx` holds **everything else** — models,
animations, GUIs, VFX assets. The two are kept in step by hand.

Studio exports one way, in Rojo format, scripts only.

- `X.luau` beside `X/` is a parent module. **Not** `X/init.luau` —
  `UI/Icons/init.luau` is the single exception.
- `.server.luau` is a `Script`, `.client.luau` a `LocalScript`, `.luau` a
  `ModuleScript`.
- `.meta.json` carries `className` for non-script instances that contain scripts.

## The tools

| Tool | What it does |
| --- | --- |
| `tools/graft.py` | Moves subtrees between places, syncs script sources from the repo, validates on the way out. |
| `tools/adopt.py` | Diffs an uploaded place against the repo and writes the differences back. Run **without** `--apply` first. |
| `tools/rename.py` | Renames instances by dotted path. Errors rather than skipping on an ambiguous path. |
| `tools/setprop.py` | Sets one property on one instance. Refuses to invent a property that was not serialised. |
| `tools/check_requires.py` | Resolves every `require` against the tree. Baseline is two unresolved, both vendored test files. |
| `tools/fix_services.py` | Finds services used but not declared, and declared but not used. |

## Adding a character, end to end

1. Write `ServerStorage/characterData/<name>.luau`.
2. Write the move modules under `Attacks/List/<name>/`.
3. Write the VFX modules under `replication/VFX/<name>/`.
4. In Studio, add the animation folders (see [characters.md](characters.md)) and
   the VFX assets, then export.
5. Adopt the export, verify, commit.

## Verification, every time

Before anything ships:

```bash
# every file compiles
find . -name "*.luau" -not -path "./.git/*" | while read f; do luau-compile --binary "$f" >/dev/null || echo "FAIL $f"; done

# every require resolves (baseline: 2 unresolved, both vendored)
python3 tools/check_requires.py

# no service used without being declared
python3 tools/fix_services.py --check
```

Then for the place: script parity, all four `validate()` checks, and an instance
count for anything grafted. **Re-run the validation on the zip after unzipping
it** — that catches packaging mistakes the in-memory tree never sees.

## Gotchas that have actually bitten

### Graft order

`graft.py` syncs sources **before** it grafts, and syncing creates any script the
repo has and the place lacks. Add a character's files to the repo first and the
graft will find bare ModuleScripts already sitting at the destination, report
`[already present]`, and skip the entire subtree — models, VFX assets and all.

**Graft first with the new files held out of the repo, then put them back and run
a source-only second pass.** The Kratos port lost 6,305 instances to this before
an instance count caught it.

### Renaming an instance the code reaches by name

If you rename a folder or model, every `script.X` and `Parent.X` that reached it
has to move at the same time — and so does the instance in the place. Renaming
one without the other gives a nil index at runtime with no compile error.

The safe check: after a rename, scan the place for any instance still carrying
the old name, until the count is zero.

### Deleting a script from the repo

`sync_sources` **never deletes**. Remove a script from the repo and the instance
stays in the place as an orphan. Use `graft.py --deletes` with its dotted path.

### The service-declaration trap

A script that uses `ServerStorage.something` without declaring
`local ServerStorage = game:GetService("ServerStorage")` compiles fine and throws
at require time. `fix_services.py --check` catches it.

Note that it picks a name by the file's prevailing case, so check its suggestion
before applying — this repo writes `replicatedStorage` lowercase but
`ServerStorage` capitalised.

### Anything the server sends once, at join

It will be dropped if the client has not finished requiring byteNet. Add it to
the `clientReady` replay. See [overview.md](overview.md).

## Packets

Every packet lives in `ReplicatedStorage/modules/network.luau` — 105 of them,
one byteNet namespace.

Adding one is a `byteNet.definePacket` in that file, a listener in
`ServerScriptService/networker.server.luau` if it is client-to-server, and a
`.listen` on the client if it is the other way.

> **Do not reorder or remove packets casually.** Packet ids are assigned by
> definition order, and the id is a `uint8` — a client and server that disagree
> on the order will route messages to the wrong handler. Add at the end.

Types: `string`, `bool`, `uint8/16/32`, `int8/16/32`, `float32/64`, `vec2`,
`vec3`, `cframe`, `cframeQ16`, `inst`, `buff`, `unknown`, `optional`, `nothing`,
`struct`, `array`, `map`.

`reliabilityType = "unreliable"` for per-frame streams where a dropped packet
costs nothing.
