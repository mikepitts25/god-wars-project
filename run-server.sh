#!/usr/bin/env bash
#
# Starts the God Wars Reborn authoritative server (headless, UDP 7777).
# Then launch a client however you like (e.g. press Play in the Godot editor).
#
# Usage:   ./run-server.sh
# Override the engine path if needed:   GODOT=/path/to/Godot ./run-server.sh
#
set -euo pipefail
cd "$(dirname "$0")"

find_godot() {
	# 1) Explicit override.
	if [[ -n "${GODOT:-}" && -x "${GODOT}" ]]; then echo "${GODOT}"; return 0; fi
	if [[ -n "${GODOT:-}" ]] && command -v "${GODOT}" >/dev/null 2>&1; then command -v "${GODOT}"; return 0; fi
	# 2) On PATH.
	if command -v godot >/dev/null 2>&1; then command -v godot; return 0; fi
	if command -v godot4 >/dev/null 2>&1; then command -v godot4; return 0; fi
	# 3) Common macOS app-bundle locations.
	for p in \
		"/Applications/Godot.app/Contents/MacOS/Godot" \
		"$HOME/Applications/Godot.app/Contents/MacOS/Godot" \
		/Applications/Godot*.app/Contents/MacOS/Godot \
		"$HOME"/Applications/Godot*.app/Contents/MacOS/Godot; do
		if [[ -x "$p" ]]; then echo "$p"; return 0; fi
	done
	return 1
}

if ! GODOT_BIN="$(find_godot)"; then
	echo "ERROR: could not find a Godot 4 binary." >&2
	echo "  - Install Godot 4.3+ (https://godotengine.org/download/macos), or" >&2
	echo "  - run with an explicit path:  GODOT=/Applications/Godot.app/Contents/MacOS/Godot ./run-server.sh" >&2
	exit 1
fi

echo "Using Godot:  $GODOT_BIN"
echo "Starting God Wars Reborn server on UDP 7777  (Ctrl+C to stop)"
echo "When a client connects you should see: [server] peer N connected"
echo
exec "$GODOT_BIN" --headless --path godot -- --server
