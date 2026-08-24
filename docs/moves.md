# Moves

## What a move is

A ModuleScript that inherits `BaseAttack` and overrides `Activate`.

It lives at `ServerStorage/serverCombat/Attacks/List/<character>/<Move>.luau`,
but **the folder is organisation, not routing**. `Combat:GetAttackModule`
(`serverCombat.luau:1129`) walks every descendant of `List` looking for a
ModuleScript whose *name* matches, and stops at the first hit.

> **Limitation:** two characters cannot share a move name. If both want a
> "Barrage", one of them has to be called something else.

A move becomes real when a character module's `Attacks` table names it against a
key. Nothing else registers it.

## The whole minimum

```lua
local ServerStorage = game:GetService("ServerStorage")
local BaseAttack = require( ServerStorage.serverCombat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack
setmetatable(Attack, BaseAttack)

function Attack:Activate()
    self.Combat:StackState("Attacking", true)

    local Hitbox = self:CreateHitbox(false)
    Hitbox.Params.Offset = CFrame.new(0, 0, -4)
    Hitbox.Params.Size   = Vector3.new(6, 6, 8)

    Hitbox.Events.OnLuaPlayerHit:Connect(function(VictimLuaPlayer)
        self:Afflict(VictimLuaPlayer, { Damage = 8, Stun = 0.6 })
    end)

    Hitbox:BeginCast(0.2)

    self.Thread.OnClosed:Connect(function()
        self:AddCooldown(6)
        self.Combat:StackState("Attacking", false)
    end)

    task.wait(1)
    self:Close()
end

function Attack.new(...)
    local self = setmetatable(BaseAttack.new(...), Attack)
    self.TryToCancelMoves = true

    self:_Init()

    return self
end

table.freeze(Attack)

return Attack
```

## Lifecycle

In the order they run:

| Override | When |
| --- | --- |
| `Attack.new(...)` | Once, at registration. Where flags go. |
| `_Init()` | Stub on the base, called from your own `new`. |
| `Initialise()` | After the `createAttack` packet and the animation load. |
| `Pretrigger(Extra, State)` | Every press, **before** conditions. Dash and WallJump read direction off the client's `Extra` here. |
| `ConditionToActivate(State)` | The gate. |
| `Activate()` | The move. Own coroutine, wrapped in `pcall`. |

A throw inside `Activate` warns, sets `Thread.Errored` and closes the move —
it does not take combat down with it. That also means **a broken move fails
quietly**; check the output.

### Conditions

`BasicConditions()` (`BaseAttack.luau:543`) is the floor, and it already covers:

- not `Stunned`
- not `Attacking`
- not `Ragdolled`
- not `Backdashing`
- not on cooldown
- `self.Enabled`
- not `Cannot<MoveNameWithoutSpaces>`

That last one is worth knowing: setting the state `CannotBloodyMary` blocks
`Bloody Mary` with no code in the move at all.

The default `ConditionToActivate` adds not `Dashing`, not `Blocking`, not
`M1ing`. Override it to add to the floor — call `self:BasicConditions()` inside
rather than replacing it:

```lua
function Attack:ConditionToActivate()
    return self:BasicConditions() and not self.Combat:GetState("Blocking")
end
```

## self.Thread

Built fresh on every activation, thrown away on close.

```lua
self.Thread = {
    Closed = false, Cancelled = false, Errored = false,
    OnClosed = ..., OnCancelled = ...,
    Job = ..., CancelJob = ...,
    Object = ...,   -- the coroutine
}
```

`Job` is destroyed on close; `CancelJob` only on cancel. Put every connection and
instance a run creates on one of them and teardown handles itself.

`self:ThreadAvailable()` tells you whether a run is live.

> **Limitation:** `self.Thread` is nil before the first activation. Anything in
> `new` or `Initialise` that touches it will fail.

## Animations

The move's animation folder is found **by move name** anywhere under
`animations.Attacks` (`BaseAttack.luau:351`), then narrowed by character
(`:193`). See [characters.md](characters.md) for the folder layout.

`self.Animations.Windup` is special: if a track by that name exists, `Trigger`
plays it for you before `Activate` is reached, using `self.AnimationSettings`:

```lua
self.AnimationSettings = { FadeTime = 0.1, Weight = 1, Speed = 1 }
```

Everything else is `self.Animations.<TrackName>`, and marker signals are the
normal way to time a move:

```lua
self.Thread.Job:Task(self.Animations.Windup:GetMarkerReachedSignal("hit"):Connect(function()
    Hitbox:Detect()
end))
```

`self:StopAllAnimations()` and `self:GetAnimationDirectory()` are there when you
need them.

## Flags

Set in `new`, before `_Init`.

| Flag | Effect |
| --- | --- |
| `TryToCancelMoves` | Cancels M1 and Block on activation. On 26 of the game's moves. |
| `Uncancellable` | Nothing else may cancel this once it starts. |
| `DontBuffer` | A press during another move is dropped rather than queued. |
| `BypassHumanoidAlive` | Usable while dead. Chara's ultimate is why this exists. |
| `BeginRequestingMouseOnBuffer` | Starts the aim stream on press, ends it on release. |
| `VariantsEnabled` | Whether the air variant may fire. Default true. |
| `ForceVariant` / `ForceSpecialVariant` | Pin the variant on. |
| `Enabled` | False blocks activation *and* hides the slot. |
| `CooldownEnabled` | False makes `AddCooldown` a no-op. |
| `FinisherEnabled` | Read by finisher logic. |
| `SoundEffectsEnabled` | False makes `CreateMoveSFX` return a dead Sound. |
| `VisualEffectsEnabled` | False makes all four `FireVFX` helpers no-op. |
| `DamageMultiplier` | Applied by `Afflict`. |
| `RagdollMultiplier` | Applied by `Afflict`. |
| `KnockbackMultiplier` | Applied by `VelocityOn`. |
| `StunMultiplier` | Applied by `Afflict` to `Stun` and `TrueStun`. |
| `SpeedMultiplier` | Applied to animation playback. |
| `HitboxMultiplier` / `HitboxOffset` | Applied by `CreateHitbox`, intercepted at `BeginCast`. |
| `Properties` | Free-form table sent to the client. See [presentation.md](presentation.md). |

The multipliers exist so buffs can scale a move without the move knowing. Do not
apply them by hand — `Afflict` and `VelocityOn` already do.

## Closing

- `self:Close(...)` — normal end. Fires `Thread.OnClosed`, destroys `Thread.Job`.
- `self:Cancel()` — interrupted. Fires `OnCancelled` too, destroys `CancelJob`.
- `self:SetUncancellable(true)` — mid-run.

A move that never closes holds `Attacking` forever and locks the player out of
everything. Always close, on every path.

## Limitations, collected

- **Move names are global.** One `Barrage` in the whole game.
- **A move only exists while its character is equipped.** Switching characters
  destroys the attack objects and sends `removeAttack`.
- **`Activate` runs in a pcall.** Errors warn instead of erroring loudly.
- **The client cannot start a move.** It can only ask; the server gates it.
- **Animation lookup is by move name, then character.** Two moves with the same
  name would collide in the animation tree as well as the module tree.
- **`self.Properties` is read once**, when the move is registered. It is not
  live — changing it later sends nothing.
- **NPCs skip most client-facing calls.** Guard with `self.LuaPlayer.IsNPC` if
  you are doing something unusual; the built-in helpers already do.
