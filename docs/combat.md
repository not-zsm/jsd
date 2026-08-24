# Combat

## Hitboxes

```lua
local Hitbox = self:CreateHitbox(Sphere?, DontClose?)
```

Returns a hitbox already bound to the thread — it stops casting and destroys
itself on close, unless `DontClose` is set. `Sphere` picks the spherical shape
over the default box.

### Params

| Param | Meaning |
| --- | --- |
| `Offset` | `CFrame` relative to the character's root. |
| `Size` | `Vector3` for a box, `number` radius for a sphere. |
| `MaxTargets` | Stop after this many. |
| `DestroyOnEndCast` | Tear down when the cast window closes. |
| `Ignore` | Instances to skip. |

### Casting

- `Hitbox:BeginCast(duration)` — a window, checked continuously.
- `Hitbox:Detect()` — a single frame, right now.
- `Hitbox:EndCast()` — stop early.
- `Hitbox:GetCFrame()` — where it currently is.

### Events

- `Hitbox.Events.OnLuaPlayerHit` — fires per victim. This is the one you want.
- `Hitbox.Events.OnCastEnded`

### Terrain and extras

- `Hitbox:CreateHavocReplicated{ parameters = ..., debris = ... }` — replicated debris.
- `Hitbox:Destruction(offset, size, radius)` and `Hitbox:SphereDestruction(...)`.
- `Hitbox:AoeHitboxForGrabs(...)` — for moves that grab.

## Afflict

```lua
local Validated, Result = self:Afflict(VictimLuaPlayer, { ... })
```

One call does damage, stun, ragdoll, knockback and block interaction. The move's
multipliers are applied on the way through, and the victim is tracked so one
activation cannot hit the same character twice unless you say so.

**Check `Validated`** before spending VFX on a hit that was blocked.

| Argument | Meaning |
| --- | --- |
| `Damage` | A number, or `{ Amount = n, DontKill = true }`. |
| `Stun` | Seconds. |
| `TrueStun` | Seconds, ignoring stun resistance. |
| `Ragdoll` | Seconds ragdolled. |
| `Velocity` | `{ Vector3, duration }`. |
| `BreakBlock` | Guard breaks instead of absorbing. |
| `DontCheckBlock` | Lands regardless of block. |
| `ExcludeAttempts` | Not counted as a hit attempt — for follow-up ticks inside one move. |
| `FinisherKill` | Routes through the finisher path. |
| `DontHitDeadPeople` | Skip dead targets. |
| `DontHitRagdolled` | Skip ragdolled targets. |
| `DontBypassIFrames` | Respect invulnerability. |
| `DontCheckForHitboxImmunity` | Ignore hitbox immunity. |
| `DontRestartRespawnTimer` | |
| `CanPerfectBlock` | Allow a perfect block against this. |
| `NoCounter` | Cannot be countered. |
| `TriggerActiveCounterOverOrEqualLevel` | Counter interaction threshold. |
| `BlockAngle` | Arc within which a block works. |
| `HitAngleLookVector` | Direction used for the reaction. |
| `PlayRandomHitReaction` | Pick a reaction at random. |
| `YDifferenceValue` | Vertical offset handling. |
| `Projectile` | Mark as projectile damage. |
| `Inspection` | Debug. |

`SourceAttack` is set for you.

## States

States are a stack, not a boolean — two moves can both hold `Attacking` and it
stays true until both release. That is why they come in pairs.

```lua
self.Combat:StackState("Attacking", true)
-- ...
self.Combat:StackState("Attacking", false)
```

`self.Combat:GetState(name)` reads one. `ResetState(name)` clears the stack.

> **Every `true` needs its `false`.** The usual place is
> `self.Thread.OnClosed:Connect(...)`, so an interrupted move still releases.

The states in use across the game, by how often:

