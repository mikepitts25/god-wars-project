class_name ClientMain
extends Node

## Client controller: connects to the server, drives the login / character-select
## / in-game UI flow, renders entities from server snapshots, predicts local
## movement, and forwards input. All gameplay decisions remain server-side.

const COLOR_LOCAL := Color(0.30, 0.60, 1.00)
const COLOR_OTHER := Color(0.70, 0.40, 0.90)
const COLOR_NPC := Color(0.90, 0.30, 0.30)
const COLOR_CORPSE := Color(0.45, 0.38, 0.30)

var _world: Node3D
var _cam: FixedCam
var _ui: CanvasLayer

var _login_root: Control
var _charsel_root: Control
var _status_label: Label
var _name_edit: LineEdit
var _pass_edit: LineEdit
var _create_name_edit: LineEdit
var _class_picker: OptionButton
var _class_ids: Array[String] = []

var _hud: HUD
var _chat: ChatPanel

var _views := {}                # entity id -> PlayerView
var _latest := {}               # entity id -> snapshot dict
var _my_entity_id := 0
var _target_id := 0
var _in_game := false
var _pred_init := false
var _local_pred := Vector3.ZERO
var _abilities_set := false

func _ready() -> void:
	_build_world()
	_build_ui()

	Net.connected_ok.connect(_on_connected)
	Net.connection_failed.connect(func(): _set_status("Connection failed."))
	Net.server_closed.connect(func(): _set_status("Disconnected from server."))
	Net.c_login_result.connect(_on_login_result)
	Net.c_char_list.connect(_on_char_list)
	Net.c_enter_world_result.connect(_on_enter_world_result)
	Net.c_snapshot.connect(_on_snapshot)
	Net.c_combat_event.connect(_on_combat_event)
	Net.c_chat.connect(_on_chat)

	var host := _arg_value("--host", GameConstants.DEFAULT_HOST)
	var port := int(_arg_value("--port", str(GameConstants.DEFAULT_PORT)))
	_set_status("Connecting to %s:%d ..." % [host, port])
	var err := Net.start_client(host, port)
	if err != OK:
		_set_status("Could not start client (err %d)" % err)

# --- world / rendering --------------------------------------------------
func _build_world() -> void:
	_world = Node3D.new()
	_world.name = "World"
	add_child(_world)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.6)
	env.ambient_light_energy = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	_world.add_child(we)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	_world.add_child(light)

	# Ground (visual only; positions are authoritative from the server).
	var b := GameConstants.ZONE_HALF_EXTENT
	var ground := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(b * 2.0, 1.0, b * 2.0)
	ground.mesh = gm
	ground.position.y = -0.5
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.13, 0.16, 0.14)
	ground.material_override = gmat
	_world.add_child(ground)

	# A couple of landmark obstacles for spatial reference.
	for p in [Vector3(10, 0, -4), Vector3(-12, 0, 8)]:
		var ob := MeshInstance3D.new()
		var om := BoxMesh.new()
		om.size = Vector3(3, 4, 3)
		ob.mesh = om
		ob.position = p + Vector3(0, 2, 0)
		var omat := StandardMaterial3D.new()
		omat.albedo_color = Color(0.25, 0.22, 0.30)
		ob.material_override = omat
		_world.add_child(ob)

	_cam = FixedCam.new()
	_cam.current = true
	_world.add_child(_cam)

# --- UI scaffolding -----------------------------------------------------
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	_build_login()

