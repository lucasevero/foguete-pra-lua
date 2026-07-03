class_name CutsceneFinal
## Dados da CENA 2 (final — a chegada). Fonte: roteiro do time.
## Área: integration. Reaproveita o CutscenePlayer.

const MOON := Color(0.11, 0.12, 0.18)     # fallback (interior/espaço)
const GROUND := Color(0.10, 0.11, 0.18)   # fallback (exterior lunar)

const CARLOS_1 := preload("res://assets/cutscenes/carlos1.png")
const CARLOS_2 := preload("res://assets/cutscenes/carlos2.png")
const GUS_2 := preload("res://assets/cutscenes/gus2.png")
const LUCA_1 := preload("res://assets/cutscenes/luca1.png")
const LUA_BG := preload("res://assets/cutscenes/lua_bg.png")
const MOON_SURFACE := preload("res://assets/cutscenes/moon_surface.png")
const MOON_SIT := preload("res://assets/cutscenes/moon_sit.png")

static func build() -> Array[CutsceneBeat]:
	var K := CutsceneBeat.Kind
	var S := CutsceneBeat.PortraitSide
	var beats: Array[CutsceneBeat] = [
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "CARA! Eu sabia que você vinha! Salvou a gente!", S.LEFT, GROUND, ""),
		CutsceneBeat.make(K.DIALOGUE, "LUCA", "Bora voltar pra casa.", S.RIGHT, GROUND, ""),
		CutsceneBeat.make(K.DIALOGUE, "", "(Todos entram. Ignição… o motor tosse. Tenta de novo. Silêncio.)", S.LEFT, MOON, ""),
		CutsceneBeat.make(K.DIALOGUE, "GUS", "Ãhn… Carlos.", S.RIGHT, MOON, ""),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "Que foi.", S.LEFT, MOON, ""),
		CutsceneBeat.make(K.DIALOGUE, "GUS", "Esse foguete também não tem a volta codada.", S.RIGHT, MOON, ""),
		CutsceneBeat.make(K.DIALOGUE, "", "(Os três, sentados na Lua. Capacetes na mão. A Terra, brilhando.)", S.LEFT, GROUND, ""),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "…Alguém trouxe o lanche?", S.LEFT, GROUND, ""),
		CutsceneBeat.make(K.CAPTION, "", "Missão de resgate: concluída.\nMissão de retorno: não implementada.\n// TODO: codar a volta", S.LEFT, GROUND, ""),
	]
	beats[0].portrait = CARLOS_1
	beats[1].portrait = LUCA_1
	beats[3].portrait = GUS_2
	beats[4].portrait = CARLOS_2
	beats[5].portrait = GUS_2
	# beats 2, 6, 7, 8 sem retrato (ação / wide-shot / legenda)
	beats[0].background = MOON_SURFACE
	beats[1].background = MOON_SURFACE
	beats[2].background = LUA_BG
	beats[3].background = LUA_BG
	beats[4].background = LUA_BG
	beats[5].background = LUA_BG
	beats[6].background = MOON_SIT
	beats[7].background = MOON_SIT
	beats[8].background = MOON_SIT
	return beats
