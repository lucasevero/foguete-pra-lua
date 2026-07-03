extends CanvasLayer
## DONO: Dev D — HUD. Só escuta signals, não conhece nenhum outro sistema.

@onready var fuel_label: Label = $FuelLabel
@onready var time_label: Label = $TimeLabel
@onready var result_label: Label = $ResultLabel

func _ready() -> void:
	result_label.hide()
	GameEvents.fuel_changed.connect(_on_fuel_changed)
	GameEvents.time_changed.connect(_on_time_changed)
	GameEvents.game_over.connect(_on_game_over)

func _on_fuel_changed(current: float, maximum: float) -> void:
	fuel_label.text = "Combustível: %d / %d" % [current, maximum]

func _on_time_changed(seconds_left: float) -> void:
	time_label.text = "Tempo: %.1f" % seconds_left

func _on_game_over(won: bool) -> void:
	# TODO(Dev D): tela real de vitória/derrota + botão reiniciar
	result_label.text = "VITÓRIA! ...mas nosso foguete também não volta." if won else "GAME OVER"
	result_label.show()
