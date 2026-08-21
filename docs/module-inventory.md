# Module inventory

What is duplicated, what only looks duplicated, and what is dead. Written
against the Studio export at `9391383`.

Chara is going too, so nothing below is chosen for being what Chara happens to
call. Where a pick is obvious it says so; where two implementations are both
defensible it says that instead of guessing.

---

## 1. Leftovers in the export

Your deletions were complete — nothing I removed came back, and you went further
(`Icon-Old`, `BrokenPopper`, `OldDialogue`, `AenoirEmitOld`, the `*Old` VFX
variants, `CharacterWhitelists_old`, `BufferUtilOld`/`OldOld`, `OldIndicator`,
`ProfileStoreBackup`, `UnusedForNow`). 634 files compile, and the only
unresolved requires are the two pre-existing test stubs in `Packages/Des`.

Six live references to removed content survive. Only the first is worth fixing
now.

**`Combat/Passives/Kills.luau` — still the original file.** Passives for Gojo,
Accelerator, Kratos, Meaty Michael and Anubis, including the
`Attacks["Adapt"]` lookup and two `FireReliableVFX("Anubis/Adapt", …)` calls.
This is the Anubis reference you hit; the fix did not reach this file, or
reached Studio after you exported. It cannot fire today — `Combat` looks up
`Passives.Kills[CurrentCharacter.Name]` and no key matches — but it is a live
landmine for whoever adds a character named in it.

The rest are dead branches that cost nothing and cannot fire:

| Where | What |
| --- | --- |
| `Combat/init.luau` 1809–1831 | `CanDamageAI` / `CanGainKills` still name Invincible, Meaty Michael, Walter, Gebura Red Mist |
| `Data/init.luau:110` | profile template defaults `CurrentCharacter = "Gojo"`. Harmless — `CanUseCharacter` rejects it on spawn and rewrites to Chara — but every new profile is written wrong then corrected |
| `DonationBoardServer:235` | `SetCharacter("Gojo")`, reachable only for a character with `DonatorAccess`, of which there are none |
| `Emotes/init.luau:285` | `Attacks["Anubis Weapon"]`, nil-guarded |
| client `Combat` 331/655, `VFX/Global/Block:36`, `VFX/Global/M1:72,155` | name checks for Anubis, Hornet, Gojo, Edgerunner |
| `AttackFunctions/Stands/Stand FrontDash:62` | loads `Animations.Attacks["Stardust Crusader"]` — **would error** if reached, but no character has a stand |

---

## 2. Real duplication

### Tweening — 2 identical copies, ~2,800 lines

`BoatTween` exists twice, byte for byte, with all four of its files:

```
Modules/Player/Replication/Global/Dojyan_Util/BoatTween/
Modules/Player/Replication/VFX/Chara/Atonement/quickutil/BoatTween/
```

The single largest win in the tree. One copy, somewhere neutral.

### VFX emitters — 4 distinct things wearing similar names

| Module | Lines | What it actually is |
| --- | --- | --- |
| `EffectUtility` | 622 | the general one: `Emit`, `CloneAndEmit`, `EmitEffects`, toggles, sound handling |
| `AenoirEmit` | 456 | sequence-scaling emitter — lerps NumberSequences, scales light range |
| `MeshEmit` ×5 | 129–156 | tween-a-mesh helper. Copies at 70–95% similarity |
| `Yuki_Emit` | 119 | byte-identical to `Emotes/Love Train/Modules/EffectUtility` |

`MeshEmit`'s five copies are the copy-paste-and-tweak pattern:

```
Global/Dojyan_Util/MeshEmit.luau                      155   (reference)
VFX/Chara/Atonement/quickutil/MeshEmit.luau           156   95% like it
VFX/Chara/Ultimate_Alt/quickutil/MeshEmit.luau        143   72%
VFX/Chara/Seven Souls/quickutil/MeshEmit.luau         143   72%
VFX/Emotes/The Final Showdown/MeshEmit.luau           129   70%
```

The 72% ones have drifted, so merging means reading the diffs rather than
deleting four files. `quickutil` itself is duplicated the same way — 614 lines
in Atonement, 99 in each of Ultimate_Alt and Seven Souls.

`EffectUtility` and `AenoirEmit` genuinely do different jobs. Whether that stays
two modules or becomes one with a sequence-scaling mode is a design call.

### Screen effects — 2 modules, same job

`Vignette` and `ScreenPulse` both fade an image on `PlayerGui.FXScreen`, both
respect `Epileptic_Mode`, both take a `Small` flag choosing `FXScreen.SmallPulse`
over `FXScreen.Pulse`. The only difference is the signature — `Vignette` takes
`(Color, StartTransparency, FadeTime, Smaller)`, `ScreenPulse` takes
`(PresetName, Small)` — and their preset tables were near-identical before the
strip-down.

One module taking either a preset name or an explicit table.

### Signals — 4 implementations

| Module | Lines | Used by |
| --- | --- | --- |
| `Shared/Utilities/EventService` | 79 | 36 files |
| `Packages/Signal` | 238 | 21 files |
| `Icon/Packages/GoodSignal` | 182 | 3 files (Icon only) |
| `Packages/Des/_Index/sleitnick_signal` | 432 | 2 files |

`EventService` is the house one and the most used. `GoodSignal` and the Des copy
are vendored dependencies of `Icon` and `Des` — leave those alone unless you drop
those libraries.

### Cleanup / lifetime — 4 implementations

| Module | Lines | Used by |
| --- | --- | --- |
| `Shared/Utilities/Job` | 134 | 54 files |
| `Packages/Maid` | 422 | 21 files |
| `Icon/Packages/Janitor` | 322 | 3 (Icon only) |
| `Packages/Des/_Index/sleitnick_trove` | 613 | 2, and it is vendored **twice** — 1.5.0 and 1.5.1 |

