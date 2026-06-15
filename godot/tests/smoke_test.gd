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
