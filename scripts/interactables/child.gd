extends "res://scripts/interactions/interactable.gd"
## The protagonist's child, waiting at home.
## Present on days 1-2 only (GameState.child_present()); the house scene removes
## this node on day 3 so the room reads as empty.
## Owner: builder-core (CONTRACT.md §1/§6).

const LINES_DAY_1 := [
	"Filho: Você vai cortar lenha de novo, mãe?",
	"Filho: Tudo bem. Eu espero você aqui dentro.",
	"Filho: Só... fecha a porta quando voltar. Tem vento lá fora.",
]

const LINES_DAY_2 := [
	"Filho: Você voltou! Eu contei as tábuas do chão enquanto esperava.",
	"Filho: Continuam as mesmas. Sempre as mesmas tábuas...",
	"Filho: Mãe, você trocou a minha cama de lugar, ou eu sonhei que ela estava no outro canto?",
]


func _ready() -> void:
	super._ready()
	# Safety net: never visible / interactable when the state says the child is gone.
	if not GameState.child_present():
		visible = false


func can_interact() -> bool:
	if not GameState.child_present():
		return false
	return super.can_interact()


func interact(_by: Node) -> void:
	if not can_interact():
		return
	Dialogue.show_lines(_lines_for_today())


## Short prompt lines, one set per day. Day 3 has no child, so it returns nothing.
func _lines_for_today() -> Array:
	if GameState.day <= 1:
		return LINES_DAY_1
	if GameState.day == 2:
		return LINES_DAY_2
	return []
