# God Wars Reborn

A **2.5D multiplayer reimagining of the classic God Wars MUD**, built in **Godot 4**.
Supernatural, PK-focused classes; an authoritative single-shard server; persistent
characters — the soul of the MUD in a real-time 3D world with a first-class chat layer.

> Original IP inspired by the God Wars MUD family — it evokes the fantasy without using
> any borrowed names/lore.

## Repository layout

```
docs/design/      Full Game Design Document (read 00-overview.md first)
godot/            Godot 4 project (the runnable scaffold)
  shared/         Code + data shared by client and server
  server/         Authoritative world, combat, auth, persistence
  client/         Rendering, input, camera, HUD, chat, login/char-select
  zones/          Sample area (built in code in the scaffold)
  tests/          Headless smoke test
```

## Design documents

Start with **[`docs/design/00-overview.md`](docs/design/00-overview.md)**. The set covers
overview, technical architecture, classes, combat, progression/PK, world/zones,
networking/persistence, UI/UX, and the M0–M4 roadmap.

## What the scaffold implements (M0 + M1)

- Single project that boots as **client** or **headless authoritative server**.
- **ENet** networking via Godot's high-level Multiplayer API (server-authoritative).
- **Login + account/character create/select**, JSON-backed persistence.
- One playable class — **Sanguine** — with the **Vitae** resource and 4 data-driven
  abilities, resolved server-side.
- **Combat** vs. a respawning **Training Dummy**; resource/cooldown/range validation.
- **2.5D** fixed-angle camera, HUD (health/resource/ability bar/target frame), and a
  **global chat + combat log**.

## M2 additions (in progress)

- **Three playable classes:** Sanguine, **Moonbound** (Rage; weak to silver), and
  **Shadowblade** (Focus; fragile) — all data-driven.
- **Combat depth:** soak mitigation, class **weakness multipliers** (damage types), and
  **DOT / fear / slow / teleport** effects.
- **Open-world PK:** combatant flagging + **sanctuary** (no-PK) around the hub.
- **Death & loot:** lootable, decaying **corpses** with partial gold loot (press **F** to
  loot in range); gold persists.

Remaining M2 work (inventory/equipment, multiple zones + portals) and everything after
(clans, quests, polish, deployment) is tracked in the roadmap.

## Requirements

- **Godot 4.3+** (`gl_compatibility` renderer; works on modest hardware).

## Running

**You always need a server running plus one or more clients** — launching only a
client (e.g. the editor) leaves it unconnected and login will fail.

The quickest way to start the server (auto-detects Godot, incl. `Godot.app` on macOS):

```bash
./run-server.sh
```

Or invoke Godot directly from the repo root:

```bash
# 1) Start the authoritative server (headless, binds UDP 7777)
godot --headless --path godot -- --server

# 2) Start one or more clients (separate terminals / machines)
godot --path godot
#   optional: connect to a remote host
#   godot --path godot -- --host 1.2.3.4 --port 7777
```

In each client: create an account → create a character (**Sanguine / Moonbound /
Shadowblade**) → enter the world. **WASD** move, **1–4** abilities, **Tab** target,
**F** loot a nearby corpse, **Enter** chat.

## Tests

Headless gameplay smoke test (auth + combat resolution):

```bash
godot --headless --path godot --script res://tests/smoke_test.gd
```

## Status

Greenfield scaffold + design plan. The networking model, data-driven class/ability system,
and persistence boundary are built so breadth (more classes, zones, PK systems) is largely
content authoring, not new engine work.
