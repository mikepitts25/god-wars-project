class_name WorldState
extends Node

## Authoritative world: owns every entity, runs the fixed simulation tick, and
## broadcasts state snapshots to all clients. Rendering/animation live only on
## the client (docs/design/01-technical-architecture.md).

# A single simulated entity (player, NPC or corpse). Kept as a lightweight
# object rather than a scene node so the headless server spends nothing on
# rendering.
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
	var soak := 0.0
	var weakness_damage_type := -1
	var weakness_mult := 1.5
	var cooldowns := {}          # ability_id (StringName) -> seconds remaining
	var statuses := {}           # status name (String) -> seconds remaining
	var dots: Array = []         # active damage-over-time effects
	var pk_flag := 0.0           # seconds remaining as a flagged combatant
	var gold := 0
	var loot_gold := 0           # for corpses
	var decay := 0.0             # corpse decay timer
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
	e.soak = class_def.soak
	e.weakness_damage_type = class_def.weakness_damage_type
	e.weakness_mult = class_def.weakness_mult
	e.gold = int(char_data.get("gold", GameConstants.START_GOLD))
	e.position = Vector3(float(char_data.get("px", 0.0)), 0.0, float(char_data.get("pz", 6.0)))
	e.spawn_pos = GameConstants.SANCTUARY_CENTER
	entities[e.id] = e
	return e.id

func spawn_corpse(pos: Vector3, owner_name: String, gold: int) -> int:
	var e := Entity.new()
	e.id = _alloc_id()
	e.kind = GameConstants.Kind.CORPSE
	e.display_name = "Corpse of %s" % owner_name
	e.alive = false
	e.position = pos
	e.loot_gold = gold
	e.decay = GameConstants.CORPSE_DECAY
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

func in_sanctuary(pos: Vector3) -> bool:
	return pos.distance_to(GameConstants.SANCTUARY_CENTER) <= GameConstants.SANCTUARY_RADIUS

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

	# PK gating: players cannot be harmed in a sanctuary.
	if target != null and target.kind == GameConstants.Kind.PLAYER and target.id != caster.id:
		if in_sanctuary(caster.position) or in_sanctuary(target.position):
			return {"ok": false, "reason": "sanctuary"}

	var event := CombatSystem.resolve_ability(caster, ability, target)
	if event.get("ok", false):
		if target != null and event.has("damage") and target.kind == GameConstants.Kind.PLAYER and caster.kind == GameConstants.Kind.PLAYER:
			caster.pk_flag = GameConstants.PK_FLAG_DURATION
			target.pk_flag = GameConstants.PK_FLAG_DURATION
		if event.has("killed"):
			_on_entity_killed(entities.get(int(event["killed"]), null))
	return event

func request_loot(peer: int, corpse_id: int) -> Dictionary:
	var id := find_player_id(peer)
	if id == 0:
		return {"ok": false, "reason": "no_entity"}
	var looter: Entity = entities[id]
	var corpse = entities.get(corpse_id, null)
	if corpse == null or corpse.kind != GameConstants.Kind.CORPSE:
		return {"ok": false, "reason": "no_corpse"}
	if looter.position.distance_to(corpse.position) > GameConstants.LOOT_RANGE:
		return {"ok": false, "reason": "too_far"}
	var gold: int = corpse.loot_gold
	looter.gold += gold
	entities.erase(corpse_id)
	return {"ok": true, "type": "loot", "looter": looter.id, "looter_name": looter.display_name, "gold": gold}

# Death consequences: players drop a lootable corpse (partial loot).
func _on_entity_killed(victim) -> void:
	if victim == null or victim.kind != GameConstants.Kind.PLAYER:
		return
	var dropped := int(victim.gold / 2)
	if dropped > 0:
		victim.gold -= dropped
		spawn_corpse(victim.position, victim.display_name, dropped)
	if _net != null:
		_net.rpc("combat_event", {"type": "death", "victim": victim.id, "victim_name": victim.display_name})

# --- simulation tick ----------------------------------------------------
func _physics_process(delta: float) -> void:
	var to_remove: Array = []
	for id in entities:
		var e: Entity = entities[id]
		_tick_entity(e, delta)
		if e.kind == GameConstants.Kind.CORPSE and e.decay <= 0.0:
			to_remove.append(id)
	for id in to_remove:
		entities.erase(id)

	_snapshot_accum += delta
	if _snapshot_accum >= 1.0 / GameConstants.SNAPSHOT_HZ:
		_snapshot_accum = 0.0
		if _net != null:
			_net.rpc("snapshot", build_snapshot())

func _tick_entity(e: Entity, delta: float) -> void:
	if e.kind == GameConstants.Kind.CORPSE:
		e.decay -= delta
		return

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
			e.dots.clear()
		return

	_process_dots(e, delta)
	if not e.alive:
		return

	# Movement (simple authoritative integration; collision is M2+).
	if e.kind == GameConstants.Kind.PLAYER:
		var mv := e.move_input
		if e.statuses.has("fear"):
			mv = Vector3.ZERO          # feared: loss of control
		var spd := GameConstants.PLAYER_SPEED
		if e.statuses.has("slow"):
			spd *= GameConstants.SLOW_MULT
		if mv.length() > 0.01:
			e.position += mv * spd * delta
			var b := GameConstants.ZONE_HALF_EXTENT
			e.position.x = clampf(e.position.x, -b, b)
			e.position.z = clampf(e.position.z, -b, b)

	# Resource regen.
	if e.resource < e.max_resource:
		e.resource = minf(e.max_resource, e.resource + e.resource_regen * delta)

	# PK flag countdown.
	if e.pk_flag > 0.0:
		e.pk_flag = maxf(0.0, e.pk_flag - delta)

	# Cooldowns + statuses countdown.
	for k in e.cooldowns.keys():
		e.cooldowns[k] = float(e.cooldowns[k]) - delta
		if e.cooldowns[k] <= 0.0:
			e.cooldowns.erase(k)
	for k in e.statuses.keys():
		e.statuses[k] = float(e.statuses[k]) - delta
		if e.statuses[k] <= 0.0:
			e.statuses.erase(k)

func _process_dots(e: Entity, delta: float) -> void:
	if e.dots.is_empty():
		return
	var still: Array = []
	for d in e.dots:
		d["remaining"] = float(d["remaining"]) - delta
		d["accum"] = float(d["accum"]) + delta
		while float(d["accum"]) >= float(d["interval"]) and e.alive:
			d["accum"] = float(d["accum"]) - float(d["interval"])
			var res := CombatSystem.apply_damage_value(e, float(d["dmg"]), int(d["type"]))
			if res["killed"]:
				_on_entity_killed(e)
				break
		if float(d["remaining"]) > 0.0 and e.alive:
			still.append(d)
	e.dots = still

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
			"feared": e.statuses.has("fear"),
			"slowed": e.statuses.has("slow"),
			"pk": e.pk_flag > 0.0,
			"gold": e.gold,
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
	char_data["gold"] = e.gold
