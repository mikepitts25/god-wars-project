extends SceneTree

## Headless smoke test for the authoritative gameplay logic (auth + combat),
## runnable without a display:
##
##   godot --headless --path godot --script res://tests/smoke_test.gd
##
## Validates the pieces that can be exercised off the network: account
## registration/verification and server-side ability resolution.

var _pass := 0
var _fail := 0

func _initialize() -> void:
	_test_auth()
	_test_combat()
	_test_classes()
	_test_effects_and_weakness()
	_test_pk_and_loot()
	print("\n[smoke] %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _check(label: String, cond: bool) -> void:
	if cond:
		_pass += 1
		print("  PASS  " + label)
	else:
		_fail += 1
		print("  FAIL  " + label)

func _test_auth() -> void:
	print("[smoke] auth")
	var persist := PersistenceService.new()
	persist.init()
	var auth := AuthService.new(persist)
	var uname := "smoke%d" % (Time.get_ticks_usec() % 100000)

	var reg: Dictionary = auth.register(uname, "secret")
	_check("register succeeds", reg.get("ok", false))
	_check("duplicate register rejected", not auth.register(uname, "secret").get("ok", true))
	_check("wrong password rejected", not auth.verify(uname, "nope").get("ok", true))
	_check("correct password accepted", auth.verify(uname, "secret").get("ok", false))
	_check("short username rejected", not auth.register("ab", "secret").get("ok", true))

func _test_combat() -> void:
	print("[smoke] combat")
	var cls := GameData.sanguine()
	var claw: AbilityDef = cls.abilities[1]
	var feed: AbilityDef = cls.abilities[2]

	var caster := WorldState.Entity.new()
	caster.class_def = cls
	caster.max_resource = cls.max_resource
	caster.resource = cls.max_resource
	caster.position = Vector3.ZERO

	var dummy := WorldState.Entity.new()
	dummy.kind = GameConstants.Kind.NPC
	dummy.max_health = 80.0
	dummy.health = 80.0
	dummy.position = Vector3(0, 0, 2)

	var ev1 := CombatSystem.resolve_ability(caster, claw, dummy)
	_check("claw resolves", ev1.get("ok", false))
	_check("claw deals damage", is_equal_approx(dummy.health, 62.0))
	_check("claw spends resource", is_equal_approx(caster.resource, 90.0))
	_check("claw on cooldown", not CombatSystem.resolve_ability(caster, claw, dummy).get("ok", true))

	var ev_feed := CombatSystem.resolve_ability(caster, feed, dummy)
	_check("feed resolves", ev_feed.get("ok", false))
	_check("feed drains health", is_equal_approx(dummy.health, 46.0))
	_check("feed restores vitae (capped)", is_equal_approx(caster.resource, 100.0))

	# Out-of-range rejection.
	caster.cooldowns.clear()
	dummy.position = Vector3(0, 0, 50)
	_check("out of range rejected", not CombatSystem.resolve_ability(caster, claw, dummy).get("ok", true))

	# Lethal hit -> death + respawn timer.
	caster.cooldowns.clear()
	dummy.position = Vector3(0, 0, 2)
	dummy.health = 10.0
	var ev_kill := CombatSystem.resolve_ability(caster, claw, dummy)
	_check("lethal hit reports kill", ev_kill.has("killed"))
	_check("target marked dead", not dummy.alive)
	_check("respawn timer armed", dummy.respawn_in > 0.0)

func _test_classes() -> void:
	print("[smoke] classes")
	_check("three classes registered", GameData.get_all_classes().size() == 3)
	var mb := GameData.moonbound()
	_check("moonbound weak to silver", mb.weakness_damage_type == GameConstants.DamageType.SILVER)
	_check("moonbound uses Rage", mb.resource_label == "Rage")
	_check("moonbound has 4 abilities", mb.abilities.size() == 4)
	var sb := GameData.shadowblade()
	_check("shadowblade is fragile", sb.max_health <= 100.0)
	_check("shadowblade uses Focus", sb.resource_label == "Focus")

func _test_effects_and_weakness() -> void:
	print("[smoke] effects + weakness")
	var world := WorldState.new()
	var mb := GameData.moonbound()

	# DOT: Rend applies a bleed rather than instant damage.
	var caster := WorldState.Entity.new()
	caster.class_def = mb
	caster.max_resource = mb.max_resource
	caster.resource = mb.max_resource
	var dummy := WorldState.Entity.new()
	dummy.kind = GameConstants.Kind.NPC
	dummy.max_health = 80.0
	dummy.health = 80.0
	dummy.position = Vector3(0, 0, 2)
	var ev := CombatSystem.resolve_ability(caster, mb.abilities[0], dummy)
	_check("rend applies a dot", dummy.dots.size() == 1 and ev.get("ok", false))
	_check("rend deals no instant damage", is_equal_approx(dummy.health, 80.0))
	world._process_dots(dummy, 1.6)   # one tick (interval 1.5, 8 dmg)
	_check("dot ticks for damage", is_equal_approx(dummy.health, 72.0))

	# Weakness multiplier: silver vs a silver-weak target.
	var silver := AbilityDef.new()
	silver.id = &"silver_test"
	silver.effect = GameConstants.Effect.DAMAGE
	silver.power = 20.0
	silver.cast_range = 3.0
	silver.cooldown = 1.0
	silver.damage_type = GameConstants.DamageType.SILVER
	var wolf := WorldState.Entity.new()
	wolf.soak = mb.soak               # 7
	wolf.weakness_damage_type = GameConstants.DamageType.SILVER
	wolf.weakness_mult = mb.weakness_mult  # 1.6
	wolf.max_health = 200.0
	wolf.health = 200.0
	wolf.position = Vector3(0, 0, 2)
	var caster2 := WorldState.Entity.new()
	caster2.resource = 100.0
	caster2.max_resource = 100.0
	CombatSystem.resolve_ability(caster2, silver, wolf)
	# (20 - 7 soak) * 1.6 = 20.8
	_check("silver weakness amplifies damage", is_equal_approx(wolf.health, 179.2))

	# Teleport: gap-close then strike.
	var caster3 := WorldState.Entity.new()
	caster3.class_def = mb
	caster3.resource = 100.0
	caster3.max_resource = 100.0
	caster3.position = Vector3.ZERO
	var prey := WorldState.Entity.new()
	prey.max_health = 100.0
	prey.health = 100.0
	prey.position = Vector3(0, 0, 10)
	CombatSystem.resolve_ability(caster3, mb.abilities[3], prey)  # Pounce
	_check("teleport closes distance", caster3.position.distance_to(prey.position) < 3.0)
	_check("teleport strikes", prey.health < 100.0)
	world.free()

func _test_pk_and_loot() -> void:
	print("[smoke] pk + loot")
	var world := WorldState.new()
	var sang := GameData.sanguine()

	var atk := WorldState.Entity.new()
	atk.id = 2001
	atk.kind = GameConstants.Kind.PLAYER
	atk.owner_peer = 10
	atk.class_def = sang
	atk.resource = 100.0
	atk.max_resource = 100.0
	world.entities[2001] = atk

	var vic := WorldState.Entity.new()
	vic.id = 2002
	vic.kind = GameConstants.Kind.PLAYER
	vic.owner_peer = 20
	vic.max_health = 120.0
	vic.health = 10.0
	vic.gold = 40
	world.entities[2002] = vic

	# Inside the sanctuary, PK is refused.
	atk.position = GameConstants.SANCTUARY_CENTER
	vic.position = GameConstants.SANCTUARY_CENTER + Vector3(0, 0, 1)
	_check("sanctuary blocks PK", not world.request_ability(10, 1, 2002).get("ok", true))

	# Outside it, the kill lands and drops a lootable corpse.
	atk.position = Vector3(0, 0, 30)
	vic.position = Vector3(0, 0, 31)
	vic.health = 10.0
	var ev_kill := world.request_ability(10, 1, 2002)
	_check("PK hit lands outside sanctuary", ev_kill.get("ok", false))
	_check("attacker is PK-flagged", atk.pk_flag > 0.0)
	_check("victim is slain", not vic.alive)

	var corpse_id := 0
	for cid in world.entities:
		if world.entities[cid].kind == GameConstants.Kind.CORPSE:
			corpse_id = cid
	_check("corpse spawned on death", corpse_id != 0)

	var looter := WorldState.Entity.new()
	looter.id = 2003
	looter.kind = GameConstants.Kind.PLAYER
	looter.owner_peer = 30
	looter.gold = 0
	looter.position = world.entities[corpse_id].position
	world.entities[2003] = looter
	var ev_loot := world.request_loot(30, corpse_id)
	_check("loot succeeds", ev_loot.get("ok", false))
	_check("gold transferred (partial loot)", looter.gold == 20)
	_check("corpse consumed by loot", not world.entities.has(corpse_id))
	world.free()
