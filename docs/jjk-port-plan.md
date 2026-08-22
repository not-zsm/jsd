# Porting toward the jjk layout

Comparison of the two codebases and what moving jsd toward jjk's shape actually
involves, in the order I'd do it.

## What jjk gets right

```
ReplicatedStorage/          ServerStorage/            StarterPlayerScripts/
    info/                       characterData/            PlayerScriptsLoader/
    characterData/              gameHandler/                  mainClient/
    clientCombat/               modules/                          UI/helpers/
    modules/                    serverCombat/
        client/ effect/
        shared/ utility/
```

Three things jsd does not have:

- **`info/`** — one require reaching `movesets`, `emotes`, `settings`, `titles`,
  plus place ids, walk speeds, gamepass ids. jsd scatters this across `shared.*`
  and inlined constants.
- **`clientCombat` / `serverCombat` as peers.** jsd's split is
  `ReplicatedStorage/Client/Character/Combat` against
  `ServerScriptService/Modules/Player/Character/Combat` — same split, three
  levels deeper on each side, and neither name says which half it is.
- **`serverCombat` in ServerStorage, not ServerScriptService.** That is sketch A
  from `organisation-sketches.md`. jjk is the working proof it is right.

jsd is already most of the way after the restructure. The remaining distance is
naming and depth, not architecture.

## Moveset parsing, since you asked

jsd already does the data-driven half, it just never used it for the picker.

`Combat:SendCharacterInformation` requires every module under `Combat/Characters`
and builds a summary — `StandName`, `PrivateServerPlusOnly`, `Attacks`, and
`Ultimate` as `{Name, Color, Attacks}` — then fires it to the client once, where
`Client/Character/InfoCharacter` caches it.

So the ult colour and the full move list already reach the client. The old
picker ignored all of it and hardcoded fifteen entries by hand, which is why it
needed maintaining.

**An automatic picker needs two fields added and one module written.** Add
`Icon` and `DisplayName` to each character definition, extend the summary to
carry them, and have the picker build itself from `InfoCharacter`. Nothing else
changes. jjk's `movesetInfo` shape — `colour`, `ultName`, `moveset` entries with
`name`/`label`/`activation` — is a superset worth adopting, but the wiring
already exists.

The one thing jsd has no equivalent for is `activation` (`tap` / `hold` /
`useTwice` / `useThrice`). jsd encodes that per-attack in code, via `HeldState`
and variant methods on BaseAttack. Moving it to data is a real change to how
BaseAttack dispatches, not a config addition.

## Port list

| From jjk | Lines | Effort | Notes |
| --- | --- | --- | --- |
| `footsteps.client` | 261 | low | self-contained, reads surface material |
| `stuff/lean.client` | 233 | low | leans the rig into movement direction |
| `settingsHelper/default/cameraFollowHead` | — | low | jsd has its own; replace |
| `settingsHelper/default/shiftlockSettings` | — | low | as above |
| `effect/tekrinnDialogue` | 534 | medium | jsd's own is 263 lines; compare before replacing |
| `info/` + `movesetInfo` | 246 | medium | the shape is easy, deciding what moves into it is not |
| `mainClient` | 1325 | high | jsd's MainClient is a system runner; jjk's owns menus and UI too |
| `charSelectHelper` | — | medium | wants the Icon/DisplayName work above first |

Lean and footsteps replace the directional animation-based movement, which means
touching `Client/Character/Movement`, at 1,058 lines the largest client module. Do them
together, not separately.

## Re-adding Invincible and Kratos

The scripts are recoverable: 101 files at `f73ed23`, 24 for Invincible and 74
for Kratos, restorable with `git checkout f73ed23 -- <path>`.

**Their assets are not.** Those VFX modules reference child instances — meshes,
particle emitters, sounds — between 2 and 10 times each, and those instances
lived only in the place. `VFX.Kratos` and `VFX.Invincible` are absent from the
current place, so a restore from git brings back code whose effects reference
nothing.

Same for `Animations.Attacks.Kratos`, the spawn animations, and Kratos's Mimir
model.

So: do you have a place file from before the strip? If yes this is an afternoon.
If no, the code comes back but the characters need their VFX rebuilt, and it is
worth asking whether that is the best use of the effort versus building the two
dev characters fresh against the new structure.

## Server authority

Worth separating into two questions.

jsd is already server-authoritative for the things that matter — hitboxes,
damage, blocking, i-frames and stun all resolve on the server in `Combat`. The
client sends input and plays effects.

What it lacks is **lag compensation**: the server does not rewind to where the
victim was on the attacker's screen. jjk carries `chrono` for exactly this — a
snapshot and interpolation library, 30 files under `modules/shared/chrono`, with
an entity grid and a client clock.

That is a substantial subsystem and it changes how every hitbox resolves.
Sequence it after the reorganisation, not during.

## Suggested order

1. **Naming and depth.** `Client/Character/Combat` to `clientCombat`,
   `Modules/Player/Character/Combat` to `serverCombat` in ServerStorage. Same
   tooling as the last restructure, and it makes everything below easier to
   place.
2. **`info/`.** Move the `shared.*` keys and the scattered constants in. Nothing
   depends on it yet, so it cannot break anything.
3. **Character select.** Add `Icon` and `DisplayName`, extend the summary,
   rebuild the picker from `InfoCharacter`. Unblocks having more than one
   character.
4. **Movement.** Footsteps, lean, camera-follow-head, shiftlock, together.
5. **Characters.** Once the picker exists and the asset question is answered.
6. **Chrono**, if the reorganisation has settled.

## camelCase

jsd is PascalCase throughout — every module, method and field. jjk is camelCase.
Mixing them is worse than either.

A rename is mechanical for locals and module names but not for the public
surface: `Combat:Afflict`, `Attack:Activate`, `self.LuaPlayer`, and every field
the character definitions and the 20 attack modules read. That is a whole-tree rewrite
with the same tooling as the restructure, verified the same way.

Worth doing as its own pass, once the structure has stopped moving. Doing it
alongside a reorganisation makes both harder to verify, because every file
differs for two reasons at once.
