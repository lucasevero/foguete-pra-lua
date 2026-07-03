extends CanvasLayer
## DONO: Dev C — fundo que transiciona Terra -> espaço -> Lua conforme sobe.
## Escuta GameEvents.altitude_changed (0.0 = Terra, 1.0 = Lua).

@onready var rect: ColorRect = $ColorRect

var earth_sky := Color(0.53, 0.81, 0.92)  # azul celeste
var deep_space := Color(0.02, 0.02, 0.08) # espaço escuro

func _ready() -> void:
	GameEvents.altitude_changed.connect(_on_altitude_changed)

func _on_altitude_changed(ratio: float) -> void:
	# TODO(Dev C): trocar por camadas parallax de pixel art (nuvens, estrelas, lua)
	rect.color = earth_sky.lerp(deep_space, clampf(ratio, 0.0, 1.0))
