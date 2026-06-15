class_name HUD
extends Control

## In-game heads-up display: self health/resource bars, ability bar, and a
## target frame (docs/design/07-ui-ux.md). Built entirely in code.

signal ability_pressed(index: int)

var _hp_bar: ProgressBar
var _res_bar: ProgressBar
var _res_label: Label
var _target_panel: PanelContainer
var _target_label: Label
var _target_hp: ProgressBar
var _ability_buttons: Array[Button] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# --- Target frame (top centre) ---
	_target_panel = PanelContainer.new()
	_target_panel.position = Vector2(520, 16)
	_target_panel.custom_minimum_size = Vector2(240, 0)
	_target_panel.visible = false
	var tv := VBoxContainer.new()
	_target_label = Label.new()
	_target_label.text = "Target"
	_target_hp = ProgressBar.new()
	_target_hp.max_value = 100.0
	_target_hp.custom_minimum_size = Vector2(220, 16)
	tv.add_child(_target_label)
	tv.add_child(_target_hp)
	_target_panel.add_child(tv)
	add_child(_target_panel)

	# --- Self frame (bottom left) ---
	var self_box := VBoxContainer.new()
	self_box.position = Vector2(24, 560)
	self_box.custom_minimum_size = Vector2(280, 0)
	var hp_label := Label.new()
	hp_label.text = "Health"
	_hp_bar = ProgressBar.new()
	_hp_bar.max_value = 100.0
	_hp_bar.custom_minimum_size = Vector2(260, 18)
	_res_label = Label.new()
	_res_label.text = "Resource"
	_res_bar = ProgressBar.new()
	_res_bar.max_value = 100.0
	_res_bar.custom_minimum_size = Vector2(260, 18)
	self_box.add_child(hp_label)
	self_box.add_child(_hp_bar)
	self_box.add_child(_res_label)
	self_box.add_child(_res_bar)
	add_child(self_box)

	# --- Ability bar (bottom centre) ---
	var bar := HBoxContainer.new()
	bar.position = Vector2(440, 660)
	for i in range(4):
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 44)
		b.text = "%d:" % (i + 1)
		b.focus_mode = Control.FOCUS_NONE
		var idx := i
		b.pressed.connect(func(): ability_pressed.emit(idx))
		_ability_buttons.append(b)
		bar.add_child(b)
	add_child(bar)

func set_abilities(names: PackedStringArray) -> void:
	for i in range(_ability_buttons.size()):
		if i < names.size():
			_ability_buttons[i].text = "%d: %s" % [i + 1, names[i]]
			_ability_buttons[i].visible = true
		else:
			_ability_buttons[i].visible = false

func set_self_stats(hp: float, max_hp: float, res: float, max_res: float, res_name: String) -> void:
	_hp_bar.max_value = maxf(1.0, max_hp)
	_hp_bar.value = hp
	_res_label.text = res_name
	_res_bar.max_value = maxf(1.0, max_res)
	_res_bar.value = res

func set_target(display_name: String, hp: float, max_hp: float) -> void:
	_target_panel.visible = true
	_target_label.text = display_name
	_target_hp.max_value = maxf(1.0, max_hp)
	_target_hp.value = hp

func clear_target() -> void:
	_target_panel.visible = false
