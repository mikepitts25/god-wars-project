class_name FixedCam
extends Camera3D

## Constrained third-person / fixed-angle camera (the 2.5D approach from
## docs/design/07-ui-ux.md). Follows a target at a fixed offset and angle.

const OFFSET := Vector3(0.0, 14.0, 11.0)
const FOLLOW_LERP := 8.0

var target: Node3D

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var desired := target.global_position + OFFSET
	global_position = global_position.lerp(desired, clampf(FOLLOW_LERP * delta, 0.0, 1.0))
	look_at(target.global_position + Vector3.UP, Vector3.UP)
