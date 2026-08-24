# Characters

## Registering one

There is no registry. `Combat:SendCharacterInformation` walks
`ServerStorage/characterData/` and builds the picker from whatever ModuleScripts
it finds (`serverCombat.luau:199`). A module in that folder **is** a character.

`Combat:GetCharacterModule` (`serverCombat.luau:1139`) looks up by exact name
first, then falls back to a lowercase match — so a saved profile pointing at
`"Chara"` still resolves to `chara`.

## The module

Every field is optional except where noted. This is the complete set the engine
reads.

```lua
local replicatedStorage = game:GetService("ReplicatedStorage")

return {
    --// identity
    DisplayName = "Kratos",          -- falls back to the module name
    Icon        = "101089066666765", -- asset id; the picker is name-only today
    StandName   = nil,               -- for stand-style characters

    --// access
    DevOnly              = true,     -- gated to info.theBigFour
    PrivateServerPlusOnly = nil,

    --// moves
    Attacks = {
        ["Chaos Barrage"]  = Enum.KeyCode.One,
        ["Leviathan Rush"] = Enum.KeyCode.Two,
    },

    UsingAttacks = { "Guardian Shield" },  -- created but not keybound
    VaultedAttacks = { },

    --// tuning
    Stats = { M1 = { ... } },        -- see below

    --// the ultimate
    Ultimate = { ... },              -- see below

    --// per-move engine overrides
    M1   = { AnimationDirectory = function(self) ... end },
    Dash = { AnimationDirectory = function(self) ... end },
    Parry = { CustomFunction = function(...) end },

    --// lifecycle
    OnSpawn   = function(LuaPlayer, ...) end,
    OnRespawn = function(LuaPlayer, Job) end,
    OnRemoved = function(LuaPlayer) end,

    SpawnAnimationRng = nil,
}
```

### Stats.M1

```lua
Stats = {
    M1 = {
        Speed = 1.55,               -- animation speed multiplier
        EndlagAfterSwing = 0.08,    -- seconds

        Hitbox = {
            Offset = CFrame.new(0, 0, -2.65),
            Size   = Vector3.new(6, 6, 6.8),
        },

        LastHitbox = nil,           -- optional, for the final swing

        ArmFlashes = { ... },       -- REQUIRED, see below

        Count = nil,                -- swings in the string, defaults to 4
        CustomConditionToActivate = function(self) end,
        StartFunction = function(self) end,
        EndFunction   = function(self) end,
        CustomFunction = function(self) end,
        AnimationDirectory = function(self) end,
    },
},
```

**`ArmFlashes` is required.** `Global/M1.luau` warns once per character if it is
missing. It is keyed by swing number, plus `Up` and `Down` for the air finishers:

```lua
ArmFlashes = {
    [1] = { Limb = "Right Arm", Colour = Color3.fromRGB(255, 115, 15), Duration = 0.35 },
    [2] = false,                                     -- a swing that deliberately has no flash
    [3] = { Limb = "Right Arm", Colour = ..., Duration = 0.35 },
    [4] = { Limb = { "Left Arm", "Right Arm" }, Colour = ..., Duration = 0.4 },

    Up   = { Limb = "Right Leg", Colour = ..., Duration = 0.4 },
    Down = { Limb = "Right Arm", Colour = ..., Duration = 0.4 },
},
```

`false` means a swing that opts out — a weapon swing with no bare limb to light
up, like Chara's second and fourth. That is **not** the same as omitting the
table, which is an authoring mistake and warns.

`Limb` takes a string, or a list to flash both.

### Ultimate

```lua
Ultimate = {
    Name = "The Rage of War",

    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 115, 15)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 115, 15)),
    }),

    Attacks = {                     -- replaces the normal moveset while ulting
        ["Spartan Rage"] = Enum.KeyCode.One,
    },

    CanRotate  = true,
    DontHeal   = nil,
    CanUseWhileDead = nil,
    SkipIntro  = nil,
    OneTimePop = nil,
    ManuallyFireStartRemote = nil,

    OnStart  = function(self) end,
    Function = function(self) end,
    CustomFunction = function(self) end,
}
```

## Access

`Combat:CanUseCharacter` (`serverCombat.luau:390`) is the gate.

- No flags → public.
- `DevOnly = true` → checks the user id against `info.theBigFour`.
- `PrivateServerPlusOnly` → the other gate.

`SendCharacterInformation` filters to what the asking player can actually use, so
a `DevOnly` character never reaches a client that could not switch to it.

## What the place needs

The module alone gets you a character in the picker. It will not look or sound
like one until the place has its assets, and **the folder names must match the
module name exactly** — the engine indexes them with `self.Animations[CurrentCharacter.Name]`,
which is a plain table lookup, not a case-insensitive one.

| Place path | What it holds |
| --- | --- |
| `animations.Attacks.<name>.<Move>` | One folder per move, holding its tracks |
| `animations.Attacks.Global.M1.<name>` | The punch string. Without it you fall back to `Default` |
| `animations.Attacks.Global.Dash.<name>` | |
| `animations.Attacks.Global.Block.<name>` | |
| `animations.Attacks.Global.Ultimate.<name>` | |
| `animations.Attacks.Global.Dash.WallCombo.<name>` | |
| `animations.CharacterSpawnAnimations.<name>` | Spawn animation, if `OnRespawn` plays one |
| `animations.Movement.<name>` | Per-character locomotion, optional |
| `modules.client.replication.VFX.<name>` | The VFX modules for its moves |
| `modules.client.replication.VFX.Global.M1.Hit.<name>` | Custom hit effects |
| `modules.client.replication.VFX.Global.M1.CustomSwings.<name>` | Custom swing effects |
| `modules.effect.assets.Characters.<name>` | Shared assets the VFX clone from |

A character with no `Global.M1.<name>` folder still works — it just punches like
`Default`. This is the most common "why does my new character feel wrong"
answer.

## Models on the module

The character ModuleScript can hold instances as children, and they come across
in the place with it. `chara` carries a Knife and a Necklace; `kratos` carries
Mimir, OldMimir, an SFX sound and a LogRig. Reach them with `script.<Name>` from
inside the module.

## Lifecycle hooks

- `OnSpawn(LuaPlayer, ...)` — after the character is set and its attacks created.
- `OnRespawn(LuaPlayer, Job)` — on each respawn. Put anything that needs cleaning
  up on the `Job`.
- `OnRemoved(LuaPlayer)` — when switching away.

## Worked example

`ServerStorage/characterData/megumi.luau` is the smallest complete character —
identity, `Stats.M1` with arm flashes, an ultimate, and an empty `Attacks` table.
`kratos.luau` is the largest, with weapon-aware animation directories and a spawn
sequence.
