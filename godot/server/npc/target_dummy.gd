class_name TargetDummy
extends RefCounted

## Configuration for the scaffold's sample creature (docs/design/05-world-zones.md).
## NPCs are server-side entities in WorldState (not scene nodes), so this just
## describes how to build one. M3 replaces static NPCs with behaviour trees.

const DISPLAY_NAME := "Training Dummy"
const MAX_HEALTH := 80.0
const SPAWN_POSITION := Vector3(0.0, 0.0, -8.0)

# Applied to a freshly created WorldState.Entity.
static func configure(entity) -> void:
	entity.kind = GameConstants.Kind.NPC
	entity.display_name = DISPLAY_NAME
	entity.max_health = MAX_HEALTH
	entity.health = MAX_HEALTH
	entity.max_resource = 0.0
	entity.resource = 0.0
	entity.resource_regen = 0.0
	entity.position = SPAWN_POSITION
	entity.spawn_pos = SPAWN_POSITION
