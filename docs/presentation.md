# Presentation

## Visual effects

The server never draws anything. It names a module and a function, and every
client runs it.

```lua
self:FireVFX("kratos/Chaos Blades", "Start", self.LuaCharacter.RootPart)
self:FireReliableVFX("chara/Bloody Mary", "Hit", Attacker, Victim)
self:FireVFXToSelf("chara/Reset", "Flash")
self:FireReliableVFXToSelf("chara/Atonement", "Intro")
```

| Helper | Use |
| --- | --- |
| `FireVFX` | Unreliable, everyone. A dropped frame costs nothing. |
| `FireReliableVFX` | Reliable, everyone. One-shots that must not drop. |
| `FireVFXToSelf` | Unreliable, just the user. |
| `FireReliableVFXToSelf` | Reliable, just the user. |

All four no-op when `VisualEffectsEnabled` is false, so never guard them
yourself.

The first argument is a path under
`ReplicatedStorage/modules/client/replication/VFX/`, and the second is a function
the module returns.

### Writing the module

```lua
-- VFX/kratos/Chaos Blades.luau
local replicatedStorage = game:GetService("ReplicatedStorage")

local AnimationRetriever = require( replicatedStorage.modules.client.replication.VFX.AnimationRetriever )
local Animations = replicatedStorage.animations.Attacks.kratos["Chaos Blades"]

return {
    Start = function(Model : Model)
        local Retrieved = AnimationRetriever.new(Model, Animations.Hit)
        if (Retrieved == nil) then return end

        local Animation, MainJob = Retrieved.Animation, Retrieved.Job
        local RootPart, Torso = Retrieved.RootPart, Retrieved.Torso

        if Retrieved.IsLocalSource then
            -- only the player using the move
        end
    end,
}
```

`AnimationRetriever` gives you the track, the rig parts, and a Job scoped to the
animation so cleanup happens when it stops. `IsLocalSource` is how you show
camera work to the user and not to everyone watching.

Shared pieces live in `replication/Global/` — `CameraShake`, `Blood`, `Vignette`,
`RockHandler`, `Smoke`, `MeshVFX`, `RunCameraRig`, `HideAllUI`, `Yuki_FOV`.

> **Limitation:** arguments cross as byteNet `unknown`, which means Instances and
> plain data only. Do not try to send a function or a metatable.

## Hotbar tooltips

Four mechanisms. Which you want depends entirely on whether the label changes.

### 1. A fixed tag under the name

Declared by the move, in the move:

```lua
function Attack.new(...)
    local self = setmetatable(BaseAttack.new(...), Attack)

    self.Properties = { Tip = "[TIMED]" }

    self:_Init()
    return self
end
```

`Properties` rides along with the `createAttack` packet, and
`Hotbar:ApplyTip` reads `Tip` off it when the slot is built. Existing tags in use:
`[TIMED]`, `[COUNTER]`, `[CURSOR AIMED]`, `[HOLD SPACE]`, `[DISABLED]`.

> Read **once**, at registration. It is not live.

### 2. A one-off rename from the move

When something happened and the bar should say so:

```lua
self:ChangeDisplay("Chaos Blades", {
    Tip = "[EMPOWERED]",
    FlashColor = Color3.fromRGB(255, 115, 15),
})
```

Goes out as one `hotbarDisplay` packet with `important` set, which is what makes
the slot flash. Called with no arguments it resets to `self.DisplayName`.

### 3. A label that tracks live state

The air variants — the slot reads *Feral Takedown* while space is held and
*Onslaught* when it is not. Declared by the move, driven on the client so no
packet goes out per keypress:

```lua
self.Properties = {
    Variant = {
        Name   = "Feral Takedown",
        Colour = Color3.fromRGB(191, 0, 0),
        When   = "HoldingSpace",
    },
}
```

`When` must be one of the conditions
`ReplicatedStorage/clientCombat/OnCreatedMoves.luau` knows how to watch:

| `When` | Active while |
| --- | --- |
| `HoldingSpace` | Space is held. |
| `HoldingSpaceOrFalling` | Space is held **or** the player is free-falling, until they land. |
| `AirLockedOrUpTilted` | The `AirLocked` or `UpTilted` attributes are above zero. |

Anything else warns and does nothing. To add a fourth, add a `Watchers` entry to
that file — it is the only place that knows about conditions.

### 4. Visibility

- `self:HideDisplay()` / `self:ShowDisplay()` — take the slot off the bar and put
  it back.
- `self:SetEnabled(false)` — both at once, **and** blocks activation, since
  `Enabled` is part of `BasicConditions`.
- `Properties.HotbarHidden = true` — never build a slot at all. Checked once, by
  the UI. This is why every move in the `Global` folder is invisible.

## Arm flashes

Declared per character, not per move — see [characters.md](characters.md). The M1
reads `Stats.M1.ArmFlashes` keyed by swing number, and calls
`VFX/Global/PunchFlash.luau`:

- `VFX.Arm(Character, Limbs, Colour, Duration)` — `Limbs` is a name or a list.
- `VFX.Highlight(Character, Colour, Duration)`

## Sound

```lua
local Sound = self:CreateMoveSFX(CharacterName, MoveName, SoundName?)
```

Returns a dead `Sound` when `SoundEffectsEnabled` is false, so it is always safe
to call and index.

## Outfits

`Humanoid:ApplyDescription` is **server-only**. To dress a rig, tag it
`RandomDevOutfit` and the observer in
`ReplicatedStorage/modules/shared/Game/Appearances.luau` handles it.

> A rig tagged inside `StarterGui` exists twice as far as the server is
> concerned — the copy in StarterGui and the clone PlayerGui takes per player.
> The observer skips the StarterGui one for that reason. Keep that in mind if you
> tag anything in a GUI.
