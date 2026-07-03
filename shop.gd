extends CanvasLayer
## DONO: integration — contador de moedas (canto sup. dir.) + loja de powerups
## (ícone canto inf. dir.). Abre pausando o jogo; comprar debita e aplica na hora.
## Cena separada do HUD (ui.tscn) p/ não conflitar com a área ativa do Dev D.

const PRICES := {"time": 5, "shield": 10, "fuel": 15, "weapon": 25}

@onready var shop_button: Button = $ShopButton
@onready var panel: Panel = $Panel
@onready var balance: Label = $Panel/VBox/Balance
@onready var buy_time: Button = $Panel/VBox/BuyTime
@onready var buy_shield: Button = $Panel/VBox/BuyShield
@onready var buy_fuel: Button = $Panel/VBox/BuyFuel
@onready var buy_weapon: Button = $Panel/VBox/BuyWeapon

var _coins: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	shop_button.hide()                        # escondido no menu; aparece só quando o jogo começa
	shop_button.pressed.connect(_open)
	$Panel/VBox/Close.pressed.connect(_close)
	buy_time.pressed.connect(_buy.bind("time"))
	buy_shield.pressed.connect(_buy.bind("shield"))
	buy_fuel.pressed.connect(_buy.bind("fuel"))
	buy_weapon.pressed.connect(_buy.bind("weapon"))
	GameEvents.coins_changed.connect(_on_coins_changed)
	GameEvents.game_started.connect(func(): shop_button.show())   # aparece quando começa a partida
	# no game over: esconde a loja SEM despausar (o GameManager controla a pausa aqui)
	GameEvents.game_over.connect(func(_w): shop_button.hide(); panel.hide())

func _on_coins_changed(total: int) -> void:
	_coins = total   # contador agora fica no HUD (ui.tscn); aqui só atualiza o saldo do painel
	_refresh()

func _open() -> void:
	AudioManager.play_ui_click()
	_refresh()
	panel.show()
	get_tree().paused = true

func _close() -> void:
	panel.hide()
	get_tree().paused = false

func _buy(kind: String) -> void:
	if _coins >= PRICES[kind]:
		AudioManager.play_ui_click()
		GameEvents.powerup_purchase_requested.emit(kind)  # GameManager debita e aplica

func _refresh() -> void:
	balance.text = "Moedas: %d" % _coins
	buy_time.disabled = _coins < PRICES["time"]
	buy_shield.disabled = _coins < PRICES["shield"]
	buy_fuel.disabled = _coins < PRICES["fuel"]
	buy_weapon.disabled = _coins < PRICES["weapon"]
