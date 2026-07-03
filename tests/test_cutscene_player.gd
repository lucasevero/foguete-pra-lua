extends SceneTree
## Teste headless da lógica do CutscenePlayer. Rodar:
##   Godot --headless --script res://tests/test_cutscene_player.gd

func _initialize() -> void:
	var ok := true

	var scene: PackedScene = load("res://cutscene_player.tscn")

	var d1 := CutsceneBeat.make(CutsceneBeat.Kind.DIALOGUE, "CARLOS", "oi")
	var d2 := CutsceneBeat.make(CutsceneBeat.Kind.DIALOGUE, "VOCÊ", "tchau", CutsceneBeat.PortraitSide.RIGHT)
	var beats: Array[CutsceneBeat] = [d1, d2]

	# 1) DIALOGUE: dirige advance() até finalizar
	var player: CutscenePlayer = scene.instantiate()
	get_root().add_child(player)
	await process_frame  # deixa o _ready()/@onready do player rodar antes de usá-lo
	var done := {"v": false}
	player.finished.connect(func(): done["v"] = true)
	player.play(beats)
	var guard := 0
	while not done["v"] and guard < 20:
		player.advance()
		guard += 1
	ok = _check(done["v"], "finished deveria disparar ao fim dos beats") and ok
	ok = _check(guard < 20, "não deve precisar de 20 advances (loop travado?)") and ok

	# 2) skip() finaliza imediatamente
	var player2: CutscenePlayer = scene.instantiate()
	get_root().add_child(player2)
	await process_frame  # deixa o _ready()/@onready do player rodar antes de usá-lo
	var done2 := {"v": false}
	player2.finished.connect(func(): done2["v"] = true)
	player2.play(beats)
	player2.skip()
	ok = _check(done2["v"], "skip() deveria disparar finished") and ok

	# 3) CALL + CAPTION: cobre os dois outros caminhos de render (chamada e legenda)
	var caption_beats: Array[CutsceneBeat] = [
		CutsceneBeat.make(CutsceneBeat.Kind.CALL, "CARLOS", "CARLOS chamando…"),
		CutsceneBeat.make(CutsceneBeat.Kind.CAPTION, "", "Missão de resgate iniciada."),
	]
	var player3: CutscenePlayer = scene.instantiate()
	get_root().add_child(player3)
	await process_frame  # deixa o _ready()/@onready do player rodar antes de usá-lo
	var done3 := {"v": false}
	player3.finished.connect(func(): done3["v"] = true)
	player3.play(caption_beats)
	var guard3 := 0
	while not done3["v"] and guard3 < 20:
		player3.advance()
		guard3 += 1
	ok = _check(done3["v"], "finished deveria disparar ao fim dos beats CALL/CAPTION") and ok
	ok = _check(guard3 < 20, "não deve precisar de 20 advances no CALL/CAPTION (loop travado?)") and ok

	# 4) SkipButton.pressed -> skip() -> finished
	var player4: CutscenePlayer = scene.instantiate()
	get_root().add_child(player4)
	await process_frame  # deixa o _ready()/@onready do player rodar antes de usá-lo
	var done4 := {"v": false}
	player4.finished.connect(func(): done4["v"] = true)
	player4.play(beats)
	(player4.get_node("CallUI/SkipButton") as Button).pressed.emit()
	ok = _check(done4["v"], "SkipButton deveria disparar skip()->finished") and ok

	# 5) AnswerButton.pressed -> advance() a partir do CALL, depois dirige até o fim
	var player5: CutscenePlayer = scene.instantiate()
	get_root().add_child(player5)
	await process_frame  # deixa o _ready()/@onready do player rodar antes de usá-lo
	var done5 := {"v": false}
	player5.finished.connect(func(): done5["v"] = true)
	player5.play(caption_beats)
	(player5.get_node("CallUI/AnswerButton") as Button).pressed.emit()
	var guard5 := 0
	while not done5["v"] and guard5 < 20:
		player5.advance()
		guard5 += 1
	ok = _check(done5["v"], "AnswerButton deveria avançar a partir do CALL") and ok

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
