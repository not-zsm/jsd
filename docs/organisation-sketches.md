# Reorganising the tree

Three ways to lay this out, with what each costs. Measured against the export at
`9391383`.

## What the current layout actually is

```
ReplicatedFirst          1 file        57 lines
ReplicatedStorage      462 files   89,747 lines     ← 75% of the codebase
ServerScriptService    112 files   31,818 lines
ServerStorage            0 files        0 lines     ← empty
StarterGui               8 files      695 lines
StarterPlayer           39 files   11,338 lines
Workspace               11 files      427 lines
```

Two things stand out.

**ServerStorage is unused, and ReplicatedStorage is doing everything.** Every one
of those 89,747 lines replicates to every client on join. Some of it must —
that is what shared code is for — but not all of it.

**ServerScriptService is 96% library.** Of its 112 files, four are actual server
entry points (`Game`, `Game/ProductHandler`, `Game/Modules/Weather/Init`,
`Game/Modules/Player/Character/Title/Gui/Gradient`). The other 108 are
ModuleScripts sitting in the service whose job is to *run scripts*.

Across the whole tree: 42 entry-point Scripts, 592 ModuleScripts.

### Which side actually needs what

`tools/reachability.py` seeds from the scripts each side runs, follows requires
(including `script.X`, local aliases and `WaitForChild` chains), and adds the two
trees the engine loads by name instead of by require — VFX, and the attack and
character folders.

```
       both:  41 files,   8,155 lines    genuinely shared
client only: 237 files,  44,946 lines    replicated because the client needs it
server only:  16 files,   5,669 lines    replicated for no reason
    neither: 168 files,  31,439 lines    not reached from either entry point
```

The 16 server-only files in ReplicatedStorage are the concrete, uncontroversial
win — nothing on the client touches them:

```
Havoc/DebrisPool, Havoc/PartCache, Havoc/Settings
Modules/Preloading
Modules/Shared/Commands/UserRoles
Modules/Shared/Game/Gamepasses/{init, GroupRankGamepasses, HasGamepassOffline}
Modules/Shared/Game/Hitbox/Type/Sphere/{init, Params}
Modules/Shared/Game/TitleData
Packages/Serialise/{init, Base91, LibDeflate}
Packages/Type
Projectiles/Util, Projectiles/Projectiles/BaseSaucer
```

Treat "neither" as *unproven*, not *dead* — it is mostly `Modules/Shared` (97
files, of which SmartBone is 67) and `Modules/Player` (44). Some is reached by patterns
the tool cannot follow; some is genuinely orphaned. Worth a pass, not a delete.

### Paths are long

```
ServerScriptService/Scripts/Game/Modules/Player/Character/Combat/Attacks/List/Chara/Onslaught
ReplicatedStorage/Modules/Player/Character/Combat/UI/DialogueManager/DialogueSystem/Configuration
```

`Scripts/Game/Modules/` carries no information — every server module is under it.
`Modules/Player/` likewise.

---

## Sketch A — Role-first

Each service gets one job, which is the convention you already reached for.

```
ServerScriptService/          entry points only, ~6 Scripts
    Boot.server.luau
    ProductHandler.server.luau

ServerStorage/Source/         the server library
    Combat/                   engine, attacks, characters, hitbox, ragdoll
    Players/                  LuaPlayer, Data, Emotes
    World/                    Havoc, MovementReplicator, NPCs, Weather

ReplicatedStorage/
    Info/                     the global config
    Shared/                   things both sides reach (41 files today)
    Client/                   things only the client reaches (237 files)
    Packages/                 third-party

StarterPlayer/StarterPlayerScripts/
    Boot.client.luau          entry point; the library lives in RS/Client
```

**Why:** the question "can the client see this?" is answered by which service it
is in, not by reading requires. Server logic in ServerStorage cannot leak to
exploiters at all. Entry points are six files you can read in a sitting.

**Cost:** the combat engine moves from ServerScriptService to ServerStorage,
which means every absolute require to it changes — and attack modules each carry
a hardcoded `ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack`.
That is a find-and-replace across 26 files, mechanical but wide.

**Watch out:** `RS/Client` still replicates. Putting client code there is about
clarity, not secrecy — anything in ReplicatedStorage is readable by exploiters
regardless of the folder name.

---

## Sketch B — Domain-mirrored

Same top-level names inside each service, so one feature reads the same way
wherever you are.

```
ServerStorage/Source/Combat/        engine, attacks, characters
ReplicatedStorage/Shared/Combat/    types, config, hitbox params
ReplicatedStorage/Client/Combat/    client combat, VFX, UI
```

and the same for `Players`, `World`, `Effects`.

**Why:** best for modding. Someone changing combat sees three folders with one
name, and the boundary between them is the client/server boundary. Adding a
domain means adding one folder in three places.

**Cost:** more moving than A, and the same name in three services can confuse
Studio search — you will get three `Combat` hits and have to read the path.

**Note:** true domain-first (one `Combat` folder holding server, client and
shared) is not expressible in Studio. The datamodel forces the service split, so
mirroring is as close as you get without a Rojo-driven workflow.

---

## Sketch C — Minimal

Keep the service layout. Fix three things.

1. **Move the 16 server-only modules to ServerStorage.** Listed above. Nothing on
   the client requires them, so this is a move plus a require rewrite per file.
2. **Collapse the dead path segments.** `ServerScriptService/Scripts/Game/Modules/X`
   becomes `ServerScriptService/Modules/X`; `ReplicatedStorage/Modules/Player/X`
   becomes `ReplicatedStorage/Client/X`. Two levels off every path.
3. **Separate entry points from library** inside each service — a `Scripts` folder
   holding only the 42 Scripts, everything else under `Modules`.

**Why:** each step is independently shippable and independently revertible. You
can do (1) this week and never do (2).

**Cost:** you keep a layout that grew rather than one that was chosen. It gets
better, not right.

---

## Where Info goes

As a large global config both sides read, it belongs in ReplicatedStorage in all
three sketches, near the top:

```
ReplicatedStorage/Info/
    init.luau           re-exports children; the only thing anything requires
    Places.luau         place ids, the IsX flags derived from them
    Combat.luau         default character, m1 defaults, cooldowns, damage caps
    Movement.luau       dash, vault, wallrun tunables
    Effects.luau        vignette and pulse presets, shake defaults
    Movesets/           one child per character
```

One constraint worth fixing now: **`Info` must not require anything from combat.**
If the combat engine requires `Info` — which it will — and `Info` requires a
moveset that requires `BaseAttack`, that is a cycle. Movesets under `Info` have
to stay pure data, or live outside it.

The free first step in any sketch: move the nine `shared.*` keys into
`Info.Places` and `Info.Combat`, and delete `GlobalSettings.luau`, which nothing
requires and whose `PlaceIds` have already drifted from the boot script's.

---

## Recommendation

**C first, then A.** The 16-file move and the path collapse are cheap, verifiable
and useful whichever end state you pick — and they are the two changes that make
the tree readable enough to judge the rest. A is the right end state for a
framework other people mod; B is A plus a naming convention, worth adopting only
if you find yourself repeatedly hunting for the other half of a feature.

Whatever you pick, do it in one sitting per step and re-export. `tools/check_requires.py`
catches a broken require immediately; a half-finished move that sits for a week
is how a tree ends up with `Scripts/Game/Modules/Player/Character/Combat`.
