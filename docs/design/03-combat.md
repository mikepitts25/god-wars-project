# Combat System

A real-time translation of the MUD's auto-combat-plus-disciplines model. The MUD resolved
rounds on a timer while players layered discipline/power activations; *God Wars Reborn*
keeps that **"auto-rhythm + active powers"** feel in real time, fully server-authoritative.

## 1. Targeting

- **Soft-target:** click/tab a target to "lock" it; the target frame shows its health and
  status. Most abilities require a valid locked target in range/LOS.
- **Action abilities** (AoE, dashes, ground effects) aim from facing/position rather than a
  locked target.
- Targeting is a **client convenience**; the server re-validates target, range and
  line-of-sight before applying any effect.

## 2. Ability execution pipeline (server-authoritative)

When a client requests "use ability N on target T":

1. **Validate** ownership, that the character knows ability N, **cooldown** ready,
   **resource** sufficient, **range/LOS** to T, and caster state (not stunned/silenced).
2. **Commit cost:** deduct resource, start cooldown, apply **cast time / GCD**.
3. **Resolve effect** from the `AbilityDef` effect descriptor:
   - *instant* (strike, heal, resource drain), *projectile* (travels, server-simulated),
     *buff/debuff* (timed status), *form/stance change*, *summon*, *movement* (dash/blink,
     server-clamped).
4. **Apply** damage/heal/status via `combat_system`; broadcast a reliable event for
   client VFX/SFX/log.

A malformed or cheating request fails at step 1 and is dropped (optionally logged).

## 3. Damage & mitigation model

```
raw            = base_damage * power_scaling (+ buffs like Brutality)
post_soak      = max(0, raw - soak)          # flat soak (Resilience, armor)
post_armor     = post_soak * (1 - armor_pct) # percentage mitigation
final          = post_armor * weakness_mult  # e.g. silver vs Moonbound, holy vs Infernal
```

- **Soak** = flat reduction (heavy/defensive builds). **Armor %** = scaling reduction.
- **Weakness multipliers** implement the class counters from `02-classes.md`
  (silver→Moonbound, holy→Infernal, etc.).
- **Resources** gate sustained pressure: you can't spam your best powers without feeding/
  building Rage/regenerating Mana.

## 4. Status effects

Standard timed statuses ticked on the server each step:

| Status | Effect |
|---|---|
| **Bleed / DoT** | Periodic damage (Rend, Venom, Hellfire) |
| **Regen / HoT** | Periodic heal (Moonbound Regenerate, Sanguine feed) |
| **Fear** | Reduced control / forced movement (Howl, Dread Aura) |
| **Frenzy** | Class loss-of-control (Sanguine Beast, Moonbound Rage overflow) |
| **Root / Slow** | Movement denial/reduction (control) |
| **Silence / Stun** | Ability denial (interrupt casters) |
| **Stealth** | Hard to see/target; broken by attacking (Veil, Cloak) |
| **Shield / Ward** | Absorb pool consumed before HP (Arcanist Ward) |

Statuses are data on the `AbilityDef` effect, so new ones are mostly content, not code.

## 5. Auto-attack rhythm

To preserve the MUD's continuous-combat feel, locking a target in range engages an
**auto-attack** at a class/weapon cadence (server-resolved). Active powers layer on top —
exactly the "rounds tick while you fire disciplines" cadence of the original, just real
time. Movement out of range pauses auto-attack.

## 6. Death, corpse & respawn

- At 0 HP a character enters **Downed** (brief window; some classes have clutch escapes —
  Eternal Second Wind, Revenant cheat-death).
- If not saved, the character **dies** → a **corpse** object spawns holding droppable loot
  (partial-loot rules in `04-progression-pk.md`).
- The player **respawns** at the zone's bind/spawn point after a short timer, at reduced
  resource. **Eternal beheading** finisher converts a downed Eternal kill into Quickening.
- NPC death (`target_dummy` in the scaffold) drops loot/credit and **respawns** on a timer.

## 7. Flee / wimpy analog

- **Flee:** disengage and sprint; movement powers (Blink, Mist, Wings, Shadowstep) are the
  premium escape tools and a key part of class identity.
- **Wimpy (auto-flee):** optional client setting that auto-disengages and retreats below a
  health threshold (sends a flee intent the server honours) — a nod to MUD `wimpy`.

## 8. Client responsibilities (and limits)

- Predict **own movement**; interpolate others; play VFX/SFX from server events; show
  cooldowns/resources in the HUD; render the combat log.
- The client **never** decides hit/miss, damage, resource changes, or death. All of that is
  the server's, replicated back. This keeps PK fair on a public shard.
