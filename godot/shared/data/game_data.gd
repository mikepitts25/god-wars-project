class_name GameData
extends RefCounted

## Central registry of class/ability content.
##
## The scaffold constructs definitions in code for robustness (no fragile
## hand-authored .tres). The ClassDef/AbilityDef Resource types exist so the
## production path can author content as .tres without changing any callers.
## Add new classes here (or as .tres) — combat_system.gd needs no changes.

static func get_all_classes() -> Array[ClassDef]:
	var arr: Array[ClassDef] = [sanguine()]
	return arr

static func get_class_def(id: StringName) -> ClassDef:
	for c in get_all_classes():
		if c.id == id:
			return c
	return null

# --- Sanguine (vampire-inspired) — the scaffold's playable class ---------
static func sanguine() -> ClassDef:
	var c := ClassDef.new()
	c.id = &"sanguine"
	c.display_name = "Sanguine"
	c.blurb = "An undying bloodborn predator — fast, brutal and deceptive, sustained by feeding. Weak to sunlight."
	c.max_health = 120.0
	c.resource_label = "Vitae"
	c.max_resource = 100.0
	c.resource_regen = 1.0
	c.weakness = "Sunlight"
	c.abilities = [
		_ability(&"swiftness", "Swiftness", 20.0, 8.0, 0.0, GameConstants.Effect.BUFF_HASTE, 0.0, 6.0),
		_ability(&"claw", "Claw Strike", 10.0, 1.5, 3.0, GameConstants.Effect.DAMAGE, 18.0, 0.0),
		_ability(&"crimson_feed", "Crimson Feed", 0.0, 4.0, 3.0, GameConstants.Effect.DRAIN, 16.0, 0.0),
		_ability(&"veil", "Veil", 25.0, 12.0, 0.0, GameConstants.Effect.STEALTH, 0.0, 8.0),
	]
	return c

static func _ability(id: StringName, dname: String, cost: float, cd: float, rng: float, effect: int, power: float, dur: float) -> AbilityDef:
	var a := AbilityDef.new()
	a.id = id
	a.display_name = dname
	a.cost = cost
	a.cooldown = cd
	a.cast_range = rng
	a.effect = effect
	a.power = power
	a.duration = dur
	return a
