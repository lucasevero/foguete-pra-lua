class_name CutsceneIntro
## Dados da CENA 1 (abertura — a ligação do Carlos). Fonte: Notion "Storytelling".
## Área: integration.

const SKY := Color(0.35, 0.65, 0.95)   # azul-céu da base de lançamento (legenda final)
const MOON := Color(0.11, 0.12, 0.18)  # cinza-espaço escuro (ambiente LUA)
const ROOM := Color(0.28, 0.20, 0.15)  # marrom-quente (seu quarto na TERRA)

# Retratos pixel-art dos personagens (assets/cutscenes/). Carlos calmo no
# primeiro diálogo, aflito no resto; Você = Luca; Gus sorridente.
const CARLOS_1 := preload("res://assets/cutscenes/carlos1.png")
const CARLOS_2 := preload("res://assets/cutscenes/carlos2.png")
const LUCA_1 := preload("res://assets/cutscenes/luca1.png")
const GUS_2 := preload("res://assets/cutscenes/gus2.png")
const LUA_BG := preload("res://assets/cutscenes/lua_bg.png")   # fundo: interior do foguete na Lua
const CALL_BG := preload("res://assets/cutscenes/call_bg.png")     # fundo: celular tocando
const OFFICE_BG := preload("res://assets/cutscenes/office_bg.png") # fundo: escritório da Capim

static func build() -> Array[CutsceneBeat]:
	var K := CutsceneBeat.Kind
	var S := CutsceneBeat.PortraitSide
	var beats: Array[CutsceneBeat] = [
		CutsceneBeat.make(K.CALL, "CARLOS", "Carlos chamando", S.LEFT, Color.BLACK, ""),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "E aí, beleza? Então… eu e o Gus vibecodamos um foguete no fim de semana.", S.LEFT, MOON, "LUA"),
		CutsceneBeat.make(K.DIALOGUE, "LUCA", "Vocês fizeram o quê?", S.RIGHT, ROOM, "TERRA — seu quarto"),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "Funcionou! A gente chegou na Lua! De verdade!", S.LEFT, MOON, "LUA"),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "É… só que a gente esqueceu de codar a volta.", S.LEFT, MOON, "LUA"),
		CutsceneBeat.make(K.DIALOGUE, "GUS", "FALA PRA ELE TRAZER LANCHE!", S.RIGHT, MOON, "LUA"),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "Dá pra vir buscar a gente? Cê é a nossa única… uh… branch de recuperação.", S.LEFT, MOON, "LUA"),
		CutsceneBeat.make(K.CAPTION, "", "Missão de resgate iniciada.", S.LEFT, SKY, ""),
	]
	beats[7].auto_advance_after = 2.5   # a legenda final aparece sozinha e segue pro jogo
	# retratos por beat (beat 0/chamada e beat 7/legenda ficam sem retrato)
	beats[1].portrait = CARLOS_1   # primeiro diálogo (calmo)
	beats[2].portrait = LUCA_1     # Você (Luca)
	beats[3].portrait = CARLOS_2   # aflito
	beats[4].portrait = CARLOS_2
	beats[5].portrait = GUS_2      # Gus ao fundo
	beats[6].portrait = CARLOS_2
	# ambiente LUA (interior do foguete) nas falas do Carlos/Gus
	beats[1].background = LUA_BG
	beats[3].background = LUA_BG
	beats[4].background = LUA_BG
	beats[5].background = LUA_BG
	beats[6].background = LUA_BG
	beats[0].background = CALL_BG     # tela de chamada: celular tocando
	beats[2].background = OFFICE_BG   # Luca no escritório da Capim
	return beats
