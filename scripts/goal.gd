extends Area2D
## Fim da fase: ao tocar, mostra "FASE CONCLUÍDA!" e vai para a próxima fase.

@export var next_level : String = ""


func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	if next_level == "":
		push_warning("goal sem next_level definido")
		return
	Transition.level_complete(next_level)
