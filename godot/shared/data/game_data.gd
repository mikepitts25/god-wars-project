class_name GameData
extends RefCounted

## Central registry of class/ability content.
##
## The scaffold constructs definitions in code for robustness (no fragile
## hand-authored .tres). The ClassDef/AbilityDef Resource types exist so the
## production path can author content as .tres without changing any callers.
## Add new classes here (or as .tres) — combat_system.gd needs no changes.

static func get_all_classes() -> Array[ClassDef]:
	var arr: Array[ClassDef] = [sanguine(), moonbound(), shadowblade()]
	return arr

static func get_class_def(id: StringName) -> ClassDef:
	for c in get_all_classes():
		if c.id == id:
			return c
	return null

# --- Sanguine (vampire-inspired) -----------------------------------------
static func sanguine() -> ClassDef:
	var c := ClassDef.new()
	c.id = &"sanguine"
	c.display_name = "Sanguine"
	c.blurb = "An undying bloodborn predator — fast, brutal and deceptive, sustained by feeding. Weak to sunlight."
	c.max_health = 120.0
	c.resource_label = "Vitae"
	c.max_resource = 100.0
	c.resource_regen = 1.0
	c.soak = 4.0
	c.weakness = "Sunlight"
	c.abilities = [
		_ability(&"swiftness", "Swiftness", 20.0, 8.0, 0.0, GameConstants.Effect.BUFF_HASTE, 0.0, 6.0),
		_ability(&"claw", "Claw Strike", 10.0, 1.5, 3.0, GameConstants.Effect.DAMAGE, 18.0),
		_ability(&"crimson_feed", "Crimson Feed", 0.0, 4.0, 3.0, GameConstants.Effect.DRAIN, 16.0),
		_ability(&"veil", "Veil", 25.0, 12.0, 0.0, GameConstants.Effect.STEALTH, 0.0, 8.0),
	]
	return c

# --- Moonbound (werewolf-inspired) ---------------------------------------
static func moonbound() -> ClassDef:
	var c := ClassDef.new()
	c.id = &"moonbound"
	c.display_name = "Moonbound"
	c.blurb = "A feral shapeshifter: explosive melee, regeneration and terror. Weak to silver."
	c.max_health = 150.0
	c.resource_label = "Rage"
	c.max_resource = 100.0
	c.resource_regen = 3.0
	c.soak = 7.0
	c.weakness = "Silver"
	c.weakness_damage_type = GameConstants.DamageType.SILVER
	c.weakness_mult = 1.6
	c.abilities = [
		_ability(&"rend", "Rend", 15.0, 6.0, 3.0, GameConstants.Effect.DOT, 8.0, 6.0, 1.5),
		_ability(&"regenerate", "Regenerate", 30.0, 10.0, 0.0, GameConstants.Effect.HEAL, 50.0),
		_ability(&"howl", "Howl", 25.0, 14.0, 8.0, GameConstants.Effect.FEAR, 0.0, 3.0),
		_ability(&"pounce", "Pounce", 20.0, 8.0, 20.0, GameConstants.Effect.TELEPORT, 14.0),
	]
	return c

# --- Shadowblade (assassin-inspired) -------------------------------------
static func shadowblade() -> ClassDef:
	var c := ClassDef.new()
	c.id = &"shadowblade"
	c.display_name = "Shadowblade"
	c.blurb = "A stealth striker: poison, mobility and lethal openers. Fragile in a stand-up fight."
	c.max_health = 90.0
	c.resource_label = "Focus"
	c.max_resource = 100.0
	c.resource_regen = 5.0
	c.soak = 2.0
	c.weakness = "Fragility"
	c.abilities = [
		_ability(&"shadowstep", "Shadowstep", 20.0, 6.0, 25.0, GameConstants.Effect.TELEPORT, 16.0),
		_ability(&"venom", "Venom", 15.0, 5.0, 3.0, GameConstants.Effect.DOT, 6.0, 8.0, 1.0, GameConstants.DamageType.POISON),
		_ability(&"cloak", "Cloak", 25.0, 12.0, 0.0, GameConstants.Effect.STEALTH, 0.0, 8.0),
		_ability(&"garrote", "Garrote", 20.0, 7.0, 2.5, GameConstants.Effect.DAMAGE, 30.0),
	]
	return c

static func _ability(id: StringName, dname: String, cost: float, cd: float, rng: float, effect: int, power: float, dur: float = 0.0, tick: float = 1.0, damage_type: int = GameConstants.DamageType.PHYSICAL) -> AbilityDef:
	var a := AbilityDef.new()
	a.id = id
	a.display_name = dname
	a.cost = cost
	a.cooldown = cd
	a.cast_range = rng
	a.effect = effect
	a.power = power
	a.duration = dur
	a.tick = tick
	a.damage_type = damage_type
	return a
