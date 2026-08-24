# Modding jsd

How to add characters, moves and effects to this framework.

Everything here is written against the code as it stands, with file and line
references you can follow. If a reference has drifted, the code wins — say so and
it gets fixed.

## Where to start

| Doc | What it covers |
| --- | --- |
| [overview.md](overview.md) | How the framework is put together, and the one rule that explains most of it |
| [characters.md](characters.md) | Adding a character: every field, what is required, what the place needs |
| [moves.md](moves.md) | Adding a move: the lifecycle, every flag, and the limitations |
| [combat.md](combat.md) | Hitboxes, `Afflict`, states, velocity, cooldowns |
| [presentation.md](presentation.md) | VFX, hotbar tooltips, arm flashes, sound |
| [input.md](input.md) | Keys, held and charged moves, aiming, air variants |
| [workflow.md](workflow.md) | Repo and place, the tools, and how to not break things |

## The shortest possible version

A character is a ModuleScript in `ServerStorage/characterData/`. A move is a
ModuleScript in `ServerStorage/serverCombat/Attacks/List/`. Neither needs
registering anywhere — the engine walks those folders.

```lua
-- ServerStorage/characterData/yourname.luau
return {
    DisplayName = "Your Name",

    Attacks = {
        ["Your Move"] = Enum.KeyCode.One,
    },

    Stats = {
        M1 = {
            Speed = 1.3,
            EndlagAfterSwing = 0.1,
            Hitbox = { Offset = CFrame.new(0, 0, -3), Size = Vector3.new(6, 6, 7) },
            ArmFlashes = { --[[ required, see characters.md ]] },
        },
    },
}
```

```lua
-- ServerStorage/serverCombat/Attacks/List/yourname/Your Move.luau
local ServerStorage = game:GetService("ServerStorage")
local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack
setmetatable(Attack, BaseAttack)

function Attack:Activate()
    -- the move
    self:Close()
end

function Attack.new(...)
    local self = setmetatable(BaseAttack.new(...), Attack)
    self:_Init()
    return self
end

table.freeze(Attack)

return Attack
```

That is a playable character with one move. Everything else in these docs is
detail on top of those two files.

## Conventions

Names are lowercase: characters are `chara`, `kratos`, `megumi`, and the
containers they live in are `animations`, `packages`, `emotes`. Move names keep
their spaces and capitals (`Bloody Mary`) because they are display text as well
as identifiers.

Code style is camelCase for locals the codebase owns and PascalCase for the
engine's own methods and fields, which is what you will see in every existing
move.
