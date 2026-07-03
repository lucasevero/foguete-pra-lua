extends SceneTree
## Teste headless dos dados da CENA 2. Rodar:
##   Godot --headless --script res://tests/test_cutscene_final.gd

func _initialize() -> void:
	var ok := true
	var beats := CutsceneFinal.build()
	ok = _check(beats.size() == 9, "esperava 9 beats, veio %d" % beats.size()) and ok
	ok = _check(beats[0].speaker == "CARLOS", "beat 0 deve ser CARLOS") and ok
	ok = _check(beats[1].speaker == "LUCA", "beat 1 deve ser LUCA") and ok
	ok = _check(beats[2].speaker == "", "beat 2 (ação) deve ter speaker vazio") and ok
	ok = _check(beats[7].text == "…Alguém trouxe o lanche?", "beat 7 (lanche) errado") and ok
	ok = _check(beats[8].kind == CutsceneBeat.Kind.CAPTION, "beat 8 deve ser CAPTION") and ok
	ok = _check(beats[8].text.contains("TODO: codar a volta"), "legenda final deve ter o TODO") and ok
	if ok:
		print("TEST_OK test_cutscene_final")
		quit(0)
	else:
		printerr("TEST_FAIL test_cutscene_final")
		quit(1)

func _check(cond: bool, msg: String) -> bool:
	if not cond:
		printerr("  FAIL: " + msg)
	return cond
