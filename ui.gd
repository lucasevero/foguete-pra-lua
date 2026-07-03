extends CanvasLayer
## DONO: Dev D — HUD. Só escuta signals. process_mode=ALWAYS (funciona na pausa).

@onready var fuel_label: Label = $FuelLabel
@onready var time_label: Label = $TimeLabel
@onready var result_label: Label = $ResultLabel
@onready var restart_button: Button = $RestartButton

func _ready() -> void:
	result_label.hide()
	restart_button.hide()
	restart_button.pressed.connect(_on_restart_pressed)
	GameEvents.fuel_changed.connect(_on_fuel_changed)
	GameEvents.time_changed.connect(_on_time_changed)
	GameEvents.game_over.connect(_on_game_over)

func _on_fuel_changed(current: float, maximum: float) -> void:
	fuel_label.text = "Combustível: %d / %d" % [current, maximum]

func _on_time_changed(seconds_left: float) -> void:
	time_label.text = "Tempo: %.1f" % seconds_left

func _on_game_over(won: bool) -> void:
	result_label.text = "VITÓRIA!\n...mas nosso foguete também não volta." if won else "GAME OVER"
	result_label.show()
	restart_button.show()

func _on_restart_pressed() -> void:
	get_tree().paused = false            # despausa antes de recarregar
	get_tree().reload_current_scene()
