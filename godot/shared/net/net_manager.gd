extends Node

## Autoload "Net": the shared RPC surface. Because RPCs route by node path,
## both client and server must expose the same node at the same path (/root/Net).
## All @rpc methods live here; they simply re-emit as local signals that the
## server controller (ServerMain) and client controller (ClientMain) connect to.
##
##   client -> server : @rpc("any_peer")  (validated server-side via sender id)
##   server -> client : @rpc("authority") (only peer id 1 may send)

# Connection lifecycle (client side)
signal connected_ok()
signal connection_failed()
signal server_closed()

# Server-side request signals (peer = remote sender)
signal s_peer_connected(peer: int)
signal s_peer_disconnected(peer: int)
signal s_login_requested(peer: int, username: String, password: String, is_create: bool)
signal s_char_list_requested(peer: int)
signal s_create_char_requested(peer: int, char_name: String, class_id: String)
signal s_enter_world_requested(peer: int, char_id: String)
signal s_input_received(peer: int, move_x: float, move_z: float, yaw: float)
signal s_ability_requested(peer: int, ability_idx: int, target_id: int)
signal s_chat_requested(peer: int, channel: int, text: String)

# Client-side response signals
signal c_login_result(ok: bool, message: String)
signal c_char_list(characters: Array)
signal c_enter_world_result(ok: bool, message: String, my_entity_id: int)
signal c_snapshot(entities: Array)
signal c_combat_event(event: Dictionary)
signal c_chat(channel: int, sender: String, text: String)

var is_server := false


func start_server(port: int = GameConstants.DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, GameConstants.MAX_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	is_server = true
	multiplayer.peer_connected.connect(func(id: int): s_peer_connected.emit(id))
	multiplayer.peer_disconnected.connect(func(id: int): s_peer_disconnected.emit(id))
	return OK


func start_client(host: String = GameConstants.DEFAULT_HOST, port: int = GameConstants.DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(host, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	is_server = false
	multiplayer.connected_to_server.connect(func(): connected_ok.emit())
	multiplayer.connection_failed.connect(func(): connection_failed.emit())
	multiplayer.server_disconnected.connect(func(): server_closed.emit())
	return OK


# --- client -> server ---------------------------------------------------
@rpc("any_peer", "call_remote", "reliable")
func login(username: String, password: String, is_create: bool) -> void:
	s_login_requested.emit(multiplayer.get_remote_sender_id(), username, password, is_create)

@rpc("any_peer", "call_remote", "reliable")
func request_char_list() -> void:
	s_char_list_requested.emit(multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func create_character(char_name: String, class_id: String) -> void:
	s_create_char_requested.emit(multiplayer.get_remote_sender_id(), char_name, class_id)

@rpc("any_peer", "call_remote", "reliable")
func enter_world(char_id: String) -> void:
	s_enter_world_requested.emit(multiplayer.get_remote_sender_id(), char_id)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func send_input(move_x: float, move_z: float, yaw: float) -> void:
	s_input_received.emit(multiplayer.get_remote_sender_id(), move_x, move_z, yaw)

@rpc("any_peer", "call_remote", "reliable")
func use_ability(ability_idx: int, target_id: int) -> void:
	s_ability_requested.emit(multiplayer.get_remote_sender_id(), ability_idx, target_id)

@rpc("any_peer", "call_remote", "reliable")
func send_chat(channel: int, text: String) -> void:
	s_chat_requested.emit(multiplayer.get_remote_sender_id(), channel, text)


# --- server -> client ---------------------------------------------------
@rpc("authority", "call_remote", "reliable")
func login_result(ok: bool, message: String) -> void:
	c_login_result.emit(ok, message)

@rpc("authority", "call_remote", "reliable")
func char_list(characters: Array) -> void:
	c_char_list.emit(characters)

@rpc("authority", "call_remote", "reliable")
func enter_world_result(ok: bool, message: String, my_entity_id: int) -> void:
	c_enter_world_result.emit(ok, message, my_entity_id)

@rpc("authority", "call_remote", "unreliable_ordered")
func snapshot(entities: Array) -> void:
	c_snapshot.emit(entities)

@rpc("authority", "call_remote", "reliable")
func combat_event(event: Dictionary) -> void:
	c_combat_event.emit(event)

@rpc("authority", "call_remote", "reliable")
func chat_broadcast(channel: int, sender: String, text: String) -> void:
	c_chat.emit(channel, sender, text)
