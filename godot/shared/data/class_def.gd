class_name ClassDef
extends Resource

## Data-driven class definition (see docs/design/02-classes.md).
## Scaffold builds these in code (game_data.gd); production authors .tres.

@export var id: StringName
@export var display_name: String = ""
@export_multiline var blurb: String = ""
@export var max_health: float = 100.0
@export var resource_label: String = "Resource"   # 'resource_name' is reserved by Resource
@export var max_resource: float = 100.0
@export var resource_regen: float = 2.0     # per second
@export var weakness: String = ""
@export var abilities: Array[AbilityDef] = []