func _build_login() -> void:
	_login_root = _centered_panel()
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(320, 0)
	(_login_root.get_child(0) as Control).add_child(v)

	var title := Label.new()
	title.text = "God Wars Reborn"
	v.add_child(title)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Username"
	v.add_child(_name_edit)

	_pass_edit = LineEdit.new()
	_pass_edit.placeholder_text = "Password"
	_pass_edit.secret = true
	v.add_child(_pass_edit)

	_status_label = Label.new()
	_status_label.text = ""
	v.add_child(_status_label)

	var row := HBoxContainer.new()
	var login_btn := Button.new()
	login_btn.text = "Login"
	login_btn.pressed.connect(func(): _do_login(false))
	var create_btn := Button.new()
	create_btn.text = "Create Account"
	create_btn.pressed.connect(func(): _do_login(true))
	row.add_child(login_btn)
	row.add_child(create_btn)
	v.add_child(row)

	_ui.add_child(_login_root)

func _build_charselect(chars: Array) -> void:
	if _charsel_root != null and is_instance_valid(_charsel_root):
		_charsel_root.queue_free()
	_charsel_root = _centered_panel()
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(360, 0)
	(_charsel_root.get_child(0) as Control).add_child(v)

	var title := Label.new()
	title.text = "Select a character"
	v.add_child(title)

	if chars.is_empty():
		var none := Label.new()
		none.text = "(no characters yet — create one below)"
		v.add_child(none)
	for ch in chars:
		var btn := Button.new()
		btn.text = "%s  (%s)  Lv %s" % [ch.get("name", "?"), ch.get("class_id", "?"), str(ch.get("level", 1))]
		var cid := String(ch.get("id", ""))
		btn.pressed.connect(func(): Net.enter_world.rpc_id(1, cid))
		v.add_child(btn)

	v.add_child(HSeparator.new())
	var create_label := Label.new()
	create_label.text = "Create new character"
	v.add_child(create_label)

	_create_name_edit = LineEdit.new()
	_create_name_edit.placeholder_text = "Character name"
	v.add_child(_create_name_edit)

	_class_picker = OptionButton.new()
	_class_ids.clear()
	for c in GameData.get_all_classes():
		_class_picker.add_item("%s — %s" % [c.display_name, c.weakness])
		_class_ids.append(String(c.id))
	v.add_child(_class_picker)

	var create_btn := Button.new()
	create_btn.text = "Create"
	create_btn.pressed.connect(_do_create_char)
	v.add_child(create_btn)

	_ui.add_child(_charsel_root)

func _build_ingame_ui() -> void:
	_hud = HUD.new()
	_ui.add_child(_hud)
	_hud.ability_pressed.connect(_use_ability)

	_chat = ChatPanel.new()
	_ui.add_child(_chat)
	_chat.message_submitted.connect(func(t: String): Net.send_chat.rpc_id(1, GameConstants.Channel.GLOBAL, t))
	_chat.add_system("Entered the world. WASD move, 1-4 abilities, Tab target, F loot, Enter chat.")

func _centered_panel() -> Control:
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	cc.add_child(panel)
	return cc

func _set_status(text: String) -> void:
	if _status_label != null and is_instance_valid(_status_label):
		_status_label.text = text
	print("[client] " + text)

# --- request helpers ----------------------------------------------------
func _do_login(is_create: bool) -> void:
	var u := _name_edit.text.strip_edges()
	var p := _pass_edit.text
	if u.is_empty() or p.is_empty():
		_set_status("Enter a username and password.")
		return
	Net.login.rpc_id(1, u, p, is_create)

func _do_create_char() -> void:
	var n := _create_name_edit.text.strip_edges()
	if n.length() < 2:
		return
	var idx := _class_picker.selected
	if idx < 0 or idx >= _class_ids.size():
		idx = 0
	Net.create_character.rpc_id(1, n, _class_ids[idx])

func _use_ability(index: int) -> void:
	if _in_game:
		Net.use_ability.rpc_id(1, index, _target_id)

# --- server callbacks ---------------------------------------------------
func _on_connected() -> void:
	_set_status("Connected. Log in or create an account.")

func _on_login_result(ok: bool, message: String) -> void:
	_set_status(message)
	if ok and _login_root != null and is_instance_valid(_login_root):
		_login_root.queue_free()

