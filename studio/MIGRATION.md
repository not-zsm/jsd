# Applying the strip-down in Studio

You work in Studio and export to this format for backup, so nothing in this
repository has touched your place. This is how to make the same changes there.

## Read this first

**This export contains only scripts.** 1329 `.luau` files and 636 `.meta.json`,
and nothing else — no parts, models, animations, particles, sounds or GUIs. Your
place is not reconstructible from it.

That rules out the obvious shortcut. Do not point Rojo at this repository and
sync it into your place: you would get the scripts and lose everything they
operate on. The changes have to be applied to the place you already have.

**Save a copy of the place before you start.** Step 1 deletes about ninety
subtrees and everything inside them. Undo is not a backup.

---

## Step 1 — Delete the removed instances

`studio/DeleteRemovedInstances.luau` holds the 96 instance paths that were
removed, collapsed to the topmost one in each subtree so you delete containers
rather than walking every leaf.

1. Open the place in Studio.
2. Paste the whole file into the command bar and run it.

It starts as a **dry run**: it prints what it would delete, with class name and
descendant count, and what it could not find. Nothing changes.

Read that output. Anything under "not found" either moved or was renamed since
the export — worth understanding before you delete the rest, because a path that
stops early means its parent is gone too.

3. Change `local DRY_RUN = true` to `false`, paste and run again.

---

## Step 2 — Update the scripts that changed

24 scripts have edits. If you have not touched them in Studio since your last
export, the simplest approach is to open each in Studio, select all, and paste
in the contents of the file from this repository.

If you *have* edited any of them since, paste would lose that work — use the
"what changed" column and make the edit by hand instead.

### Small files — paste the whole thing

These are short enough that wholesale replacement is easiest.

| Script | What changed |
| --- | --- |
| `…Combat/Passives/Kills` | emptied; every on-kill passive belonged to a deleted character |
| `…Combat/Mouse/AimPresets` | emptied; its one entry was Invincible's |
| `…Replication/Global/Vignette/Presets` | kept `Black Flash`, `Regeneration`; dropped 9 |
| `…Replication/Global/ScreenPulse/Presets` | kept `Black Flash`, `Regeneration`; dropped 11 |
| `…Replication/Global/RockHandler/Presets` | kept the dash and `CharaLethalWoundSlide` entries; dropped 6 |
| `…Replication/GrabHandler/Presets` | kept `CharaOnslaughtAerial`; dropped `ReigenSummonMob` |
| `…Replication/Projectiles/Functions` | kept `Raygun`; dropped 5 |
| `…Replication/VFX/Global/M1/CustomSwings` | Chara only; 181 lines to 42 |
| `…Replication/VFX/Global/M1/CustomHits` | Chara only; 173 to 40 |
| `…Replication/VFX/Global/M1/CustomSpecialSwings` | Chara only; 122 to 37 |
| `…Replication/VFX/Global/M1/CustomSpecialHits` | Chara only; 58 to 29 |
| `StarterPlayerScripts/…/MiscellaneousPackages` | dropped the `BossBar` require |

### Larger files — targeted edits

Each of these is mostly untouched, so hand-editing is safer than pasting.

| Script | What changed |
| --- | --- |
| `ServerScriptService/Scripts/Game` (the boot script) | removed the ranked-lobby and ranked-place map swapping, the `TesterPlate` block, and the requires for `CharaSpawner`, the three teleporters, `EventSystemHandler`, `ItemSpawnHandler` and `Arcade`. Ranked place IDs dropped; `shared.IsRankedPlace` / `IsRankedLobby` now literal `false` |
| `…Player/Character/Combat` (server, 3840 → 3649 lines) | removed `CharaAward` and the boss branch of the kill loop, `IsChara` branches, `IsWorldBoss`, `CheckForChara`, the `BossDrop` access branch, the whole `-- compatability for the builder` block, and the `HostHandler` require. Default character `"Gojo"` → `"Chara"` in five places |
| `…Player/Character/Combat` (client) | removed the build-mode toggle that hid the combat HUD |
| `…Combat/UI/Icons` (204 lines out, 86 in) | removed the browser, VC, ranked and main-place icons and the character picker; both ranked guards were always true once ranked went, so the module flattened out by one indent level |
| `…Combat/Characters/Chara` | removed `BossDrop = "Chara"` |
| `…Game/Modules/CommandHandler` | removed the `spawn_chara` / `remove_chara` commands, the boss command gate, the `HostHandler` owner check and the builder teardown |
| `…Game/Modules/Player/Data` | removed the `HostHandler` add/remove calls and the skill-builder editor registration |
| `…Game/Modules/Player/Character/Emotes` | removed the `ClientSpirit` require and the Anubis and Star Platinum stand poses |
| `…Game/ProductHandler` | removed the build-tools shop branch and its `TransactionHandler` / `Unpacker` requires |
| `…Game/ProductHandler/Products` | removed the `Spawn Cursed Child` product (3348046631) |
| `ReplicatedStorage/Modules/Shared/Commands` | removed the `Toggle Build Mode` command, the skill-builder branch of `Give Move`, and the client-side flight require |
| `ServerScriptService/Scripts/HavocHandler` | one line: `Serialise` now comes from `ReplicatedStorage.Packages.Serialise` |

