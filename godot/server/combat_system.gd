class_name CombatSystem
extends RefCounted

## Pure, server-authoritative ability resolution. Operates on WorldState.Entity
## objects (passed untyped to avoid cross-script inner-class type coupling).
## Every gameplay-affecting decision (cost, cooldown, range, mitigation, death)
## is made here on the server — never trusted to the client.

# Effects that require a valid living target.
const TARGETED := [
	GameConstants.Effect.DAMAGE, GameConstants.Effect.DRAIN, GameConstants.Effect.DOT,
	GameConstants.Effect.TELEPORT, GameConstants.Effect.FEAR, GameConstants.Effect.SLOW,
]

# Returns an event Dictionary describing the outcome (for broadcast), or
# {"ok": false, "reason": ...} if rejected. Mutates caster/target state.
static func resolve_ability(caster, ability: AbilityDef, target) -> Dictionary:
	if caster == null or not caster.alive:
		return {"ok": false, "reason": "caster_invalid"}
	if float(caster.cooldowns.get(ability.id, 0.0)) > 0.0:
		return {"ok": false, "reason": "cooldown"}
	if caster.resource < ability.cost:
		return {"ok": false, "reason": "resource"}

	if TARGETED.has(ability.effect):
		if target == null or not target.alive:
			return {"ok": false, "reason": "no_target"}
		if caster.position.distance_to(target.position) > ability.cast_range + 1.5:
			return {"ok": false, "reason": "out_of_range"}

	# Commit cost + cooldown.
	caster.resource = maxf(0.0, caster.resource - ability.cost)
	caster.cooldowns[ability.id] = ability.cooldown

	var event := {
		"ok": true,
		"type": "cast",
		"caster": caster.id,
		"caster_name": caster.display_name,
		"ability": String(ability.id),
		"ability_name": ability.display_name,
	}

	match ability.effect:
		GameConstants.Effect.DAMAGE:
			_strike(caster, target, ability.power, ability.damage_type, event)
		GameConstants.Effect.DRAIN:
			var res := apply_damage_value(target, ability.power, ability.damage_type)
			caster.resource = minf(caster.max_resource, caster.resource + res["final"])
			_record_hit(caster, target, res, event)
			event["drained"] = res["final"]
			caster.statuses.erase("stealth")
		GameConstants.Effect.TELEPORT:
			# Gap-close to the target, then strike.
			var dir: Vector3 = caster.position - target.position
			dir.y = 0.0
			dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
			caster.position = target.position + dir * 1.5
			event["teleport"] = true
			_strike(caster, target, ability.power, ability.damage_type, event)
		GameConstants.Effect.DOT:
			target.dots.append({
				"remaining": ability.duration,
				"interval": ability.tick,
				"accum": 0.0,
				"dmg": ability.power,
				"type": ability.damage_type,
				"source": caster.id,
			})
			event["dot"] = String(ability.id)
			event["target"] = target.id
			event["target_name"] = target.display_name
			caster.statuses.erase("stealth")
		GameConstants.Effect.FEAR:
			target.statuses["fear"] = ability.duration
			event["status"] = "fear"
			event["target"] = target.id
			event["target_name"] = target.display_name
		GameConstants.Effect.SLOW:
			target.statuses["slow"] = ability.duration
			event["status"] = "slow"
			event["target"] = target.id
			event["target_name"] = target.display_name
		GameConstants.Effect.BUFF_HASTE:
			caster.statuses["haste"] = ability.duration
			event["buff"] = "haste"
		GameConstants.Effect.STEALTH:
			caster.statuses["stealth"] = ability.duration
			event["buff"] = "stealth"
		GameConstants.Effect.HEAL:
			caster.health = minf(caster.max_health, caster.health + ability.power)
			event["healed"] = ability.power

	return event


# Applies mitigated damage to a target and handles death. Returns
# {"final": float, "killed": bool}. Shared by direct hits and DOT ticks.
static func apply_damage_value(target, amount: float, damage_type: int) -> Dictionary:
	var post_soak: float = maxf(0.0, amount - target.soak)
	var mult := 1.0
	if damage_type >= 0 and target.weakness_damage_type == damage_type:
		mult = target.weakness_mult
	var final: float = post_soak * mult
	target.health -= final
	var killed := false
	if target.health <= 0.0:
		target.health = 0.0
		target.alive = false
		target.respawn_in = GameConstants.RESPAWN_TIME
		target.statuses.clear()
		target.dots.clear()
		killed = true
	return {"final": final, "killed": killed}


static func _strike(caster, target, amount: float, damage_type: int, event: Dictionary) -> void:
	caster.statuses.erase("stealth")  # attacking breaks stealth
	var res := apply_damage_value(target, amount, damage_type)
	_record_hit(caster, target, res, event)


static func _record_hit(caster, target, res: Dictionary, event: Dictionary) -> void:
	event["target"] = target.id
	event["target_name"] = target.display_name
	event["damage"] = res["final"]
	if res["killed"]:
		event["killed"] = target.id
		event["killer"] = caster.id
