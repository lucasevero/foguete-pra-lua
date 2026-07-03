extends SceneTree
## Teste headless da lógica do CutscenePlayer. Rodar:
##   Godot --headless --script res://tests/test_cutscene_player.gd

func _initialize() -> void:
	var ok := true

	var scene: PackedScene = load("res://cutscene_player.tscn")
	var player: CutscenePlayer = scene.instantiate()
	get_root().add_child(player)
	await process_frame  # deixa o _ready()/@onready do player rodar antes de usá-lo

	var done := {"v": false}
	player.finished.connect(func(): done["v"] = true)

	var d1 := CutsceneBeat.make(CutsceneBeat.Kind.DIALOGUE, "CARLOS", "oi")
	var d2 := CutsceneBeat.make(CutsceneBeat.Kind.DIALOGUE, "VOCÊ", "tchau", CutsceneBeat.PortraitSide.RIGHT)
	var beats: Array[CutsceneBeat] = [d1, d2]
	player.play(beats)

	# dirige advance() até finalizar (cada beat: 1 advance completa a linha, 1 avança)
	var guard := 0
	while not done["v"] and guard < 20:
		player.advance()
		guard += 1
	ok = _check(done["v"], "finished deveria disparar ao fim dos beats") and ok
	ok = _check(guard < 20, "não deve precisar de 20 advances (loop travado?)") and ok

	# skip() finaliza imediatamente
	var player2: CutscenePlayer = scene.instantiate()
	get_root().add_child(player2)
	await process_frame
	var done2 := {"v": false}
	player2.finished.connect(func(): done2["v"] = true)
	player2.play(beats)
	player2.skip()
	ok = _check(done2["v"], "skip() deveria disparar finished") and ok

	if ok:
		print("TEST_OK test_cutscene_player")
		quit(0)
	else:
		printerr("TEST_FAIL test_cutscene_player")
		quit(1)

func _check(cond: bool, msg: String) -> bool:
	if not cond:
		printerr("  FAIL: " + msg)
	return cond
