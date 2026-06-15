# Progression, PK & Social Systems

## 1. Advancement by use (God Wars tradition)

Powers grow by **using them**, not by grinding filler XP:

- Each known power has a **rank** (e.g. 1→max). Using a power successfully grants progress
  toward its next rank; higher ranks cost less / hit harder / unlock upgrades.
- A character can keep only a **limited number of powers at max rank** ("primary powers" —
  a God Wars staple). This forces **build identity**: a Sanguine maxing Swiftness+Brutality+
  Crimson Feed plays very differently from one maxing Veil+Sight+Shapecraft.
- **Tier/level** is a coarse gate (unlocks power slots, base stats, zone access). It rises
  from meaningful activity (PK, tough NPCs, quests), not trash farming.

This keeps the curve about **mastery and specialisation**, matching the MUD's identity.

## 2. PK rules

The world is **open-world PvP by default**, with structure so it's rivalry, not pure
grief:

- **Flagging:** attacking another player flags you as a combatant; sanctuaries and guards
  punish unprovoked aggression in safe areas.
- **Sanctuaries / safe zones:** hubs and cities (see `05-world-zones.md`) are **no-PK**
  (or heavily guarded). Players need somewhere to socialise, trade and respawn.
- **Zone hazards as PK levers:** sunlight zones punish Sanguine; consecrated ground punishes
  Infernal/undead; darkness favours stealth. Terrain is a tactical PK resource.
- **Level/tier brackets (optional):** soft protection or penalties for ganking far-lower
  characters, to keep new players from being farmed off the shard.

## 3. Loot & death stakes

**Recommendation: partial loot + corpse retrieval** (the sweet spot between MUD stakes and
player retention):

- On death, a **corpse** holds a *subset* of carried items (e.g. unequipped/marked-droppable
  consumables and currency), **not** your whole character. Bound/soulbound power gear stays.
- The **killer** can loot the corpse; the **victim** can race back to retrieve what's left
  before it decays.
- This preserves real risk (you can lose something meaningful) without the full-loot death
  spiral that bleeds population. Full-loot can be a **hardcore opt-in ruleset** later.

## 4. Clans / tribes

- Players form **clans** (covens, packs, circles, clans — flavoured per fiction) with a
  name, roster, ranks, and a **clan chat channel**.
- Clans enable group PK identity, shared territory goals, and rivalries — the backbone of
  MUD social longevity.
- **Territory/renown objectives** (M3+): control of contested zones, kill-based standings,
  clan-vs-clan war declarations.

## 5. Renown / reputation

- **Renown** tracks PK prowess and notable deeds (kills, beheadings, territory holds). It
  feeds leaderboards/titles and can gate prestige cosmetics or power unlocks.
- Per-class flavour: Eternal Quickening (power from defeating Eternals), Moonbound Renown
  (tribe standing), Sanguine elder status, etc.

## 6. Economy (lightweight, PK-serving)

- Currency and consumables drop from NPCs and corpses; vendors in sanctuaries sell
  utility (not power shortcuts).
- The economy exists to **fuel PK** (potions, silver weapons vs Moonbound, holy items vs
  Infernal, escape tools) — not as an end in itself.

## 7. Anti-grief & moderation

- **Admin/Immortal tools** (M3): teleport, mute, jail, ban, spawn, inspect — the MUD
  "Immortal" staff role, modernised.
- Server-side rate limits on chat and combat-spam; report/log pipeline for abuse review.

## 8. Progression data is tunable

Rank curves, power slot counts, weakness multipliers, loot tables and renown values live in
`.tres`/JSON data (see `01-technical-architecture.md` §5), so balancing PK is a tuning pass,
not an engineering project.