| State | Meaning |
| --- | --- |
| `Attacking` | A move is running. Blocks most other moves. |
| `HitboxImmunity` | Cannot be hit by hitboxes. |
| `Blocking` | Guard up. |
| `GrabIFrames` | Invulnerable during a grab. |
| `Ragdolled` | |
| `Grabbed` / `Grabbing` | The two ends of a grab. |
| `StunImmunity` | |
| `CannotDash`, `CannotBlock`, `CannotM1`, `CannotRun`, `CannotDrawWeapon`, `CannotGainMeter` | Targeted lockouts. |
| `BackdashIFrames` | |
| `Stunned` | |
| `M1ing` | |
| `EvasiveState` / `Evasived` | |
| `Backdashing` | |
| `Pushed` | |
| `Emoting` / `EmoteDebounce` | |
| `WallComboed` / `WallComboing` | |
| `ForceDashPush` | |
| `Dashing` | |
| `AntiTeam` | |
| `Ulting` | |

`Cannot<MoveName>` (no spaces) blocks that specific move through
`BasicConditions` — no code needed in the move itself.

## Velocity

```lua
local VelocityObject = self.Combat:Velocity()
VelocityObject.Settings.MaxForce = Vector3.new(0, 1, 0) * 80000
VelocityObject.Settings.Y = 27.5
VelocityObject.Settings.Duration = 0.65
VelocityObject.Settings.RemoveTime = 0.15
VelocityObject.Settings.Controllable = true
VelocityObject:Fire()
```

| Setting | Meaning |
| --- | --- |
| `MaxForce` | Which axes are driven, and how hard. |
| `X` / `Y` / `Z` | Per-axis speed, relative to facing. |
| `Velocity` | A whole `Vector3` instead of per-axis. |
| `Duration` | How long it drives. |
| `RemoveTime` | Fade-out after that. |
| `Controllable` | Whether the player can still steer. |
| `NeedsVelocityAttribute` | Gate on an attribute. |
| `FixScale` | Scale correction. |

Use `self:VelocityOn(VictimCombat)` rather than `VictimCombat:Velocity()` when
pushing a *victim* — it applies the move's `KnockbackMultiplier`.

## Cooldowns

```lua
self:AddCooldown(12)          -- hotbar ring
self:AddCooldown(12, true)    -- and the bigger on-screen indicator
```

- `self:RemoveCooldown()`
- `self:PauseCooldown()` / `self:ResumeCooldown()`
- `self:AddCertainCooldown(name, duration, onEnded, indicator)` — a second timer
  that is not the move's own: a stance, a resource, a per-target lockout.
- `self:HasCertainCooldown(name)`

`CooldownEnabled = false` makes `AddCooldown` a no-op, and the engine-wide
`Combat.CooldownsEnabled` overrides everything except M1.

## Grabs

```lua
local GrabObject = self.Combat:GrabVictim(VictimLuaPlayer, BoundTo, Offset, PresetName)
```

Binds the victim to a part with an offset. Handles iframes, collision groups,
camera occlusion and stun for both sides.

- `GrabObject.SetOffset(NewOffset)`
- `GrabObject.SetBound(NewBound)`
- `GrabObject.Destroy(OwnerIFrameDuration)`
- `GrabObject.Destroyed`

**Always destroy it**, including on `Thread.OnClosed`, or the victim stays stuck.

> **Gotcha, fixed but worth knowing:** an `Offset` with no rotation used to
> produce a NaN CFrame through the byteNet codec, which made the victim vanish.
> Guarded now, but if a grab ever renders someone invisible, that is the shape of
> the bug.

## Other Combat calls moves use

| Call | What it does |
| --- | --- |
| `DivideSpeed(n)` / `TimesSpeed(n)` | Slow and restore walkspeed. Always pair them. |
| `HideUI(bool)` | Hide the player's HUD. |
| `GetSimulatedRoot()` | The root to bind effects to. |
| `CalculateUnitDifference(Victim)` | Direction to a victim. |
| `CalculateYDifference` / `CalculateMagnitude` / `CalculateHitAngle` | Geometry helpers. |
| `MatchAttack(...)` | Attack matching for clashes. |
| `ChangeAttackDisplay(name, text, settings)` | Hotbar label — see [presentation.md](presentation.md). |
| `CombatTag()` | Mark as in combat. |
| `VictimImpactGround(Victim)` | Ground-slam reaction. |
| `TSBPushVictim` / `PushSkidVictim` | Push variants. |
| `CreateCounter` / `RemoveActiveCounter` | Counter windows. |
| `CreateAttack` / `RemoveAttack` | Add or remove a move at runtime. |
| `HasACharacter()` | Guard before touching `CurrentCharacter`. |
