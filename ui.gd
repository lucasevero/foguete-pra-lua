extends CanvasLayer
## DONO: Dev D — HUD (arte pixel). Só escuta signals. process_mode=ALWAYS (funciona na pausa).

@onready var fuel_bar: TextureProgressBar = $HudPanel/FuelBar
@onready var fuel_value: Label = $HudPanel/FuelValue
@onready var time_label: Label = $HudPanel/TimeLabel
@onready var result_label: Label = $ResultLabel
@onready var restart_button: Button = $RestartButton

const FUEL_OK := Color(1, 1, 1, 1)             # âmbar original do sprite
const FUEL_LOW := Color(1.0, 0.45, 0.35, 1)    # tingido de vermelho quando acabando
const LOW_RATIO := 0.25

func _ready() -> void:
	result_label.hide()
	restart_button.hide()
	restart_button.pressed.connect(_on_restart_pressed)
	GameEvents.fuel_changed.connect(_on_fuel_changed)
	GameEvents.time_changed.connect(_on_time_changed)
	GameEvents.game_over.connect(_on_game_over)

func _on_fuel_changed(current: float, maximum: float) -> void:
	fuel_bar.max_value = maximum
	fuel_bar.value = current
	fuel_value.text = "%d / %d" % [current, maximum]
	# alerta visual quando o combustível está acabando
	var low := maximum > 0.0 and current / maximum <= LOW_RATIO
	fuel_bar.tint_progress = FUEL_LOW if low else FUEL_OK

func _on_time_changed(seconds_left: float) -> void:
	time_label.text = "Tempo: %.1f" % seconds_left

func _on_game_over(won: bool) -> void:
	result_label.text = "VITÓRIA!\n...mas nosso foguete também não volta." if won else "GAME OVER"
	result_label.show()
	restart_button.show()

func _on_restart_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().paused = false            # despausa antes de recarregar
	get_tree().reload_current_scene()
