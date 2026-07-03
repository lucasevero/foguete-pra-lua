extends SceneTree
## Teste headless dos dados da cutscene. Rodar:
##   Godot --headless --script res://tests/test_cutscene_data.gd

func _initialize() -> void:
	var ok := true
	var beats := CutsceneIntro.build()
	ok = _check(beats.size() == 8, "esperava 8 beats, veio %d" % beats.size()) and ok
	ok = _check(beats[0].kind == CutsceneBeat.Kind.CALL, "beat 0 deve ser CALL") and ok
	ok = _check(beats[0].speaker == "CARLOS", "beat 0 speaker deve ser CARLOS") and ok
	ok = _check(beats[1].location == "LUA", "beat 1 (Carlos) deve ser ambiente LUA") and ok
	ok = _check(beats[2].location == "TERRA — seu quarto", "beat 2 (Você) deve ser ambiente TERRA") and ok
	ok = _check(beats[5].speaker == "GUS", "beat 5 deve ser o GUS") and ok
	ok = _check(beats[5].location == "LUA", "beat 5 (Gus) deve ser ambiente LUA") and ok
	ok = _check(beats[7].kind == CutsceneBeat.Kind.CAPTION, "beat 7 deve ser CAPTION") and ok
	ok = _check(beats[7].text == "Missão de resgate iniciada.", "legenda final errada") and ok
	ok = _check(beats[7].auto_advance_after > 0.0, "legenda final deve auto-avançar") and ok
	if ok:
		print("TEST_OK test_cutscene_data")
		quit(0)
	else:
		printerr("TEST_FAIL test_cutscene_data")
		quit(1)

func _check(cond: bool, msg: String) -> bool:
	if not cond:
		printerr("  FAIL: " + msg)
	return cond
