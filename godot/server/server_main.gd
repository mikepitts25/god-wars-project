class_name ServerMain
extends Node

## Authoritative server controller. Owns auth, persistence and the world, and
## handles validated client requests relayed by the Net autoload.

var _persist: PersistenceService
var _auth: AuthService
var _world: WorldState
var _sessions := {}     # peer -> { "account": Dictionary, "entered": bool }

func _ready() -> void:
	_persist = PersistenceService.new()
	_persist.init()
	_auth = AuthService.new(_persist)

	_world = WorldState.new()
	_world.name = "WorldState"
	add_child(_world)

	if Net.multiplayer.multiplayer_peer == null:
		var err := Net.start_server()
		if err != OK:
			push_error("[server] failed to bind port %d (err %d)" % [GameConstants.DEFAULT_PORT, err])
			return

	Net.s_peer_connected.connect(_on_peer_connected)
	Net.s_peer_disconnected.connect(_on_peer_disconnected)
	Net.s_login_requested.connect(_on_login)
	Net.s_char_list_requested.connect(_on_char_list)
	Net.s_create_char_requested.connect(_on_create_char)
	Net.s_enter_world_requested.connect(_on_enter_world)
	Net.s_input_received.connect(_on_input)
	Net.s_ability_requested.connect(_on_ability)
	Net.s_chat_requested.connect(_on_chat)

	print("[server] world ready on port %d (max %d players)" % [GameConstants.DEFAULT_PORT, GameConstants.MAX_CLIENTS])

# --- connection lifecycle ----------------------------------------------
func _on_peer_connected(peer: int) -> void:
	_sessions[peer] = {"account": {}, "entered": false}
	print("[server] peer %d connected" % peer)

func _on_peer_disconnected(peer: int) -> void:
	_save_peer(peer)
	_world.remove_player(peer)
	_sessions.erase(peer)
	print("[server] peer %d disconnected" % peer)

# --- account + character -----------------------------------------------
func _on_login(peer: int, username: String, password: String, is_create: bool) -> void:
	var res: Dictionary = _auth.register(username, password) if is_create else _auth.verify(username, password)
	if not res.get("ok", false):
		Net.login_result.rpc_id(peer, false, String(res.get("message", "Login failed")))
		return
	_sessions[peer] = {"account": res["account"], "entered": false}
	Net.login_result.rpc_id(peer, true, "Welcome, %s" % username)
	Net.char_list.rpc_id(peer, _char_summaries(res["account"]))

func _on_char_list(peer: int) -> void:
	var sess: Dictionary = _sessions.get(peer, {})
	Net.char_list.rpc_id(peer, _char_summaries(sess.get("account", {})))

func _on_create_char(peer: int, char_name: String, class_id: String) -> void:
	var sess: Dictionary = _sessions.get(peer, {})
	var account: Dictionary = sess.get("account", {})
	if account.is_empty():
		return
	if char_name.strip_edges().length() < 2:
		return
	var cls := GameData.get_class_def(StringName(class_id))
	if cls == null:
		return
	var cid := str(int(account.get("next_char", 1)))
	account["next_char"] = int(account.get("next_char", 1)) + 1
	var characters: Dictionary = account.get("characters", {})
	characters[cid] = {
		"id": cid,
		"name": char_name.strip_edges(),
		"class_id": class_id,
		"level": 1,
		"px": 0.0, "pz": 6.0,
		"health": cls.max_health,
		"resource": cls.max_resource,
	}
	account["characters"] = characters
	_persist.save_account(account)
	_sessions[peer]["account"] = account
	Net.char_list.rpc_id(peer, _char_summaries(account))

func _on_enter_world(peer: int, char_id: String) -> void:
	var sess: Dictionary = _sessions.get(peer, {})
	var account: Dictionary = sess.get("account", {})
	var characters: Dictionary = account.get("characters", {})
	if not characters.has(char_id):
		Net.enter_world_result.rpc_id(peer, false, "No such character", 0)
		return
	var char_data: Dictionary = characters[char_id]
	var cls := GameData.get_class_def(StringName(char_data.get("class_id", "")))
	if cls == null:
		Net.enter_world_result.rpc_id(peer, false, "Unknown class", 0)
		return
	var entity_id := _world.spawn_player(peer, char_data, cls)
	_sessions[peer]["entered"] = true
	_sessions[peer]["char_id"] = char_id
	Net.enter_world_result.rpc_id(peer, true, "Entered the world", entity_id)
	Net.chat_broadcast.rpc(GameConstants.Channel.SYSTEM, "World", "%s has entered the world." % char_data.get("name", "Someone"))

# --- gameplay -----------------------------------------------------------
func _on_input(peer: int, move_x: float, move_z: float, yaw: float) -> void:
	_world.set_input(peer, move_x, move_z, yaw)

func _on_ability(peer: int, ability_idx: int, target_id: int) -> void:
	var event := _world.request_ability(peer, ability_idx, target_id)
	if event.get("ok", false):
		Net.combat_event.rpc(event)

func _on_chat(peer: int, channel: int, text: String) -> void:
	text = text.strip_edges()
	if text.is_empty() or text.length() > 200:
		return
	var sender := _sender_name(peer)
	Net.chat_broadcast.rpc(channel, sender, text)

# --- helpers ------------------------------------------------------------
func _char_summaries(account: Dictionary) -> Array:
	var out: Array = []
	var characters: Dictionary = account.get("characters", {})
	for cid in characters:
		var ch: Dictionary = characters[cid]
		out.append({
			"id": ch.get("id", cid),
			"name": ch.get("name", "?"),
			"class_id": ch.get("class_id", ""),
			"level": ch.get("level", 1),
		})
	return out

func _sender_name(peer: int) -> String:
	var sess: Dictionary = _sessions.get(peer, {})
	var account: Dictionary = sess.get("account", {})
	return String(account.get("username", "Anon"))

func _save_peer(peer: int) -> void:
	var sess: Dictionary = _sessions.get(peer, {})
	var account: Dictionary = sess.get("account", {})
	if account.is_empty():
		return
	# Write the live entity state back into the active character record.
	var char_id := String(sess.get("char_id", ""))
	if _world.find_player_id(peer) != 0 and not char_id.is_empty():
		var characters: Dictionary = account.get("characters", {})
		if characters.has(char_id):
			var ch: Dictionary = characters[char_id]
			_world.write_back(peer, ch)
			characters[char_id] = ch
			account["characters"] = characters
	_persist.save_account(account)
