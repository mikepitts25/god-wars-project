# World & Zones

## 1. From rooms to zones

The MUD's world was a graph of text **rooms**. *God Wars Reborn* keeps that **graph
structure** but each node is a **3D zone** (a `PackedScene`) rather than a paragraph:

- A **zone** is a contiguous 3D area (terrain, props, colliders, lighting, spawn points,
  ambient mood) sized for moment-to-moment PK and exploration.
- Zones connect via **portals / load triggers** (gates, doors, cave mouths, ley-rifts).
  Crossing one streams the player into the adjacent zone. This is the graphical analog of
  MUD exits (n/s/e/w → portals).
- A **world map / zone graph** describes adjacency, danger tier, and environmental
  properties (lit/dark, consecrated, etc.).

For the single-shard scope we use **per-zone areas with seamless-ish portal transitions**,
not one giant open world — cheaper to build, stream and keep authoritative.

## 2. Zone properties (PK levers)

Each zone carries environmental tags that interact with class weaknesses (`02-classes.md`,
`04-progression-pk.md`):

| Tag | Effect |
|---|---|
| **Lit / Sunlit** | Sanguine takes Vitae drain + DoT; favours anti-vampire play |
| **Dark / Shrouded** | Stealth classes (Shadowblade, Sanguine Veil) thrive |
| **Consecrated / Holy** | Infernal & undead penalised; Ascended empowered |
| **Sanctuary** | No-PK / guarded safe area (hubs, cities) |
| **Contested** | Open PK, clan territory objectives, richer rewards |
| **Wild** | NPC creatures, leveling/farming, ambush-prone |

## 3. Hubs & sanctuaries

- At least one **central hub city** = sanctuary: vendors, trainers, bind/respawn point,
  social space, clan halls. The MUD's "recall point" and town square, in 3D.
- Hubs are where the **community** lives between fights — critical for a PK game's social
  glue. Chat channels (`07-ui-ux.md`) keep the conversation going everywhere.

## 4. NPCs & creatures (mobprog analog)

The MUD's **mobprogs** (scripted mob behaviour) become **state machines / behaviour trees**
on the server:

- **Creatures** (wild zones): patrol → detect → engage → flee/return, with aggro tables.
  Used for leveling, loot, and as PK ambush cover.
- **Guards** (sanctuaries): enforce no-PK, punish flagged aggressors.
- **Vendors / trainers** (hubs): dialog + shop/train interactions.
- **Named/elite** (M3+): rare spawns with unique loot, world-event triggers.

Behaviour is server-authoritative; clients only render NPC state replicated via the
`MultiplayerSynchronizer`. The scaffold ships one creature — the **`target_dummy`**
(health → death → respawn) — proving the NPC + combat + respawn loop.

## 5. World persistence

- **Characters** persist (position, class, level, powers, inventory) — see
  `06-networking-persistence.md`.
- **World objects** that should persist (corpses for their decay window, dropped loot,
  contested-zone control state in M3+) are tracked in `world_state` and flushed by
  `PersistenceService`. Static geometry is baked into zone scenes and not persisted.
- On server restart, characters reload to their last bind/position; transient combat state
  resets.

## 6. Scaffold zone

`zones/sample_zone.tscn` is the M0/M1 playable area:

- Flat-ish terrain + a few colliders/obstacles, spawn point(s), one portal placeholder.
- A **`target_dummy`** creature for combat testing.
- Placeholder primitives / low-poly art (`assets/`) so the loop is playable without an art
  pipeline. Real zone art and the full zone graph are an M2+ effort.