func _on_char_list(characters: Array) -> void:
	_build_charselect(characters)

func _on_enter_world_result(ok: bool, message: String, my_entity_id: int) -> void:
	if not ok:
		_set_status(message)
		return
	_my_entity_id = my_entity_id
	_in_game = true
	_pred_init = false
	_abilities_set = false
	if _charsel_root != null and is_instance_valid(_charsel_root):
		_charsel_root.queue_free()
	_build_ingame_ui()

func _on_snapshot(entities: Array) -> void:
	var seen := {}
	for e in entities:
		var id := int(e["id"])
		seen[id] = true
		_latest[id] = e
		var view: PlayerView = _ensure_view(id, e)
		var server_pos := Vector3(float(e["px"]), 0.0, float(e["pz"]))
		view.target_pos = server_pos
		view.set_stealth(bool(e.get("stealth", false)))
		# Corpses stay visible (alive == false); dead/respawning players are hidden.
		var is_corpse := int(e.get("kind", GameConstants.Kind.PLAYER)) == GameConstants.Kind.CORPSE
		view.set_dead(not bool(e.get("alive", true)) and not is_corpse)

		if id == _my_entity_id:
			if not _pred_init:
				_local_pred = server_pos
				_pred_init = true
			else:
				_local_pred = _local_pred.lerp(server_pos, 0.2)
			_update_self_hud(e)

	# Remove stale views.
	for id in _views.keys():
		if not seen.has(id):
			_views[id].queue_free()
			_views.erase(id)
			_latest.erase(id)

func _on_combat_event(event: Dictionary) -> void:
	if _chat == null:
		return
	match String(event.get("type", "cast")):
		"loot":
			if int(event.get("looter", 0)) == _my_entity_id:
				_chat.add_system("You loot %d gold." % int(event.get("gold", 0)))
		"death":
			_chat.add_system("%s has fallen." % event.get("victim_name", "Someone"))
		_:
			var line := "%s uses %s" % [event.get("caster_name", "?"), event.get("ability_name", "?")]
			if event.has("damage") and event.has("target_name"):
				line += " — %s takes %d damage" % [event["target_name"], int(event["damage"])]
			if event.has("dot") and event.has("target_name"):
				line += " on %s" % event["target_name"]
			if event.has("killed"):
				line += " (slain!)"
			_chat.add_system(line)

func _on_chat(channel: int, sender: String, text: String) -> void:
	if _chat == null:
		return
	if channel == GameConstants.Channel.SYSTEM:
		_chat.add_system(text)
	else:
		_chat.add_chat(sender, text)

# --- view management ----------------------------------------------------
func _ensure_view(id: int, e: Dictionary) -> PlayerView:
	if _views.has(id):
		return _views[id]
	var view := PlayerView.new()
	view.entity_id = id
	var is_local := id == _my_entity_id
	var kind := int(e.get("kind", GameConstants.Kind.PLAYER))
	var color := COLOR_LOCAL
	if kind == GameConstants.Kind.NPC:
		color = COLOR_NPC
	elif kind == GameConstants.Kind.CORPSE:
		color = COLOR_CORPSE
	elif not is_local:
		color = COLOR_OTHER
	view.is_local = is_local
	view.setup(color, String(e.get("name", "?")))
	_world.add_child(view)
	_views[id] = view
	if is_local and not _abilities_set:
		_apply_ability_labels(String(e.get("class_id", "")))
	return view

func _apply_ability_labels(class_id: String) -> void:
	var cls := GameData.get_class_def(StringName(class_id))
	if cls == null:
		return
	var names := PackedStringArray()
	for a in cls.abilities:
		names.append(a.display_name)
	_hud.set_abilities(names)
	_abilities_set = true

