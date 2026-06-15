extends Node

## Entry point (attached to boot.tscn, the project's main scene).
## Detects whether this process is a dedicated server or a client and swaps in
## the appropriate root controller. Everything else is built in code, so the
## only .tscn in the project is boot.tscn.
##
##   godot --headless -- --server   -> ServerMain (authoritative world)
##   godot                          -> ClientMain (rendering + input + UI)

func _ready() -> void:
	var is_server := _detect_server()
	var root := get_tree().root
	if is_server:
		print("[boot] starting in SERVER mode")
		var sm := ServerMain.new()
		sm.name = "ServerMain"
		root.call_deferred("add_child", sm)
	else:
		print("[boot] starting in CLIENT mode")
		var cm := ClientMain.new()
		cm.name = "ClientMain"
		root.call_deferred("add_child", cm)
	queue_free()


func _detect_server() -> bool:
	# Explicit overrides win (useful for headless testing of a client).
	if OS.get_cmdline_user_args().has("--client"):
		return false
	if OS.has_feature("dedicated_server"):
		return true
	if DisplayServer.get_name() == "headless":
		return true
	if OS.get_cmdline_user_args().has("--server"):
		return true
	if OS.get_cmdline_args().has("--server"):
		return true
	return false
