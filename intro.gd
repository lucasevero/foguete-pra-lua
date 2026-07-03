extends Node
## Fluxo da abertura: toca a CENA 1 e, ao terminar/pular, entra no jogo.
## Área: integration. Só orquestra cena — não conhece gameplay nem GameEvents.

@onready var _player: CutscenePlayer = $CutscenePlayer

func _ready() -> void:
	_player.finished.connect(_on_finished)
	_player.play(CutsceneIntro.build())

func _on_finished() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
