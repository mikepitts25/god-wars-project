# Roadmap & Milestones

Each milestone has a **Definition of Done (DoD)**. **M0 + M1 are built in the scaffold**;
M2–M4 are planned.

---

## M0 — Connectivity slice  *(built)*

Prove the client/server backbone with no real gameplay.

- Single project boots as client or headless server via `--server` (`boot.gd`).
- `ENetMultiplayerPeer` server/client connect.
- Player spawns into `sample_zone`; **movement is server-authoritative** and replicated.
- **DoD:** two clients connect to one headless server and see each other move smoothly
  (interpolated) in the shared zone, with placeholder capsule characters + fixed camera.

---

## M1 — Vertical slice  *(built)*

The smallest end-to-end "this is the game" loop.

- **Login + character create/select** (`auth_service`, hashed passwords).
- **Persistence:** account → character (class, level, position) saved/loaded via
  `PersistenceService` (JSON impl).
- **Sanguine playable:** Vitae resource + 3–4 data-driven powers (Swiftness, claw strike,
  Crimson Feed, Veil) resolved server-side.
- **Combat:** `combat_system` resolves damage/resource/cooldowns; **`target_dummy`** NPC
  with health → death → respawn; player death → respawn at bind.
- **HUD + chat:** HP/Vitae bars, ability bar, target frame; global `say` channel + combat
  log.
- **DoD:** the full verification checklist (below / plan §Verification) passes — log in,
  move, fight the dummy with abilities, chat, and reload a character after server restart.

---

## M2 — PK & breadth  *(in progress)*

Make it a *player-vs-player* game with more identity.

**Implemented (server-authoritative + validated by smoke tests):**
- **Open-world PK** with combatant **flagging** and **sanctuary** (no-PK) enforcement
  around the hub.
- **Partial loot + corpse retrieval:** death drops a lootable corpse holding part of the
  victim's gold; corpses decay; a looter in range retrieves the gold (`F` key).
- **+2 classes — Moonbound and Shadowblade** (fully data-driven; they appear in character
  create and the ability bar with no client changes).
- **Combat depth:** flat **soak** mitigation and class **weakness multipliers** by damage
  type (e.g. silver vs Moonbound), plus new effects: **DOT** (bleed/poison), **fear**,
  **slow**, and **teleport** gap-closers.

**Remaining for M2:**
- **Inventory & equipment** (slots, items, class-tag gear: silver/holy) and its UI.
- **Multiple zones + portals** and a basic zone graph (currently one arena + hub
  sanctuary); requires per-zone interest management on the wire.
- Client-side polish for PK feedback (flag indicator, status icons).

- **DoD:** two players of different classes can PK in a contested zone, loot/retrieve
  corpses, and retreat to a guarded hub; gear affects outcomes.

---

## M3 — Depth & community

Turn the slice into a living world.

- **Full roster** (Infernal, Arcanist, Eternal; stretch: Revenant, Ascended).
- **Advancement-by-use** with power ranks and primary-power slots (`04`).
- **Clans/tribes** + clan chat + basic territory/renown objectives.
- **NPC behaviour trees** (mobprog analog): creatures, guards, vendors/trainers, named
  elites.
- **Admin/Immortal tools** (teleport, mute, jail, ban, spawn, inspect).
- **DoD:** a small live group can form clans, advance powers by play, fight over a contested
  zone, and be moderated by staff tools.

---

## M4 — Polish, balance & ops

Ship-readiness.

- **Animation blending, audio, VFX** pass; UI polish (minimap, full channels, emotes).
- **Balance pass** across classes/weaknesses (data-only tuning).
- **Reconnection/session hardening** (session tokens) and **persistence backend swap**
  (SQLite/Postgres impl of `PersistenceService`).
- **Linux dedicated-server packaging** (headless export + container) and deployment;
  autosave/backup; basic metrics & logging.
- **DoD:** a stable, balanced shard runs unattended on a Linux host, survives restarts with
  no character loss, and handles dozens of concurrent players.

---

## Sequencing notes

- Everything after M1 is **content + tuning on the same engine spine** — data-driven
  classes/abilities/zones (`01` §5) mean breadth (M2–M3) is mostly authoring, not new
  systems.
- The **persistence interface** (`06` §5) and **server authority** (`01`/`03`) are designed
  up front specifically so M4 ops/scale work doesn't require rewrites.
