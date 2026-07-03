extends CanvasLayer
## DONO: Dev D — HUD + menu inicial (arte pixel). Só fala por signals.
## process_mode=ALWAYS: menu e botões funcionam com a árvore pausada.

@onready var hud_panel: NinePatchRect = $HudPanel
@onready var fuel_bar: TextureProgressBar = $HudPanel/FuelBar
@onready var fuel_value: Label = $HudPanel/FuelValue
@onready var time_label: Label = $HudPanel/TimeLabel
@onready var tilt_panel: NinePatchRect = $TiltPanel
@onready var tilt_arrow: TextureRect = $TiltPanel/TiltArrow
@onready var result_label: Label = $ResultLabel
@onready var restart_button: Button = $RestartButton
@onready var menu_button: Button = $MenuButton
@onready var menu_layer: Control = $MenuLayer
@onready var menu_panel: NinePatchRect = $MenuLayer/MenuPanel
@onready var credits_panel: NinePatchRect = $MenuLayer/CreditsPanel
@onready var jogar_button: Button = $MenuLayer/MenuPanel/JogarButton
@onready var creditos_button: Button = $MenuLayer/MenuPanel/CreditosButton
@onready var sair_button: Button = $MenuLayer/MenuPanel/SairButton
@onready var voltar_button: Button = $MenuLayer/CreditsPanel/VoltarButton

const FUEL_OK := Color(1, 1, 1, 1)             # âmbar original do sprite
const FUEL_LOW := Color(1.0, 0.45, 0.35, 1)    # tingido de vermelho quando acabando
const LOW_RATIO := 0.25

const TILT_OK := Color(0.5, 0.9, 0.55, 1)      # verde: no prumo
const TILT_BAD := Color(1.0, 0.42, 0.36, 1)    # vermelho: muito inclinado
const TILT_DANGER := 0.9                        # rad (~51°) → totalmente vermelho

func _ready() -> void:
	# estado inicial = menu; HUD e game over escondidos
	hud_panel.hide()
	tilt_panel.hide()
	result_label.hide()
	restart_button.hide()
	menu_button.hide()
	credits_panel.hide()
	menu_layer.show()

	jogar_button.pressed.connect(_on_jogar_pressed)
	creditos_button.pressed.connect(_on_creditos_pressed)
	sair_button.pressed.connect(_on_sair_pressed)
	voltar_button.pressed.connect(_on_voltar_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)

	GameEvents.game_started.connect(_on_game_started)
	GameEvents.fuel_changed.connect(_on_fuel_changed)
	GameEvents.time_changed.connect(_on_time_changed)
	GameEvents.tilt_changed.connect(_on_tilt_changed)
	GameEvents.game_over.connect(_on_game_over)

# --- Menu ---
func _on_jogar_pressed() -> void:
	GameEvents.start_requested.emit()   # GameManager começa a partida

func _on_creditos_pressed() -> void:
	menu_panel.hide()
	credits_panel.show()

func _on_voltar_pressed() -> void:
	credits_panel.hide()
	menu_panel.show()

func _on_sair_pressed() -> void:
	get_tree().quit()

func _on_game_started() -> void:
	menu_layer.hide()
	result_label.hide()
	restart_button.hide()
	menu_button.hide()
	hud_panel.show()
	tilt_panel.show()

# --- HUD ---
func _on_fuel_changed(current: float, maximum: float) -> void:
	fuel_bar.max_value = maximum
	fuel_bar.value = current
	fuel_value.text = "%d / %d" % [current, maximum]
	var low := maximum > 0.0 and current / maximum <= LOW_RATIO
	fuel_bar.tint_progress = FUEL_LOW if low else FUEL_OK

func _on_time_changed(seconds_left: float) -> void:
	time_label.text = "Tempo: %.1f" % seconds_left

func _on_tilt_changed(radians: float) -> void:
	tilt_arrow.rotation = radians
	var t := clampf(absf(radians) / TILT_DANGER, 0.0, 1.0)
	tilt_arrow.modulate = TILT_OK.lerp(TILT_BAD, t)

func _on_game_over(won: bool) -> void:
	result_label.text = "VITÓRIA!\n...mas nosso foguete também não volta." if won else "GAME OVER"
	result_label.show()
	restart_button.show()
	menu_button.show()

func _on_restart_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().paused = false            # despausa antes de recarregar
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	GameEvents.menu_requested.emit()     # GameManager zera o replay e recarrega no menu