func _update_self_hud(e: Dictionary) -> void:
	if _hud == null:
		return
	var res_name := "Resource"
	var cls := GameData.get_class_def(StringName(e.get("class_id", "")))
	if cls != null:
		res_name = cls.resource_label
	_hud.set_self_stats(float(e["hp"]), float(e["max_hp"]), float(e["res"]), float(e["max_res"]), res_name)
	_hud.set_gold(int(e.get("gold", 0)))

# --- frame loops --------------------------------------------------------
func _process(delta: float) -> void:
	for id in _views:
		var view: PlayerView = _views[id]
		if id == _my_entity_id:
			view.position = _local_pred
		else:
			view.position = view.position.lerp(view.target_pos, clampf(12.0 * delta, 0.0, 1.0))
	if _my_entity_id != 0 and _views.has(_my_entity_id):
		_cam.target = _views[_my_entity_id]
	_refresh_target_frame()

func _physics_process(delta: float) -> void:
	if not _in_game or not _views.has(_my_entity_id):
		return
	var dir := Vector3.ZERO
	if not _typing():
		if Input.is_physical_key_pressed(KEY_W): dir.z -= 1.0
		if Input.is_physical_key_pressed(KEY_S): dir.z += 1.0
		if Input.is_physical_key_pressed(KEY_A): dir.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D): dir.x += 1.0
	if dir.length() > 1.0:
		dir = dir.normalized()

	var yaw := 0.0
	if dir.length() > 0.01:
		yaw = atan2(dir.x, dir.z)
		_local_pred += dir * GameConstants.PLAYER_SPEED * delta
		var b := GameConstants.ZONE_HALF_EXTENT
		_local_pred.x = clampf(_local_pred.x, -b, b)
		_local_pred.z = clampf(_local_pred.z, -b, b)

	Net.send_input.rpc_id(1, dir.x, dir.z, yaw)

func _input(event: InputEvent) -> void:
	if not _in_game or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).physical_keycode
	if _typing():
		return
	match key:
		KEY_1: _use_ability(0)
		KEY_2: _use_ability(1)
		KEY_3: _use_ability(2)
		KEY_4: _use_ability(3)
		KEY_F: _try_loot()
		KEY_TAB: _cycle_target()
		KEY_ENTER, KEY_KP_ENTER:
			if _chat != null:
				_chat.focus_input()

func _typing() -> bool:
	return _chat != null and _chat.is_typing()

# --- targeting ----------------------------------------------------------
func _cycle_target() -> void:
	var ids: Array = []
	for id in _latest:
		if id != _my_entity_id and bool(_latest[id].get("alive", true)):
			ids.append(id)
	ids.sort()
	if ids.is_empty():
		_target_id = 0
		return
	var pos := ids.find(_target_id)
	_target_id = ids[(pos + 1) % ids.size()] if pos != -1 else ids[0]

func _try_loot() -> void:
	var best := 0
	var best_d := GameConstants.LOOT_RANGE + 0.01
	for id in _latest:
		var e: Dictionary = _latest[id]
		if int(e.get("kind", GameConstants.Kind.PLAYER)) != GameConstants.Kind.CORPSE:
			continue
		var d := _local_pred.distance_to(Vector3(float(e["px"]), 0.0, float(e["pz"])))
		if d <= best_d:
			best = id
			best_d = d
	if best != 0:
		Net.request_loot.rpc_id(1, best)
	elif _chat != null:
		_chat.add_system("No corpse in reach to loot.")

func _refresh_target_frame() -> void:
	if _hud == null:
		return
	if _target_id != 0 and _latest.has(_target_id):
		var e: Dictionary = _latest[_target_id]
		_hud.set_target(String(e.get("name", "?")), float(e["hp"]), float(e["max_hp"]))
	else:
		_hud.clear_target()

# --- misc ---------------------------------------------------------------
func _arg_value(flag: String, fallback: String) -> String:
	var args := OS.get_cmdline_user_args()
	var i := args.find(flag)
	if i != -1 and i + 1 < args.size():
		return args[i + 1]
	return fallback
