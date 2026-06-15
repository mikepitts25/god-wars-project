# Zones

In the **scaffold**, the sample playable area is built in **code** for robustness:

- **Server authority/bounds:** `GameConstants.ZONE_HALF_EXTENT` defines the square arena
  the authoritative `WorldState` clamps movement to, and `TargetDummy.SPAWN_POSITION` places
  the sample creature. No physics geometry is needed server-side (collision is M2+).
- **Client visuals:** `client/client_main.gd::_build_world()` constructs the matching ground,
  lighting, environment and a couple of landmark obstacles.

This avoids hand-authored `.tscn` sub-resources (meshes/shapes/materials) that are hard to
get right without the editor.

## Production path (M2+)

Author zones as real `PackedScene` (`.tscn`) files here — terrain, props, colliders, spawn
`Marker3D`s and portal `Area3D`s — and load them on the server (for collision/spawns) and
client (for rendering). The zone graph + portal streaming is described in
`../../docs/design/05-world-zones.md`.