---

## Step 3 — Create the Serialise package

`HavocHandler` decompresses its rubble presets with a serialiser that lived
inside the build tools. The build tools are gone, but the half it needs depends
only on Base91, LibDeflate and BufferUtil, so that half moved out.

In `ReplicatedStorage.Packages`, create a ModuleScript named **Serialise** with
two ModuleScript children, **Base91** and **LibDeflate**. Fill all three from
`ReplicatedStorage/Packages/Serialise/` in this repository.

Base91 and LibDeflate are unchanged copies of the ones that were under
`ServerScriptService.Scripts.BuildHandler.Serialise` — if you would rather move
the originals than paste, do that before deleting `BuildHandler` in step 1.

---

## Step 4 — Delete what the export cannot see

Instances with no script inside them never appear in this repository, so the
step 1 script does not know about them. These are orphaned now:

**Animations** — under `ReplicatedStorage.Animations.Attacks`, delete the folder
for each removed character: Accelerator, Anubis, Edgerunner, Garou, Gebura Red
Mist, Gojo, Hornet, Invincible, Items, Jimpee, Kratos, Meaty Michael, Mori,
Powers, Reigen, Stardust Crusader, Steve, Walter. Same names under
`ReplicatedStorage.Animations.CharacterSpawnAnimations`.

**ServerStorage** — `EventAssets`, `ItemSpawns`, `RankedAssets`.

**StarterGui** — `BossBars`, `ServerBrowser`, and the build-tools UI.

**Workspace** — the models for the twelve removed NPCs (Black Market Dealer,
BruhSalino, FadeUnchanged, HW5567, Jade, Jimpee, Mymy32100, News Boy, Sketch,
TheCookieGuy, Tough, Wellworks), plus `TesterPlate` and `RankedPlate`. Step 1
removes the scripts inside them; the models themselves are yours to delete.

**Remotes** — these 33 under `ReplicatedStorage.Remotes` are no longer fired or
listened to by anything:

```
ApplyVelocity            EnterDomain              RequestServerList
BulkCreateDomain         JoinServer               RequestUserStatus
CaptureSelection         LeaveDomain              Serialisation
CreateDomain             ModerateServer           SetAdmin
CreateServer             ModerateUser             SetPreference
DeleteBuildTools         NotifyServerRefresh      SpawnDome
DeleteServer             Operations               SpawnWave
EditServer               PopUp                    ToggleBuildTools
                         ReliableCaptureSelection Transactions
                         RemoveVelocity           UpdateServerList
                         RequestInstanceModifiers ViewerSubscribe
                         RequestMyServers         ViewerUnsubscribe
                         RequestServer
```

Also `JoinMainPlace`, `JoinRankedLobby`, `JoinVCServer` and the `Ranked` folder,
whose handlers went with the teleporters.

This list is the conservative one — a name was only included if it appears
nowhere in the surviving scripts, including comments. Anything you find under
Remotes that is not listed here, leave alone.

**Sounds** — `SoundService.DialogueVoicelines` has entries for the removed NPCs.
The dialogue system itself is still in place (see below), so check before
deleting.

---

## Step 5 — Verify

1. **Play test.** You should spawn as Chara with its full kit. There is no
   character picker any more; Chara is the default in `Combat:SetCharacter`.
2. **Watch the output window on join.** A missing module shows up immediately as
   a require error naming the path.
3. **Hit a dummy.** M1, block, parry, dash, vault, wall-run and the ultimate all
   go through code that was edited.
4. **Break something.** Destruction runs through `HavocHandler`, which is the
   one system whose dependency moved in step 3.

To re-check the repository side after your next export:

```sh
tools/check_requires.py .
```

It resolves every `require` in the tree against the files that exist. Two
failures are expected — test stubs in `ReplicatedStorage/Packages/Des` pointing
at a test runner this game does not have. Anything else is a real break.

---

## Still there, deliberately

Three things survived that you may or may not want:

- **DialogueManager** — NPC dialogue, including entries for NPCs that no longer
  exist. It still loads and costs nothing, but it is dead.
- **The stand system** — `BaseStand`, `AttackFunctions/Stands`,
  `Combat:GetStand`. No character uses it. It is engine capability rather than
  content, which is why it stayed.
- **The character item system** — `Player/Character/Items`. Its spawner is gone
  so nothing drops items, but M1 depends on it through `Items:IsSinked()`.

And `shared.IsRankedPlace` / `IsRankedLobby` are still defined, as `false`.
Combat, Hitbox, Actions, Movement and three client handlers guard on them;
leaving them false preserves current behaviour exactly, where removing them
means touching combat in twenty files.
