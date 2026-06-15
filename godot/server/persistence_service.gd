class_name PersistenceService
extends RefCounted

## The single boundary between game logic and storage
## (docs/design/06-networking-persistence.md §5).
##
## Scaffold impl: one JSON file per account under user://data/accounts/.
## Production: drop in a SqlitePersistence / PostgresPersistence with the same
## method surface — no caller changes required.

const ACCT_DIR := "user://data/accounts"

func init() -> void:
	DirAccess.make_dir_recursive_absolute(ACCT_DIR)

func _acct_path(username: String) -> String:
	return ACCT_DIR.path_join(username.to_lower() + ".json")

func has_account(username: String) -> bool:
	return FileAccess.file_exists(_acct_path(username))

func load_account(username: String) -> Dictionary:
	var p := _acct_path(username)
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(txt)
	return data if typeof(data) == TYPE_DICTIONARY else {}

func save_account(account: Dictionary) -> void:
	var username := String(account.get("username", ""))
	if username.is_empty():
		return
	var f := FileAccess.open(_acct_path(username), FileAccess.WRITE)
	if f == null:
		push_error("PersistenceService: could not open account file for write")
		return
	f.store_string(JSON.stringify(account, "  "))
	f.close()
