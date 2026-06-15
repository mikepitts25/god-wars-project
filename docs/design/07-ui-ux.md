# UI / UX

Design goal: a clean action HUD **plus a first-class text layer**. The MUD's social and
informational richness (channels, combat log, emotes) is a feature, not legacy baggage.

## 1. Camera & control (2.5D)

- **Constrained third-person / fixed-angle** camera following the player (the agreed 2.5D
  approach): full 3D world, bounded camera to keep art/anim/netcode scope sane.
- **Controls:** WASD / click-to-move movement, mouse for facing/target selection, number
  keys for the ability bar, Tab to cycle targets, Enter to focus chat.
- Camera, input and animation are **client-only**.

## 2. HUD

```
┌───────────────────────────────────────────────────────────────┐
│ [Target frame: name/HP/status]                       [Minimap] │
│                                                                 │
│                       (3D world view)                           │
│                                                                 │
│ [Combat log / floating combat text]                             │
│ ┌─ Self ──────────────┐                                         │
│ │ HP ▓▓▓▓▓▓░░  Vitae ▓▓▓▓░ │   [ 1 2 3 4 5 6 ability bar ]      │
│ └─────────────────────┘                                         │
│ [ Chat panel: tabs = All / Say / Clan / Tell / System ]         │
└───────────────────────────────────────────────────────────────┘
```

- **Self frame:** health bar + class resource bar (Vitae/Rage+Spirit/Mana/etc.), key
  status icons (frenzy, stealth, shield).
- **Ability bar:** known powers with cooldown sweeps and resource-cost affordability; greys
  out when on cooldown / unaffordable / out of range.
- **Target frame:** locked target's name, health, statuses.
- **Minimap:** local zone + nearby entities + portals (full map screen lists the zone graph).
- **Floating combat text + combat log:** every server-resolved hit/heal/effect, mirroring
  the MUD's combat narration (the text soul, now with numbers).

## 3. Chat & channels (the MUD text layer)

A dockable, tabbed chat panel — the heart of the social experience:

| Channel | Scope |
|---|---|
| **Say / Local** | Nearby players in the same zone (proximity) |
| **Global / OOC** | Shard-wide (rate-limited) |
| **Clan** | Members of your clan/coven/pack |
| **Tell / Whisper** | Private 1:1 |
| **System** | Server, combat, and event messages |

- `/say`, `/global`, `/clan`, `/tell <name>`, `/who`, `/emote` style slash commands — a
  direct nod to MUD command input, so MUD veterans feel at home.
- Chat is reliable RPC, server-relayed and server-rate-limited (`06`/`04`).

## 4. Character create / select

- **Login screen:** username + password (`auth_service`), with create-account.
- **Character select:** list of the account's characters (name, class, tier) → enter world,
  or create new.
- **Character create:** name (unique on shard) + **class pick** with a short fantasy blurb,
  resource explainer, and weakness call-out (so players choose with eyes open). Scaffold
  exposes **Sanguine**; UI is data-driven from `ClassDef`s so new classes appear
  automatically.

## 5. Inventory & equipment (M2+)

- Grid inventory + equipment slots (weapon, armor, trinkets, consumables).
- Item tooltips show stats and **class-relevant tags** (e.g. *silver* — bonus vs Moonbound;
  *holy* — bonus vs Infernal/undead), tying gear into the PK counter system.
- Drag-to-equip, right-click consume, drop-to-corpse on death (partial loot, `04`).

## 6. Accessibility & feel

- Scalable UI / font (readability for the text-heavy chat & log).
- Colour-coded channels and damage types; option for high-contrast.
- Audio cues for low health, ability ready, incoming attack.
- Keybind remapping.

## 7. Scaffold UI scope (M0/M1)

Built now: **login**, **character select/create (Sanguine)**, **self HP/Vitae bars**,
**ability bar**, **target frame**, and a **global `say` chat panel + combat log**.
Minimap, inventory/equipment, full channel set, and emotes are M2+.