`Job` is the house one by a wide margin. `Maid`'s 21 users are the real decision.
Dropping trove 1.5.0 is free.

### Hitboxes — 3

| Module | Lines | What |
| --- | --- | --- |
| `Shared/Game/Hitbox` | 185 + Box/Sphere/Touch types | the general one, shared |
| `Combat/Hitbox` | 221 | server combat's own, wraps the above |
| `Shared/Utilities/RaycastHitbox` | 233 across 4 files | third-party, used once |

The first two are a front-door/engine pair like camera shake, not duplication.
`RaycastHitbox` is the odd one out.

### Part pooling — 3

`Havoc/PartCache` (186), `Packages/InstanceCache` (153),
`RaycastHitbox/VisualizerCache` (62). Three answers to one question, one user
each.

### Projectiles — 3 trees

`ReplicatedStorage/Projectiles/ProjectileHandler` (142) and
`ServerScriptService/Scripts/ProjectileHandler` (113) are 57% similar — a
client/server pair that drifted. `Combat/Projectiles` (58) is a third.
`Projectile.luau` exists at all three paths.

### Smaller ones

- `Observer` — `Shared/Utilities/Observer` (81) vs `Packages/Observer` (128), both used.
- `Sorting` — `Hitbox/Sorting` (45) vs `AI/Detection/Sorting` (64), 68% similar.
- `Ragdoll/Data.luau` — byte-identical under `MovementReplicator/Lib` and `Combat/Ragdoll`.
- `Blood` / `Blood_Rainbow` — identical `Presets.luau`; the second is a recolour.
- `Thumbstick` — `Des/Chara` vs `Des/Arcade`, 43% similar.
- `GlobalSettings.luau` — required by nothing, and its `PlaceIds` duplicates `shared.PlaceIds` with `MainVC = nil` where the boot script has a real id. Already drifted, already dead.

---

## 3. Not duplicates — leave these alone

83 module names appear at more than one path, but most are the client/server
split working as intended: `Combat`, `Character`, `Player`, `Dash`, `WallRun`,
`Vault`, `M1`, `Block`, `Ultimate`, `Quicktime`, `Mouse`, `Emotes`,
`Destruction`, `Replicant`. Same name, 2–10% similar, different sides.

Every Chara move has the same shape — `VFX/Chara/Bloody Mary` (494 lines,
client) against `Attacks/List/Chara/Bloody Mary` (309, server). That is the
convention, not a mistake.

Camera shake reads like three implementations and is not:

```
Global/CameraShake.luau          27 lines, 43 users   the front door
Shared/Utilities/CameraShaker/  247 lines,  1 user    the engine behind it
Des/Chara/Shake.luau            195 lines             Atonement's own
```

`CameraShake` sets up one `CameraShaker`, honours `CannotCameraShake` and the
`Camera_Shake` setting, and exposes a single function. That layering is right.
Only `Des/Chara/Shake` is a separate thing, and it goes with Chara.

**Caveat on the numbers:** attacks and VFX modules show "0 users" because the
engine finds them by name — `GetAttackModule`, `FireReliableVFX` — not by
`require`. Do not read a zero there as dead.

---

## 4. Dead weight

- **`Des/Arcade`** — 5,628 lines of Tetris, PacMan, Minesweeper and Pong, loaded
  by `Des/init.client.luau`. Its server module was deleted with the arcade. It
  belongs to Chara's Atonement minigame, so it goes when Chara does.
- **`Des/Chara`** — 11 files, same story.
- **`SmartBone`** — live: `StarterPlayerScripts/Game/SmartBone.client.luau`
  starts it. Not dead, but it vendors a whole Iris debug UI and a Gizmo
  library, which is where several of the duplicate `Box`, `Sphere`, `Text` and
  `Table` names come from. Those are its own, not yours.
- **`Packages/Des/_Index`** — vendored Wally packages including `init.spec` and
  `init.test` files and two versions of trove.

---

## 5. The centralised Info module

Globals live in three places today: `shared.*` set by the boot script, the dead
`GlobalSettings.luau`, and constants inlined wherever they are used.

```
shared.IsTestPlace     12 uses      shared.PlayerStore      4
shared.FrameCounter     8           shared.Group            3
shared.IsRankedPlace    6           shared.IsVCPlace        2
shared.PlaceIds         5           shared.TesterPlaceId    1
shared.IsRankedLobby    5
```

`shared` is a poor home: no types, no autocomplete, load-order dependent, and
anything in the game can overwrite a key. A ModuleScript fixes all four.

Suggested shape, as a folder so it can grow child modules:

```
ReplicatedStorage/Modules/Info/
    init.luau          re-exports the children; the only thing anything requires
    Places.luau        place ids and the IsX flags derived from them
    Combat.luau        engine tunables — default character, m1 defaults, cooldowns
    Movesets/          one child per character, replacing Combat/Characters
        init.luau      name -> definition, built by scanning children
```

Two things worth deciding before it is built:

**Where movesets live.** `Combat/Characters` already is a moveset directory —
one ModuleScript per character, each returning a table. Moving it under `Info`
puts content and engine config in one tree, which is either the point or exactly
what you do not want. It also means the combat engine requires `Info`, so `Info`
can never require anything from combat.

**Whether the flags stay derived.** `IsTestPlace` is computed from
`game.PlaceId`. If `Info` is required on both sides it can compute them once and
hand out the result, which is strictly better than every caller reading
`shared`.

A first pass that is pure profit regardless: move the nine `shared.*` keys into
`Info.Places` and `Info.Combat`, delete `GlobalSettings.luau`, and leave movesets
where they are until the shape settles.
