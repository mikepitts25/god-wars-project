# Classes & Powers

Six original-IP classes distilled from the classic God Wars archetypes. Each evokes a
familiar supernatural fantasy with **original names/lore** (no borrowed IP). In the
scaffold, **Sanguine** is fully playable; the rest are fully specced here for M2–M3.

## Design rules shared by all classes

- **One signature resource** (sometimes two) that defines the class's economy and rhythm.
- **A transformation or stance** that changes how the class fights.
- **A hard weakness** — a counter every class can exploit (sunlight, silver, holy ground,
  etc.). PK is rock-paper-scissors-ish, not flat.
- **~6 core powers**, advanced by **use** (see `04-progression-pk.md`). A character runs a
  limited number at max rank, forcing build identity (God Wars tradition).
- **Counterplay is documented**, so balance has a target.

---

## Sanguine *(vampire-inspired)* — **playable in scaffold**

- **Fantasy:** an undying bloodborn predator: fast, brutal, deceptive; sustained by feeding.
- **Resource — Vitae (blood):** spent on powers; **refilled by feeding** (life-drain on
  living targets / corpses). Running dry weakens you and risks losing control to **the
  Beast** (frenzy: forced aggression, reduced control).
- **Weakness:** **sunlight** (open daytime/lit zones drain Vitae and apply damage-over-time);
  vulnerable while frenzied.
- **Disciplines (core powers):**
  | Power | Effect |
  |---|---|
  | **Swiftness** | Buff: bonus attack speed / extra strike for a window |
  | **Brutality** | Buff/strike: amplified physical damage |
  | **Resilience** | Buff: damage soak / reduced incoming damage |
  | **Veil** | Stealth: become hard to see/target (broken by attacking) |
  | **Sight** | Reveal hidden/stealthed enemies; detect threats |
  | **Shapecraft** | Form-shift: claws (melee burst), mist (escape/immune-move), beast (brawler) |
  | **Crimson Feed** *(signature)* | Drain HP from target, **refill Vitae** |
- **Counterplay:** force them into sunlight/lit areas; burst them while Vitae-starved or
  frenzied; `Sight`-type reveals beat `Veil`.

---

## Moonbound *(werewolf-inspired)*

- **Fantasy:** feral shapeshifter; explosive melee, regeneration, terror.
- **Resources — Rage + Spirit:** **Rage** builds in combat and fuels brutal powers but high
  Rage risks **frenzy**; **Spirit** powers gifts/regeneration and is restored by ritual/calm.
- **Forms:** **Human** (social/utility, no PK power), **Hybrid** (balanced war form),
  **Beast** (max melee/speed, minimal utility). Shifting costs and gates powers.
- **Weakness:** **silver** (silver weapons bypass regeneration; cripple healing).
- **Core powers:** Rend (heavy bleed strike), Regenerate (spend Spirit to heal), Howl
  (fear/AoE debuff), Razor Hide (armor/thorns), Pounce (gap-close), Lunar Surge (Rage burst).
- **Counterplay:** carry silver; kite the gap-closer; bait frenzy then disengage.

---

## Infernal *(demon-inspired)*

- **Fantasy:** corruptor and summoner; fire, fear, flight.
- **Resource — Corruption:** rises as you use infernal power and by harming others; high
  Corruption boosts damage but draws **holy** retaliation/penalties and marks you on the map.
- **Weakness:** **consecrated/holy ground & holy damage** (sanctuaries hurt; Ascended counter).
- **Core powers:** Hellfire (ranged DoT), Dread Aura (fear/slow), Wings (flight/mobility),
  Summon Fiend (temporary pet), Brimstone Nova (AoE burst), Pact (sacrifice HP for power).
- **Counterplay:** holy damage; bait summons then AoE; deny vertical escapes.

---

## Arcanist *(mage-inspired)*

- **Fantasy:** glass-cannon controller; spheres of magic, rituals and counters.
- **Resource — Mana:** regenerates slowly; rituals (out of combat) prep powerful effects.
- **Spheres (pick specialisation):** **Force** (damage/knockback), **Flesh** (heal/poison),
  **Mind** (charm/silence), **Entropy** (decay/curses), **Ward** (shields/dispels).
- **Weakness:** **fragile** (low soak); vulnerable to silence/interrupt and gap-closers.
- **Core powers:** Bolt (nuke), Ward (absorb shield), Dispel (strip buffs), Blink (short
  teleport), Hex (DoT/curse), Counterspell (interrupt/reflect).
- **Counterplay:** close distance and interrupt; force them to blow defensives early.

---

## Eternal *(highlander-inspired)*

- **Fantasy:** immortal duelist — *"in the end, there can be only one."*
- **Resource — Quickening:** gained primarily by **defeating other Eternals** (a
  beheading/finisher on a downed Eternal grants a large permanent-ish power surge),
  encouraging a tense duel meta among Eternals.
- **Weakness:** no supernatural escape kit — must win the *fight*, not run it; can be ganged.
- **Core powers:** Riposte (counter-attack stance), Surge (Quickening burst), Sword Mastery
  (passive scaling), Challenge (duel lock / forced 1v1 zone), Second Wind (clutch heal),
  Beheading (finisher on downed Eternal).
- **Counterplay:** outnumber them; deny the finisher (rescue downed allies); ranged poke.

---

## Shadowblade *(ninja/assassin-inspired)*

- **Fantasy:** stealth striker; poison, mobility, lethal openers.
- **Resource — Focus:** spent on stealth/mobility/strikes; regenerates out of combat and on
  stealth kills.
- **Weakness:** **low durability**; reveal/detection powers hard-counter the opener; weak
  in prolonged stand-up fights.
- **Core powers:** Shadowstep (teleport-strike), Cloak (stealth), Venom (stacking poison
  DoT), Garrote (silence/burst from stealth), Smoke (escape/blind AoE), Mark (execute
  low-HP targets).
- **Counterplay:** detection (Sanguine `Sight`, Arcanist reveal); area denial; survive the
  burst and they fold.

---

## Stretch classes (documented, post-M3)

- **Revenant** *(lich/undead-inspired)* — necromancy, raise minions, soul/phylactery
  resource, can cheat death once; weak to consecration/turn effects.
- **Ascended** *(angel/holy-inspired)* — holy damage, group support/wards, anti-Infernal/
  anti-undead specialist; weak to corruption stacking and being focused.

## Balance philosophy

Classes are intentionally **asymmetric** with explicit counters. The goal is a PK
metagame where group composition, terrain (sun/holy/dark zones), and timing matter more
than raw numbers. Numbers live in tunable `.tres` data, not code, so balance passes are
data edits (see `08-roadmap-milestones.md`, M4).
