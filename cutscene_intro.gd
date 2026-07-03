class_name CutsceneIntro
## Dados da CENA 1 (abertura — a ligação do Carlos). Fonte: Notion "Storytelling".
## Área: integration.

const SKY := Color(0.35, 0.65, 0.95)   # azul-céu da base de lançamento

static func build() -> Array[CutsceneBeat]:
	var K := CutsceneBeat.Kind
	var S := CutsceneBeat.PortraitSide
	var beats: Array[CutsceneBeat] = [
		CutsceneBeat.make(K.CALL, "CARLOS", "CARLOS chamando…", S.LEFT, Color.BLACK),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "E aí, beleza? Então… eu e o Gus vibecodamos um foguete no fim de semana.", S.LEFT, Color.BLACK),
		CutsceneBeat.make(K.DIALOGUE, "VOCÊ", "Vocês fizeram o quê?", S.RIGHT, Color.BLACK),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "Funcionou! A gente chegou na Lua! De verdade!", S.LEFT, Color.BLACK),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "É… só que a gente esqueceu de codar a volta.", S.LEFT, Color.BLACK),
		CutsceneBeat.make(K.DIALOGUE, "GUS", "FALA PRA ELE TRAZER LANCHE!", S.RIGHT, Color.BLACK),
		CutsceneBeat.make(K.DIALOGUE, "CARLOS", "Dá pra vir buscar a gente? Cê é a nossa única… uh… branch de recuperação.", S.LEFT, Color.BLACK),
		CutsceneBeat.make(K.CAPTION, "", "Missão de resgate iniciada.", S.LEFT, SKY),
	]
	beats[7].auto_advance_after = 2.5   # a legenda final aparece sozinha e segue pro jogo
	return beats
