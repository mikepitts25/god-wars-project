class_name GameConstants
extends RefCounted

## Project-wide constants and enums shared by client and server.
## (A plain named class — globally available without an autoload.)

const DEFAULT_PORT := 7777
const DEFAULT_HOST := "127.0.0.1"
const MAX_CLIENTS := 40            # matches Godot/ENet practical single-shard ceiling
const SNAPSHOT_HZ := 20.0
const PLAYER_SPEED := 7.0
const ZONE_HALF_EXTENT := 40.0      # square arena half-size (metres)
const RESPAWN_TIME := 6.0

# PK / world rules (docs/design/04-progression-pk.md, 05-world-zones.md).
const PK_FLAG_DURATION := 15.0
const SANCTUARY_CENTER := Vector3(0.0, 0.0, 6.0)   # spawn hub = no-PK sanctuary
const SANCTUARY_RADIUS := 12.0
const CORPSE_DECAY := 60.0
const LOOT_RANGE := 3.5
const SLOW_MULT := 0.5
const START_GOLD := 50

# Chat channels (mirrors docs/design/07-ui-ux.md).
enum Channel { SYSTEM, SAY, GLOBAL, CLAN, TELL }

# Ability effect descriptors (interpreted by combat_system.gd).
# Order is append-only so saved data / indices stay stable.
enum Effect { DAMAGE, DRAIN, BUFF_HASTE, STEALTH, HEAL, DOT, FEAR, SLOW, TELEPORT }

# Damage types — drive class weakness multipliers (e.g. silver vs Moonbound).
enum DamageType { PHYSICAL, SILVER, HOLY, FIRE, POISON, ARCANE }

# Entity kinds tracked by the authoritative world.
enum Kind { PLAYER, NPC, CORPSE }
