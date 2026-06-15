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

# Chat channels (mirrors docs/design/07-ui-ux.md).
enum Channel { SYSTEM, SAY, GLOBAL, CLAN, TELL }

# Ability effect descriptors (interpreted by combat_system.gd).
enum Effect { DAMAGE, DRAIN, BUFF_HASTE, STEALTH, HEAL }

# Entity kinds tracked by the authoritative world.
enum Kind { PLAYER, NPC }
