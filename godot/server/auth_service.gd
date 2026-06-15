class_name AuthService
extends RefCounted

## Username/password auth for the scaffold. Passwords are salted + SHA-256
## hashed; plaintext is never stored or logged. Production swaps this for an
## external account/token backend (docs/design/06-networking-persistence.md §2).

var _persist: PersistenceService

func _init(persist: PersistenceService) -> void:
	_persist = persist

func _valid_username(u: String) -> bool:
	if u.length() < 3 or u.length() > 16:
		return false
	for c in u:
		if not (c.is_valid_int() or (c.to_lower() != c.to_upper())):
			return false  # allow digits and letters only
	return true

func _hash(password: String, salt: String) -> String:
	return (salt + password).sha256_text()

func register(username: String, password: String) -> Dictionary:
	if not _valid_username(username):
		return {"ok": false, "message": "Username must be 3-16 letters/digits"}
	if password.length() < 3:
		return {"ok": false, "message": "Password too short"}
	if _persist.has_account(username):
		return {"ok": false, "message": "Account already exists"}
	var crypto := Crypto.new()
	var salt := crypto.generate_random_bytes(16).hex_encode()
	var account := {
		"username": username,
		"salt": salt,
		"password_hash": _hash(password, salt),
		"characters": {},
		"next_char": 1,
	}
	_persist.save_account(account)
	return {"ok": true, "message": "Account created", "account": account}

func verify(username: String, password: String) -> Dictionary:
	if not _persist.has_account(username):
		return {"ok": false, "message": "Invalid credentials"}
	var account := _persist.load_account(username)
	if _hash(password, String(account.get("salt", ""))) != String(account.get("password_hash", "")):
		return {"ok": false, "message": "Invalid credentials"}
	return {"ok": true, "message": "ok", "account": account}
