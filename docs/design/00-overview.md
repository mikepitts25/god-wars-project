# God Wars Reborn — Design Overview

> A graphical reimagining of the classic, PK-focused **God Wars** MUD
> (KaVir / Richard Woolcock, 1995) as a **2.5D multiplayer game built in Godot 4**.

---

## 1. Pitch

*God Wars Reborn* is a persistent-world, **player-vs-player** action game where
supernatural beings — bloodborn, beast-kin, infernals, mages, immortals and assassins —
hunt, scheme and war with one another for dominance. It keeps the soul of the original
God Wars MUD (deep class identity, brutal open-world PK, advancement-by-mastery, a living
chat-driven community) while expressing it through a real-time 3D world with a constrained
camera and a first-class text/chat layer.

It is **not** a faithful clone of any IP. The classic God Wars roster borrows heavily from
White Wolf's *World of Darkness*; *God Wars Reborn* uses **original names and lore** that
evoke the same fantasy without the borrowed IP.

## 2. Design Pillars

1. **Supernatural PK first.** Combat between players is the centre of gravity. Every
   system (progression, loot, world design) feeds the rivalry loop.
2. **Deep class identity.** Each class plays unmistakably differently — its own resource,
   weaknesses, transformation/utility, and counterplay. You should be able to tell who
   killed you by *how* you died.
3. **Persistent, dangerous world.** One shared shard. Characters persist. Death has teeth
   (corpse + partial loot), tempered by sanctuaries so the world isn't pure griefing.
4. **Mastery, not grind.** Powers advance by *use* (God Wars tradition), not by farming
   filler. Skill expression > gear treadmill.
5. **The text layer matters.** Chat channels, combat log, and emotes are first-class UI —
   the MUD's social and informational richness is preserved, not discarded.

## 3. Genre & Reference Points

- **Roots:** God Wars MUD family — PK-centric, supernatural, advancement-by-use.
- **Combat feel:** real-time action with soft-targeting and resource/cooldown abilities
  (a real-time translation of the MUD's auto-combat-plus-disciplines model).
- **Camera/scope:** 2.5D — full 3D world and characters with a **constrained
  third-person / fixed-angle** camera to bound art, animation and netcode cost.

## 4. Platform & Tech

- **Engine:** Godot 4.3+ (GDScript).
- **Targets:** Desktop — Windows, Linux, macOS. Linux **headless dedicated server**.
- **Networking:** Authoritative server, single persistent shard, Godot high-level
  Multiplayer API over `ENetMultiplayerPeer`. See `01-technical-architecture.md`.
- **Persistence:** Account → character model; JSON-backed in the scaffold, SQLite/Postgres
  documented as the production path. See `06-networking-persistence.md`.

## 5. Scope & Scale

- **Single persistent shard.** One world server, **dozens of concurrent players**
  (Godot/ENet practical ceiling is ~40 concurrent before connection stress; this matches
  classic MUD population and our PK design).
- **Roster:** six original-IP classes specced (one — **Sanguine** — fully playable in the
  scaffold). Two stretch classes documented.
- **Not in scope (initially):** sharding/horizontal scale, instanced dungeons, mobile,
  controller-first UX, voice.

## 6. Target Audience

- Former/current MUD players (especially God Wars / PK MUD veterans) wanting a graphical
  home.
- PvP-driven players who value mastery, rivalry and high-stakes open worlds over
  theme-park PvE.

## 7. Player Fantasy (the 30-second hook)

> *You are not a hero. You are a predator in a world of predators. Master your blood, your
> rage, your forbidden art — then prove it on everyone who shares the night with you.*

## 8. Document Map

| Doc | Covers |
|---|---|
| `01-technical-architecture.md` | Client/server split, netcode, authority, project boot |
| `02-classes.md` | Original-IP class roster, resources, abilities, progression |
| `03-combat.md` | Real-time combat model, damage, statuses, death |
| `04-progression-pk.md` | Advancement-by-use, PK rules, loot, clans, renown |
| `05-world-zones.md` | Zone graph, NPCs/mobprog analog, hubs/sanctuaries |
| `06-networking-persistence.md` | Auth, sessions, save model, persistence interface |
| `07-ui-ux.md` | HUD, chat/channels, char create/select, inventory |
| `08-roadmap-milestones.md` | M0–M4 milestones and definitions of done |
