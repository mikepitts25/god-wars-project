# Networking & Persistence

See `01-technical-architecture.md` for the authority model and transport. This doc covers
**auth, sessions, and the save model**.

## 1. Connection flow

```
Client                              Server (authoritative)
  │  create_client(host, port) ───────►  ENet accept, assign peer_id
  │  login(username, password) ───────►  auth_service.verify()
  │            ◄─── login_ok(account)  /  login_failed(reason)
  │  request_character_list ──────────►  persistence.list_characters(account)
  │            ◄─── character_list
  │  create_character(name, class) ───►  validate + persistence.create_character()
  │  enter_world(character_id) ───────►  load char, spawn in zone, begin sync
  │            ◄═══ state sync (Synchronizer) + world events (RPC) ═══►
```

## 2. Authentication

- **Scaffold:** username + **salted, hashed password** (e.g. SHA-256 + per-account salt
  via Godot `Crypto`/`HashingContext`) stored server-side through `PersistenceService`.
  Plaintext passwords are never stored or logged.
- **Validation:** server checks credentials on `login`; failures return a generic reason
  (no user-enumeration). Basic rate-limiting on login attempts per peer/IP.
- **Production path:** swap `auth_service` for an external backend (account service / OAuth /
  token issuance). The rest of the server only depends on "is this peer an authenticated
  account?", so the swap is localised.

## 3. Sessions & reconnection

- Godot/ENet assigns a **new peer_id on every (re)connection** and has **no built-in
  reconnection**. We handle this in `auth_service`/`world_state`:
  - On disconnect, the character enters a short **linkdead** grace period (stays in world,
    inert) before being saved out and despawned — a MUD "linkdead" analog.
  - On reconnect + re-login, the account is **re-bound** to its existing character/session
    if still within grace, else it re-enters from its last saved bind point.
- **M4 hardening:** issue a **session token** at login so a reconnecting client can resume
  its session deterministically rather than relying on the grace window.

## 4. Save model

```
Account
  ├─ id / username / password_hash / salt
  ├─ created_at / last_login
  └─ Characters[]
       ├─ id / name / class_id / tier / level
       ├─ position (zone_id + transform) / bind_point
       ├─ resources (vitae/rage/etc.) / health
       ├─ powers[] (id + rank + progress)
       ├─ inventory[] / equipment[]
       └─ renown / clan_id
```

- One **account** → many **characters**. Names are unique on the shard.
- **Autosave:** periodic flush (e.g. every N seconds) + on key events (level/rank up, zone
  change, logout, server shutdown) to bound data loss.

## 5. PersistenceService interface

`server/persistence_service.gd` is the **single boundary** between game logic and storage:

```
load_account(username) -> Account or null
create_account(username, password) -> Account or error
verify_credentials(username, password) -> bool
list_characters(account_id) -> [CharacterSummary]
create_character(account_id, name, class_id) -> Character or error
load_character(character_id) -> Character
save_character(character) -> void
save_world_object(obj) / load_world_objects(zone_id)   # corpses, contested state (M3+)
```

- **Scaffold impl:** JSON files under `user://data/` (one file per account, plus a name
  index). Simple, inspectable, zero external deps — good enough for dozens of players.
- **Production impl:** a drop-in `SqlitePersistence` / `PostgresPersistence` implementing the
  same interface. **No caller changes** — the rest of the server is storage-agnostic.

## 6. Replicated vs. RPC traffic

| Data | Mechanism | Reliability |
|---|---|---|
| Position / velocity | `MultiplayerSynchronizer` | unreliable (interpolated) |
| Health / resource / status flags | `MultiplayerSynchronizer` | reliable-ish (delta) |
| Ability cast / hit / death events | RPC | reliable |
| Chat messages | RPC | reliable |
| Spawn / despawn | `MultiplayerSpawner` | reliable |

## 7. Security notes

- All gameplay-affecting requests are **server-validated** (range, cooldown, resource,
  ownership) — clients are never trusted (`03-combat.md` §2).
- Passwords hashed + salted; credentials and tokens never logged.
- Rate-limit chat and ability spam server-side; log suspicious input patterns for review.
