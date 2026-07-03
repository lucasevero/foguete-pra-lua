class_name CutsceneFinal
## Dados da CENA 2 (final — a chegada). Fonte: roteiro do time.
## Área: integration. Reaproveita o CutscenePlayer.
##
## Usa as ILUSTRAÇÕES de cena final do time (cenas completas, com todos os
## personagens) sobre um fundo de espaço estrelado (space_bg). Por isso NÃO usa
## retratos individuais:
##   cena_final1 = chegada feliz, foguete intacto;
##   cena_final2 = foguete quebrado/fumaçando, os três presos.

const SPACE := Color(0.03, 0.03, 0.06)   # fallback caso o space_bg falte
const SPACE_BG := preload("res://assets/cutscenes/space_bg.png")     # fundo: espaço estrelado
const CENA_1 := preload("res://assets/cutscenes/cena_final1.png")    # chegada, foguete intacto
const CENA_2 := preload("res://assets/cutscenes/cena_final2.png")    # foguete quebrado, presos

static func build() -> Array[CutsceneBeat]:
	var K := CutsceneBeat.Kind
	var S := CutsceneBeat.PortraitSide
	var beats: Array[CutsceneBeat] = [
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "CARA! Eu sabia que você vinha! Salvou a gente!", S.LEFT, SPACE, ""),
		CutsceneBeat.make(K.DIALOGUE, "LUCA", "Bora voltar pra casa.", S.RIGHT, SPACE, ""),
		CutsceneBeat.make(K.DIALOGUE, "", "(Todos entram. Ignição… o motor tosse. Tenta de novo. Silêncio.)", S.LEFT, SPACE, ""),
		CutsceneBeat.make(K.DIALOGUE, "GUS", "Ãhn… Carlos.", S.RIGHT, SPACE, ""),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "Que foi.", S.LEFT, SPACE, ""),
		CutsceneBeat.make(K.DIALOGUE, "GUS", "Esse foguete também não tem a volta codada.", S.RIGHT, SPACE, ""),
		CutsceneBeat.make(K.DIALOGUE, "", "(Os três, sentados na Lua. Capacetes na mão. A Terra, brilhando.)", S.LEFT, SPACE, ""),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "…Alguém trouxe o lanche?", S.LEFT, SPACE, ""),
		CutsceneBeat.make(K.CAPTION, "", "Missão de resgate: concluída.\nMissão de retorno: não implementada.\n// TODO: codar a volta", S.LEFT, SPACE, ""),
	]
	# fundo de espaço em todos os beats; a ilustração (cena_final) vem por cima.
	for b in beats:
		b.background = SPACE_BG
	# chegada feliz (foguete intacto) nos 2 primeiros; da ignição falha em diante,
	# a cena do foguete quebrado / os três presos.
	beats[0].scene_art = CENA_1
	beats[1].scene_art = CENA_1
	beats[2].scene_art = CENA_2
	beats[3].scene_art = CENA_2
	beats[4].scene_art = CENA_2
	beats[5].scene_art = CENA_2
	beats[6].scene_art = CENA_2
	beats[7].scene_art = CENA_2
	beats[8].scene_art = CENA_2
	# sem retratos: as ilustrações já mostram os personagens.
	return beats
