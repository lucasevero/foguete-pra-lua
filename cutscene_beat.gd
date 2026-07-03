class_name CutsceneBeat
extends Resource
## Uma "fala" da cutscene. Dados puros, consumidos pelo CutscenePlayer.
## Área: integration. Não conhece gameplay nem GameEvents.

enum Kind { CALL, DIALOGUE, CAPTION }
enum PortraitSide { LEFT, RIGHT }

@export var kind: Kind = Kind.DIALOGUE
@export var speaker: String = ""
@export_multiline var text: String = ""
@export var portrait: Texture2D                      # null = placeholder colorido
@export var portrait_side: PortraitSide = PortraitSide.LEFT
@export var background: Texture2D                     # null = usa background_color
@export var background_color: Color = Color.BLACK     # fallback quando não há textura
@export var sfx: AudioStream                          # som opcional do beat
@export var auto_advance_after: float = 0.0           # 0 = espera input; >0 = auto após N s

static func make(p_kind: Kind, p_speaker: String, p_text: String,
		p_side: PortraitSide = PortraitSide.LEFT,
		p_bg: Color = Color.BLACK) -> CutsceneBeat:
	var b := CutsceneBeat.new()
	b.kind = p_kind
	b.speaker = p_speaker
	b.text = p_text
	b.portrait_side = p_side
	b.background_color = p_bg
	return b
