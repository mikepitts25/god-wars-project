class_name AbilityDef
extends Resource

## Data-driven ability definition. The scaffold builds these in code
## (shared/data/game_data.gd); production authors them as .tres assets.
## combat_system.gd interprets `effect` generically, so new abilities are
## content, not new code paths.

@export var id: StringName
@export var display_name: String = ""
@export var cost: float = 0.0          # resource cost
@export var cooldown: float = 1.0      # seconds
@export var cast_range: float = 3.0    # metres (named cast_range; `range` is reserved)
@export var effect: int = GameConstants.Effect.DAMAGE
@export var power: float = 0.0         # damage / heal / drain magnitude (per tick for DOT)
@export var duration: float = 0.0      # status / DOT total duration
@export var tick: float = 1.0          # DOT tick interval (seconds)
@export var damage_type: int = GameConstants.DamageType.PHYSICAL
