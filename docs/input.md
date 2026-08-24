# Input and variants

## Keys

A move gets its key from the character module:

```lua
Attacks = {
    ["Chaos Barrage"] = Enum.KeyCode.One,
},
```

The server sends that to the client as a `createAttack` packet at character
switch, and the client binds it. You never bind a key yourself for a normal move.

Keys `One` through `Nine` also claim a hotbar slot — `Combat:_CreateAttack`
derives the slot number from `Key.Value - 48`.

The Global moves are bound by the engine, not by a character:

| Move | Key |
| --- | --- |
| M1 | `MouseButton1` |
| Block | `F` |
| Ultimate | `G` |
| Dash | `Q` |
| Vault / WallJump | `W` |

## Press and release

Press and release are the same packet with a boolean.
`Actions:UseMove(Name, State, Extra)` writes it to `self.HeldState` **before**
conditions run:

- `State == nil` — a plain press, fire once.
- `State == true` — pressed, for a held move.
- `State == false` — released.

A charged move reads `self.HeldState` in `Activate` and loops until it flips:

```lua
function Attack:Activate()
    while self.HeldState and not self.Thread.Closed do
        task.wait()
    end
    -- release
end
```

`DontBuffer` makes a press during another move drop rather than queue.

## Aiming

Set the flag and the stream manages itself:

```lua
self.BeginRequestingMouseOnBuffer = true
```

Press starts `Mouse:BeginRequesting()`, release ends it. Or start it on demand
from inside the move:

```lua
self.Combat.Mouse:BeginRequesting(nil, "Default")
```

The mouse position arrives as an unreliable `mouseAim` stream while the move is
charging.

### Aim presets

A preset name other than `"Default"` looks up
`ReplicatedStorage/clientCombat/Mouse/AimPresets.luau`. An entry is a function
returning something destroyable:

```lua
return {
    ["Invincible_Ultimate"] = function(self)
        local Gyro = Instance.new("BodyGyro")
        -- ... bind a render step that turns the character to face the cursor

        Gyro.Destroying:Once(function()
            RunService:UnbindFromRenderStep("AimToMouseGyroUpdate")
        end)

        Gyro.Parent = self.LuaCharacter.RootPart
        return Gyro
    end,
}
```

Whatever you return is destroyed when aiming ends, so unbind render steps in
`Destroying` rather than tracking the lifetime yourself.

## Air variants

The client sends `Extra` with the move, `UpdateAirVariantChecking`
(`BaseAttack.luau:50`) unpacks it, and the move branches:

```lua
function Attack:Activate()
    if (self.VariantsEnabled and self.HoldingJump) or self.ForceVariant then
        return self:FeralTakedown()
    end

    -- the ground version
end
```

| Field | Meaning |
| --- | --- |
| `self.HoldingJump` | Space held at the moment of the press. |
| `self.FreeFalling` | Airborne and falling. |
| `self.ClientSentExtra` | The raw table, if you need more. |

`VariantsEnabled` gates it; `ForceVariant` and `ForceSpecialVariant` pin it on.

To make the hotbar say which one will fire, declare a `Variant` in
`self.Properties` — see [presentation.md](presentation.md).

> The client decides `HoldingJump`, so it is a hint, not a guarantee. Do not use
> it to gate anything that matters for fairness; use it to pick a flavour.

## Pretrigger

Runs on every press, **before** conditions, and receives the same `Extra`:

```lua
function Attack:Pretrigger(Extra, State)
    self.Direction = Extra and Extra.Direction
end
```

Dash and WallJump use it to read direction. Anything that must be known before
`ConditionToActivate` can decide belongs here.

## Client-side handlers

For a move that needs to bind its own input — a directional read, a double tap,
something held across frames — put it in
`ReplicatedStorage/clientCombat/ClientHandlers/`. That is how Dash, Roll, Vault
and WallJump work.

Each is a module with a `.new(Combat)`, constructed at client startup, and it
owns its own input bindings. This is the escape hatch when a key on the hotbar is
not enough — but it means the input path is no longer declarative, so reach for
it last.

## Keybind changes

`network.changeAttackKey` reaches `Combat:ChangeAttackKey` on the client, which
rebinds and repaints the slot. The server is the source of truth for the mapping.
