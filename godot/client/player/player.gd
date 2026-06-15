class_name PlayerView
extends Node3D

## Pure client-side visual for one entity. Position/health come from server
## snapshots; this node only renders. Built in code so the project needs no
## hand-authored character scene.

var entity_id: int = 0
var is_local := false
var target_pos := Vector3.ZERO

var _mesh: MeshInstance3D
var _material: StandardMaterial3D
var _label: Label3D

func setup(color: Color, display_name: String) -> void:
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8

	_material = StandardMaterial3D.new()
	_material.albedo_color = color

	_mesh = MeshInstance3D.new()
	_mesh.mesh = capsule
	_mesh.material_override = _material
	_mesh.position.y = 0.9
	add_child(_mesh)

	_label = Label3D.new()
	_label.text = display_name
	_label.position.y = 2.2
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.pixel_size = 0.01
	add_child(_label)

func set_stealth(stealth: bool) -> void:
	if _material == null:
		return
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if stealth else BaseMaterial3D.TRANSPARENCY_DISABLED
	var c := _material.albedo_color
	c.a = 0.35 if stealth else 1.0
	_material.albedo_color = c

func set_dead(dead: bool) -> void:
	visible = not dead
