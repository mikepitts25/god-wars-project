class_name WorldState
extends Node

## Authoritative world: owns every entity, runs the fixed simulation tick, and
## broadcasts state snapshots to all clients. Rendering/animation live only on
## the client (docs/design/01-technical-architecture.md).

# A single simulated entity (player or NPC). Kept as a lightweight object rather
# than a scene node so the headless server spends nothing on rendering.
class Entity:
	var id: int
	var kind: int = GameConstants.Kind.PLAYER
	var owner_peer: int = 0
	var char_id: String = ""
	var class_id: String = ""
	var display_name: String = ""
	var position := Vector3.ZERO
	var yaw := 0.0
	var move_input := Vector3.ZERO
	var health := 100.0
	var max_health := 100.0
	var resource := 100.0
	var max_resource := 100.0
	var resource_regen := 1.0
	var cooldowns := {}          # ability_id (StringName) -> seconds remaining
	var statuses := {}           # status name (String) -> seconds remaining
	var alive := true
	var respawn_in := 0.0
	var spawn_pos := Vector3.ZERO
	var class_def: ClassDef = null

var entities := {}               # id -> Entity
var _next_id := 1000
var _snapshot_accum := 0.0
@onready var _net: Node = get_node_or_null("/root/Net")

func _ready() -> void:
	_spawn_dummy()

# --- spawning -----------------------------------------------------------
func _spawn_dummy() -> void:
	var e := Entity.new()
	e.id = _alloc_id()
	TargetDummy.configure(e)
	entities[e.id] = e

func spawn_player(peer: int, char_data: Dictionary, class_def: ClassDef) -> int:
	var e := Entity.new()
	e.id = _alloc_id()
	e.kind = GameConstants.Kind.PLAYER
	e.owner_peer = peer
	e.char_id = String(char_data.get("id", ""))
	e.class_id = class_def.id
	e.display_name = String(char_data.get("name", "Unknown"))
	e.class_def = class_def
	e.max_health = class_def.max_health
	e.health = float(char_data.get("health", class_def.max_health))
	e.max_resource = class_def.max_resource
	e.resource = float(char_data.get("resource", class_def.max_resource))
	e.resource_regen = class_def.resource_regen
	e.position = Vector3(float(char_data.get("px", 0.0)), 0.0, float(char_data.get("pz", 6.0)))
	e.spawn_pos = e.position
	entities[e.id] = e
	return e.id

func remove_player(peer: int) -> void:
	var id := find_player_id(peer)
	if id != 0:
		entities.erase(id)

func find_player_id(peer: int) -> int:
	for id in entities:
		var e: Entity = entities[id]
		if e.kind == GameConstants.Kind.PLAYER and e.owner_peer == peer:
			return id
	return 0

func _alloc_id() -> int:
	_next_id += 1
	return _next_id

# --- input + intents (validated upstream by sender id) ------------------
func set_input(peer: int, move_x: float, move_z: float, yaw: float) -> void:
	var id := find_player_id(peer)
	if id == 0:
		return
	var e: Entity = entities[id]
	var v := Vector3(move_x, 0.0, move_z)
	e.move_input = v.normalized() if v.length() > 1.0 else v
	e.yaw = yaw

func request_ability(peer: int, ability_idx: int, target_id: int) -> Dictionary:
	var id := find_player_id(peer)
	if id == 0:
		return {"ok": false, "reason": "no_entity"}
	var caster: Entity = entities[id]
	if caster.class_def == null or ability_idx < 0 or ability_idx >= caster.class_def.abilities.size():
		return {"ok": false, "reason": "bad_ability"}
	var ability: AbilityDef = caster.class_def.abilities[ability_idx]
	var target = entities.get(target_id, null)
	return CombatSystem.resolve_ability(caster, ability, target)

# --- simulation tick ----------------------------------------------------
func _physics_process(delta: float) -> void:
	for id in entities:
		_tick_entity(entities[id], delta)

	_snapshot_accum += delta
	if _snapshot_accum >= 1.0 / GameConstants.SNAPSHOT_HZ:
		_snapshot_accum = 0.0
		if _net != null:
			_net.rpc("snapshot", build_snapshot())

func _tick_entity(e: Entity, delta: float) -> void:
	# Respawn handling.
	if not e.alive:
		e.respawn_in -= delta
		if e.respawn_in <= 0.0:
			e.alive = true
			e.health = e.max_health
			e.resource = e.max_resource * 0.5
			e.position = e.spawn_pos
			e.move_input = Vector3.ZERO
			e.statuses.clear()
		return

	# Movement (simple authoritative integration; collision is M2+).
	if e.kind == GameConstants.Kind.PLAYER and e.move_input.length() > 0.01:
		e.position += e.move_input * GameConstants.PLAYER_SPEED * delta
		var b := GameConstants.ZONE_HALF_EXTENT
		e.position.x = clampf(e.position.x, -b, b)
		e.position.z = clampf(e.position.z, -b, b)

	# Resource regen.
	if e.resource < e.max_resource:
		e.resource = minf(e.max_resource, e.resource + e.resource_regen * delta)

	# Cooldowns + statuses countdown.
	for k in e.cooldowns.keys():
		e.cooldowns[k] = float(e.cooldowns[k]) - delta
		if e.cooldowns[k] <= 0.0:
			e.cooldowns.erase(k)
	for k in e.statuses.keys():
		e.statuses[k] = float(e.statuses[k]) - delta
		if e.statuses[k] <= 0.0:
			e.statuses.erase(k)

# --- replication --------------------------------------------------------
func build_snapshot() -> Array:
	var out: Array = []
	for id in entities:
		var e: Entity = entities[id]
		out.append({
			"id": e.id,
			"kind": e.kind,
			"class_id": String(e.class_id),
			"name": e.display_name,
			"px": e.position.x,
			"pz": e.position.z,
			"yaw": e.yaw,
			"hp": e.health,
			"max_hp": e.max_health,
			"res": e.resource,
			"max_res": e.max_resource,
			"alive": e.alive,
			"stealth": e.statuses.has("stealth"),
		})
	return out

# Snapshot a player's current state back into its character record for saving.
func write_back(peer: int, char_data: Dictionary) -> void:
	var id := find_player_id(peer)
	if id == 0:
		return
	var e: Entity = entities[id]
	char_data["px"] = e.position.x
	char_data["pz"] = e.position.z
	char_data["health"] = e.health
	char_data["resource"] = e.resource
