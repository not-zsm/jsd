# Overview

## The one rule

**The server decides, the client shows.**

The server owns combat state, hitboxes, damage and cooldowns. The client owns
input, UI and every visual effect. Nothing crosses between them except byteNet
packets, all of which are defined in one file.

Almost every bug in this codebase has been a violation of that rule, or a
misunderstanding of when the two sides start up relative to each other.

## Where things live

### Server

| Path | What it is |
| --- | --- |
| `ServerStorage/serverCombat.luau` | The combat engine. State stacks, character switching, grabs, block and parry, the attack registry. |
| `ServerStorage/serverCombat/Attacks/BaseAttack.luau` | The class every move inherits. |
| `ServerStorage/serverCombat/Attacks/List/Global/` | M1, Block, Ultimate, Dash, Vault, WallJump. |
| `ServerStorage/serverCombat/Attacks/List/<character>/` | That character's moves. |
| `ServerStorage/characterData/` | One ModuleScript per character. |
| `ServerScriptService/networker.server.luau` | Every server-side packet listener. |

### Client

| Path | What it is |
| --- | --- |
| `ReplicatedStorage/clientCombat.luau` | Input binding, cooldowns, the aim mouse, and every listener for what the server sends back. |
| `ReplicatedStorage/modules/client/replication/VFX/<character>/` | Per-move visual effects. |
| `ReplicatedStorage/modules/client/replication/Global/` | Shared effect pieces — camera shake, blood, vignette, the punch flash. |
| `StarterPlayer/StarterPlayerScripts/mainClient.luau` | Client startup and the menus. |

### Shared

| Path | What it is |
| --- | --- |
| `ReplicatedStorage/modules/network.luau` | Every packet in the game. |
| `ReplicatedStorage/animations/` | Every animation, addressed by move name. |
| `ReplicatedStorage/ass/` | Per-character self-contained assets. Not wired up yet. |

## How a move fires

1. **Client** — `clientCombat` has the key bound, because the server told it
   which key maps to which move with a `createAttack` packet at character switch.
2. **Packet** — `network.useMove.send{ move, state }`. Press and release are the
   same packet with a boolean, so a charged move needs no second definition.
3. **Server** — `networker` rate-limits it and hands it to `Actions:UseMove`.
4. **Server** — `Attack:ConditionToActivate` gates it, `Attack:Trigger` starts it,
   `Attack:Activate` runs in its own coroutine.
5. **Server** — `Hitbox:BeginCast`, then `Afflict` on whoever it caught. This is
   the only place a hit is decided.
6. **Packet** — `vfx` or `vfxReliable` to every client: a directory, a function
   name, and arguments.
7. **Client** — routed to `VFX/<character>/<Move>.luau` and the named function runs.

## The startup race

Requiring `ReplicatedStorage/modules/network.luau` **yields on the client** until
the server publishes the byteNet namespace. RemoteEvents never imposed that wait,
so code written against them assumes a listener exists the moment the server
wants to send.

Anything the server pushes once, at join, before the client has finished
requiring byteNet and registering listeners, is **dropped silently**.

The fix already in place: the client sends `clientReady` at the end of
`Combat:Connect()`, and the server replays state on receiving it —
`Combat:ResendState()` and `Emotes:ResendState()`.

**If you add anything the server pushes once at join, add it to that replay** or
it will work on your machine and vanish on a slower one. This has caused, so far:
M1 and dash not binding, the entire emote list failing to appear, and the emote
wheel rendering empty.

## Server-only calls worth knowing

Some Roblox APIs only run on the server, and calling them from a LocalScript
raises rather than returning nil:

- `Humanoid:ApplyDescription` — this is why outfits are applied server-side and
  the client receives finished rigs or uses the `RandomDevOutfit` tag.

If a preview looks grey, check whether something is trying to dress it from the
client.
