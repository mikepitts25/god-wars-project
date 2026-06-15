# Technical Architecture

## 1. One project, two roles

*God Wars Reborn* is a **single Godot 4 project** that boots as either a **client** or a
**headless authoritative server**, decided at runtime by a command-line flag. This avoids
duplicating shared code (entity definitions, class/ability data, constants, RPC contracts)
across two projects.

```
godot --headless -- --server     # boots server_main (authoritative world)
godot                            # boots client_main (rendering + input + UI)
```

`boot.gd` (autoload) inspects `OS.get_cmdline_user_args()` / `OS.has_feature(
"dedicated_server")` and changes the scene to `server/server_main.tscn` or
`client/client_main.tscn` accordingly.

## 2. Authority model

The **server is authoritative for all game state**: positions, health, resources,
cooldowns, ability effects, NPCs, loot, persistence. Clients are "dumb-ish" renderers that:

- send **input intents** (movement vector, "use ability N on target T", "say <msg>");
- **predict their own movement** locally for responsiveness and **interpolate** other
  entities;
- never decide damage, resource changes, hit/miss, or death.

This is the standard anti-cheat posture: a malicious client can lie about its inputs but
the server validates everything (range checks, cooldown checks, resource checks,
line-of-sight) before applying effects.

```
┌─────────────┐  inputs (RPC)   ┌────────────────────┐
│   Client    │ ───────────────►│  Authoritative      │
│ (render/UI/ │                 │  Server (headless)   │
│  predict)   │◄─────────────── │  world_state +       │
└─────────────┘  state sync     │  combat_system       │
                  (Synchronizer) └────────┬───────────┘
                                          │ save/load
                                          ▼
                                 PersistenceService
                                 (JSON now → SQLite later)
```

## 3. Transport & replication

- **Transport:** `ENetMultiplayerPeer` (UDP, reliable + unreliable channels) via Godot's
  high-level Multiplayer API. Server: `create_server(port, max_clients)`. Client:
  `create_client(host, port)`.
- **Spawning:** `MultiplayerSpawner` spawns/despawns player and NPC scenes across peers
  as they enter/leave the zone.
- **State sync:** `MultiplayerSynchronizer` replicates authoritative properties (position,
  health, resource, status flags) from server to clients. Movement uses unreliable sync
  with interpolation; discrete events (ability cast, death, chat) use reliable RPCs.
- **Input:** clients call `@rpc("any_peer", "call_remote", "reliable")` /
  `unreliable_ordered` server methods. The server checks `multiplayer.get_remote_sender_id()`
  to attribute and validate the input.

## 4. Server tick & systems

The server runs a fixed simulation step (e.g. 20–30 Hz) in `world_state.gd`:

1. Apply queued, validated player inputs (movement, ability requests).
2. Advance NPC behaviour (`server/npc/*`).
3. `combat_system.gd` resolves ability effects, damage, status ticks (bleed/regen),
   resource regen, deaths.
4. Mark dirty state for `MultiplayerSynchronizer` replication.
5. Periodically flush persistence (autosave) via `PersistenceService`.

Rendering, animation and camera are **client-only** (`client/`), so the headless server
spends nothing on them.

## 5. Data-driven content

Classes and abilities are **Godot `Resource` types**, not hard-coded:

- `shared/data/class_def.gd` — a class (display name, base stats, resource type, ability
  list, weaknesses).
- `shared/data/ability_def.gd` — an ability (cost, cooldown, range, cast time, effect
  descriptor).

Content is authored as `.tres` files (e.g. `shared/classes/sanguine.tres`). The
`combat_system` interprets `AbilityDef` effect descriptors generically, so **adding a new
class/ability is data authoring, not new code paths** — critical for shipping M2+ classes
cheaply.

## 6. Persistence boundary

`server/persistence_service.gd` exposes a narrow interface (`load_account`,
`save_character`, `create_character`, etc.). The scaffold implements it with JSON files
under `user://`; production swaps to SQLite/Postgres **without touching callers**. See
`06-networking-persistence.md`.

## 7. Directory layout

```
godot/
  project.godot
  boot.gd
  shared/      # code+data shared by client & server (constants, net contract, defs)
  server/      # authoritative world, combat, NPCs, auth, persistence
  client/      # rendering, input, camera, HUD, chat, char select
  zones/       # 3D playable areas (sample_zone.tscn)
  assets/      # placeholder primitives / low-poly art
```

## 8. Known constraints & mitigations

| Constraint | Mitigation |
|---|---|
| ENet ~40 concurrent practical ceiling | Single shard targets dozens of players by design |
| No built-in reconnection (new peer id on reconnect) | `auth_service` re-binds a reconnecting account to its character; session token planned for M4 |
| No built-in auth/lobby | `auth_service` (hashed password) in scaffold; pluggable external backend later |
| Cheating | Full server authority + server-side validation of every input |
