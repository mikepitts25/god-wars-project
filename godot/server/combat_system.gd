class_name CombatSystem
extends RefCounted

## Pure, server-authoritative ability resolution. Operates on WorldState.Entity
## objects (passed untyped to avoid cross-script inner-class type coupling).
## Every gameplay-affecting decision (cost, cooldown, range, damage, death) is
## made here on the server — never trusted to the client (docs/design/03-combat.md).

# Returns an event Dictionary describing the outcome (for broadcast to clients),
# or {"ok": false, "reason": ...} if the ability was rejected.
static func resolve_ability(caster, ability: AbilityDef, target) -> Dictionary:
	if caster == null or not caster.alive:
		return {"ok": false, "reason": "caster_invalid"}
	if float(caster.cooldowns.get(ability.id, 0.0)) > 0.0:
		return {"ok": false, "reason": "cooldown"}
	if caster.resource < ability.cost:
		return {"ok": false, "reason": "resource"}

	var needs_target := ability.effect == GameConstants.Effect.DAMAGE or ability.effect == GameConstants.Effect.DRAIN
	if needs_target:
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
			_apply_damage(caster, target, ability.power, event)
		GameConstants.Effect.DRAIN:
			var dmg: float = minf(ability.power, target.health)
			_apply_damage(caster, target, ability.power, event)
			caster.resource = minf(caster.max_resource, caster.resource + dmg)
			event["drained"] = dmg
			# Attacking breaks stealth.
			caster.statuses.erase("stealth")
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


static func _apply_damage(caster, target, amount: float, event: Dictionary) -> void:
	# Damage breaks the attacker's stealth.
	caster.statuses.erase("stealth")
	target.health -= amount
	event["target"] = target.id
	event["target_name"] = target.display_name
	event["damage"] = amount
	if target.health <= 0.0:
		target.health = 0.0
		target.alive = false
		target.respawn_in = GameConstants.RESPAWN_TIME
		target.statuses.clear()
		event["killed"] = target.id
		event["killer"] = caster.id
