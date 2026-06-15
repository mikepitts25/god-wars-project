class_name ChatPanel
extends Control

## Chat + combat log — the MUD's text layer as first-class UI
## (docs/design/07-ui-ux.md). Scaffold exposes the global channel; the full
## channel set (Say/Clan/Tell) is M2+.

signal message_submitted(text: String)

var _log: RichTextLabel
var _input: LineEdit

func _ready() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	position = Vector2(320, 470)
	custom_minimum_size = Vector2(540, 230)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(540, 230)
	add_child(box)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.custom_minimum_size = Vector2(540, 190)
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_log)

	_input = LineEdit.new()
	_input.placeholder_text = "Press Enter to chat..."
	_input.custom_minimum_size = Vector2(540, 30)
	_input.text_submitted.connect(_on_submit)
	box.add_child(_input)

func _on_submit(text: String) -> void:
	_input.clear()
	_input.release_focus()
	var t := text.strip_edges()
	if not t.is_empty():
		message_submitted.emit(t)

func focus_input() -> void:
	_input.grab_focus()

func is_typing() -> bool:
	return _input.has_focus()

func add_line(text: String) -> void:
	_log.append_text(text + "\n")

func add_system(text: String) -> void:
	add_line("[color=#9aa0b5]%s[/color]" % text)

func add_chat(sender: String, text: String) -> void:
	add_line("[color=#d8d8ff]%s:[/color] %s" % [sender, text])
